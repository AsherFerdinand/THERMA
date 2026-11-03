"""Small synthetic contract tests, never new MATLAB or convergence evidence."""

import importlib.util
import json
from pathlib import Path

import numpy as np
import pytest
from test_solar_benchmark import exports
from test_solar_replay import write

from therma.validation.analysis import file_hash
from therma.validation.replay import prepare
from therma.validation.solar import prepare_solar
from therma.validation.study import EXPERIMENTS, analyze_study, event_balance, load_study

pytest_plugins = ["test_solar_replay"]


def events(path, *, duplicate=True):
    t = [30, 45, 45, 60] if duplicate else [30, 45, 60]
    # Exact E for q=1 then q=3. Duplicate records retain left/right event sides.
    q = [1, 1, 3, 3] if duplicate else [1, 3, 3]
    e = [0, 15, 15, 60] if duplicate else [0, 15, 60]
    np.savetxt(
        path,
        np.column_stack([t, e, q, q, q, np.zeros(len(t))]),
        delimiter=",",
        comments="",
        header="time_s,stored_thermal_energy,net_external_power,stored_energy_derivative,prescribed_power,power_balance_residual",
    )


def test_ordered_event_integral_preserves_jump_and_rejects_reverse_time(tmp_path):
    path = tmp_path / "events.csv"
    events(path)
    result, trace = event_balance(path)
    assert result["duplicate_timestamps"] == 1
    assert result["final_discrepancy_J"] == 0 and trace[-1, 2] == 60
    events(path, duplicate=False)
    result, _ = event_balance(path)
    assert (
        result["final_discrepancy_J"] != 0
    )  # Sparse logs alone do not preserve the event left limit.
    data = np.loadtxt(path, delimiter=",", skiprows=1)
    data[1, 0] = 29
    np.savetxt(path, data, delimiter=",", comments="", header=path.read_text().splitlines()[0])
    with pytest.raises(ValueError, match="ordered"):
        event_balance(path)


@pytest.fixture
def study(runs, tmp_path):
    source, baseline = runs
    for folder in runs:
        raw = np.loadtxt(folder / "trajectory.csv", delimiter=",", skiprows=1)
        header = (folder / "trajectory.csv").read_text().splitlines()[0]
        np.savetxt(folder / "evaluation.csv", raw[1:], delimiter=",", comments="", header=header)
        m = json.loads((folder / "manifest.json").read_text())
        m["artifacts"]["evaluation.csv"] = file_hash(folder / "evaluation.csv")
        write(folder / "manifest.json", m)
    prepare(baseline, tmp_path / "old", partial=True)
    prepare_solar(source, baseline, tmp_path / "new")
    root = tmp_path / "study"
    session = root / "session"
    session.mkdir(parents=True)
    from therma.validation.archive import REGISTRY_HASH

    contract = {
        "matlab_version": "SYNTHETIC TEST ONLY",
        "simulink": {"Version": "synthetic"},
        "sources": [{"name": "run_boptest_zone_replay.m", "sha256": "c" * 64}],
        "frozen_registry_sha256": REGISTRY_HASH,
        "assumptions_sha256": "a" * 64,
    }
    write(session / "contract.json", contract)
    contract_hash = file_hash(session / "contract.json")
    index = {"status": "completed", "contract_sha256": contract_hash, "experiments": {}}
    for name, step in EXPERIMENTS.items():
        folder = root / name / "attempt"
        folder.parent.mkdir()
        exports(
            folder,
            tmp_path / ("old" if name == "no_solar_30" else "new"),
            -2 if name == "no_solar_30" else -1,
        )
        r = json.loads((folder / "replay_run.json").read_text())
        r.update(
            matlab_version=contract["matlab_version"],
            simulink=contract["simulink"],
            elapsed_simulation_s=1.0,
            driver_source_sha256="c" * 64,
        )
        r["solver"] = {"name": "ode15s", "RelTol": "1e-7", "AbsTol": "1e-9", "MaxStep_s": str(step)}
        write(folder / "replay_run.json", r)
        write(
            folder / "solver_metadata.json",
            {"solver": r["solver"], "status": r["status"], "elapsed_simulation_s": 1.0},
        )
        events(folder / "energy_events.csv")
        expected = {
            "experiment_id": name,
            "max_step_s": step,
            "contract_sha256": contract_hash,
            "matlab_version": contract["matlab_version"],
            "packet_sha256": r["replay_packet_sha256"],
        }
        artifacts = [{"name": p.name, "sha256": file_hash(p)} for p in folder.iterdir()]
        write(
            folder / "completion.json",
            {"status": "completed", "expected": expected, "artifacts": artifacts},
        )
        index["experiments"][name] = {
            "status": "completed",
            "folder": f"{name}/attempt",
            "completion_sha256": file_hash(folder / "completion.json"),
        }
    write(session / "study_index.json", index)
    return session / "study_index.json", source


