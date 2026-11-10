"""Snapshot recoverable Git bytes and storage; never delete or fetch raw artifacts."""

import argparse
import hashlib
import io
import json
import os
import subprocess
import zipfile
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def git(*args: str) -> bytes:
    env = dict(os.environ, GIT_NO_LAZY_FETCH="1")
    return subprocess.check_output(["git", *args], cwd=ROOT, env=env)


def snapshot(source: str, transfer: str) -> None:
    records: dict[str, dict] = {}
    artifacts = []
    for commit, kind in [(source, "source"), (transfer, "transfer")]:
        tree = git("ls-tree", "-r", commit).decode().splitlines()
        for line in tree:
            meta, name = line.split("\t", 1)
            blob = meta.split()[-1]
            raw = git("cat-file", "blob", blob)
            sha = hashlib.sha256(raw).hexdigest()
            entry = records.setdefault(sha, {"sha256": sha, "bytes": len(raw), "locations": []})
            entry["locations"].append({"commit": commit, "path": name, "member": "", "kind": kind})
            if kind == "transfer" and name.endswith(".zip"):
                archive = {"path": name, "bytes": len(raw), "sha256": sha, "slx": [], "members": 0}
                with zipfile.ZipFile(io.BytesIO(raw)) as z:
                    for member in z.infolist():
                        if member.is_dir():
                            continue
                        with z.open(member) as stream:
                            digest = hashlib.file_digest(stream, "sha256").hexdigest()
                        item = records.setdefault(
                            digest,
                            {"sha256": digest, "bytes": member.file_size, "locations": []},
                        )
                        item["locations"].append(
                            {
                                "commit": commit,
                                "path": name,
                                "member": member.filename,
                                "kind": "transfer_member",
                            }
                        )
                        archive["members"] += 1
                        if member.filename.lower().endswith(".slx"):
                            archive["slx"].append(member.filename)
                artifacts.append(archive)
    manifest = {
        "schema_version": 1,
        "snapshot_date": "2026-11-10",
        "source_commit": source,
        "transfer_commit": transfer,
        "scope": "exact Git bytes and ZIP members; not proof of native model execution",
        "records": sorted(records.values(), key=lambda r: r["sha256"]),
    }
    (ROOT / "tools/preservation_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    totals: dict[str, int] = defaultdict(int)
    largest = []
    slx = []
    local_zips: dict[str, list[str]] = defaultdict(list)
    tracked = set(git("ls-files", "-z").decode().split("\0"))
    for folder, _, names in os.walk(ROOT):
        for name in names:
            path = Path(folder) / name
            if path.is_symlink():
                continue
            relative = path.relative_to(ROOT).as_posix()
            size = path.stat().st_size
            totals[relative.split("/")[0]] += size
            largest.append({"path": relative, "bytes": size, "tracked": relative in tracked})
            if path.suffix.lower() == ".slx":
                slx.append(relative)
            if path.suffix.lower() == ".zip":
                with path.open("rb") as stream:
                    sha = hashlib.file_digest(stream, "sha256").hexdigest()
                local_zips[sha].append(relative)
    object_paths = {}
    for line in git("rev-list", "--objects", "--all", source, transfer).decode().splitlines():
        pieces = line.split(" ", 1)
        if len(pieces) == 2:
            object_paths.setdefault(pieces[0], pieces[1])
    objects = []
    for line in (
        git(
            "cat-file",
            "--batch-all-objects",
            "--batch-check=%(objectname) %(objecttype) %(objectsize)",
        )
        .decode()
        .splitlines()
    ):
        blob, kind, size = line.split()
        if kind == "blob":
            objects.append(
                {
                    "git_blob": blob,
                    "path": object_paths.get(blob, "unresolved"),
                    "uncompressed_bytes": int(size),
                }
            )
    report = {
        "snapshot_date": "2026-11-10",
        "source_commit": source,
        "transfer_commit": transfer,
        "scope": "cloud checkout; university folder not measured",
        "directory_bytes": dict(sorted(totals.items())),
        "tracked_source_bytes": sum(
            len(git("show", source + ":" + n))
            for n in git("ls-tree", "-r", "--name-only", source).decode().splitlines()
        ),
        "largest_files": sorted(largest, key=lambda r: r["bytes"], reverse=True)[:20],
        "local_slx": slx,
        "transfer_archives": artifacts,
        "duplicate_zip_groups": [v for v in local_zips.values() if len(v) > 1],
        "largest_git_blobs": sorted(objects, key=lambda r: r["uncompressed_bytes"], reverse=True)[
            :15
        ],
    }
    (ROOT / "docs/REPOSITORY_STORAGE_SNAPSHOT.json").write_text(json.dumps(report, indent=2) + "\n")
    print(
        f"Preserved {len(records)} unique byte identities; "
        f"{len(artifacts)} remote ZIPs; local SLX {len(slx)}"
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-commit", required=True)
    parser.add_argument("--transfer-commit", required=True)
    args = parser.parse_args()
    snapshot(args.source_commit, args.transfer_commit)
