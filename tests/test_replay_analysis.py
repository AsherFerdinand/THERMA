"""Synthetic export fixtures only. No MATLAB run/evidence is fabricated or archived."""

import importlib.util
import json

import numpy as np
import pytest

from therma.validation.analysis import (
    REQUIRED,
    SOURCE_AIR,
    SOURCE_CONV,
    SOURCE_RAD,
    analyze_run,
    file_hash,
    load_replay,
    reference_sign_audit,
    signed_power,
)
from therma.validation.archive import REGISTRY_HASH
from therma.validation.replay import validate_matrix


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n")


def update_csv_hash(run):
    meta = json.loads((run / "comparison_metadata.json").read_text())
    meta["csv_sha256"] = file_hash(run / "evaluation.csv")
    write_json(run / "comparison_metadata.json", meta)


@pytest.fixture
def exports(tmp_path):
    run = tmp_path / "synthetic_run"
    ref = tmp_path / "synthetic_reference"
    run.mkdir()
    ref.mkdir()
    t = np.array([1.0, 2.0, 3.0])
    source = np.column_stack([t, [291, 292, 293], [-5, -5, 1], [-2, 4, -2]])
    np.savetxt(
        ref / "evaluation.csv",
        source,
        delimiter=",",
        comments="",
        header=",".join(["time_s", SOURCE_AIR, SOURCE_CONV, SOURCE_RAD]),
    )
    definitions = [
        {"name": name, "unit": unit}
        for name, unit in ((SOURCE_AIR, "K"), (SOURCE_CONV, "W"), (SOURCE_RAD, "W"))
    ]
    write_json(ref / "signals.json", definitions)
    matrix = validate_matrix()
    scenario = {
        "name": "synthetic_fixture",
        "initialization_time_s": 0,
        "evaluation_start_s": 1,
        "evaluation_end_s": 3,
    }
    manifest = {
        "status": "success",
        "source_fmu_unchanged": True,
        "fmu": {"sha256": matrix["fmu_sha256"]},
        "boptest_commit": matrix["boptest_commit"],
        "scenario": scenario,
        "artifacts": {
            "trajectory.csv": "b" * 64,
            "evaluation.csv": file_hash(ref / "evaluation.csv"),
            "signals.json": file_hash(ref / "signals.json"),
        },
    }
    write_json(ref / "manifest.json", manifest)
    packet = {
        "scenario_id": "synthetic_fixture__partial",
        "reference_scenario_id": "synthetic_fixture",
        "source_scenario": scenario,
        "reference_version": matrix["boptest_commit"],
        "reference_manifest_sha256": file_hash(ref / "manifest.json"),
        "source_trajectory_sha256": "b" * 64,
        "source_signals_sha256": file_hash(ref / "signals.json"),
        "time_origin_s": 0,
        "duration_s": 3,
        "evaluation_start_s": 1,
        "evaluation_end_s": 3,
        "channels": [],
        "initial_conditions": {"status": "synthetic test only"},
    }
    columns = {
        "air_temperature": [293, 294, 295],
        "outdoor_temperature": [283, 284, 285],
        "delivered_heating_power": [7, 1, 1],
        "delivered_heating_convective_power": [5, 5, -1],
        "delivered_heating_radiative_power": [2, -4, 2],
        "ventilation_sensible_power": [-217.296] * 3,
        "stored_thermal_energy": [-10, 0, 10],
        "power_balance_residual": [1e-12, 0, -1e-12],
    }
    np.savetxt(
        run / "evaluation.csv",
        np.column_stack([t, *columns.values()]),
        delimiter=",",
        comments="",
        header=",".join(["time_s", *columns]),
    )
    meta = {
        "schema_version": 1,
        "classification": "exploratory_comparison",
        "scenario_id": packet["scenario_id"],
        "model_version": "SYNTHETIC_TEST_ONLY",
        "reference_version": matrix["boptest_commit"],
        "csv_sha256": file_hash(run / "evaluation.csv"),
        "missing_inputs": ["absorbed solar", "full initial state"],
        "signals": [
            {
                "quantity": name,
                "unit": unit,
                "interpolation": "linear" if unit in ("K", "J") else "previous",
            }
            for name, unit in REQUIRED.items()
        ],
    }
    write_json(run / "comparison_metadata.json", meta)
    report = {
        "status": "executed_partial_not_validated",
        "matlab_execution_completed": True,
        "simulation_returned": True,
        "model_name": "THERMA_BOPTEST_ThermalZone_C2",
        "model_version": "SYNTHETIC_TEST_ONLY",
        "matlab_version": "SYNTHETIC TEST - NOT MATLAB EXECUTION",
        "simulink": "synthetic test only",
        "registry_sha256": REGISTRY_HASH,
        "replay_metadata": packet,
        "assumptions": {
            "parameters": {
                "rho_air_kg_m3": {"value": 1.2, "unit": "kg/m3"},
                "cp_air_J_kgK": {"value": 1006, "unit": "J/(kg.K)"},
            }
        },
    }
    write_json(run / "replay_run.json", report)
    return run, ref


