"""Pinned IDEAS solar distribution and observable-state contracts, not a solver."""

from __future__ import annotations

import argparse
import json
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Any
from zipfile import ZipFile

import numpy as np
from numpy.typing import NDArray

from therma.validation.archive import sha256
from therma.validation.replay import INPUTS, prepare, reference_run, validate_matrix

PREFIX = "mod.case900Template.radDistr."
SURFACES = ["south", "west", "north", "east", "floor", "roof", "glazing"]
C2_ORDER = ["south", "north", "east", "west", "roof", "floor"]
C2_INDICES = [0, 2, 3, 1, 5, 4]
OPAQUE_VRS = [
    [2022, 2021, 2023, 2025, 2024],
    [2032, 2031, 2033, 2035, 2034],
    [2037, 2036, 2038, 2040, 2039],
    [2027, 2026, 2028, 2030, 2029],
    [2042, 2041, 2043, 2044],
    [2019, 2018, 2020],
]
SOLAR_NAMES = [PREFIX + n for n in ["iSolDir.Q_flow", "iSolDif.Q_flow", "radGain.Q_flow"]]
SOLAR_NAMES += [
    PREFIX + f"{group}[{i}]"
    for group in ["weightFactorDir", "weightFactorDif", "weightFactorGain"]
    for i in range(1, 8)
]
SOLAR_NAMES += [PREFIX + f"radSurfTot[{i}].Q_flow" for i in range(1, 8)]


def catalog(fmu: Path) -> dict[str, Any]:
    """Resolve one-based FMI derivative indices; retain original names and units."""
    with ZipFile(fmu) as archive:
        raw = archive.read("modelDescription.xml")
    root = ET.fromstring(raw)
    variables = list(root.find("ModelVariables"))  # type: ignore[arg-type]
    derivatives = root.findall("ModelStructure/Derivatives/Unknown")
    states = []
    for entry in derivatives:
        derivative = variables[int(entry.attrib["index"]) - 1].find("Real")
        assert derivative is not None
        states.append(variables[int(derivative.attrib["derivative"]) - 1].attrib["name"])
    names = list(dict.fromkeys(SOLAR_NAMES + states + ["mod.case900Template.TAir"]))
    by_name = {v.attrib["name"]: v for v in variables}
    rows: list[dict[str, Any]] = []
    for name in names:
        v = by_name[name]
        real = v.find("Real")
        if real is None:
            raise ValueError("Expected Real: " + name)
        unit = real.get("unit", "1")
        expected = "1" if "weightFactor" in name else ("W" if name in SOLAR_NAMES else None)
        if expected and unit != expected:
            raise ValueError("Wrong source unit: " + name)
        rows.append(
            {
                "name": name,
                "unit": unit,
                "value_reference": int(v.attrib["valueReference"]),
                "declared_state": name in states,
                "state_index": states.index(name) + 1 if name in states else None,
            }
        )
    if {int(by_name[n].attrib["valueReference"]) for n in states} != set(range(2016, 2055)):
        raise ValueError("Pinned state ordering/value references differ")
    if len(states) != 39:
        raise ValueError("Pinned state count differs")
    mapping = []
    for face, refs in zip(C2_ORDER, OPAQUE_VRS, strict=True):
        for vr in refs:
            row = next(r for r in rows if r["value_reference"] == vr)
            if row["unit"] != "K":
                raise ValueError("Opaque state must be Kelvin")
            mapping.append({"face": face, **row})
    for row in rows:
        if row["declared_state"]:
            vr = row["value_reference"]
            expected = (
                "K"
                if vr <= 2044
                else ("kg" if 2046 <= vr <= 2048 else ("1" if vr == 2054 else "J"))
            )
            if row["unit"] != expected:
                raise ValueError("Incorrect state dimension: " + row["name"])
    cs = root.find("CoSimulation")
    assert cs is not None
    return {
        "variables": rows,
        "state_names": states,
        "c2_opaque_mapping": mapping,
        "model_description_sha256": sha256(raw),
        "restorable_fmu_state": False,
        "capabilities": cs.attrib,
    }


