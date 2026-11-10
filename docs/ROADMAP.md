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
- [x] Import actual three MATLAB exports unchanged; validate CSV/reference provenance.
- [x] Execute first actual exploratory comparison: MAE 2.34053 K, bias -2.33520 K; limitations recorded.
- [x] Investigate pinned-FMU solar/state access: source-derived opaque solar is available;
  all 27 initialized opaque temperatures are readable and match current 293.15 K start.
- [x] Publish results-only ZIP separately and document C2.6 prerequisites/implementation gates.
- [x] C2.6A: extract actual solar observations/state snapshots; verify unchanged baseline and seven-surface conservation.
- [x] C2.6B: prepare versioned solar-resolved packet, compatible MATLAB loader/batch entry and complete energy exports.
- [x] Add independent contracts, future controlled comparison/day-wise metrics and actual-output solver sensitivity tools.
- [x] Publish checked C2.6 packet/reference subset separately from development.
- [x] C2.6C: analyze actual R2021a solar replay; user reports 14/14 MATLAB tests passed.
- [x] Compare preserved no-solar/reference trajectories: MAE 0.79253 K (66.14% lower), daily error/energy audits and figures.
- [x] C2.7 infrastructure: same-release control, 30/15/5 s refinements, hash-checked resume and event exports.
- [x] Prepare offline R2021a quick/full package, actual-only study analyzer and six PNG/PDF outputs.
- [x] Document C3 hydronic architecture options; design only, no implementation.
- [ ] Execute C2.7 university quick/full runs and analyze actual controlled/convergence/energy results.
  User reports all four runs completed; the original controlled pair is reviewed,
  while refinement/event evidence remains pending.
- [x] C2.8: recover genuine pinned air/operative reference; prepare standalone offline MATLAB comparison.
- [x] C2.8: inspect supplied controlled pair and generate reference-aligned numerical metrics/plots.
- [ ] C2.8: reproduce MATLAB FIG outputs and resolve duplicate prior solar CSV execution lineage.
- [ ] Decide remaining glazing/exterior/moist-air physics scope from measured evidence; no calibration.
- [ ] Resolve exact-reference physics and replay initialization before BOPTEST accuracy claims.
- [x] C3.1–C3.3: prepare isolated native thermostat, asymmetric valve and mixed radiator
  builders with explicitly illustrative assumptions and analytical MATLAB tests.
- [x] Review actual C3 component report/log: 13 passed, 0 failed/incomplete, university R2025a; source/config/package hashes match.
- [x] C3.4: prepare a separate native closed-loop C2-copy variant, integration tests, energy diagnostics and standalone runner.
- [x] Review actual C3.4 R2025a report: 17/17 tests and 24 h simulation passed with native energy diagnostics; full trajectory not supplied.
- [x] Prepare C3.5 one-factor UA/supply/outdoor/solar investigation, conditional controller selection, native-energy metrics and max-step comparisons.
- [ ] Execute C3.5 new cases in university MATLAB and review actual capacity/inertia/loss, controller and sensitivity evidence.
- [ ] Complete engineering conclusions from measured results; no convergence/regulation/solar-savings claim before those results.
- [ ] Satisfy full reference readiness gates before C3 BOPTEST/system-accuracy claims; no C4.

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


### C3.6 reality check

- [x] Extract existing building/radiator specifications and steady capacity.
- [x] Inspect actual C3.5 UA60/180 traces; quantify storage/loss and create two plots.
- [x] Prepare read-only MATLAB entry point reusing the existing C3.5 study.
- [ ] University execution of the new C3.6 entry point/static test (no new simulations).
- [x] C3.7 building and manufacturer emitter specification established.


### C3.7 residential scenario (native execution user-reported)

- [x] Separate20m² corner-room data and one-run integration entry point prepared.
- [x] Record user-supplied Purmo864W at55/45/20°C with URL and transcription provenance.
- [x] Match existing model UA/flow; document unresolved weight interpretation and capacitance.
- [x] Successful R2025a residential execution and checks user-reported on2026-11-08.
- [ ] Independently review the actual C3.7 trajectory/report when supplied.
- [x] C3.8 thermostat investigation authorized; implementation prepared, native comparison pending.


