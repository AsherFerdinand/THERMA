# Historical project overview — retained in full

Archived from source commit `a57a62aa823624688a62ccde0ac7ed8a039a210e`.
Relative links adjusted for this archive location. This is a chronological record;
use [the current quickstart](../../MATLAB_QUICKSTART.md) for new execution packages.

# THERMA

A research project for a modular, web-based digital twin of hydronic building heating.
The project began with a MATLAB/Simulink bachelor's thesis describing a three-storey apartment
building with 36 rooms, a central boiler, distribution pipes, radiators and controllers.
The reference repository has been inspected statically; see [the inventory](../../docs/SIMULINK_INVENTORY.md).
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

Read [the roadmap](../../docs/ROADMAP.md), [progress](../../docs/PROGRESS.md), and
[development guidance](../../docs/DEVELOPMENT.md) before contributing.

Phase 1A deliverables: [migration plan](../../docs/MIGRATION_PLAN.md) and
[reference data plan](../../docs/REFERENCE_DATA_PLAN.md). University MATLAB diagnostics remain pending.

The selected independent reconstruction reference is now BOPTEST `bestest_hydronic`
(BESTEST Case 900 envelope). Read [the pinned physical/reference extraction](../../docs/BOPTEST_REFERENCE.md)
and its [machine-readable parameters](../../configs/references/boptest_bestest_hydronic.json).
The thesis model and local EN 12831 room-builder draft remain separate; neither has
been validated as a BOPTEST reconstruction. The original BOPTEST FMU has now run via
an isolated FMI runtime; C2 has since passed local MATLAB verification as recorded below.

See [baseline results and reproduction commands](../../docs/BOPTEST_BASELINE.md) and the
[envelope-first Simulink contract](../../docs/BOPTEST_SIMULINK_CONTRACT.md). Generated CSVs,
plots, FMUs and runtime environments remain under ignored `outputs/boptest/`.

The [C1 layered-envelope builder and university execution guide](../../docs/BOPTEST_SIMULINK_C1.md)
use 27 source-derived thermal states. C1 success on R2025a is user-reported;
the full verification report and exact local source revision remain to be archived.


The user reports C1 verification passed on R2025a; the full local report is not yet
archived. See the [sprint audit](../../docs/SPRINT_AUDIT.md),
[C2 equations and exact MATLAB commands](../../docs/BOPTEST_SIMULINK_C2.md),
[comparison tools](../../docs/REFERENCE_COMPARISON.md) and [C3 gates](../../docs/C3_READINESS.md).
C2 uses explicit provisional dry-air/surface assumptions and is not an exact
BOPTEST reconstruction. Its successful local MATLAB report is now archived below.


## Engineering verification evidence

University MATLAB **R2025a** execution at Technische Hochschule Ingolstadt:
**10/10 C2 scenarios passed**, with the [actual original report archived](../../verification/c2/matlab-r2025a/b00092e4236789a4/verification.json)
and [separate hash/source provenance](../../verification/c2/matlab-r2025a/b00092e4236789a4/metadata.json).
The user separately reports **7/7 MATLAB unit tests passed**; that test log is not
part of the report. All recorded source hashes match commit `071269e`.
Codex/CI check integrity and static code; they have not independently executed MATLAB.
C1 also passed according to the user, but its original report is not archived.

C2 remains a verified **reduced** model, not BOPTEST-validated. Phase C2.5 now provides
[evidence import/integrity tools](../../docs/VERIFICATION_EVIDENCE.md), a
[signal compatibility matrix](../../docs/C2_SIGNAL_COMPATIBILITY.md), and
[partial reference-replay/comparison commands](../../docs/C2_REFERENCE_REPLAY.md).
Missing absorbed solar/full initial states and simplified physics limit comparisons;
[C2.6 refinement](../../docs/C2_PHYSICS_GAPS.md) is recommended before C3 hydronics.


## C2.5C replay analysis

The user reports the first 21-day partial replay completed on MATLAB R2025a. Its
actual three export files have now been imported unchanged and analyzed: air-temperature
MAE **2.341 K**, RMSE **2.806 K**, bias **-2.335 K** over the 14-day evaluation.
See [the actual-results engineering summary](../../docs/C25C_FIRST_ACTUAL_RESULTS.md).
This exploratory partial-forcing comparison is not BOPTEST validation. The read-only
[analysis pipeline and sign audit](../../docs/C25C_REPLAY_ANALYSIS.md) generate PNG/PDF
figures, metrics JSON and an engineering summary from actual exports. Original
BOPTEST trajectories are available locally; matching uses air temperature, not
operative temperature. Signed reverse radiator heat exists in the reference and
is retained. C2.6A/B now adds solar-resolved reference extraction and replay preparation;
C2.6C has now executed on university MATLAB R2021a; see the results below.


