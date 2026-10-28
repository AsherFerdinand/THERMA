# A separate one-room MATLAB/Simulink reference

Requested scope: a small model built directly as Simulink blocks, with an **EN 12831
heating-load basis**. This is a new simplified benchmark, not an extracted thesis model,
not a reconstruction of its missing control scenarios, and not a certified calculation.
MATLAB execution is not available in cloud; the builder has been syntax-checked only.
The original thesis diagnostic workflow and Phase 1B.2 gate remain unchanged.

## What it does

`build_room_heating_model.m` creates two understandable subsystems, `Room` and `Radiator`,
a thermostat and an ideal valve represented by prescribed flow. MATLAB plus Simulink
is sufficient; no Simscape or third-party MATLAB toolbox is needed.

The blocks implement these deliberately simplified conservation equations:

- `C_room * dT_room/dt = Q_rad - G_loss * (T_room - T_outdoor)`
- `C_rad * dT_rad/dt = m_dot * cp * (T_supply - T_rad) - Q_rad`
- `Q_rad = UA * (T_rad - T_room)`
- `m_dot = valve_command * open_flow`

Temperatures are K, capacities J/K, conductances W/K, heat rates W, mass flow kg/s,
specific heat J/(kg K), time s. The same `Q_rad` is subtracted from radiator storage
and added to room storage, so it cancels from the combined energy balance. The remaining
terms are supply/return advective energy and heat loss to the environment. Closed flow
stops advection, not residual radiator heat release. Negative radiator heat transfer is
allowed when the radiator is colder than the room; it is not silently clamped.

Room capacity is an effective air/fabric lump. Radiator capacity represents mixed water
and metal at one temperature; outlet water is approximated by `T_rad`. No pipe transport,
pressure-drop solution, pump dynamics, boiler storage or radiator nonlinear rating law
is implemented. The ideal valve sets a measured/design flow; it does not solve hydraulics.
Supply and outdoor temperatures are constant for this initial benchmark.

The thermostat opens below `setpoint - deadband/2` and closes above
`setpoint + deadband/2`, retaining state between thresholds. Initial room temperature
must be strictly outside the band to avoid an unspecified initial relay state. Threshold
crossing semantics still need checking in MATLAB. This is a new thermostat, not the
thesis controller or evidence about its historic local-only scenario.

## How EN 12831 is used, and its limits

EN 12831 concerns **design heating load**; it does not by itself define this dynamic
room/radiator solver. The applicable edition and country-specific rules, design climate,
room use, geometry, U-values, thermal bridges, ground/adjacent-space conditions and
ventilation assumptions must come from a checked calculation.

This builder does **not implement the standard**. Supply the separately calculated
room transmission and ventilation losses, excluding any separate reheating allowance.
It derives an equivalent outdoor conductance:

`G_loss = (design_transmission_loss + design_ventilation_loss) / (design_indoor - design_outdoor)`

This matches the supplied sum **at the design temperature difference only**. Collapsing
adjacent-room, ground and other boundary paths into one outdoor conductance is a dynamic
model reduction, not an EN 12831 rule or proof of compliance away from that point.
Do not add a reheating allowance as continuous heat loss. Record it separately in the
external design calculation if required. More detailed boundary nodes are needed if
that reduction is unsuitable for the intended experiment.

A radiator's EN 442 rating is not automatically its constant `UA`. Do not divide its
rated power by an arbitrary temperature difference and treat the result as universally
valid. Select/identify the approximation and its operating range from documented data.
No physical parameters are filled in or certified by this repository.

## Use on the university computer

Download the THERMA folder including both new `.m` files and this guide. From MATLAB,
set Current Folder to the THERMA root:

```matlab
addpath(fullfile(pwd, 'scripts', 'matlab'));
p = room_heating_parameters();
```

Open `room_heating_parameters.m` in the Editor and replace the NaN/empty entries using
your checked calculation and equipment data, then call it again. Alternatively assign
the fields on `p` in MATLAB. Convert °C to K by adding 273.15. Fill:

| Data | Where it comes from |
|---|---|
| Standard edition, national rules and calculation reference | Your university's applicable EN 12831 calculation basis |
| Design indoor/outdoor temperatures and transmission/ventilation losses | The checked one-room heating-load calculation |
| Effective room capacity | Documented air/fabric calculation or identified reference data; EN 12831 load alone does not determine it |
| Radiator capacity and UA | Water/metal data and a justified heat-transfer approximation |
| Water cp and open-valve mass flow | Fluid data at the intended range and measured/design flow |
| Initial room/radiator temperatures, supply/outdoor temperatures, setpoint and full deadband | The explicitly chosen experiment and controller |
| Provenance text | Sources and assumptions for the above |

Missing values deliberately stop the builder. They are not replaced by plausible-looking
numbers. Numerical defaults (one-hour horizon, one-second maximum step and tolerances)
are starting settings only, not measured convergence or source-model settings.

After filling the values:

```matlab
[model, modelFile] = build_room_heating_model(p);
% A new block diagram opens. Inspect Room and Radiator by double-clicking them.
out = sim(model);
signals = out.therma_signals;
plot(signals.Time, signals.Data(:, 1) - 273.15);
xlabel('Time (s)'); ylabel('Room temperature (degC)'); grid on;
```

The builder stores `p` in the new Model Workspace, saves the model under a unique ignored
`outputs/room_reference/<run>/therma_room_reference.slx` and opens it. It does not simulate
automatically. It never opens, edits or overwrites the thesis model. A model of the same
name already open in MATLAB blocks rebuilding; close it yourself first. Preserve any
edits before closing. Only a newly created model is closed on a build error.

`therma_signals` is a timeseries with columns:

1. Room temperature (K).
2. Mixed radiator temperature (K).
3. Radiator heat to room (W).
4. Prescribed mass flow (kg/s).
5. Thermostat command (0 or 1).

The model is made of editable Simulink blocks already; there is no later conversion
step. SI labels describe the equations; this is not a Simscape automatic-unit-verification
claim. The model's parameters and equations can later be mirrored in Python after scope
and reference results are agreed. No Python solver is added here.

## Checks to perform in MATLAB before trusting results

First run `checkcode('scripts/matlab/build_room_heating_model.m')` and compile/update the
new model; cloud syntax lint cannot verify library paths or block API settings. Resolve
any MATLAB errors before claiming a working benchmark.

Check thermostat opening/closing temperatures, mass-flow values and initial conditions.
For a passive cooling case with no radiator-to-room exchange, the room equation should
approach the fixed outdoor boundary exponentially. For an isolated combined room/radiator
case with zero losses and zero advection, stored energy must remain constant. Those are
separate validation configurations to design explicitly; the normal template requires
positive UA and open flow, so do not silently weaken its validation to force such cases.
For ordinary runs check the integrated combined energy balance using the two equations
above. The logged temperatures, flow and heat rate plus constants permit that comparison.

Repeat with smaller maximum step/tighter tolerances and compare trajectories and relay
event times. Check that design-point loss equals the supplied transmission plus ventilation
sum. Check heating sufficiency against the design load and equipment ratings; a physically
consistent model may still have an undersized radiator and fail to reach its setpoint.
None of these MATLAB checks have been run in cloud. Return parameter provenance, errors
and the actual traces before claiming validation or starting a Python implementation.
