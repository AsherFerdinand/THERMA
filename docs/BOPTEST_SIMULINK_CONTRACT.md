# Next-phase Simulink contract — envelope first

Status: proposal grounded in the **executed original-FMU baseline**, not an implemented
or validated THERMA model. See [BOPTEST_BASELINE.md](BOPTEST_BASELINE.md) for exact runs,
runtime, checks and limits, and [BOPTEST_REFERENCE.md](BOPTEST_REFERENCE.md) for the
source extraction. Do not modify the thesis model or treat the separate local EN 12831
builder as this benchmark. No DIN calculation, new valve or German weather is involved.

## First implementation boundary

Build a separately named **layered Case 900 envelope plus zone model**, driven by
recorded reference boundary/gain signals. Defer the heater, pump, radiator and controller
reconstruction until envelope tests are understood. For this first replay experiment,
use the recorded radiator convective/radiative heat rates as prescribed external inputs.
This deliberately cuts the hydronic feedback loop to isolate envelope error; it is not
full closed-loop equivalence to BOPTEST.

Required conceptual blocks, in order:

1. Model-time/weather/solar replay and signal registry.
2. Separate south, west, north, east wall layer chains; roof and floor layers.
3. South glazing with its optical tables, gas-gap treatment and source dynamics.
4. Interior/exterior surface convection, configured longwave exchange and solar distribution.
5. Well-mixed moist-air zone, infiltration and occupant moisture/CO2/gain handling.
6. Radiative-temperature calculation and operative-temperature output.

Preserve material mass/resistance, thermal flow signs and state ownership at shared
layer interfaces. The adiabatic outer floor boundary still has dynamic floor storage.
Do not attach that boundary to outdoor air or a guessed ground temperature. Do not lump
all wall/floor mass into air, use glazing g as a substitute for the optical tables, or
replace all dynamic exchange with the source's design U-values.

## Input contract

Every imported column must retain model time, unit, sign, source run/manifest hash and
measurement semantics. Use evaluation CSV for metrics and **trajectory.csv** for the
complete warm-up+evaluation replay. Signals are post-initialization/post-communication
samples, not continuous analytic input functions.

| Requirement | Available original-FMU signal / source | Interpretation |
|---|---|---|
| Outdoor temperature | weaSta_reaWeaTDryBul_y [K] | Actual active Brussels boundary, not a forecast substituted for it |
| Pressure/humidity | weaSta_reaWeaPAtm_y [Pa], weaSta_reaWeaRelHum_y [1], dewpoint/wetbulb if required | Use the specified moist-air formulation; no assumed dry-air cp/density |
| Solar | weaSta_reaWeaHDirNor_y, HDifHor_y, HGloHor_y [W/m2] | Distinguish direct-normal, diffuse-horizontal and global-horizontal |
| Solar geometry | weaSta_reaWeaSolAlt_y, SolZen_y, SolHouAng_y, SolDec_y [rad], latitude/longitude and time outputs | Respect source azimuth conventions and angle wrap; avoid double-computing inconsistent sun positions |
| Longwave boundary | weaSta_reaWeaTBlaSky_y [K], HHorIR_y [W/m2], sky-cover outputs | Needed by exterior longwave model; outdoor air alone is insufficient |
| Wind | weaSta_reaWeaWinSpe_y [m/s], WinDir_y [rad] | Exterior-convection dependence remains active |
| Occupants | INTERNAL mod.yOcc.y | Exact source schedule, not a conventional office schedule; unit absent in XML, source interprets it as occupant count |
| Occupant convective heat | INTERNAL mod.case900Template.intGaiOcc.portCon.Q_flow [W] | Negate for heat added to air |
| Occupant radiative heat | INTERNAL mod.case900Template.intGaiOcc.portRad.Q_flow [W] | Negate for heat added to radiative/surface network |
| Latent source | INTERNAL mod.case900Template.airModel.preHeaFloLat.Q_flow [W] and source moisture balance | Not another direct sensible load; source latent/moisture coupling still needs faithful mapping |
| Radiator convective heat | INTERNAL mod.rad.QCon_flow [W] | Negate for heat delivered to room air |
| Radiator radiative heat | INTERNAL mod.rad.QRad_flow [W] | Negate for heat delivered to surfaces/radiative network |

