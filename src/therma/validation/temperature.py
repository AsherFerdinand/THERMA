"""C2.8 extraction of existing, hash-verified BOPTEST temperatures; no simulation."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Any

import numpy as np
from numpy.typing import NDArray

from therma.comparison import Series, convert, resample
from therma.validation.analysis import file_hash, numeric_columns
from therma.validation.benchmark import metrics
from therma.validation.replay import reference_run

AIR = "mod.case900Template.TAir"
OPERATIVE = "reaTRoo_y"
START, END, ORIGIN = 28857600, 30067200, 28252800


def aligned_errors(candidate: Series, reference: Series) -> dict[str, float]:
    """Reuse semantic/unit/interpolation contracts on the native reference grid."""
    if candidate.quantity != "air_temperature" or reference.quantity != "air_temperature":
        raise ValueError("Like-for-like metrics require air temperature, not operative temperature")
    if candidate.reference_version != reference.reference_version:
        raise ValueError("Reference versions differ")
    if candidate.scenario != reference.scenario:
        raise ValueError("Scenarios differ")
    values = convert(resample(candidate, reference.time_s), candidate.unit, "K")
    return metrics(values - convert(reference.values, reference.unit, "K"))


def check_grid(time: NDArray[np.float64], *, step: float = 30) -> None:
    if (
        time.ndim != 1
        or len(time) != int((END - START) / step) + 1
        or not np.isfinite(time).all()
        or time[0] != START
        or time[-1] != END
        or not np.all(np.diff(time) == step)
    ):
        raise ValueError(
            "Incomplete/duplicate/nonfinite reference grid or incorrect evaluation interval"
        )


def read_reference(folder: Path) -> Series:
    """Parse the portable reference strictly; operative data never supplies air metrics."""
    metadata = json.loads((folder / "reference_metadata.json").read_text())
    path = folder / "reference_temperature.csv"
    if file_hash(path) != metadata["csv_sha256"]:
        raise ValueError("Reference CSV hash mismatch")
    signals = [s for s in metadata["signals"] if s["quantity"] == "air_temperature"]
    if len(signals) != 1 or signals[0]["source"] != AIR or signals[0]["unit"] != "K":
        raise ValueError("Reference requires the original air temperature in K")
    t, values = numeric_columns(path, [signals[0]["column"]])
    check_grid(t)
    if metadata["time_basis"] != "absolute_simulation_seconds":
        raise ValueError("Reference time basis must be absolute")
    return Series(
        t,
        values[signals[0]["column"]],
        "K",
        "air_temperature",
        "linear",
        metadata["scenario"]["name"],
        "BOPTEST",
        metadata["boptest_commit"],
        metadata["csv_sha256"],
        30,
    )


def extract(
    run: Path, packet: Path, output: Path, equivalent_run: Path | None = None
) -> dict[str, Any]:
    """Bind extraction to the original replay's exact manifest/trajectory/signals."""
    replay = json.loads(packet.read_text())
    manifest, data, units = reference_run(run)
    for name, field in [
        ("manifest.json", "reference_manifest_sha256"),
        ("trajectory.csv", "source_trajectory_sha256"),
        ("signals.json", "source_signals_sha256"),
    ]:
        if file_hash(run / name) != replay[field]:
            raise ValueError("Original replay source mismatch: " + name)
    scenario = manifest["scenario"]
    if (
        scenario != replay["source_scenario"]
        or scenario["name"] != "typical_heat_day"
        or scenario["initialization_time_s"] != ORIGIN
        or scenario["evaluation_start_s"] != START
        or scenario["evaluation_end_s"] != END
        or scenario["reset_at_evaluation_start"] is not False
    ):
        raise ValueError("Scenario/warm-up identity mismatch")
    time = data["time_s"]
    if time[0] != ORIGIN or time[-1] != END or not np.all(np.diff(time) == 30):
        raise ValueError("Original trajectory incomplete or irregular")
    mask = (time >= START) & (time <= END)
    t = time[mask]
    check_grid(t)
    columns = ["time_s"]
    arrays = [t]
    signals = []
    for source, column, quantity in [
        (AIR, "air_temperature_K", "air_temperature"),
        (OPERATIVE, "operative_temperature_K", "operative_temperature"),
    ]:
        if source not in data.dtype.names:
            continue
        if units[source] != "K" or not np.isfinite(data[source]).all():
            raise ValueError("Nonfinite or incorrect reference temperature units")
        columns.append(column)
        arrays.append(data[source][mask])
        signals.append(dict(column=column, source=source, quantity=quantity, unit="K"))
    if not signals:
        raise ValueError("No genuine temperature signal is available")
    compatible = [
        {
            "manifest_sha256": file_hash(run / "manifest.json"),
            "trajectory_sha256": file_hash(run / "trajectory.csv"),
            "signals_sha256": file_hash(run / "signals.json"),
            "basis": "Original replay source",
        }
    ]
    if equivalent_run is not None:
        other, extra, extra_units = reference_run(equivalent_run)
        common = list(data.dtype.names)
        if other["scenario"] != scenario or any(
            name not in extra.dtype.names
            or not np.array_equal(data[name], extra[name])
            or (name != "time_s" and units[name] != extra_units[name])
            for name in common
        ):
            raise ValueError("Extended extraction does not reproduce all original channels exactly")
        compatible.append(
            {
                "manifest_sha256": file_hash(equivalent_run / "manifest.json"),
                "trajectory_sha256": file_hash(equivalent_run / "trajectory.csv"),
                "signals_sha256": file_hash(equivalent_run / "signals.json"),
                "basis": (
                    f"Exact numerical equality of all {len(common)} original columns "
                    "over full 21 days"
                ),
            }
        )
    output.mkdir(parents=True, exist_ok=False)
    csv_file = output / "reference_temperature.csv"
    with csv_file.open("w", newline="") as stream:
        writer = csv.writer(stream, lineterminator="\n")
        writer.writerow(columns)
        writer.writerows(zip(*([format(v, ".17g") for v in a] for a in arrays), strict=True))
    metadata = {
        "schema_version": 1,
        "compatible_reference_sources": compatible,
        "status": "genuine_reference_extracted_not_C28_validation",
        "scenario": scenario,
        "boptest_commit": manifest["boptest_commit"],
        "ideas_commit": manifest["ideas_commit"],
        "fmu_sha256": manifest["fmu"]["sha256"],
        "source_manifest_sha256": file_hash(run / "manifest.json"),
        "source_trajectory_sha256": file_hash(run / "trajectory.csv"),
        "source_signals_sha256": file_hash(run / "signals.json"),
        "replay_packet_sha256": file_hash(packet),
        "csv_sha256": file_hash(csv_file),
        "time_unit": "s",
        "time_basis": "absolute_simulation_seconds",
        "sample_count": len(t),
        "sampling_s": 30,
        "signals": signals,
        "method": "Select original 30 s samples, exclude warm-up; no resampling or FMU rerun",
        "MATLAB_execution_in_cloud": False,
    }
    for name in ["manifest.json", "signals.json"]:
        (output / ("source_" + name)).write_bytes((run / name).read_bytes())
    if equivalent_run is not None:
        (output / "equivalent_manifest.json").write_bytes(
            (equivalent_run / "manifest.json").read_bytes()
        )
        (output / "equivalent_signals.json").write_bytes(
            (equivalent_run / "signals.json").read_bytes()
        )
    (output / "reference_metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")
    if AIR in data.dtype.names:
        restored = read_reference(output)
        if not np.array_equal(restored.values, data[AIR][mask]):
            raise ValueError("Extracted reference lost numerical roundtrip identity")
    return metadata


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run", type=Path, required=True)
    parser.add_argument("--packet", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--equivalent-run", type=Path)
    args = parser.parse_args()
    print(json.dumps(extract(args.run, args.packet, args.output, args.equivalent_run), indent=2))


if __name__ == "__main__":
    main()
