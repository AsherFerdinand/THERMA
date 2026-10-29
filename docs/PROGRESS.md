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

## 2026-10-26 — Phase 1B.1 diagnostic workflow prepared

User confirmed Phase 1A review. Added `scripts/matlab/diagnose_reference.m` and
`docs/MATLAB_DIAGNOSTICS.md`. Default mode verifies the pinned source SHA-256 and copy,
extracts archive evidence without loading, inventories callback/code fields and traces
saved room/Mux/valve mappings. A matching explicit ReviewedHash is required before
load/expression resolution; Compile=true separately authorises compile/terminate only.
No simulation, model edits, original saves or scenario reconstruction are performed.

Loaded diagnostics are designed to record installed products/licence availability,
solver/duration, known scientific workspace values, effective dialog parameters/units,
connectivity, library link status, embedded controllers, thermostat candidates and optional
compiled port metadata. Errors and load/compile console warnings are retained with partial
report checkpoints. Model close-without-save, temporary-copy cleanup and final source
hash checking protect the original; no success is claimed until a report verifies it.

Outputs and extracted archives go to ignored `outputs/matlab/<unique-run>/`. Added ignore
rules for outputs, Simulink caches and MATLAB autosaves. University users must review
reports for paths/licence diagnostics before sharing private attachments; no generated
reports, reference binaries, datasets or machine licence details are committed.

Additional source-backed static finding: following the saved floor and root Mux/tag/
Memory wiring maps 1/13/25 to EG/Raum1, OG1/Raum1 and OG2/Raum1. Their saved room
subtrees contain neither gate valves nor radiator pipes; author intent and runtime
activation remain unconfirmed. The function exports these associations and unresolved
cases rather than creating missing actuators or local control logic.

Checks completed:

- MISS_HIT 0.9.44 MATLAB syntax/lint: one file analysed, no findings. Tool ran in an
  isolated temporary uv tool environment; project dependencies/lockfile are unchanged.
- Static review of review-before-load gate, temporary-copy load target, original-file
  read-only operations, close-without-save, cleanup and final hash handling.
- Actual pinned SLX hash/ZIP integrity, room-vector wiring and 33-valve/selector structure
  inspected independently through XML; original hash remained unchanged.
- Output root derivation, Git ignore rules, documentation links and Git whitespace checks.
- Existing Python checks: 11 tests passed; Ruff lint/format and strict mypy passed.

MATLAB execution, MathWorks checkcode, loading, licensing, compilation and physical-unit
resolution remain unrun in cloud. Third-party syntax lint is not a Simulink validation.
Next: execute the guide's archive review on university MATLAB R2024b, then reviewed load
and optional compile if safe; return sanitised JSON reports. Do not begin Phase 1B.2
until these diagnostic results are available. No Python physics, ML or web work started.

## 2026-10-26 — Separate one-room reference builder requested

User explicitly requested a MATLAB script to create a new room/heating Simulink model,
then selected an EN 12831 heating-load basis. Added build_room_heating_model.m,
room_heating_parameters.m and docs/ROOM_REFERENCE_MODEL.md. This standalone benchmark
is separate from the original thesis diagnostic/scenario workflow; no Phase 1B.2
baseline/export work or Python physics implementation was started.

The builder creates editable Room and Radiator energy-balance subsystems, an ideal
prescribed-flow valve, a hysteresis thermostat and a timeseries logger. Source/supply
and outdoor boundaries are constant. It consumes externally checked EN 12831 design
transmission/ventilation losses and temperatures, reducing them to one equivalent
outdoor conductance. This reduction is exact only at the supplied design point; it is
not a standards implementation or evidence of regulatory compliance. National rules,
standard edition and calculation provenance are required inputs. Radiator hydraulics,
pump/boiler dynamics and nonlinear radiator ratings are deliberately not modelled.

No physical parameter values are invented: the template uses NaN/empty required fields.
Numerical settings are labelled starting choices requiring convergence checks. The
builder validates inputs, embeds them in a new Model Workspace, refuses to overwrite
an already open model and saves only to a unique ignored outputs/room_reference run.
It never opens or changes the thesis model and does not simulate automatically.

Checks: MISS_HIT 0.9.44 parsed/linted both new MATLAB files without findings; independent
static checks verified block endpoint names, unique wired inputs, parameter-template
coverage, output path/ignore rules and Git whitespace. MATLAB build/compile/simulation
and standard calculations remain unrun. Existing Python code/dependencies are unchanged.
Changes remain local; no commit or push performed for this separate request.

Next: supply the country/applicable national rules, checked EN 12831 room calculation
and documented radiator/thermal inputs, then build and validate on university MATLAB.
Original thesis diagnostics are still needed before Phase 1B.2. Do not claim a working
MATLAB execution, validated physics or standards compliance from cloud static checks.

## 2026-10-28 — Resume and first-room data preparation

Reviewed repository status, AGENTS, roadmap and recent progress. Phase 0, Phase 1A and
Phase 1B.1 diagnostic preparation remain complete; university MATLAB execution/results
are still pending. The separate one-room builder, parameter template and guide remain
local/uncommitted, along with their progress entry.

Recorded the user's clarification: Germany, with no existing EN 12831 room heat-load
calculation. Added ROOM_DATA_CHECKLIST.md to gather a single room's geometry, boundaries,
ventilation, equipment and source information without inventing parameters. The exact
standard/national-rule basis and checked design calculation are still required; dynamic
capacities and radiator conductance need separate evidence.

Checks: documentation link and Git whitespace review. No executable changes were made
in this session; no tests rerun and no commit/push performed. Next: choose one thesis
room and supply its city, dimensions and available construction/radiator records.
The original diagnostic-results gate remains in place; no Phase 1B.2 or Python solver
work started.

## 2026-10-28 — BOPTEST-A reference extraction complete

