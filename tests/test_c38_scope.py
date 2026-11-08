"""C3.8 changes only thermostat settings; preserve verified component sources."""

import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_c38_reuses_checks_and_generates_only_two_plots():
    entry = (ROOT / "run_c38_thermostat_comparison.m").read_text()
    builder = (ROOT / "scripts/matlab/c38/c38_build_case.m").read_text()
    check = (ROOT / "scripts/matlab/c38/c38_check_trace.m").read_text()
    assert "deadbands=[1 0.5]" in entry
    assert entry.count("fig=figure(") == 2
    assert "if k==1 && ~isempty(curves{1}), continue; end" in entry
    assert "P.deadband_K=deadband" in builder
    assert "copyfile(sourceModel,file)" in builder
    assert "assess_c34(" in check and "c35_metrics(" in check
    assert "[2 24]" in entry and "[2 8]" in entry
    assert "run_c37_residential_heating(" not in entry


def test_c37_dependencies_remain_the_published_purmo_sources():
    # Pinned C3.7 source hashes prevent accidental edits during this investigation.
    expected = {
        "run_c37_residential_heating.m": (
            "cffa6d1752e560926926ef7c508161def0a79f970f6f1e92c86d9a4ec296c18a"
        ),
        "scripts/matlab/c37/c37_room_parameters.m": (
            "0add223b11877c8cc3e03d4125634bdc2246c6ef1eee352c7b5a419de6128639"
        ),
        "scripts/matlab/c37/c37_radiator_parameters.m": (
            "7e66e6c7746c8ed583a5751981b1776977adaaaa9e92c7d2cab870e6198dac6b"
        ),
        "configs/c37/residential_room.json": (
            "098d5b2c794137b620fa55bd127097b4584a72b398b0a2b68c5c52e0fffe9b7a"
        ),
        "configs/c37/radiator_rating.json": (
            "3357a4bba3b25aa3d46642b42cb8a314530ce5100fcfd19aa9b8d8342f20092b"
        ),
        "scripts/matlab/c3/add_c3_thermostat.m": (
            "f825b5ca732d18c2b37b5d149ee521dee0788594bade0aa1b6d7b36eacb57e80"
        ),
        "scripts/matlab/c3/add_c3_radiator.m": (
            "18121ff2dd966278e4c604af26db26179b5482afc167fcb120db366b84431100"
        ),
        "scripts/matlab/c3/add_c3_valve.m": (
            "ddd9bdc43cde641bac3ec2b6db6b59e7cb18cc95f0676a257d10b44d00f333ce"
        ),
    }
    for name, digest in expected.items():
        assert hashlib.sha256((ROOT / name).read_bytes()).hexdigest() == digest
