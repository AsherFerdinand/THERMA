# THERMA

A research project for a modular, web-based digital twin of hydronic building heating.
The project began with a MATLAB/Simulink bachelor's thesis describing a three-storey apartment
building with 36 rooms, a central boiler, distribution pipes, radiators and controllers.
The reference repository has been inspected statically; see [the inventory](docs/SIMULINK_INVENTORY.md).
Reference assets are not vendored, and raw validation datasets are not yet available.

Current scope: **C2.5 — archived local verification evidence and reference-comparison infrastructure**. No Python physics solver, surrogate, API or web UI
is implemented. Original-FMU reference outputs exist; no THERMA/Simulink equivalence
or performance improvement is claimed.

## Development

Prerequisites: Python 3.12 and [uv](https://docs.astral.sh/uv/). From the checkout root:

```bash
# The cache override works in cloud environments with a read-only home directory.
export UV_CACHE_DIR=/workspace/.cache/uv  # optional on other machines
uv sync --frozen
uv run --frozen pytest
uv run --frozen ruff check .
uv run --frozen ruff format --check .
uv run --frozen mypy
```

`uv.lock` pins runtime and development packages. `uv sync --frozen` creates `.venv` and
installs the project in editable mode. No services, credentials or MATLAB installation
are needed for Phase 0. Future dependencies will be added when their phases begin.

## Configuration

`configs/project.toml` contains non-physical project metadata. Load it explicitly:

```python
from therma.config import load_config

config = load_config("configs/project.toml")
print(config.name)
```

Paths resolve from the caller's working directory. The loader rejects unknown keys,
empty names and incorrect types. Physical schema, units and solver controls are deferred
until the reference model has been verified in MATLAB; no default physical values are assumed.

## Layout

- `src/therma/`: Python package and configuration loader
- `tests/`: automated tests
- `configs/`: versioned, non-secret configuration examples
- `docs/`: roadmap, progress, architecture decisions and reference handoff
- `models/simulink/`: guidance for preserving the original reference model
- `data/raw/`, `data/processed/`: local datasets; generated contents are ignored
- `notebooks/`, `scripts/`: reserved analysis and automation locations

Read [the roadmap](docs/ROADMAP.md), [progress](docs/PROGRESS.md), and
[development guidance](docs/DEVELOPMENT.md) before contributing.

Phase 1A deliverables: [migration plan](docs/MIGRATION_PLAN.md) and
[reference data plan](docs/REFERENCE_DATA_PLAN.md). University MATLAB diagnostics remain pending.

The selected independent reconstruction reference is now BOPTEST `bestest_hydronic`
(BESTEST Case 900 envelope). Read [the pinned physical/reference extraction](docs/BOPTEST_REFERENCE.md)
and its [machine-readable parameters](configs/references/boptest_bestest_hydronic.json).
The thesis model and local EN 12831 room-builder draft remain separate; neither has
been validated as a BOPTEST reconstruction. The original BOPTEST FMU has now run via
an isolated FMI runtime; C2 has since passed local MATLAB verification as recorded below.

See [baseline results and reproduction commands](docs/BOPTEST_BASELINE.md) and the
[envelope-first Simulink contract](docs/BOPTEST_SIMULINK_CONTRACT.md). Generated CSVs,
plots, FMUs and runtime environments remain under ignored `outputs/boptest/`.

The [C1 layered-envelope builder and university execution guide](docs/BOPTEST_SIMULINK_C1.md)
use 27 source-derived thermal states. C1 success on R2025a is user-reported;
the full verification report and exact local source revision remain to be archived.


The user reports C1 verification passed on R2025a; the full local report is not yet
archived. See the [sprint audit](docs/SPRINT_AUDIT.md),
[C2 equations and exact MATLAB commands](docs/BOPTEST_SIMULINK_C2.md),
[comparison tools](docs/REFERENCE_COMPARISON.md) and [C3 gates](docs/C3_READINESS.md).
C2 uses explicit provisional dry-air/surface assumptions and is not an exact
BOPTEST reconstruction. Its successful local MATLAB report is now archived below.


## Engineering verification evidence

University MATLAB **R2025a** execution at Technische Hochschule Ingolstadt:
**10/10 C2 scenarios passed**, with the [actual original report archived](verification/c2/matlab-r2025a/b00092e4236789a4/verification.json)
and [separate hash/source provenance](verification/c2/matlab-r2025a/b00092e4236789a4/metadata.json).
The user separately reports **7/7 MATLAB unit tests passed**; that test log is not
part of the report. All recorded source hashes match commit `071269e`.
Codex/CI check integrity and static code; they have not independently executed MATLAB.
C1 also passed according to the user, but its original report is not archived.

C2 remains a verified **reduced** model, not BOPTEST-validated. Phase C2.5 now provides
[evidence import/integrity tools](docs/VERIFICATION_EVIDENCE.md), a
[signal compatibility matrix](docs/C2_SIGNAL_COMPATIBILITY.md), and
[partial reference-replay/comparison commands](docs/C2_REFERENCE_REPLAY.md).
Missing absorbed solar/full initial states and simplified physics limit comparisons;
[C2.6 refinement](docs/C2_PHYSICS_GAPS.md) is recommended before C3 hydronics.


## C2.5C replay analysis

The user reports the first 21-day partial replay completed on MATLAB R2025a. Its
actual three export files are still awaiting upload here; no replay temperature
metrics or validation claim have been made. The read-only
[analysis pipeline and sign audit](docs/C25C_REPLAY_ANALYSIS.md) generate PNG/PDF
figures, metrics JSON and an engineering summary from actual exports. Original
BOPTEST trajectories are available locally; matching uses air temperature, not
operative temperature. Signed reverse radiator heat exists in the reference and
is retained. C2.6 remains unimplemented pending first comparison review.