User selected the independent BOPTEST bestest_hydronic reference and explicitly scoped
this session to source extraction/documentation only. Preserved the original thesis
track and pre-existing uncommitted one-room builder/worksheet files. No Simulink model
or Python physics was built, and no DIN compliance or numerical validation is claimed.

Pinned BOPTEST a29024f8c453517ccbd1186006a3fa6af8de1ae2 and followed the testcase's
library_versions.json to IDEAS f1fdd8b22d39dc50297c47b6433e44381e40d0ff rather than
assuming the package's 2.2.1 annotation selects the build. Inspected canonical MSL 3.2.3
at 2da48301b8c3071158aa5ada8693767e6717ca47 for water/LimPID inheritance; the exact
compiler-bundled MSL patch revision remains unrecorded. Temporary upstream checkouts
were inspected without source edits, outside THERMA.

Created docs/BOPTEST_REFERENCE.md and configs/references/boptest_bestest_hydronic.json:
217 sourced parameter entries, 63 source-file hashes, equation/dependency locations,
resource/FMU-member hashes and 11 explicit unresolved items. Every verified entry has
units, explicit/derived status and source lines or a precise FMU XML XPath. Null unknowns
are separate from verified values. Updated README and roadmap for this reference track.

Findings include 48 m² / 129.6 m³ geometry, heavy wall/floor and light roof layers,
12 m² south glazing with full optical tables, material R/G/C derivations, nominal
0.5 ACH infiltration, moist-air/occupant gains, five-element nonlinear 5 kW radiator,
constant-property water and 0.059751434 kg/s nominal flow, 100 kPa pressure pump,
limited ideal heater, operative-temperature PI control and pump hysteresis.
Documented discrepancies/limits: no separate executable valve despite prose; adiabatic
floor outer boundary; occupancy expression differs from comment; nominal 70/50°C is
not operating water temperature; reaQHea_y measures gas input, not radiator heat.
Active weather is Brussels, not the Uccle resource-inclusion string or German design
weather. Source-tree and embedded forecast CSV byte hashes differ; static numeric
comparison found rounding-scale differences, so dataset identity must be recorded.

Inspected stored wrapped.fmu only as ZIP/XML, never loading its binaries. Source and
FMU constants corroborate nominal flow and control bounds; that is metadata checking,
not numerical simulation. Resource forecasts/gains are not validation trajectories.
Prepared staged weather/envelope/zone-air/hydronic/control block architecture and
baseline/peak/typical comparison plan with explicit public versus internal signals.

Checks: strict JSON parse, unique parameter IDs and dependency references, status/unit
coverage, pinned local source hashes and exact line anchors/XML XPaths, material
resistance/capacity arithmetic and nominal-flow metadata agreement, resource ZIP CRC,
local Markdown links and Git whitespace. Existing suite: 11 tests passed; Ruff lint,
format and strict mypy passed. No new tests/dependencies were added for extraction.
Modelica/FMU/MATLAB execution and quantitative comparison remain unrun.

Next: review the extraction and establish a pinned BOPTEST baseline/environment, then
agree envelope discretization and boundary/measurement replay before any Simulink build.
Calibrated radiator UAEle, moist-air initialization and full consistent initial states,
operating temperatures and runtime solver options still require runtime resolution.
All changes from this session remain local; no commit/push was requested or performed.

## 2026-10-28 — Phase B numerical reference baseline complete

Read the Phase B request, reference documentation/JSON, roadmap, progress and existing
code/tests. Preserved all earlier uncommitted work. The Phase A reference JSON was not
modified (SHA-256 f91141d78668908525d484a4900dc69af1a163c4c5e07f5a5fbd0c43eae4451c).
No thesis edits, new Simulink model, Python thermal solver, ML or web work was introduced.

Verified original wrapped.fmu SHA-256
365b3085d97cc4620c06b6036156126a056d7f160fcc4f181d6b2fac4b05743b,
FMI 2.0 Co-Simulation mode, Linux x86-64 binary, embedded resources/CRC and no external
execution-tool requirement. Its legacy libgfortran.so.4 dependency was initially absent.
Resolved it using the genuine Ubuntu package through signed APT metadata/package
verification in a pinned disposable Ubuntu 18.04 container; no ABI-5 symlink, binary
patch, FMU rebuild or system package modification. Native bytes/hash provenance is kept.

Added scripts/boptest/run_reference.py, prepare_native_runtime.sh and isolated hash-locked
requirements.in/requirements.txt, configs/references/boptest_scenarios.json, baseline and
Simulink contract docs, plus data/provenance contract tests. Runtime: Python 3.12.14,
FMPy 0.3.20, NumPy 1.26.4, Matplotlib 3.10.8; original JModelica embedded solver settings
queried unchanged (_cs_solver=0, _cs_rel_tol=1e-6). No tolerance/control/physical/weather
setter was applied. The runtime is separate from THERMA's development environment.

Actual final successful runs (all under ignored outputs/boptest/runs):
- typical_heat_day_ailcox5y: initialize/warm up day 327 to 334; evaluate 334 to 348.
- peak_heat_day_wfla_b__: initialize/warm up day 304 to 311; evaluate 311 to 325.
- typical_heat_day_t8_7qbxh: fresh-process repeat of the final typical run.

Each full run has 60481 samples, evaluation has 40321 samples at 30 s communication/
measurement spacing (not an integration-step or weather-grid assertion). Exported all
39 public input/output variables plus 21 verified internal variables and time. All
activation inputs stayed false; Brussels.mos remained active. Original FMU rehash passed.
All columns/rows matched exactly numerically on the typical repeat, max absolute
differences zero. This is same-host repeatability, not model validation or convergence.