def distribution(data: Any, units: dict[str, str]) -> tuple[NDArray[np.float64], dict[str, Any]]:
    """Verify independent direct/diffuse sums and combined source-port equation."""
    if any(units.get(n) != ("1" if "weightFactor" in n else "W") for n in SOLAR_NAMES):
        raise ValueError("Missing solar signal or incorrect units")
    arrays = [np.asarray(data[n], dtype=float) for n in SOLAR_NAMES]
    if not np.isfinite(arrays).all():
        raise ValueError("Non-finite solar inputs")
    direct, diffuse, gains = arrays[:3]
    wd, wf, wg = (np.column_stack(arrays[a : a + 7]) for a in [3, 10, 17])
    combined = np.column_stack(arrays[24:31])
    for weights in [wd, wf, wg]:
        if np.any(weights < 0) or not np.allclose(weights.sum(axis=1), 1, atol=1e-12, rtol=0):
            raise ValueError("Invalid seven-surface weights")
        if not np.array_equal(weights, np.broadcast_to(weights[0], weights.shape)):
            raise ValueError("Expected fixed distribution weights")
    if np.min(direct) < -1e-8 or np.min(diffuse) < -1e-8:
        raise ValueError("Unexpected solar sign; no clamping permitted")
    solar_direct = wd * direct[:, None]
    solar_diffuse = wf * diffuse[:, None]
    solar = solar_direct + solar_diffuse
    residual = combined + solar + wg * gains[:, None]
    if not np.allclose(residual, 0, atol=1e-7, rtol=0):
        raise ValueError("Combined distribution equation mismatch / double-counted gains")
    if not np.allclose(solar.sum(axis=1), direct + diffuse, atol=1e-7, rtol=0):
        raise ValueError("Solar energy conservation failed")
    return solar, {
        "status": "passed",
        "surface_order": SURFACES,
        "max_distribution_residual_W": float(np.max(np.abs(residual))),
        "max_direct_sum_residual_W": float(np.max(np.abs(solar_direct.sum(axis=1) - direct))),
        "max_diffuse_sum_residual_W": float(np.max(np.abs(solar_diffuse.sum(axis=1) - diffuse))),
        "max_solar_sum_residual_W": float(np.max(np.abs(solar.sum(axis=1) - direct - diffuse))),
        "direct_weights": wd[0].tolist(),
        "diffuse_weights": wf[0].tolist(),
        "gain_weights": wg[0].tolist(),
    }


def validate_observation(observation: dict[str, Any], scenario: dict[str, Any]) -> None:
    """Snapshots are observations in original state order, never restart instructions."""
    rows = observation["variables"]
    states = [r for r in rows if r.get("declared_state")]
    if (
        len(states) != 39
        or [r["name"] for r in states] != observation["state_names"]
        or [r["value_reference"] for r in states] != list(range(2016, 2055))
        or observation.get("restorable_fmu_state") is not False
    ):
        raise ValueError("Invalid observable state ordering or restart claim")
    expected_mapping = [v for refs in OPAQUE_VRS for v in refs]
    if [r["value_reference"] for r in observation["c2_opaque_mapping"]] != expected_mapping:
        raise ValueError("Incorrect C2 thermal state mapping")
    for r in states:
        vr = r["value_reference"]
        unit = "K" if vr <= 2044 else ("kg" if 2046 <= vr <= 2048 else ("1" if vr == 2054 else "J"))
        if r["unit"] != unit:
            raise ValueError("Incorrect observed state dimension")
    snapshots = observation["snapshots"]
    if len(snapshots) != 2:
        raise ValueError("Two state snapshots required")
    for snapshot, label, time in zip(
        snapshots,
        ["initialized", "evaluation_start"],
        [scenario["initialization_time_s"], scenario["evaluation_start_s"]],
        strict=True,
    ):
        if snapshot["label"] != label or snapshot["time_s"] != time:
            raise ValueError("State snapshot time/identity mismatch")
        values = snapshot["values"]
        for row in rows:
            value = values[row["name"]]
            if not np.isfinite(value) or (row["unit"] == "K" and value <= 0):
                raise ValueError("Invalid observed state value")


