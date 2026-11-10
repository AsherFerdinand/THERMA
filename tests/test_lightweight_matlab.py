"""Software fixtures only: no MATLAB execution, synthetic benchmark or measurements."""

import hashlib
import json
import sys
import zipfile
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from build_matlab_package import build_package, dependency_closure, safe_name  # noqa: E402
from verify_matlab_results import verify_results  # noqa: E402


@pytest.fixture
def package(tmp_path: Path) -> Path:
    return build_package("C42B", tmp_path / "package")


def result_fixture(package: Path, destination: Path, *, success: bool = False) -> Path:
    """Create receipt-shaped software input; never presented as native evidence."""
    with zipfile.ZipFile(package) as z:
        manifest_raw = z.read("package_manifest.json")
        config_raw = z.read("experiments/C42B.json")
        audit = json.loads(z.read("docs/results/c42b/source_audit.json"))
    package_manifest = json.loads(manifest_raw)
    commit = package_manifest["source_commit"]
    status = "completed_inspection" if success else "failed"
    verification = {
        "experiment_id": "C42B",
        "kind": "inspection",
        "source_commit": commit,
        "status": status,
        "matlab_version": "SOFTWARE TEST FIXTURE - NOT EXECUTED",
        "matlab_release": "2025a",
        "matlab_executed": success,
        "simulation_performed": False,
        "empirical_validation_performed": False,
        "inputs_verified": success,
        "external_inputs": [
            dict(i, verified=True)
            for i in audit["files"]
            if i["path"] in audit["selected_core_files"]
        ],
    }
    payload = {
        "package_manifest.json": manifest_raw,
        "experiment.json": config_raw,
        "SOURCE_COMMIT.txt": commit.encode(),
        "verification.json": json.dumps(verification).encode(),
        "matlab_execution.log": b"SOFTWARE TEST FIXTURE ONLY - NO MATLAB EXECUTION\n",
    }
    if success:
        payload["inspection_summary.json"] = json.dumps(
            {
                "source_commit": audit["source_commit"],
                "selected_rows_per_source": 721,
                "simulation_performed": False,
            }
        ).encode()
        payload["measured_temperatures.png"] = b"SOFTWARE TEST PLACEHOLDER - NOT A FIGURE"
        payload["measured_cooling.png"] = b"SOFTWARE TEST PLACEHOLDER - NOT A FIGURE"
    result = {
        "schema_version": 1,
        "experiment_id": "C42B",
        "source_commit": commit,
        "status": status,
        "simulation_performed": False,
        "empirical_validation_performed": False,
        "raw_measurements_included": False,
        "files": [
            {"path": n, "bytes": len(v), "sha256": hashlib.sha256(v).hexdigest()}
            for n, v in payload.items()
        ],
    }
    payload["result_manifest.json"] = json.dumps(result).encode()
    with zipfile.ZipFile(destination, "w") as z:
        for name, value in payload.items():
            z.writestr(name, value)
    return destination


def test_fresh_extraction_hash_closure_and_no_raw_data(package: Path, tmp_path: Path) -> None:
    with zipfile.ZipFile(package) as z:
        manifest = json.loads(z.read("package_manifest.json"))
        metadata = json.loads(z.read("docs/results/c42b/source_audit.json"))
        assert metadata["kind"] == "external_file_identity_only"
        assert len(metadata["files"]) == 6
        assert "csv_audit" not in metadata  # no prior measured extrema/trajectories
        z.extractall(tmp_path / "empty")
        assert len(z.namelist()) == len(manifest["files"]) + 1
        for item in manifest["files"]:
            raw = (tmp_path / "empty" / item["path"]).read_bytes()
            assert hashlib.sha256(raw).hexdigest() == item["sha256"]
            assert len(raw) == item["bytes"]
        assert not any(n.endswith((".csv", ".slx", ".mat", ".zip", ".png")) for n in z.namelist())
        assert "scripts/matlab/boptest/boptest_sha256_update.m" in z.namelist()
    assert package.stat().st_size < 10 * 1024**2
    with pytest.raises(FileExistsError):
        build_package("C42B", package.parent)


def test_unresolved_dependency_and_unsafe_paths() -> None:
    with pytest.raises(ValueError, match="Undeclared"):
        dependency_closure(
            {"entry_points": ["missing.m"], "matlab_dependencies": {}, "small_inputs": []}
        )
    for name in ["../result.json", "/tmp/result.json", "C:\\result.json", "a//b"]:
        with pytest.raises(ValueError):
            safe_name(name)


def test_failed_receipt_is_not_success(package: Path, tmp_path: Path) -> None:
    report = verify_results(result_fixture(package, tmp_path / "failed.zip"))
    assert report["integrity_and_source_checked"]
    assert not report["eligible_for_success_archive"]
    assert not report["native_execution_independently_verified"]


def test_complete_receipt_schema_preserves_provenance(package: Path, tmp_path: Path) -> None:
    report = verify_results(result_fixture(package, tmp_path / "fixture.zip", success=True))
    assert report["eligible_for_success_archive"]  # schema/software check only
    assert not report["native_execution_independently_verified"]
    assert not report["automatic_publication_performed"]
    assert not report["privacy_review_required"]  # official HTTPS URLs are not Windows paths


def test_changed_result_bytes_are_rejected(package: Path, tmp_path: Path) -> None:
    original = result_fixture(package, tmp_path / "original.zip")
    changed = tmp_path / "changed.zip"
    with zipfile.ZipFile(original) as source, zipfile.ZipFile(changed, "w") as target:
        for name in source.namelist():
            target.writestr(
                name, b"changed" if name == "matlab_execution.log" else source.read(name)
            )
    with pytest.raises(ValueError, match="Changed result bytes"):
        verify_results(changed)


def test_unlisted_and_traversal_outputs_rejected(package: Path, tmp_path: Path) -> None:
    original = result_fixture(package, tmp_path / "unsafe.zip")
    with zipfile.ZipFile(original, "a") as z:
        z.writestr("../unexpected.csv", b"software test only")
    with pytest.raises(ValueError, match="Unsafe"):
        verify_results(original)


def test_source_inventory_checked_against_git_not_just_returned_hashes(
    package: Path, tmp_path: Path
) -> None:
    original = result_fixture(package, tmp_path / "source_fixture.zip")
    with zipfile.ZipFile(original) as z:
        payload = {name: z.read(name) for name in z.namelist()}
    manifest = json.loads(payload["package_manifest.json"])
    item = next(i for i in manifest["files"] if i["origin"] == "git_source")
    item["sha256"] = "0" * 64
    payload["package_manifest.json"] = json.dumps(manifest).encode()
    result = json.loads(payload["result_manifest.json"])
    item = next(i for i in result["files"] if i["path"] == "package_manifest.json")
    item["sha256"] = hashlib.sha256(payload["package_manifest.json"]).hexdigest()
    item["bytes"] = len(payload["package_manifest.json"])
    payload["result_manifest.json"] = json.dumps(result).encode()
    changed = tmp_path / "wrong_source.zip"
    with zipfile.ZipFile(changed, "w") as z:
        for name, value in payload.items():
            z.writestr(name, value)
    with pytest.raises(ValueError, match="Source hash mismatch"):
        verify_results(changed)
