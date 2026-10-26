# Simulink reference inventory — Phase 1A

## Evidence and reproducibility

Source: [Ferdinand Yurichson's thesis repository](https://github.com/AsherFerdinand/SimulinkMATLAB-dynamic-hydronic-balancing-simulation),
commit `a4b6451f74a436b8daa57633962c91202c5b39e3`, inspected 2026-10-26.
The repository carries [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) in
`LICENSE`. This document analyses that work; no reference assets are vendored or modified.
The temporary inspection checkout is not a required THERMA runtime dependency.

Evidence labels: **source** means readable documentation/code/archive content;
**inference** means an engineering interpretation, not an executed result;
**pending** means MATLAB or author confirmation is required. XML locations below are
inside `model/Main_SpeedOptimisedVersionTannenweg.slx`; SIDs are saved block identifiers.
No MATLAB executable was found on PATH. No model compilation, simulation, toolbox
license check or numerical validation was performed.

SLX SHA-256: `2b797e2b23320cf9514e1b761efeb7c39d8bf56f761b307776ade23330c1651f`.
Inspection used Python's `zipfile` and `xml.etree.ElementTree`; ZIP CRC validation passed.
All 210 system XML files parsed, containing 2,925 block records. Counts include saved,
possibly inactive or commented blocks and are not counts of runtime states.
`metadata/mwcorePropertiesReleaseInfo.xml` reports **R2024b Update 5**, version
`24.2.0.2863752`. Older releases have not been tested.

## File inventory

| Source path | Finding |
|---|---|
| `model/Main_SpeedOptimisedVersionTannenweg.slx` | Only SLX; no MDL files. Thermal and thermal-liquid networks, embedded controller, saved workspace/configuration. |
| `script/central_control_logic.m` | Only `.m` file; function is named `controlAllValves`, so direct external invocation needs filename/path handling. Embedded code is separately present in the SLX. |
| `script/control` | One-byte placeholder, not executable control logic. |
| `README.md` | Architecture images, three scenarios and KPI descriptions. Links to `01_Thesis`, `02_Model`, `03_Control`, `05_Results` do not match tracked paths; no thesis PDF is present. |
| `documentation/project_overview.md` | Substantive narrative: building, scenarios, assumptions and claimed results. Claims are not independently reproduced here. |
| `documentation/Pipe_and_Model_Modelling.md` | Pipe-based radiators and ideal adiabatic distribution assumptions. |
| `documentation/{parameter_table,model_architecture,assumptions_and_limitations,validation}.md` | Each is a one-byte placeholder; no parameter table or numerical validation dataset. |
| `model/diagrams/` | Four PNGs: `Boiler`, `Central Valve Controller Logic`, `Temperature Input`, `Whole System`; `1` is a placeholder. |
| `results/` | Three overview JPGs: `Comparisons All Floors`, `House with only comfort logic`, `Whole House 36 rooms 3 hours simulation`. Eleven room JPGs in `room temperature graph/`: r2, r3 (2), r4 (2), r5–r12; `1` is a placeholder. |
| `LICENSE`, `PROFILE.md`, `.gitignore`, `.github/` | License, profile and GitHub exercise scaffolding; not simulation setup/CI. |

No standalone initialization scripts, MAT/CSV time-series, parameter files, or separate
scenario model versions are tracked. Plot images are qualitative evidence only.
The controller diagram and `Comparisons All Floors.jpg` were visually inspected: the
latter shows per-floor traces with differing temperature levels and a 10,800 s scope
horizon. The image cannot establish exact crossing times, error metrics, units or the
configuration of the currently saved model. The diagram's gain `.1` differs from the
saved gain `fd` (0.03); do not treat screenshots as authoritative executable settings.

## Dependencies and saved configuration

**Source:** library references require MATLAB, Simulink, Simscape and Simscape Fluids
(`SimscapeFluids_lib` pump, tank and gate valves). An embedded MATLAB Function uses
Stateflow chart serialization; whether a separate Stateflow license is required must
be checked on the execution machine. No evidence requires Parallel Computing Toolbox
for sequential runs. Confirm dependencies with MATLAB product/dependency analysis and
a compile; serialized library names alone do not prove license availability.

`simulink/configSet0.xml`: start 0 s, stop `3600*2` (7,200 s), solver `ode15s`, relative
tolerance 0.001, absolute tolerance and maximum step `auto`. Simulink signal logging is
on with Dataset name `logsout`; Simscape logging is `none`. No To Workspace block was
found. Enabled global logging does not establish that required individual signals are
marked or exported. Confirm effective configuration and local solver settings at runtime.

`simulink/modelWorkspace.mxarray` contains a small serialized struct. For static reading,
the compact 8-byte header was replaced **in memory only** by a MAT v5 header and parsed
with installed SciPy `loadmat`; the `__function_workspace__` fields decoded as follows.
This is not a supported MATLAB evaluation and must be cross-checked in Model Workspace.

| Workspace field | Saved value | Unit evidence/use |
|---|---:|---|
| `Ti` | 5 | Room air initial-temperature field specifies °C; 278.15 K in SI. |
| `fa` | 0.00071 | Valve `area` uses m². |
| `fd` | 0.03 | Valve `diam_orifice` uses m; root command gain also uses `fd`. |
| `ips` | 36 | Name/value recovered; intended role/unit not established. |
| `ma` | 0.0013 | Main pipe/pump port area uses m². |
| `md` | 0.04 | Main pipe hydraulic diameter uses m. |
| `roomarea1` | 20 | Name suggests area, but use/unit not established by this inspection. |
| `s` | 15 | Transfer-function denominator `[s 1]`; inferred time constant 15 s, to verify. |

These are source observations, not endorsed defaults or a complete active parameter set.
Inactive mask alternatives can coexist in XML; do not use every saved field as active.

## Physical subsystems and migration boundaries

**Source:** root subsystems `EG` (SID 7657), `OG1` (4377), `OG2` (4285) each contain
Raum1–Raum12. Physical inter-floor connectors and room-labelled connections are present.
A complete adjacency graph and room-to-vector index contract remain to be exported.

| Subsystem | Inputs and dependencies | Candidate states / outputs | Parameter evidence and Python direction |
|---|---|---|---|
| Room air and fabric | Outdoor boundary, radiator heat, adjacent room/fabric thermal ports | Air/fabric temperatures; room `Troom` | Saved Thermal Mass, Conductive and Convective Heat Transfer blocks; multi-node thermal network before any justified reduction. |
| Walls/windows/doors/floors/roof | Room air and coupled thermal nodes | Stored energy/temperatures and heat flows | 368 Thermal Mass, 410 conduction, 410 convection references overall. Room examples distinguish air, wall, roof, window and doors. Some OG1 boundary blocks in `system_4650.xml` have `Commented=on`; do not assume all boundaries are active. |
| Outdoor input | Floor-local `Tatm12` sine to `Tatm` tag | Imposed temperature boundary | Amplitude 7, frequency `2*pi/(24*3600)`, phase pi; representative converter uses degC with affine conversion. Bias/defaults and all effective paths require confirmation; SI export is K. |
| Boiler/storage | Controlled heat-flow source, return water, pump circulation | Tank internal temperature, water storage; supply/return enthalpy and pressure pending | Root `Heat Power` constant is 25000; heat-power unit chain must be resolved before labelling it 25000 W. Tank saved initial temperature 55°C = 328.15 K. Python eventually needs a storage/source energy balance. |
| Circulation pump | Driven rotational source, connected tank/pipes | Flow/head/pressure; mechanical state depends on active formulation | Centrifugal Pump TL, 1-D tabulated parameterization; flow table in lpm, head m, power kW. Convert to m³/s and W for export; reproduce active curve rather than assume fixed flow. |
| Distribution | Pump, branches, fluid properties, valves | Pipe fluid temperature/pressure storage; port mass flow and heat transfer | 69 Pipe TL references overall; representative main pipe length 4.8 m, area `ma`, diameter `md`, roughness 15e-6 m. Perfect Insulator boundaries support documented adiabatic intent. Coupled network required for hydraulic equivalence. |
| Radiators | Inlet water, valve, room heat port | Water temperature/energy and room heat input | Pipe-based radiator: `system_137.xml` SID145, length 5 m, area .01 m², Dh .1128 m, initial T 293.15 K, dynamic compressibility true, inertia false. These are one instance's saved fields, not all radiator settings. |
| Valves/actuation | Selected room command, root gain, first-order filter, pressure difference | Filtered actuator state, opening, resulting branch flow | 33 Gate Valve TL references and 33 selectors/transfer functions, not 36. Need compiled topology and opening-unit reconciliation before porting the hydraulic relation. |

Representative thermal evidence (`system_1.xml`, OG2/Raum3): SID45 air mass 48.7 kg,
specific heat 1005 J/(kg K), initial `Ti` in °C; product is 48,943.5 J/K (derived air
capacity only, not total room/fabric capacity). SID17 conduction: area 6.7 m²,
thickness .16 m, conductivity .069 W/(m K); SID29 convection: area 6.7 m²,
coefficient 8 W/(m² K). Geometry and material provenance remain unverified.

**Identifiable physics:** storage, planar conduction, convection, thermal-liquid
transport, pump characteristic and valve restriction are evidenced by library types
and parameter fields. The exact library equations, active modes, fluid properties,
initialization constraints and assembled DAE are not exposed in full here. Do not claim
that a single room RC equation reproduces these components. Proposed reduced equations
and their assumptions are in MIGRATION_PLAN.md.

**Conflict requiring resolution:** source prose says pressure losses/flow distribution
are not explicitly calculated. Saved Pipe TL fields include roughness, laminar/turbulent
Re thresholds and diameter; Gate Valve and pump curve components are also present.
These support investigating hydraulic coupling, but static presence does not prove
which losses/states were active or measured. No formal balancing or redistribution
benefit is established. Confirm actual pressures, flows, active parameterization and
conservation from a compiled, logged run.

## Control strategies

The standalone `.m` and embedded `simulink/stateflow/chart_14.xml` contain the same
`controlAllValves` function text after surrounding whitespace is stripped.
For room temperatures T and desired temperatures D:

1. Heating subset H = rooms where T + 0.3 < D (strict inequality).
2. Average A = mean(T in H); A = NaN when H is empty.
3. Command i is 1 only if T_i < D_i **and** T_i - 0.1 < A; otherwise 0.

Threshold differences correspond to 0.3 K and 0.1 K after consistent temperature
conversion. The controller prioritises temperatures relative to the mean of rooms
sufficiently below their own targets, not the single coldest room. There is no persistent
hysteresis state in this function. If H is empty, comparisons with NaN close every valve,
even if a room is less than 0.3 K below target. This is code-derived behaviour, not a
runtime observation; preserve and test it before considering any redesign.

Root wiring: `TroomEG`, `TroomOG1`, `TroomOG2` feed a Mux through Memory blocks, then
`TroomArray` feeds another Memory and the controller. Output passes gain `fd` into a
Manual Switch; its other input is constant 0.1. The result is tagged `ValveSignal` and
sent into all floors. The switch's saved `CurrentSetting` is 0; effective branch and
scenario must be confirmed in MATLAB rather than inferred from a screenshot.
Selectors cover 2–12, 14–24 and 26–36; indices 1,13,25 have no selector. A representative
chain (`system_12990.xml`) selects index 27, applies Transfer Fcn denominator `[s 1]`,
then a Simulink-PS converter labelled unit `1` into a valve opening port. Confirm the
opening dimensions/scaling (valve parameters use m) and any compile diagnostics.

Saved `Tdesired` is the following 12-value vector repeated three times:
`[-5,15,20,24,20,20,15,24,20,20,20,20]` °C by temperature-signal context
(SI K: add 273.15). It differs from the README's common 20°C objective. Do not
silently replace it or assign room identities until vector order is traced.

| Scenario described by source | Accessible implementation evidence | Pending confirmation |
|---|---|---|
| Uncontrolled heating | Root constant/switch offers a fixed-command route. | Which setting/scalar distribution reproduces baseline; full-open meaning and excluded branches. |
| Local thermostats | Overview describes independent two-point control with hysteresis. | No room Relay or separate local thermostat function was found in saved block records. Obtain original local-only implementation, switching thresholds, state initialization and scenario configuration. |
| Supervisory + local | Embedded central function and command path above are present. | Whether a separate local layer is actually active; execution/sample semantics and three-scenario reproducibility. |

The only saved Relay block found is boiler controller SID589 (`system_596.xml`):
OnSwitchValue -305, OffSwitchValue -308, OffOutputValue .008. Its input passes
sign/temperature transformations, and other outputs inherit defaults. These raw values
must not be presented as local thermostat thresholds or interpreted as physical boiler
switch temperatures without tracing/evaluating the full path.

## Required MATLAB handoff

On an R2024b-equipped licensed machine: inventory required products; load an immutable
copy; inspect callbacks, workspace and masks; compile/update the diagram; resolve all
variables/defaults and warnings; export active connectivity, state initialization,
units, fluid properties, pump curve and control sample times. Establish the room index
map, 33/36 discrepancy, actual local thermostat implementation, switch semantics and
scenario-specific model versions. Resolve prose/XML conflicts and 7,200 versus 10,800 s
horizons before automation. Obtain raw baseline signals; screenshots cannot validate a
Python solver. No automation script is implemented until these details are confirmed.
