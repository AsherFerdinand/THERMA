"""Actual imported-report regressions; mutated copies stay in pytest temp dirs."""

import copy
import json

import pytest

from therma.validation.archive import (
    ROOT,
    archive_report,
    read_json,
    sha256,
    validate_archive,
    validate_report,
)

EVIDENCE = ROOT / "verification/c2/matlab-r2025a/b00092e4236789a4"


@pytest.fixture
def report():
    return read_json((EVIDENCE / "verification.json").read_bytes())


def test_actual_archived_report_bytes_and_integrity():
    raw = (EVIDENCE / "verification.json").read_bytes()
    assert sha256(raw) == "b00092e4236789a4fca959fc0a18d779b038d4b686064d8d876a402e22c8babe"
    assert validate_archive(ROOT / "verification") == 1


def test_import_original_bytes_no_git_requirement_and_no_overwrite(tmp_path):
    original = EVIDENCE / "verification.json"
    target = archive_report(original, "C2", "R2025a", tmp_path)
    assert (target / "verification.json").read_bytes() == original.read_bytes()
    meta = read_json((target / "metadata.json").read_bytes())
    assert meta["source_git_commit"] is None
    assert meta["independently_reproduced_by_ci"] is False
    with pytest.raises(FileExistsError):
        archive_report(original, "C2", "R2025a", tmp_path)


@pytest.mark.parametrize(
    "change",
    [
        "missing_case",
        "failed_case",
        "duplicate_case",
        "failed_overall",
        "not_verified",
        "bad_registry",
        "bad_source_hash",
        "missing_source",
        "bad_schema",
        "missing_metrics",
        "failed_refined",
        "bad_solver",
        "bad_assumptions",
        "embedded_assumptions",
        "no_convergence",
    ],
)
def test_refuse_invalid_incomplete_reports(tmp_path, report, change):
    invalid = copy.deepcopy(report)
    if change == "missing_case":
        invalid["cases"].pop()
    elif change == "failed_case":
        invalid["cases"][0]["status"] = "failed"
    elif change == "duplicate_case":
        invalid["cases"].append(copy.deepcopy(invalid["cases"][0]))
    elif change == "failed_overall":
        invalid["status"] = "failed"
    elif change == "not_verified":
        invalid["matlab_verified"] = False
    elif change == "bad_registry":
        invalid["registry_sha256"] = "0" * 64
    elif change == "bad_source_hash":
        invalid["source_sha256"]["verify_boptest_zone_c2_m"] = "0" * 64
    elif change == "missing_source":
        invalid["source_sha256"].pop("verify_boptest_zone_c2_m")
    elif change == "bad_schema":
        invalid["schema_version"] = 99
    elif change == "missing_metrics":
        invalid["cases"][0].pop("coarse")
    elif change == "failed_refined":
        invalid["cases"][0]["refined"]["passed"] = False
    elif change == "bad_solver":
        invalid["cases"][0]["coarse"]["solver"]["RelTol"] = -1
    elif change == "bad_assumptions":
        invalid["assumptions_sha256"] = "0" * 64
    elif change == "embedded_assumptions":
        invalid["assumptions"]["model_kind"] = "changed"
    elif change == "no_convergence":
        invalid["cases"][0]["convergence_improved"] = False
    path = tmp_path / "report.json"
    path.write_text(json.dumps(invalid))
    with pytest.raises(ValueError):
        archive_report(path, "C2", "R2025a", tmp_path / "archive")


@pytest.mark.parametrize("change", ["report", "source_metadata", "count", "schema", "release"])
def test_detect_modified_archive(tmp_path, change):
    target = archive_report(EVIDENCE / "verification.json", "C2", "R2025a", tmp_path)
    if change == "report":
        path = target / "verification.json"
        value = read_json(path.read_bytes())
        value["scope"] = "changed"
    else:
        path = target / "metadata.json"
        value = read_json(path.read_bytes())
        if change == "source_metadata":
            value["source_files"]["configs/references/boptest_bestest_hydronic.json"] = "0" * 64
        elif change == "count":
            value["scenarios_passed"] = 9
        elif change == "schema":
            value["schema_version"] = 2
        elif change == "release":
            value["matlab_release"] = "R2024b"
    path.write_text(json.dumps(value))
    with pytest.raises(ValueError):
        validate_archive(tmp_path)


def test_source_commit_checked_not_assumed(tmp_path):
    with pytest.raises(ValueError):
        archive_report(
            EVIDENCE / "verification.json", "C2", "R2025a", tmp_path, source_commit="0" * 40
        )
    with pytest.raises(ValueError):
        archive_report(EVIDENCE / "verification.json", "C2", "R2024b", tmp_path)


def test_no_duplicate_json_keys_or_nonfinite_evidence():
    for raw in [b'{"status":"passed","status":"failed"}', b'{"metric":NaN}']:
        with pytest.raises(ValueError):
            read_json(raw)


def test_actual_source_snapshot_matches_report(report):
    files = validate_report(report, "C2")
    assert len(files) == 17
    assert all(sha256((ROOT / name).read_bytes()) == digest for name, digest in files.items())
