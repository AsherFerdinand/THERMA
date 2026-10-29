# C2 step-input debugging — 2026-10-29

## Evidence and diagnosis

The user reports C2 generated and ran on R2025a, with five constant-input scenarios
passing and five step scenarios failing. Reported errors were heating/shutdown ~1.38 K,
outdoor ~8.83 K, internal gains ~0.29 K and solar ~0.14 K. The full JSON/CSV traces
were not supplied; no corrected MATLAB run has occurred in Codex.

Tracing `heating_step` end-to-end:

1. `boptest_zone_scenarios` specifies `[0,0]` convective/radiative heating until
   3600 s and `[650,350]` W thereafter, through 7200 s.
2. `runCase` sets a timeseries interpolation method to zoh, but the generated
   root Inport previously left **its own** Interpolate parameter unspecified.
   The generated model therefore did not explicitly enforce the intended hold
   reconstruction at the external-input boundary.
3. Root selectors route channels 2/3 to convective/radiative heating, 4/5 to
   internal gains, 6:11 to absorbed solar and 1 to outdoors. Static inspection
   found this mapping consistent with B and the documented interface.
4. The original analytical propagator already split intervals at scenario times
   and used the preceding hold over each interval. It did not apply the final
   input over the entire run. The new standalone helper retains that algorithm
   and makes it directly testable on elementary linear systems.
5. A default linearly interpolated root input would ramp during 0–3600 s, whereas
   the reference remains at its pre-step value. This produces a trajectory error
   before the event, not merely a disagreement at one exact event sample.

Quantitative diagnostic example at 3599 s, computed from the scenario definition:

| Input | Difference between a ramp and prescribed hold |
|---|---:|
| Heating step/shutdown | 999.722 W |
| Internal gain step | 299.917 W |
| Absorbed solar sum step | 209.942 W |
| Outdoor step, through infiltration H=21.7296 W/K | 217.236 W |

These fit the reported magnitudes. This identifies an uncontrolled interpolation
setting and a strong explanation for the failure pattern; it is **not** a measured
reconstruction of the university waveform. Confirm with the new logged input traces.
Small power-balance residuals do not disprove this: a model can conserve energy under
the wrong forcing. A boundary-only left/right discrepancy likewise cannot explain
large errors developed throughout a preceding ramp interval.

## Correction and verification safeguards

- The root `Inputs` Inport now explicitly sets `Interpolate='off'`, and the verifier
  asserts it. The timeseries also keeps its zoh policy.
- `Log_inputs_used` records all 11 actual root channels. CSVs append those channels,
  and separate `_inputs_raw.csv` files preserve input samples including duplicate
  event timestamps. Accounting checks use the actual model inputs.
- Independently compare actual inputs with the prescribed schedule. An incorrect
  waveform cannot pass by being reused as the analytical reference. All channels,
  including individual solar powers, are checked at floating roundoff scale.
- Right-continuous holds define the experiment. At an exact event timestamp, an
  output log may contain a left or right one-sided sample. Accept a complete valid
  limit vector only; a partial mix or intermediate ramp vector still fails. Only
  event timestamps within 64 ULPs are classified this way; no time interval is dropped.
- Duplicate state-output samples retain the last logged record. Raw input logs are
  preserved, never averaged. Reports expose duplicate counts and event-side values.
- Additional output times request scenario events explicitly. This is a logging aid;
  it is not a substitute for disabling root input interpolation.

No temperature, power, energy or convergence tolerance was relaxed. C1 scripts,
physical equations, assumptions, registry values and state-space A/B are unchanged.

## Piecewise reference and energy handling

`boptest_piecewise_reference` propagates each constant-input segment with a matrix
exponential, carries state continuously through every change, and applies the new
input only after the event. Initial/final events, repeated event/output times and
non-grid-aligned changes are covered by MATLAB regression tests.

For total-system power, `qnet = (C'*A)*x + (C'*B)*u` in offset coordinates. The
state-dependent first term is continuous; the second contains prescribed jumps.
The updated energy check subtracts the logged direct-input term before numerical
quadrature, integrates the prescribed hold contribution exactly by segment, and
reports the remaining continuous-response quadrature bias independently. Old raw
trapezoidal residual fields remain for comparison; corrected energy metrics now use
the piecewise treatment. Energy gates and refinement budgets remain unchanged.

New diagnostics include expected/actual input limits and their sample times,
per-channel input errors, accounting/ventilation errors away from exact events,
temperature errors before/after each step, piecewise energy residuals and the
existing coarse/refined solver metrics. Missing pre/post samples at initial/final
events are recorded as empty, not fabricated or extrapolated.

## Regression coverage and local commands

Python tests guard the Inport setting, logging route, all selector mappings and the
use of both actual/prescribed inputs. Analytical synthetic input examples demonstrate
ramp-versus-hold differences for all five failed scenarios. These are static/input
checks, not Simulink execution or a Python thermal engine.

`tests/matlab/test_boptest_step_inputs.m` covers every scenario's hold values and
integrals, shutdown, heating, outdoor/internal/solar changes, explicit initial/final
steps, non-grid-aligned times, duplicate event/output timestamps, left/right limits,
state continuity, rejection of ramps/mixed limits, and generated Inport/selector
settings. The full C2 runner still executes all ten scenarios with both solver settings.

Download the updated **work** branch and save/close any old generated C2 model.
Rebuild; existing saved models retain their old input configuration.

```matlab
cd('C:\YOUR\PATH\THERMA'); % use your actual root
addpath(fullfile(pwd,'scripts','matlab','boptest'));
results = runtests('tests/matlab');
assertSuccess(results);
assumptions = fullfile(pwd,'configs','references','c2_reduced_assumptions.json');
reportFile = verify_boptest_zone_c2(assumptions);
report = jsondecode(fileread(reportFile));
disp(report.status);
```

Return `verification.json` plus coarse/refined CSVs and `_inputs_raw.csv` for any
failure. Check `input_interpolation`, `input_diagnostics`, before/after temperature
errors and solver refinement before attributing remaining errors to physics.
MATLAB/Simulink are unavailable in Codex: the reported five failures are **not yet
confirmed resolved**. No force-push, main merge or physical-reference change is needed.
