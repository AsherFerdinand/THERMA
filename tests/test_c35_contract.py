"""Real prior gate and new study software contracts; no C3.5 simulation claims."""

import hashlib
import importlib.util
import json
import subprocess
from pathlib import Path
from zipfile import ZipFile

import pytest

ROOT = Path(__file__).resolve().parents[1]


def test_actual_c34_gate_and_immutable_sources():
    gate = json.loads((ROOT / "verification/c3/c34_gate/summary.json").read_text())
    assert (gate["tests_passed"], gate["tests_failed"], gate["tests_incomplete"]) == (17, 0, 0)
    assert gate["nominal_simulation_completed"] and "R2025a" in gate["matlab_version"]
    assert all(gate["diagnostics"]["checks"].values())
    assert gate["diagnostics"]["combined_integrated_error_max_J"] < 1e-3
    for item in gate["integration_sources"]:
        assert hashlib.sha256((ROOT / item["name"]).read_bytes()).hexdigest() == item["sha256"]
    assert (
        hashlib.sha256((ROOT / "configs/c3/integration_c34.json").read_bytes()).hexdigest()
        == gate["integration_config_sha256"]
    )
    assert "rz-home" not in (ROOT / "verification/c3/c34_gate/summary.json").read_text()
    assert (
        "rz-home"
        not in (
            ROOT / "verification/c3/c34_gate/matlab_integration_test_log.redacted.txt"
        ).read_text()
    )


def test_plan_matches_requested_cases_and_explicit_solar():
    plan = json.loads((ROOT / "configs/c35/investigation.json").read_text())
    assert plan["UA_W_K"] == [60, 90, 120, 180]
    assert plan["supply_degC"] == [40, 45, 55, 65]
    assert plan["outdoor_degC"] == [-5, 0, 5, 10]
    assert plan["max_steps_s"] == [10, 5, 1]
    assert sum(plan["solar"]["surface_weights"]) == 1
    assert plan["solar"]["peak_total_W"] * 86400 * 0.25 / 3.6e6 == 3.6
    source = (ROOT / "scripts/matlab/c35/c35_build_case.m").read_text()
    assert "P.UA_W_K=c.UA_W_K" in source and "'Holding final value'" in source
    assert "'Interpolate','on'" in source
    assert "C35_solar" in source and "Thermal_zone/" in source


def test_all_package_profiles_enforce_required_files(tmp_path, monkeypatch):
    spec = importlib.util.spec_from_file_location(
        "packager", ROOT / "scripts/c3/package_components.py"
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    repo = tmp_path / "source"
    repo.mkdir()
    monkeypatch.chdir(repo)
    subprocess.run(["git", "init", "-q"], check=True)
    for name in module.C35_REQUIRED:
        path = repo / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("software packaging fixture only\n")

    def commit():
        subprocess.run(["git", "add", "."], check=True)
        subprocess.run(
            [
                "git",
                "-c",
                "user.name=Test",
                "-c",
                "user.email=test@example.invalid",
                "commit",
                "-qm",
                "Fixture",
            ],
            check=True,
        )

    commit()
    receipt = module.package("HEAD", tmp_path / "c35.zip", "investigation")
    assert receipt["scope"] == "C3.5 engineering investigation"
    with ZipFile(tmp_path / "c35.zip") as archive:
        assert archive.read("THERMA_C35_MATLAB/START_HERE.md") == archive.read(
            "THERMA_C35_MATLAB/START_C35.md"
        )
    (repo / "run_c35_investigation.m").unlink()
    commit()
    with pytest.raises(ValueError, match="Missing required"):
        module.package("HEAD", tmp_path / "bad.zip", "investigation")
    (repo / "run_c34_verification.m").unlink()
    commit()
    with pytest.raises(ValueError, match="Missing required"):
        module.package("HEAD", tmp_path / "bad_c34.zip", "integration")
    with pytest.raises(ValueError, match="Unknown"):
        module.package("HEAD", tmp_path / "unknown.zip", "invalid")
