# C2.7 — Controlled benchmark verification and numerical convergence

R2024a export update: [scoped event-export fix/package](C27_EVENT_EXPORT_FIX.md).
The original package below remains archived; use the updated package for the reported
UNC event-writer failure. Original full C2.7 execution remains pending.

## Executive summary and current evidence

C2.7 prepares a same-release no-solar/solar control and maximum-step refinement
study. **No C2.7 MATLAB experiment has been executed in Codex Cloud.** Temperature,
runtime and convergence results remain pending university MATLAB execution. The
source, input integrity, numerical analysis and transfer packaging can be checked
here; they cannot establish Simulink runtime compatibility or convergence.

The preserved C2.6C comparison measured MAE 2.340532 → 0.792534 K and RMSE
2.805500 → 0.923976 K, with bias −2.335196 → −0.450613 K. The baseline ran on
R2025a and the solar experiment on R2021a. That cross-release comparison is not
reused as a same-release control. Its actual results, 14/14 user-reported MATLAB
tests and scientific limits remain in [C26C_ENGINEERING_REPORT.md](C26C_ENGINEERING_REPORT.md).

## Objective and repository inspection

Close the release/control and numerical-sensitivity gap before C3 implementation.
Reuse, rather than rewrite, these existing pieces:

| Existing component | C2.7 use / finding |
|---|---|
| build_boptest_zone_c2.m, add_boptest_construction.m | Unchanged generated 28-state model |
| Frozen BOPTEST registry and c2_reduced_assumptions.json | Unchanged material parameters and provisional air/surface assumptions |
| Original C2.5 schema v1 replay | Exact preserved no-solar CSV and metadata from first transfer archive |
| C2.6 schema v2 replay | Exact verified solar packet, including seven-surface/source provenance |
| configure_boptest_replay_sources.m | Unchanged mixed linear/hold policies and final-value holding |
| run_boptest_zone_replay.m | Extended orchestration, timing, optional retention, smoke and ordered event export |
| MATLAB tests and recursive exceptions | Reused; resume-corruption regression added |
| therma.validation.benchmark / analysis | Reused native-grid temperature metrics, daily errors, figures and sampled closure |
| therma.validation.study | New strict four-experiment receipt/identity validation and convergence comparison |

R2021a already executed the previous runner successfully. New code uses existing
arguments blocks, timeseries, tables, onCleanup, jsonencode/jsondecode and ordinary
sequential loops. MISS_HIT performs static syntax checks only. The known MATLAB
JSON field-name/null round-trip behavior remains accounted for in analysis. R2025a
compatibility is retained by avoiding release-specific newer APIs, but new C2.7
execution is pending on both releases. All experiments in one analyzed study must
use exactly the same MATLAB and Simulink versions.

## Model architecture and reference building

Reference: pinned BOPTEST BESTEST Hydronic / heavyweight BESTEST Case 900. The
frozen registry specifies an 8 m × 6 m × 2.7 m zone, 48 m² floor, 129.6 m³ air
volume and 12 m² south-facing window. Source pins/hashes are unchanged from C2.6.
The reference includes multilayer opaque fabric, dynamic glazing, moist air,
weather/radiation, infiltration and controlled hydronic equipment.

THERMA C2 retains 27 unique opaque temperature states and one dry-air state.
Prescribed radiator powers enter separate convective/radiative ports. The other
inputs are outdoor temperature, two internal gains and six absorbed opaque solar
powers in south/north/east/west/roof/floor order. Glazing's seventh solar share
remains separate; it is not redistributed to opaque fabric or air.

## Thermal equations and unchanged assumptions

For each capacitive node, `C_i * dT_i/dt = sum(Q_into_i)`, with conductive paths
`Q = G*(T_upstream - T_downstream)`. The air balance sums prescribed convective
heating/gains, sensible infiltration and static window exchange, subtracting air-to-
surface convection. Radiative heating/gains are distributed to opaque surfaces;
interior reciprocal radiation cancels in the whole-zone sum. Source-specified
layer conductivities, thicknesses, densities and specific heats remain frozen.

