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

## 2026-10-29 — C2.6A/B solar-resolved benchmarking implemented in cloud

Added opt-in --solar reference observation to the pinned original FMI driver. Final
full-period run typical_heat_day_u7x05kpz succeeded on the unchanged original FMU,
with 60,481 samples at 30 s, seven warm-up and fourteen evaluation days. Recorded
original names/VRs/units, direct/diffuse/gain distribution and all 39 continuous states
plus air temperature at initialization/evaluation start. Exporter/module hashes are
recorded. All common original channels were bit-identical to the frozen typical run;
a separate default-export regression also reproduced every original channel exactly.
FMU and frozen registry hashes remained unchanged. No MATLAB execution occurred.

Independent source-equation checks: combined residual <=2.256e-13 W, direct sum
<=9.095e-13 W, diffuse sum <=2.274e-13 W, seven-surface total <=1.365e-12 W.
Evaluation solar hold reconstruction: total 65.42872 kWh, six opaque 61.29195 kWh,
separate glazing 4.13678 kWh. These are sampled reference energies, not measured
THERMA improvements. Initialized opaque states are 293.15 K; evaluation-start range
270.380878–294.714344 K. State snapshots are not portable restart evidence.

Implemented solar.py verified opt-in schema v2 packet alongside untouched v1/no-solar
preparation. Original five forcings remain unchanged; six source-derived solar ports
use [1,3,4,2,6,5], seventh glazing allocation is preserved and never redistributed.
New checks reject checksum, source-equation, identity, unit, sign, ordering, timestamp,
state-dimension and initialization errors. Independent tests use small synthetic data
explicitly labeled as tests, never physical evidence. Actual packet/report/PNG/PDF
source figures generated under ignored outputs/boptest/c26/.

MATLAB loader supports v1/v2, source hashes/units, observed uniform initial vector,
solar routing and strict v2 grid. Driver hold policy and nested exception diagnostics
remain intact. Added one solar batch entry and opt-in MaxStepSeconds for later actual
solver sensitivity; defaults retain original settings. Extended export uses already
existing net external power, stored-energy derivative, solar and internal-power logs.
No thermal equations, physical parameters or frozen reference artifacts changed.

Added actual-output paired analysis: native-reference temperature MAE/RMSE/max/bias,
daily errors, signed heating/internal/solar energies, complete sampled energy closure,
publication plots, JSON and optional actual-output solver comparison. Same solver
settings are labeled repeatability only. Actual solar-resolved MATLAB results and
metrics remain pending; original 2.34053 K MAE/-2.33520 K bias is not reinterpreted as
validation or attributed solely to solar. Dynamic glazing/exterior/moist-air gaps remain.

Updated README, roadmap, C26_SOLAR_BENCHMARK guide and machine-readable C26_ARTIFACTS
receipt. Prepared separate transfer ZIP with checksummed packet, reference evaluation
subset, reports and source-only figures, without FMU/runtime, MATLAB uploads or models.
Next milestone is C2.6C actual MATLAB tests/replay and controlled comparison; no further
physics/calibration/network implementation started.

Resumed publication session: preserved all prepared changes and verified existing
full-period outputs without rerunning the FMU. Full optional-plot suite: 162 tests
passed (4.91 s). Ruff lint/format (66 files), mypy (10 modules), archive integrity,
14 compatibility mappings, MISS_HIT (29 MATLAB files), package sdist/wheel build and
git diff --check passed. Wheel contains both new analysis modules. Verified exact
observed/declared initialization equality and unchanged C1/C2 builders/loaders,
assumptions and frozen registry against the pre-task commit. No MATLAB execution.

Reference/replay ZIP is 36,415,347 bytes, SHA-256
117ce27286e078080fb6766c77b1e9ad0939d6ecb39ae2b86f1f354d666364aa.
ZIP CRC and every payload hash were checked; the original packet independently
passed its 60,481-sample schema/source conservation audit. Generated datasets remain
ignored on work. Publication metadata and independent upload verification are recorded
in docs/C26_ARTIFACTS.json; replay-transfer remains separate from work/main.
Transfer publication succeeded at f52fc632167aeeed0be60bf173f036a3410190c0;
a fresh isolated GitHub fetch verified identical uploaded ZIP bytes/SHA-256.

## 2026-11-02 — Actual C2.6C R2021a benchmark comparison

Downloaded the actual evaluation.csv (13,537,973 bytes), comparison_metadata.json
(2,695 bytes) and replay_run.json (61,677 bytes); preserved original bytes in ignored
outputs/boptest/replays/c26_solar_actual/. CSV SHA-256
b1c340ae56d42877ff000104f921dc42f43faa41f040f7e5c1a9230e6255cb0d matches
metadata. The optional simulation.mat exceeds the attachment tool 32 MiB transfer
limit and was not accessed. No MAT contents, missing logs or MATLAB execution were
fabricated. The user reports 14/14 MATLAB tests passed; no separate test log supplied.
Actual replay confirms MATLAB 9.10 R2021a / Simulink 10.3 R2021a, completed execution
and export. Preserve matlab_verified:false and executed_partial_not_validated flags.

Used the existing paired/individual comparison pipeline on 40,321 native reference
30-second timestamps, excluding seven-day warm-up. New 59,292 adaptive samples span
exact 14-day endpoints. MAE=0.7925341950338989 K, RMSE=0.9239755340437169 K,
maximum absolute error=2.3971545332768756 K, bias=-0.4506132799970814 K. Against
preserved C2.5, error reductions are 66.13872%, 67.06557%, 67.75463%, and 80.70341%
in absolute bias. All 14 daily MAEs improve. No accuracy threshold or validation
pass was invented. R2025a baseline versus R2021a solar remains a causal confound;
no quantified release/solver sensitivity exists yet.

Verified original packet/file hashes, pins, units, reference identity, driver hash,
initial vector, all 11 driver policies and input coverage. Supplementary audit checks
actual outdoor/heating/internal inputs in both runs against the same source at every
export timestamp; max heating discrepancy 5.01e-12 W, solar 5.01e-12 W. Explicitly
handled known MATLAB embedded-JSON field-name/null round-trip effects after checking
the exact original packet hash; originals remain untouched. Source energies are
529.38619 kWh radiator, 15.038 kWh internal, 61.29195 kWh opaque solar, with seventh
4.13678 kWh glazing share preserved separately. Adaptive-log energy differences do
not indicate heating savings or changed forcing. Signed reverse heat is retained.

Instantaneous residual max 2.70575e-11 W. Storage changes +15.258404 MJ; sampled
hold integral final residual -109.063 kJ (max 110.247 kJ); trapezoid sensitivity gives
-6.910 kJ (max 7.227 kJ). These are quadrature diagnostics, not exact conservation
or solver convergence proof. Baseline integrated closure remains blocked by absent
net power. No equations/parameters/source reference artifacts were altered.

Added reusable metric-change/environment reporting, daily/error plots, metadata
round-trip guards, solar-aware limitations and an actual-input/energy audit command.
Published professional docs/C26C_ENGINEERING_REPORT.md, small JSON/CSV provenance and
results, and five PNG/PDF pairs. Original raw uploads/baseline/reference remain ignored
and byte-preserved; only derived reports/figures are versioned. README/roadmap updated.
Checks: 164 Python tests passed; Ruff lint/format, mypy, archived evidence, 14 replay
mappings, 29 MATLAB files static lint and wheel/sdist build passed. No MATLAB in cloud.
Next: common-R2021a baseline control and solar step refinement/full logs, then source-
derived glazing/exterior-boundary diagnostics before deciding further physics scope.

## 2026-11-03 — C2.7 controlled verification infrastructure (execution pending)

Inspected existing C2.6C evidence, both original transfer packets, model builders,
solver/drivers, tests and analysis. Preserved C2.6C actual R2021a results and the
R2025a no-solar baseline. Directly checked 60,481 full-period timestamps: original
packets' first five channels/time are exactly equal; original six no-solar columns
are zero. Frozen C1/C2 builders/loaders, material registry and assumptions remain
byte-identical. No FMU rerun, MATLAB execution, recalibration or new physics.

Added C27 study plan and sequential MATLAB quick/full workflows. Quick runs all
MATLAB tests and 600 s smoke after checksums; its distinct status cannot be accepted
as a benchmark. Full schedules original no-solar/30 s and identical solar/30/15/5 s,
with unchanged tolerances/family/start/warm-up/evaluation. Each attempt has fresh
outputs. Hash-checked completion receipts and code/input/release/retention contracts
permit resume only for matching intact full runs; corrupt/incomplete attempts are
preserved and rerun separately. New resume regression is a synthetic unit fixture,
not evidence of MATLAB execution.

Extended existing replay orchestration only: measured sim() wall time, actual solver
metadata, optional MAT/trajectory retention, short stop and ordered original energy
logs before unique-time export. Original full-run defaults remain available; C27 lean
mode omits large MAT/full trajectory files. Driver interpolation/final-value holding
and nested exception causes remain preserved. Separate driver duration enables smoke
coverage without changing original packet metadata or physical equations.

Added actual-only four-run study analyzer: validates every receipt/artifact/contract,
requires one MATLAB/Simulink version and unchanged family/tolerances/parameters,
compares all temperature errors on native reference grid, quantifies pairwise step
sensitivity/runtime, and integrates ordered event logs without deleting duplicate
sides. No convergence threshold/order assumed. Six figure pairs are generated only
from actual exports; plotting/contracts tested with explicitly synthetic fixtures.

Added root offline entry and START_HERE, package assembler, C27 engineering report
with pending result table/reproduction and design-only C3 hydronic architecture plan
comparing Simscape and equation-based/hybrid options. C3 implementation remains gated
on actual C27 study results. All new datasets are drawn unchanged from original
packets; no new benchmark output was invented. Preparing an immutable transfer ZIP
from the committed work source, with per-file SHA256 integrity and input provenance.

