# Python migration plan — Phase 1A

Status: research/design only. No solver or automation implementation is authorised in
this phase. Evidence and unresolved source conflicts are in [SIMULINK_INVENTORY.md](SIMULINK_INVENTORY.md).
The existing `src` layout, typed dataclasses, explicit TOML paths, frozen uv dependencies,
pytest, Ruff and strict mypy remain unchanged. There was no ARCHITECTURE.md at inspection.
This document records proposed architecture, not an already implemented framework.

## Component mapping and fidelity

| Reference element | Proposed Python responsibility | Fidelity boundary |
|---|---|---|
| Thermal Mass / conduction / convection | `physics/thermal`: temperature states, capacities, conductances, boundary fluxes | An ODE thermal network is plausible; preserve fabric states initially or justify their reduction against data. |
| Pipe TL radiator | `physics/radiator`: water storage and water-to-room heat exchange | A lumped UA model is a candidate reduction, not a verified replacement for distributed fluid/thermal behaviour. |
| Distribution pipes / Gate Valve TL | `physics/hydraulics`: graph, pressure/flow constraints, valve relation | Coupled nonlinear network for network equivalence; prescribed flow is only a declared prototype boundary. |
| Pump / Tank / heat-flow source | `physics/source`: active pump curve, storage and supply energy | Do not replace storage with constant supply and call it an equivalent model. |
| MATLAB Function / Memory / actuator filter | `control`: pure command policy plus explicit controller/actuator state | Preserve strict comparisons, empty-subset NaN semantics, delays and timing before improvements. |
| Physical ports and solver configuration | `simulation`: assemble states, boundary schedules, events and integration | SciPy `solve_ivp` can handle explicit ODEs, not arbitrary Simscape DAEs directly. |
| Scope / logsout / simlog | `data`: signal registry, raw exports and aligned tables | Retain native timestamps, dimensions, metadata and discontinuities. |
| MATLAB runtime and export | `reference`: external adapter and run manifests | Keep MATLAB-specific access out of physics modules; implementation awaits resolved model information. |

These are future module boundaries, not a reason to create empty modules or add
packages now. NumPy/SciPy/Pandas already suffice for the proposed first numerical work.
No ML, service, frontend, database or deployment changes are needed.

## Smallest meaningful prototype (after review and reference handoff)

Use one identified reference room, one radiator water volume, one valve/actuator, one
outdoor-temperature input and one local thermostat. Supply temperature and boundary
pressure or flow must come from a documented reference experiment. Begin with isolated
room/radiator reference runs, not an unlabelled subset of the coupled 36-room result.
Document adjacent-room/fabric boundary temperatures or insulation explicitly.

Candidate reduced balances below are **recommendations derived from conservation**, not
recovered Simscape source equations or an implementation. Their applicability and
parameters must be agreed from the reference before coding:

- Room: `C_a dT_a/dt = Q_rad + sum(G_aj (T_j - T_a)) + G_ao (T_out - T_a)`.
- Optional fabric node j: `C_j dT_j/dt = sum(G_jk (T_k - T_j))` with shared edges counted
  once per physical connection. This avoids silently discarding wall/window storage.
- Mixed radiator water: `C_w dT_w/dt = m_dot c_p (T_in - T_w) - Q_rad`, with
  candidate `Q_rad = UA (T_w - T_a)` only if a constant-UA approximation is supported.
- Candidate actuator: `tau dx/dt + x = u`, after confirming the saved `[s 1]` filter,
  numerator, initial state, command scaling and units.

Here temperatures are K, time s, capacities J/K, conductances/UA W/K, heat W,
mass flow kg/s, specific heat J/(kg K). For simple constant properties `C=m c_p`;
planar `G=k A/L` or convective `G=h A` applies only to an identified active path.
Do not sum series wall and convection conductances as parallel paths. A mixed radiator
is an approximation; variable fluid properties, pipe pressure storage and nonlinear
heat transfer may require a richer model. Do not infer UA from pipe geometry alone.

