"""Recheck measured inputs for C4.3 feasibility; never simulate, fit, or publish raw data."""

import argparse
import hashlib
import json
from datetime import timedelta, timezone
from pathlib import Path

import numpy as np
import pandas as pd
from audit_flexlab import COMMIT, CORE, END, START

ROOT = Path(__file__).resolve().parents[2]
PST = timezone(timedelta(hours=-8))
SUPPORT = [
    "Measured dataset for validation of building energy modeling programs.pdf",
    "Auxiliary Data/Materials.csv",
    "Auxiliary Data/Construction.csv",
    "Auxiliary Data/Materials and Construction.idf",
    "Meta data.xlsx",
]


def load_frame(path: Path, identity: dict) -> pd.DataFrame:
    """Authenticate original bytes; retain fixed-PST timestamps, signs, and all columns."""
    with path.open("rb") as stream:
        digest = hashlib.file_digest(stream, "sha256").hexdigest()
    if digest != identity["sha256"] or path.stat().st_size != identity["bytes"]:
        raise ValueError(f"Pinned bytes differ: {identity['path']}")
    frame = pd.read_csv(path)
    times = pd.DatetimeIndex(pd.to_datetime(frame.pop("time"), format="mixed", errors="raise"))
    if (
        times.hasnans
        or times.has_duplicates
        or not times.is_monotonic_increasing
        or times.tz is not None
    ):
        raise ValueError("Expected unique ordered naive source timestamps in fixed PST")
    frame.index = times.tz_localize(PST)
    return frame.astype(float)


def select_minutes(frame: pd.DataFrame, start: str, end: str) -> pd.DataFrame:
    expected = pd.date_range(start, end, freq="min", tz=PST)
    selected = frame.loc[expected[0] : expected[-1]]
    if not selected.index.equals(expected):
        raise ValueError("Missing/extra/non-minute timestamps; no interpolation is permitted")
    if not np.isfinite(selected.to_numpy()).all():
        raise ValueError("Missing/nonfinite selected measurement")
    return selected


def flow_m3_s(flow_m3_h: pd.Series) -> pd.Series:
    """Exact unit conversion only; no density or ventilation power assumption."""
    return flow_m3_h / 3600.0


def stats(series: pd.Series) -> dict:
    return {
        "min": float(series.min()),
        "max": float(series.max()),
        "mean": float(series.mean()),
        "first": float(series.iloc[0]),
        "last": float(series.iloc[-1]),
    }


def assess(source: Path) -> dict:
    prior = json.loads((ROOT / "docs/results/c42b/source_audit.json").read_text())
    if prior["source_commit"] != COMMIT:
        raise ValueError("Unexpected upstream pin")
    known = {r["path"]: r for r in prior["files"]}
    frames, provenance = {}, []
    for name in CORE + SUPPORT:
        identity = known[name]
        path = source / name
        if name in CORE:
            frames[name] = load_frame(path, identity)
            select_minutes(frames[name], START, END)
        else:
            with path.open("rb") as stream:
                digest = hashlib.file_digest(stream, "sha256").hexdigest()
            if digest != identity["sha256"] or path.stat().st_size != identity["bytes"]:
                raise ValueError(f"Pinned bytes differ: {name}")
        provenance.append({k: identity[k] for k in ["path", "bytes", "sha256", "source"]})
    air, weather, gains, vent, fcu, surfaces = [
        select_minutes(frames[name], START, END) for name in CORE
    ]
    if air.shape[1] != 26:
        raise ValueError("Expected 26 supplied air-temperature sensors")
    cooling = fcu["Total cooling rate [W]"]
    days = []
    for day in [f"2021-06-{d:02d}" for d in range(22, 27)]:
        expected = pd.date_range(day, periods=1440, freq="min", tz=PST)
        missing = {
            n: int((~np.isfinite(f.reindex(expected).to_numpy())).any(axis=1).sum())
            for n, f in frames.items()
        }
        days.append({"day_PST": day, "expected_rows": 1440, "invalid_rows_by_source": missing})
    conditioned = pd.date_range("2021-06-22", periods=5 * 1440, freq="min", tz=PST)
    valid = np.ones(len(conditioned), dtype=bool)
    for frame in frames.values():
        valid &= np.isfinite(frame.reindex(conditioned).to_numpy()).all(axis=1)
    starts = np.flatnonzero(valid & ~np.r_[False, valid[:-1]])
    ends = np.flatnonzero(valid & ~np.r_[valid[1:], False])
    runs = [
        {
            "start_inclusive_PST": str(conditioned[a]),
            "end_inclusive_PST": str(conditioned[b]),
            "rows": int(b - a + 1),
            "duration_hours": float((b - a) / 60),
        }
        for a, b in zip(starts, ends, strict=True)
    ]
    return {
        "schema_version": 1,
        "upstream_commit": COMMIT,
        "timezone": "PST fixed UTC-08:00; no DST",
        "status": "blocked_pending_cell3b_model_specification",
        "measurement_only": True,
        "matlab_executed_in_cloud": False,
        "simulation_performed": False,
        "empirical_validation_performed": False,
        "start_inclusive": START,
        "end_inclusive": END,
        "rows_per_core_source": 721,
        "sources": provenance,
        "arithmetic_mean_air_C": stats(air.mean(axis=1)),
        "maximum_sensor_spread_K": float((air.max(axis=1) - air.min(axis=1)).max()),
        "outdoor_W_OAT_2_C": stats(weather["W-OAT-2"]),
        "internal_gain_W": stats(gains["Internal heat gain rate [W]"]),
        "raw_total_cooling_W": stats(cooling),
        "negative_cooling_samples": int((cooling < 0).sum()),
        "cooling_component_sum_max_abs_difference_W": float(
            (cooling - fcu["Cooling_2 rate [W]"] - fcu["Cooling_4 rate [W]"]).abs().max()
        ),
        "adjusted_ventilation_flow_m3_s": stats(flow_m3_s(vent["Flow adjusted [m3/h]"])),
        "vent_supply_C": stats(vent["Ventilation air temperature [C]"]),
        "derived_ventilation_W_diagnostic_only": stats(vent["Ventilation heat transfer rate [W]"]),
        "radiation_W_m2": {n: stats(weather[n]) for n in ["GHI", "DNI", "DHI", "PIRin"]},
        "measured_boundary_surface_C": {n: stats(surfaces[n]) for n in surfaces.columns},
        "full_conditioned_day_completeness_all_columns": days,
        "longest_complete_runs_all_columns": sorted(runs, key=lambda r: r["rows"], reverse=True)[
            :5
        ],
        "metrics": dict.fromkeys(["MAE_K", "RMSE_K", "MBE_K", "max_absolute_error_K"]),
        "metrics_unavailable_reason": (
            "No prediction: Cell3B parameter/boundary/state choices remain open"
        ),
        "calibration_performed": False,
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.output.resolve().is_relative_to(args.source.resolve()):
        parser.error("Output must be outside original source directory")
    result = assess(args.source)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("x") as stream:
        stream.write(json.dumps(result, indent=2, allow_nan=False) + "\n")
    print(f"Authenticated {len(result['sources'])} files; no prediction or calibration performed.")