Measured evaluation gas input: typical 583.464515 kWh, peak 428.051986 kWh; pump electricity
4.115407 kWh in each. These are trapezoidal integrals of sampled power, not delivered
radiator heat or experimentally validated energy use. Peak-day labeling does not require
higher fourteen-day energy. Generated all five requested PNGs for each final scenario,
full/evaluation CSVs, signal registries, resource/native-library hashes and manifests.
Runtime reads resolved UAEle=11.325832677562174, infiltration density=1.2 kg/m3 and
mass flow=0.0216 kg/s; original extraction JSON remains frozen, findings are in manifests.

A first adapter attempt failed before stepping because FMI strings were bytes; corrected
and retained its failed manifest separately. Earlier smoke/development runs are not the
final baseline. Final runs use the current runner hash and have checked artifact hashes.

Quality checks passed: timestamp monotonicity/uniqueness/grid/coverage and exact warm-up/
evaluation boundaries, finite data, required units, nonnegative gas/pump power, valid
absolute temperatures/CO2 and baseline activation/stage contracts. 34 automated tests
(23 new reference/data tests plus 11 existing tests) passed; Ruff lint/format and strict
mypy passed. Shell syntax and actual native-library bootstrap execution passed. Exact
FMU download and hash-required runtime installation were also reproduced.

Phase B is complete for the original direct-FMI numerical reference; no official REST
service/KPI engine, new Modelica build, MATLAB comparison or THERMA validation is claimed.
Complete fabric state vectors, hidden absolute tolerances and exact old compiler MSL
patch identity remain unresolved. Next: review baseline/contract and design a layered
envelope with recorded weather, gains and separate radiator heat-flow replay before
adding the hydronic circuit. No commit or push performed, as explicitly instructed.


## 2026-10-28 — Phase C1 envelope implementation prepared; MATLAB pending

Prepared four MATLAB functions under scripts/matlab/boptest: frozen-registry loader,
editable construction helper, main model builder and A–G verification runner.
Inspected the pinned IDEAS MultiLayer, MonoLayerDynamic and Material implementations.
The heat-flow-driven main model retains endpoint capacities, merges shared interface
temperatures with summed distinct material capacities, and has wall counts 5/5/5/5,
roof 4 and floor 3: 27 scalar states. Floor back power is zero without removing its
storage or internal conduction. No surface films or new material assumptions added.

Builder stores explicit parameters in Model Workspace and saves unique ignored
outputs/boptest/simulink_c1 directories, refusing already loaded model names and
avoiding overwrites. Verification covers resistance/capacity, uniform temperature,
steady conduction, analytical modal transient response and solver refinement, power
and integral energy balance, per-face routing and insulated-floor redistribution.
Separate constant-Dirichlet fixtures report boundary-step energy impulses; raw and
analytical quadrature errors are distinguished. Numerical budgets are documented
heuristics, not building-accuracy or standards claims.

Added an independent static Python parameter/discretisation audit and 12 tests;
46 total tests pass. MATLAB MISS_HIT 0.9.44 lint passes all four files. Ruff lint,
format checks, strict package mypy and git diff whitespace checks pass. Static audit
confirms 27 states and material/geometry consistency. The frozen Phase A JSON hash
remains f91141d78668908525d484a4900dc69af1a163c4c5e07f5a5fbd0c43eae4451c.
Existing /outputs/ ignore rules cover every generated result; no new dependencies.
Added docs/BOPTEST_SIMULINK_C1.md and updated README/roadmap.

Neither MATLAB nor Octave is installed. No .slx was generated, opened or compiled;
no MATLAB tests or new BOPTEST comparisons were executed. Implementation scripts
are ready for university execution, but builder/runtime acceptance is pending.
No original thesis/FMU or Phase A registry changes; no C2, hydronics, Python physics,
ML or frontend implementation. No commit or push. Next: execute the documented
university MATLAB verifier, return actual reports and resolve failures before C2.


## 2026-10-28 — University transfer publication

User authorized committing and pushing the current work branch, including the
previously uncommitted reference/baseline prerequisites and C1 implementation.
Confirmed all four C1 MATLAB functions, guide and static parameter tests are present.
Repeated Python checks: 46 pytest tests passed; Ruff lint/format and package mypy
passed. No physics or frozen reference data changes were made for publication;
registry SHA-256 remains f91141d78668908525d484a4900dc69af1a163c4c5e07f5a5fbd0c43eae4451c.
Generated outputs, environments and caches remain ignored. MATLAB generation and
verification remain pending. Publication outcome is reported separately after the
Git push attempt.

## 2026-10-28 — C1 layer-structure loading fix for review

University MATLAB execution was attempted and failed in the parameter loader before
model generation: subscripted assignment between dissimilar structures. The layers
field was initialized with fieldless struct([]), whereas each assigned material
record has nine fields: material, d_m, k_W_mK, rho_kg_m3, cp_J_kgK, n_source,
R_K_W, C_J_K and local_C_J_K. Replaced that destination with an explicit nine-field
layer template preallocated to nLayers. The indexed assignment retains the same
values, expressions and exterior-to-interior loop ordering. Also replaced the
similar fieldless P.components initialization with direct first-component assignment;
subsequent components retain the same complete schema. No other indexed struct
constructor assignments/fieldless initializations were found in the MATLAB scripts.

Added a Python static regression guard comparing template and assigned field names
and enforcing preallocation, plus tests/matlab/test_boptest_envelope_loader.m for
actual MATLAB loader execution, checking every layer schema, ordered properties,
registry source provenance, R/C calculations and state counts. Run in MATLAB from
repository root:
results = runtests('tests/matlab/test_boptest_envelope_loader.m'); assertSuccess(results);
Then rerun verify_boptest_envelope_c1 after adding scripts/matlab/boptest to the path.

