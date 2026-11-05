# C3.5 engineering investigation — prepared, new case execution pending

The request file ends midway through the metric table at “Maximum integrated”.
All complete sections A–F are implemented as a reproducible MATLAB workflow; no
unseen instructions are assumed. The actual C3.4 gate is reviewed in
[C35_BASELINE_REVIEW.md](C35_BASELINE_REVIEW.md). New study data must be generated
in university MATLAB; no C3.5 simulation result or figure is claimed in cloud.

## Preservation and experiment isolation

A new C3.5 branch adds scripts/matlab/c35 and configs/c35. Verified C2/C3/C3.4
builders, equations, parameters and baseline files are unchanged. Each case calls
the verified C3.4 builder into a fresh output folder, then changes only the new
workspace's explicitly declared case parameters. UA-only cases keep water/metal
capacity, nominal flow and all other physical coefficients identical. Larger UA
is a conductance sensitivity, not a claim about a real radiator of larger area
with unchanged mass. Extra native diagnostic integrators do not feed back into
physics, but may change adaptive output times; baseline differences against the
incoming summary are therefore measured, not assumed bit-identical.

No BOPTEST heating trajectory is injected or compared as C3.5 ground truth. The
source model still uses imposed water supply/flow mapping, constant properties,
linear heat transfer and an air-temperature radiant-sink proxy. Those limitations,
C2.8 qualifications and absence of fuel/electric consumption modeling are retained.

## Ordered case plan

| Investigation | Cases / shared baseline |
|---|---|
| A first, highest priority | UA 60/90/120/180 W/K, 24 hours, initial air/fabric/radiator 15 °C, outdoor 5 °C, supply 55 °C |
| B | Supply 40/45/55/65 °C, UA 60 W/K; shared baseline supplies 55 °C case |
| D | Outdoor −5/0/5/10 °C, baseline emitter; shared baseline supplies 5 °C case |
| E | Baseline no solar versus documented six-surface absorbed-solar profile |
| C conditional | Prefer A/B case with an observed off event; otherwise use a case that reaches 21 °C without claiming cycling. If none reaches 21 °C, use explicit fallback |
| F | Same solver/tolerances, max step 10/5/1 s for baseline and an observed switching case; reuse 10 s runs |

There are 11 unique primary A/B/D/E cases, not 14 independent runs: shared controls
are reused and labeled. Additional F/fallback cases are separate. Sequential
execution and caching keep memory modest on an 8 GB computer. If no case meets a
target, it stays not reached. The fallback is not an improved baseline: it changes
UA to 180 W/K, supply to 65 °C, outdoor and initial air/fabric/radiator to 20 °C,
with everything else fixed. It is authorized only when A/B never reaches 21 °C.
No automatic further parameter escalation is implemented. If no selected case
switches off, that missing controller evidence and switched-case F comparison are
explicitly blocked rather than called successful regulation.

## Solar profile and energy

The source is absorbed interior power in W, not irradiance. A 24-hour triangular
profile is zero before 06:00 and after 18:00, peaks at 600 W at noon, and contributes
3.6 kWh/day. A constant allocation sends 50% to the floor and 10% to each other
opaque surface (four walls and roof). It is an explicitly illustrative boundary,
not inferred from BOPTEST weather, glazing optics or sun angles. It corresponds to
50 W per m² of the 12 m² reference window at peak if expressed as an effective
absorbed total; that dimensional comparison is not a solar transmission model.

The case replaces only the newly generated Solar_W source with a six-channel
Model-Workspace timeseries. Linear interpolation, explicit coverage and holding
final values are configured consistently with the R2024a-compatible source API.
The verified C2 solar distribution/thermal equations are unchanged. For a solar
case I.solar_W records the **peak envelope**, while the actual saved timeseries
is authoritative forcing; this disables the zero-gain-only envelope screen without
changing the original assessor. Metadata records this distinction.

Native integrators separately accumulate solar, exterior, ventilation and window
energy alongside existing water/delivered/combined energy states. No energy result
is replaced by sparse exported-log quadrature. Signed heat loss may be negative
when a boundary supplies heat; it is not clamped.

## Why underheating? Conditional analysis alongside measurements

The existing independent C2 nodal assembly provides `dT/dt=A*T+B*u`. A new analysis
function (not a new physics solver) computes static response under full valve
opening and zero solar:

