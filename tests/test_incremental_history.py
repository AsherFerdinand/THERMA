"""Opaque software byte fixtures;not MATLAB or simulation results."""

import hashlib
import json
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from incremental_history import make_incremental_plan, verify_reassembly  # noqa: E402


def test_large_original_is_split_without_compression_assumption() -> None:
    legacy = {
        "audit_sha256": "a" * 64,
        "records": [
            {"path": "large.csv", "bytes": 100_000_001, "sha256": "b" * 64, "action": "archive"}
        ],
    }
    p = make_incremental_plan(legacy, {"verified_models": []})
    assert [s["bytes"] for s in p["segments"]] == [40_000_000, 40_000_000, 20_000_001]
    assert [s["offset"] for s in p["segments"]] == [0, 40_000_000, 80_000_000]
    assert all(s["source_bytes"] <= 40_000_000 for s in p["parts"])


def test_lossless_reassembly_duplicate_timestamps_and_empty_file(tmp_path: Path) -> None:
    raw = b"t,q\r\n0,1\r\n0,-2\r\n1,3\r\n\xff"
    data = {"data/original.csv": raw, "data/empty.bin": b""}
    legacy = {
        "audit_sha256": "a" * 64,
        "records": [
            {
                "path": n,
                "bytes": len(b),
                "sha256": hashlib.sha256(b).hexdigest(),
                "action": "archive",
            }
            for n, b in data.items()
        ],
    }
    p = make_incremental_plan(legacy, {"verified_models": []}, limit=7)
    for part in p["parts"]:
        with zipfile.ZipFile(tmp_path / part["name"], "w", compression=zipfile.ZIP_STORED) as z:
            for s in p["segments"]:
                if s["part"] == part["name"]:
                    z.writestr(s["member"], data[s["path"]][s["offset"] : s["offset"] + s["bytes"]])
    assert verify_reassembly(tmp_path, p)["originals_reassembled_and_sha256_verified"] == 2


def test_model_receipt_and_actual_incremental_plan() -> None:
    ref = ROOT / "history_reference"
    models = json.loads((ref / "remote_models_verified.json").read_text())
    assert len(models["verified_models"]) == 36
    legacy = json.loads((ref / "history_plan.json").read_text())
    plan = make_incremental_plan(legacy, models)
    assert plan == json.loads((ref / "incremental_plan.json").read_text())
    assert plan["remaining_original_files"] == 243
    assert not any(s["path"].endswith(".slx") for s in plan["segments"])
    for path in {s["path"] for s in plan["segments"]}:
        ranges = [s for s in plan["segments"] if s["path"] == path]
        assert sum(s["bytes"] for s in ranges) == ranges[0]["original_bytes"]