Quality gates: 174 Python tests passed (17.69 s), including corruption, mixed-release,
receipt, ordered-event quadrature, all-six-figure export and driver smoke-coverage
regressions. Ruff lint/format (74 files), mypy (11 modules), archived-report integrity,
14 replay mappings, MISS_HIT static lint (34 MATLAB files including root entry) and
wheel/sdist build passed. CI now includes root-entry static lint. Original C26C
report/figure checksums and physical-code/configuration bytes were verified unchanged.
No actual C27 MATLAB tests, simulations, runtimes or convergence measurements exist yet.

C27 delivery completed: 12,853,763-byte ZIP, 152 files, pinned implementation source
7516fd073fdf590162812048eaf3a844dc7e26f5. Packaging now resolves symbolic refs to
immutable commit hashes. Extracted package manifest/source hashes, required Windows
paths, original packet byte preservation and full 60,481-sample solar contract passed.
SHA-256: 01b093ce8c684d62a1e90912af2d837672251faab8cc74158e590e061d575db6.
Published separately at replay-transfer 9dd5a89380d160ab4db213213b1b3e7492a4e231;
a fresh isolated GitHub fetch verified the uploaded ZIP bytes. Previous transfer
artifacts and main are unchanged. docs/C27_DELIVERY.json records provenance/checks.
University commands are run_verification("quick") then run_verification("full").
C27 actual MATLAB tests/runs, solver metrics and convergence conclusions remain pending.

## 2026-11-03 — C2.7 R2024a event-export failure: scoped implementation

User reports quick verification/tests/smoke pass on R2024a, while first full
no_solar_30 fails at event writetable with MATLAB:fopen:InvalidFileLocation on UNC.
Directory exists, reported path length 128, small and 1000-row/six-column CSVs succeed,
final file absent. These observations do not establish file size, RAM, quota, locking
or filesystem transience as the cause. University root cause remains unconfirmed.

Inspected old event pipeline: full raw matrix, copied evaluation subset, full table
conversion and writetable. Replaced event path only with 4096-row binary64 %.17g
chunk writing to unique system-temp staging; no full event matrix/table. Evaluation
bounds, six columns, original event order, duplicate times and prescribed-power sum
are preserved. Stream validation checks exact header/column counts, finite values,
row count, complete records and nondecreasing time. Closed staging is copied through
unique sibling partial files with bounded attempts; final size/SHA256 identity proves
it matches the stream-verified file. Existing final files are never intentionally
replaced. Staging locality/UNC atomicity/free quota are not assumed.

Added context diagnostics: MATLAB version, target/directory/UNC classification,
directory existence, input/selected row counts, size estimates, usable-space observation
only when obtainable, stage, staging path and original recursive exception. Failed
staging retained for diagnosis; partial copies cleaned best effort. Context is printed,
written to a unique failure JSON if possible and embedded in the chained exception.
Runner records verified export metadata/hash on success, explicit export_completed
only after all exports, and failed overall/export state on error. Solver-return flags
remain truthful. Resume rejects explicit failed export or changed export hashes;
intact matching-contract successes remain reusable. Cross-code-contract migration is
not silently enabled. No C1/C2 equations, parameters, solver settings, reference inputs,
C26C results or C3 implementation changed.

Prepared six MATLAB IO tests for small/full precision, 50000-row synthetic chunking,
duplicates/bounds, invalid destinations, overwrite refusal, truncated/interrupted CSV,
ordering and UNC classification/conditional actual UNC IO. Resume regression covers
failed-export rejection and verified success. These are unexecuted MATLAB software
tests, not benchmark evidence. Added Python static guards; all 177 Python tests passed.
New code statically linted with MISS_HIT (38 MATLAB files); actual university execution
of the fix remains pending. R2024a explicitly recognized; R2021a interface retained.
New scoped diagnostic guide and fresh offline package will preserve the old artifacts.
Final checks after the scoped changes: 177 Python tests passed (20.13 s), Ruff
lint/format (76 files), mypy (11 modules), archive integrity, 14 replay mappings and
wheel/sdist build passed. Static MATLAB lint passed for 38 files. Physical builders,
loaders, material/assumption registries, solver study plan and C26C result hashes were
verified unchanged. MATLAB IO regressions and UNC success still require university execution.

Updated package published: THERMA_C27_EVENT_EXPORT_FIX_R2024a_2026-11-03.zip,
12,869,505 bytes / 159 files, source 202df140773bc74a4fda3342cc543e580863a730.
SHA-256 fd6a09d46981df83dfb68b3167c600107580465c841053b040572a1ac1587a96.
Fresh extraction verified all manifest/source/dataset hashes, required helpers/tests
and the original 60,481-sample solar packet. Static MATLAB lint passed after ensuring
synthetic UNC classification does not probe an unreachable fake server; real UNC IO
is tested conditionally only on an actual Windows UNC installation. Relevant Python
export guards reran 3/3 passed. Published on replay-transfer at
995bdf68b190c5067502b6c804eb3dc0cc74dcb6, independently fetched and hash-verified.
Previous ZIPs, main, physical models, solver plan and original results remain unchanged.
New delivery receipt is docs/C27_EVENT_EXPORT_FIX_DELIVERY.json. University quick/full
execution of this fix remains pending; no claim of resolved UNC root cause is made.

## 2026-11-03 — C2.7 EOF classification and cleanup lifetime correction

User reports R2024a package integrity passes (158 manifest payloads), thermal tests
complete, but six event-export regressions fail: expected fread EOF is rejected as
THERMA:EventCSVRead, followed by already-destroyed shared fid in nested cleanup.
Inspected both paths. No new MATLAB report/log was supplied or fabricated.

Verifier now checks ferror after each read: status 0 is accepted; status -1 only with
feof true is treated as expected EOF; every other read error remains fatal, and an
empty read before EOF fails. Pending partial record, exact header/six columns,
finite values, exact row count, event order/duplicates and final SHA checks remain
unchanged. Extra records and malformed/truncated input still fail verification.

Replaced nested cleanup functions with independent BoptestEventExportResources handle
state captured by value in an anonymous callback. File ID is disarmed before close;
cleanup is idempotent and cannot close a reused ID or access destroyed parent locals.
Owned partial copies are removed best-effort, failed staging retained and successful
staging removed; verified final output is never a cleanup target. Cleanup probe/delete
failures cannot replace primary exceptions. Original invalid-directory cause preserved.

Original six MATLAB export tests retained; added independent normal-EOF/extra-row,
missing-column/nonfinite, reused-ID/idempotent cleanup and warning/leak/error-cause
regressions. These remain unexecuted MATLAB software tests; user university rerun
is required. Python/static guards cover EOF predicate and cleanup structure. Current
Python suite: 179 passed; static MATLAB lint 39 files. No thermal physics, solver,
BOPTEST inputs, C26C results or C3 implementation changed. New scoped guide documents
the corrections and fresh offline quick/full delivery, with successful MATLAB execution
explicitly pending. Original university UNC file-creation root cause remains unconfirmed.
Available checks passed: 179 Python tests (20.54 s), Ruff lint/format (76 files), mypy
(11 modules), archived evidence/14 replay mapping checks, wheel/sdist build and final
MATLAB static lint (39 files). Targeted EOF/cleanup static guards reran 5/5 passed.
Physical code/configuration, solver study plan and C26C artifact checksums unchanged.
No MATLAB test result or successful university verification is claimed for this patch.

New delivery: THERMA_C27_EOF_CLEANUP_FIX_R2024a_2026-11-03.zip, 12,876,800 bytes,
162 files, source 28965ed1c83068b7d92d6a1e325584122b24a0b1. ZIP CRC, every extracted
manifest/source hash, new resource-owner class/EOF guard and original 60,481-sample
solar packet passed cloud integrity checks. SHA-256:
b680eb85123d1bcc5a648ca74b8d8c9c43d81e0d0cccbe2bb21721c6a359e4a9.
Published on replay-transfer at 1a7b668cbbc62b88340596e7fd71390750a16feb and independently
fetched from GitHub to verify identical uploaded bytes. Old artifacts/main unchanged.
Delivery receipt: docs/C27_EOF_CLEANUP_FIX_DELIVERY.json. Commands remain
run_verification("quick") then, only after successful quick tests, run_verification("full").
University MATLAB execution of the new EOF/cleanup regressions remains pending.

## 2026-11-03 — R2024a reader state-machine revision (execution pending)

User reports integrity passes (161 payloads) but eight export tests fail on R2024a:
normal EOF is reported by ferror as -4. The previous -1-based classification was an
incorrect portability assumption. No new MATLAB output logs were supplied beyond
the reported failure; no actual R2024a reproduction can be run in this environment.
Vendor/mirror document retrieval attempted once in parallel and blocked by proxy 403.

Replaced the complete production read loop, not an EOF-number allowlist. The verifier
opens once, checks seek statuses, captures byte length with ftell, rewinds and requests
only min(1 MiB, remaining bytes). Exact returned counts and byte positions are required;
short/no-progress reads and final length changes fail. No terminal read past EOF and
no fgetl/ferror numeric classification on the success path. ferror/feof are failure
diagnostics only. Header/body parsed from the same bounded byte stream; incomplete
records, header/column errors, nonfinite values, extra/missing rows and decreasing
timestamps remain errors. Duplicate timestamps/order preserved. Incremental SHA256
binds the verified bytes; writer checks fresh staging hash equals that scan digest
before unchanged copy/final-hash publication. Thermal physics and inputs unchanged.