Reduced assumptions remain explicitly provisional: constant dry-air rho/cp,
constant surface convection and linearized opaque radiation, static window UA,
reduced exterior boundary and prescribed radiator heat. The C2 floor's exterior
boundary is adiabatic. Relative stored energy uses the unchanged 293.15 K datum;
negative storage values are permitted. No calibration or equation/material change
is part of C2.7. See [BOPTEST_SIMULINK_C2.md](BOPTEST_SIMULINK_C2.md).

## Controlled experiment design

Plan: configs/references/c27_study.json. Both original packet files are hashed.
The MATLAB workflow requires exact equality of timestamps/first five channels,
initial vector, warm-up/evaluation bounds, and all six no-solar inputs equal zero.
Each experiment initializes afresh; no prior experiment state or serialized restart
is reused. All retain seven-day warm-up and fourteen-day evaluation.

| ID | Packet | Maximum solver step | Solver / tolerances | Actual result |
|---|---|---:|---|---|
| no_solar_30 | Original v1 no-solar | 30 s | ode15s, RelTol 1e-7, AbsTol 1e-9 | Pending |
| solar_30 | Verified v2 solar | 30 s | Same | Pending |
| solar_15 | Same solar file | 15 s | Same | Pending |
| solar_5 | Same solar file | 5 s | Same | Pending |

Maximum step is a cap on adaptive integration, not the 30 s input measurement
interval or a fixed integration step. Unknown sub-30-second source events are not
reconstructed. Smaller maximum steps do not automatically prove convergence.

## Offline Windows package and execution

