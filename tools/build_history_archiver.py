"""Build only committed MATLAB archival utilities/reference identities, no history data."""

import argparse
import hashlib
import json
import subprocess
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FILES = ["archive_therma_history.m", "test_therma_history_archiver.m", "HISTORY_ARCHIVER_README.md"]
INCREMENTAL_FILES = [
    "archive_therma_history_incremental.m",
    "verify_therma_history_remote.m",
    "restore_therma_history_incremental.m",
    "INCREMENTAL_HISTORY_README.md",
]
INCREMENTAL_FILES += [
    "history_reference/incremental_plan.json",
    "history_reference/remote_models_verified.json",
]
INCREMENTAL_FILES += [
    "tools/matlab/therma_incremental_part.m",
    "tools/matlab/therma_incremental_save.m",
]
FILES += INCREMENTAL_FILES
FILES += [
    "history_reference/" + n
    for n in ["storage_audit.json", "history_plan.json", "preservation_manifest.json"]
]
FILES += [
    "tools/matlab/" + n
    for n in [
        "therma_safe_path.m",
        "recover_therma_evidence.m",
        "therma_history_bytes.m",
        "therma_history_load.m",
        "therma_history_preflight.m",
        "therma_history_space.m",
        "therma_history_write_part.m",
        "therma_history_verify_part.m",
        "therma_history_zip_hash.m",
        "therma_history_verify_catalog.m",
        "therma_history_packet.m",
    ]
]
FILES += [
    "scripts/matlab/boptest/" + n
    for n in [
        "boptest_file_sha256.m",
        "boptest_sha256_update.m",
        "write_boptest_json.m",
        "boptest_exception_diagnostic.m",
    ]
]


def build(output: Path) -> Path:
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    payload = {
        n: subprocess.check_output(["git", "show", f"{commit}:{n}"], cwd=ROOT) for n in FILES
    }
    manifest = {
        "schema_version": 1,
        "source_commit": commit,
        "native_execution_verified": False,
        "files": [
            {"path": n, "bytes": len(b), "sha256": hashlib.sha256(b).hexdigest()}
            for n, b in sorted(payload.items())
        ],
    }
    payload["HISTORY_PACKAGE_MANIFEST.json"] = (json.dumps(manifest, indent=2) + "\n").encode()
    output.mkdir(parents=True, exist_ok=True)
    target = output / "THERMA_HISTORY_ARCHIVER.zip"
    with zipfile.ZipFile(target, "x", zipfile.ZIP_DEFLATED) as z:
        for n, b in sorted(payload.items()):
            info = zipfile.ZipInfo(n, date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            z.writestr(info, b)
    assert target.stat().st_size < 1024**2
    with zipfile.ZipFile(target) as z:
        assert z.testzip() is None
        for n, b in payload.items():
            assert z.read(n) == b
    digest = hashlib.sha256(target.read_bytes()).hexdigest()
    target.with_suffix(".zip.sha256").write_text(f"{digest}  {target.name}\n")
    print(
        f"{target}: {target.stat().st_size} bytes;{len(payload)} files;"
        f"source {commit};SHA256 {digest}"
    )
    return target


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT / "outputs/history_archiver")
    args = parser.parse_args()
    build(args.output)