Found a Windows diagnostic representation mismatch: the invalid-directory test
searched for a plain path inside JSON-escaped exception context. Primary message now
also includes the plain target path; all original identifier/cause assertions remain.
Test additionally verifies exact target/directory/existence/original identifier in
actual failure JSON. No failed assertion was simply removed. Independent cleanup
owner remains unchanged and safely disarms IDs; resume/completion gates preserved.

Added minimal MATLAB-compatible reproduce_boptest_csv_reader: writes two synthetic
records, records actual fgetl/fread counts/positions/feof/ferror diagnostics without
assuming their numbers, and verifies those same bytes using the new reader. Probe
JSON is saved even if snapshot verification fails, retaining actual observations.
Added exact-one-MiB and split-final-record tests, probe test and invalid-record classes;
retained all previous export/cleanup tests. These MATLAB regressions are unexecuted
here and not benchmark evidence. New guide documents API semantics, blocked live-doc
retrieval, the full state machine and university validation limits. No C3 changes.
Checks: 180 Python tests passed (19.89 s), Ruff lint/format (78 files), mypy (11
modules), archive integrity/14 replay mappings, wheel/sdist build and MATLAB static
lint (40 files) passed. Added CRLF header handling to preserve fgetl line-terminator
semantics while hashing original bytes; CRLF and chunk-boundary MATLAB cases prepared.
Physical builders/loaders, solver plan, parameter registries, independent cleanup owner
and previous C26C result hashes verified unchanged. No MATLAB test was executed here.

R2024a reader delivery: THERMA_C27_R2024A_READER_FIX_2026-11-03.zip, 12,886,495 bytes,
165 files, pinned source 945acca7cbd8c43bd8050b7a768811ac5f1902b9. CRLF record
terminators are normalized for numeric parsing only after raw bytes are hashed;
the original bytes/values/order remain the verified payload. Fresh extraction passed
manifest/source/dataset hashes, required probe/reader presence and original solar
packet validation. SHA-256:
6147bc270ff95be5c94637c236b123ce6bc0ca25c09e925840156b4e12827d86.
Published on replay-transfer at 30f48534f4cb67e17e01199ecd55d69b822c3f87; an independent
GitHub fetch verified identical uploaded bytes. Prior artifacts/main unchanged.
Delivery metadata: docs/C27_R2024A_READER_FIX_DELIVERY.json. Targeted reader/diagnostic
Python guards 6/6 and final MATLAB static lint passed. All actual MATLAB API-probe,
regression, quick/full and university-success claims remain pending execution.

## C2.7 SHA-256 compatibility revision — 2026-11-03

User reports successful CSV probe and only one remaining Java NonScalarArg test failure. Shared explicit byte-array update handles empty/singleton reads; file hashing is snapshot-bound. Seven fixed hashlib/OpenSSL vectors and MATLAB regressions added. Physics, reference data, CSV integrity and resume unchanged. MATLAB execution remains pending.

Checks: 182 Python tests passed (20.64 s); Ruff lint/format, mypy (11 modules),
archive integrity, 14 replay mappings, wheel/sdist build and MATLAB static lint
(42 files) passed. Prior C2.6C report/figure/data checksums match. Historical evidence
import tests now reconstruct the report's pinned source snapshot rather than
assuming its old hash utility matches current code; evidence bytes are unchanged.
No MATLAB tests were executed in cloud.

Delivery: THERMA_C27_SHA256_FIX_R2024a_2026-11-03.zip (171 files, 170 manifest
entries), pinned source d63b98320c69d72043dd23ecd51dca7b49c2c84d. Fresh extraction
verified all source/dataset hashes. SHA-256:
77e70085bbb45256a734195b7ea9e0adbbbdabdb43d330423a5562e565fc1fd6.
Published on replay-transfer at 02473b7cb0a52a84e00f5611eb348e759192ce55;
an independent GitHub fetch confirmed uploaded ZIP byte identity. Old transfer
artifacts and main preserved. Delivery receipt: docs/C27_SHA256_FIX_DELIVERY.json.
University run_verification("quick") acceptance remains pending.

## C2.8 reference-temperature workflow — 2026-11-05

User reports completed four C2.7 university runs and approximately 7.154 °C maximum
solar/no-solar difference. No corresponding study_index or outputs are present in
this workspace, so completion and this difference remain user-reported; no C2.8
metrics or three-curve results can be produced here yet. Existing C2.6C evidence is
preserved and is not relabeled as same-release C2.7 validation.

Recovered the exact original replay reference from existing verified FMU artifacts;
no FMU or MATLAB simulation rerun. Exported 40,321 native 30 s evaluation samples
with genuine air and operative temperatures, complete provenance and original
source manifests/signals. Confirmed all 61 original columns numerically identical
in the later solar extraction over 21 days, allowing its distinct source hashes
explicitly. Extracted CSV SHA256 b2c01b8fa7eace3a6d68e6e6c67b02f44574522c9ceb38319f1faa6803ec2f4e.

Added reproducible extraction, strict standalone MATLAB comparison, metrics and
figure/report generation, software tests, offline packaging and execution guide.
No physics, solvers, reference inputs or prior benchmark results changed. C2.8 is
incomplete pending actual C2.7 data comparison and university MATLAB execution.


C2.8 evidence update: all ten actual attachments received. Index-to-contract,
index-to-receipt and all six consumed export hashes pass. Both supplied reports
state MATLAB/Simulink R2024a; source/solver/parameter identities match the study.
Parsed 58,008 no-solar and 59,292 solar evaluation samples; aligned to 40,321 native
reference timestamps, no extrapolation or warm-up. MAE 2.340532264→0.792534195 K
(66.1387% reduction); RMSE 2.805500413→0.923975534 K (67.0656% reduction).
All 14 daily MAEs improve; maximum trajectory separation is 7.153831909 K.
Generated three actual PNG/PDF pairs, metrics JSON/CSV, daily errors, provenance and
engineering report. Raw attachments and prior C2.6C baseline remain unchanged.

Execution-lineage qualification: solar evaluation.csv is byte-identical to prior
C2.6C evidence whose report recorded R2021a, while the new contract/report state
R2024a. This numerical comparison is valid for the supplied trajectories but does
not establish an independent fresh same-release run. Original university logs,
solver metadata and event files should resolve lineage. Refinement data/event logs
were not supplied or rehashed. MATLAB regressions/FIG reproduction remain pending;
no new simulations, recalibration, physics or C2.9 work performed.

Final checks: 196 Python tests passed (23.59 s); Ruff lint/format (88 files),
strict mypy (13 modules), MATLAB static lint (45 files), archived evidence check,
14 replay mappings and wheel/sdist builds passed. Prior C2.6C checksums match.
MATLAB tests remain unexecuted here. Ordinary GitHub access currently fails at the
network proxy; publication will be attempted with the available authorized route.

Publication: source/results commit a2a7f1be518f4a8f1b09e8b7b4cc961daf2610c7 on
feat/c28-reference-temperature-validation. Offline package
THERMA_C28_REFERENCE_MATLAB_2026-11-05.zip contains 195 files, genuine reference
CSV/provenance and all source/derived reports, excluding raw MATLAB uploads.
Fresh extraction passed CRC, all manifest hashes and expected reference-path checks.
SHA256 c27596e46cc6d89a081d5515f023311cd04331141032962acb8782d1c286f6a3.
Published to replay-transfer at 68da48666048aa2a4634849c628bcc88bac2db45;
an independent GitHub fetch verified ZIP byte identity. The authorized network
route succeeded after ordinary proxy access failed. Existing artifacts, work/main,
reference data and prior results preserved. Delivery metadata:
docs/C28_REFERENCE_DELIVERY.json. MATLAB reproduction and lineage review pending.

## C2.8 standalone packaging correction — 2026-11-05

User found that the earlier offline package omitted the C2.7 trajectories and
failed after their external C2.7 directory was deleted. Recovered the ten original
supplied study files from preserved local outputs, without regeneration or any
synthetic replacement. Updated packager to require and validate the original study,
include the two comparison cases with unchanged bytes/relative layout, and record
all file hashes. Updated MATLAB default discovery to use and verify the bundle's
explicit local index. Replaced external-directory instructions with the standalone
three-command workflow. Existing numerical results/qualifications and physics are
preserved. MATLAB R2024a execution remains pending university confirmation.

Checks before packaging: 198 Python tests passed (22.15 s), Ruff lint/format,
strict mypy (13 modules), MATLAB static lint (46 files), archive integrity and
14 replay mappings passed. All existing C2.8 report/figure/metric checksums match.
Added a MATLAB packaged-data integration test invoking compare_boptest_c28() and
checking PNG/FIG generation plus original MAE/RMSE; it remains unexecuted here.

Standalone delivery: THERMA_C28_STANDALONE_MATLAB_2026-11-05.zip (207 files),
pinned source 58d97674a697f4ccbeb34563b40b5ce734d7aec2. Fresh extraction into an
otherwise empty temporary directory passed CRC, all package manifest hashes and
the ten original study-file hashes. A fresh-source Python analysis using only
bundled inputs reproduced the complete preserved metrics JSON exactly and all
three PNG/PDF figure pairs. This is not MATLAB execution or FIG verification.

ZIP SHA256 026801895c81ba6442f79530172bf7b6b359606e612c013a90dd0be19e369714.
Published to replay-transfer at fd823664688d6c07fa58b5296bd96b6f900af1b0;
an independent GitHub fetch confirmed uploaded ZIP identity. Prior artifacts,
work/main, physical model and numerical results preserved. Receipt:
docs/C28_STANDALONE_DELIVERY.json. University R2024a no-argument comparison and
its PNG/FIG generation still require confirmation; no external C2.7 folder is
included in the corrected workflow.


