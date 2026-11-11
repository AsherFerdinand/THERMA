"""Lossless archival software fixtures only; no native simulation/model evidence."""

import csv
import hashlib
import json
import subprocess
import sys
import zipfile
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from build_history_archiver import FILES, build  # noqa: E402
from history_archive import group_for, make_plan, verify_return  # noqa: E402


def test_actual_audit_csv_selection_and_all_models() -> None:
    reference = ROOT / "history_reference"
    raw = (reference / "storage_audit.json").read_bytes()
    audit = json.loads(raw)
    rows = list(csv.DictReader((reference / "cleanup_review.csv").open()))
    known = {
        r["sha256"]
        for r in json.loads((reference / "preservation_manifest.json").read_text())["records"]
    }
    assert len(rows) == len(audit["files"]) == 602
    by_name = {r["path"]: r for r in audit["files"]}
    for row in rows:
        item = by_name[row["path"]]
        assert int(float(row["bytes"])) == item["bytes"]
        assert row["sha256"] == item["sha256"]
    plan = make_plan(audit, known, hashlib.sha256(raw).hexdigest())
    assert plan == json.loads((reference / "history_plan.json").read_text())
    assert plan["archive_files"] == 279
    assert plan["source_bytes_to_archive"] == 420811850
    assert plan["all_audited_slx"] == 36
    assert len(plan["parts"]) == 12
    assert all(r["action"] == "archive" for r in plan["records"] if r["path"].endswith(".slx"))
    assert group_for("outputs/c3/c35/tpc40ff/THERMA_C34_ClosedLoop.slx") == "C31_C36"


def test_actual_public_c42b_evidence_is_byte_preserved() -> None:
    folder = ROOT / "results/C42B/c146fd42ee036a3a"
    provenance = json.loads((folder / "provenance.json").read_text())
    for item in provenance["files"]:
        raw = (folder / item["path"]).read_bytes()
        assert hashlib.sha256(raw).hexdigest() == item["sha256"]
    assert provenance["status"] == "completed_inspection"
    assert provenance["rows_per_input"] == 721
    assert not provenance["simulation_performed"]
    assert not provenance["empirical_validation_performed"]
    assert provenance["uploaded_ciphertext_sha256_verified"]


def software_fixture(
    tmp_path: Path, *, corrupt: bool = False, extra: bool = False
) -> tuple[Path, Path]:
    reference = tmp_path / "reference"
    returned = tmp_path / "returned"
    reference.mkdir()
    returned.mkdir()
    payload = {
        "models/software_fixture.slx": b"SOFTWARE TEST ONLY - NOT A MODEL",
        "other/software_fixture.slx": b"SOFTWARE TEST ONLY - NOT A MODEL",
        "empty.bin": b"",
        "chunk.bin": bytes(range(256)) * 8192 + b"x",
    }
    audit = {
        "files": [
            {
                "path": n,
                "bytes": len(b),
                "sha256": hashlib.sha256(b).hexdigest(),
                "classification": "KEEP_NOT_YET_BACKED_UP",
            }
            for n, b in payload.items()
        ]
    }
    audit_raw = json.dumps(audit).encode()
    known_raw = json.dumps({"records": []}).encode()
    (reference / "storage_audit.json").write_bytes(audit_raw)
    (reference / "preservation_manifest.json").write_bytes(known_raw)
    plan = make_plan(audit, set(), hashlib.sha256(audit_raw).hexdigest())
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    toolkit = {"source_commit": commit, "files": []}
    for name in FILES:
        raw = subprocess.check_output(["git", "show", f"{commit}:{name}"], cwd=ROOT)
        toolkit["files"].append(
            {"path": name, "bytes": len(raw), "sha256": hashlib.sha256(raw).hexdigest()}
        )
    parts = []
    for part in plan["parts"]:
        records = [r for r in plan["records"] if r["part"] == part["name"]]
        target = returned / part["name"]
        with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as z:
            for record in records:
                value = payload[record["path"]]
                if corrupt and record["path"] == "chunk.bin":
                    value = value[:-1] + b"y"
                z.writestr(record["path"], value)
            z.writestr(
                "__THERMA_ARCHIVE__/manifest.json",
                json.dumps(
                    {"audit_sha256": plan["audit_sha256"], "part": part["name"], "files": records}
                ),
            )
            z.writestr("__THERMA_ARCHIVE__/RECOVERY.txt", "SOFTWARE FIXTURE")
            if extra:
                z.writestr("../unexpected", b"fixture")
        parts.append(
            {
                "name": part["name"],
                "bytes": target.stat().st_size,
                "sha256": hashlib.sha256(target.read_bytes()).hexdigest(),
            }
        )
    catalog = {
        "status": "locally_verified_only",
        "audit_sha256": plan["audit_sha256"],
        "toolkit_source_commit": commit,
        "matlab_release": "2025a",
        "archives": parts,
    }
    with zipfile.ZipFile(returned / "THERMA_HISTORY_CATALOG.zip", "w") as z:
        z.writestr("storage_audit.json", audit_raw)
        z.writestr("preservation_manifest.json", known_raw)
        z.writestr("history_plan.json", json.dumps(plan))
        z.writestr("archive_catalog.json", json.dumps(catalog))
        z.writestr("HISTORY_PACKAGE_MANIFEST.json", json.dumps(toolkit))
        z.writestr("RECOVERY.txt", "SOFTWARE FIXTURE")
    return returned, reference


def test_round_trip_duplicate_paths_empty_and_chunked_bytes(tmp_path: Path) -> None:
    returned, reference = software_fixture(tmp_path)
    report = verify_return(returned, reference)
    assert report["archive_files_verified"] == 4
    assert (
        report["native_slx_byte_identities_verified"] == 2
    )  # opaque fixture extensions,not native models
    assert not report["remote_recovery_confirmed"]
    assert not report["cleanup_approved"]


def test_changed_original_rejected_even_when_outer_zip_receipt_matches(tmp_path: Path) -> None:
    returned, reference = software_fixture(tmp_path, corrupt=True)
    with pytest.raises(ValueError, match="Original content differs"):
        verify_return(returned, reference)


def test_unexpected_traversal_entry_rejected(tmp_path: Path) -> None:
    returned, reference = software_fixture(tmp_path, extra=True)
    with pytest.raises(ValueError, match="Unexpected/missing ZIP paths"):
        verify_return(returned, reference)


def test_clean_toolkit_extraction_and_byte_manifest(tmp_path: Path) -> None:
    archive = build(tmp_path / "package")
    with zipfile.ZipFile(archive) as z:
        manifest = json.loads(z.read("HISTORY_PACKAGE_MANIFEST.json"))
        z.extractall(tmp_path / "empty")
        for item in manifest["files"]:
            raw = (tmp_path / "empty" / item["path"]).read_bytes()
            assert hashlib.sha256(raw).hexdigest() == item["sha256"]
        assert not any(n.endswith((".slx", ".mat", ".fig", ".zip")) for n in z.namelist())
    assert archive.stat().st_size < 1024**2