Checks executed here: all 47 Python tests pass; Ruff lint/format, strict package
mypy, independent static parameter audit (27 nodes), git diff whitespace checks,
and MISS_HIT lint of all eight MATLAB files pass. Frozen registry SHA-256 remains
f91141d78668908525d484a4900dc69af1a163c4c5e07f5a5fbd0c43eae4451c; no physical
parameters/equations or reference bytes changed. MATLAB/Octave remain unavailable
in the cloud; MATLAB regression and subsequent model generation remain unverified.
No C2 work, commit or push. Fix awaits review and university rerun.

User subsequently authorized publication of this fix to the work branch.
MATLAB regression and university verification remain pending.

## 2026-10-29 — Extended sprint: C1 compatibility and reduced C2 handoff

User now reports full C1 verification passed on university MATLAB R2025a, including
A–G, with status=passed and matlab_verified=true. Full local report, generated model,
source hashes and local compatibility edits were not supplied. Recorded this as
user-reported evidence, separate from cloud execution or archived/reviewed artifacts.
No MATLAB or Octave is available in Codex. Did not fabricate or overwrite C1 results.

Audit: reused existing uv/pytest/Ruff/mypy/CI, frozen registry, Phase B manifests and
runner, and C1 construction helper. Fixed every existing file-only new_system guard
to also accept built-ins (R2025a issue), with a targeted Python regression. Moved C1
boundary-output positions to distinct rows; no C1 topology, material values, equations
or state ownership changed. Existing structure-array regression remains protected.

Prepared THERMA_BOPTEST_ThermalZone_C2 builder: 27 unchanged fabric states + one air
state, interior/exterior convection, reciprocal linear opaque-surface radiation,
static aggregate window UA, sensible infiltration, explicit split convective/radiative
heating/internal gains and six absorbed-solar inputs. Floor back remains adiabatic.
This is a clearly labelled reduced dry-air subset, NOT exact BOPTEST. All provisional
rho/cp/h choices are in a mandatory explicit versioned assumptions file with status,
units and rationale; no missing reference field gets a silent default. Provenance
matrix, equations, states, sign conventions and missing moist-air/glazing/solar/
nonlinear surface/sky radiation physics are documented in BOPTEST_SIMULINK_C2.md.

Added 10 independent MATLAB scenarios and an analytical nodal matrix-exponential
verification oracle for all 28 states. Checks cover uniform equilibrium, warm/cold
infiltration, surface convection, heating/cooling, gain accounting, radiation
cancellation, stored energy, instantaneous/integral balance and two solver settings.
Raw quadrature bias is separated from corrected energy residual; heuristic numerical
budgets and refinement checks are explicit. MATLAB-only parameter/network regression
checks stability, state count, per-W conservation and no direct radiant gains to air.
Unique ignored outputs preserve partial JSON, completed CSVs and plots. Reports
record MATLAB/Simulink/model versions, assumptions and source/registry hashes.
These MATLAB scripts have NOT generated, compiled or executed C2 in Codex.

Implemented Python Series contracts and metrics in therma.comparison; CSV normalization
and generic comparison CLIs. Reject invalid samples, duplicate times/columns,
missing coverage/metadata, incompatible units, scenarios, revisions and physical
quantities. Explicit linear/previous alignment preserves known switching timestamps;
power and cumulative-energy metrics remain distinct, with null relative error for
zero reference energy. Reports identify missing quantities and do not apply invented
accuracy criteria. No Python thermal integrator or engine was implemented.

Executed normalization against hash-checked existing typical_heat_day_ailcox5y and
its original-FMU repeat typical_heat_day_t8_7qbxh: all 10 selected signals available,
zero maximum absolute difference for each. This is original-FMU processing and
repeatability evidence only, NOT C2 validation. No new FMU simulation was run.
Generated data stays ignored under outputs/boptest/normalized/.

Checks: 72 Python tests pass; Ruff lint/format and strict mypy pass; MISS_HIT 0.9.44
passes 16 MATLAB files; wheel/sdist build and git diff whitespace checks pass.
New documentation links resolve. CI adds pinned MATLAB static lint, explicitly not
MATLAB execution. Frozen registry hash remains f91141d78668908525d484a4900dc69af1a163c4c5e07f5a5fbd0c43eae4451c;
original FMU remains 365b3085d97cc4620c06b6036156126a056d7f160fcc4f181d6b2fac4b05743b.

Added sprint audit, C2 handoff, reference-comparison guide and C3 interface/gates;
updated README, C1 evidence status and roadmap. No hydronic equipment, 36-room model,
ML or web work. No commit or push for this sprint. Prepared a source-only working
snapshot ZIP under ignored outputs/boptest/handoff for university transfer, excluding
environments, caches, datasets, generated models and Git credentials/history.

Next: archive the complete local C1 report/source identity; run tests/matlab and the
new C2 verification suite on R2025a, return the actual reports, resolve runtime/API/
numerical failures, then review reference-physics gaps before replay or C3.


## 2026-10-29 — C2 sprint publication

User authorized committing all relevant sprint source, configuration, tests and
documentation to the current work branch. Existing ignore rules exclude outputs,
handoff ZIP, simulation data, environments, caches, build artifacts and MATLAB
backups; no generated artifacts or files over 1 MB are among commit candidates.
Repeated checks: 72 Python tests, Ruff lint/format, strict mypy, static MATLAB lint
(16 files), and whitespace checks pass. Frozen registry hash remains unchanged.
C2 MATLAB verification remains pending. Publication uses a normal branch push,
without force-pushing or merging main; final remote result is reported in chat.

## 2026-10-29 — C2 step-input debugging correction

User reports C2 generated/executed on R2025a: equilibrium, cold outdoors, constant
heating, warm ventilation and surface perturbation passed, while all five step
scenarios failed. Full local traces/report were not supplied. Traced heating step
through scenario times, root Inport, selector mapping, B inputs and the analytical
propagator. The latter already split intervals correctly; no constant-final-input
or port-order defect was found. Root Inputs previously left Interpolate unspecified,
while the verifier assumed holds. A root linear ramp predicts discrepancies at
3599 s of 999.722 W heating, 299.917 W internal, 209.942 W solar and 217.236 W
infiltration for the outdoor change, matching the reported error scale. This is a
strong code/equation-supported diagnosis, not a replay of unavailable local logs.