## C3.1–C3.3 component preparation — 2026-11-05

Read the new C3 request and existing architecture/readiness/zone interfaces. The
user explicitly permits labeled illustrative defaults for an independent emitter
track. Preserved unresolved C2.8 solar execution lineage and all prior numerical
results. Implemented separate native Simulink thermostat, asymmetric bounded valve
and mixed water/metal radiator builders, explicit assumptions/units, actual MATLAB
component driver, 13 analytical/limit tests and a staged offline verification runner.
No BOPTEST radiator forcing is consumed and no Python physics solver was introduced.
Thermostat state retention/sample timing, valve limits and signed radiator energy
storage/flow interfaces are documented. Constant-property/linear-UA/air-as-radiant-
sink and imposed-flow assumptions are explicit, not calibration or hydraulic closure.

The user requires component verification before C3.4 and basic checks before
C3.5/C3.6. MATLAB is unavailable here; therefore integration, the six engineering
experiments and closed-loop comfort/energy plots are not implemented or claimed
complete. Their coupling/scenario plan is documented, with C2 inputs 2/3 identified
for future replacement without double counting. Three SLX component models will be
generated/saved on university MATLAB; no prebuilt SLX or invented simulation outputs
are supplied. New native model solver settings do not alter frozen C2 settings.

Cloud checks: full Python suite 201 passed (21.59 s), Ruff lint/format (92 files),
strict mypy (13 modules), MATLAB static lint (55 files), evidence archive/14 replay
mappings and wheel/sdist builds passed. All C2.8 and C2.6C result checksums match.
The 13 new MATLAB tests are unexecuted; static checks and packaging tests do not
establish numerical Simulink correctness. Runner writes actual test console text,
per-source/config hashes, release and solver settings on university execution.

C3 component delivery: THERMA_C3_COMPONENT_VERIFICATION_R2024a_2026-11-05.zip,
206 files, pinned source b5fd807d2e329d82d468e429655dafa9630d7f8e on dedicated
feat/c3-component-verification. Fresh empty-directory extraction passed CRC,
all manifest/source hashes, declared C3 entry-guide override, required helper/config
presence, 13 MATLAB test definitions and extracted-source MATLAB static lint.
No raw reference/replay data or external project directory is required.
SHA256 c56dd84a80e10f3214379a75f320ef11fc45144004adb0ec04999b20751f9355.
Published separately to replay-transfer at bf1f1f4fdb8005f0ea3ab51fe379908b1aed5138;
an independent GitHub fetch verified identical uploaded bytes. Prior transfer
artifacts and main preserved. Receipt: docs/C3_COMPONENT_DELIVERY.json.
C3.4–C3.6 remain blocked pending actual component verification in university MATLAB;
no C3 simulation result or figure was fabricated, and C4 has not begun.


## C3.4 closed-loop integration preparation — 2026-11-05

Reviewed actual component_verification.json and original test log: 13 passed,
0 failed, 0 incomplete, duration 34.1251171 s, MATLAB/Simulink R2025a. Verified all
nine reported source hashes, explicit assumptions and original package-provenance
hash. Original report/log preserved byte-for-byte under ignored outputs/c3/evidence/
82f4706b453a256c/. Committed selected public summary and exact short test log; raw
report contains private network paths and is not published. No raw numerical max
errors were supplied and generated model files were not supplied for rehashing.
The component gate passes for the recorded source, not C3.4 or R2024a execution.

Reused unchanged thermostat/valve/radiator sources and original C2 building graph.
New C3.4 builder copies that graph into a separate model, assigns explicit 15 °C
initial conditions in its copied workspace, and replaces only heating vector
inputs 2/3 with independent radiator powers. Outdoors/solar/internal/envelope
physics and frozen materials/solvers in original C2 remain untouched. Air remains
the documented radiator radiant-sink proxy, not exact mean radiant temperature.
Added native combined external-energy integrator, radiator/zone/global diagnostics,
finite/physical screening, topology/double-heating checks and three short actual-
Simulink integration fixtures plus CSV-precision test. A standalone runner repeats
13 component regressions and four new tests, then runs only the requested cold
start after passing tests. Default 24 h conditions: room/fabric/radiator 15 °C,
setpoint 21 °C, supply 55 °C, held outdoor 5 °C, zero internal/solar gains. No sizing
or setpoint attainment is assumed. Output plotting and engineering report code
use actual MATLAB data only; no cloud integration result or plot was fabricated.
C3.5/C3.6 and C4 remain gated. Reused/extended packaging supports a self-contained
C3.4 profile with all frozen source/configuration and public component evidence.

Checks: full Python suite 206 passed (21.97 s); Ruff lint/format (96 files), strict
mypy (13 modules), MATLAB static lint (63 files), archive evidence integrity and
14 replay mappings passed. Prior C2.8/C2.6C report, figure and metric checksums match.
Actual source/configuration gate hashes match the preserved component evidence.
These are cloud software/static checks, not execution of the 17 MATLAB regressions
or C3.4 cold-start simulation. MATLAB R2024a compatibility remains an intended
supported interface awaiting execution on the university PC.

C3.4 delivery: THERMA_C34_CLOSED_LOOP_R2024a_2026-11-05.zip (222 files), pinned
source cd95158c28ee125dfb2a92ea74fb7365761f2ebb. Fresh extraction into an otherwise
empty directory passed CRC, all manifest/source hashes, source/config/helper
availability, frozen C2/current component gate identities and 13+4 MATLAB test
definitions/static syntax. No old project directories, FMU or replay data are
required. This does not establish MATLAB model compilation or simulation.
SHA256 690da942c3311cc1d803ba830d949500edf00fe4f919224ae5f0a8a8ecda3cf2.
Published on replay-transfer at da19923436cb7c8ec69fbcd43169a836427dc38b;
an independent GitHub fetch verified identical uploaded bytes. Source pushed to
the C3 development branch. Old artifacts, source physics, work/main and numerical
results preserved. Delivery receipt: docs/C34_INTEGRATION_DELIVERY.json.
Original component log bytes (including final blank line) retained; .gitattributes
prevents text normalization/diff whitespace rewriting of that evidence file.
C3.4 MATLAB execution remains pending. C3.5/C3.6 and C4 not implemented.


## C3.5 engineering investigation preparation — 2026-11-05

New branch feat/c35-heating-investigation. Actual supplied C3.4 report/log reviewed:
17 passed, 0 failed/incomplete, R2025a, tests 57.9763809 s, nominal 86400 s simulation
completed (reported simulation duration 2.0866746 s). All 15 recorded integration
source hashes, baseline configuration and prior component-summary hashes match.
Maximum native integrated errors: radiator 2.21701339e-6 J, combined 9.26294597e-5 J;
heating/partition mismatches zero. Baseline reported max air 17.70689053 °C,
max absolute heat 1586.915949 W, delivered 36.86579156 kWh, water 37.04066826 kWh,
zero observed demand transitions. Full trajectory/final air not supplied; no
tracking/inertia/heat-loss history is invented. Raw report/log preserved unchanged
under ignored outputs/c3/evidence/b92885c8e4b36c37; public selected/path-redacted
copies and original hashes archived in verification/c3/c34_gate.

Attached request ends at “Maximum integrated” midway through the metric table.
Implemented all complete A–F requirements as a standalone MATLAB investigation:
priority four-case UA run; one-factor supply/outdoor cases; paired explicit 3.6 kWh
absorbed-solar profile; conditional observed-controller selection/fallback; baseline
and switched-case 10/5/1 s comparisons. Cases use new generated workspaces only;
C3.4 baseline and verified builders/components remain unchanged. Native additional
loss/solar integrators, continuous-time temperature metrics, hysteresis/valve audit,
steady-load/all-on eigenvalue diagnostic and measured reporting distinguish capacity,
inertia and loss. Resuming requires identical source/config/release contract plus
complete case artifact hashes. No case is altered to manufacture target attainment.

MATLAB is unavailable here, so new cases/figures/metrics/convergence remain pending
university execution. Only the incoming baseline evidence is an actual result.
No C2.8 accuracy reuse, physical recalibration, Python physics solver, ML or C4.


Checks: 209 Python tests passed (21.06 s), targeted source/evidence/package tests
11/11 passed, Ruff lint/format (101 files), mypy (13 modules), MATLAB static lint
(73 files), evidence archive/14 replay mappings and wheel/sdist builds passed.
All C2.8/C2.6C result hashes match; all reported C3.4 source/config hashes remain
unchanged. Fixed packaging profile validation so integration/investigation modes
reject missing stage-specific entrypoints/dependencies, with a regression test.
The new 16-test MATLAB gate (13 existing plus 3 new) is unexecuted here; a passed
actual gate is reused only with matching source/release contract and log hash.
No new study simulation result or convergence claim is made.

C3.5 source and standalone workflow published on feat/c35-heating-investigation.
ZIP THERMA_C35_ENGINEERING_INVESTIGATION_2026-11-05.zip (241 files) pins
b044bf082dbd5f337e0f17267435deb95eed71e8. Fresh extraction passed CRC, full manifest/
source and incoming C3.4 gate/source/config hashes, required dependencies and
13+3 MATLAB test definitions/static syntax. No old folders or raw datasets needed.
SHA256 0cb342a0a75d11319c20c690d8a8bbfe0476fb33971a4888c76e26a095a66472.
Published separately to replay-transfer at d39eaec284d003af95dd1692a3327600312ae285;
an independent GitHub fetch verified identical bytes. Original C3 branch/baselines,
C2.8 results, private raw incoming evidence, existing transfer files and main
preserved. Case-specific provenance clearly separates new one-factor cases from
baseline reproduction; solar reports identify peak envelope versus actual profile.
Delivery receipt: docs/C35_INVESTIGATION_DELIVERY.json. New C3.5 case execution,
results table/figures, regulation, savings and convergence conclusions remain pending
university MATLAB. No C4 work performed.