def prepare_solar(run: Path, baseline: Path, output: Path) -> dict[str, Any]:
    """New v2 packet; original v1 implementation and baseline files stay untouched."""
    manifest, data, units = reference_run(run)
    old, old_data, _ = reference_run(baseline)
    if manifest["scenario"] != old["scenario"] or manifest["ideas_commit"] != old["ideas_commit"]:
        raise ValueError("Reference scenario identity mismatch")
    t = np.asarray(data["time_s"], dtype=float)
    if not np.array_equal(t, old_data["time_s"]) or not np.all(np.diff(t) == 30):
        raise ValueError("Missing, duplicate or inconsistent timestamps")
    # Compare every common baseline channel, not just the five replay forcings.
    differences = {
        n: float(np.max(np.abs(data[n] - old_data[n])))
        for n in old_data.dtype.names
        if n != "time_s" and n in data.dtype.names
    }
    if set(old_data.dtype.names) - set(data.dtype.names):
        raise ValueError("Baseline signal missing")
    if any(v > 1e-7 for v in differences.values()):
        raise ValueError("Observed baseline changed; inspect native runtime/provenance")
    solar, checks = distribution(data, units)
    observation = manifest.get("solar_observability")
    if not observation or len(observation["snapshots"]) != 2:
        raise ValueError("Initialized and evaluation-start state snapshots required")
    validate_observation(observation, manifest["scenario"])
    initial = observation["snapshots"][0]
    mapping = observation["c2_opaque_mapping"]
    temperatures = [initial["values"][r["name"]] for r in mapping]
    temperatures.append(initial["values"]["mod.case900Template.TAir"])
    if len(temperatures) != 28 or not np.allclose(temperatures, 293.15, atol=1e-10, rtol=0):
        raise ValueError("Current C2 uniform-start runner cannot represent source initial state")
    # Reuse all unchanged base-channel conversions then replace only explicit solar slots.
    metadata = prepare(run, output, partial=True)
    values = np.loadtxt(output / "inputs.csv", delimiter=",", skiprows=1)
    values[:, 6:12] = solar[:, C2_INDICES]
    np.savetxt(
        output / "inputs.csv",
        values,
        delimiter=",",
        comments="",
        fmt="%.17g",
        header=",".join(["time_s", *[c["column"] for c in metadata["channels"]]]),
    )
    supplemental = np.column_stack([t, *solar.T])
    np.savetxt(
        output / "solar_seven.csv",
        supplemental,
        delimiter=",",
        comments="",
        fmt="%.17g",
        header=",".join(["time_s", *SURFACES]),
    )
    np.savetxt(
        output / "solar_sources.csv",
        np.column_stack([t, *[data[n] for n in SOLAR_NAMES]]),
        delimiter=",",
        comments="",
        fmt="%.17g",
        header=",".join(["time_s", *SOLAR_NAMES]),
    )
    for i, face in enumerate(C2_ORDER, 6):
        channel = metadata["channels"][i - 1]
        channel.update(
            quantity=f"absorbed_solar_{face}_power",
            source="source-equation derivation",
            status="derived_reference",
            sign_multiplier=1,
        )
    metadata.update(
        schema_version=2,
        replay_mode="solar_resolved_partial",
        scenario_id=manifest["scenario"]["name"] + "__partial_solar_resolved_uniform_start",
        inputs_sha256=sha256((output / "inputs.csv").read_bytes()),
        solar_seven_sha256=sha256((output / "solar_seven.csv").read_bytes()),
        solar_sources_sha256=sha256((output / "solar_sources.csv").read_bytes()),
        solar_surface_order=SURFACES,
        c2_solar_order=C2_ORDER,
        solar_checks=checks,
        solar_observability=observation,
        baseline_manifest_sha256=sha256((baseline / "manifest.json").read_bytes()),
        baseline_max_differences=differences,
        missing_inputs=[
            "dynamic glazing and exterior-boundary equivalence",
            "complete portable FMU restart (unsupported)",
        ],
    )
    metadata["assumptions"][0] = (
        "Six source-derived opaque solar powers; glazing share separate, never redistributed."
    )
    metadata["initial_conditions"]["observed_temperature_K"] = temperatures
    metadata["initial_conditions"]["source"] += (
        "; confirmed against actual initialized source states"
    )
    metadata["solar_signals"] = [r for r in observation["variables"] if r["name"] in SOLAR_NAMES]
    (output / "replay.json").write_text(json.dumps(metadata, indent=2, allow_nan=False) + "\n")
    verify_packet(output)
    return metadata