Valve opening must affect a justified flow relation or an explicitly prescribed measured
flow schedule. A fixed-flow heat-input switch can test thermal code but cannot validate
valve/hydraulic coupling. Later hydraulic modelling requires continuity at each junction,
pressure-drop/flow laws for active pipes and valves, pump head and boundary conditions.
Exact friction correlations and fluid properties are pending; none are invented here.
Closed-valve leakage and pump dead-head behaviour require explicit treatment.

The local thermostat needs verified on/off thresholds, hysteresis memory, initial state
and sampling. Do not substitute the central controller's 0.3/0.1 K comparisons for the
missing local controller. The central policy can later be ported independently, including
the empty heating-subset case, after reference behaviour is captured.

## Required parameters and validation evidence

Obtain an active, unit-tagged parameter manifest: room air/fabric capacities, geometry,
conductive/convective paths, adjacency, water volume/properties, radiator heat-transfer
law, valve characteristic/leakage/scaling, pump/boundary conditions, initial states,
setpoint schedules and controller timing. Saved examples in the inventory cannot be
extrapolated to every room. Resolve room numbering and unactuated indices first.

Reference experiments should isolate passive cooling, constant-boundary heating,
valve step/open-close response and thermostat switching, followed by the original
combined scenario. Record room and radiator temperatures, heat flow, water flow and
valve commands at native timestamps. Identify which initial conditions and boundary
histories are identical between models.

Validation metrics: temperature MAE/RMSE and maximum absolute error in K; signed and
integrated energy residuals in W/J; valve transition timing in s; flow error in kg/s;
time-to-target and room-spread metrics where applicable. Report unreachable targets as
censored, not zero. Define tolerances from reference resolution, solver sensitivity and
intended use before accepting results; no tolerances or measured performance exist yet.
Compare baseline numerical convergence before interpreting model-reduction error.

## Numerical and expansion strategy

1. After Phase 1A review, reproduce/inspect MATLAB baseline and resolve the inventory's
   handoff questions. Only then implement simulation/export automation (Phase 1B).
2. Agree the one-room boundaries and collect reference experiments. Develop the smallest
   thermal/radiator model with unit, sign, conservation and dimensional checks.
3. Investigate stiffness from water, air, fabric and 15 s candidate actuation time scales.
   Compare suitable SciPy methods (e.g. BDF/Radau) with tolerance/step refinement; the
   source's ode15s setting motivates investigation, not an automatic equivalence claim.
4. Represent thermostat switching as events or explicit sampled updates with hysteresis
   state. Separate controller intervals from adaptive solver steps; preserve delay/reset
   semantics and avoid stateful RHS side effects.
5. Add a second coupled room and shared thermal edges before expanding the room graph.
   Establish stable IDs independent of array order and avoid double-counting fabric mass.
6. Add hydraulic branches, pipe transport/storage, pump and tank coupling as evidence
   requires. Algebraic pressure/flow constraints may be solved per thermal step only
   under a justified quasi-steady approximation. Otherwise a DAE-capable strategy is
   needed; `solve_ivp` is not a drop-in DAE solver.
7. Expand to floors and all 36 rooms with topology/conservation checks and the three
   reproducible scenarios. Reconcile the saved 33-valve arrangement rather than assuming
   36 actuators. Only validated datasets should feed later surrogate work.

## Gate before implementation

Next milestone is **Phase 1B: MATLAB baseline and export preparation**, after user review
of Phase 1A. Acceptance requires the original asset hash, a compiled model, confirmed
licensed products, resolved variables/units/index order, all three scenario configurations,
confirmed local controller, and a raw baseline run with provenance. Missing historic
scenario implementations must be obtained or explicitly scoped as reconstructions.
Do not silently change the thesis model to manufacture reproducibility.