Explicitly set root Interpolate=off and assert it in verification. Log all 11 actual
root input channels; use them for accounting, independently enforce equivalence to
the prescribed hold schedule, and preserve raw input CSVs including duplicate event
timestamps. Added helper functions for explicit left/right hold limits, exact hold
integrals, piecewise linear-system reference propagation and per-event diagnostics.
The reference never follows a potentially wrong logged waveform. State continuity
is preserved at initial/final/non-grid events. Exact event logs may contain a whole
left/right limit vector; intermediate ramps or mixed channel limits still fail.
Non-event samples remain strictly checked; no finite event interval is excluded.

Energy checking now quadratures the continuous state-dependent power separately
from the exact integral of piecewise-constant direct-input power. Existing raw
residual fields remain, with new piecewise/quadrature fields and before/after input
and temperature diagnostics. Additional output times request event logging. No
physical parameters, C1 scripts, A/B nodal equations, solver tolerances, conservation
budgets or convergence requirements were changed or disabled.

Added MATLAB regressions for all scenario hold values/areas, initial/final steps,
non-grid transitions, duplicate event/output times, both limits, state continuity,
ramp/mixed-limit rejection and generated Inport/selector configuration. Python
static/input regressions guard interpolation, raw logging, all channel mappings,
actual-versus-prescribed checking and all five ramp/step discrepancy patterns.

Executed: 79 Python tests pass; Ruff lint/format, strict mypy, MISS_HIT 0.9.44 across
21 MATLAB files and git whitespace checks pass. Frozen registry SHA-256 remains
f91141d78668908525d484a4900dc69af1a163c4c5e07f5a5fbd0c43eae4451c. MATLAB/Octave are
not installed here: new MATLAB regressions and all ten corrected scenarios require
university execution. Do NOT treat reported failures as confirmed resolved yet.
Documented diagnosis and exact commands in docs/C2_STEP_DEBUGGING.md; updated C2
handoff and roadmap. User authorized normal commit/push to work after checks, without
force-push or main merge. Next: rebuild from updated scripts, run tests/matlab and
verify_boptest_zone_c2, return JSON and raw input/trajectory CSVs if any failure persists.

## 2026-10-29 — C2.5 actual evidence archive and reference readiness

During this sprint the user uploaded the original successful R2025a C2 report.
Archived its exact 75,326 bytes at verification/c2/matlab-r2025a/b00092e4236789a4/verification.json.
Report SHA-256 is b00092e4236789a4fca959fc0a18d779b038d4b686064d8d876a402e22c8babe.
Validated overall passed/matlab_verified=true, all ten unique scenarios, coarse and
refined solver metrics, convergence, and reported numerical budgets. All 15 recorded
MATLAB source hashes, registry and assumptions hashes match current recorded files
and explicit compatible commit 071269ef6c1d558785b58b6e82ade540c2fc6d39. Separate metadata
preserves import time, unknown execution date, source hashes and the limitation that
the report does not record the actual Git checkout. No report bytes were altered.
User separately reports 7/7 MATLAB unit tests passed at TH Ingolstadt in ~10.21 s;
that unit-test log was not uploaded and is not represented as an archived artifact.
C1's original full report remains awaiting import. No MATLAB execution occurred here.

Implemented therma.validation.archive: strict JSON/report/schema/status/scenario/
numerical metric/source validation, byte-preserving import, duplicate/overwrite
refusal, optional source-root and explicit Git commit verification, and archive checks.
Tests mutate temporary copies to detect missing/failed scenarios, false status,
incorrect hashes, modified report/provenance and unsupported schemas. CI checks
integrity with full Git history, explicitly not MATLAB re-execution. Added ignored
local evidence inbox and disabled raw report line-ending conversion in Git attributes.

Added 14-row machine/human signal compatibility matrix and actual typical/peak
reference inventory from existing hash-checked original-FMU artifacts. Air is distinct
from operative/radiative temperature, opaque area mean is only a proxy, fuel and pump
power are not room-delivered heat, and full fabric/solar storage inputs are missing.

Implemented hash-checked reference replay preparation with explicit --partial opt-in,
unit/sign conversion, preserved full warm-up and absolute-time provenance, per-channel
linear/hold policies, recorded omissions and a clearly provisional uniform declared
start. Full replay refuses absent absorbed solar and full initialized state. Real
typical/peak partial packets were prepared under ignored outputs/boptest/replay_inputs.
New MATLAB loader/runner generate mixed-policy From Workspace drivers around unchanged
C2 equations, validate packet integrity/ordering, request exact evaluation boundaries
and export trajectory/evaluation CSV plus model/solver/provenance diagnostics. Partial
execution is never labelled validation. New MATLAB packet tests are prepared but have
NOT executed here. Existing verified C1/C2 source, equations and assumptions are intact.

Extended comparison CLI with classified JSON/Markdown reports, explicit exploratory
pairing of different scenario IDs, missing-input/assumption metadata and optional
Matplotlib diagnostics. Added derived delivered heating total to normalization;
commodity boundaries remain strict. Actually normalized original typical/repeat runs,
compared 11 signals with zero difference and generated 11 diagnostic plots. This is
reference processing/repeatability only; no C2-versus-FMU metrics were fabricated.
Optional plotting cache paths are kept in generated output directories.

Added evidence/replay/compatibility and qualitative physics-gap guides, updated README
and roadmap to distinguish archived local verification from reference validation.
Prioritize C2.6 missing absorbed forcing/full initialization, glazing/solar/exterior
exchange and radiative feedback before C3. No hydronics, ML, frontend or 36-room work.

