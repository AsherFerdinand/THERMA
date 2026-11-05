# C3 component verification — implementation prepared, MATLAB execution pending

The current user request authorizes an independent thermostat/valve/radiator track
with explicitly illustrative parameters. Older C3 design documents describe the
broader hydraulic architecture and benchmark gates; they are preserved as design
history. This first increment implements **C3.1–C3.3 only**. The requested order
requires actual component verification before C3.4 integration and C3.5/C3.6
engineering experiments. No MATLAB executable is available here, so these later
stages are blocked, not completed or silently replaced by a Python simulation.

The existing C2.8 comparison improved agreement for its supplied trajectories
under prescribed radiator forcing. Its solar CSV/execution-lineage qualification
remains unresolved. Neither that MAE nor successful component execution is a C3
accuracy or real-world validation claim. No frozen C2/BOPTEST parameter, equation,
solver, reference artifact or benchmark result was changed.

## Delivered architecture

Native MATLAB/Simulink blocks generate three standalone models with labeled
component subsystems, root inputs, vector outputs and timeseries logging:

| Model | Inputs | Outputs |
|---|---|---|
| THERMA_C3_thermostat | setpoint K, measured air K, binary enable | demand 0/1 |
| THERMA_C3_valve | demand (saturated to 0–1) | opening 0–1 |
| THERMA_C3_radiator | opening, supply K, room air K | temperature K; convective/radiative/total W; flow kg/s; water W; room/water J; stored change J; residual W |

There is no connection to a C2 zone or reference radiator input at this stage.
The generated SLX embeds its effective parameters in Model Workspace C3 and is
saved locally. `component.json` records actual effective parameters separately
from classification and does not claim that generation alone verifies execution.
Top-level external inputs explicitly disable interpolation, and the test driver
uses held timeseries. No MATLAB Function blocks or extra physical toolboxes are
introduced. The radiator is a reduced emitter, not a complete hydraulic network.

## C3.1 sampled thermostat

At controller instants k*Ts, let e=Tset−Tair and h=deadband/2:

- e >= h: turn on.
- e <= −h: turn off.
- Otherwise retain the previous state.
- Disabled: output zero and remember zero at the next state update.

A Unit Delay carries the previous demand with a configurable binary initial
condition. That condition controls the initial result **inside** the band; an
initial temperature outside the band immediately invokes the threshold rule.
Native zero-order holds sample setpoint, temperature and enable together. Default
Ts=10 s is an illustrative numerical/controller choice. State changes occur only
at controller instants; no additional anti-cycling dwell time is claimed.

User-example setpoint 294.15 K (21 °C), full deadband 1 K, lower threshold
293.65 K (20.5 °C), upper threshold 294.65 K (21.5 °C). The setpoint is an input,
not a frozen constant. Positive deadband avoids coincident on/off thresholds.

## C3.2 actuator

```
u_b = min(max(u,0),1)
tau = tau_open if u_b >= x, otherwise tau_close
dx/dt = (u_b - x)/tau
0 <= x <= 1
```

A limited Integrator bounds the state; both time constants are positive. They are
**e-folding times**, not guaranteed full-stroke times. With a held target, the
independent analytical reference is `x(t)=u_b+(x0−u_b)*exp(−t/tau)`. No flow-pressure
relationship or actual commercial actuator specification is inferred.

## C3.3 mixed water/metal radiator

```
C = m_water*cp_water + m_metal*cp_metal                       [J/K]
m_dot = m_nominal * bounded_opening                         [kg/s]
Q_water = m_dot*cp_water*(T_supply - T_radiator)              [W]
Q_conv = (1-f_rad)*UA*(T_radiator - T_air)                    [W]
Q_rad  = f_rad*UA*(T_radiator - T_air)                        [W]
Q_room = Q_conv + Q_rad                                     [W]
C*dT_radiator/dt = Q_water - Q_room                          [W]
E_water = integral(Q_water dt); E_room = integral(Q_room dt)  [J]
Delta_U = C*(T_radiator-T_initial)                           [J]
```

Water and metal have one common temperature (instantaneous internal mixing and
thermal equilibrium). Return-water temperature is consequently approximated by
the radiator lump temperature; inlet-to-outlet enthalpy is approximated with a
constant cp. Imposed forward mass flow is proportional to opening. This does not
solve pressure, valve Cv, pump behavior or reverse flow.

At this isolated stage **air temperature is also the explicit radiant-sink proxy**.
Radiation is linearized and partitioned with a fixed fraction; it is not a
Stefan–Boltzmann/mean-radiant-temperature model or an EN 442 rating law. C3.4 must
review this boundary before coupling radiative delivery to C2 surfaces.

All thermal flows are signed. A radiator colder than the room absorbs room heat;
values are not clamped to fabricate positive heating. At zero flow Q_water=0,
but stored energy can still leave the radiator. A closed, room-temperature
radiator produces zero heat. The balance residual is an algebraic diagnostic;
independent transient and integrated-energy tests are needed as well.

Delivered heat E_room is not water-side input E_water. Their difference is stored
energy. Neither is fuel/electrical consumption: source efficiency, pump electricity,
pipe losses and boiler storage are absent. There is no free-energy claim from
residual release after closure, which comes from the explicit initial/storage term.

## Illustrative parameters and provenance

Every value, unit and assumption source is recorded in
configs/c3/illustrative_components.json; none is calibrated from C2.8 errors.

