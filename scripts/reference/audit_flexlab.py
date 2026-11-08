"""Read authentic FLEXLAB CSVs; write metadata only, never rewrite measurements."""

import argparse
import hashlib
import json
from pathlib import Path
from urllib.parse import quote

import numpy as np
import pandas as pd

COMMIT = "265312ec3843c97d5a24b7d5671ee2891f326af6"
START = "2021-06-23 00:00:00"
END = "2021-06-23 12:00:00"
CORE = [
    "Direct Validation Data/Air temperature.csv",
    "Input Data/Weather data.csv",
    "Input Data/Internal heat gain rate.csv",
    "Input Data/Duct blaster.csv",
    "Direct Validation Data/Fan coil units.csv",
    "Input Data/Exterior surface temperature.csv",
]


def inspect(root: Path) -> dict:
    """Audit one file at a time; PST is fixed UTC-08, with no DST conversion."""
    pinned = json.loads(
        (Path(__file__).resolve().parents[2] / "docs/results/c42b/source_audit.json").read_text()
    )
    known = {item["path"]: item["sha256"] for item in pinned["files"]}
    result = {
        "source_commit": COMMIT,
        "timezone": "PST fixed UTC-08:00 (report p23/p31)",
        "selection_start_inclusive": START,
        "selection_end_inclusive": END,
        "selection_expected_rows": 721,
        "matlab_executed": False,
        "simulation_performed": False,
        "redistribution_license": "not_found_in_pinned_repository",
        "files": [],
        "csv_audit": [],
    }
    for path in sorted(p for p in root.rglob("*") if p.is_file() and ".git" not in p.parts):
        name = path.relative_to(root).as_posix()
        with path.open("rb") as stream:
            sha = hashlib.file_digest(stream, "sha256").hexdigest()
        if known.get(name) != sha:
            raise ValueError(f"Unpinned or modified source file: {name}")
        result["files"].append(
            {
                "path": name,
                "bytes": path.stat().st_size,
                "sha256": sha,
                "source": f"https://raw.githubusercontent.com/LBNL-ETA/FLEXLAB-ASHRAE140/{COMMIT}/"
                + quote(name, safe="/"),
            }
        )
        if path.suffix.lower() != ".csv" or name.startswith("Auxiliary Data/"):
            continue
        frame = pd.read_csv(path)
        times = pd.to_datetime(frame.pop("time"), format="mixed", errors="raise")
        if times.isna().any() or times.duplicated().any() or not times.is_monotonic_increasing:
            raise ValueError(f"Invalid/duplicate/unordered source times: {name}")
        values = frame.to_numpy(dtype=float)
        selected = times.between(pd.Timestamp(START), pd.Timestamp(END))
        subset = frame.loc[selected]
        gaps = times.diff().dt.total_seconds().dropna().value_counts().sort_index()
        result["csv_audit"].append(
            {
                "path": name,
                "rows": len(frame),
                "channels": list(frame.columns),
                "first_timestamp": str(times.iloc[0]),
                "last_timestamp": str(times.iloc[-1]),
                "interval_seconds_counts": {str(k): int(v) for k, v in gaps.items()},
                "missing_cells": int(np.isnan(values).sum()),
                "infinite_cells": int(np.isinf(values).sum()),
                "selected_rows": int(selected.sum()),
                "selected_absent_timestamps": 721 - int(selected.sum()),
                "selected_missing_cells": int(subset.isna().sum().sum()),
                "selected_nonfinite_cells": int((~np.isfinite(subset)).sum().sum()),
                "selected_missing_by_channel": subset.isna().sum().to_dict(),
                "selected_min": subset.min().to_dict(),
                "selected_max": subset.max().to_dict(),
            }
        )
    index = pd.date_range(START, END, freq="min")
    for name in CORE:
        frame = pd.read_csv(root / name)
        times = pd.to_datetime(frame.pop("time"), format="mixed")
        frame.index = times
        selected = frame.reindex(index)
        if not np.isfinite(selected).all().all():
            raise ValueError(f"Incomplete selected core channels: {name}")
    result["selected_core_files"] = CORE
    result["selected_core_complete"] = True
    result["initial_states"] = "air/boundary observations available; complete fabric states unknown"
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source_root", type=Path)
    parser.add_argument("output_json", type=Path)
    args = parser.parse_args()
    report = inspect(args.source_root)
    args.output_json.parent.mkdir(parents=True, exist_ok=True)
    args.output_json.write_text(json.dumps(report, indent=2, allow_nan=False) + "\n")