Checks: 113 Python tests pass; Ruff lint/format, strict mypy, one archived-report
integrity check, 14 signal mappings, MISS_HIT 0.9.44 across 24 MATLAB files, package
wheel/sdist build and whitespace checks pass. Evidence/docs links resolve. Registry
and original FMU hashes are unchanged. User authorized normal commit/push of sprint
and actual evidence to work; no force-push or main merge. New replay execution remains
pending on university MATLAB; the imported report verifies the existing C2 suite only.


## 2026-10-29 — User-reported C2.5 tests and first replay transfer

User reports latest work-branch MATLAB R2025a suite: 8 passed, 0 failed, 0 incomplete,
23.5779 s. New test_boptest_replay passed alongside C1/C2 tests. No raw unit-test log
was supplied, no test-log archive was created, and no MATLAB execution was performed
in Codex. Existing original ten-scenario C2 report remains unchanged. This result
covers the replay packet test, not execution of the full reference replay.

Prepared the first typical-heating partial packet from the existing original-FMU
run typical_heat_day_ailcox5y, rechecking trajectory/signals/evaluation artifact hashes.
Generated inputs.csv/replay.json and normalized reference CSV/metadata under ignored
outputs/boptest, plus original manifest/signals provenance and a per-file SHA manifest.
Bundled eight files into outputs/boptest/handoff/THERMA_first_typical_replay.zip
(4,676,884 bytes). ZIP integrity and every included data-file hash were checked.
ZIP SHA-256: b8a9e791b26554781360a07454db63c38bc0ff9410a60bb4a90561d675c5787d.
No source datasets, FMU or runtime binaries are needed on the university PC. Git and
Python there are unnecessary: extract the bundle into the existing repository root
and run MATLAB. Full reference regeneration remains a Linux x86-64 fallback.

Added docs/FIRST_PARTIAL_COMPARISON.md with exact extraction/integrity/run commands,
return-file list, local comparison command and reproduction route. Updated roadmap
priority to the first partial comparison before C2.6. The packet retains all seven
warm-up plus fourteen evaluation days (60,481 samples), explicit interpolation,
omitted-solar and provisional initial-state limitations. No replay execution or
C2-versus-BOPTEST numerical comparison is claimed. Next: university run, return
actual evaluation.csv/comparison_metadata.json/replay_run.json, then compare here.
No physical implementation, assumptions or frozen reference changes.


## 2026-10-29 — Isolated replay transfer publication and documentation commit

Workspace/sandbox links were not downloadable in the user's client. User explicitly
authorized hosting the original ZIP on a separate replay-transfer branch and then
committing pending documentation separately to work. Created an independent root
commit d87531d91c6989fbf63c5522c65fa3f5a22d43a7 containing only the unchanged ZIP,
SHA256SUMS and transfer instructions, without checking out or merging that branch.
Pushed normally. A fresh isolated bare Git fetch downloaded the remote ZIP and
confirmed all 4,676,884 bytes match SHA-256
b8a9e791b26554781360a07454db63c38bc0ff9410a60bb4a90561d675c5787d.
Work/main were unchanged by transfer creation; the following work commit contains
only the four pending documentation files, not the ZIP or generated data. Updated
the first-comparison guide with the direct GitHub download link. No force-push or
merge into either development branch. The user-reported 8/8 MATLAB result remains
explicitly separate from supplied archived evidence and Codex execution.


## 2026-10-29 — Real replay failure: full diagnostics and driver regression

User reports two R2025a real replay failures after successful 60481-by-12 packet
loading and C2 generation. Earlier eight MATLAB tests passed, but they did not
compile/simulate the new long-replay source configuration. Only an aggregate
MATLAB:MException:MultipleErrors message survived in replay_run.json. Static review
confirmed the catch discarded stacks/causes and the final status assertion masked
context. The underlying source/compile/simulation cause remains unconfirmed without
its nested exceptions; input-source evaluation is the leading replay-specific area
to isolate, not a demonstrated thermal physics defect. Numeric time/value matrices
are supported Simulink data; their previous use alone does not establish a bug.

Implemented recursive exception serialization with identifier/message/stack and all
causes plus extended reports. Runner saves failed JSON before printing or throwing,
prints the complete cause tree, and adds the original MException as the final wrapper's
cause. Reports distinguish configure/compile/simulate/export stages and whether sim
returned, so export failures are not mislabeled as simulations that never completed.

Extracted driver setup into configure_boptest_replay_sources: named scalar timeseries,
explicit linear/zoh methods and From Workspace interpolation, Model Workspace plus
SimulationInput bindings, continuous sample time and enabled zero-crossing detection.
Recorded per-driver class/dimensions/coverage/value endpoints/workspace/settings.
Relative start time is explicitly zero; solver/tolerances and packet duration remain
unchanged. No verified C1/C2 thermal code, assumptions or reference data changed.

Added real MATLAB MException tree/JSON/printing regressions and a two-second,
eleven-source compile/sim fixture checking linear outdoor and held gain values.
An intentionally invalid source verifies the original variable/block diagnostic is
retained. Python static regressions guard recursion, preservation/print/throw order,
original addCause chain, staged reports and explicit source binding. New tests are
prepared for R2025a; MATLAB/Octave remain unavailable here, so no driver execution or
resolution of the user's replay failure is claimed.

Checks executed: 116 Python tests pass, Ruff lint/format and strict mypy pass, archive
integrity and 14 signal mappings pass, MISS_HIT 0.9.44 passes all 28 MATLAB files,
package wheel/sdist builds pass and whitespace checks pass. Registry hash remains
f91141d78668908525d484a4900dc69af1a163c4c5e07f5a5fbd0c43eae4451c; assumptions hash remains
de81bc5fe282ff6f91c95a167d4db797cce66f0deeb4806bc6a0db3cfc1ffc61. Existing successful
verification report and original transfer ZIP remain untouched. Added exact targeted
and full-rerun instructions in docs/C25_REPLAY_DIAGNOSTICS.md and linked the first
comparison guide. C2.6 stays blocked until the real replay works. User authorized
normal commit/push to work; no force-push or merge into main/transfer branches.


