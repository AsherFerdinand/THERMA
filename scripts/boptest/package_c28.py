"""Package pinned THERMA source and genuine reference data for offline MATLAB."""

from __future__ import annotations

import argparse
import hashlib
import io
import json
import subprocess
import tarfile
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

from therma.validation.temperature import read_reference
from therma.validation.temperature_study import FILES, IDS, load_pair


def study_payload(index_file: Path) -> tuple[dict[str, bytes], dict[str, object]]:
    """Keep original index-relative layout and every consumed receipt/export byte."""
    _, checked = load_pair(index_file)
    index = json.loads(index_file.read_text())
    session = index_file.parent.name
    payload = {}
    base = "outputs/boptest/c27/"
    for name in ["study_index.json", "contract.json"]:
        payload[base + session + "/" + name] = (index_file.parent / name).read_bytes()
    for experiment in IDS:
        relative = index["experiments"][experiment]["folder"]
        folder = index_file.parent.parent / relative
        for name in ["completion.json", *FILES]:
            payload[base + relative + "/" + name] = (folder / name).read_bytes()
    return payload, {
        "study_index": base + session + "/study_index.json",
        "study_artifacts": [
            {"path": name, "sha256": hashlib.sha256(raw).hexdigest()}
            for name, raw in sorted(payload.items())
        ],
        "study_verification": checked,
        "study_scope": "Original supplied no_solar_30/solar_30; refinements/events not bundled",
    }


def package(source: str, reference: Path, study: Path, output: Path) -> dict[str, object]:
    study_files, study_provenance = study_payload(study)
    read_reference(reference)
    metadata = json.loads((reference / "reference_metadata.json").read_text())
    for name, expected in [
        ("source_manifest.json", metadata["source_manifest_sha256"]),
        ("source_signals.json", metadata["source_signals_sha256"]),
        (
            "equivalent_manifest.json",
            metadata["compatible_reference_sources"][1]["manifest_sha256"],
        ),
        ("equivalent_signals.json", metadata["compatible_reference_sources"][1]["signals_sha256"]),
    ]:
        if hashlib.sha256((reference / name).read_bytes()).hexdigest() != expected:
            raise ValueError("Reference provenance artifact changed: " + name)
    commit = subprocess.check_output(["git", "rev-parse", source + "^{commit}"]).decode().strip()
    raw = subprocess.check_output(["git", "archive", "--format=tar", commit])
    payload = {}
    with tarfile.open(fileobj=io.BytesIO(raw)) as archive:
        for member in archive:
            if member.isfile():
                stream = archive.extractfile(member)
                assert stream is not None
                payload[member.name] = stream.read()
    for name in [
        "reference_temperature.csv",
        "reference_metadata.json",
        "source_manifest.json",
        "source_signals.json",
        "equivalent_manifest.json",
        "equivalent_signals.json",
    ]:
        payload["outputs/boptest/c28/reference/" + name] = (reference / name).read_bytes()
    payload.update(study_files)
    payload["C28_PACKAGE_PROVENANCE.json"] = (
        json.dumps(
            {
                "source_commit": commit,
                "status": "self_contained_controlled_pair_ready_MATLAB_execution_pending",
                **study_provenance,
                "matlab_execution_in_cloud": False,
                "reference_csv_sha256": metadata["csv_sha256"],
                "contains_C27_simulation_outputs": True,
            },
            indent=2,
        )
        + "\n"
    ).encode()
    payload["C28_PACKAGE_SHA256SUMS"] = "".join(
        hashlib.sha256(value).hexdigest() + "  " + key + "\n"
        for key, value in sorted(payload.items())
    ).encode()
    output.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(output, "x", ZIP_DEFLATED) as archive:
        for name, value in sorted(payload.items()):
            archive.writestr("THERMA_C28_MATLAB/" + name, value)
    with ZipFile(output) as archive:
        assert archive.testzip() is None
        for name, value in payload.items():
            assert archive.read("THERMA_C28_MATLAB/" + name) == value
    receipt = {
        "filename": output.name,
        "source_commit": commit,
        "files": len(payload),
        "sha256": hashlib.sha256(output.read_bytes()).hexdigest(),
    }
    output.with_suffix(".receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    return receipt


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True)
    parser.add_argument("--reference", type=Path, required=True)
    parser.add_argument("--study", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    print(json.dumps(package(args.source, args.reference, args.study, args.output), indent=2))
