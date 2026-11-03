"""Assemble an immutable offline C2.7 package from a commit and original transfer ZIPs."""

from __future__ import annotations

import argparse
import hashlib
import io
import json
import subprocess
import tarfile
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo


def digest(raw: bytes) -> str:
    return hashlib.sha256(raw).hexdigest()


def package(source: str, no_solar: Path, solar: Path, output: Path) -> dict[str, object]:
    archive = subprocess.check_output(["git", "archive", "--format=tar", source])
    payload = {}
    with tarfile.open(fileobj=io.BytesIO(archive)) as tar:
        for member in tar:
            if member.isfile():
                stream = tar.extractfile(member)
                assert stream is not None
                payload[member.name] = stream.read()
    original = {name: digest(raw) for name, raw in payload.items()}
    plan = json.loads(payload["configs/references/c27_study.json"])
    with ZipFile(no_solar) as z:
        assert z.testzip() is None
        for name in ["inputs.csv", "replay.json"]:
            key = "outputs/boptest/replay_inputs/first_typical/" + name
            payload[key] = z.read(key)
    with ZipFile(solar) as z:
        assert z.testzip() is None
        for name in ["inputs.csv", "replay.json", "solar_seven.csv", "solar_sources.csv"]:
            payload["outputs/boptest/THERMA_C26_solar_replay/packet/" + name] = z.read(
                "THERMA_C26_solar_replay/packet/" + name
            )
    for prefix in ["no_solar", "solar"]:
        name = plan[prefix + "_packet"]
        assert digest(payload[name]) == plan[prefix + "_packet_sha256"]
        metadata = json.loads(payload[name])
        folder = str(Path(name).parent).replace("\\", "/")
        assert digest(payload[folder + "/inputs.csv"]) == metadata["inputs_sha256"]
        if prefix == "solar":
            for filename, field in [
                ("solar_seven.csv", "solar_seven_sha256"),
                ("solar_sources.csv", "solar_sources_sha256"),
            ]:
                assert digest(payload[folder + "/" + filename]) == metadata[field]
    provenance = {
        "source_commit": source,
        "classification": "C2.7 prepared; MATLAB execution pending",
        "no_solar_zip_sha256": digest(no_solar.read_bytes()),
        "solar_zip_sha256": digest(solar.read_bytes()),
        "source_payload_sha256": original,
        "dataset_payload_sha256": {n: digest(b) for n, b in payload.items() if n not in original},
        "prebuilt_slx": False,
        "model_delivery": "Existing verified MATLAB builders generate models on the PC",
        "matlab_execution_in_cloud": False,
    }
    payload["PACKAGE_PROVENANCE.json"] = (json.dumps(provenance, indent=2) + "\n").encode()
    payload["PACKAGE_SHA256SUMS"] = "".join(
        f"{digest(b)}  {n}\n" for n, b in sorted(payload.items())
    ).encode()
    output.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(output, "x", compression=ZIP_DEFLATED, compresslevel=9) as z:
        for name, raw in sorted(payload.items()):
            assert not Path(name).is_absolute() and ".." not in Path(name).parts
            assert len("C:/THERMA_C27/THERMA_C27_MATLAB/" + name) < 240
            assert not any(p in [".git", ".venv", "__pycache__"] for p in Path(name).parts)
            info = ZipInfo("THERMA_C27_MATLAB/" + name, date_time=(2026, 11, 3, 0, 0, 0))
            info.compress_type = ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            z.writestr(info, raw, compress_type=ZIP_DEFLATED, compresslevel=9)
    with ZipFile(output) as z:
        assert z.testzip() is None
        for name, raw in payload.items():
            assert z.read("THERMA_C27_MATLAB/" + name) == raw
    return {
        "filename": output.name,
        "sha256": digest(output.read_bytes()),
        "bytes": output.stat().st_size,
        "source_commit": source,
        "files": len(payload),
        "matlab_execution": "pending",
    }


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--source", required=True)
    p.add_argument("--no-solar-zip", type=Path, required=True)
    p.add_argument("--solar-zip", type=Path, required=True)
    p.add_argument("--output", type=Path, required=True)
    a = p.parse_args()
    receipt = package(a.source, a.no_solar_zip, a.solar_zip, a.output)
    a.output.with_suffix(".receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print(json.dumps(receipt, indent=2))


if __name__ == "__main__":
    main()