## 2026-10-29 — Confirmed R2025a From Workspace final-value policy fix

User executed diagnostic tests on dac0c7e: 2 passed, 1 failed/incomplete, 18.6242 s.
The actual nested error repeats for Replay_Source_02 through _11: unable to extrapolate
beyond final workspace data because interpolation is not enabled; linear source 01
did not have this error. This confirms an incompatible default after-final policy,
not a thermal equation, matrix data format or workspace-resolution defect. Compilation
requires a legal policy even though the normal simulation ends at the final datum.
No raw test log was supplied or fabricated, and no MATLAB execution occurred here.

Set OutputAfterFinalValue='Holding final value' explicitly on all eleven sources.
In-range outdoor interpolation stays linear; heating/internal/solar remain block
Interpolate=off and timeseries zoh. Record the policy in driver diagnostics. Added
strict positive finite duration and actual model/packet/data interval coverage checks;
the runner sets its requested start/stop before configuring drivers. Holding after
final data is a defensive block setting, not permission to silently extend a replay
whose input coverage is incomplete. Existing nested exception diagnostics unchanged.

Extended MATLAB driver regression to check all settings, values between samples,
right-limit values at the final sample and deliberate driver-only post-final holding
for all eleven channels (nonzero terminal outdoor slope ensures extrapolation fails
the test). Added missing/truncated/nonfinite/mismatched interval cases. The test-only
post-final run intentionally changes the model stop after covered setup; production
requests remain strictly bounded. Targeted MATLAB suite now has five test functions;
none were executed in Codex. Reuse existing data ZIP; no dataset updates are needed.

Checks executed: 118 Python tests pass; Ruff lint/format, strict mypy, archived evidence
integrity, 14 signal mappings, MISS_HIT across 28 MATLAB files, package wheel/sdist
builds and whitespace checks pass. Verified C1/C2 equations, assumptions, frozen
registry, original reference data, archived report and transfer branch are unchanged.
Updated diagnosis/roadmap. Fix awaits university R2025a regression/full replay rerun;
no claim of MATLAB verification or replay success. User authorized normal commit/push
to work, without force-push or merging main/transfer. C2.6 remains blocked.

## 2026-10-29 — C2.5C replay post-processing and reference sign analysis

User reports successful first 21-day partial replay on MATLAB/Simulink R2025a:
executed_partial_not_validated, matlab_execution_completed=true, simulation_returned=true,
seven warm-up plus fourteen evaluation days, eleven drivers and 60,481 input samples.
No evaluation.csv, comparison_metadata.json or replay_run.json from that run has yet
been uploaded to this workspace. Recorded execution as user-reported; did not create
or archive a substitute replay report, infer THERMA temperatures or claim independent
MATLAB execution. Earlier archived engineering verification remains separate.

Implemented therma.validation.analysis with analyze/reference-signs commands. The
read-only pipeline validates the actual three export files, CSV hash, execution/model/
scenario/revision consistency, units, finiteness, unique monotonic time, driver coverage
and interpolation, exact evaluation boundaries and warm-up exclusion. It streams
hashes and loads selected numeric columns only, without simulation.mat or an FMU
runtime. Produces metrics.json, engineering_summary.md and five diagnostic plot pairs
(300-dpi PNG/vector PDF), plus a reference air comparison when provenance checks pass.
Temperature conversion is explicit; signed power and relative storage remain unchanged.
Full-resolution calculations retain all negative samples; no calibration or clamping.

The original typical/peak BOPTEST evaluation trajectories are available under ignored
outputs/boptest/runs. Reference comparison checks original manifest/CSV/signal hashes,
FMU/revision/scenario, period and physical quantity. Uses internal TAir, never operative
temperature or TRad proxies. Continuous candidate air temperature aligns onto native
30-second reference timestamps to avoid adaptive-solver sample-density bias; reports
MAE/RMSE/sampled max/bias and alignment details without accuracy thresholds. Missing or
incompatible reference data yields blocked status and no invented metrics. Actual
C2-versus-BOPTEST comparison still awaits the three MATLAB files.

Investigated actual original-source heat-port data with sign conversion -QCon_flow,
-QRad_flow. Typical evaluation: zero negative convective samples, 580 negative radiative,
392 negative total; minimum radiative -32.38455799 W and total -27.82465885 W. Peak:
1456 negative convective, 4059 radiative, 2761 total; minimum total -59.19742692 W.
These are genuine signed source samples, consistent with reverse exchange, not fuel
consumption. Generated source-only sign-audit JSON/summary and PNG/PDF plots for both
actual references under ignored outputs/boptest/analysis/c25c_*_source_signs. Did not
represent these as THERMA results or infer an exact temperature cause without states.

Energy diagnostics report storage change, instantaneous power residual, signed sampled
residual integral and component accounting. Standard replay CSV lacks total external
net power, so full DeltaE-integralQnet closure is explicitly blocked rather than
summing an incomplete heating/ventilation boundary. Optional documented net power
allows a sampled (quadrature-sensitive) closure diagnostic; no conservation pass is
inferred. Recommendations remain missing absorbed solar/full initialization, then
source glazing/exchange/radiative refinements; no C2.6 physics work began.

