"""Normalize verified Phase B data; no model simulation or validation claim.

Outputs retain original model seconds, source manifest, signal metadata and hashes.
Power uses explicit previous holds; temperature uses explicit linear reconstruction.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

import numpy as np

from therma.comparison import Series

MAPPING = {
    "reaTRoo_y": ("operative_temperature", "K", 1, "linear"),
    "mod.case900Template.TAir": ("air_temperature", "K", 1, "linear"),
    "mod.case900Template.TRad": ("radiative_temperature", "K", 1, "linear"),
    "weaSta_reaWeaTDryBul_y": ("outdoor_temperature", "K", 1, "linear"),
    "reaQHea_y": ("gas_input_power", "W", 1, "previous"),
    "reaPPum_y": ("pump_electrical_power", "W", 1, "previous"),
    "mod.rad.QCon_flow": ("delivered_heating_convective_power", "W", -1, "previous"),
    "mod.rad.QRad_flow": ("delivered_heating_radiative_power", "W", -1, "previous"),
    "mod.case900Template.intGaiOcc.portCon.Q_flow": (
        "internal_convective_power",
        "W",
        -1,
        "previous",
    ),
    "mod.case900Template.intGaiOcc.portRad.Q_flow": (
        "internal_radiative_power",
        "W",
        -1,
        "previous",
    ),
}


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def normalize(run: Path, output: Path) -> dict:
    manifest = json.loads((run / "manifest.json").read_text())
    if manifest["status"] != "success" or not manifest["source_fmu_unchanged"]:
        raise ValueError("Source run was not successful/unchanged")
    for name in ("evaluation.csv", "signals.json"):
        if digest(run / name) != manifest["artifacts"][name]:
            raise ValueError("Source artifact hash mismatch: " + name)
    definitions = json.loads((run / "signals.json").read_text())
    units = {s["name"]: s["unit"] for s in definitions}
    data = np.genfromtxt(run / "evaluation.csv", delimiter=",", names=True, deletechars="")
    names = data.dtype.names
    assert names is not None
    missing = [name for name in MAPPING if name not in names]
    metadata = {
        "schema_version": 1,
        "status": "normalized_reference_only_no_THERMA_comparison",
        "scenario": manifest["scenario"],
        "scenario_id": manifest["scenario"]["name"],
        "model_version": manifest["fmu"]["sha256"],
        "reference_version": manifest["boptest_commit"],
        "source_manifest_sha256": digest(run / "manifest.json"),
        "source_manifest": manifest,
        "source_signals": definitions,
        "missing_signals": missing,
        "signals": [],
        "limitations": [
            "Power hold policy differs from Phase B's sampled trapezoidal power integrals.",
            "Unknown between-sample events are not recovered; sampling sensitivity remains.",
            "C2 reduced model lacks exact reference surface/optical/moist-air physics.",
        ],
    }
    columns = [data["time_s"]]
    headers = ["time_s"]
    for source, (quantity, unit, sign, policy) in MAPPING.items():
        if source in missing:
            continue
        if units[source] != unit:
            raise ValueError("Unexpected source units: " + source)
        series = Series(
            data["time_s"],
            sign * data[source],
            unit,
            quantity,
            policy,
            manifest["scenario"]["name"],
            manifest["fmu"]["sha256"],
            manifest["boptest_commit"],
            digest(run / "evaluation.csv"),
            max_gap_s=30,
        )
        if series.time_s[0] != manifest["scenario"]["evaluation_start_s"] or (
            series.time_s[-1] != manifest["scenario"]["evaluation_end_s"]
        ):
            raise ValueError("Evaluation coverage disagrees with scenario")
        columns.append(series.values)
        headers.append(quantity)
        metadata["signals"].append(
            {
                "quantity": quantity,
                "unit": unit,
                "source_name": source,
                "sign_multiplier": sign,
                "interpolation": policy,
            }
        )
    output.mkdir(parents=True, exist_ok=False)
    np.savetxt(
        output / "normalized.csv",
        np.column_stack(columns),
        delimiter=",",
        header=",".join(headers),
        comments="",
        fmt="%.17g",
    )
    metadata["csv_sha256"] = digest(output / "normalized.csv")
    (output / "metadata.json").write_text(json.dumps(metadata, indent=2, allow_nan=False) + "\n")
    return metadata


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("run", type=Path)
    parser.add_argument("output", type=Path, help="New local directory, normally under outputs/")
    args = parser.parse_args()
    metadata = normalize(args.run, args.output)
    print(
        json.dumps({"status": metadata["status"], "missing_signals": metadata["missing_signals"]})
    )


if __name__ == "__main__":
    main()
