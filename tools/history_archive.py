"""Plan/verify exact original university archive bytes; never delete or publish data."""

import argparse
import hashlib
import json
import math
import re
import subprocess
import zipfile
from pathlib import Path

from build_history_archiver import FILES
from build_matlab_package import safe_name

ROOT = Path(__file__).resolve().parents[1]


def group_for(path: str) -> str:
    p = path.lower()
    for token, group in [
        ("c42b", "C42B"),
        ("c40", "C40"),
        ("c39", "C39"),
        ("c38", "C38"),
        ("c37", "C37"),
        ("c28", "C28"),
    ]:
        if re.search(rf"(^|[/_]){token}([/_.]|$)", p):
            return group
    if p.startswith("outputs/c3/") or any(
        re.search(rf"(^|[/_])c{n}([/_.]|$)", p) for n in [31, 32, 33, 34, 35, 36]
    ):
        return "C31_C36"
    if p.startswith("outputs/boptest/") or "envelope" in p or "simulink_c2" in p:
        return "C1_C2"
    return "REVIEW"


def is_cache(path: str) -> bool:
    return path.lower().endswith(".slxc") or "slprj" in path.lower().split("/")


def make_plan(audit: dict, known: set[str], audit_hash: str) -> dict:
    rows = []
    seen = set()
    for record in audit["files"]:
        name = safe_name(record["path"])
        if name.casefold() in seen or name.startswith("__THERMA_ARCHIVE__/"):
            raise ValueError("Ambiguous/reserved source path")
        seen.add(name.casefold())
        sha = record["sha256"]
        if not re.fullmatch(r"[0-9a-f]{64}", sha):
            raise ValueError(f"Missing original source hash: {name}")
        size = int(record["bytes"])
        if size != record["bytes"] or size < 0:
            raise ValueError("Invalid original source size")
        if name.lower().endswith(".slx"):
            action = "archive"  # Every model, even a future known byte match.
        elif sha in known:
            action = "github_preserved"
        elif record["classification"] == "REGENERATE_CACHE_REVIEW" and is_cache(name):
            action = "regenerable_cache"
        else:
            action = "archive"  # Unknown/review material is kept, never discarded.
        rows.append(
            {
                "path": name,
                "bytes": size,
                "sha256": sha,
                "action": action,
                "group": group_for(name),
                "part": "",
            }
        )
    parts = []
    for group in sorted({r["group"] for r in rows if r["action"] == "archive"}):
        number = 0
        current = []

        def finish(group: str = group) -> None:
            nonlocal current, number
            if not current:
                return
            number += 1
            name = f"THERMA_HISTORY_{group}_{number:03d}.zip"
            for row in current:
                row["part"] = name
            parts.append(
                {
                    "name": name,
                    "group": group,
                    "files": len(current),
                    "source_bytes": sum(r["bytes"] for r in current),
                }
            )
            current = []

        for row in [r for r in rows if r["action"] == "archive" and r["group"] == group]:
            if current and sum(r["bytes"] for r in current) + row["bytes"] > 64 * 1024**2:
                finish()
            current.append(row)
        finish()
    total = sum(r["bytes"] for r in rows if r["action"] == "archive")
    return {
        "schema_version": 1,
        "audit_sha256": audit_hash,
        "selection_policy": (
            "all SLX;all unknown originals;skip only exact known Git bytes and declared caches"
        ),
        "expected_source_files": len(rows),
        "archive_files": sum(r["action"] == "archive" for r in rows),
        "all_audited_slx": sum(r["path"].lower().endswith(".slx") for r in rows),
        "source_bytes_to_archive": total,
        "space_estimate_bytes": math.ceil(total * 1.05) + 4 * 1024**2,
        "parts": parts,
        "records": rows,
    }


