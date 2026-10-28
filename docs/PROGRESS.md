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
