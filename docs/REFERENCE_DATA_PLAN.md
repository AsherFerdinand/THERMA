# Reference simulation and export plan — Phase 1A

Status: proposed contract, not existing datasets or implemented MATLAB automation.
Source findings and unresolved signal paths are in [SIMULINK_INVENTORY.md](SIMULINK_INVENTORY.md).
No simulation results have been generated or validated in this phase.

## Reproducible MATLAB workflow (design only)

1. Pin the thesis Git commit and SLX SHA-256 in the inventory. Verify the originals and
   work in a separate run directory/copy; check hashes again after execution. Review
   model callbacks before loading. Record MATLAB release/update and required products.
2. Load a working copy and compile it without saving changes to the reference. Export
   effective workspace values, masks, units, active graph, initial states and resolved
   solver/local-solver settings. Confirm room vector order and dimensioned actuator path.
3. Define explicit scenario manifests for `uncontrolled`, `local_thermostat` and
   `supervisory_local`. Confirm the actual historic implementation for each. A saved
   manual switch is not evidence of all three configurations. If the original local
   controller is missing, stop scenario replication rather than silently replacing it.
4. Once paths/parameter scopes are known, use `Simulink.SimulationInput` variable and
   block/model parameter overrides for each run, preserving identical physical settings,
   environmental inputs and initial conditions across scenarios. Use the correct model
   workspace scope; do not rely on a dirty interactive base workspace. Start sequentially
   with `sim`; parallelism and `parsim` are optional future optimisations.
5. Enable required signal/Simscape logging on the working copy or through supported
   runtime overrides; do not save instrumentation into the original. Inspect warnings,
   actual stop time and termination status. A failed/truncated run cannot be a baseline.
6. Retain native time-series and metadata, then create a separate aligned Python-readable
   view. Record every transformation. Close without saving and verify original hashes.

No automation `.m` script is added until the inventory's model questions are resolved.
In particular confirm the switch setting, local hysteresis, controller timing, 33/36
actuation mapping, temperature conversions, valve opening units, source power units,
fluid model and whether the reference horizon is 7,200 or 10,800 s.

## Signal contract

Names below are **proposed canonical exports**, not claims about existing logsout fields.
A signal registry must map each to model path/SID, physical port or logged variable,
original name, vector index, stable room/branch ID, native unit, conversion, shape,
sample semantics and logging mechanism. Preserve original names alongside canonical ones.

| Proposed signal | SI unit | Source evidence / availability |
|---|---|---|
| `time` | s | Solver time; preserve native sample vectors per signal. |
| `room_temperature[room_id]` | K | `TroomEG`, `TroomOG1`, `TroomOG2`, `TroomArray` tags; representative sensor converter produces °C. |
| `outdoor_temperature[floor_id]` | K | Each floor's `Tatm` source; root `Tatm12` is a separate scope input and must not be assumed to drive floors. |
| `setpoint_temperature[room_id]` | K | `TdesiredArray`; retain the actual schedule/vector, not a uniform 20°C substitution. |
| `supervisory_mean_temperature` | K | `Tavg`; NaN when the heating subset is empty. Preserve validity flag/reason. |
| `valve_command[actuator_id]` | 1 | Embedded MATLAB Function output, before gain/filter; 0/1 semantics. |
| `valve_opening[actuator_id]` | m, if confirmed | Filtered physical opening; converter/unit chain remains unresolved. Do not label scaled `ValveSignal` as dimensionless without verification. |
| `local_thermostat_state[actuator_id]` | 1 | Pending discovery of actual local controller; not currently established. |
| `radiator_inlet_temperature`, `radiator_outlet_temperature` | K | Requires mapping/logging pipe ports/internal state; not exported as raw data in source. |
| `radiator_heat_to_room` | W | Requires thermal-port logging, sign convention positive into room. |
| `branch_mass_flow` | kg/s | Requires Simscape logging/measurement and orientation registry. |
| `branch_inlet_pressure`, `branch_outlet_pressure` | Pa | Requires Simscape logging, reference convention absolute/gauge. |
| `supply_temperature`, `return_temperature`, `tank_temperature` | K | Root `Tboiler` exists but its transformed unit must be traced; distinguish tank from supply/return. |
| `source_heat_rate`, `pump_power` | W | Requested diagnostics; active availability and source power unit chain pending. |

For SI conversion, °C to K adds 273.15; temperature **differences** retain their numeric
value in K. Convert lpm to m³/s by dividing by 60,000; convert kW to W by multiplying by
1,000; MPa to Pa by 1,000,000. Mass flow cannot be obtained from volume flow without
consistent fluid density. Record conversion and direction, not just a column label.

## Storage and alignment

Proposed run layout (under ignored local `data/raw/`, not committed by default):
`<run_id>/manifest.json`, `signals.csv`, `signal_registry.json`, and native MATLAB result
file(s) for later inspection. Keep processed aligned tables separately in
`data/processed/<run_id>/`. Choose MATLAB MAT format/version on the execution machine;
SciPy cannot directly read all v7.3/HDF5 structures. CSV plus JSON is the required
portable interchange, avoiding a new Python dependency now.

Native CSV may be long-form: `signal_id, entity_id, time_s, value, valid`, with explicit
registry units and mapping. Retain full floating-point precision and event duplicates
using a sequence/side field where needed. Do not overwrite native samples with a
resampled table. Store missing/NaN values with validity/reason metadata; never coerce
undefined controller mean or unavailable flow to zero.

Agree an output grid from the fastest relevant dynamics and control/event sampling;
no arbitrary fixed interval is prescribed yet. Continuous-state interpolation must
respect discontinuities; use zero-order hold for discrete commands and preserve both
sides of switching events. Interpolate only within each signal's valid time range.
Check timestamp monotonicity (allow documented duplicate event times), dimensions,
coverage, NaNs, units and termination status before creating aligned results.

## Run metadata and evaluation

Every manifest records schema version, unique run ID, source commit/hash, working-copy
hash and changes, export script version, UTC timestamp, MATLAB/toolbox versions,
platform, simulation mode, scenario and exact override list, full resolved parameter
values/units, initial states, boundary histories, room/actuator order, solver type,
tolerances, step limits, local solver settings, controller timing, logging/decimation,
requested/actual horizon, warnings/errors, wall-clock timing and file checksums.
Use hashes/paths for large parameter histories; never include license credentials.

For each run, distinguish successful, failed, terminated and partially exported states.
Validate mass/energy balance when measurements permit; do not infer conservation from
smooth temperature curves. Keep raw reference output immutable and version transforms.

Warm-up metrics must state whether the threshold is the historical common 293.15 K
(20°C) or each room's actual target. The saved -5/15/20/24°C vector makes these distinct
experiments. Record first-passage rule, interpolation and unreached/censored rooms.
Calculate earliest/latest/spread only over an explicitly stated eligible population;
report missing crossings. Temperature spread is max minus min over the declared room
set at a common time. Screenshots and source narrative are not quantitative ground truth.

Preserve complete runs as groups for future train/validation/test splits; do not
randomly split adjacent timestamps from the same trajectory. Vary configurations only
with documented provenance and keep out-of-range cases identifiable. No ML dataset
or performance comparison is claimed here.