- `T_free = -A\f_environment`.
- `R_heat = (-A\b_heat)_air`, with the existing convective/radiative split.
- Required room heat at setpoint: `(Tset−T_free_air)/R_heat`.
- `H=m_nominal*cp`, `K_emitter=H*UA/(H+UA)`.
- Available heat at setpoint: `K_emitter*(Tsupply−Tset)`.
- All-on steady air: `(T_free_air+R_heat*K_emitter*Tsupply)/(1+R_heat*K_emitter)`.

The combined zone/radiator linear plant eigenvalues provide a conditional slowest
time scale only when stable. This excludes valve transients/hysteresis and, for
solar cases, deliberately uses a separately labeled zero-solar static reference.
It is not an observed 24-hour or closed-loop regulation result. Compare capacity
margin with actual zone storage increase, signed losses and late temperature-rise
slope before distinguishing capacity, inertia and envelope loss. Several can
contribute. The air-radiant proxy also limits physical interpretation.

## Metric definitions

Tables include initial/final/min/max air, time-weighted tracking MAE, time below/
above the ±0.5 K comfort band, 20.5/21/21.5 °C first-attainment estimates, delivered
and water energy, peak power, switch counts, heat losses/storage, solar energy and
native integrated/instantaneous balance errors. A missing threshold uses **−1 s
plus observed=false**, explicitly missingness, not a negative physical time.

Temperature/time metrics use exact integration of their declared piecewise-linear
reconstruction, splitting zero/threshold crossings. Duplicate event times have
zero measure. First attainment is interpolated between recorded samples, not an
exact solver event bound. Initial heating activation is reported separately and
is not falsely counted as an observed 1→0/0→1 transition, consistent with C3.4.
Controller state is checked at each logged sample instant, including in-band
retention. Valve opening is compared with piecewise exponential evolution using
its existing asymmetric tau values (provisional error screen 1e-5).

Demand-off delivered/water/storage energies are separately accumulated from native
energy state differences. Approximate closure means opening <=0.001, not truly
zero mass flow: asymptotic actuator closure may leave residual water input. Air
warming may also involve fabric storage/solar, so a compatible post-off trace is
not sole-cause attribution. Existing exact-zero-flow storage tests remain intact.

## Numerical sensitivity and reporting

F retains ode15s, RelTol 1e-8 and AbsTol 1e-10; only max step changes. Reports compare
final air, native delivered energy, counts, ordered event times and temperature
differences on a common 60 s grid without extrapolation. Unequal event counts are
not forcibly paired. Actual peak/end metrics remain native, not restricted to that
grid. No automatically chosen tolerance declares convergence. Report observed
differences and event sensitivity before making any convergence claim.

The native energy budget/checks from verified C3.4 are unchanged. Additional
controller/valve checks cannot silently convert a failed case to completed.
Completed case receipts hash every consumed report/CSV/figure. Corrupt or incomplete
attempts are retained and rerun into new folders. Source/configuration/release
contracts separate experiments; no unverified reuse across changed conditions.

## Execution and evidence limits

See [START_C35.md](../START_C35.md). Run quick, then capacity, then all. The incoming
C3.4 gate is R2025a; R2024a source compatibility is intended, not independently
executed. No university MATLAB execution occurred in cloud, no new C3.5 plots or
results were fabricated, and no Python thermal solver was introduced. The original
report lacks a full trajectory/final air value; existing baseline review uses only
its reported diagnostics. The new native runs will provide the requested histories.
No real-world/BOPTEST validation, calibration, fuel savings, ML or C4 is claimed.

## Offline delivery

[Download THERMA_C35_ENGINEERING_INVESTIGATION_2026-11-05.zip](https://github.com/AsherFerdinand/THERMA/raw/refs/heads/replay-transfer/THERMA_C35_ENGINEERING_INVESTIGATION_2026-11-05.zip).
The package has 241 files, pinned source
`b044bf082dbd5f337e0f17267435deb95eed71e8`.

SHA-256:
`0cb342a0a75d11319c20c690d8a8bbfe0476fb33971a4888c76e26a095a66472`.
Fresh empty-directory extraction verified all manifest/source hashes, incoming
C3.4 gate/source/config identities, required helpers/configuration, 13+3 MATLAB
test definitions and static syntax. No old project/output/data folder is required.
Uploaded bytes were independently fetched and checked. MATLAB tests/cases still
require university execution; package completeness is not numerical study
verification. See C35_INVESTIGATION_DELIVERY.json.
