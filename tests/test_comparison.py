"""Analytical synthetic data tests; no MATLAB or thermal simulation."""

import hashlib
import importlib.util
import json
from dataclasses import replace
from pathlib import Path

import numpy as np
import pytest

from therma.comparison import Series, compare, convert, integrate, resample


def series(values=(1, 2, 3), times=(0, 1, 2), **kwargs):
    fields = dict(
        unit="K",
        quantity="air_temperature",
        interpolation="linear",
        scenario="fixture",
        model_version="test-v1",
        reference_version="pinned",
        source_sha256="a" * 64,
    )
    fields.update(kwargs)
    return Series(np.array(times), np.array(values), **fields)


def test_metrics_and_temperature_conversion():
    reference = series((273.15, 274.15, 275.15))
    candidate = series((1, 2, 3), unit="degC")
    report = compare(reference, candidate)
    for name in ["mae", "rmse", "maximum_absolute_error", "mean_bias_error"]:
        assert report[name] == pytest.approx(1)
    assert report["peak_value_difference"] == pytest.approx(1)
    assert report["relative_energy_difference"] is None
    assert report["status"] == "compared_no_accuracy_threshold_applied"


def test_known_nonconstant_error():
    report = compare(series((1, 1, 1)), series((0, 1, 3)))
    assert report["mae"] == pytest.approx(1)
    assert report["rmse"] == pytest.approx(np.sqrt(5 / 3))
    assert report["mean_bias_error"] == pytest.approx(1 / 3)
    assert report["maximum_absolute_error"] == 2


def test_power_steps_union_preserves_event_and_energy():
    reference = series((0, 10, 10), times=(0, 1, 2), unit="W", interpolation="previous")
    candidate = series((0, 0, 10, 10), times=(0, 0.5, 1, 2), unit="W", interpolation="previous")
    report = compare(reference, candidate)
    assert report["mae"] == 0
    assert report["reference_energy_J"] == 10
    assert report["relative_energy_difference"] == 0
    np.testing.assert_array_equal(resample(reference, np.array([0.5, 1, 1.5])), [0, 10, 10])
    assert integrate(np.array([0, 1, 2]), np.array([0, 10, 10]), "linear") == 15


def test_energy_units_and_zero_denominator():
    reference = series((0, 3.6e6, 7.2e6), unit="J", quantity="heating_energy")
    candidate = series((0, 1.5, 3), unit="kWh", quantity="heating_energy")
    assert compare(reference, candidate)["relative_energy_difference"] == pytest.approx(0.5)
    zero = series((0, 0, 0), unit="W")
    assert compare(zero, zero)["relative_energy_difference"] is None
    np.testing.assert_array_equal(convert(np.array([1.0]), "kW", "W"), [1000])


@pytest.mark.parametrize(
    "times,values",
    [
        ((0, 0, 1), (1, 2, 3)),
        ((0, 2, 1), (1, 2, 3)),
        ((0, 1, 2), (1, float("nan"), 3)),
        ((0, float("inf"), 2), (1, 2, 3)),
        ((0, 1), (1, 2, 3)),
        ((0,), (1,)),
    ],
)
def test_reject_invalid_samples(times, values):
    with pytest.raises(ValueError):
        series(values, times)


@pytest.mark.parametrize(
    "kwargs",
    [
        {"scenario": ""},
        {"model_version": ""},
        {"reference_version": ""},
        {"source_sha256": "missing"},
        {"unit": "unknown"},
        {"interpolation": "smooth"},
        {"max_gap_s": 0.5},
        {"max_gap_s": -1},
    ],
)
def test_metadata_and_missing_gap(kwargs):
    with pytest.raises(ValueError):
        series(**kwargs)


def test_comparison_rejects_semantic_units_scenario_revision_and_coverage_mismatch():
    source = series()
    for other in [
        replace(source, quantity="operative_temperature"),
        replace(source, unit="W"),
        replace(source, scenario="other"),
        replace(source, reference_version="other"),
        series(times=(0, 1, 3)),
    ]:
        with pytest.raises(ValueError):
            compare(source, other)
    with pytest.raises(ValueError):
        convert(np.array([1.0]), "J", "W")
    with pytest.raises(ValueError):
        resample(source, np.array([-1, 0]))


def test_linear_alignment_and_immutable_input_copy():
    source = series((0, 2), times=(0, 2))
    candidate = series((0, 1, 2))
    assert compare(source, candidate)["mae"] == 0
    np.testing.assert_array_equal(resample(source, np.array([0, 0.5, 2])), [0, 0.5, 2])
    with pytest.raises(ValueError):
        source.values[0] = 42