## C3.6 physical reality check — 2026-11-06

Inspected original C2/C3 parameters without changing physics. The simulated
building is one 48 m² / 129.6 m³ heavy benchmark cell. Approximate H=100.81 W/K;
existing split-consistent steady demand at 21/5 °C is 1.685 kW. At supply55 °C,
UA60 provides1.380 kW (undersized); UA180 provides2.513 kW (capacity headroom).

Actual user-uploaded R2025a baseline/A_UA_180 reports and trajectories matched
completion-receipt SHA256s. First21 °C=12.5077 h for UA180; baseline ends17.707 °C.
By the crossing,32.582 kWh delivered=20.122 outgoing+12.460 building storage.
Heavy fabric15.485 MJ/K plus continuing losses explains slow warmup; losses use
61.8% of delivered energy. No new simulations or counterfactual experiments.
Two actual-data plots, compact metrics/provenance and original small JSON evidence
archived; large original CSVs unchanged locally. Original study contract/index
not supplied; shared contract digest recorded without claiming full contract review.
16 passed C3.5 MATLAB tests are user-reported; new MATLAB entry/test unexecuted here.
See docs/C36_PHYSICAL_CHECK.md. C3.7 not started.

Checks: 212 Python tests passed (19.29 s), Ruff lint/format (103 files), mypy
(13 modules), archive integrity and14 replay mappings, wheel/sdist builds passed.
MATLAB static lint: existing workflow73 files and3 C3.6 targets passed. Byte
comparison confirmed72 existing C2/C3/C3.5/reference/result files unchanged.
New MATLAB test/entry point remain unexecuted here; no MATLAB installation.

Minimal transfer update published separately to replay-transfer (0a99655):
THERMA_C36_PHYSICAL_CHECK_UPDATE_2026-11-06.zip,9 files,454928 bytes.
SHA256 c1b36c656e44ef3afbb17310dd068892cf273c45542c874d71103c32f29c05e9.
An independent GitHub fetch confirmed identical bytes. Tested extraction as an
overlay preserves all241 original C3.5 package files. Requires the existing C3.5
project and completed study; does not duplicate components or trajectories.
main,work,C3.5 branch and existing transfer artifacts preserved. Source ddd7b11;
delivery receipt docs/C36_DELIVERY.json. New MATLAB entry execution still pending.

## C3.7 residential preparation — 2026-11-06

Created separate20m²/50m³ corner-room assumptions and parameter loader. New
construction is rebuilt algebraically on the existing multilayer node topology,
not BESTEST area scaling. Two outdoor walls, two conditioned-adjacent partitions,
and explicit slab symmetry boundaries;15°C air/radiator,20°C fabric,0°C outdoor,
21°C setpoint,55°C supply,24h. Approximate outdoor H15.61W/K (328W at21K), not
a full design load. Unchanged C3.4/C3.5 builders and heating components are reused.
One-run entry point reuses native-energy/hysteresis/valve checks and emits only two
plots. No simulation executed in cloud; no heating time/energy result exists yet.

Manufacturer/search sites are inaccessible (HTTP403), including after network
permission was granted. Asked for an actual manufacturer datasheet/operating
point; no reply/source available at preparation. Radiator config remains explicitly
blocked and empty. No catalogue output, UA or flow has been invented. The entry
point refuses model construction/simulation until a reviewed55°C source, model,
output/return/room temperatures, archived document and its SHA256 are supplied.
The matching algebra is prepared; no generic radiator is presented as a selected
commercial product. C3.7 remains incomplete pending that evidence and university
MATLAB execution. BESTEST, previous results and verified component code unchanged.
C3.8 not started. See docs/C37_RESIDENTIAL_HEATING.md.

Preparation checks:214 Python tests passed(17.58s); Ruff lint/format(105 files),
mypy(13 modules), MATLAB static lint77 files plus4 targeted C3.7 files passed;
archive integrity/14 replay mappings and wheel/sdist builds passed. First test
run caught a material-label JSON key mismatch; corrected before the full passing
run.81 existing source/reference/evidence/result files compared byte-for-byte
unchanged. New MATLAB test and entry point remain unexecuted. No real or synthetic
C3.7 simulation output produced. Any transfer archive is labeled PREPARATION,
not a runnable verified residential benchmark while radiator evidence is missing.

Preparation-only overlay published on replay-transfer(f8b0522):
THERMA_C37_RESIDENTIAL_PREPARATION_2026-11-06.zip,9 new files,13457bytes;
source afaa57b. SHA256 c94bcb81da726b01eac550f558f4cd5b38eb65dc3feddd00597796cc8cde7774.
CRC/manifest/fresh overlay checks passed; all241 original C3.5 package files
unchanged. Independent GitHub fetch verified uploaded ZIP bytes. This is NOT a
ready heating-run package: manufacturer rating and university MATLAB execution
remain required. Source and delivery stored on feat/c37-residential-heating;
main/work and existing transfer artifacts preserved. docs/C37_PREPARATION_DELIVERY.json.

## C3.7 Purmo completion — 2026-11-06

User supplied Purmo Compact Type22 F062206010010P00,600x1000x102mm,864W at
55/45/20°C,6.6L water and listed31.356kg weight, with manufacturer URL. Archived
an accurately labeled user transcription and SHA256; supplied URL still HTTP403,
so no independent page retrieval or downloaded manufacturer datasheet is claimed.
Replaced the prior missing-rating gate with a checked local source transcription.

Existing mixed radiator gives UA34.56W/K,flow0.02066985646kg/s (74.411kg/h),
exact864W at the rated point and839.314W at21°C room,55°C supply. Reused C2 static
network with adjacent-room source correction:339.267W demand,500.047W margin.
Sufficient steady capacity under this room's explicit boundaries, not a measured
rating or a guarantee of transient21°C crossing. No capacity tuning or sweep.

Weight inclusion remains unresolved. For this illustrative run explicitly assume
listed mass includes6.6kg water (density1kg/L), giving24.756kg effective metal,
cp500J/(kgK) and total39,966J/K. If listed weight is dry,43,266J/K instead.
Neither interpretation is claimed as a manufacturer dry-mass fact; fittings and
metal composition remain approximate. No extra simulations to explore this choice.
Actual capacitance is recomputed and assigned to the existing radiator workspace.

Entry point performs one24h native run, existing energy/hysteresis/valve checks,
state and radiator equation checks, previous source/config preservation check,
two PNGs, CSV and structured report. Static demand included in metadata/report;
no accepted result file is written until plots/report complete. Two MATLAB static
C3.7 tests are provided. MATLAB unavailable here: no plots, heat-up time, delivered
energy or successful native test/run fabricated. Native gate pending; C3.8 not begun.

Checks:215 Python tests passed(17.79s), Ruff lint/format(105 files), mypy(13
modules), MATLAB static lint78 files plus5 targeted C3.7 files, archive check,
14 replay mappings and wheel/sdist builds passed.81 previous source/config/
reference/evidence/result files unchanged byte-for-byte. Added one focused MATLAB
static test for the matched rating, mass interpretation and adjacent-boundary
steady demand, alongside the existing room/layer test. Both remain unexecuted
here. No full repository/component duplication or new physics implementation.

Purmo update published separately to replay-transfer(f72ea44):
THERMA_C37_PURMO_RESIDENTIAL_UPDATE_2026-11-06.zip,11 files,17955bytes,
source224eec64e6696a467d187c334763ad1801a922f0. SHA256
f68326e515e68c5381b9a98b5b7fed6df1dd8e822a65623bfc15b4c342901cdb.
Fresh extraction verified CRC, manifest, source transcription hash and correct
relative paths, both over base C3.5 and after the earlier C3.7 preparation update.
All241 original C3.5 package files preserved. Independent GitHub fetch confirmed
uploaded bytes. No raw datasets, outputs, caches or full component duplication.
Use START_C37.txt; previous preparation-only instructions are superseded. Local
MATLAB source/config/test dependencies are in the existing C3.5 folder; no network,
Git or Python needed. Runtime still pending on university MATLAB R2025a.
Delivery receipt docs/C37_PURMO_DELIVERY.json; main/work and old artifacts preserved.

## C3.8 thermostat comparison preparation — 2026-11-08

User reports actual C3.7 MATLAB R2025a execution:20m²/50m³,15°C air/20°C
fabric,21°C setpoint,1K total hysteresis,55°C supply; first21°C0.310h,
62 full-day transitions,10.215kWh delivered, maximum21.754°C; existing energy
and controller checks passed. No actual C3.7 files/test log supplied this turn;
these are user-reported results, not independently inspected or archived logs.
C3.7 files, original results and BESTEST remain unchanged.

Added separate run_c38_thermostat_comparison entry point:1.0/0.5K only, matching
20.5/21.5 and20.75/21.25°C inclusive thermostat thresholds. Reuses unchanged
C3.7 data and original components; only C3.deadband_K changes on a saved-model
copy. Auto-discovers original result/CSV/model, checks hashes/status/room/P/release,
recomputes existing numerical/hysteresis/valve checks and validates saved workspace/
solver/initialization. Compatible C3.7 baseline means only one new simulation.
If no compatible baseline exists, creates both cases in C3.8 outputs; never runs
the C3.7 entry point or overwrites its report/results. Explicit incompatible
baseline input errors. Old source/config/selected result bytes checked preserved.