[Download the actual C2.5C figures and reports](https://github.com/AsherFerdinand/THERMA/raw/refs/heads/replay-transfer/THERMA_first_typical_actual_analysis.zip)
from the separate transfer branch. Raw uploads/reference datasets/models are excluded.
See [C2.6 prerequisites](../../docs/C26_PREREQUISITES.md) for newly confirmed solar/state
access and the proposed plan. No C1/C2 physics or parameter calibration was changed.


[C2.6A/B solar-resolved benchmarking](../../docs/C26_SOLAR_BENCHMARK.md) is implemented:
actual pinned-FMU solar extraction, 39-state observations, checked opt-in v2 packets,
MATLAB preparation and future paired diagnostics. The unchanged baseline channels
reproduce exactly. [Download the prepared replay/reference packet](https://github.com/AsherFerdinand/THERMA/raw/refs/heads/replay-transfer/THERMA_C26_solar_replay.zip)
from the separate transfer branch; [checksums and actual checks](../../docs/C26_ARTIFACTS.json).
Actual C2.6C exports confirm successful execution on **MATLAB/Simulink R2021a**.
[The engineering report and figures](../../docs/C26C_ENGINEERING_REPORT.md) show MAE
**0.793 K** (66.14% lower), RMSE **0.924 K** and bias **−0.451 K** against BOPTEST.
Daily MAE improves on all 14 evaluation days. The user reports 14/14 MATLAB tests
passed; no raw test log was supplied. This remains a partial benchmark, not real-world
validation. Common-release controls and solver sensitivity remain pending.


## C2.7 controlled numerical verification — prepared, execution pending

[Download the offline R2021a C2.7 package](https://github.com/AsherFerdinand/THERMA/raw/refs/heads/replay-transfer/THERMA_C27_MATLAB_R2021a_2026-11-03.zip),
extract, and run `run_verification("quick")` then `run_verification("full")` in MATLAB.
Full mode runs the preserved no-solar control at 30 s and solar at 30/15/5 s sequentially,
with hash-checked resume, lean exports, measured runtime and original event logs.
No new C2.7 MATLAB runs or convergence results are claimed. See
[the experiment/report guide](../../docs/C27_NUMERICAL_VERIFICATION_REPORT.md),
[START_HERE.md](../../START_HERE.md), and the [C3 design-only plan](../../docs/C3_HYDRONIC_ARCHITECTURE_PLAN.md).
C3 implementation remains pending actual controlled-study results.


[C2.7 R2024a event-export fix](../../docs/C27_EVENT_EXPORT_FIX.md): bounded chunk writing,
staged publication, streaming row/header/order checks and SHA-256 verification replace
the large event table writer. The network-path root cause is unconfirmed; university
verification remains pending. [Download the updated offline ZIP](https://github.com/AsherFerdinand/THERMA/raw/refs/heads/replay-transfer/THERMA_C27_EVENT_EXPORT_FIX_R2024a_2026-11-03.zip).
Thermal physics, solver settings and reference inputs remain unchanged.


[C2.7 CSV EOF/cleanup correction](../../docs/C27_EOF_CLEANUP_FIX.md): accepts confirmed
normal EOF without disabling CSV checks, and replaces shared-workspace cleanup with
an independent, idempotent file-handle owner. [Updated offline ZIP](https://github.com/AsherFerdinand/THERMA/raw/refs/heads/replay-transfer/THERMA_C27_EOF_CLEANUP_FIX_R2024a_2026-11-03.zip).
The new MATLAB regressions and university execution remain pending; thermal physics,
solver settings and reference datasets are unchanged.


[C2.7 R2024a reader revision](../../docs/C27_R2024A_READER_FIX.md) removes the incorrect
numeric EOF-code assumption. The verifier reads an exact byte snapshot, validates
read counts/positions and all CSV records, then binds scanned bytes to SHA-256.
Windows diagnostic paths are checked both in plain text and structured JSON.
[New offline ZIP](https://github.com/AsherFerdinand/THERMA/raw/refs/heads/replay-transfer/THERMA_C27_R2024A_READER_FIX_2026-11-03.zip).
The minimal MATLAB API probe/regressions remain unexecuted in cloud; university
confirmation is required. Thermal physics, solver settings and inputs are unchanged.

Latest offline revision: [C2.7 R2024a SHA-256 compatibility](../../docs/C27_SHA256_COMPATIBILITY_FIX.md). University quick verification is required before the full benchmark.

C2.8 reference-temperature comparison is prepared: [guide](../../docs/C28_REFERENCE_VALIDATION.md)
and [offline MATLAB instructions](../../START_C28.md). The supplied controlled pair has been compared against genuine BOPTEST air temperature: MAE improves by 66.14% and RMSE by 67.07% with solar. See the [engineering report](../../docs/C28_ENGINEERING_REPORT.md), including the unresolved execution-lineage qualification.

The corrected C2.8 standalone package bundles the original two C2.7 trajectories;
no external C2.7 directory is required. Follow [START_C28.md](../../START_C28.md).

C3 component verification is prepared for MATLAB R2024a: [instructions](../../START_C3.md)
and [equations, assumptions and staged gates](../../docs/C3_COMPONENTS.md). This increment
covers C3.1–C3.3 only. It does not yet implement a closed-loop C2 zone or claim
successful MATLAB execution, comfort performance or C3 reference accuracy.

C3 component evidence is now reviewed: **13/13 passed in university R2025a**.
The separate C3.4 closed-loop integration generator and standalone verification
workflow are prepared for R2024a: [instructions](../../START_C34.md),
[engineering design/evidence limits](../../docs/C34_INTEGRATION.md). Integration execution
is pending; C3.5/C3.6 remain gated. No C3.4 performance result is claimed.

C3.5 investigation is prepared on its own branch: [instructions](../../START_C35.md),
[study/metric definitions](../../docs/C35_INVESTIGATION.md), and
[actual incoming C3.4 baseline review](../../docs/C35_BASELINE_REVIEW.md). The supplied
C3.4 R2025a report confirms 17/17 tests and energy closure; new C3.5 sweeps have
not been executed in cloud. Start with the four-case UA study before all cases.
