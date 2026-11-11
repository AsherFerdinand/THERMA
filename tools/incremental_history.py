"""Bounded incremental plan and streamed reassembly verification; no source deletion."""

import hashlib
import json
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PAYLOAD = 40_000_000
CAP = 45_000_000


def make_incremental_plan(legacy: dict, models: dict, limit: int = PAYLOAD) -> dict:
    assert 0 < limit <= PAYLOAD
    verified = {r["path"]: r for r in models["verified_models"]}
    segments = []
    for row in legacy["records"]:
        if row["action"] != "archive":
            continue
        if row["path"] in verified:
            assert row["sha256"] == verified[row["path"]]["sha256"]
            continue
        size = row["bytes"]
        for offset in range(0, max(size, 1), limit):
            count = min(limit, size - offset)
            member = (
                row["path"]
                if size <= limit
                else f"__THERMA_SEGMENTS__/{row['path']}.range_{offset:012d}_{count:012d}"
            )
            segments.append(
                {
                    "path": row["path"],
                    "original_bytes": size,
                    "original_sha256": row["sha256"],
                    "offset": offset,
                    "bytes": count,
                    "member": member,
                    "part": "",
                }
            )
    parts = []
    for segment in segments:
        if not parts or parts[-1]["source_bytes"] + segment["bytes"] > limit:
            parts.append(
                {"name": f"THERMA_INCREMENTAL_{len(parts) + 1:03d}.zip", "source_bytes": 0}
            )
        part = parts[-1]
        segment["part"] = part["name"]
        part["source_bytes"] += segment["bytes"]
    return {
        "schema_version": 2,
        "audit_sha256": legacy["audit_sha256"],
        "max_zip_bytes": CAP,
        "max_payload_bytes": limit,
        "remote_model_count": len(verified),
        "remaining_original_files": len({s["path"] for s in segments}),
        "parts": parts,
        "segments": segments,
    }


def verify_reassembly(folder: Path, plan: dict) -> dict:
    """Read each range in original order; CRC+SHA checked without an uncompressed copy."""
    originals = list(dict.fromkeys(s["path"] for s in plan["segments"]))
    for path in originals:
        digest = hashlib.sha256()
        position = 0
        for segment in [s for s in plan["segments"] if s["path"] == path]:
            assert segment["offset"] == position
            archive = folder / segment["part"]
            assert archive.stat().st_size <= plan["max_zip_bytes"]
            with zipfile.ZipFile(archive) as z, z.open(segment["member"]) as stream:
                assert z.getinfo(segment["member"]).file_size == segment["bytes"]
                count = 0
                while data := stream.read(1024 * 1024):
                    count += len(data)
                    digest.update(data)
                assert count == segment["bytes"]
            position += count
        assert position == segment["original_bytes"]
        assert digest.hexdigest() == segment["original_sha256"], path
    return {"originals_reassembled_and_sha256_verified": len(originals), "cleanup_approved": False}


if __name__ == "__main__":
    ref = ROOT / "history_reference"
    plan = make_incremental_plan(
        json.loads((ref / "history_plan.json").read_text()),
        json.loads((ref / "remote_models_verified.json").read_text()),
    )
    (ref / "incremental_plan.json").write_text(json.dumps(plan, indent=2) + "\n")
    print(len(plan["parts"]), "parts;", plan["remaining_original_files"], "originals remaining")

# For returned,downloaded Release assets use verify_reassembly(folder,plan).
# A successful reassembly is not proof of fresh network availability or cleanup approval.
