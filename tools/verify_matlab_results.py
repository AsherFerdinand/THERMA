"""Verify returned MATLAB ZIP integrity/source provenance, never infer execution proof."""

import argparse
import hashlib
import json
import re
import subprocess
import sys
import zipfile
from pathlib import Path

# Supports both direct CLI and import during software tests.
sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_matlab_package import ROOT, dependency_closure, safe_name  # noqa: E402


def verify_results(archive: Path) -> dict:
    if archive.stat().st_size > 50 * 1024**2:
        raise ValueError("Over50MiB: use reviewed external archival")
    with zipfile.ZipFile(archive) as z:
        names = z.namelist()
        if len(names) != len(set(n.casefold() for n in names)) or len(names) > 32:
            raise ValueError("Duplicate/excessive ZIP entries")
        allowed = {
            "result_manifest.json",
            "verification.json",
            "package_manifest.json",
            "experiment.json",
            "SOURCE_COMMIT.txt",
            "matlab_execution.log",
            "inspection_summary.json",
            "measured_temperatures.png",
            "measured_cooling.png",
        }
        for item in z.infolist():
            safe_name(item.filename)
            if item.filename not in allowed or ((item.external_attr >> 16) & 0o170000) == 0o120000:
                raise ValueError("Unexpected content or symbolic link in result ZIP")
        if sum(i.file_size for i in z.infolist()) > 50 * 1024**2:
            raise ValueError("Over50MiB: use reviewed external archival; no silent reduction")
        raw = {name: z.read(name) for name in names}  # CRC checked by ZIP reader; bounded above
    required = {
        "result_manifest.json",
        "verification.json",
        "package_manifest.json",
        "experiment.json",
        "SOURCE_COMMIT.txt",
        "matlab_execution.log",
    }
    if not required <= raw.keys():
        raise ValueError("Missing result receipt/log/configuration")
    result = json.loads(raw["result_manifest.json"])
    package = json.loads(raw["package_manifest.json"])
    execution = json.loads(raw["verification.json"])
    if result["schema_version"] != 1 or package["schema_version"] != 1:
        raise ValueError("Unsupported manifest schema")
    listed = result["files"]
    if len(listed) != len({i["path"].casefold() for i in listed}):
        raise ValueError("Duplicate result-manifest paths")
    if {i["path"] for i in listed} != set(raw) - {"result_manifest.json"}:
        raise ValueError("Unlisted or omitted result files")
    for item in listed:
        value = raw[safe_name(item["path"])]
        if len(value) != item["bytes"] or hashlib.sha256(value).hexdigest() != item["sha256"]:
            raise ValueError(f"Changed result bytes: {item['path']}")
    if package["kind"] != "inspection" or execution["kind"] != "inspection":
        raise ValueError("Only inspection receipts are supported")
    commit = package["source_commit"]
    if not re.fullmatch(r"[0-9a-f]{40}", commit):
        raise ValueError("Source commit must be a full Git object ID")

    def source(name: str) -> bytes:
        return subprocess.check_output(["git", "show", f"{commit}:{safe_name(name)}"], cwd=ROOT)

    configuration = json.loads(source("experiments/C42B.json"))
    if raw["experiment.json"] != source("experiments/C42B.json"):
        raise ValueError("Changed experiment configuration")
    expected = dependency_closure(configuration) | {"experiments/C42B.json", "README.md"}
    if len(package["files"]) != len(expected) or {i["path"] for i in package["files"]} != expected:
        raise ValueError("Incomplete/extra package dependency inventory")
    for item in package["files"]:
        if item["path"] == "README.md" and item["origin"] == "generated_readme":
            continue  # Generated instruction text is not falsely treated as a Git source file.
        if item["origin"] != "git_source":
            raise ValueError("Unknown package provenance")
        value = source(item["path"])
        if len(value) != item["bytes"] or hashlib.sha256(value).hexdigest() != item["sha256"]:
            raise ValueError(f"Source hash mismatch: {item['path']}")
    if any(
        d["source_commit"] != commit or d["experiment_id"] != "C42B"
        for d in [result, package, execution]
    ):
        raise ValueError("Source/experiment identity disagreement")
    if raw["SOURCE_COMMIT.txt"].decode().strip() != commit:
        raise ValueError("Source receipt mismatch")
    if result["status"] != execution["status"] or execution["status"] not in {
        "failed",
        "completed_inspection",
    }:
        raise ValueError("Contradictory/unknown execution status")
    if any(d["simulation_performed"] is not False for d in [result, execution]):
        raise ValueError("Inspection must not claim simulation")
    if any(d["empirical_validation_performed"] is not False for d in [result, execution]):
        raise ValueError("Inspection must not claim empirical validation")
    if result["raw_measurements_included"] is not False:
        raise ValueError("Do not redistribute raw FLEXLAB measurements")
    success = execution["status"] == "completed_inspection"
    if success:
        if execution["matlab_release"] != "2025a" or execution["inputs_verified"] is not True:
            raise ValueError("Unverified release/inputs cannot be accepted as completed inspection")
        if execution["matlab_executed"] is not True:
            raise ValueError("Missing reported native execution")
        for name in [
            "inspection_summary.json",
            "measured_temperatures.png",
            "measured_cooling.png",
        ]:
            if name not in raw or not raw[name]:
                raise ValueError(f"Missing successful inspection output: {name}")
        audit = json.loads(source("docs/results/c42b/source_audit.json"))
        wanted = {i["path"]: i for i in audit["files"] if i["path"] in audit["selected_core_files"]}
        actual = execution["external_inputs"]
        if len(actual) != 6 or {i["path"] for i in actual} != wanted.keys():
            raise ValueError("External input inventory mismatch")
        for item in actual:
            known = wanted[item["path"]]
            if item["verified"] is not True or any(
                item[k] != known[k] for k in ["sha256", "bytes", "source"]
            ):
                raise ValueError("External input provenance mismatch")
        inspection = json.loads(raw["inspection_summary.json"])
        if (
            inspection["source_commit"] != audit["source_commit"]
            or inspection["selected_rows_per_source"] != 721
            or inspection["simulation_performed"] is not False
        ):
            raise ValueError("Inspection summary disagrees with pinned selection")
    privacy = [
        name
        for name, value in raw.items()
        if name.endswith((".json", ".log"))
        and re.search(rb"(?:[A-Za-z]:[\\/]|\\\\[^\s\\]+\\|/(?:home|workspace|Users)/)", value)
    ]
    with archive.open("rb") as stream:
        archive_hash = hashlib.file_digest(stream, "sha256").hexdigest()
    return {
        "zip_sha256": archive_hash,
        "source_commit": commit,
        "execution_status": execution["status"],
        "reported_matlab_release": execution.get("matlab_release"),
        "integrity_and_source_checked": True,
        "native_execution_independently_verified": False,
        "eligible_for_success_archive": success,
        "privacy_review_files": privacy,
        "automatic_publication_performed": False,
        "privacy_review_required": bool(privacy),
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("zip", type=Path)
    args = parser.parse_args()
    report = verify_results(args.zip)
    print(json.dumps(report, indent=2))
    if not report["eligible_for_success_archive"]:
        sys.exit(2)