Primary metrics share2–24h: time-weighted mean/MAE, logged min/max, switches in
(2h,24h], native cumulative-energy difference. Full-day energy is kept separate.
Exactly two PNGs show temperature and thermostat demand during2–8h. Compact report
and conditional recommendation generated from actual results only. No efficiency
claim from delivered energy: boiler/pump efficiencies absent. No physics, building,
weather, new controller or large sweep added. Two focused MATLAB software tests
cover weighting, interpolation, duplicate/boundary events and incomplete coverage.
MATLAB unavailable in cloud: modified case and comparison remain pending native
execution; no fabricated comparison table/plots/results. C3.9 not started.

Checks:217 Python tests passed(17.56s), Ruff lint/format(107 files), mypy(13
modules), MATLAB static lint84 files and6 targeted C3.8 files passed. Archive
integrity/14 replay mappings and wheel/sdist builds passed.95 previous source/
config/reference/evidence/result files compared byte-for-byte unchanged. New
MATLAB metric tests are unexecuted here; no native C3.8 execution is claimed.

Published minimal C3.8 update to replay-transfer(e9ec002):
THERMA_C38_THERMOSTAT_UPDATE_2026-11-08.zip,9 files,13544bytes. Source
c9b5469e2744ec38814c6a2304b9b9c55becedd8. SHA256
628695c1e8c842bca231b8dbe5b4d1e1171e1b425bcf9639b0b1940bf69ba9e8.
Fresh extraction over C3.5+Purmo C3.7 verified CRC, manifest, dependencies and
all252 previous installation files unchanged. No raw datasets, existing models
or output duplication. Independent GitHub fetch verified uploaded bytes. Previous
feature/main/work branches and transfer artifacts preserved. START_C38.txt gives
native test/run commands and baseline reuse policy. Native C3.8 comparison and
recommendation remain pending university execution. docs/C38_DELIVERY.json.


## C3.8 supplied summary review and C3.9 — 2026-11-08

Supplied actual comparison.json SHA256 94855980324494daa8b88b73ceb734fe36a41cd2e2e2371b0566cbb142b4973c.
R2025a report records one new simulation and reused baseline; both numerical/
controller checks passed.2–24h MAE0.358421→0.263136K; switches57→80; delivered
heat8.990510→9.249685kWh. Narrower hysteresis reduced deviation with more switching;
no efficiency claim. Raw trajectories/source artifacts were not supplied for
independent rehashing. Original upload retained unchanged locally; no private
machine paths or fabricated test logs archived, and no C3.8 files modified.

C3.9 reused hash-verified C2.8 controlled pair and original BOPTEST reference run.
Solar MAE0.792534195K,RMSE0.923975534K reproduced exactly with the original native
air trajectory mod.case900Template.TAir; operative reaTRoo_y explicitly excluded.
40,321 common30s absolute evaluation samples,14days after7-day warm-up. Brussels
weather, selected293.15K initial temperatures, existing radiator/internal gains
and six opaque solar powers preserved. No FMU/MATLAB simulation or calibration.

Signed source30s heat529.386194kWh; THERMA adaptive-log hold529.450119kWh; source
on same log grid529.450119kWh. Components match pointwise to5.01e-12W. The0.063925
kWh grid difference is a sampled reconstruction limitation, not independent
heating-system validation or a continuous native-integral proof. Negative source
heat retained. Existing R2021a/R2024a duplicate-solar execution-lineage caveat and
missing event/convergence certification retained. Compact derived tables support
standalone post-processing on the C3.5 installation with no old C2.7/C2.8 folder.
Exactly two actual-data PNGs, metrics/provenance and concise C39 report prepared.
MATLAB R2025a entry/two SOFTWARE tests remain unexecuted; no C4.0 started.

Checks:219 Python tests passed(17.61s), Ruff lint/format(110 files), mypy(13
modules), static MATLAB lint87 files plus3 C3.9 targets, archive integrity,
14 replay mappings and wheel/sdist builds passed.116 previous source/config/
evidence/benchmark files unchanged byte-for-byte. New MATLAB tests are software
fixtures only and remain unexecuted. Original source CSVs/receipts/reports are
preserved; only derived tables are prepared for the transfer ZIP. Exactly two
actual-data PNGs committed. MATLAB reproduction pending, no new model simulation.

Published C3.9 compact update on replay-transfer(2decad0):
THERMA_C39_BOPTEST_COMPARISON_UPDATE_2026-11-08.zip,12 files,2386927bytes.
Source30ea3c50f71b95957cf5b5f75d22950d3e44c5e4; SHA256
3fd6c9974c5201ae61c5869eba0c5ebb49ab0998502672535b576085c38217db.
Fresh extraction over C3.5+C3.7+C3.8 preserved all261 existing files. CRC,
manifest, dependencies,40321x4 temperature and59292x3 heating derived tables,
MAE/RMSE and both energy reconstructions verified without C2.7/C2.8 folders.
Independent GitHub fetch confirmed ZIP bytes. Previous branches and artifacts
preserved; no raw FMU/source datasets or generated models duplicated. START_C39.txt
contains offline MATLAB post-processing commands. docs/C39_DELIVERY.json.
Actual reference comparison complete on preserved results; MATLAB entry/test
execution remains pending. No C4.0 or new physics implemented.

## C4.0 residential heating-system workbench — 2026-11-08

User reports successful R2025a execution/verification of C3.7,C3.8,C3.9; no new
native C4.0 evidence supplied. Created a separate presentation-only builder/entry
point using the verified C3.8 copy helper and C3.7 saved model/parameters. Original
geometry/materials/initial conditions/UA/flow/deadband/solver settings preserved.
Four clearly named physical subsystems laid out left-to-right; main feedback and
heat/mass-flow signals named. Existing diagnostics grouped into a fifth passive
Results and checks utility. Main source-to-destination connections asserted after
grouping; no thermal/control equations or component implementations duplicated.
Only the run's owned intermediate model is removed after saving the final C40 SLX.

Original result/CSV/model hashes and effective release/parameters are checked via
the existing baseline reader. Missing baseline artifacts stop without a substitute
or rerun. One new24h demonstration, existing numerical/hysteresis/valve/power
checks, source/result preservation checks and fixed baseline-comparison gate:
0.001K temperature,0.5W power,0.001kWh energy and identical sampled demands/full-day
transition counts. No tolerances changed after observing results. Controller ticks
use verified post-event sample-selection semantics, not linear discrete interpolation.
One figure overlays C3.7/C4.0 air temperature and radiator power. Model and figure
remain open; only new C4.0 outputs/report written. No original C3.7/C3.8/BESTEST
files modified. No new plant components/controllers/weather or next phase added.

MATLAB unavailable here: no SLX binary or C4.0 trajectory/plot fabricated. The
entry point must generate/open THERMA_C40_HeatingSystem.slx, simulate and establish
reproduction on the university PC. Layout inspection and both small MATLAB
software comparator tests also remain pending. docs/C40_HEATING_SYSTEM.md.

Checks:221 Python tests passed(18.67s), Ruff lint/format(112 files), mypy(13
modules), MATLAB static lint91 files and4 targeted C4.0 files, archive integrity,
14 replay mappings and wheel/sdist builds passed.136 previous source/config/
reference/result files unchanged byte-for-byte. Native model generation, topology/
layout inspection, two MATLAB software tests and one demonstration comparison
remain unexecuted here. C4.0 completion is pending those university checks.

Published C4.0 source update on replay-transfer(c330958):
THERMA_C40_HEATING_SYSTEM_UPDATE_2026-11-08.zip,7 files,11443bytes. Source
40973742501e0930c24786b72b91613fdbffc0c0. SHA256
f7964f6609f62f450ba80e3c07b857ed0aeaa94753e0c9beae58dea689c8ca45.
Fresh extraction/CRC/manifest/dependency checks preserved all273 prior installed
C3.5/C3.7/C3.8/C3.9 package files. Independent GitHub fetch verified ZIP bytes;
previous branches and transfer artifacts preserved. No generated SLX, results,
large datasets or caches included: native builder creates the requested model
on the university PC. START_C40.txt gives test/run/baseline instructions.
docs/C40_DELIVERY.json records pending native generation/reproduction explicitly.
C4.0 not marked complete; no subsequent phase started.

## C4.1 building-reference assessment — 2026-11-08

User reports native C4.0 R2025a verification reproducing C3.7. No actual C4.0
verification JSON/model supplied in this turn; recorded as user-reported, with
no cloud execution or manufactured test log. Existing C3.7–C4.0 files unchanged.

All three requested primary sites returned proxy HTTP403 locally. Inspected
accessible immutable GitHub documentation instead: Twin Houses research mirror
at ae7614bed0d7e5f5e73b3d52e6bcec8efe5f85f9, official ResStock source at
33433157aa52d1a97f35b9640bdf7a2c46f5d908. Twin documentation comprises a198KB
exercise description,34KB channel catalogue and3.87MB KU Leuven report. Only
small repository metadata/text/schema examples also downloaded; no raw measurement
workbooks/FMUs or large dataset archive. Source files retained only in temporary
research storage; source links/hashes recorded, no third-party data redistribution.

Conditional recommendation: IBP Twin House N2, Annex71 2018–2019 campaign,
Holzkirchen. N2 electric heating is simpler for envelope validation than O5's
underfloor-heated periods. Catalogue establishes N2 room-air/heat/weather/ventilation/
cellar/opening signal names/units; report documents ten model zones, six openings
and references primary plans/constructions. Proposed graph includes only those
source-reported openings, with unknown adjacencies explicit. No floor areas,
dimensions, construction properties or measurements invented. Modeller assumptions
and simulated emulator outputs explicitly separated from actual measurements.

