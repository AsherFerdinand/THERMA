# 2026-10-29 technical audit

## Evidence and reusable architecture

- Python 3.12 package, frozen uv environment, pytest/Ruff/strict mypy and package-build
  CI exist. No Python thermal solver, ML, API or frontend is present.
- Phase A's frozen registry contains 217 parameter records, 63 source hashes and 11
  unresolved items; BOPTEST/IDEAS commits and the original-FMU byte hash are recorded.
  The registry is unchanged in this sprint.
- Phase B runner, hash-locked isolated FMI runtime and scenario config are reusable.
  Local ignored `baseline_index.json` identifies typical `typical_heat_day_ailcox5y`,
  peak `peak_heat_day_wfla_b__` and repeat `typical_heat_day_t8_7qbxh`.
  Evaluation/trajectory CSVs, signal registries and manifests exist locally. Baselines
  are original-FMU outputs, not THERMA validation. No baseline rerun was needed.
- C1 provides explicit model-workspace parameters and reusable editable construction
  blocks. Its loader has explicit structure-array schemas and a MATLAB regression.
  The 27 states include dynamic endpoints and an adiabatic floor back.

## C1 evidence boundary

The user reports successful C1 generation and A–G verification on MATLAB R2025a,
with report summary `status=passed`, `matlab_verified=true`. The full report,
model, source hashes, solver metrics and local compatibility edits were **not supplied**
with this sprint; no such artifacts were found in the repository. This is user-reported
local evidence, not a verification executed or independently reviewed in Codex.
The cloud still has neither MATLAB nor Octave. Archive the local report and exact
source revision before calling the published revision reproducibly MATLAB-verified.

Targeted compatibility changes accept both file and built-in `new_system` in every
existing availability guard. The C1 boundary output ports now occupy distinct vertical
positions across both input groups. This is a layout-only edit; C1 equations,
parameters, state ownership and physical connections are preserved.

## Missing physics and integration risks

- Exact moist-air sensible storage, latent/moisture/CO2 balances and initialization
  are not reproduced by multiplying default infiltration density by guessed cp.
- Source interior/exterior convection is nonlinear, interior radiation linearized,
  opaque exterior longwave nonlinear and glazing longwave linearized. Constant h
  coefficients in C2 are explicit provisional approximations.
- Window U and g are ratings, not substitutes for source dynamic glazing and optics.
  No exact irradiance-to-absorbed-gain implementation is provided this sprint.
- Complete warmed-up fabric state is unavailable from Phase B's selected signals.
  Synthetic tests do not create a BOPTEST-compatible restart or replay history.
- Gas input is not radiator-delivered heat; air temperature is not operative
  temperature. Validation contracts reject semantically incompatible comparisons.
- `.slx` generation and execution must be tested locally; static lint cannot establish
  block-library availability, API compatibility, dimensions or successful simulation.

## Sprint result and next gates

The reduced C2 implementation and MATLAB verification suite are prepared, plus data
normalization/comparison tools that execute independently of MATLAB. Reference exactness
and C2 MATLAB verification are not claimed. CI now also runs pinned static MATLAB lint.
Keep the original thesis, frozen registry, FMU and ignored local baseline evidence intact.
See [C2 equations and handoff](BOPTEST_SIMULINK_C2.md),
[data comparison contracts](REFERENCE_COMPARISON.md) and [C3 gates](C3_READINESS.md).
