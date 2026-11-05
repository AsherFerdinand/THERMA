"""Selective controlled-pair integrity tests with synthetic software fixtures."""

import json

import pytest

from therma.validation.analysis import file_hash
from therma.validation.temperature_study import IDS, load_pair

pytest_plugins = ["test_solar_replay", "test_numerical_study"]


@pytest.fixture
def pair(study, tmp_path, monkeypatch):
    from therma.validation import temperature_study as module

    index_path, _ = study
    index = json.loads(index_path.read_text())
    contract_path = index_path.parent / "contract.json"
    contract = json.loads(contract_path.read_text())
    plan = {}
    for name, key in zip(IDS, ["no_solar", "solar"], strict=True):
        folder = index_path.parent.parent / index["experiments"][name]["folder"]
        receipt = json.loads((folder / "completion.json").read_text())
        plan[key + "_packet_sha256"] = receipt["expected"]["packet_sha256"]
    plan_file = tmp_path / "configs/references/c27_study.json"
    plan_file.parent.mkdir(parents=True)
    plan_file.write_text(json.dumps(plan))
    contract["plan_sha256"] = file_hash(plan_file)
    contract_path.write_text(json.dumps(contract))
    index["contract_sha256"] = file_hash(contract_path)
    for name in IDS:
        folder = index_path.parent.parent / index["experiments"][name]["folder"]
        report_path = folder / "replay_run.json"
        report = json.loads(report_path.read_text())
        report["export_completed"] = True
        report_path.write_text(json.dumps(report))
        receipt_path = folder / "completion.json"
        receipt = json.loads(receipt_path.read_text())
        receipt["expected"]["contract_sha256"] = index["contract_sha256"]
        for artifact in receipt["artifacts"]:
            if artifact["name"] == "replay_run.json":
                artifact["sha256"] = file_hash(report_path)
        receipt_path.write_text(json.dumps(receipt))
        index["experiments"][name]["completion_sha256"] = file_hash(receipt_path)
        # These files aren't consumed or claimed verified by selective pair loading.
        (folder / "energy_events.csv").unlink()
        (folder / "solver_metadata.json").unlink()
    index_path.write_text(json.dumps(index))
    monkeypatch.setattr(module, "ROOT", tmp_path)
    return index_path


def test_selective_pair_works_without_unsupplied_event_data(pair):
    data, provenance = load_pair(pair)
    assert set(data) == set(IDS)
    assert "energy_events.csv" in provenance["solar_30"]["unverified_unsupplied_artifacts"]
    assert provenance["independent_MATLAB_execution"] is False


@pytest.mark.parametrize("change", ["csv", "receipt", "contract", "path"])
def test_selective_pair_rejects_tampering(pair, change):
    index = json.loads(pair.read_text())
    folder = pair.parent.parent / index["experiments"]["solar_30"]["folder"]
    if change == "csv":
        (folder / "evaluation.csv").write_text("tampered")
    elif change == "receipt":
        (folder / "completion.json").write_text("{}")
    elif change == "contract":
        (pair.parent / "contract.json").write_text("{}")
    else:
        index["experiments"]["solar_30"]["folder"] = "../escape"
        pair.write_text(json.dumps(index))
    with pytest.raises(ValueError):
        load_pair(pair)


def test_packaged_pair_preserves_original_bytes_and_runs_after_source_removed(pair, tmp_path):
    import importlib.util
    import shutil
    from pathlib import Path

    script = Path(__file__).resolve().parents[1] / "scripts/boptest/package_c28.py"
    spec = importlib.util.spec_from_file_location("package_c28", script)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    payload, metadata = module.study_payload(pair)
    assert len(payload) == 10
    assert len(metadata["study_artifacts"]) == 10
    empty = tmp_path / "empty-extraction"
    for name, raw in payload.items():
        path = empty / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(raw)
    # Original study no longer exists; only the extracted tree can satisfy reads.
    shutil.rmtree(pair.parent.parent)
    extracted_index = empty / metadata["study_index"]
    loaded, _ = load_pair(extracted_index)
    assert set(loaded) == set(IDS)
    for artifact in metadata["study_artifacts"]:
        assert file_hash(empty / artifact["path"]) == artifact["sha256"]


def test_packaging_rejects_missing_original_trajectory(pair):
    import importlib.util
    from pathlib import Path

    spec = importlib.util.spec_from_file_location(
        "package_c28", Path(__file__).resolve().parents[1] / "scripts/boptest/package_c28.py"
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    index = json.loads(pair.read_text())
    folder = pair.parent.parent / index["experiments"]["solar_30"]["folder"]
    (folder / "evaluation.csv").unlink()
    with pytest.raises(FileNotFoundError):
        module.study_payload(pair)