def verify_packet(folder: Path) -> dict[str, Any]:
    """Independently re-read a packet and reject schema/algebra/provenance drift."""
    m = json.loads((folder / "replay.json").read_text())
    matrix = validate_matrix()
    if (
        m.get("schema_version") != 2
        or m.get("replay_mode") != "solar_resolved_partial"
        or m["c2_solar_order"] != C2_ORDER
        or m["solar_surface_order"] != SURFACES
    ):
        raise ValueError("Invalid schema or surface order")
    if (
        m["source_fmu_sha256"] != matrix["fmu_sha256"]
        or m["reference_version"] != matrix["boptest_commit"]
        or m["reference_scenario_id"] != m["source_scenario"]["name"]
        or m["scenario_id"] != m["reference_scenario_id"] + "__partial_solar_resolved_uniform_start"
    ):
        raise ValueError("Reference identity mismatch")
    for filename, key in [
        ("inputs.csv", "inputs_sha256"),
        ("solar_seven.csv", "solar_seven_sha256"),
        ("solar_sources.csv", "solar_sources_sha256"),
    ]:
        if sha256((folder / filename).read_bytes()) != m[key]:
            raise ValueError("Packet hash mismatch: " + filename)

    def read(filename: str, headers: list[str]) -> Any:
        with (folder / filename).open() as stream:
            if stream.readline().strip().split(",") != headers:
                raise ValueError("Incorrect column order: " + filename)
        return np.genfromtxt(folder / filename, delimiter=",", names=True, deletechars="")

    inputs = read("inputs.csv", ["time_s", *[f"input_{i:02d}" for i in range(1, 12)]])
    seven = read("solar_seven.csv", ["time_s", *SURFACES])
    sources = read("solar_sources.csv", ["time_s", *SOLAR_NAMES])
    t = inputs["time_s"]
    if (
        not np.isfinite(t).all()
        or t[0] != 0
        or t[-1] != m["duration_s"]
        or not np.all(np.diff(t) == 30)
        or not np.array_equal(t + m["time_origin_s"], sources["time_s"])
        or not np.array_equal(sources["time_s"], seven["time_s"])
    ):
        raise ValueError("Invalid timestamps/coverage")
    scenario = m["source_scenario"]
    if (
        m["time_origin_s"] != scenario["initialization_time_s"]
        or m["evaluation_start_s"] != scenario["evaluation_start_s"]
        or m["evaluation_end_s"] != scenario["evaluation_end_s"]
        or m["evaluation_end_s"] != m["time_origin_s"] + m["duration_s"]
        or not m["time_origin_s"] < m["evaluation_start_s"] < m["evaluation_end_s"]
    ):
        raise ValueError("Invalid warm-up/evaluation bounds")
    validate_observation(m["solar_observability"], scenario)
    rows = m["solar_signals"]
    expected_vrs = [
        2509,
        2510,
        2511,
        1601,
        1602,
        1603,
        1604,
        1348,
        1605,
        1606,
        *range(1511, 1525),
        *range(2512, 2519),
    ]
    if [r["value_reference"] for r in rows] != expected_vrs:
        raise ValueError("Pinned FMI value reference mismatch")
    if [r["name"] for r in rows] != SOLAR_NAMES:
        raise ValueError("Source name order mismatch")
    solar, checks = distribution(sources, {r["name"]: r["unit"] for r in rows})
    for i, face in enumerate(SURFACES):
        if not np.allclose(seven[face], solar[:, i], atol=1e-8, rtol=0):
            raise ValueError("Solar derivation/glazing preservation mismatch")
    if len(m["channels"]) != 11:
        raise ValueError("Incorrect channel count")
    for i, c in enumerate(m["channels"], 1):
        expected = INPUTS[i - 1][1] if i <= 5 else f"absorbed_solar_{C2_ORDER[i - 6]}_power"
        if (
            c["column"] != f"input_{i:02d}"
            or c["quantity"] != expected
            or c["unit"] != ("K" if i == 1 else "W")
            or c["interpolation"] != ("linear" if i == 1 else "previous")
            or not np.isfinite(inputs[c["column"]]).all()
        ):
            raise ValueError("Incorrect channel units/order/interpolation or nonfinite values")
        if i > 5 and not np.allclose(
            inputs[c["column"]], solar[:, C2_INDICES[i - 6]], atol=1e-8, rtol=0
        ):
            raise ValueError("Opaque channel mapping mismatch")
    evaluation = sources["time_s"] >= m["evaluation_start_s"]
    dt = np.diff(sources["time_s"][evaluation])
    checks["evaluation_solar_hold_energy_J"] = {
        face: float(np.sum(dt * solar[evaluation, i][:-1])) for i, face in enumerate(SURFACES)
    }
    checks["samples"] = len(t)
    checks["interpretation"] = "30 s held reconstruction, not exact continuous FMU energy"
    return checks


