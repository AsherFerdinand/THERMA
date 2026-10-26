# Progress

## 2026-10-26 — Phase 0 complete

Inspected the checkout: no commits, project files, roadmap or progress document existed.
Created the source package, tests, non-physical TOML configuration, documentation,
reference/data placeholders, agent guidance, Python version pin, dependency lockfile,
and GitHub Actions checks. No original model or existing user files were changed.

Prepared a Python 3.12.14 virtual environment using uv 0.12.23. Installed the editable
package, NumPy, SciPy, Pandas and development tools. Cloud setup uses
`UV_CACHE_DIR=/workspace/.cache/uv` because the default home cache is read-only.
Repeated `uv sync --frozen` succeeded without changing dependency definitions.

Validation completed locally:

- pytest: 11 passed, covering example loading, defaults, invalid types/keys, missing
  files and malformed TOML.
- Ruff lint and formatting checks passed.
- Strict mypy passed for both package source files.
- Wheel and source distribution built successfully with `uv build`.
- NumPy/SciPy/Pandas integration smoke check passed using a synthetic exponential
  decay ODE and a DataFrame. This is dependency validation, not building physics validation.

GitHub Actions is configured with the locally used uv version but has not run remotely.
No application server exists or is required for Phase 0. No physical parameters,
reference validation results, ML models or performance claims have been introduced.
At the end of the initial setup session, code remained local and uncommitted.

## Remaining issues and next task

Phase 1 is unstarted. Next obtain and inventory the original MATLAB/Simulink model,
supporting files, MATLAB release, required toolboxes, execution/license availability,
and asset usage rights. Then establish a reproducible reference baseline before batch
automation. Do not implement physics, ML or web features as part of Phase 0.

## 2026-10-26 — Phase 0 publication review

Reviewed all 19 candidate files, ignore rules and lockfile artifact metadata. No secrets
were found in the reviewed content or credential-pattern scan. Only small text files
are included; the virtual environment, caches, build outputs and dataset contents are
excluded. Re-ran frozen dependency sync, all 11 tests, Ruff lint/format, strict mypy,
and source/wheel builds successfully. The remote had no branches before publication;
the initial Phase 0 commit targets main. Push and remote verification are recorded in
the publication session report. GitHub Actions execution remains unverified.
No Phase 1 implementation or additional features were introduced.

## 2026-10-26 — Phase 1A static analysis complete; review pending

Inspected AGENTS, README, roadmap/progress, package and configuration. No existing
ARCHITECTURE.md was present. Read the thesis repository at commit
`a4b6451f74a436b8daa57633962c91202c5b39e3` in an external temporary checkout;
original files remain unchanged and are not vendored. Created SIMULINK_INVENTORY.md,
MIGRATION_PLAN.md and REFERENCE_DATA_PLAN.md; updated README and roadmap for the review gate.

Verified the SLX SHA-256, ZIP integrity, all 210 system XML files (2,925 block records),
release/solver metadata and matching standalone/embedded central control function.
Statically decoded the small workspace struct with SciPy using an in-memory MAT header;
values require MATLAB confirmation. Inspected the controller diagram and floor-comparison
image. The reference LICENSE is CC BY 4.0; attribution and source links are in the inventory.

Confirmed thermal mass/conduction/convection, pipe radiators, tank, centrifugal pump,
gate valves and central average-based control. Important unresolved differences:
33 valve selectors versus 36 rooms; saved mixed setpoints versus documented uniform
20°C; missing separate local thermostat/hysteresis implementation; source prose versus
hydraulic component settings; screenshot gain/horizon versus saved model configuration.
The central function is stateless and its empty heating subset yields NaN/all closed.
No physical equivalence, hydraulic redistribution benefit or numerical validation is claimed.

MATLAB is not on PATH: compilation, licensed product verification and all simulations
remain unrun. No raw datasets or standalone initialization/batch scripts were found.
Defined the MATLAB handoff, immutable-reference workflow, native/aligned signal export,
SI units/provenance and a proposed one-room/radiator/valve prototype. Proposed conservation
equations are explicitly distinguished from recovered library equations.

Checks: source inventory and XML parsing, ZIP CRC/hash, controller text comparison,
workspace static decode, documentation link/scope review and Git whitespace checks.
No executable files, manifests, lockfiles or dependencies changed, so no new tests were
added and the Python suite was not rerun for this documentation-only session. Phase 0
GitHub Actions verification is user-reported; not independently queried in this session.

Next: review Phase 1A. Only after review, Phase 1B should confirm the model on licensed
MATLAB R2024b, resolve scenario/control/units/index questions and establish a raw baseline
before writing automation. Do not start Phase 1B or Python physics implementation yet.
