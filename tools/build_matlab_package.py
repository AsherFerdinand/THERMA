"""Cloud-side allowlisted dependency closure; university execution stays MATLAB-only."""

import argparse
import hashlib
import json
import re
import subprocess
import zipfile
from pathlib import Path, PurePosixPath

ROOT = Path(__file__).resolve().parents[1]


def safe_name(name: str) -> str:
    if not name or "\\" in name or ":" in name or name.startswith("/"):
        raise ValueError(f"Unsafe archive path: {name}")
    if any(p in {"", ".", ".."} for p in name.split("/")):
        raise ValueError(f"Unsafe archive path: {name}")
    return name


def dependency_closure(config: dict) -> set[str]:
    graph = config["matlab_dependencies"]
    selected: set[str] = set()

    def visit(name: str) -> None:
        safe_name(name)
        if name in selected:
            return
        if name not in graph:
            raise ValueError(f"Undeclared transitive dependency: {name}")
        selected.add(name)
        for child in graph[name]:
            visit(child)

    for entry in config["entry_points"]:
        visit(entry)
    return selected | {safe_name(n) for n in config["small_inputs"]}


def external_metadata(raw: bytes) -> bytes:
    """Only six external file identities; omit all prior measurement statistics."""
    original = json.loads(raw)
    metadata = {
        "source_commit": original["source_commit"],
        "source_metadata_sha256": hashlib.sha256(raw).hexdigest(),
        "kind": "external_file_identity_only",
        "selected_core_files": original["selected_core_files"],
        "files": [
            item for item in original["files"] if item["path"] in original["selected_core_files"]
        ],
    }
    return (json.dumps(metadata, indent=2) + "\n").encode()


def build_package(experiment: str, output: Path) -> Path:
    if experiment.upper() != "C42B":
        raise ValueError(
            "Only C42B is supported; historical experiments keep their existing runners."
        )
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()

    def source(name: str) -> bytes:
        return subprocess.check_output(["git", "show", f"{commit}:{safe_name(name)}"], cwd=ROOT)

    config_path = "experiments/C42B.json"
    config = json.loads(source(config_path))
    selected = dependency_closure(config) | {config_path}
    payload = {name: source(name) for name in sorted(selected)}
    # Reject omitted repository-local function calls in addition to the explicit graph.
    # Built-ins/toolbox resolution still requires native MATLAB; this is not a parser/compiler.
    all_names = subprocess.check_output(
        ["git", "ls-tree", "-r", "--name-only", commit], cwd=ROOT, text=True
    ).splitlines()
    local_functions = {PurePosixPath(n).stem: n for n in all_names if n.endswith(".m")}
    for name, raw in payload.items():
        if not name.endswith(".m"):
            continue
        for called in re.findall(r"\b([A-Za-z]\w*)\s*\(", raw.decode()):
            if called in local_functions and local_functions[called] not in selected:
                raise ValueError(f"Unpackaged local dependency {called} referenced by {name}")
    metadata_path = "docs/results/c42b/source_audit.json"
    payload[metadata_path] = external_metadata(payload[metadata_path])
    for name in payload:
        if any(p in {".git", ".venv", "tests", "outputs", "__pycache__"} for p in name.split("/")):
            raise ValueError(f"Excluded execution-package content: {name}")
        if name.endswith((".zip", ".csv", ".pdf", ".slx", ".mat")):
            raise ValueError(f"C42B package must contain no raw/model/history artifact: {name}")
    payload["README.md"] = (
        b"# THERMA C42B lightweight run\n\n"
        b"Fresh extraction only; no old THERMA folder needed. Read MATLAB_QUICKSTART.md.\n"
        b'In MATLAB R2025a: result = run_therma_experiment("C42B", "C:\\FLEXLAB_DATA");\n'
        b"Only base MATLAB with JVM is required; no Simulink/Git/Python/WSL.\n"
        b"Six external original CSVs are NOT bundled. Missing-data errors give official URLs.\n"
        b"Optional explicit download: addpath tools/matlab scripts/matlab/boptest;\n"
        b"acquire_therma_inputs('C:\\FLEXLAB_DATA','download',pwd);\n"
        b"Download mode needs Internet; existing local files work offline.\n"
        b"Native execution of this new wrapper remains pending. No simulation is performed.\n"
        b"Return the generated THERMA_RESULTS_C42B.zip; keep originals until an archive receipt.\n"
        b"Audit the OLD folder before deletion:\n"
        b"audit_therma_local_storage('C:\\OLD\\THERMA_C35_MATLAB');\n"
        b"The audit never deletes files or approves deletion.\n"
    )
    manifest = {
        "schema_version": 1,
        "experiment_id": "C42B",
        "kind": "inspection",
        "source_commit": commit,
        "matlab_release": config["matlab_release"],
        "required_products": config["required_products"],
        "native_execution_verified": False,
        "files": [
            {
                "path": n,
                "bytes": len(raw),
                "sha256": hashlib.sha256(raw).hexdigest(),
                "origin": (
                    "generated_readme"
                    if n == "README.md"
                    else "derived_external_metadata"
                    if n == metadata_path
                    else "git_source"
                ),
            }
            for n, raw in sorted(payload.items())
        ],
    }
    payload["package_manifest.json"] = (json.dumps(manifest, indent=2) + "\n").encode()
    output.mkdir(parents=True, exist_ok=True)
    archive = output / "THERMA_C42B_RUN.zip"
    if archive.exists():
        raise FileExistsError(f"Never overwrite a previous package: {archive}")
    with zipfile.ZipFile(archive, "x", zipfile.ZIP_DEFLATED) as z:
        for name, raw in sorted(payload.items()):
            info = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            z.writestr(info, raw)
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        for item in manifest["files"]:
            assert hashlib.sha256(z.read(item["path"])).hexdigest() == item["sha256"]
    if archive.stat().st_size >= 10 * 1024**2:
        raise ValueError(
            "Execution ZIP exceeds target; inspect before delivery, never discard inputs."
        )
    checksum = hashlib.sha256(archive.read_bytes()).hexdigest()
    archive.with_suffix(".zip.sha256").write_text(f"{checksum}  {archive.name}\n")
    print(
        f"{archive}: {archive.stat().st_size} bytes, {len(payload)} files, "
        f"source {commit}\nSHA256 {checksum}"
    )
    return archive


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("experiment")
    parser.add_argument("--output", type=Path, default=ROOT / "outputs/matlab_packages")
    args = parser.parse_args()
    build_package(args.experiment, args.output)