[Download THERMA_C27_MATLAB_R2021a_2026-11-03.zip](https://github.com/AsherFerdinand/THERMA/raw/refs/heads/replay-transfer/THERMA_C27_MATLAB_R2021a_2026-11-03.zip)

Extract All to a short writable local path, open MATLAB R2021a with Simulink and
Java enabled, and set Current Folder to the extracted THERMA_C27_MATLAB folder.
The package needs no internet, Git, Python, Docker, FMU runtime or Simscape.
The exact builders generate the real .slx model on the university PC; no prebuilt
SLX or cloud MATLAB execution is claimed.

```matlab
run_verification("quick")   % checksums, all MATLAB tests, model build and 600 s smoke
run_verification("full")    % tests, then four full experiments sequentially
```

Quick mode is not a 14-day benchmark and cannot be accepted by the benchmark loader.
Its report is labeled executed_smoke_not_benchmark. It uses the original packet's
start and inputs with a shorter requested stop; it does not change physical states.

Full mode releases each simulation/model before starting the next. By default it
saves evaluation CSV, ordered energy events, comparison/replay/solver JSON and model
SLX, but omits large simulation.mat/full trajectory. To retain both, accepting the
additional disk cost:

```matlab
run_verification("full",'SaveSimulation',true,'SaveTrajectory',true)
```

Each attempt gets a new folder. Never edit package inputs or overwrite prior outputs.
Re-running full mode skips only completed runs whose receipt, every exported file,
packet, step, code/configuration contract and execution environment still match.
Corrupt/incomplete attempts remain on disk and are rerun in a fresh folder. Changing
retention options or code changes the contract and requires fresh attempts. To force
fresh experiments explicitly, use `run_verification("full",'Resume',false)`.

Tests and session diary go to outputs/boptest/c27/<session>/. Experiments are under
outputs/boptest/c27/<experiment-id>/<attempt>/. The final study_index.json in the
session folder records portable relative experiment paths and receipt hashes. A
failure preserves recursive diagnostics and stops the sequential study. Simulation
wall time is measured around sim(), not fabricated or estimated. Larger output/data
arrays are local to each runner call, not retained in a four-run workspace.

## Export and numerical convergence methodology

Each full run exports evaluation.csv, comparison_metadata.json, replay_run.json,
solver_metadata.json and energy_events.csv. Metadata records actual versions,
solver/tolerances/step, status/period, measured sim() wall time, model/parameter/input
hashes and retention policy. Optional MAT/trajectory retention is explicit. Completed
receipts hash every retained artifact, including solver metadata and generated SLX.

After university execution, transfer the whole outputs/boptest/c27 tree (session
index/contract plus the four referenced attempt folders) back for cloud analysis.
The Windows computer does not perform the Python stage. Do not send only the index
without its referenced folders. Preserve optional large MAT files locally if needed.

```sh
uv run --frozen --with matplotlib==3.10.8 python -m therma.validation.study \
  --study-index outputs/boptest/c27/SESSION/study_index.json \
  --reference outputs/boptest/solar_runs/typical_heat_day_u7x05kpz \
  --output outputs/boptest/analysis/NEW_C27_STUDY
```

Analysis rejects incomplete/corrupt exports, mixed releases/parameters/tolerances,
wrong steps, differing solar packets and incompatible reference identity. Temperature
MAE/RMSE/maximum/bias and daily MAE all use the same 40,321 native reference timestamps,
with continuous candidate temperature interpolated linearly and no extrapolation.
Warm-up is excluded. Solver differences are measured for 30−15, 30−5 and 15−5 s;
5 s is another approximation, not ground truth. An order of convergence or accuracy
pass is not inferred from three adaptive step caps.

## Energy conservation and stability diagnostics

The whole-zone derivative identity is `dE/dt = Qnet + residual`. The existing C2
logs supply both sides. New energy_events.csv preserves original ordered timestamps
and duplicate event records **before** unique-time CSV reduction. Trapezoidal
integration assigns zero width to duplicate-time jumps, retaining event left/right
sides where logged. If the solver did not log both sides, they are not invented.

Report instantaneous residual, derivative accounting, storage change and integrated
net-energy discrepancy with the explicit method. Existing ordinary CSV hold-integral
diagnostics remain available alongside ordered-event quadrature. These contain
logging/quadrature/solver error; neither a tiny algebraic residual nor a smaller step
proves conservation or reference accuracy. Finite successful full-period outputs are
limited stability evidence, not a mathematical stability proof. Simulation runtimes
exclude separate explicit build/compile/export and depend on workstation load.

## Figure outputs (actual data required)

The analysis generates 300-dpi PNG and vector PDF pairs:

1. Indoor temperature: BOPTEST, same-release no-solar and solar-30.
2. Signed temperature error: no-solar and solar-30 on the native reference grid.
3. Solver refinement: solar-30 minus solar-5 and solar-15 minus solar-5.
4. Daily MAE/bias: same-release control comparison across all 14 days.
5. Storage change, integrated net power and event-log closure discrepancies.
6. Prescribed radiator, absorbed opaque solar and internal gains.

No C2.7 plot or measured table is populated from synthetic unit tests or relabeled
C2.6 results. study_metrics.json contains actual measurements only after four valid
exports are supplied. Automated synthetic fixtures check contracts and plotting
capability in temporary test directories; they are not physical evidence.

## Engineering conclusions, limitations and C3 gate

- Software verification: Python tests, export/integrity contracts and static MATLAB
  checks can be executed here; new MATLAB unit/smoke/full runs remain pending.
- Numerical convergence: requires actual controlled refinements and documented
  temperature/energy/runtime sensitivity. No result or pass exists yet.
- Simulation benchmarking: compares a reduced model to pinned Modelica/FMU, with
  acknowledged glazing/exterior/moist-air differences. It is not field validation.
- Real-world validation: no real-building measurements have been supplied.

C3 implementation remains blocked until the same-release control/refinements are
executed and analyzed, and an evidence-based numerical acceptance budget is reviewed.
Any residual physics extension must be justified separately without tuning to hide
missing boundaries. The design-only [C3 architecture plan](C3_HYDRONIC_ARCHITECTURE_PLAN.md)
compares implementation choices without implementing a hydronic component.
