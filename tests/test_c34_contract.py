"""Actual component evidence and integration packaging/static guards; no MATLAB execution."""

import hashlib
import importlib.util
import json
import subprocess
from pathlib import Path
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]


def test_actual_component_gate_and_source_identity():
    folder = ROOT / "verification/c3/component_gate"
    gate = json.loads((folder / "summary.json").read_text())
    assert (gate["tests_passed"], gate["tests_failed"], gate["tests_incomplete"]) == (13, 0, 0)
    assert "R2025a" in gate["matlab_version"]
    assert gate["simulink"]["Release"] == "(R2025a)"
    assert (
        gate["original_report_sha256"]
        == "82f4706b453a256c4cbd47f8869b1e2026701ee75537b9ed899c711288cce86a"
    )
    assert (
        hashlib.sha256((folder / "matlab_component_test_log.txt").read_bytes()).hexdigest()
        == gate["original_test_log_sha256"]
    )
    for item in gate["source_files"]:
        assert hashlib.sha256((ROOT / item["name"]).read_bytes()).hexdigest() == item["sha256"]
    assert gate["independently_executed_in_cloud"] is False
    assert gate["generated_model_hashes_verified"] is False
    assert "rz-home" not in (folder / "summary.json").read_text()


def test_frozen_zone_sources_are_not_rewritten():
    evidence = json.loads(
        (ROOT / "verification/c2/matlab-r2025a/b00092e4236789a4/metadata.json").read_text()
    )
    for name in [
        "build_boptest_zone_c2.m",
        "load_boptest_zone_parameters.m",
        "load_boptest_envelope_parameters.m",
        "add_boptest_construction.m",
    ]:
        path = "scripts/matlab/boptest/" + name
        assert (
            hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == evidence["source_files"][path]
        )


def test_new_heating_coupling_and_energy_boundary_are_explicit():
    source = (ROOT / "scripts/matlab/c3/build_c34_model.m").read_text()
    for connection in [
        "w('Thermal_zone/1','Thermostat/2')",
        "w('Thermostat/1','Valve/1')",
        "w('Valve/1','Radiator/1')",
        "w('Thermal_zone/1','Radiator/3')",
        "w('Radiator/2','Zone_inputs/2')",
        "w('Radiator/3','Zone_inputs/3')",
        "w('Zone_inputs/1','Thermal_zone/1')",
    ]:
        assert source.count(connection) == 1
    assert "ports=[4 6 7 9 10]" in source  # Environment excludes radiator delivery.
    assert "w('Radiator/6','Combined_external_W/2')" in source  # Water heat once.
    assert "copyContentsToSubSystem" in source
    assert "Z.envelope.components(k).initial_K(:)=I.initial_zone_K" in source
    assert "replay.json" not in source and "reaQHea_y" not in source


def test_initial_fixture_is_explicit_not_a_reference_scenario():
    config = json.loads((ROOT / "configs/c3/integration_c34.json").read_text())
    assert config["classification"] == "illustrative_C34_integration_not_BOPTEST_benchmark"
    p = config["parameters"]
    assert p["initial_zone_K"]["value"] == 288.15
    assert p["setpoint_K"]["value"] == 294.15
    assert p["supply_K"]["value"] == 328.15
    assert p["solar_W"]["value"] == [0] * 6
    assert p["internal_convective_W"]["value"] == 0
    assert p["internal_radiative_W"]["value"] == 0
    assert all(item["unit"] and item["source"] for item in p.values())
    assert config["heating_enabled"] is True


def test_integration_package_has_frozen_builders_gate_and_local_entrypoint(tmp_path, monkeypatch):
    spec = importlib.util.spec_from_file_location(
        "c34_packager", ROOT / "scripts/c3/package_components.py"
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    repo = tmp_path / "source"
    repo.mkdir()
    subprocess.run(["git", "init", "-q", str(repo)], check=True)
    for name in module.C34_REQUIRED:
        path = repo / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("synthetic packaging fixture only\n")
    monkeypatch.chdir(repo)
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
            "Synthetic integration package",
        ],
        check=True,
    )
    result = module.package("HEAD", tmp_path / "c34.zip", "integration")
    assert result["scope"] == "C3.4 closed-loop integration"
    with ZipFile(tmp_path / "c34.zip") as z:
        assert z.read("THERMA_C34_MATLAB/START_HERE.md") == z.read("THERMA_C34_MATLAB/START_C34.md")
        for name in module.C34_REQUIRED:
            assert "THERMA_C34_MATLAB/" + name in z.namelist()
        assert not any("/outputs/" in name for name in z.namelist())
        provenance = json.loads(z.read("THERMA_C34_MATLAB/C34_PACKAGE_PROVENANCE.json"))
        assert provenance["matlab_execution_in_cloud"] is False
        assert provenance["raw_datasets_required"] is False
