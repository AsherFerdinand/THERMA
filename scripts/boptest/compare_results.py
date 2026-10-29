"""Compare canonical CSV+metadata pairs; never asserts reference validation.

Metadata requires scenario_id, model_version, reference_version, csv_sha256 and
signals [{quantity, unit, interpolation, optional column}]. CSV time is time_s.
Candidate metadata must describe the experiment actually executed, not be copied
from the reference to bypass scenario or revision checks.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
from pathlib import Path

import numpy as np

from therma.comparison import Series
from therma.validation.reporting import (
    CLASSIFICATIONS,
    diagnostic_plots,
    markdown_report,
    study_report,
)


def load_series(csv_path: Path, metadata_path: Path) -> dict[str, Series]:
    raw = csv_path.read_bytes()
    digest = hashlib.sha256(raw).hexdigest()
    metadata = json.loads(metadata_path.read_text())
    if metadata.get("schema_version") != 1 or metadata["csv_sha256"] != digest:
        raise ValueError("Metadata schema or CSV provenance hash mismatch")
    with csv_path.open(newline="") as stream:
        header = next(csv.reader(stream))
    if len(set(header)) != len(header):
        raise ValueError("Duplicate CSV column names")
    data = np.genfromtxt(csv_path, delimiter=",", names=True, deletechars="")
    if "time_s" not in header:
        raise ValueError("Missing time_s column")
    result = {}
    for signal in metadata["signals"]:
        quantity = signal["quantity"]
        if quantity in result:
            raise ValueError("Duplicate quantity in signal contract")
        column = signal.get("column", quantity)
        if column not in header:
            raise ValueError("Declared signal column is missing: " + column)
        result[quantity] = Series(
            data["time_s"],
            data[column],
            signal["unit"],
            quantity,
            signal["interpolation"],
            metadata["scenario_id"],
            metadata["model_version"],
            metadata["reference_version"],
            digest,
            metadata.get("max_gap_s"),
        )
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("reference_csv", type=Path)
    parser.add_argument("reference_metadata", type=Path)
    parser.add_argument("candidate_csv", type=Path)
    parser.add_argument("candidate_metadata", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument(
        "--classification", choices=CLASSIFICATIONS, default="exploratory_comparison"
    )
    parser.add_argument("--allow-scenario-difference", action="store_true")
    parser.add_argument("--plots", type=Path)
    args = parser.parse_args()
    reference = load_series(args.reference_csv, args.reference_metadata)
    candidate = load_series(args.candidate_csv, args.candidate_metadata)
    report = study_report(
        reference,
        candidate,
        json.loads(args.reference_metadata.read_text()),
        json.loads(args.candidate_metadata.read_text()),
        args.classification,
        args.allow_scenario_difference,
    )
    report["input_metadata_sha256"] = [
        hashlib.sha256(path.read_bytes()).hexdigest()
        for path in (args.reference_metadata, args.candidate_metadata)
    ]
    report["self_comparison"] = args.reference_csv.read_bytes() == args.candidate_csv.read_bytes()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2, allow_nan=False) + "\n")
    args.output.with_suffix(".md").write_text(markdown_report(report))
    if args.plots:
        diagnostic_plots(reference, candidate, args.plots)
    print(report["status"])


if __name__ == "__main__":
    main()
