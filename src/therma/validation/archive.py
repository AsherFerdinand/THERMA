"""Import actual MATLAB evidence unchanged; validate selected archived reports.

Import never establishes that MATLAB was independently rerun. Reports are unsigned
execution evidence, not cryptographic attestations. Git is optional on import PCs.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import re
import shutil
import subprocess
import tempfile
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[3]
REGISTRY = "configs/references/boptest_bestest_hydronic.json"
ASSUMPTIONS = "configs/references/c2_reduced_assumptions.json"
REGISTRY_HASH = "f91141d78668908525d484a4900dc69af1a163c4c5e07f5a5fbd0c43eae4451c"
EXPECTED = {
    "C1": {
        "A_B_R_C",
        "C_uniform_all_surfaces",
        "F_G_core_energy_and_floor",
        "South_Wall",
        "North_Wall",
        "East_Wall",
        "West_Wall",
        "Roof",
        "Floor",
    },
    "C2": {
        "equilibrium",
        "cold_outdoor",
        "constant_heating",
        "heating_step",
        "heating_shutdown",
        "outdoor_step",
        "internal_step",
        "solar_step",
        "warm_ventilation",
        "surface_perturbation",
    },
}


def sha256(raw: bytes) -> str:
    return hashlib.sha256(raw).hexdigest()


def digest(value: object) -> str:
    if not isinstance(value, str) or re.fullmatch(r"[0-9a-f]{64}", value) is None:
        raise ValueError("Expected lowercase SHA-256")
    return value


def _pairs(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("Duplicate JSON key: " + key)
        result[key] = value
    return result


def _nonfinite(value: str) -> None:
    raise ValueError("Nonfinite JSON value: " + value)


def read_json(raw: bytes) -> dict[str, Any]:
    if len(raw) > 2_000_000:
        raise ValueError("Evidence JSON exceeds 2 MB; import only selected report")
    value = json.loads(raw, object_pairs_hook=_pairs, parse_constant=_nonfinite)
    if not isinstance(value, dict):
        raise ValueError("Expected JSON object")
    return value


def validate_report(report: dict[str, Any], phase: str) -> dict[str, str]:
    if phase not in EXPECTED or report.get("schema_version", 1) != 1:
        raise ValueError("Unsupported report schema or phase")
    if report.get("status") != "passed" or report.get("matlab_verified") is not True:
        raise ValueError("Report must be successfully MATLAB verified")
    cases = report.get("cases")
    if not isinstance(cases, list) or not all(isinstance(c, dict) for c in cases):
        raise ValueError("Missing case records")
    names = [c.get("name") for c in cases]
    if not all(isinstance(n, str) for n in names):
        raise ValueError("Scenario names must be strings")
    if len(names) != len(set(names)) or set(names) != EXPECTED[phase]:
        raise ValueError("Missing, unexpected or duplicate scenarios")
    if any(c.get("status") != "passed" for c in cases):
        raise ValueError("Every scenario must have passed")
    if report.get("registry_sha256") != REGISTRY_HASH:
        raise ValueError("Wrong frozen reference registry hash")
    if not isinstance(report.get("matlab_version"), str) or not report["matlab_version"]:
        raise ValueError("Missing MATLAB version")
    version_key = "simulink_version" if phase == "C2" else "simulink"
    if not isinstance(report.get(version_key), dict) or not report[version_key].get("Version"):
        raise ValueError("Missing Simulink version")
    if phase == "C2":
        for case in cases:
            if case.get("convergence_improved") is not True:
                raise ValueError("Scenario convergence must be established")
            for level in ("coarse", "refined"):
                metrics = case.get(level)
                if not isinstance(metrics, dict) or metrics.get("passed") is not True:
                    raise ValueError("Missing successful coarse/refined metrics")
                solver = metrics.get("solver", {})
                if not solver.get("name"):
                    raise ValueError("Missing solver identity")
                for key in ("RelTol", "AbsTol_K", "MaxStep_s"):
                    value = solver.get(key)
                    if (
                        isinstance(value, bool)
                        or not isinstance(value, (int, float))
                        or not math.isfinite(value)
                        or value <= 0
                    ):
                        raise ValueError("Missing/invalid solver setting")
                for key in (
                    "temperature_error_K",
                    "corrected_integral_residual_J",
                    "max_power_residual_W",
                ):
                    value = metrics.get(key)
                    if (
                        isinstance(value, bool)
                        or not isinstance(value, (int, float))
                        or not math.isfinite(value)
                        or value < 0
                    ):
                        raise ValueError("Missing/invalid numerical metric")
                for error_key, budget_key in (
                    ("temperature_error_K", "temperature_budget_K"),
                    ("corrected_integral_residual_J", "energy_budget_J"),
                    ("max_power_residual_W", "power_roundoff_budget_W"),
                ):
                    budget = metrics.get(budget_key)
                    if (
                        not isinstance(budget, (int, float))
                        or isinstance(budget, bool)
                        or not math.isfinite(budget)
                        or budget <= 0
                    ):
                        raise ValueError("Missing/invalid numerical budget")
                    if metrics[error_key] > budget:
                        raise ValueError("Passed status contradicts reported numerical budget")
    files = {REGISTRY: REGISTRY_HASH}
    if phase == "C2":
        files[ASSUMPTIONS] = digest(report.get("assumptions_sha256"))
        sources = report.get("source_sha256")
        if not isinstance(sources, dict) or not sources:
            raise ValueError("Missing MATLAB source hashes")
        # MATLAB makeValidName transforms each filename suffix .m into _m.
        for key, value in sources.items():
            if re.fullmatch(r"[A-Za-z][A-Za-z0-9_]*_m", key) is None:
                raise ValueError("Unrecognized MATLAB source hash key")
            files["scripts/matlab/boptest/" + key[:-2] + ".m"] = digest(value)
        required = {
            "build_boptest_zone_c2_m",
            "verify_boptest_zone_c2_m",
            "load_boptest_zone_parameters_m",
            "add_boptest_construction_m",
            "load_boptest_envelope_parameters_m",
            "boptest_zone_analytical_network_m",
        }
        if not required <= sources.keys():
            raise ValueError("Incomplete source provenance")
    return files


def verify_files(files: dict[str, str], root: Path) -> None:
    for name, expected in files.items():
        path = root / name
        if not path.is_file() or sha256(path.read_bytes()) != expected:
            raise ValueError("Source snapshot mismatch: " + name)


def verify_commit(files: dict[str, str], root: Path, commit: str) -> str:
    if re.fullmatch(r"[0-9a-f]{40}", commit) is None:
        raise ValueError("Use an explicit full 40-character source commit")
    for name, expected in files.items():
        try:
            raw = subprocess.check_output(
                ["git", "show", f"{commit}:{name}"], cwd=root, stderr=subprocess.DEVNULL
            )
        except (OSError, subprocess.CalledProcessError) as error:
            raise ValueError("Source commit unavailable or file missing") from error
        if sha256(raw) != expected:
            raise ValueError("Source commit does not match report hashes: " + name)
    return commit


def archive_report(
    report_path: Path,
    phase: str,
    release: str,
    destination: Path,
    source_root: Path = ROOT,
    source_commit: str | None = None,
    verification_date: str | None = None,
) -> Path:
    if re.fullmatch(r"R20\d\d[ab]", release) is None:
        raise ValueError("Invalid MATLAB release")
    if verification_date is not None:
        datetime.strptime(verification_date, "%Y-%m-%d")
    raw = report_path.read_bytes()
    report = read_json(raw)
    files = validate_report(report, phase)
    version = report["matlab_version"]
    releases = re.findall(r"R20\d\d[ab]", version)
    if releases and release not in releases:
        raise ValueError("Claimed MATLAB release differs from report")
    verify_files(files, source_root)
    if phase == "C2" and report.get("assumptions") != read_json(
        (source_root / ASSUMPTIONS).read_bytes()
    ):
        raise ValueError("Embedded assumptions differ from hashed assumptions file")
    verified_commit = None
    if source_commit is not None:
        if phase != "C2":
            raise ValueError("Legacy C1 report lacks sufficient source hashes to verify a commit")
        verified_commit = verify_commit(files, source_root, source_commit)
    report_hash = sha256(raw)
    for existing in destination.glob("**/metadata.json"):
        if read_json(existing.read_bytes()).get("report_sha256") == report_hash:
            raise FileExistsError("Report already archived")
    target = destination / phase.lower() / ("matlab-" + release.lower()) / report_hash[:16]
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        raise FileExistsError("Evidence destination exists")
    metadata = {
        "schema_version": 1,
        "phase": phase,
        "model_version": report.get("model_version"),
        "matlab_release": release,
        "simulink": report["simulink_version" if phase == "C2" else "simulink"],
        "report_sha256": report_hash,
        "registry_sha256": report["registry_sha256"],
        "assumptions_sha256": report.get("assumptions_sha256"),
        "source_files": files,
        "source_git_commit": verified_commit,
        "source_git_status": "hashes_verified" if verified_commit else "unresolved",
        "source_commit_basis": (
            "Explicit candidate matches recorded file hashes; "
            "report does not record Git checkout identity."
        ),
        "verification_date": verification_date,
        "verification_date_origin": "user_supplied" if verification_date else "unknown",
        "imported_utc": datetime.now(UTC).isoformat(),
        "status": "passed",
        "scenarios_passed": len(report["cases"]),
        "origin": "university MATLAB execution; supplied report, not independently reproduced",
        "independently_reproduced_by_ci": False,
    }
    staging = Path(tempfile.mkdtemp(prefix=".import-", dir=target.parent))
    try:
        (staging / "verification.json").write_bytes(raw)
        (staging / "metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")
        (staging / "README.md").write_text(
            f"# {phase} {release} imported evidence\n\n"
            "Original report bytes are preserved. Import integrity does not independently "
            "reproduce MATLAB or establish BOPTEST validation.\n"
        )
        # mkdir rather than replace: never overwrite existing evidence, even on a race.
        target.mkdir()
        for path in staging.iterdir():
            shutil.move(str(path), str(target / path.name))
    finally:
        shutil.rmtree(staging)
    return target


def validate_archive(root: Path) -> int:
    count = 0
    reports = set(root.glob("**/verification.json"))
    for path in sorted(root.glob("**/metadata.json")):
        metadata = read_json(path.read_bytes())
        if metadata.get("schema_version") != 1:
            raise ValueError("Unsupported evidence metadata schema")
        report_path = path.parent / "verification.json"
        raw = report_path.read_bytes()
        report = read_json(raw)
        files = validate_report(report, metadata["phase"])
        if metadata.get("report_sha256") != sha256(raw) or metadata.get("source_files") != files:
            raise ValueError("Modified report or inconsistent source metadata")
        checks = {
            "model_version": report.get("model_version"),
            "registry_sha256": report["registry_sha256"],
            "assumptions_sha256": report.get("assumptions_sha256"),
            "simulink": report["simulink_version" if metadata["phase"] == "C2" else "simulink"],
            "status": "passed",
            "scenarios_passed": len(report["cases"]),
            "independently_reproduced_by_ci": False,
        }
        if any(metadata.get(key) != value for key, value in checks.items()):
            raise ValueError("Evidence metadata disagrees with report")
        releases = re.findall(r"R20\d\d[ab]", report["matlab_version"])
        if releases and metadata.get("matlab_release") not in releases:
            raise ValueError("Evidence release disagrees with report")
        commit = metadata.get("source_git_commit")
        expected_status = "unresolved" if commit is None else "hashes_verified"
        if metadata.get("source_git_status") != expected_status:
            raise ValueError("Inconsistent source Git provenance status")
        if commit is not None:
            verify_commit(files, ROOT, commit)
        reports.discard(report_path)
        count += 1
    if reports:
        raise ValueError("Report has no provenance metadata")
    return count


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--phase", choices=sorted(EXPECTED))
    parser.add_argument("--report", type=Path)
    parser.add_argument("--matlab-release")
    parser.add_argument("--archive-root", type=Path, default=ROOT / "verification")
    parser.add_argument("--source-root", type=Path, default=ROOT)
    parser.add_argument("--source-commit")
    parser.add_argument("--verification-date")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    if args.check:
        print(f"Archived reports checked: {validate_archive(args.archive_root)}")
    else:
        if not (args.phase and args.report and args.matlab_release):
            parser.error("Import requires --phase, --report and --matlab-release")
        print(
            archive_report(
                args.report,
                args.phase,
                args.matlab_release,
                args.archive_root,
                args.source_root,
                args.source_commit,
                args.verification_date,
            )
        )


if __name__ == "__main__":
    main()