Not execution-ready: primary plans/material workbook/spec revision, original N2
measurement/time metadata and data reuse terms remain missing. GPL repository
text does not establish third-party dataset rights. ThermBuild contents/licence
remain unverified. ResStock official XML/YML/code are accessible, but establish
synthetic/representative simulation inputs, not measured multi-room homes; custom
software licence noted separately from data terms. One HPXML case is a simulation-
only fallback, not empirical validation. Proposed conditioning/holdout dates remain
conditional on actual N2 schedule/coverage. No empirical validation performed.

Deliverables: docs/C41_BUILDING_DATASET_ASSESSMENT.md,
docs/C41_BUILDING_ZONE_DIAGRAM.md, data/reference_building/README.md. Local data
folder ignores all downloads except README/.gitignore. No model/physics/controller,
plant component, simulation, preprocessing pipeline, dependency or new test suite.
C4.1 assessment complete with documented acquisition blocker; C4.2 not started.

Documentation-only checks:218 existing Python tests passed,3 optional plotting
tests skipped (plotting dependency absent from the base environment); no new tests.
Ruff lint/format(115 files), mypy(13 modules), new Markdown local links/code fences,
git diff whitespace and raw-file ignore rules checked.209 prior implementation/
configuration/evidence/result files compared byte-for-byte unchanged. No native
MATLAB execution needed or claimed for this assessment; no ZIP/model produced.

## C4.2 Annex58 acquisition attempt — 2026-11-08

User explicitly changed reference to Annex58 Experiment1, DOI10.15129/
8a86bbbb-7be8-4a87-be76-0372985ea228,University of Strathclyde,reported21Aug–
30Sep2013 and CC BY4.0. Those metadata are attributed to the user's publisher
listing, not independently retrieved. No Annex71 geometry, catalogue or conditions
transferred. Existing PDF not attached/found in workspace.

Official DOI/DataCite and candidate university Pure/Strathprints routes failed
with HTTP403 at proxy CONNECT; no publisher-origin response. No actual published
archive/PDF/structure file URL could be discovered, so archive origin status/size
remain unknown. No invented direct links, authentication bypass or substitute data.
FRP-2 Nature/Crossref/PubMed and secondary-cited OpenEI routes also proxy403;
no authenticated fallback geometry/data obtained, no switch made. Detailed exact
URLs and manual publisher-browser instructions in C42_DATASET_INSPECTION.md.

Prepared separate JSON scaffold with dataset provenance and physical fields null/
empty, explicit not-ready status; no claimed room count, dimensions, materials,
adjacencies, units, sampling or initial conditions. No page references fabricated.
Three docs distinguish missing actual topology from a metadata-dependency Mermaid,
not a physical house graph. Original data not obtained or processed; no reference
plot/validation generated. Entry point run_c42_reference_inspection reports missing
local originals/unknown signals and writes an inspection summary only; present
filenames alone are not treated as verified sources. No thermal simulation/new
physics or code dependencies. Two focused Python guards cover campaign separation
and no synthetic output. Raw files remain ignored. C4.2 is incomplete pending the
actual PDF/measurements; no C4.3 work. Previous models/results preserved.

Checks:220 existing/new Python tests passed,3 optional plotting tests skipped;
Ruff lint/format119 files, mypy13 modules, static MATLAB lint1 entry point and new
Markdown local links/fences/JSON checked. Source-file metadata objects share the
same field set for MATLAB struct-array decoding.209 previous implementation/
configuration/evidence/result files unchanged byte-for-byte. New native inspection
entry remains unexecuted; no measurements, processed CSV, plot, empirical-validation
claim or geometry-readiness claim produced. Raw downloads remain ignored.

Published explicitly blocked inspection-only update on replay-transfer(e168aa0):
THERMA_C42_ANNEX58_INSPECTION_BLOCKED_2026-11-08.zip,7 files,11446bytes,
source65383b49d73d2b5854592957d4af2c1003586bc0. SHA256
bac92878c4b5bdc638308ffc8181d385b151695037e0a9593435bc11c18c8aa2.
Fresh extraction/CRC/manifest/dependency checks preserve all280 previous installed
package files. Only the small uploaded ZIP was fetched for independent HTTP/hash
verification; no unrelated historical datasets downloaded for delivery checks.
Previous branches/artifacts preserved. docs/C42_BLOCKED_DELIVERY.json records
that no actual geometry/data integration has occurred. Official PDF/structure/
measurements are still required; native inspection entry is unexecuted here.

## C4.2B FLEXLAB acquisition and feasibility — 2026-11-08

Official LBNL-ETA/FLEXLAB-ASHRAE140 commit265312ec3843c97d5a24b7d5671ee2891f326af6
successfully acquired with selective primary file downloads.35 original files,
including report/drawings, metadata/sensor workbooks, material/construction tables,
window IDF and all20 input/direct/indirect time-series CSVs opened/inspected.
Source SHA256/byte sizes/immutable URLs and channel/missing/gap audit committed as
metadata only. Raw originals stay outside repository. No explicit repository-wide
data redistribution licence found; report copyright does not establish one.

Recommendation CONDITIONAL: separate Cell3B envelope benchmark, not residential
house/main model replacement. Main volume documented6.08×7.57×2.63m (AppendixB),
three physical zones; only main-cell direct validation established. Report's
recommended conditioned experiment22–27June2021 selected over co-heating, whose
experimental energy closure was unsatisfactory. Genuine23June00:00–12:00 PST
fixedUTC−08 selected:721 minute rows with complete finite data in all six core
CSVs and19 of20 audited time series. West-wall heat flux has172 selected records
(549 expected timestamps absent), blocking complete west-flux comparison. Whole files contain gaps/NaNs; no filling, clipping or invented data.
Two actual-data inspection PNGs generated with Python; no MATLAB execution or
model/empirical validation claimed. Temperature aggregate explicitly unweighted26
supplied air sensors, not operative temperature. Metadata conflicts include pressure
Pa/mbar, sampling description10min versus actual1min, missingstree5 headers,
ceiling construction, temporary-wall layer order and unusual Cotton Batt density.
The purported window detailed-report .txt has an Access/Jet binary signature.
Complete fabric initial states unresolved; future preconditioning required.

Prepared lightweight native R2025a run_c42b_flexlab_inspection, original-byte hash
checks, channel/missing/gap display,721-row strict selection, two measured plots
and JSON summary. No MATLAB simulation; native inspection remains pending. Update
requires six original CSVs downloaded directly from pinned source, preserving their
subfolders; no raw-data rehosting. Three concise requested docs plus reproducible
metadata-only Python audit; two focused guards, no extensive new suite/dependencies.
Existing C3/C4/BESTEST models, parameters and results unchanged. Annex58 remains
blocked/separate. C4.3 not started.

C4.2B checks:222 Python tests passed,3 optional plotting tests skipped in base
environment; optional publication-plot smoke test separately passed with existing
matplotlib overlay. Ruff lint/format124 files and mypy13 modules passed; archived
report and14 signal-map integrity checks passed; static MATLAB lint87 files passed;
Python sdist/wheel built. Native MATLAB inspection remains unexecuted. All35 acquired
files(217081214bytes) independently matched pinned upstream Git blob identities in
addition to recorded SHA256. No raw CSV/PDF, cache or generated model staged.

Published13-file C4.2B inspection update(218069bytes) on replay-transfer commit
647a7a81a00ab9462e9c754e190b45a962fae513. ZIP sourcecf8a6b73e2be305e3669f645b2960f92af9fa01a;
SHA2565a808c3731d38c632a35849f4a8f2fd51f87b1cbfad8c8c8f5fafca40c6548f3.
ZIP CRC/fresh extraction/manifest and byte-identical existing-helper checks passed;
independent small-file HTTP download matches SHA256. Previous transfer artifacts,
main/work and Annex58 branch unchanged. Delivery receipt docs/C42B_DELIVERY.json.
The update contains no raw CSV/PDF/SLX; six original CSV downloads from official
pinned URLs are required. No Git/Python/WSL required on PC. Native gate pending.

## Maintenance — lightweight MATLAB execution and preservation — 2026-11-10

Dedicated maintenance branch;C4.3 not started. Audited source/remote branch tips,
cloud storage,large Git blobs and22 preserved transfer ZIPs.553 unique exact-byte
identities (including archive members) recorded in tools/preservation_manifest.json;
ZIP member reads checked CRC. Source snapshot5,702,975B;cloud ignored outputs
2,286,062,890B and Python environment317,444,821B dominate. These are not measurements
of the university folder. No native SLX exists in source/cloud/transfer ZIPs;
builders are not generated-model backups. Milestone inventory explicitly marks
native models/full trajectories/private originals missing from GitHub as NOT YET
BACKED UP. Historical C28 original comparison trajectories are recoverable from its standalone
transfer ZIP. Inspection of every C36 ZIP member confirms it contains derived plots/
report,not original C35 trajectory CSVs;those remain NOT YET BACKED UP ON GITHUB.
No original data/results deleted.

Replaced the cumulative README with a concise engineering overview;retained its
full chronological text under docs/archive/ with adjusted relative links. Stable
source/config/evidence paths and old phase-specific START guides retained. Added
one MATLAB_QUICKSTART and explicit review-only cleanup proposal. No changes to
existing thermal/control/solver/reference implementation or numerical results.

Implemented cloud-side committed-source dependency-closure package builder for
C42B only;explicit graph plus repository-local call check. Added MATLAB-only runner,
package hash/release/product/input checks,explicit optional official-data acquisition,
compact success/failure result ZIP with hashes/provenance/log/configuration,and
read-only recursive local storage audit. Existing C42B inspection is reused byte
for byte. Six original external CSVs52,960,350B remain outside package;rights to
redistribute unresolved. Inspection is never labelled simulation/empirical validation.
No simulated-history downsampling or new physics. Other historical simulations
retain original runners and are not silently migrated.