Added synthetic-data regressions for known analytical metrics, blocked/mismatched
reference data, no operative-to-air substitution, nonfinite/duplicate timestamps,
warm-up leakage, source hashes/units/identities, interpolation, sign/negative-energy
handling, optional energy closure, immutable inputs and PNG/PDF export. Synthetic
results exist only in test temporary directories, not as archived MATLAB evidence.
All 139 Python tests pass with optional Matplotlib installed. Ruff lint/format, strict
mypy, evidence/mapping checks, static lint of 28 MATLAB files, wheel/sdist builds and
whitespace checks pass. CI adds a synthetic plotting smoke test. New docs/README
links resolve. No C1/C2 MATLAB implementation, parameters, reference data or archived
reports changed; frozen registry/FMU hashes remain f91141d78668908525d484a4900dc69af1a163c4c5e07f5a5fbd0c43eae4451c
and 365b3085d97cc4620c06b6036156126a056d7f160fcc4f181d6b2fac4b05743b.

Added docs/C25C_REPLAY_ANALYSIS.md and updated README/roadmap with truthful execution
and pending-data status. User authorized commit/push to work; generated outputs remain
ignored. Next: upload actual evaluation.csv/comparison_metadata.json/replay_run.json,
run the reproducible analysis, inspect the first exploratory comparison before C2.6.


## 2026-10-29 — Actual first typical replay attachments analyzed

Successfully downloaded all three actual attachments (evaluation.csv 10,688,915 bytes,
comparison_metadata.json 2,207 bytes, replay_run.json 16,384 bytes) and copied them
unchanged to ignored outputs/boptest/replays/first_typical_actual. CSV SHA-256 matches
metadata: 2f23cbda2c8c1c49e347004a2429ff2a1e9764798cbda33e2a6bd9d05539a424.
Attachment/copy hashes were compared before and after processing. No synthetic data
was substituted, no MATLAB execution occurred, and no original/reference artifact
or thermal implementation was changed.

Executed the existing C2.5C pipeline against hash-matched typical_heat_day_ailcox5y.
Verified actual run completion flags, model/reference/manifest identity, units, strict
time ordering, exact 14-day coverage (28857600–30067200 s) and warm-up exclusion.
Actual replay has 58,008 adaptive evaluation samples; metrics use 40,321 native
reference timestamps. Air-temperature MAE=2.3405322638114505 K, RMSE=2.8055004126523566 K,
maximum sampled absolute error=7.43410485371686 K, bias=-2.3351963931473314 K.
Generated actual metrics.json/engineering_summary.md and all six PNG/PDF figure pairs.
Visually reviewed figures; no clipping, smoothing, clamping or calibration performed.

Investigated raw union-grid heating comparison discrepancies with a supplementary
hash-checked full-trajectory audit at actual candidate timestamps. Both delivered
heating components match their original source holds within 5.01e-12 W at every
sample. Outdoor linear forcing matches within 3.61e-11 K, internal gains within
3.55e-15 W. Raw sparse-log reconstruction discrepancies around switching times are
not evidence of an actual source sign/driver mismatch. Preserved both diagnostic
views and their limits in generated artifacts and the engineering summary.

Actual total heating has 392 negative samples (min -27.82466 W); radiative has 580
(min -32.38456 W); convective stays positive. These match signed source exchange.
Component sum discrepancy <=1.07e-11 W; maximum instantaneous power residual is
2.81943e-11 W, RMS 6.38965e-12 W. Storage changes +49.47423 MJ. Full integrated
external-energy closure remains blocked by missing exported net external power.
Missing absorbed solar, provisional initial states and reduced physics prevent a
reference validation claim. First/second-week biases -3.15352/-1.51691 K cannot be
uniquely attributed to initialization or omitted physics.

Saved supplementary derivation script and integrity/audit JSON alongside results;
prepared results-only ZIP locally, excluding raw uploads/reference datasets/caches.
Updated README, roadmap and analysis guide; added docs/C25C_FIRST_ACTUAL_RESULTS.md.
No C2.6 implementation. Original MATLAB files and all generated datasets/plots stay
ignored; only the small human-readable results/progress documentation is versioned.

## 2026-10-29 — Results transfer published; C2.6 prerequisites investigated

Published the unchanged 1,804,074-byte results-only ZIP on replay-transfer at
4f35abfa919a707034ff0ec64114fd0430bd9cbf. A fresh isolated fetch from GitHub confirmed
SHA-256 108a5502e5604993a0782dad7759fa7f099732ddcb34c152063bcd1848e10314.
Archive contains six PNG/PDF pairs, metrics, engineering summary and supplementary
reports/script, excluding raw MATLAB uploads, reference datasets and generated models.
No transfer-branch merge into work/main occurred.

Inspected the unchanged pinned original FMU and hash-verified IDEAS sources. A short
original-FMU initialization/readability probe (24 x 1800 s, not a replacement baseline)
confirmed direct/diffuse solar totals, seven distribution weights/surface powers and
39 continuous states are readable. Six opaque solar powers can be derived from the
source equation; a seventh glazing share must remain explicit. Combined surface
powers include existing radiative gains and must not be injected as solar alone.

Initialized opaque/glazing/air temperatures were 293.15 K, already matching the C2
warm-up start. This supersedes the earlier provisional inaccessible-temperature gap;
it does not establish that initialization explains the measured bias. Complete
portable FMI restart is unsupported. See docs/C26_PREREQUISITES.md for exact variables,
source links, mapping, capability limits and probe-report hash.

Proposed future gates: observability-only export, opt-in solar-resolved packet,
initialized-temperature assertions, complete energy exports, then controlled MATLAB
comparison before deciding further physics scope. No physics, parameters, frozen
registry, original outputs or replay schema were changed; no MATLAB execution or
calibration occurred. C2.6 implementation remains pending.

Checks: 139 Python tests passed with optional plotting dependencies; Ruff lint and
format, mypy, archived-evidence integrity and 14 replay mappings passed. MISS_HIT
static lint passed for 28 MATLAB files; git diff --check passed. These checks are
not MATLAB execution or numerical validation of proposed C2.6 work.