def test_full_analysis_known_errors_and_read_only(exports, tmp_path):
    run, ref = exports
    paths = [*run.iterdir(), *ref.iterdir()]
    hashes = {p: file_hash(p) for p in paths}
    report = analyze_run(run, tmp_path / "analysis", ref, plots=False)
    metrics = report["reference_comparison"]["metrics"]
    for name in ("mae", "rmse", "maximum_absolute_error", "mean_bias_error"):
        assert metrics[name] == pytest.approx(2)
    assert metrics["analysis_grid"]["samples"] == 3
    checks = report["physical_checks"]
    assert checks["integrated_energy_balance"]["status"] == "blocked"
    assert checks["stored_energy"]["change_J"] == 20
    assert (
        checks["signed_heating"]["delivered_heating_radiative_power"][
            "negative_signed_energy_J_reconstructed"
        ]
        == -4
    )
    assert checks["ventilation"]["maximum_formula_discrepancy_W"] == pytest.approx(0)
    assert all(file_hash(p) == value for p, value in hashes.items())
    text = (tmp_path / "analysis/engineering_summary.md").read_text()
    assert "not validation" in text or "no BOPTEST validation" in text
    with pytest.raises(FileExistsError):
        analyze_run(run, tmp_path / "analysis", ref, plots=False)


def test_missing_reference_blocks_metrics(exports, tmp_path):
    run, _ = exports
    report = analyze_run(run, tmp_path / "no_reference", plots=False, auto_reference=False)
    assert report["reference_comparison"]["status"] == "blocked"
    assert report["reference_comparison"]["metrics"] is None
    report = analyze_run(run, tmp_path / "missing_reference", tmp_path / "absent", plots=False)
    assert report["reference_comparison"]["status"] == "blocked"


def test_actual_three_exports_required(tmp_path):
    with pytest.raises(FileNotFoundError, match="actual MATLAB files"):
        load_replay(tmp_path)


@pytest.mark.parametrize(
    "change",
    [
        "failed",
        "no_simulation",
        "wrong_model",
        "wrong_scenario",
        "wrong_registry",
        "warmup",
        "duplicate",
        "nan",
        "hash",
        "wrong_units",
    ],
)
def test_invalid_exports_rejected(exports, change):
    run, _ = exports
    path = run / "replay_run.json"
    report = json.loads(path.read_text())
    metadata = json.loads((run / "comparison_metadata.json").read_text())
    if change == "failed":
        report["status"] = "failed"
    elif change == "no_simulation":
        report["simulation_returned"] = False
    elif change == "wrong_model":
        report["model_name"] = "other"
    elif change == "wrong_scenario":
        metadata["scenario_id"] = "other"
    elif change == "wrong_registry":
        report["registry_sha256"] = "0" * 64
    elif change == "wrong_units":
        metadata["signals"][0]["unit"] = "W"
    elif change in ("warmup", "duplicate", "nan"):
        data = np.loadtxt(run / "evaluation.csv", delimiter=",", skiprows=1)
        if change == "warmup":
            data[0, 0] = 0
        elif change == "duplicate":
            data[1, 0] = data[0, 0]
        else:
            data[0, 1] = float("nan")
        header = (run / "evaluation.csv").read_text().splitlines()[0]
        np.savetxt(run / "evaluation.csv", data, delimiter=",", header=header, comments="")
        metadata["csv_sha256"] = file_hash(run / "evaluation.csv")
    elif change == "hash":
        metadata["csv_sha256"] = "0" * 64
    write_json(path, report)
    write_json(run / "comparison_metadata.json", metadata)
    with pytest.raises(ValueError):
        load_replay(run)


def test_source_identity_mismatch_blocks_reference_metrics(exports, tmp_path):
    run, ref = exports
    path = run / "replay_run.json"
    report = json.loads(path.read_text())
    report["replay_metadata"]["reference_manifest_sha256"] = "0" * 64
    write_json(path, report)
    analyzed = analyze_run(run, tmp_path / "bad_source", ref, plots=False)
    assert analyzed["reference_comparison"]["status"] == "blocked"
    assert analyzed["reference_comparison"]["metrics"] is None


