# C4.0 — Residential heating-system workbench

**Implementation ready; native SLX generation, layout inspection and C3.7
reproduction are pending.** MATLAB/Simulink is unavailable in cloud. The supplied
entry point generates `THERMA_C40_HeatingSystem.slx` on the university PC; no
unexecuted/fabricated binary or simulation result is supplied as verified evidence.
C3.7/C3.8/C3.9 successful R2025a execution is user-reported.

## Follow the system left to right

- **Room Thermostat:** existing sampled1K total hysteresis around21°C, ON at/below
  20.5°C, OFF at/above21.5°C. Indoor-air feedback is explicitly labelled.
- **Control Valve:** unchanged opening/closing dynamics; opening drives the
  radiator's existing nominal-flow multiplier, not a new pressure network.
- **Hydronic Radiator:** existing Purmo-calibrated linear water/metal storage;
  separate convective/radiative heat signals enter the building, without double counting.
- **Building Thermal Zone:** the original C3.7 multilayer residential model,
  including adjacent-room boundaries, surface exchanges and thermal storage.

These are the **four physical subsystems**. One additional collapsed **Results
and checks** utility contains the existing logging/energy diagnostics, with no
new heat-transfer equations. Supply, outdoor conditions, setpoint, zero gains and
thermal-input mux remain visible. The wrapper renames/repositions/groups the
existing blocks; it does not reimplement their physics or alter solver settings.
Temperature signals are K, heat W; the result plot displays°C.

Unchanged scenario:20m²/50m³,15°C initial air/radiator,20°C fabric,0°C outdoors,
21°C adjacent rooms/setpoint,1.0K total deadband,55°C supply,24h. UA34.56W/K,
nominal flow0.02066985646kg/s. The original Purmo mass-inclusion assumption,
6.6kg water+24.756kg effective metal/39,966J/K, remains unchanged. No boiler,
pump, new controller, weather profile or recalibration is introduced.

## Run and check

Extract the small update into the existing `THERMA_C35_MATLAB` folder containing
the C3.7 Purmo and C3.8 updates. Keep the original C3.7 result, CSV and generated
model together under `outputs/c3/c37/<run>/`. Save/close open generated models.
MATLAB R2025a:

```matlab
results = runtests(fullfile('tests','matlab','test_therma_c40.m'));
assertSuccess(results);
folder = run_c40_heating_system;
```

If several baselines exist, pass the desired original run folder:
`run_c40_heating_system(fullfile('outputs','c3','c37','YOUR_RUN'))`.
The existing C3.8 reader verifies original hashes, release, parameters and physical
checks. Missing/incompatible baseline data stops the run; it does not fabricate
one from reported scalar results or rerun it. A copy is built/opened, and **one24h
C4.0 simulation** is performed. The model and the single temperature/power figure
remain open. New files stay in the printed `outputs/c4/c40/<run>/` directory:
SLX, `trajectory.csv`, `verification.json`, `heating_system.png`.

Existing energy, hysteresis, valve, state and power checks must pass. Air/power are
compared on the complete10s controller grid, with post-event demands compared
without interpolation. Fixed presentation-regression tolerances are **0.001K**,
**0.5W**, **0.001kWh**, plus identical demand at every tick and identical transition
counts. These are declared software acceptance limits, not physical-accuracy
ratings or measured convergence tolerances; they are not loosened after failure.
Old sources/configuration and selected baseline artifacts are hash-checked unchanged.
Send `verification.json` and the one PNG back for review.

The two small MATLAB SOFTWARE comparator tests remain unexecuted here. A failed
comparison writes diagnostics and does not mark reproduction passed.

## Remaining limits

This demonstrates the existing reduced model, not a validated complete heating
plant: imposed55°C supply/nominal flow, linear radiator, air-as-radiant-sink proxy,
uncertain effective metal mass, fixed surface films and approximate adjacent-slab
symmetry remain. Only one manufacturer operating point is matched. No next phase
has been started.

<!-- C40_RESULTS -->

No C4.0 native result exists in cloud. Whether the wrapper reproduces the original
C3.7 trajectory, power, switching and energy is pending the actual university run.
