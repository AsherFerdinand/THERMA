# Phase C1 — layered envelope reconstruction

Implementation scripts and static checks are prepared. **MATLAB verification is pending.**
MATLAB and Octave are absent from the cloud environment; no `.slx` has been generated,
opened, compiled or simulated here. Generation and runtime acceptance remain to be
confirmed on university MATLAB R2024b with Simulink. Simscape is not required.

## Scope and provenance

C1 covers opaque south/north/east/west walls, roof and floor, including material
conduction and storage. It excludes glazing dynamics, room air, surface convection,
radiation, weather, gains and every heating-system component. No DIN EN 12831
compliance or whole-building/BOPTEST validation is claimed.

The unmodified [Phase A registry](../configs/references/boptest_bestest_hydronic.json)
is the sole material/geometry input. Its byte SHA-256 is
`f91141d78668908525d484a4900dc69af1a163c4c5e07f5a5fbd0c43eae4451c`.
The loader verifies this before decoding, then checks provenance, units, positive
finite values, geometry, layer count calculations and construction totals.

Pinned upstream sources:

- [BOPTEST TestCase.mo](https://github.com/ibpsa/project1-boptest/blob/a29024f8c453517ccbd1186006a3fa6af8de1ae2/testcases/bestest_hydronic/models/BESTESTHydronic/TestCase.mo), commit `a29024f8c453517ccbd1186006a3fa6af8de1ae2`.
- [IDEAS MultiLayer.mo](https://github.com/open-ideas/IDEAS/blob/f1fdd8b22d39dc50297c47b6433e44381e40d0ff/IDEAS/Buildings/Components/BaseClasses/ConductiveHeatTransfer/MultiLayer.mo), particularly connections around lines 88–119.
- [IDEAS MonoLayerDynamic.mo](https://github.com/open-ideas/IDEAS/blob/f1fdd8b22d39dc50297c47b6433e44381e40d0ff/IDEAS/Buildings/Components/BaseClasses/ConductiveHeatTransfer/MonoLayerDynamic.mo), resistance/capacity distribution around lines 8–39.
- [IDEAS Material.mo](https://github.com/open-ideas/IDEAS/blob/f1fdd8b22d39dc50297c47b6433e44381e40d0ff/IDEAS/Buildings/Data/Interfaces/Material.mo), node-count calculation around lines 27–40.

Exact per-value source locations remain in the registry and
[BOPTEST_REFERENCE.md](BOPTEST_REFERENCE.md). Neither the original thesis model nor
BOPTEST FMU is opened or modified by C1.

## Geometry and materials

Length 8 m, width 6 m, height 2.7 m give floor area 48 m² and volume 129.6 m³.
South opaque area is `8*2.7-12=9.6 m²`; the 12 m² glazing is excluded.
North area is 21.6 m²; east/west are each 16.2 m². Roof and floor are each 48 m².
Material order below is **exterior/back to interior**.

| Construction | Material | Thickness m | k W/(m·K) | Density kg/m³ | c J/(kg·K) | Source nodes |
|---|---|---:|---:|---:|---:|---:|
| Wall | WoodSiding | 0.009 | 0.14 | 530 | 900 | 2 |
| Wall | FoamInsulation | 0.0615 | 0.04 | 10 | 1400 | 2 |
| Wall | ConcreteBlock | 0.1 | 0.51 | 1400 | 1000 | 3 |
| Roof | Roofdeck | 0.019 | 0.14 | 530 | 900 | 2 |
| Roof | FiberGlass | 0.1118 | 0.04 | 12 | 840 | 2 |
| Roof | PlasterBoard | 0.01 | 0.16 | 950 | 840 | 2 |
| Floor | InsulationFloor | 1.007 | 0.04 | 10 | 10 | 2 |
| Floor | ConcreteSlab | 0.08 | 1.13 | 1400 | 1000 | 2 |

The unusual floor insulation heat capacity is the source value, not a typo to
replace with a typical value.

| Construction | Material R'' m²K/W | Total capacity J/K | Unique states |
|---|---:|---:|---:|
| Four walls combined | 1.797864145658263 per wall | 9,231,794.4 | 4 × 5 |
| Roof | 2.993214285714286 | 872,157.312 | 4 |
| Floor | 25.245796460176987 | 5,380,833.6 | 3 |

Total: **27 scalar Integrator states**. Per-face `R=R''/area` and material capacities
are exported in `parameters.json` when MATLAB builds the model.

## Discretisation and equations

The source conduction equation is `rho*c*dT/dt = k*d²T/dx²`.
For each layer, `R=d/(k*A)`, `C=rho*c*d*A`, and the pinned node rule is
`n=max(2,ceil(3*d/sqrt(k/(rho*c))/224))`.
There are `n-1` conductive edges, each with `G=(n-1)/R`.
For n=2 each endpoint has C/2. Otherwise endpoints have `C/(2*(n-1))`
and interior nodes have `C/(n-1)`.

Adjacent layers share one interface temperature. Its capacity is the **sum of
both distinct material endpoint contributions**, counted once each. Thus the
unique count is `sum(n_layer)-(number_of_layers-1)`. No material mass is discarded
or duplicated. IDEAS connects its last material to interior port_a; this model
reverses local node indexing to keep global order exterior to interior.
The source's `addRes_b=false` case is used; no invented surface resistance is added.

For edge j, `Phi_j=G_j*(T_j-T_(j+1))`, positive toward the interior.
Each state satisfies `C_j*dT_j/dt = incoming edge power - outgoing edge power`,
plus any applied boundary power. Both boundary input powers are positive **into
that solid**, so `dE/dt=q_exterior+q_interior`. Stored energy is
`E=sum(C_j*(T_j-293.15))`; its reference offset does not alter conservation.
Initial temperatures are 293.15 K throughout.

## Editable block architecture and interfaces

`build_boptest_envelope_c1` builds `THERMA_BOPTEST_Envelope_C1` with:

```text
Parameters (audit annotation; P lives in Model Workspace)
q_exterior_W[5] ─┐                    ┌─ T_exterior_K[6], T_interior_K[6]
                 Boundary_Inputs     │  q_exterior_W[6], q_interior_W[6]
q_interior_W[6] ─┘  │                 │  E_J[6], dE_dt_W[6], residual_W[6]
                    └─ six solids ── Heat_Flow_Outputs ─ T_states_K[27]
```

The six solids are `South_Wall`, `North_Wall`, `East_Wall`, `West_Wall`, `Roof`,
`Floor`, in that order everywhere. Each contains editable Integrator, Gain, Sum,
Mux and boundary blocks. No opaque MATLAB Function physics block is used.
The main model accepts heat-flow boundary inputs and outputs dynamic surface
temperatures; it does not clamp endpoint capacities to prescribed temperatures.
The floor has only an interior input: its exterior power is hardwired to zero,
while its outer state retains storage and internal conduction. Registry flags
`floor.use_T_fixed`, `use_T_in`, `use_Q_in` are all checked false.

Each solid exposes one packed vector:
`[T_ext_K,T_int_K,q_ext_W,q_int_W,E_J,dE_dt_W,residual_W,T_nodes_K...]`.
The collector exposes eight root output groups and Timeseries logs, listed above.
`residual_W=dE_dt_W-(q_ext_W+q_int_W)` uses actual derivative signals.

All parameters are embedded as `P` in the saved Model Workspace. There are no
base-workspace variables or initialization callbacks to recreate manually.
Every build uses a new unique directory under ignored
`outputs/boptest/simulink_c1/`, with the requested filename
`THERMA_BOPTEST_Envelope_C1.slx`, plus `build.json` and `parameters.json`.
An already loaded model of that name causes an error; it is never silently closed
or overwritten. Old output directories remain intact.

The builder explicitly chooses variable-step `ode15s`, RelTol 1e-7, AbsTol 1e-9 K,
MaxStep 60 s, duration 3600 s. These are initial numerical settings, not recovered
BOPTEST solver settings or evidence of adequate accuracy.

## Verification ready for MATLAB

`verify_boptest_envelope_c1` builds and updates the main model, checks dimensions
and Integrator count, then runs these tests:

| Test | Procedure |
|---|---|
| A | Sum discrete edge resistances versus material resistance. |
| B | Sum merged node capacities versus material capacity. |
| C | All 27 states at 293.15 K and zero boundary power: no drift/energy. |
| D | Fixed-temperature fixtures initialized at analytical steady state; compare flux with ΔT/R. Floor has zero steady flux. |
| E | Constant boundary step of 10 K from t=0+, compare generated blocks with analytical eigenmode response of the constrained network; check finite, bounded, monotone temperatures and heat direction. |
| F | Instantaneous derivative balance, stored-energy identity and integrated boundary power; distinct constant inputs also exercise all main-model routing. |
| G | Floor exterior flux exactly zero, with nonzero internal gradient/storage under interior excitation. |

Tests D/E use **separate constant-Dirichlet fixtures**. Prescribed endpoint
Integrator states are eliminated there, not in the main model. Their capacities
remain in energy accounting, with zero derivative after the step. The initial
ideal-reservoir impulse `C_boundary*10 K` is reported separately; energy integrals
start at t=0+. These fixtures do not implement moving boundary-temperature inputs
and are not equivalent to assigning a sudden temperature to a fixed-initial source
endpoint without accounting for that impulse.

Transient horizons are 12 times the slowest constrained-network time constant.
Runs use RelTol/AbsTol 1e-7/1e-9 then 1e-8/1e-10, with MaxStep horizon/250 then
horizon/500. The refined analytical temperature error must not grow beyond floating
roundoff. Algebraic R/C checks use 64 binary64 ULPs; power balance uses a 128-ULP
roundoff budget. Dynamic temperature budget is `20*(AbsTol+RelTol*Tmax)`:
this is a diagnostic heuristic, **not a rigorous global error bound or a building
accuracy target**. Corresponding energy bounds use capacities, boundary conductances
and duration, and are exported in the report.

The sampled trapezoidal energy integral has its own quadrature error. Reports
retain the raw residual, analytical same-time-grid quadrature residual and their
difference, rather than silently interpreting quadrature error as nonconservation.
Analytical response calculations are MATLAB verification helpers only; the Python
checker performs parameter algebra, not thermal time integration.

Results: unique `outputs/boptest/simulink_c1/verification/<run>/` directories,
`verification.json`, per-face steady/coarse/refined CSVs and PNGs, fixture models,
and main-model MAT logs. Partial reports and completed artifacts survive failures.
Only successful actual execution can set `matlab_verified=true`.

## University execution

Download the working project files, preserving this layout:

- All four `.m` files in `scripts/matlab/boptest/`.
- The exact unedited `configs/references/boptest_bestest_hydronic.json`.
- This guide. Keep generated outputs local.

Open MATLAB R2024b with Simulink and its usual JVM enabled. Set Current Folder to
the project root (the directory containing `configs`, `scripts`, and `docs`). Run:

```matlab
addpath(fullfile(pwd, 'scripts', 'matlab', 'boptest'));
P = load_boptest_envelope_parameters();
[P.components.n_states]  % expected [5 5 5 5 4 3]
reportFile = verify_boptest_envelope_c1();
disp(reportFile);
```

After verification, create/open a separate editable main model for inspection:

```matlab
[model, modelFile] = build_boptest_envelope_c1();
disp(modelFile);
```

The verifier closes only models it creates. Before rerunning it, save and close
any generated main model that is still open. Do not bypass the loaded-model guard.
For MATLAB's static analyzer, run `checkcode` on each of the four `.m` files.
Headless execution from the project root is also possible:

```sh
matlab -batch "addpath(fullfile(pwd,'scripts','matlab','boptest')); verify_boptest_envelope_c1();"
```

If the hash fails, restore the exact registry bytes (including LF line endings);
do not edit constants or weaken the check. Missing `new_system` means Simulink is
not installed/on the path. Licence failures require university licence access.
Compilation/block-parameter errors or numerical failures must be returned with the
full MATLAB diagnostic and partial `verification.json`; static lint cannot detect
all Simulink API or signal-dimension issues. Send back the verification directory
and associated build `parameters.json`/`build.json`, reviewing local paths first.
Do not commit generated models, MAT files, plots or CSV datasets.

Cloud/static reproduction:

```sh
uv run --frozen python scripts/boptest/check_envelope_parameters.py
uv run --frozen pytest
```

Optionally compare exported MATLAB parameters with independent Python assembly:
`uv run --frozen python scripts/boptest/check_envelope_parameters.py --matlab-parameters PATH_TO_parameters.json`.
This comparison still does not establish simulation correctness.

## Limits and Phase C2 handoff

This is a source-derived conduction/storage network, not a full IDEAS building.
It merges source interface algebraic equalities into shared states and uses explicit
signal power ports instead of Modelica acausal connectors. Whole-model state names,
initialization equations and solver machinery differ; dynamic equivalence remains
unverified. Surface films, glazing, solar/longwave exchange and zone air are absent,
so C1 outputs cannot yet be compared directly with room-temperature BOPTEST baselines.

First run and review all university tests and numerical budgets. Only then should
C2 connect surface exchange models to the temperature outputs and power inputs,
add glazing and room-air storage/gains, and replay separately recorded reference
weather and radiator heat. The floor back boundary stays insulated. Hydronic
reconstruction remains a later step.