def verify_return(folder: Path, reference: Path) -> dict:
    audit_raw = (reference / "storage_audit.json").read_bytes()
    known = {
        r["sha256"]
        for r in json.loads((reference / "preservation_manifest.json").read_text())["records"]
    }
    plan = make_plan(json.loads(audit_raw), known, hashlib.sha256(audit_raw).hexdigest())
    catalog_zip = folder / "THERMA_HISTORY_CATALOG.zip"
    with zipfile.ZipFile(catalog_zip) as z:
        expected_names = {
            "archive_catalog.json",
            "history_plan.json",
            "storage_audit.json",
            "preservation_manifest.json",
            "RECOVERY.txt",
            "HISTORY_PACKAGE_MANIFEST.json",
        }
        if len(z.namelist()) != len(expected_names) or set(z.namelist()) != expected_names:
            raise ValueError("Unexpected catalog ZIP entries")
        if sum(i.file_size for i in z.infolist()) > 5 * 1024**2:
            raise ValueError("Oversized catalog")
        if z.read("storage_audit.json") != audit_raw:
            raise ValueError("Original audit identity differs")
        if (
            z.read("preservation_manifest.json")
            != (reference / "preservation_manifest.json").read_bytes()
        ):
            raise ValueError("Preservation snapshot differs")
        if json.loads(z.read("history_plan.json")) != plan:
            raise ValueError("Archive selection plan differs")
        catalog = json.loads(z.read("archive_catalog.json"))
        toolkit = json.loads(z.read("HISTORY_PACKAGE_MANIFEST.json"))
        commit = toolkit["source_commit"]
        if not re.fullmatch(r"[0-9a-f]{40}", commit) or commit != catalog["toolkit_source_commit"]:
            raise ValueError("Toolkit source identity differs")
        if len(toolkit["files"]) != len(FILES) or {i["path"] for i in toolkit["files"]} != set(
            FILES
        ):
            raise ValueError("Toolkit dependency inventory differs")
        for item in toolkit["files"]:
            source = subprocess.check_output(
                ["git", "show", f"{commit}:{safe_name(item['path'])}"], cwd=ROOT
            )
            if len(source) != item["bytes"] or hashlib.sha256(source).hexdigest() != item["sha256"]:
                raise ValueError("Toolkit source hashes differ")
    if (
        catalog["status"] != "locally_verified_only"
        or catalog["audit_sha256"] != plan["audit_sha256"]
        or catalog["matlab_release"] != "2025a"
    ):
        raise ValueError("Incomplete/failed local catalog")
    parts = catalog["archives"]
    if len(parts) != len(plan["parts"]) or {p["name"] for p in parts} != {
        p["name"] for p in plan["parts"]
    }:
        raise ValueError("Missing/duplicate archive parts")
    preserved = []
    for part in parts:
        name = safe_name(part["name"])
        archive = folder / name
        with archive.open("rb") as stream:
            sha = hashlib.file_digest(stream, "sha256").hexdigest()
        if sha != part["sha256"] or archive.stat().st_size != part["bytes"]:
            raise ValueError(f"Archive hash differs: {name}")
        wanted = {r["path"]: r for r in plan["records"] if r["part"] == name}
        with zipfile.ZipFile(archive) as z:
            names = z.namelist()
            if len(names) != len(wanted) + 2 or set(names) != wanted.keys() | {
                "__THERMA_ARCHIVE__/manifest.json",
                "__THERMA_ARCHIVE__/RECOVERY.txt",
            }:
                raise ValueError(f"Unexpected/missing ZIP paths: {name}")
            metadata_info = z.getinfo("__THERMA_ARCHIVE__/manifest.json")
            if metadata_info.file_size > 2 * 1024**2:
                raise ValueError("Oversized part manifest")
            manifest = json.loads(z.read(metadata_info))
            if (
                manifest["audit_sha256"] != plan["audit_sha256"]
                or manifest["part"] != name
                or manifest["files"] != list(wanted.values())
            ):
                raise ValueError("Part manifest differs")
            for path, record in wanted.items():
                info = z.getinfo(path)
                if (
                    info.file_size != record["bytes"]
                    or ((info.external_attr >> 16) & 0o170000) == 0o120000
                ):
                    raise ValueError(f"Invalid source size/link: {path}")
                with z.open(info) as stream:
                    actual = hashlib.file_digest(
                        stream, "sha256"
                    ).hexdigest()  # CRC checked while reading
                if actual != record["sha256"]:
                    raise ValueError(f"Original content differs: {path}")
                preserved.append(record)
    assert len(preserved) == plan["archive_files"]
    return {
        "audit_sha256": plan["audit_sha256"],
        "archive_files_verified": len(preserved),
        "native_slx_byte_identities_verified": sum(
            r["path"].lower().endswith(".slx") for r in preserved
        ),
        "original_bytes_verified": sum(r["bytes"] for r in preserved),
        "status": "returned_archive_integrity_verified_not_remotely_archived",
        "remote_recovery_confirmed": False,
        "cleanup_approved": False,
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--reference", type=Path, default=ROOT / "history_reference")
    parser.add_argument("--returned", type=Path)
    args = parser.parse_args()
    if args.returned:
        print(json.dumps(verify_return(args.returned, args.reference), indent=2))
    else:
        raw = (args.reference / "storage_audit.json").read_bytes()
        known = {
            r["sha256"]
            for r in json.loads((args.reference / "preservation_manifest.json").read_text())[
                "records"
            ]
        }
        plan = make_plan(json.loads(raw), known, hashlib.sha256(raw).hexdigest())
        (args.reference / "history_plan.json").write_text(json.dumps(plan, indent=2) + "\n")
        print(json.dumps({k: v for k, v in plan.items() if k != "records"}, indent=2))
