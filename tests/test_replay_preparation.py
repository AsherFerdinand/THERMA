"""Replay input algebra and contracts only; no thermal solver or synthetic evidence."""

import json

import numpy as np
import pytest

from therma.validation.archive import sha256
from therma.validation.replay import INPUTS, event_samples, prepare, validate_matrix


@pytest.fixture
def reference_run(tmp_path):
    run = tmp_path / "source"
    run.mkdir()
    names = [row[0] for row in INPUTS]
    t = np.array([0.0, 30.0, 60.0])
    data = np.array(
        [
            [293.15, 0, 0, -29.2, -43.8],
            [283.15, -650, -350, -29.2, -43.8],
            [283.15, -650, -350, -29.2, -43.8],
        ]
    )
    np.savetxt(
        run / "trajectory.csv",
        np.column_stack([t, data]),
        delimiter=",",
        header=",".join(["time_s", *names]),
        comments="",
    )
    (run / "signals.json").write_text(
        json.dumps([{"name": row[0], "unit": row[2]} for row in INPUTS])
    )
    matrix = validate_matrix()
    manifest = {
        "status": "success",
        "source_fmu_unchanged": True,
        "fmu": {"sha256": matrix["fmu_sha256"]},
        "boptest_commit": matrix["boptest_commit"],
        "scenario": {
            "name": "synthetic_contract_fixture",
            "initialization_time_s": 0,
            "evaluation_start_s": 30,
            "evaluation_end_s": 60,
        },
        "artifacts": {
            n: sha256((run / n).read_bytes()) for n in ["trajectory.csv", "signals.json"]
        },
    }
    (run / "manifest.json").write_text(json.dumps(manifest))
    return run


def test_no_silent_missing_boundary_conditions(reference_run, tmp_path):
    with pytest.raises(ValueError, match="Full replay blocked"):
        prepare(reference_run, tmp_path / "full")
    metadata = prepare(reference_run, tmp_path / "partial", partial=True)
    data = np.loadtxt(tmp_path / "partial/inputs.csv", delimiter=",", skiprows=1)
    np.testing.assert_array_equal(data[:, 2], [0, 650, 650])
    np.testing.assert_array_equal(data[:, 3], [0, 350, 350])
    np.testing.assert_array_equal(data[:, 6:], np.zeros((3, 6)))
    assert metadata["classification"] == "exploratory_comparison"
    assert len(metadata["missing_inputs"]) == 2
    assert metadata["channels"][0]["interpolation"] == "linear"
    assert metadata["channels"][1]["interpolation"] == "previous"
    assert "partial" in metadata["scenario_id"]
    with pytest.raises(FileExistsError):
        prepare(reference_run, tmp_path / "partial", partial=True)


def test_tampered_reference_rejected(reference_run, tmp_path):
    (reference_run / "trajectory.csv").write_text("tampered")
    with pytest.raises(ValueError, match="hash mismatch"):
        prepare(reference_run, tmp_path / "bad", partial=True)


def test_missing_or_incompatible_required_input(reference_run, tmp_path):
    definitions = json.loads((reference_run / "signals.json").read_text())
    definitions[0]["unit"] = "Pa"
    (reference_run / "signals.json").write_text(json.dumps(definitions))
    manifest = json.loads((reference_run / "manifest.json").read_text())
    manifest["artifacts"]["signals.json"] = sha256((reference_run / "signals.json").read_bytes())
    (reference_run / "manifest.json").write_text(json.dumps(manifest))
    with pytest.raises(ValueError, match="wrong unit"):
        prepare(reference_run, tmp_path / "bad", partial=True)


def test_duplicate_events_preserve_holds_without_smearing():
    t = np.array([0.0, 1.0, 1.0, 2.0])
    y = np.array([0.0, 0.0, 1000.0, 1000.0])
    time, value = event_samples(t, y, "previous")
    np.testing.assert_array_equal(time, [0, 1, 2])
    np.testing.assert_array_equal(value, [0, 1000, 1000])
    with pytest.raises(ValueError, match="duplicate-time jump"):
        event_samples(t, y, "linear")
    time, _ = event_samples(t, np.ones(4), "linear")
    assert len(time) == 3


def test_critical_compatibility_categories(tmp_path):
    matrix = validate_matrix()
    rows = {row["quantity"]: row for row in matrix["signals"]}
    assert rows["radiative_temperature"]["comparison_status"] == "proxy_only"
    assert rows["gas_input_power"]["comparison_status"] == "not_comparable"
    rows["radiative_temperature"]["comparison_status"] = "directly_comparable"
    file = tmp_path / "bad.json"
    file.write_text(json.dumps(matrix))
    with pytest.raises(ValueError):
        validate_matrix(file)


def test_replay_converts_source_units_explicitly(reference_run, tmp_path):
    csv = reference_run / "trajectory.csv"
    definitions = json.loads((reference_run / "signals.json").read_text())
    names = ["time_s", *[row["name"] for row in definitions]]
    data = np.loadtxt(csv, delimiter=",", skiprows=1)
    data[:, 1] -= 273.15
    definitions[0]["unit"] = "degC"
    data[:, 2] /= 1000
    definitions[1]["unit"] = "kW"
    np.savetxt(csv, data, delimiter=",", header=",".join(names), comments="")
    (reference_run / "signals.json").write_text(json.dumps(definitions))
    manifest = json.loads((reference_run / "manifest.json").read_text())
    for name in ["trajectory.csv", "signals.json"]:
        manifest["artifacts"][name] = sha256((reference_run / name).read_bytes())
    (reference_run / "manifest.json").write_text(json.dumps(manifest))
    metadata = prepare(reference_run, tmp_path / "converted", partial=True)
    output = np.loadtxt(tmp_path / "converted/inputs.csv", delimiter=",", skiprows=1)
    np.testing.assert_allclose(output[:, 1], [293.15, 283.15, 283.15])
    np.testing.assert_allclose(output[:, 2], [0, 650, 650])
    assert metadata["channels"][0]["source_unit"] == "degC"
