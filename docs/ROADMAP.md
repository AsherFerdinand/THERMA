# Roadmap

## Phase 0 — Repository setup

- [x] Create an installable Python package with a modular source layout.
- [x] Configure Python 3.12, runtime dependencies and a locked development environment.
- [x] Document objectives, architecture boundaries, workflow and reference handoff.
- [x] Provide validated non-physical TOML project configuration.
- [x] Add initial tests and automated CI checks.
- [x] Run tests, lint, formatting, type checks and package build locally.

## Phase 1 — Simulink automation

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

Phase 0 is complete only after local validation. Later phases are intentionally unstarted.
