"""C3 provenance/interface guards only; these do not execute MATLAB physics."""

import importlib.util
import json
import re
import subprocess
from pathlib import Path
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]


def test_illustrative_parameters_are_explicit_and_dimensioned():
    config = json.loads((ROOT / "configs/c3/illustrative_components.json").read_text())
    assert config["classification"] == "illustrative_assumptions_not_calibrated_not_BOPTEST"
    parameters = config["parameters"]
    assert len(parameters) == 17
    assert all(item["unit"] and item["source"] for item in parameters.values())
    value = lambda key: parameters[key]["value"]  # noqa: E731
    assert value("setpoint_K") - value("deadband_K") / 2 - 273.15 == 20.5
    assert value("setpoint_K") + value("deadband_K") / 2 - 273.15 == 21.5
    assert value("controller_initial") in (0, 1)
    assert 0 <= value("valve_initial") <= 1
    assert 0 <= value("radiative_fraction") <= 1
    assert value("opening_tau_s") > 0 and value("closing_tau_s") > 0
    # Every Simulink parameter expression resolves against explicit config/derived C.
    for path in (ROOT / "scripts/matlab/c3").glob("*.m"):
        fields = set(re.findall(r"\bC3\.([A-Za-z_]\w*)", path.read_text()))
        assert fields <= set(parameters) | {"capacitance_J_K"}


def test_native_component_interface_does_not_depend_on_replay_heating():
    directory = ROOT / "scripts/matlab/c3"
    component_files = {
        "load_c3_parameters.m",
        "c3_block.m",
        "add_c3_thermostat.m",
        "add_c3_valve.m",
        "add_c3_radiator.m",
        "build_c3_component.m",
        "simulate_c3_component.m",
    }
    sources = "\n".join((directory / name).read_text() for name in sorted(component_files))
    for forbidden in [
        "reaQHea_y",
        "mod.rad",
        "replay.json",
        "MATLAB Function",
        "sps_lib",
        "simscape",
    ]:
        assert forbidden not in sources
    runner = (ROOT / "run_c3_verification.m").read_text()
    assert "assertSuccess(results)" in runner
    assert "C3.1-C3.3_components_only" in runner
    assert "build_boptest_zone_c2" not in sources + runner


def test_component_package_is_self_contained_and_rejects_incomplete_source(tmp_path):
    spec = importlib.util.spec_from_file_location(
        "c3_packager", ROOT / "scripts/c3/package_components.py"
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    # Small synthetic source tree exercises packaging, not thermal behavior.
    repository = tmp_path / "repo"
    repository.mkdir()
    subprocess.run(["git", "init", "-q", str(repository)], check=True)
    for name in module.REQUIRED:
        path = repository / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("synthetic packaging fixture only\n")
    subprocess.run(["git", "-C", str(repository), "add", "."], check=True)
    subprocess.run(
        [
            "git",
            "-C",
            str(repository),
            "-c",
            "user.name=Test",
            "-c",
            "user.email=test@example.invalid",
            "commit",
            "-qm",
            "Synthetic package fixture",
        ],
        check=True,
    )
    commit = (
        subprocess.check_output(["git", "-C", str(repository), "rev-parse", "HEAD"])
        .decode()
        .strip()
    )
    import os

    import pytest

    previous = Path.cwd()
    try:
        os.chdir(repository)
        result = module.package(commit, tmp_path / "package.zip")
        assert result["matlab_execution"] == "pending"
        with ZipFile(tmp_path / "package.zip") as archive:
            assert archive.read("THERMA_C3_MATLAB/START_HERE.md") == archive.read(
                "THERMA_C3_MATLAB/START_C3.md"
            )
        (repository / "run_c3_verification.m").unlink()
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
                "Remove mandatory entrypoint",
            ],
            check=True,
        )
        with pytest.raises(ValueError, match="Missing required"):
            module.package("HEAD", tmp_path / "invalid.zip")
    finally:
        os.chdir(previous)
