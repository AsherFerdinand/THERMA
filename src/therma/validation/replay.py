"""Hash-checked original-FMU inventory and explicitly partial replay preparation."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Any

import numpy as np
from numpy.typing import NDArray

from therma.comparison import Interpolation, Series, convert
from therma.validation.archive import REGISTRY, REGISTRY_HASH, ROOT, read_json, sha256

MATRIX = ROOT / "configs/references/c2_signal_compatibility.json"
INPUTS: list[tuple[str, str, str, int, Interpolation]] = [
    ("weaSta_reaWeaTDryBul_y", "outdoor_temperature", "K", 1, "linear"),
    ("mod.rad.QCon_flow", "delivered_heating_convective_power", "W", -1, "previous"),
    ("mod.rad.QRad_flow", "delivered_heating_radiative_power", "W", -1, "previous"),
    (
        "mod.case900Template.intGaiOcc.portCon.Q_flow",
        "internal_convective_power",
        "W",
        -1,
        "previous",
    ),
    (
        "mod.case900Template.intGaiOcc.portRad.Q_flow",
        "internal_radiative_power",
        "W",
        -1,
        "previous",
    ),
]


def validate_matrix(path: Path = MATRIX) -> dict[str, Any]:
    matrix = read_json(path.read_bytes())
    if matrix.get("schema_version") != 1:
        raise ValueError("Unsupported signal compatibility schema")
    allowed = {
        "directly_comparable",
        "comparable_after_transformation",
        "proxy_only",
        "not_comparable",
        "missing",
    }
    seen: set[str] = set()
    for row in matrix["signals"]:
        if row["quantity"] in seen or row["comparison_status"] not in allowed:
            raise ValueError("Duplicate quantity or unsupported compatibility category")
        seen.add(row["quantity"])
        if row["comparison_status"] == "directly_comparable" and not (
            row["reference_available"] and row["therma_available"]
        ):
            raise ValueError("Direct comparison requires both signals")
        if not row["reason"] or row["unit"] not in {"K", "W", "J"}:
            raise ValueError("Missing signal rationale or unsupported units")
    required = {
        "air_temperature": "directly_comparable",
        "radiative_temperature": "proxy_only",
        "operative_temperature": "missing",
        "gas_input_power": "not_comparable",
        "pump_electrical_power": "not_comparable",
        "absorbed_solar_power": "missing",
    }
    by_name = {r["quantity"]: r for r in matrix["signals"]}
    if any(
        by_name.get(name, {}).get("comparison_status") != status
        for name, status in required.items()
    ):
        raise ValueError("Critical signal equivalence classification changed")
    return matrix


def event_samples(
    times: NDArray[np.float64], values: NDArray[np.float64], policy: str
) -> tuple[NDArray[np.float64], NDArray[np.float64]]:
    """Explicit duplicate semantics: rightmost hold wins; continuous jumps rejected."""
    if times.ndim != 1 or values.shape != times.shape or len(times) < 2:
        raise ValueError("Invalid scalar event samples")
    if not np.isfinite(times).all() or not np.isfinite(values).all() or np.any(np.diff(times) < 0):
        raise ValueError("Invalid/nonmonotone event data")
    if policy not in ("linear", "previous"):
        raise ValueError("Unsupported interpolation")
    duplicate = np.diff(times) == 0
    if policy == "linear" and np.any(values[1:][duplicate] != values[:-1][duplicate]):
        raise ValueError("Continuous interpolation cannot smear a duplicate-time jump")
    keep = np.r_[np.diff(times) != 0, True]
    return times[keep], values[keep]


def reference_run(
    run: Path, filename: str = "trajectory.csv"
) -> tuple[dict[str, Any], Any, dict[str, str]]:
    manifest = read_json((run / "manifest.json").read_bytes())
    matrix = validate_matrix()
    if manifest.get("status") != "success" or manifest.get("source_fmu_unchanged") is not True:
        raise ValueError("Reference run was not successful with unchanged FMU")
    if (
        manifest["fmu"]["sha256"] != matrix["fmu_sha256"]
        or manifest["boptest_commit"] != matrix["boptest_commit"]
    ):
        raise ValueError("Unexpected reference version")
    for name in (filename, "signals.json"):
        if sha256((run / name).read_bytes()) != manifest["artifacts"][name]:
            raise ValueError("Reference artifact hash mismatch: " + name)
    with (run / filename).open(newline="") as stream:
        headers = next(csv.reader(stream))
    if len(headers) != len(set(headers)):
        raise ValueError("Duplicate source columns")
    data = np.genfromtxt(run / filename, delimiter=",", names=True, deletechars="")
    units = {s["name"]: s["unit"] for s in json.loads((run / "signals.json").read_bytes())}
    return manifest, data, units


def inventory(run: Path) -> dict[str, Any]:
    manifest, data, units = reference_run(run)
    t = data["time_s"]
    if not np.isfinite(t).all() or np.any(np.diff(t) <= 0):
        raise ValueError("Invalid reference time grid")
    return {
        "scenario": manifest["scenario"],
        "fmu": manifest["fmu"],
        "boptest_commit": manifest["boptest_commit"],
        "ideas_commit": manifest["ideas_commit"],
        "manifest_sha256": sha256((run / "manifest.json").read_bytes()),
        "sample_count": len(t),
        "start_s": float(t[0]),
        "end_s": float(t[-1]),
        "sampling": manifest["sampling"],
        "signals": units,
        "initial_snapshots": manifest["initialized_internal_values"],
        "missing": [
            "six absorbed interior solar powers",
            "complete consistent fabric/moist-air state",
        ],
        "readiness": "partial_forcing_available_not_reference_validation",
    }


def prepare(run: Path, output: Path, *, partial: bool = False) -> dict[str, Any]:
    manifest, data, units = reference_run(run)
    if not partial:
        raise ValueError(
            "Full replay blocked: absorbed solar and complete initial states missing; "
            "use explicit --partial"
        )
    registry_raw = (ROOT / REGISTRY).read_bytes()
    if sha256(registry_raw) != REGISTRY_HASH:
        raise ValueError("Frozen registry changed")
    registry = read_json(registry_raw)
    declared_start = next(
        p["value"] for p in registry["parameters"] if p["id"] == "building.initial_temperature"
    )
    t = np.asarray(data["time_s"], dtype=float)
    scenario = manifest["scenario"]
    if t[0] != scenario["initialization_time_s"] or t[-1] != scenario["evaluation_end_s"]:
        raise ValueError("Replay requires full warm-up trajectory and exact period coverage")
    channels: list[dict[str, Any]] = []
    values = []
    for index, (source, quantity, unit, sign, policy) in enumerate(INPUTS, start=1):
        if source not in data.dtype.names or source not in units:
            raise ValueError("Required forcing unavailable or wrong unit: " + source)
        try:
            canonical = convert(np.asarray(data[source], dtype=float), units[source], unit)
        except ValueError as error:
            raise ValueError("Required forcing unavailable or wrong unit: " + source) from error
        series = Series(
            t,
            np.asarray(canonical * sign, dtype=float),
            unit,
            quantity,
            policy,
            scenario["name"],
            manifest["fmu"]["sha256"],
            manifest["boptest_commit"],
            sha256((run / "trajectory.csv").read_bytes()),
            max_gap_s=30,
        )
        values.append(series.values)
        channels.append(
            {
                "column": f"input_{index:02d}",
                "quantity": quantity,
                "unit": unit,
                "interpolation": policy,
                "source": source,
                "source_unit": units[source],
                "sign_multiplier": sign,
                "status": "reference",
            }
        )
    for index in range(6, 12):
        values.append(np.zeros_like(t))
        channels.append(
            {
                "column": f"input_{index:02d}",
                "quantity": f"omitted_absorbed_solar_{index - 5}",
                "unit": "W",
                "interpolation": "previous",
                "source": None,
                "status": "explicitly_omitted_in_partial_experiment_not_reference_zero",
                "sign_multiplier": 0,
            }
        )
    metadata = {
        "schema_version": 1,
        "status": "partial_replay_ready",
        "classification": "exploratory_comparison",
        "scenario_id": scenario["name"] + "__partial_no_solar_uniform_start",
        "reference_scenario_id": scenario["name"],
        "reference_version": manifest["boptest_commit"],
        "reference_manifest_sha256": sha256((run / "manifest.json").read_bytes()),
        "source_trajectory_sha256": sha256((run / "trajectory.csv").read_bytes()),
        "source_signals_sha256": sha256((run / "signals.json").read_bytes()),
        "source_fmu_sha256": manifest["fmu"]["sha256"],
        "source_scenario": scenario,
        "time_origin_s": float(t[0]),
        "duration_s": float(t[-1] - t[0]),
        "evaluation_start_s": scenario["evaluation_start_s"],
        "evaluation_end_s": scenario["evaluation_end_s"],
        "channels": channels,
        "initial_conditions": {
            "status": "provisional_uniform_declared_start_not_full_FMU_state",
            "temperature_K": [declared_start] * 28,
            "source": "frozen building.initial_temperature",
        },
        "missing_inputs": [
            "six absorbed interior solar powers",
            "complete initialized reference state vector",
        ],
        "assumptions": [
            "Solar power omitted explicitly, not inferred zero.",
            "Uniform 293.15 K start is a declared reduced experiment, not an FMU restart.",
            "Full seven-day warm-up retained; no evaluation-start reset.",
            "Outdoor temperature linear, gains previous hold; unknown sub-30s events unresolved.",
        ],
        "limitations": [
            "Reduced C2 moist-air/surface/glazing physics differs from reference.",
            "Prescribed radiator heat removes equipment feedback; heating is not predicted.",
        ],
    }
    output.mkdir(parents=True, exist_ok=False)
    np.savetxt(
        output / "inputs.csv",
        np.column_stack([t - t[0], *values]),
        delimiter=",",
        header=",".join(["time_s", *[c["column"] for c in channels]]),
        comments="",
        fmt="%.17g",
    )
    metadata["inputs_sha256"] = sha256((output / "inputs.csv").read_bytes())
    (output / "replay.json").write_text(json.dumps(metadata, indent=2, allow_nan=False) + "\n")
    return metadata


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check-matrix", action="store_true")
    parser.add_argument("--inventory", type=Path)
    parser.add_argument("--run", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--partial", action="store_true")
    args = parser.parse_args()
    if args.check_matrix:
        print(f"Signal mappings checked: {len(validate_matrix()['signals'])}")
    elif args.inventory:
        print(json.dumps(inventory(args.inventory), indent=2))
    elif args.run and args.output:
        print(prepare(args.run, args.output, partial=args.partial)["status"])
    else:
        parser.error("Use --check-matrix, --inventory RUN, or --run RUN --output NEW_DIR --partial")


if __name__ == "__main__":
    main()
