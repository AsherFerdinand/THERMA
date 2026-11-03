"""Independent byte vectors; MATLAB Java dispatch still requires MATLAB execution."""

import hashlib
import json
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_hash_vectors_against_independent_implementations():
    vectors = json.loads((ROOT / "tests/fixtures/sha256_vectors.json").read_text())
    for vector in vectors:
        count = vector["length"]
        data = (
            b"abc"
            if vector["pattern"] == "abc"
            else b"\xff"
            if vector["pattern"] == "ff"
            else (bytes(range(256)) * ((count + 255) // 256))[:count]
        )
        assert len(data) == count
        assert hashlib.sha256(data).hexdigest() == vector["sha256"]
        if shutil.which("openssl"):
            result = subprocess.run(
                ["openssl", "dgst", "-sha256"], input=data, capture_output=True, check=True
            )
            assert result.stdout.decode().split()[-1] == vector["sha256"]


def test_event_pipeline_uses_explicit_shared_byte_array_update():
    directory = ROOT / "scripts/matlab/boptest"
    helper = (directory / "boptest_sha256_update.m").read_text()
    assert "if isempty(bytes), return; end" in helper
    assert "if count==1, signed(2)=int8(0); end" in helper
    assert "typecast(bytes(:),'int8')" in helper
    assert "digest.update(signed,int32(0),int32(count))" in helper
    for name in ["boptest_file_sha256.m", "boptest_verify_energy_csv.m"]:
        source = (directory / name).read_text()
        assert "boptest_sha256_update(digest,bytes)" in source
        assert "digest.update(" not in source