def report_packet(folder: Path, output: Path, *, plots: bool = True) -> dict[str, Any]:
    """Actual reference-only diagnostics; never invent solar-resolved THERMA outputs."""
    checks = verify_packet(folder)
    m = json.loads((folder / "replay.json").read_text())
    result = {
        "status": "reference_extracted_verified_MATLAB_replay_pending",
        "checks": checks,
        "reference_manifest_sha256": m["reference_manifest_sha256"],
        "baseline_manifest_sha256": m["baseline_manifest_sha256"],
        "baseline_max_difference": max(m["baseline_max_differences"].values()),
        "state_observability": m["solar_observability"],
        "artifacts": {p.name: sha256(p.read_bytes()) for p in folder.iterdir() if p.is_file()},
        "solar_resolved_MATLAB_metrics": None,
        "limitations": [
            "Opaque solar only; glazing remains a separate unmodeled receiver.",
            "No portable FMU restart. Initial-temperature mapping is not state restoration.",
            "Solar-resolved THERMA execution/comparison and solver sensitivity pending.",
            "Power integrals reconstruct 30-second held samples, not continuous FMU energy.",
        ],
    }
    output.mkdir(parents=True, exist_ok=False)
    if plots:
        from therma.validation.analysis import _pyplot

        plt = _pyplot(output)
        data = np.loadtxt(folder / "solar_seven.csv", delimiter=",", skiprows=1)
        selected = data[:, 0] >= m["evaluation_start_s"]
        days = (data[selected, 0] - m["evaluation_start_s"]) / 86400
        fig, axes = plt.subplots(2, 1, figsize=(10, 6), sharex=True)
        for i, face in enumerate(SURFACES):
            ax = axes[1] if face == "glazing" else axes[0]
            ax.plot(days, data[selected, i + 1], label=face, lw=0.7)
        for ax in axes:
            ax.set(ylabel="Source solar allocation (W)")
            ax.grid(alpha=0.25)
            ax.legend(ncol=3)
        axes[1].set(
            xlabel="Evaluation day", title="Glazing share retained separately; not redistributed"
        )
        fig.tight_layout()
        for suffix in ["png", "pdf"]:
            fig.savefig(output / f"reference_solar_allocations.{suffix}", dpi=300)
        plt.close(fig)
        fig, ax = plt.subplots(figsize=(10, 4))
        observation = m["solar_observability"]
        for snap in observation["snapshots"]:
            y = [snap["values"][r["name"]] for r in observation["c2_opaque_mapping"]]
            ax.plot(range(1, 28), y, marker=".", label=snap["label"])
        ax.set(xlabel="C2 ordered opaque state index", ylabel="Observed source temperature (K)")
        ax.grid(alpha=0.25)
        ax.legend()
        fig.tight_layout()
        for suffix in ["png", "pdf"]:
            fig.savefig(output / f"reference_state_snapshots.{suffix}", dpi=300)
        plt.close(fig)
    (output / "reference_checks.json").write_text(
        json.dumps(result, indent=2, allow_nan=False) + "\n"
    )
    (output / "engineering_summary.md").write_text(
        "# Actual solar reference extraction (not THERMA validation)\n\n"
        "The original FMU was executed without overrides on its original 30 s grid. "
        "Common baseline channels match exactly. All seven source solar allocations "
        "are preserved; only six opaque powers enter the new replay packet.\n\n"
        "The existing no-solar MAE 2.34053 K and bias -2.33520 K remain exploratory. "
        "Missing solar is a plausible contributor, not a quantified explanation. "
        "Initial opaque temperatures already match 293.15 K. Glazing, exterior "
        "exchange and moist-air differences remain. No solar-resolved MATLAB run "
        "or improvement measurement exists yet.\n\n" + json.dumps(checks, indent=2) + "\n"
    )
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run", type=Path)
    parser.add_argument("--verify", type=Path)
    parser.add_argument("--report", type=Path)
    parser.add_argument("--baseline", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if args.verify:
        result = (
            report_packet(args.verify, args.report) if args.report else verify_packet(args.verify)
        )
        print(json.dumps(result if not args.report else result["checks"], indent=2))
    elif args.run and args.baseline and args.output:
        print(prepare_solar(args.run, args.baseline, args.output)["scenario_id"])
    else:
        parser.error("Use --verify PACKET or --run RUN --baseline ORIGINAL --output NEW")


if __name__ == "__main__":
    main()