@pytest.mark.parametrize("plots", [False, True])
def test_actual_only_pipeline_contracts_and_six_figure_pairs(study, tmp_path, plots):
    if plots and importlib.util.find_spec("matplotlib") is None:
        pytest.skip("Optional plotting")
    index, reference = study
    assert len(load_study(index)) == 4
    result = analyze_study(index, reference, tmp_path / "analysis", plots=plots)
    assert result["temperature_metrics"]["solar_30"]["MAE_K"] == 1
    assert result["step_differences"]["solar_30_minus_solar_5"]["MAE_K"] == 0
    assert result["energy_balances"]["solar_5"]["final_discrepancy_J"] == 0
    if plots:
        assert len(list((tmp_path / "analysis").glob("figure_*.pdf"))) == 6
        assert len(list((tmp_path / "analysis").glob("figure_*.png"))) == 6


@pytest.mark.parametrize("change", ["corrupt", "receipt", "incomplete", "traversal", "release"])
def test_study_rejects_incomplete_or_corrupt_evidence(study, change):
    index, _ = study
    data = json.loads(index.read_text())
    folder = index.parent.parent / "solar_15/attempt"
    if change == "corrupt":
        (folder / "evaluation.csv").write_text("corrupt")
    elif change == "receipt":
        data["experiments"]["solar_15"]["completion_sha256"] = "0" * 64
    elif change == "incomplete":
        data["status"] = "running"
    elif change == "traversal":
        data["experiments"]["solar_15"]["folder"] = "../escape"
    else:
        # Even a self-consistent receipt cannot authorize a mixed-release study.
        r = json.loads((folder / "replay_run.json").read_text())
        r["matlab_version"] = "OTHER RELEASE"
        write(folder / "replay_run.json", r)
        receipt = json.loads((folder / "completion.json").read_text())
        for a in receipt["artifacts"]:
            if a["name"] == "replay_run.json":
                a["sha256"] = file_hash(folder / "replay_run.json")
        write(folder / "completion.json", receipt)
        data["experiments"]["solar_15"]["completion_sha256"] = file_hash(folder / "completion.json")
    write(index, data)
    with pytest.raises(ValueError):
        load_study(index)


def test_matlab_study_workflow_keeps_physics_separate():
    root = Path(__file__).resolve().parents[1]
    runner = (root / "scripts/matlab/boptest/run_boptest_zone_replay.m").read_text()
    assert "executed_smoke_not_benchmark" in runner
    assert "'time_s',firstSeries.Time(:)" in runner
    assert (
        "'elapsed_simulation_s'" not in runner
    )  # Runtime is measured with tic/toc, not an invented literal.
    assert "toc(simulationClock)" in runner
    study = (root / "scripts/matlab/boptest/run_boptest_c27.m").read_text()
    assert "boptest_c27_completed(candidate,expected)" in study
    assert "parfor" not in study and "clear sd nd" in study
    plan = json.loads((root / "configs/references/c27_study.json").read_text())
    assert [e["max_step_s"] for e in plan["experiments"]] == [30, 30, 15, 5]