def load_normalizer():
    root = Path(__file__).resolve().parents[1]
    spec = importlib.util.spec_from_file_location(
        "normalizer", root / "scripts/boptest/normalize_results.py"
    )
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_normalization_preserves_provenance_and_reports_missing_signals(tmp_path):
    normalizer = load_normalizer()
    run = tmp_path / "run"
    run.mkdir()
    (run / "evaluation.csv").write_text("time_s,reaTRoo_y\n0,293.15\n30,294.15\n60,295.15\n")
    (run / "signals.json").write_text(json.dumps([{"name": "reaTRoo_y", "unit": "K"}]))
    manifest = {
        "status": "success",
        "source_fmu_unchanged": True,
        "scenario": {"name": "test", "evaluation_start_s": 0, "evaluation_end_s": 60},
        "boptest_commit": "pinned",
        "fmu": {"sha256": "a" * 64},
        "artifacts": {
            name: normalizer.digest(run / name) for name in ["evaluation.csv", "signals.json"]
        },
    }
    (run / "manifest.json").write_text(json.dumps(manifest))
    report = normalizer.normalize(run, tmp_path / "normalized")
    assert "reaQHea_y" in report["missing_signals"]
    assert report["source_manifest"] == manifest
    assert (
        report["source_manifest_sha256"]
        == hashlib.sha256((run / "manifest.json").read_bytes()).hexdigest()
    )
    (run / "evaluation.csv").write_text("tampered")
    with pytest.raises(ValueError, match="hash mismatch"):
        normalizer.normalize(run, tmp_path / "bad")


def test_missing_signals_report_readiness():
    from therma.comparison import compare_collection

    source = series()
    report = compare_collection({"air_temperature": source}, {})
    assert report["status"] == "comparison_not_ready"
    assert report["missing_candidate_signals"] == ["air_temperature"]
    report = compare_collection({"air_temperature": source}, {"air_temperature": source})
    assert report["status"] == "compared_no_accuracy_threshold_applied"


def test_comparison_csv_contract(tmp_path):
    root = Path(__file__).resolve().parents[1]
    spec = importlib.util.spec_from_file_location(
        "comparison_cli", root / "scripts/boptest/compare_results.py"
    )
    assert spec is not None and spec.loader is not None
    cli = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(cli)
    csv_file = tmp_path / "trace.csv"
    csv_file.write_text("time_s,T_air_K\n0,293.15\n30,294.15\n")
    metadata = {
        "schema_version": 1,
        "scenario_id": "test",
        "model_version": "synthetic-v1",
        "reference_version": "pinned",
        "csv_sha256": hashlib.sha256(csv_file.read_bytes()).hexdigest(),
        "signals": [
            {
                "quantity": "air_temperature",
                "column": "T_air_K",
                "unit": "K",
                "interpolation": "linear",
            }
        ],
    }
    metadata_file = tmp_path / "metadata.json"
    metadata_file.write_text(json.dumps(metadata))
    loaded = cli.load_series(csv_file, metadata_file)
    assert loaded["air_temperature"].scenario == "test"
    assert loaded["air_temperature"].values[-1] == 294.15
    metadata["signals"][0]["column"] = "missing"
    metadata_file.write_text(json.dumps(metadata))
    with pytest.raises(ValueError, match="missing"):
        cli.load_series(csv_file, metadata_file)
    metadata["signals"][0]["column"] = "T_air_K"
    metadata["signals"].append(dict(metadata["signals"][0]))
    metadata_file.write_text(json.dumps(metadata))
    with pytest.raises(ValueError, match="Duplicate quantity"):
        cli.load_series(csv_file, metadata_file)
    metadata["signals"].pop()
    csv_file.write_text("time_s,T_air_K,T_air_K\n0,293,293\n30,294,294\n")
    metadata["csv_sha256"] = hashlib.sha256(csv_file.read_bytes()).hexdigest()
    metadata_file.write_text(json.dumps(metadata))
    with pytest.raises(ValueError, match="Duplicate CSV"):
        cli.load_series(csv_file, metadata_file)


def test_gas_and_delivered_power_are_incompatible():
    with pytest.raises(ValueError, match="physical quantities"):
        compare(
            series(unit="W", quantity="gas_input_power"),
            series(unit="W", quantity="delivered_heating_convective_power"),
        )