### C3.8 thermostat hysteresis (supplied native summary reviewed)

- [x] Two-deadband driver, compatible C3.7 reuse,2–24h metrics and two2–8h plots prepared.
- [x] Supplied R2025a comparison summary confirms both cases/checks; original trajectories not rehashed.
- [x] Narrower band reduced MAE with more switching in supplied comparison.
- [x] C3.9 existing-result reference comparison authorized and analyzed.


### C3.9 BOPTEST reference comparison

- [x] Reproduce C2.8 air MAE/RMSE and audit prescribed heating input; exactly two plots.
- [x] Retain initial-state/solar/boundary and execution-lineage limitations.
- [x] University R2025a reproduction user-reported successful (no new cloud execution).
- [ ] Resolve old execution/solver/event evidence before stronger validation claims.
- [x] C4.0 visual workbench authorized; native generation/reproduction pending.


### C4.0 integrated residential workbench

- [x] Presentation-only builder with four named physical subsystems, visible inputs/feedback and collapsed checks.
- [x] One-run C3.7 comparison driver, fixed numerical tolerances and one result figure prepared.
- [x] Native C4.0 R2025a generation/verification user-reported; no new native execution in cloud.
- [x] C3.7 reproduction user-reported successful; original C4.0 verification artifacts not supplied.
- [x] C4.1 dataset assessment explicitly authorized; no new physics.


### C4.1 residential dataset assessment

- [x] Assess Twin Houses documentation and official ResStock inputs; ThermBuild catalogue locally blocked.
- [x] Conditionally select N2 Annex71; document missing primary geometry, N2 measurements and rights.
- [x] Document source-supported openings, candidate zoning and proposed measured-data validation.
- [ ] Close data-access/geometry/licensing gates before any implementation.
- [x] C4.2 explicitly authorized; target changed to Annex58 Experiment1, without copying Annex71.


### C4.2 Annex58 integration (blocked, not complete)

- [x] Attempt official DOI, metadata and university routes; record proxy403 failures.
- [x] Prepare clearly blocked configuration, missing-input MATLAB inspection and dependency diagram.
- [ ] Obtain the official PDF/structure and extract page-cited building parameters.
- [ ] Obtain/inspect original measurements and prepare a genuine short subset/temperature plot.
- [ ] Establish verified zone adjacency and readiness for later implementation.
- [ ] FRP-2 remains unselected; primary assessment/approval required before any switch.
- [ ] C4.3 not started.

### C4.2B FLEXLAB acquisition and feasibility

- [x] Acquire/authenticate primary documentation and authentic experimental CSVs.
- [x] Map Cell3B geometry/materials/measurements; audit gaps and a continuous12h period.
- [x] Recommend CONDITIONAL separate single-zone benchmark; multi-zone/equipment validation unestablished.
- [x] Prepare measured-data-only MATLAB inspection and transfer instructions.
- [ ] Execute new inspection in MATLAB R2025a; no cloud native execution claimed.
- [ ] Resolve construction/property conflicts, initial-state conditioning and raw redistribution rights before a frozen model/data packet.
- [ ] C4.3 remains unauthorized/not started.

### Maintenance — lightweight MATLAB execution

- [x] Audit storage and milestone preservation;distinguish builders/native SLX and unbacked results.
- [x] Preserve history/engineering docs;centralize new execution instructions.
- [x] Implement explicit C42B dependency package,external-data verification and MATLAB-only runner/results ZIP.
- [x] Provide read-only PC inventory and hash/source/status verification workflow.
- [ ] University native R2025a execution/returned-ZIP acceptance;preserve original old-folder artifacts first.
- [ ] Resolve NOT YET BACKED UP artifacts and obtain explicit approval before any local deletion.
- [ ] C4.3 remains not started.
