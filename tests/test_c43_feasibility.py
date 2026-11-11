"""Synthetic data-reader tests only; not empirical validation evidence."""

import hashlib
import sys
from pathlib import Path

import numpy as np
import pandas as pd
import pytest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts/reference"))
from assess_c43 import PST, flow_m3_s, load_frame, select_minutes  # noqa: E402


@pytest.fixture
def source(tmp_path):
    path = tmp_path / "software_fixture.csv"
    raw = b"time,T_air_C,Q_W\n2021-06-23 00:00,20,-10\n2021-06-23 00:01,21,0\n"
    path.write_bytes(raw)
    return path, {"path": path.name, "sha256": hashlib.sha256(raw).hexdigest(), "bytes": len(raw)}


def test_hash_loading_fixed_pst_and_signs(source):
    path, identity = source
    frame = load_frame(path, identity)
    selected = select_minutes(frame, "2021-06-23 00:00", "2021-06-23 00:01")
    assert selected.index[0].isoformat() == "2021-06-23T00:00:00-08:00"
    assert selected["Q_W"].tolist() == [-10, 0]
    path.write_bytes(path.read_bytes() + b"modified")
    with pytest.raises(ValueError, match="Pinned bytes"):
        load_frame(path, identity)


@pytest.mark.parametrize("defect", ["gap", "nonfinite", "extra_sample"])
def test_alignment_rejects_gaps_invalid_and_extra_samples(source, defect):
    path, identity = source
    frame = load_frame(path, identity)
    if defect == "gap":
        frame = frame.iloc[:1]
    elif defect == "nonfinite":
        frame.iloc[0, 0] = np.nan
    else:
        frame.loc[pd.Timestamp("2021-06-23 00:00:30", tz=PST)] = [20, -5]
        frame = frame.sort_index()
    with pytest.raises(ValueError):
        select_minutes(frame, "2021-06-23 00:00", "2021-06-23 00:01")


def test_flow_unit_conversion_preserves_sign_and_does_not_make_heat_power():
    assert flow_m3_s(pd.Series([3600.0, 0, -1800])).tolist() == [1.0, 0.0, -0.5]


@pytest.mark.parametrize(
    "times",
    [
        ["2021-06-23 00:00", "2021-06-23 00:00"],
        ["2021-06-23 00:01", "2021-06-23 00:00"],
        ["not-a-time", "2021-06-23 00:00"],
    ],
)
def test_invalid_source_times_rejected(tmp_path, times):
    path = tmp_path / "software_times.csv"
    pd.DataFrame({"time": times, "value": [1, 2]}).to_csv(path, index=False)
    raw = path.read_bytes()
    identity = {"path": path.name, "bytes": len(raw), "sha256": hashlib.sha256(raw).hexdigest()}
    with pytest.raises(ValueError):
        load_frame(path, identity)
