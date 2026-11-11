"""Build a small read-only toolkit and an exact independent historical recovery ZIP."""

import argparse
import hashlib
import json
import secrets
import subprocess
import zipfile
from pathlib import Path

from build_matlab_package import safe_name

ROOT = Path(__file__).resolve().parents[1]
FILES = [
    "run_cleanup_readiness.m",
    "verify_git_recovery.m",
    "verify_cleanup_package.m",
    "tools/matlab/recover_therma_evidence.m",
    "CLEANUP_READINESS_START_HERE.md",
    "docs/CLEANUP_READINESS.md",
    "history_reference/storage_audit.json",
    "history_reference/cleanup_review.csv",
    "tools/matlab/therma_cleanup_compare.m",
    "tools/matlab/test_cleanup_readiness.m",
    "tools/matlab/therma_safe_path.m",
    "scripts/matlab/boptest/boptest_file_sha256.m",
    "scripts/matlab/boptest/boptest_sha256_update.m",
    "scripts/matlab/boptest/write_boptest_json.m",
]


def verified_originals(recovered: Path, audit: dict) -> dict[str, bytes]:
    selected = [r for r in audit["files"] if r["github_bytes_preserved"]]
    if len(selected) != 291:
        raise ValueError("Expected 291 Git-dependent originals")
    names = [safe_name(r["path"]) for r in selected]
    if len({n.casefold() for n in names}) != len(names):
        raise ValueError("Duplicate historical path")
    payload = {}
    for item in selected:
        name = safe_name(item["path"])
        raw = (recovered / name).read_bytes()
        if len(raw) != item["bytes"] or hashlib.sha256(raw).hexdigest() != item["sha256"]:
            raise ValueError(f"Original hash/size mismatch: {name}")
        payload["originals/" + name] = raw
    return payload


def write_zip(target: Path, payload: dict[str, bytes]) -> dict:
    with zipfile.ZipFile(target, "x", zipfile.ZIP_DEFLATED) as z:
        for name, raw in sorted(payload.items()):
            safe_name(name)
            info = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            z.writestr(info, raw)
    with zipfile.ZipFile(target) as z:
        assert z.testzip() is None
        assert set(z.namelist()) == set(payload)
        for name, raw in payload.items():
            assert z.read(name) == raw
    digest = hashlib.sha256(target.read_bytes()).hexdigest()
    target.with_suffix(".zip.sha256").write_text(f"{digest}  {target.name}\n")
    return {"name": target.name, "bytes": target.stat().st_size, "sha256": digest}


def build(recovered: Path, output: Path) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    payload = {
        n: subprocess.check_output(["git", "show", f"{commit}:{n}"], cwd=ROOT) for n in FILES
    }
    raw_audit = payload["history_reference/storage_audit.json"]
    assert hashlib.sha256(raw_audit).hexdigest() == (
        "5854d0a727fed8604eaadf7aacbcb1e3bcb00a585050ca53157e4d3e9927d8c4"
    )
    audit = json.loads(raw_audit)
    originals = verified_originals(recovered, audit)
    manifest = {
        "schema_version": 1,
        "audit_sha256": hashlib.sha256(raw_audit).hexdigest(),
        "files": [r for r in audit["files"] if r["github_bytes_preserved"]],
        "original_bytes": sum(len(b) for b in originals.values()),
        "source_commit": commit,
        "note": "Exact originals; bulk Release parts remain needed for the other 279 files.",
    }
    originals["GIT_RECOVERY_MANIFEST.json"] = (json.dumps(manifest, indent=2) + "\n").encode()
    recovery = write_zip(output / "THERMA_HISTORY_GIT_RECOVERY_291_2026-11-11.zip", originals)
    from cryptography.hazmat.primitives.ciphers.aead import AESGCM

    key = secrets.token_bytes(32)
    nonce = secrets.token_bytes(12)
    header = b"THERMA-AES256-GCM-v1\n"
    plain = (output / recovery["name"]).read_bytes()
    cipher = header + nonce + AESGCM(key).encrypt(nonce, plain, header)
    assert AESGCM(key).decrypt(nonce, cipher[len(header) + 12 :], header) == plain
    encrypted_name = recovery["name"] + ".aesgcm"
    (output / encrypted_name).write_bytes(cipher)
    key_file = output / "PRIVATE_RECOVERY_KEY.txt"
    with key_file.open("x") as stream:
        stream.write(key.hex() + "\n")
    key_file.chmod(0o600)
    recovery["encrypted_name"] = encrypted_name
    recovery["encrypted_sha256"] = hashlib.sha256(cipher).hexdigest()
    payload[encrypted_name] = cipher
    payload["GIT_RECOVERY_DELIVERY.json"] = (json.dumps(recovery, indent=2) + "\n").encode()
    toolkit_manifest = {
        "source_commit": commit,
        "native_execution_verified": False,
        "files": [
            {"path": n, "bytes": len(b), "sha256": hashlib.sha256(b).hexdigest()}
            for n, b in sorted(payload.items())
        ],
    }
    payload["CLEANUP_PACKAGE_MANIFEST.json"] = (
        json.dumps(toolkit_manifest, indent=2) + "\n"
    ).encode()
    toolkit = write_zip(output / "THERMA_CLEANUP_READINESS_2026-11-11.zip", payload)
    result = {"source_commit": commit, "toolkit": toolkit, "git_recovery": recovery}
    (output / "DELIVERY.json").write_text(json.dumps(result, indent=2) + "\n")
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--recovered", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    print(json.dumps(build(args.recovered, args.output), indent=2))
