# C3.8 — Thermostat hysteresis comparison

**Implementation prepared; native MATLAB comparison pending.** User reports
successful C3.7 R2025a execution: first21°C at0.310h,62 full-day transitions,
10.215kWh delivered over24h, maximum21.754°C, numerical/controller checks passed.
Those are user-reported figures, not an archived execution log. The actual C3.7
trajectory is not in this cloud workspace; no2–24h metrics are inferred from
full-day summary numbers.

Compare only **total deadband1.0°C versus0.5°C**, setpoint21°C. The existing
sampled thermostat switches ON at/below20.5 or20.75°C, OFF at/above21.5 or21.25°C,
retaining state between thresholds. Inclusive equality and10s sampling are unchanged.
Room20m²/50m³,15°C initial air,20°C fabric,0°C outdoors, adjacent rooms21°C,
55°C supply, Purmo radiator/flow/capacitance, valve and solver all stay unchanged.
The C3.7 radiator mass interpretation remains an explicit assumption.

## Method and outputs

Primary comparison uses **hours2–24** for both cases: time-weighted mean, min/max,
time-weighted MAE from21°C, transitions, and delivered heating energy. Means/MAE
use piecewise-linear temperatures; adaptive solver sample density does not weight
the result. Duplicate timestamps have zero duration. Temperature extrema are from
the logged piecewise-linear trace. Switching events in **(2h,24h]** are counted,
so an event exactly at2h is excluded. Energy is the difference of native cumulative
energy states at interval endpoints; full-day0–24h energy is a separate reference.
No boiler or pump efficiency is modeled: lower delivered heat does not establish
higher whole-system efficiency. Energy differences can also reflect different
mean temperatures or final stored heat. Finite radiator storage and valve response can
cause temperatures to overshoot the nominal thresholds.

Only two PNGs show **hours2–8**: both indoor-temperature curves/setpoint, and both
thermostat demand traces. A compact table and conditional recommendation are
written below only after successful actual execution. No narrow-band benefit or
additional switching is claimed in advance of those results.

## University MATLAB R2025a

Extract the update into the existing `THERMA_C35_MATLAB` folder containing the
C3.7 Purmo update. Keep `outputs/c3/c37/` intact. Save/close open generated models.

```matlab
results = runtests(fullfile('tests','matlab','test_therma_c38.m'));
assertSuccess(results);
folder = run_c38_thermostat_comparison;
```

It searches `outputs/c3/c37/*/residential_result.json`. Reuse requires the original
result, hashed CSV and hashed generated `THERMA_C37_Residential.slx`, same MATLAB
version, room configuration and effective radiator/controller parameters. It
rechecks native energy, hysteresis, valve and power diagnostics from the CSV.
The modified model is a copy of that saved model, with only `C3.deadband_K`
changed. Workspace, solver and initialization compatibility are checked before
simulation. Original result/CSV/model and previous source/config bytes are checked
unchanged afterward. Compatible data means **only one new simulation**.

If no complete compatible C3.7 result exists, it prints the reason and runs one
baseline under `outputs/c3/c38/`, then copies that model for the modified case:
**two simulations total**, no sweep. It does not invoke the C3.7 runner or overwrite
C3.7 results/report. Multiple distinct compatible baselines require an explicit folder:

```matlab
folder = run_c38_thermostat_comparison(fullfile('outputs','c3','c37','YOUR_RUN'));
```

Explicit incompatible inputs produce an error. Outputs under the printed C3.8
folder include `comparison.json`, the two PNGs and new-case trajectories/checks.
Please transfer `comparison.json` and the two PNGs for result review. MATLAB is
unavailable in cloud, so even the two small synthetic SOFTWARE metric tests remain
unexecuted there; they are not simulated benchmark evidence. C3.9 has not started.

<!-- C38_RESULTS -->

| Total deadband | Mean/min/max | MAE | Switches2–24h | Heat2–24h | Heat0–24h |
|---|---|---|---|---|---|
|1.0°C|Pending actual trajectory analysis|Pending|Pending|Pending|10.215kWh user-reported|
|0.5°C|Pending native run|Pending|Pending|Pending|Pending|

Recommendation pending actual regulation/switching trade-off. Implementation
readiness does not mark C3.8 complete: both MATLAB results and checks are required.
