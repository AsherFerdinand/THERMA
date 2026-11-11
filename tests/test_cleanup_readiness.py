"""Software-only checks; native MATLAB scan remains a university execution gate."""

import hashlib
import json
import sys
import zipfile
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from build_cleanup_readiness import verified_originals, write_zip  # noqa: E402


def test_recovery_rejects_modified_bytes(tmp_path):
    raw = b"original"
    audit = {"files": []}
    for i in range(291):
        name = f"fixture_{i}"
        (tmp_path / name).write_bytes(raw)
        audit["files"].append(
            {
                "path": name,
                "bytes": len(raw),
                "sha256": hashlib.sha256(raw).hexdigest(),
                "github_bytes_preserved": True,
            }
        )
    assert len(verified_originals(tmp_path, audit)) == 291
    (tmp_path / "fixture_0").write_bytes(b"changed!")
    with pytest.raises(ValueError, match="hash/size"):
        verified_originals(tmp_path, audit)


def test_zip_round_trip_and_no_overwrite(tmp_path):
    target = tmp_path / "test.zip"
    payload = {"originals/a/b": b"\x00\xfforiginal"}
    receipt = write_zip(target, payload)
    with zipfile.ZipFile(target) as z:
        assert z.read("originals/a/b") == payload["originals/a/b"]
    assert receipt["sha256"] == hashlib.sha256(target.read_bytes()).hexdigest()
    with pytest.raises(FileExistsError):
        write_zip(target, payload)


def test_toolkit_read_only_guards_and_audit():
    script = (ROOT / "run_cleanup_readiness.m").read_text()
    assert "THERMA:OutputInsideOriginal" in script
    assert "THERMA:ConcurrentChange" in script
    assert "'cleanup_approved',false" in script
    assert "delete(" not in script and "rmdir(" not in script
    rows = json.loads((ROOT / "history_reference/storage_audit.json").read_text())["files"]
    assert sum(bool(r["github_bytes_preserved"]) for r in rows) == 291
