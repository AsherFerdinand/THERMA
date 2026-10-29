# C2.5 real replay failure diagnostics — MATLAB R2025a

## What is known

The user reports two unsuccessful long replays. The packet loaded as 60481-by-12,
C2 model generation succeeded, and the earlier eight MATLAB tests passed. The saved
exception was only MATLAB:MException:MultipleErrors / "Error due to multiple causes."
That aggregate message does **not** identify an offending block or equation.

Static inspection establishes a definite diagnostic defect: the catch discarded
`problem.stack` and `problem.cause`, then a separate status assertion replaced the
useful exception context. Therefore the available report cannot establish the
underlying Simulink failure. No original nested exception was supplied or recovered.

The most likely area is compilation/data evaluation of the eleven newly introduced
From Workspace sources. The eight earlier tests checked packet loading and C1/C2,
not compilation/execution of these new drivers. All source variables were
N-by-2 numeric time/value matrices stored in Model Workspace and simulation used
sim(model), without explicit SimulationInput bindings. Such matrices are a supported
Simulink format; their use alone does **not** prove a defect. The new diagnostic and
driver test are designed to distinguish variable resolution, dimensions, source
settings or solver errors instead of guessing from the aggregate error.

## Changes

- A recursive exception serializer preserves every node's identifier, message,
  file/function/line stack and extended MATLAB report. Every nested cause is retained
  as a JSON array, including siblings and deeper causes.
- The runner records load/configure/compile/simulate/export/completed stages and
  writes the complete failed replay_run.json **before** printing/throwing anything.
- Command Window output contains the extended diagnostic and recursively printed
  identifiers/stacks. The final THERMA:ReplayFailed exception keeps the original
  MException via addCause; the outer status assertion no longer hides it.
- simulation_returned/matlab_execution_completed are set after sim returns. An export
  failure is now distinguished from a simulation that never returned.
- Driver setup uses explicitly named scalar timeseries, validates finite data and
  interpolation policies, and binds identical data in Model Workspace and
  SimulationInput Workspace=model. Numeric [time,value] matrix interpretation is
  no longer implicit. The model remains self-contained when saved.
- Outdoor timeseries and From Workspace use linear interpolation. Held inputs use
  zoh and block Interpolate=off. SampleTime=0 and ZeroCross=on are explicit. Duplicate
  held timestamps retain the rightmost value; continuous duplicate-time jumps are
  rejected. Each driver records its class, sample/data sizes, coverage, values,
  workspace and settings in the JSON.
- Simulation starts explicitly at relative time zero and preserves the packet stop
  time, solver/tolerances and seven-day warm-up/evaluation boundaries.

C1/C2 thermal physics, frozen registry, assumptions, transfer ZIP and verification
budgets are unchanged. This patch improves diagnostics and makes source data binding
explicit; it does **not** establish that the university failure is resolved. MATLAB
is unavailable in Codex. No C2.6 development is included.

## Fast local reproduction before the long replay

Download/extract the updated work source. Keep the existing replay data ZIP/packet;
there is no need to redownload its data. Save/close any old generated C2 or test model.
In MATLAB R2025a from the THERMA root:

```matlab
addpath(fullfile(pwd,'scripts','matlab','boptest'));
results = runtests('tests/matlab/test_boptest_replay_diagnostics.m');
assertSuccess(results);
```

These new tests serialize a real captured exception with nested/sibling causes and
round-trip it through JSON. A small **two-second driver-only model** then compiles
and executes all eleven sources, checking actual linear outdoor values and held
heating values. Another intentionally invalid source tests preservation of Simulink
variable/block diagnostics. This is a source/interface regression, not a thermal
reference simulation. The fixture uses no base-workspace replay variables.

If they pass, run the full MATLAB suite if desired, then the real partial replay:

```matlab
results = runtests('tests/matlab');
assertSuccess(results);
packet = fullfile(pwd,'outputs','boptest','replay_inputs','first_typical','replay.json');
assumptions = fullfile(pwd,'configs','references','c2_reduced_assumptions.json');
reportFile = run_boptest_zone_replay(packet,assumptions,'AllowPartial',true);
disp(reportFile);
```

On failure, the Command Window prints the full report path **before** throwing.
Upload that replay_run.json and the complete Command Window diagnostic. Inspect
`stage`, `drivers`, `solver`, `error.stack`, `error.causes` and each nested cause's
extended_report. Failure report filenames remain under unique ignored
outputs/boptest/replays/<run>/ directories. The successful original C2 ten-scenario
report remains untouched and does not verify these new tests/long replay.

After a successful partial run return evaluation.csv, comparison_metadata.json and
replay_run.json for the first exploratory comparison. C2.6 remains blocked until the
replay execution problem is resolved.
