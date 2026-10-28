"""Data/provenance contracts; numerical reference evidence is in generated manifests."""

import hashlib
import importlib.util
import json
from pathlib import Path
from zipfile import ZipFile

import numpy as np
import pytest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location(
    "boptest_runner", ROOT / "scripts/boptest/run_reference.py"
)
assert spec is not None and spec.loader is not None
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)


@pytest.fixture
def trace():
    names = [
        "time_s",
        "reaTRoo_y",
        "reaQHea_y",
        "reaPPum_y",
        "reaCO2RooAir_y",
        "weaSta_reaWeaTDryBul_y",
        "ovePum_activate",
        "ovePum_y",
    ]
    units = dict(runner.REQUIRED_UNITS, weaSta_reaWeaTDryBul_y="K")
    values = np.array([[t, 293.15, 1000, 10, 500, 278.15, 0, 1] for t in [0, 20, 40, 60]])
    return values, names, units


def test_valid_complete_trace(trace):
    values, names, units = trace
    assert runner.check_data(values, names, units, 0, 60, 20)["status"] == "passed"


@pytest.mark.parametrize("times", [[0, 0, 40, 60], [0, 40, 20, 60], [0, 19, 40, 60]])
def test_duplicate_nonmonotonic_or_offgrid_time(trace, times):
    values, names, units = trace
    values[:, 0] = times
    with pytest.raises(ValueError, match="timestamps"):
        runner.check_data(values, names, units, 0, 60, 20)


def test_missing_sample(trace):
    values, names, units = trace
    with pytest.raises(ValueError, match="coverage"):
        runner.check_data(values[[0, 2, 3]], names, units, 0, 60, 20)


def test_incorrect_warmup_boundary(trace):
    values, names, units = trace
    with pytest.raises(ValueError, match="boundaries"):
        runner.check_data(values, names, units, 20, 60, 20)


@pytest.mark.parametrize("invalid", [float("nan"), float("inf"), -float("inf")])
def test_nonfinite_data(trace, invalid):
    values, names, units = trace
    values[1, 1] = invalid
    with pytest.raises(ValueError, match="NaN or infinite"):
        runner.check_data(values, names, units, 0, 60, 20)


@pytest.mark.parametrize("signal", ["reaQHea_y", "reaPPum_y"])
def test_negative_power(trace, signal):
    values, names, units = trace
    values[1, names.index(signal)] = -1
    with pytest.raises(ValueError, match="Negative"):
        runner.check_data(values, names, units, 0, 60, 20)


def test_units_are_not_silently_converted(trace):
    values, names, units = trace
    units["reaQHea_y"] = "kW"
    with pytest.raises(ValueError, match="incorrect unit"):
        runner.check_data(values, names, units, 0, 60, 20)


@pytest.mark.parametrize(
    "signal,value",
    [("ovePum_activate", 1), ("ovePum_y", 0.5), ("reaTRoo_y", 0), ("reaCO2RooAir_y", -1)],
)
def test_invalid_baseline_or_physical_contract(trace, signal, value):
    values, names, units = trace
    values[1, names.index(signal)] = value
    with pytest.raises(ValueError):
        runner.check_data(values, names, units, 0, 60, 20)


def test_energy_integrates_watts_seconds_into_kwh():
    t = np.array([0, 1800, 3600])
    power = np.array([0, 1000, 0])
    assert runner.energy_kwh(t, power)[-1] == 0.5


@pytest.mark.parametrize(
    "name,warmup,start,end",
    [
        ("typical_heat_day", 327, 334, 348),
        ("peak_heat_day", 304, 311, 325),
    ],
)
def test_pinned_scenario_semantics(name, warmup, start, end):
    config = json.loads((ROOT / "configs/references/boptest_scenarios.json").read_text())
    assert runner.scenario_bounds(config["scenarios"][name], 30) == (
        warmup * 86400,
        start * 86400,
        end * 86400,
    )


def test_scenario_rejects_sample_grid_that_misses_boundary():
    config = json.loads((ROOT / "configs/references/boptest_scenarios.json").read_text())
    with pytest.raises(ValueError, match="boundaries"):
        runner.scenario_bounds(config["scenarios"]["typical_heat_day"], 17)


def test_hash_mismatch_rejected_before_native_loading(tmp_path):
    path = tmp_path / "not_an_fmu.fmu"
    path.write_bytes(b"changed bytes")
    source = {"stored_fmu": {"source_id": "fmu"}, "sources": {"fmu": {"sha256": "0" * 64}}}
    with pytest.raises(ValueError, match="SHA-256 mismatch"):
        runner.verify_fmu(path, source)


def test_embedded_resource_mismatch_rejected(tmp_path):
    path = tmp_path / "resource_contract.fmu"
    with ZipFile(path, "w") as archive:
        archive.writestr("resources/weather.csv", "changed weather")
    source = {
        "stored_fmu": {
            "source_id": "fmu",
            "members": [
                {"member": "resources/weather.csv", "sha256": "0" * 64},
            ],
        },
        "sources": {"fmu": {"sha256": hashlib.sha256(path.read_bytes()).hexdigest()}},
    }
    with pytest.raises(ValueError, match="Resource hash mismatch"):
        runner.verify_fmu(path, source)


def test_failed_run_cannot_be_repeat_reference(tmp_path):
    (tmp_path / "manifest.json").write_text('{"status":"failed"}')
    with pytest.raises(ValueError, match="not a successful"):
        runner.compare_repeat(np.zeros((1, 1)), ["time_s"], tmp_path, {})