Weather prefixes in the table abbreviate the full names already present in signals.json;
use that registry to select exact columns. All listed INTERNAL names were actually read
from the unchanged FMU, not invented REST endpoints. Preserve the split of radiant versus
convective heat. `reaQHea_y` is **gas input** and must not drive an envelope heat port.

Choose replay interpolation explicitly. A sampled 30 s replay cannot reproduce every
continuous weather value or controller event exactly; treating all columns as smooth
linear functions can smear switching/step boundaries, while zero-order-holding weather
introduces a different boundary error. Use discrete holds for discrete commands and
check sensitivity to weather/gain replay resolution. Do not interpolate across an event
without documenting its treatment. No replay interpolation has been numerically
validated in MATLAB during Phase B.

## Parameters and initialization

Use configs/references/boptest_bestest_hydronic.json as the immutable Phase A extraction,
with all of its source citations, not as a generic one-room parameter template. Geometry
is 8x6x2.7 m; material layers, exposed areas, optical tables and surface-exchange choices
must remain separate. The source-specific interior radiation default is linearised;
interior/exterior convection and opaque exterior longwave are not all fixed coefficients.

Additional runtime evidence, from the original FMU initialized without overrides:

- Infiltration n50_int=10 1/h, rho_default=1.2 kg/m3, m_flow=0.0216 kg/s.
- Radiator rating coefficient UAEle=11.325832677562174 (source-declared W/K with
  nonlinear temperature-power factors), for later hydronic work only.
- Air, radiative node and five radiator-node temperatures initially 293.15 K at the
  warm-up start. These are selected snapshots, not a complete serialized state vector.

The operating room-air capacity cannot be inferred by multiplying this default
infiltration density by an assumed cp. Retain the actual medium and storage equations.
The consistent moisture, trace-gas and complete fabric initial state is not exported
by this runner. Either reproduce source initialization at the same warm-up start and
replay the full seven days, or add a separately reviewed complete state-extraction step
before attempting a restart at evaluation start. Do not initialize all nodes to the
warmed-up operative temperature.

Warm-up starts at day 327 for typical and 304 for peak; evaluate days 334–348 and
311–325 respectively. Model seconds/calendar conventions remain as in the baseline.
No state reset occurs at evaluation start. Initializing only at evaluation start with
20 degrees Celsius does not meet this contract.

## Required outputs and eventual acceptance

The envelope must expose air temperature, radiative temperature and operative temperature
separately. Reproduce the source weighting: `T_op = 0.5*T_air + 0.5*T_rad`, where T_rad
is the source surface-weighted result. Compare T_op to reaTRoo_y and the other two to
the INTERNAL temperature columns, not to each other interchangeably.

Also expose layer temperatures, storage-energy changes and signed heat flows so that
mass/energy residuals and double-counted capacities can be diagnosed. Full hydronic
reconstruction later adds delivered heater/radiator heat, water flow/temperatures,
gas input with the exact efficiency polynomial, pump electricity and original controller
signals. Keep units and commodity boundaries separate.

Before accepting the envelope stage:

- Confirm parameter, area and R/C/node ownership audits, including an adiabatic floor back.
- Confirm exactly matching model-time boundaries, replay signals and initialization.
- Check numerical convergence and boundary-replay resolution separately from model error.
- Report temperature MAE/RMSE/max error in K and energy residuals in J, with event-time differences.
- Establish accuracy tolerances with a stated scientific/use-case basis before marking
  agreement; Phase B supplies no arbitrary acceptance thresholds.

Both reference scenarios and an identical fresh-process repeat have been executed, but
no Simulink comparison exists yet. The same-host exact repeat is a reproducibility
check, not a model-accuracy tolerance or physical validation.

## What still prevents a claim of exact reconstruction

A one-node RC room, constant U loss, one mixed radiator node, different occupant hours,
a valve absent from source or German design weather would be a **reduced/different
model**, not this benchmark. Exact reproduction still requires source surface-exchange
and solar algorithms, layer discretization/state merging, moist-air/latent/CO2 handling,
full initialization and carefully matched sampling/events. The old compiler's precise
MSL patch revision and unexposed integration absolute tolerances also remain unknown.
These are implementation/reproducibility limits, not evidence that the executed reference
failed. Address them explicitly in the next design review before building Simulink.