Returned-ZIP verifier checks paths/CRC/hashes/source objects/input identity/status;
failed receipts cannot become successful evidence. Privacy review and verified
remote archival receipt required before cleanup;no deletion code or approval is
provided. New native wrappers/audit/packaging remain unexecuted in cloud;university
R2025a acceptance gate still required. Actual PC savings cannot be measured here.

Maintenance checks completed:229 Python tests passed,3 optional plotting tests
skipped in the base environment;separate publication-plot smoke test passed with
existing optional matplotlib overlay. Ruff lint/format135 files,mypy13 modules,
archived report and14 signal-map checks passed;102 MATLAB files checked statically,
including every root runner and new utilities. Python sdist/wheel build passed.
Seven focused packaging tests exercise fresh extraction/hash closure,no raw-data
leakage,missing dependencies,unsafe paths,tampering,source-object comparison and
failed-versus-completed receipt schemas. Fixtures are software tests only,not
MATLAB execution or benchmark results. Existing C3/C4 scripts,physics configs,
reference/evidence/result files are unchanged byte-for-byte from a57a62a.

Published standalone17-file THERMA_C42B_RUN_2026-11-10.zip,67079B,source
c408225aaaaf07f3394e1646ce140b4ea3fcca0c,transfer commit
e58dd0e546c554036e54a4b4d63f39e5e172b0c4. SHA256
472d1e74bb34cc59f63a8c829c6100946dc3220d96a28740ce659e78adbf84ee.
Fresh extraction,CRC,all per-file hashes,uniform MATLAB JSON structure fields and
absence of raw datasets/models/prior outputs checked. Independent immutable HTTP
download matches uploaded bytes. Every previous transfer artifact and source
branch retained;main/work unchanged. docs/MAINTENANCE_DELIVERY.json records delivery.
Runtime C42B source metadata is trimmed to six file identities/URLs/hashes only;
source metadata hash records its derivation,with no prior measurement statistics
redistributed. New MATLAB package/runner/results/audit still require native
R2025a acceptance. No university files deleted and no cleanup approved.

## 2026-11-11 — Part A: actual C42B university inspection archived

Original THERMA_RESULTS_C42B.zip182600B,SHA256c146fd42ee036a3ac1fa487dfd411d3e1e691adb109d83de9cc36e288ec1cd9f.
Existing verifier accepts sourcec408225aaaaf07f3394e1646ce140b4ea3fcca0c,all result/
source/config/input hashes,statuscompleted_inspection,MATLAB25.1.0.2943329(R2025a).
All six required original FLEXLAB inputs match;721 complete selected minute rows
per input;no reported exception/error/warning. Both native PNGs inspected/preserved.
No simulation,empirical model validation or unit-test-suite execution is claimed;
no native MATLAB execution occurred in cloud.

Public evidence at results/C42B/c146fd42ee036a3a/:original JSONs/plots/source receipt,
input provenance,original manifest and explicitly redacted log. One private university
Output line removed only from separately named public log;original hash retained.
Unchanged original ZIP is recoverable through AES-256-GCM encryption on replay-transfer;
immutable URL/ciphertext hash in provenance. Key kept out of Git and delivered only
in private conversation;Python encrypt/decrypt round-trip and remote ciphertext
bytes verified. Native MATLAB recovery helper prepared,unexecuted. Part A is
committed/pushed before beginning Part B archival-tool implementation.

## 2026-11-11 — Part B: university historical preservation utility prepared

Part A commitf0fb2718bb138833250a0a6892ee38f2450927f6 pushed/remote-verified before
Part B implementation. Original auditJSON/CSV validated acrossall602 rows,totals
431,966,619B;291 exactGit matches,179 KEEP,100 REVIEW,32 tiny caches. All291 match
trusted preservation identities. Audited36 SLX/12,208,834B,25CSV/319,729,849B,
36FIG/83,966,502B;all16MAT files are cache metadata. No historical file bodies
received/verified independently in cloud. Three exactduplicate groups identified;
all selected paths retained. No file deletion or cleanup recommendation issued.

Conservative plan279 originals/420,811,850B includingall36 SLX;12 milestone parts
with64MiB source-byte target,plus small catalog. Native archiver streams directly
from source,hashes every original/rechecks all602 inventory entries,verifies ZIP
members and current originals,retains partials and reuses verified completed parts.
No uncompressed432MB staging copy. Conservative free-space budget446,046,747B;
user network quota may be smaller than volume report. Missing/changed/new/unreadable
sources or inadequate space block completion. No source writes,model loading,
simulation,numeric conversion/downsampling or deletion functionality.

Prepared four native software-fixture tests and a cloud returned-archive verifier;
local success is not remote backup. Actual historical archives must be returned,
verified and preserved at confirmed immutable privacy-appropriate remote locations
before a final file-by-file cleanup proposal/user approval. New native archiver/
self-tests remain unexecuted. Existing C42B runner/thermal code/parameters unchanged.

Part B checks:235 Python tests passed,3 optional plotting tests skipped;separate
publication-plot smoke passed. Ruff lint/format141 files,mypy13 modules,original
report/14 mapping integrity checks and Python build passed.114 MATLAB files passed
static lint;CI now covers root runners/native tests/tools. Six focused archival
Python tests cover actual audit/CSV/model coverage,public evidence hashes,empty/
chunked/duplicate software fixtures,changed originals despite updated outer ZIP
receipts,unsafe entries and clean toolkit extraction. Java21 stream smoke verified
five byte-boundary cases;this is explicitly NOT native MATLAB execution. Four
MATLAB archival software tests are prepared/unexecuted. No old experiment reruns.

Delivered22-file THERMA_HISTORY_ARCHIVER.zip140327B,source
8968ffa4fa396f27499a714a9336e31b2082080d,transfer commit
0f4947640bd1b509dc96a51632770403ea50bcf8. SHA256
0c46c1aaeca0708db1573614b622ad4df79c59c7798200bb89b9a44d61f8e5e1.
Fresh empty-folder extraction,CRC,all toolkit dependency hashes and exact original
audit bytes verified. Independent immutable HTTP download matches uploaded ZIP.
Previous artifacts/source branches retained. No native models,MATs,figures or
historical output bodies are included. docs/HISTORY_ARCHIVER_DELIVERY.json records
scope/native-pending/storage details. Wait for returned12 parts/catalog and verified
remote recovery before any old-installation cleanup proposal. No deletion approved.

## 2026-11-11 —80MB incremental archival update

User-provided Release archive-matlab-models-2026-11 inspected via GitHub website;
API route blocked by proxy403. Downloaded THERMA_NATIVE_MODELS_BACKUP.zip2511883B,
SHA2565fab723d165a242974ad5de3dd78fd3d95434b8720c307106b33f7e6d2eb5328.
All36 members match full original relative paths,size andSHA256;CRC checked,no
models loaded. Source model bodies not committed. Recovery URL is mutable;hashes
must be rechecked on retrieval. Public verification receipt in history_reference/.

New separate incremental entry point keeps legacy/C42B behavior intact. One ZIP
per call,<=40,000,000source bytes and hard45,000,000final ZIP cap,deflate level0;
no assumptions about compression. Large files become lossless offset/length ranges,
with original paths/full hashes and reassembly verification. New plan12 parts for
243 remaining originals;36 exact remotely verified model versions skipped. Per-part
space guard about43MB,not whole-job446MB. No second on-disk download for remote
checking:HTTPS bytes stream throughSHA256/count before remote status is recorded.
Generated catalog snapshots track each file/range/part;uploaded links alone never
qualify. A pending ZIP is reverified/reused;interrupted completed stages/finals can
resume. Failed partials retained;no deletion code. User moves only remotely verified
generated working ZIPs elsewhere before the next call. Original files untouched.

Recovery writes only a new directory and verifies each full original SHA. Remote
Release availability must be rechecked before any later cleanup;new files outside
the audited snapshot remain unreviewed. New native incremental code is unexecuted
in cloud;five native software tests prepared. No thermal physics or C4.3 work.

Incremental checks:238 Python tests passed,3 optional plotting skips;119 MATLAB
files statically linted. Ruff144 files,mypy13 modules,evidence/mapping checks and
Python build passed. New software tests cover100MB+ originals split without any
compression assumption,duplicate timestamps/CRLF/opaque bytes/empty files reassembled
with original SHA256,and actual36-model verification/243-file plan. ExistingC42B,
physics/reference code unchanged. Native incremental self-test/range/recovery/HTTPS
bindings still require university execution;no native success claimed.

Published30-file incremental toolkit169670B,source dc606708870c3f9854923ec75eaefd5c722088b7,
transfer582ce7fdba6e533bbfda8ca2ce204861411c5e67. SHA256
10c0f32b7c24ea594fcff41bc95a6bd70bf4a6de30f557dc212ec476bf999aa8.
Fresh extraction/all source hashes and independently downloaded upload verified.
Old artifacts retained. Delivery receipt docs/INCREMENTAL_HISTORY_DELIVERY.json.
No source deletion,original modifications or C4.3 work. Stop for native verification.

Final incremental revision records newly added files (such as the generated model
backup ZIP) as outside-snapshot outstanding items rather than blocking unchanged
audited originals. Missing/changed/unreadable audited originals still block.
Published r2 toolkit170028B,source33778730d741927e9561d825998af834ea486b1a,
transferce17cff496a1514bd15b42887f23d5a8b3a6e67f;SHA256
7c3732b559e04c92be8c553561017a25198454232f2ef9938dc29dece157d945.
Final238 Python tests pass (3 optional skips),CRC/fresh extraction/all dependency
hashes and uploaded SHA verified. Earlier artifacts retained. Native code remains
pending university tests;no cleanup authorization or C4.3 work.
