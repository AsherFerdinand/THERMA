"""Synthetic small export fixtures test diagnostics, not MATLAB execution evidence."""

import importlib.util
import json
import shutil

import numpy as np
import pytest
from test_solar_replay import write

from therma.validation.analysis import OPTIONAL, REQUIRED
from therma.validation.archive import REGISTRY_HASH, sha256
from therma.validation.benchmark import day_metrics, metrics, paired
from therma.validation.replay import prepare
from therma.validation.solar import prepare_solar

pytest_plugins = ["test_solar_replay"]


def exports(folder, packet, offset):
    folder.mkdir()
    m = json.loads((packet / "replay.json").read_text())
    quantities = REQUIRED | OPTIONAL
    values = {q: np.array([0.0, 0.0]) for q in quantities}
    values["air_temperature"] = np.array([294.0, 295.0]) + offset
    values["outdoor_temperature"] = np.array([293.15, 293.15])
    values["stored_thermal_energy"] = np.array([0.0, 30.0])
    values["net_external_power"] = np.array([1.0, 1.0])
    values["stored_energy_derivative"] = np.array([1.0, 1.0])
    np.savetxt(
        folder / "evaluation.csv",
        np.column_stack([[30, 60], *values.values()]),
        delimiter=",",
        comments="",
        header=",".join(["time_s", *values]),
    )
    write(
        folder / "comparison_metadata.json",
        {
            "schema_version": 1,
            "classification": "exploratory_comparison",
            "scenario_id": m["scenario_id"],
            "reference_version": m["reference_version"],
            "model_version": "SYNTHETIC_TEST_ONLY",
            "csv_sha256": sha256((folder / "evaluation.csv").read_bytes()),
            "signals": [
                {
                    "quantity": q,
                    "unit": u,
                    "interpolation": "linear" if u in ["K", "J"] else "previous",
                }
                for q, u in quantities.items()
            ],
        },
    )
    write(
        folder / "replay_run.json",
        {
            "status": "executed_partial_not_validated",
            "matlab_execution_completed": True,
            "simulation_returned": True,
            "model_name": "THERMA_BOPTEST_ThermalZone_C2",
            "model_version": "SYNTHETIC_TEST_ONLY",
            "matlab_version": "SYNTHETIC TEST ONLY",
            "replay_metadata": m,
            "registry_sha256": REGISTRY_HASH,
            "assumptions_sha256": "a" * 64,
            "replay_packet_sha256": sha256((packet / "replay.json").read_bytes()),
            "assumptions": {},
            "solver": {"MaxStep_s": "30"},
        },
    )


@pytest.mark.parametrize("plots", [False, True])
def test_controlled_pair_energy_and_sensitivity(runs, tmp_path, plots):
    if plots and importlib.util.find_spec("matplotlib") is None:
        pytest.skip("Optional plotting dependency")
    run, base = runs
    for folder in runs:
        data = np.loadtxt(folder / "trajectory.csv", delimiter=",", skiprows=1)
        header = (folder / "trajectory.csv").read_text().splitlines()[0]
        np.savetxt(folder / "evaluation.csv", data[1:], delimiter=",", comments="", header=header)
        m = json.loads((folder / "manifest.json").read_text())
        m["artifacts"]["evaluation.csv"] = sha256((folder / "evaluation.csv").read_bytes())
        write(folder / "manifest.json", m)
    prepare(base, tmp_path / "old", partial=True)
    prepare_solar(run, base, tmp_path / "new")
    exports(tmp_path / "b", tmp_path / "old", -2)
    exports(tmp_path / "s", tmp_path / "new", -1)
    shutil.copytree(tmp_path / "s", tmp_path / "step")
    result = paired(
        tmp_path / "b",
        tmp_path / "s",
        run,
        tmp_path / "out",
        plots=plots,
        step_run=tmp_path / "step",
    )
    assert result["baseline"]["MAE_K"] == 2
    assert result["solar"]["bias_K"] == -1
    assert result["solar_minus_baseline"]["bias_K"] == 1
    assert result["solver_step_sensitivity"]["temperature_difference"]["MAE_K"] == 0
    analysis = json.loads((tmp_path / "out/solar/metrics.json").read_text())
    assert analysis["physical_checks"]["integrated_energy_balance"]["final_residual_J"] == 0
    if plots:
        assert (tmp_path / "out/controlled_comparison.pdf").is_file()


def test_daily_boundaries_and_invalid_metrics():
    t = np.array([0.0, 43200.0, 86400.0, 129600.0, 172800.0])
    rows = day_metrics(t, np.array([1.0, 1.0, 2.0, 2.0, 2.0]))
    assert len(rows) == 2 and rows[0]["MAE_K"] == 1 and rows[1]["samples"] == 3
    with pytest.raises(ValueError):
        metrics(np.array([np.nan]))
    with pytest.raises(ValueError):
        day_metrics(np.array([1.0, 1.0]), np.array([1.0, 1.0]))
