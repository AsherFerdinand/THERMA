"""Package C3.1-C3.3 native MATLAB component verification; no raw datasets needed."""

from __future__ import annotations

import argparse
import hashlib
import io
import json
import subprocess
import tarfile
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

REQUIRED = {
    "run_c3_verification.m",
    "START_C3.md",
    "configs/c3/illustrative_components.json",
    "scripts/matlab/c3/load_c3_parameters.m",
    "scripts/matlab/c3/c3_block.m",
    "scripts/matlab/c3/add_c3_thermostat.m",
    "scripts/matlab/c3/add_c3_valve.m",
    "scripts/matlab/c3/add_c3_radiator.m",
    "scripts/matlab/c3/build_c3_component.m",
    "scripts/matlab/c3/simulate_c3_component.m",
    "tests/matlab/test_therma_c3_components.m",
    "scripts/matlab/boptest/boptest_file_sha256.m",
    "scripts/matlab/boptest/boptest_sha256_update.m",
    "scripts/matlab/boptest/write_boptest_json.m",
    "scripts/matlab/boptest/boptest_exception_diagnostic.m",
    "scripts/matlab/boptest/print_boptest_exception.m",
}


C34_REQUIRED = REQUIRED | {
    "START_C34.md",
    "run_c34_verification.m",
    "configs/c3/integration_c34.json",
    "scripts/matlab/c3/load_c34_experiment.m",
    "scripts/matlab/c3/build_c34_model.m",
    "scripts/matlab/c3/assess_c34.m",
    "scripts/matlab/c3/simulate_c34_model.m",
    "scripts/matlab/c3/export_c34_results.m",
    "scripts/matlab/c3/write_c34_csv.m",
    "tests/matlab/test_therma_c34_integration.m",
    "verification/c3/component_gate/summary.json",
    "verification/c3/component_gate/matlab_component_test_log.txt",
    "configs/references/boptest_bestest_hydronic.json",
    "configs/references/c2_reduced_assumptions.json",
    "scripts/matlab/boptest/build_boptest_zone_c2.m",
    "scripts/matlab/boptest/load_boptest_zone_parameters.m",
    "scripts/matlab/boptest/load_boptest_envelope_parameters.m",
    "scripts/matlab/boptest/add_boptest_construction.m",
}


def package(source: str, output: Path, stage: str = "components") -> dict[str, object]:
    commit = subprocess.check_output(["git", "rev-parse", source + "^{commit}"]).decode().strip()
    raw = subprocess.check_output(["git", "archive", "--format=tar", commit])
    payload = {}
    with tarfile.open(fileobj=io.BytesIO(raw)) as archive:
        for member in archive:
            if member.isfile():
                stream = archive.extractfile(member)
                assert stream is not None
                payload[member.name] = stream.read()
    if not REQUIRED <= payload.keys():
        raise ValueError(
            "Missing required component package files: " + str(REQUIRED - payload.keys())
        )
    if any(name.startswith("outputs/") for name in payload):
        raise ValueError(
            "C3 components must not depend on bundled simulation or reference datasets"
        )
    source_hashes = {name: hashlib.sha256(raw).hexdigest() for name, raw in payload.items()}
    # Offline entrypoint must describe C3, not the historical C2.7 root guide.
    guide = "START_C34.md" if stage == "integration" else "START_C3.md"
    prefix = "C34" if stage == "integration" else "C3"
    payload["START_HERE.md"] = payload[guide]
    provenance = {
        "source_commit": commit,
        "scope": (
            "C3.4 closed-loop integration"
            if stage == "integration"
            else "C3.1-C3.3 isolated illustrative components"
        ),
        "matlab_execution_in_cloud": False,
        "C3_4_integration": (
            "prepared_MATLAB_execution_pending"
            if stage == "integration"
            else "blocked_pending_component_execution"
        ),
        "prebuilt_SLX": False,
        "SLX_delivery": "Native builders save models on university MATLAB",
        "source_payload_sha256": source_hashes,
        "documentation_override": {"START_HERE.md": guide},
        "raw_datasets_required": False,
    }
    payload[prefix + "_PACKAGE_PROVENANCE.json"] = (
        json.dumps(provenance, indent=2) + "\n"
    ).encode()
    payload[prefix + "_PACKAGE_SHA256SUMS"] = "".join(
        hashlib.sha256(value).hexdigest() + "  " + name + "\n"
        for name, value in sorted(payload.items())
    ).encode()
    output.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(output, "x", ZIP_DEFLATED) as archive:
        for name, value in sorted(payload.items()):
            if Path(name).is_absolute() or ".." in Path(name).parts:
                raise ValueError("Unsafe ZIP member")
            archive.writestr("THERMA_" + prefix + "_MATLAB/" + name, value)
    with ZipFile(output) as archive:
        assert archive.testzip() is None
        for name, value in payload.items():
            assert archive.read("THERMA_" + prefix + "_MATLAB/" + name) == value
    receipt = {
        "filename": output.name,
        "sha256": hashlib.sha256(output.read_bytes()).hexdigest(),
        "source_commit": commit,
        "files": len(payload),
        "scope": provenance["scope"],
        "matlab_execution": "pending",
    }
    output.with_suffix(".receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    return receipt


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--stage", choices=["components", "integration"], default="components")
    args = parser.parse_args()
    print(json.dumps(package(args.source, args.output, args.stage), indent=2))