| Parameter | Example | Basis/limitation |
|---|---:|---|
| Controller initial state | 0 | Illustrative off memory |
| Valve open/close tau | 60 / 90 s | Illustrative e-folding times |
| Initial valve opening | 0 | Illustrative closed state |
| Water mass / cp | 3 kg / 4180 J/(kg K) | Constant-property illustrative inventory |
| Metal mass / cp | 20 kg / 500 J/(kg K) | Illustrative lump, no product material claim |
| Derived capacitance | 22540 J/K | Sum of the two inventories |
| Maximum imposed flow | 0.03 kg/s | No pressure network |
| Linear UA | 60 W/K | Illustrative, not fitted/rated |
| Radiative fraction | 0.35 | Illustrative, not a calibrated BOPTEST parameter |
| Initial radiator / example room | 293.15 K | 20 °C example |
| Example supply | 328.15 K | Externally imposed 55 °C boundary |

Constant-property approximations and the linear heat law require scientific
review for any proposed operating range. No DIN EN 12831, EN 442, product sizing,
reference equivalence or field accuracy claim is made.

## Verification stages and evidence

`run_c3_verification()` checks package hashes, executes the actual Simulink tests,
writes counts/duration/release, solver settings, actual MATLAB console test text
and nested failure diagnostics, and only saves the
three default component models for inspection after assertSuccess. Test-generated
models use unique local directories and do not overwrite defaults or prior results.

Thirteen prepared MATLAB tests cover threshold activation/deactivation, initial
state, retention, disable/re-enable, runtime setpoint change, analytic opening and
closing, demand saturation and tau transition, analytic radiator warmup, signed
heat partition, flow, equilibrium zero heat, post-closure stored heat, an adiabatic
limit, signed room-to-radiator transfer and energy consistency. Adiabatic/other
special fixtures explicitly alter effective parameters for analytical testing;
they are not new calibrated configurations or benchmark outputs.

For constant x/supply/room, the independent emitter solution is
`T_eq=(H*T_supply+UA*T_air)/(H+UA)` and
`T(t)=T_eq+(T0−T_eq)*exp(−(H+UA)*t/C)`, where `H=m_dot*cp`.
Tests compare native Simulink temperatures against this solution, and require
`E_water−E_room−Delta_U` near zero. Pure cooldown and adiabatic input provide
independent limiting balances. The algebraic residual by itself is insufficient.
The test tolerances (e.g. 1e-5 K, 0.05 J) are numerical checks for these controlled
linear fixtures, not C3 accuracy/comfort criteria. They must be assessed against
actual MATLAB output and later step/tolerance sensitivity before broader claims.

Cloud checks validate source syntax, explicit configuration/provenance, packaging
and preservation of earlier evidence. **They do not execute or numerically verify
these Simulink components.** No C3 simulation plots, successful MATLAB test report,
room response, switching count or heating energy has been fabricated.

## Gated C3.4–C3.6 plan — not implemented

After actual C3.1–C3.3 execution passes and results are reviewed:

1. Generate a separate C3 zone model from the existing C2 builder, preserving the
   original C2 model and all outdoor/internal/solar equations. Existing C2 vector
   input elements 2 and 3 are delivered convective/radiative radiator powers.
   Replace those two only; never add both reference and independent radiator heat.
   Feed C2 air temperature to the thermostat and emitter. Resolve/declare the
   radiant sink approximation; do not silently treat air as exact mean radiant T.
2. Connect thermostat→valve→radiator→zone feedback and verify combined storage
   closure before changing environmental forcing or implementing experiments.
3. Implement paired A–F scenarios with explicitly recorded initial states and
   boundaries, keeping the same weather/solar/internal inputs across controls.

| Future scenario | Required comparison/check |
|---|---|
| A cold start | User-specified room 15 °C, setpoint 21 °C; record demand, valve, radiator and room response; do not assume heating capacity suffices |
| B setpoint step | Start room 20 °C, setpoint 21→23 °C; record threshold response and tracking |
| C daytime solar | Matched solar/no-solar pairs; measure delivered heat difference, not assume it |
| D outdoor drop | Matched boundaries except outdoor change; record demand/comfort response |
| E disabled heat | Zero commanded heating with explicit radiator initial storage; residual release is permitted, no new water heat at zero flow |
| F combined energy | Track zone plus radiator stored energy, water input and all environmental flows; preserve original event times |

C3.6 then exports temperature/setpoint, demand, opening, radiator temperature,
separate heat flows and cumulative signed energies. On a declared common time
basis, calculate tracking MAE, time outside the configured band, delivered energy,
maximum power and switching count; distinguish event-integrated duration from
sample counts. No C2.8 MAE can be reused as a C3 claim. A BOPTEST comparison requires
compatible states, boundary conditions, controls and observable definitions.

C4 remains gated on independent C3 verification. The current deliverable is the
component-verification package, not completion of all requested C3 capabilities.

## Offline component delivery

[Download the C3 component verification ZIP](https://github.com/AsherFerdinand/THERMA/raw/refs/heads/replay-transfer/THERMA_C3_COMPONENT_VERIFICATION_R2024a_2026-11-05.zip).
Read START_HERE.md/START_C3.md. Source commit:
`b5fd807d2e329d82d468e429655dafa9630d7f8e`.

ZIP SHA-256:
`c56dd84a80e10f3214379a75f320ef11fc45144004adb0ec04999b20751f9355`.
Fresh extraction into an empty directory verified the full package manifest,
source hashes (with the declared C3 entry-guide override), required helpers/config
and 13 test definitions. Uploaded bytes were independently fetched and verified.
This establishes package completeness/static checks, not successful MATLAB
execution or C3.4–C3.6 completion. See C3_COMPONENT_DELIVERY.json.