def test_unit_conversion_preserves_original_csv(exports):
    run, _ = exports
    data = np.loadtxt(run / "evaluation.csv", delimiter=",", skiprows=1)
    data[:, 1] -= 273.15
    header = (run / "evaluation.csv").read_text().splitlines()[0]
    np.savetxt(run / "evaluation.csv", data, delimiter=",", header=header, comments="")
    update_csv_hash(run)
    metadata = json.loads((run / "comparison_metadata.json").read_text())
    metadata["signals"][0]["unit"] = "degC"
    write_json(run / "comparison_metadata.json", metadata)
    series, _, _ = load_replay(run)
    np.testing.assert_allclose(series["air_temperature"].values, [293, 294, 295])


def test_reference_negative_samples_are_not_clamped(exports):
    _, ref = exports
    audit = reference_sign_audit(ref)
    assert audit["radiative"]["negative_sample_count"] == 1
    assert audit["radiative"]["minimum"] == -4
    assert audit["convective"]["negative_sample_count"] == 1
    assert audit["total"]["negative_sample_count"] == 0


def test_linear_negative_integral_splits_zero_crossing():
    result = signed_power(np.array([0.0, 2.0]), np.array([-2.0, 2.0]), "linear")
    assert result["negative_signed_energy_J_reconstructed"] == pytest.approx(-1)
    assert result["negative_duration_s_reconstructed"] == pytest.approx(1)
    assert result["signed_energy_J_reconstructed"] == 0


@pytest.mark.skipif(
    importlib.util.find_spec("matplotlib") is None, reason="optional plotting dependency"
)
def test_publication_plot_exports(exports, tmp_path):
    run, ref = exports
    report = analyze_run(run, tmp_path / "plots", ref, plots=True)
    assert report["plots"]["status"] == "generated"
    assert len(report["plots"]["files"]) == 12
    pdf = tmp_path / "plots/plots/06_reference_air_comparison.pdf"
    assert pdf.read_bytes().startswith(b"%PDF")


def test_integral_energy_closure_requires_complete_net_power(exports, tmp_path):
    run, _ = exports
    path = run / "evaluation.csv"
    header = path.read_text().splitlines()[0]
    data = np.loadtxt(path, delimiter=",", skiprows=1)
    np.savetxt(
        path,
        np.column_stack([data, [10.0, 10.0, 10.0]]),
        delimiter=",",
        header=header + ",net_external_power",
        comments="",
    )
    update_csv_hash(run)
    meta = json.loads((run / "comparison_metadata.json").read_text())
    meta["signals"].append(
        {"quantity": "net_external_power", "unit": "W", "interpolation": "previous"}
    )
    write_json(run / "comparison_metadata.json", meta)
    report = analyze_run(run, tmp_path / "closed_boundary", plots=False, auto_reference=False)
    diagnostic = report["physical_checks"]["integrated_energy_balance"]
    assert diagnostic["status"] == "sampled_diagnostic_not_accuracy_pass"
    assert diagnostic["maximum_absolute_residual_J"] == 0


def test_reference_operative_temperature_not_substituted_for_air(exports, tmp_path):
    run, ref = exports
    path = ref / "evaluation.csv"
    path.write_text(path.read_text().replace(SOURCE_AIR, "reaTRoo_y"))
    definitions = json.loads((ref / "signals.json").read_text())
    definitions[0]["name"] = "reaTRoo_y"
    write_json(ref / "signals.json", definitions)
    manifest = json.loads((ref / "manifest.json").read_text())
    for name in ("evaluation.csv", "signals.json"):
        manifest["artifacts"][name] = file_hash(ref / name)
    write_json(ref / "manifest.json", manifest)
    report = json.loads((run / "replay_run.json").read_text())
    report["replay_metadata"]["reference_manifest_sha256"] = file_hash(ref / "manifest.json")
    report["replay_metadata"]["source_signals_sha256"] = file_hash(ref / "signals.json")
    write_json(run / "replay_run.json", report)
    analyzed = analyze_run(run, tmp_path / "no_air", ref, plots=False)
    assert analyzed["reference_comparison"]["status"] == "blocked"
    assert analyzed["reference_comparison"]["metrics"] is None


def test_driver_diagnostics_interpolation_and_interval_guard(exports):
    run, _ = exports
    path = run / "replay_run.json"
    report = json.loads(path.read_text())
    report["drivers"] = [
        {
            "block": f"Replay_Source_{j:02d}",
            "samples": 4,
            "first_time_s": 0,
            "last_time_s": 3,
            "interpolation": "linear" if j == 1 else "previous",
            "block_interpolate": "on" if j == 1 else "off",
        }
        for j in range(1, 12)
    ]
    report["start_time_s"] = "0"
    report["stop_time_s"] = "3"
    write_json(path, report)
    load_replay(run)
    report["drivers"][1]["block_interpolate"] = "on"
    write_json(path, report)
    with pytest.raises(ValueError, match="interpolation"):
        load_replay(run)
