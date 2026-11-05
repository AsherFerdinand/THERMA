"""Synthetic software tests only, never benchmark evidence."""

from dataclasses import replace
from pathlib import Path

import numpy as np
import pytest

from therma.comparison import Series, convert
from therma.validation.temperature import END, START, aligned_errors, check_grid


def series(t=None, values=None, quantity="air_temperature", unit="K"):
    return Series(
        np.array([0, 30, 60], dtype=float) if t is None else np.array(t, dtype=float),
        np.array([273.15, 274.15, 275.15]) if values is None else np.array(values, dtype=float),
        unit,
        quantity,
        "linear",
        "typical_heat_day",
        "test",
        "pinned",
        "a" * 64,
    )


def test_temperature_conversion_interpolation_and_known_metrics():
    reference = series([0, 15, 30, 45, 60], [273.15, 273.65, 274.15, 274.65, 275.15])
    candidate = series(values=[1, 2, 3], unit="degC")
    actual = aligned_errors(candidate, reference)
    assert actual["MAE_K"] == pytest.approx(1)
    assert actual["RMSE_K"] == pytest.approx(1)
    assert actual["bias_K"] == pytest.approx(1)
    assert np.array_equal(convert(np.array([273.15]), "K", "degC"), [0])


def test_known_nonuniform_errors():
    actual = aligned_errors(series(values=[272.15, 274.15, 277.15]), series())
    assert actual["MAE_K"] == pytest.approx(1)
    assert actual["RMSE_K"] == pytest.approx(np.sqrt(5 / 3))
    assert actual["bias_K"] == pytest.approx(1 / 3)
    assert actual["maximum_absolute_error_K"] == pytest.approx(2)


def test_never_extrapolate_or_compare_operative():
    with pytest.raises(ValueError, match="extrapolation"):
        aligned_errors(series(), series([-1, 30, 60]))
    with pytest.raises(ValueError, match="operative"):
        aligned_errors(series(), series(quantity="operative_temperature"))
    with pytest.raises(ValueError, match="Scenarios"):
        aligned_errors(series(), replace(series(), scenario="peak_heat_day"))
    with pytest.raises(ValueError, match="versions"):
        aligned_errors(series(), replace(series(), reference_version="other"))


@pytest.mark.parametrize("times", [[0, 0, 60], [0, 60, 30], [0, np.nan, 60]])
def test_invalid_times_rejected(times):
    with pytest.raises(ValueError):
        series(times)


def test_missing_values_and_reference_samples_rejected():
    with pytest.raises(ValueError):
        series(values=[1, np.nan, 3])
    t = np.arange(START, END + 30, 30, dtype=float)
    check_grid(t)
    for wrong in [t[:-1], np.delete(t, 3), t + 30, np.r_[t[:-1], t[-2]]]:
        with pytest.raises(ValueError):
            check_grid(wrong)


def test_matlab_contract_preserves_sources_and_has_no_simulation():
    root = Path(__file__).resolve().parents[1]
    source = (root / "scripts/matlab/boptest/compare_boptest_c28.m").read_text()
    for token in ["completion_sha256", "csv_sha256", "compatible_reference_sources", "40321"]:
        assert token in source
    assert "run_boptest_zone_replay(" not in source
    assert "sim(" not in source
    assert "'k'" in source and "'b'" in source and "'r'" in source


def test_reference_parser_integrity_units_and_reproducibility(tmp_path):
    import hashlib
    import json

    from therma.validation.temperature import AIR, read_reference

    time = np.arange(START, END + 30, 30)
    csv_file = tmp_path / "reference_temperature.csv"
    np.savetxt(
        csv_file,
        np.column_stack([time, time * 0 + 293.15]),
        delimiter=",",
        header="time_s,air_temperature_K",
        comments="",
        fmt="%.17g",
    )
    metadata = {
        "csv_sha256": hashlib.sha256(csv_file.read_bytes()).hexdigest(),
        "signals": [
            {
                "column": "air_temperature_K",
                "quantity": "air_temperature",
                "source": AIR,
                "unit": "K",
            }
        ],
        "time_basis": "absolute_simulation_seconds",
        "scenario": {"name": "typical_heat_day"},
        "boptest_commit": "pinned",
    }
    meta_file = tmp_path / "reference_metadata.json"
    meta_file.write_text(json.dumps(metadata))
    first = read_reference(tmp_path)
    assert np.array_equal(first.values, read_reference(tmp_path).values)
    metadata["signals"][0]["unit"] = "degC"
    meta_file.write_text(json.dumps(metadata))
    with pytest.raises(ValueError, match="original air"):
        read_reference(tmp_path)
    metadata["signals"][0]["unit"] = "K"
    meta_file.write_text(json.dumps(metadata))
    csv_file.write_text(csv_file.read_text() + "0,0\n")
    with pytest.raises(ValueError, match="hash"):
        read_reference(tmp_path)
