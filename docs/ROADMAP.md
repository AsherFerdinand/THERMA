# Roadmap

## Phase 0 — Repository setup

- [x] Create an installable Python package with a modular source layout.
- [x] Configure Python 3.12, runtime dependencies and a locked development environment.
- [x] Document objectives, architecture boundaries, workflow and reference handoff.
- [x] Provide validated non-physical TOML project configuration.
- [x] Add initial tests and automated CI checks.
- [x] Run tests, lint, formatting, type checks and package build locally.

## Current reference track — BOPTEST

The user selected BOPTEST `bestest_hydronic` as the independent single-zone reference.
Keep its parameters separate from the thesis and the unvalidated EN 12831 builder.

- [x] BOPTEST-A: pin upstream/dependencies; extract physical parameters, equations,
  measurements, limitations and staged architecture into documentation and JSON.
- [x] Use the Phase A extraction to establish a pinned direct-FMI runtime.
- [x] Phase B: execute typical and peak reference periods with seven-day warm-up,
  export measurements/plots, verify quality and fresh-process repeatability.
- [x] Review pinned IDEAS layer discretisation and prepare C1 envelope builder,
  parameter loader, A–G verification scripts and static parameter audits.
- [x] User reports C1 generation and A–G verification passed on R2025a.
- [ ] Archive full C1 verification report and exact local source revision.
- [x] Prepare reduced C2 28-state dry-air model, explicit provisional assumptions,
  analytical MATLAB verification scenarios and data comparison infrastructure.
- [x] C2 generated/executed on university R2025a; corrected suite passed 10/10 scenarios.
- [x] Prepare explicit root-input hold policy, actual-input diagnostics and step regressions.
- [x] Archive actual successful C2 report unchanged; check recorded source/assumption hashes.
- [x] C2.5: implement evidence importer, integrity checks, compatibility matrix,
  explicitly partial replay preparation/runner and classified comparison reports/plots.
- [x] User reports C2.5 MATLAB suite 8/8 passed, 23.5779 s; no raw test log supplied.
- [x] Prepare hash-checked first typical replay/reference transfer ZIP; no Git needed at university.
- [x] User reports final-value policy fix allowed the first 21-day partial R2025a replay to complete.
- [x] Explicitly set final-value holding and add interval/endpoint regressions; MATLAB rerun pending.
- [x] Prepare recursive exception diagnostics and explicit replay-source binding regressions.
- [x] Implement C2.5C read-only replay analysis, publication plots and original-reference sign audit.
- [ ] Import actual evaluation.csv, comparison_metadata.json and replay_run.json from successful replay.
- [ ] Run first exploratory THERMA-versus-BOPTEST comparison and review limits before C2.6.
- [ ] C2.6: resolve absorbed forcing, initialization and prioritized reference-physics gaps.
- [ ] Resolve exact-reference physics and replay initialization before BOPTEST accuracy claims.
- [ ] Satisfy C3 readiness gates before hydronic implementation.

BOPTEST-A is static extraction; Phase B has executed the unchanged original FMU.
C1 success is user-reported; its full local report is not in the repository.
C2 is MATLAB-verified locally with its actual report archived; Codex has not executed MATLAB.
Reference validation remains pending because the reduced subset and replay inputs differ. No Python physics, ML or web work is included. The thesis diagnostic track below remains preserved and pending independently.
See [BOPTEST_REFERENCE.md](BOPTEST_REFERENCE.md),
[BOPTEST_BASELINE.md](BOPTEST_BASELINE.md) and
[BOPTEST_SIMULINK_CONTRACT.md](BOPTEST_SIMULINK_CONTRACT.md) and
[BOPTEST_SIMULINK_C1.md](BOPTEST_SIMULINK_C1.md).

## Phase 1 — Simulink automation

### Phase 1A — analysis and preparation

- [x] Inventory accessible reference files and SLX metadata at a pinned source commit.
- [x] Document source-supported physics/control findings and unresolved discrepancies.
- [x] Define migration architecture, MATLAB automation strategy and dataset contract.
- [x] Review Phase 1A before starting Phase 1B (user confirmed).

### Phase 1B — reference execution

- [x] Phase 1B.1: prepare reviewed-load MATLAB diagnostics and university execution guide.
- [ ] Execute Phase 1B.1 on university MATLAB and return diagnostic reports.
- [ ] Review diagnostics before beginning Phase 1B.2.

- [ ] Acquire and inventory the original thesis model and supporting files.
- [ ] Establish MATLAB/Simulink release, toolboxes, execution access and baseline run.
- [ ] Document signals, physical units, parameters, initial conditions and controls.
- [ ] Automate parameter overrides and batch execution while preserving originals.
- [ ] Export datasets with provenance and reproducible run metadata.

## Phase 2 — Python physics engine

- [ ] Define simplified thermal and hydraulic equations and explicit assumptions.
- [ ] Implement components and numerical integration with unit and conservation tests.
- [ ] Compare with reference runs using declared metrics and tolerances.

## Phase 3 — Modular simulation framework

- [ ] Configure buildings, rooms, radiators, pipes, boilers and controls independently.
- [ ] Validate topology, dimensions, units and scenario reproducibility.

## Phase 4 — Machine learning

- [ ] Prepare leakage-safe training, validation and test datasets.
- [ ] Train scikit-learn, XGBoost and/or PyTorch surrogate candidates as justified.
- [ ] Measure prediction errors, computational costs and operating-range limitations.

## Phase 5 — Web application

- [ ] Add FastAPI services and SQLite persistence.
- [ ] Build React and Plotly scenario configuration and interactive result views.
- [ ] Test API and browser workflows.

## Phase 6 — Intelligent control

- [ ] Implement decentralised and centralised supervisory control baselines.
- [ ] Implement and evaluate Model Predictive Control with explicit constraints.

## Phase 7 — Deployment

- [ ] Containerise required services and extend automated integration tests.
- [ ] Document public demonstration limitations and reproducibility.
- [ ] Add PostgreSQL only when the persistence requirements justify it.

Phase 0 is locally validated. Phase 1A static analysis is complete; MATLAB runtime
verification remains pending. Phase 1B.1 diagnostic implementation is prepared;
Phase 1B.2 and later implementation await university diagnostic results.
