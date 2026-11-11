# C4.3 — Measurement-based thermal validation: feasibility gate

11 November 2026. **Assessment complete; simulation-to-measurement validation blocked, not completed.** The real data support a future Cell 3B experiment, but the current repository has no source-reviewed Cell 3B parameter/boundary/state configuration. This assessment follows the request's instruction to stop rather than fabricate predictions or force calibration. No historical archives were restored.

## Objective and evidence

Predict indoor **air** temperature from measured operating inputs and compare it with an independently held-out measured air-temperature trajectory. Prescribing measured cooling tests the envelope response; it does not validate THERMA's radiator, thermostat, plant or residential realism.

Sources are the official [LBNL-ETA/FLEXLAB-ASHRAE140 repository](https://github.com/LBNL-ETA/FLEXLAB-ASHRAE140/tree/265312ec3843c97d5a24b7d5671ee2891f326af6), pinned to `265312ec3843c97d5a24b7d5671ee2891f326af6`, and its April 2023 report *Measured dataset for validation of building energy modeling programs*. Report page numbers below are printed page numbers. The new [measurement-readiness record](results/c43/measurement_readiness.json) contains immutable source URLs and sizes/SHA-256 for six measurement files and five supporting documents; all eleven were rechecked against the C4.2B provenance manifest.

The actual university [C4.2B verification](../results/C42B/c146fd42ee036a3a/verification.json) records MATLAB **R2025a**, successful input verification, and `completed_inspection`. It explicitly records **no simulation and no empirical validation**. Earlier C4.2B documents saying native inspection was pending predate that returned evidence. No MATLAB execution occurred in this cloud session.

## Available measurements and their roles

| Source / exact channel | Unit | Proposed role and qualification |
|---|---|---|
| `Direct Validation Data/Air temperature.csv`: all 26 supplied sensors | °C | Validation target: explicitly labelled arithmetic mean, not operative temperature or a demonstrated volume-weighted average. Use first value only for air initialization; do not feed the later target trajectory into a temperature-prediction model. |
| `Input Data/Weather data.csv`: `W-OAT-2` | °C | Outdoor boundary when using a weather-driven exterior model. |
| Same: `GHI`, `DNI`, `DHI`, `PIRin` | W/m² | Available radiation observations, **not absorbed interior solar powers**. They cannot directly replace the six C2 absorbed-power inputs. |
| `Input Data/Internal heat gain rate.csv`: `Internal heat gain rate [W]` | W | Aggregate measured electrical gains. Determine convective/radiative allocation; do not add FCU fan heat again if included in this aggregate (report pp21–22,29). |
| `Direct Validation Data/Fan coil units.csv`: `Total cooling rate [W]` | W | Derived water-side cooling, used as forcing in the authors' backward approach (p31). This is not a predicted equipment output. |
| `Input Data/Duct blaster.csv`: `Flow adjusted [m3/h]`, `Ventilation air temperature [C]` | m³/h, °C | Preferred ventilation forcing: use measured flow/supply temperature with **predicted** room temperature. Flow is derived/corrected, not an exact independent airflow measurement. |
| Same: `Ventilation heat transfer rate [W]` | W | Diagnostic only: report Eq8 derives it using indoor temperature. Using this as an independent forcing would introduce target dependence. Do not also add a second airflow heat term. |
| `Input Data/Exterior surface temperature.csv`: seven boundary channels | °C | Candidate measured exterior-face boundaries, including west partition, temporary north wall, ceiling and floor/ground. These are surface observations, not interchangeable adjacent-room air temperatures. Preserve the original `Ground ` trailing space. |
| Indirect surface flux/transfer data | W/m², W | Additional diagnostics; not a substitute for predicting envelope heat transfer. West-wall flux has 549 absent timestamps in the existing 12-hour selection. Some integrated rates use regression/spatial weighting (report pp13–16). |

Times are **fixed PST, UTC−08:00, with no daylight-saving conversion**, including June (report pp23,31). Files contain two timestamp formats; parsing preserves the same instants. The nominal file spacing is 60 s; this does not resolve the report's separate statement about 10-minute averaging. No resampling, interpolation, clipping or filling was performed. °C and K have identical temperature-difference increments; absolute model temperatures would need `T_K = T_C + 273.15`. Flow conversion is exactly `m³/s = (m³/h)/3600`.

## Real-data checks performed

The existing **23 June 2021 00:00–12:00 PST** selection has **721 finite, aligned records per core file**, covering 720 one-minute intervals. These are measurement statistics, not model performance:

| Quantity | Observed result |
|---|---:|
| Arithmetic mean indoor air temperature | 19.9254–20.1023 °C |
| Mean indoor air temperature over supplied timestamps | 20.0345 °C |
| First mean air temperature | 19.9731 °C |
| Largest simultaneous spread among the 26 sensors | 0.4605 K |
| Outdoor `W-OAT-2` | 11.8801–19.6737 °C |
| Aggregate internal gain | 340.26–349.74 W |
| Total cooling magnitude, original signed channel | 143.73–738.30 W; all 721 values positive in this window |
| Adjusted ventilation flow | 0.07645–0.11877 m³/s |
| Derived ventilation power, retained for diagnosis | −130.76 to +69.43 W |
| West boundary surface temperature | 20.161–20.795 °C |
| East boundary surface temperature | 14.634–40.600 °C |

Total cooling equals the two supplied component rates within `1.14e-13 W`. The supplied positive cooling convention represents heat removal under normal operation (the water returns warmer than supply); a zone heat-gain convention must subtract that signed cooling channel. Do not insert it as positive heating, clamp values, or blindly copy the report Eq10 sign notation without reconciling its cooling convention with these CSVs. Negative records outside this window must remain signed.

Checking **all supplied columns** of the six core files found at least one missing/nonfinite minute on each full conditioned day, 22–26 June. This conservative check does not mean every missing column is essential to every possible model. It does mean a complete five-day run cannot silently be assumed. Examples of actual common finite runs are 23 June 00:00–12:35, 24 June 01:10–17:23, and 26 June 00:00–23:58 PST. Their exact extents and per-day counts are in the readiness JSON. The latter intervals are candidates only, not selected calibration/validation experiments; the additional heaters operate after 25 June 15:00.

## Physical model and parameter gate

The reusable starting point is the existing C2 **layered construction + air-capacitance equations**, not the BESTEST parameter set. C3.7 is a 20 m² illustrative room with different adjacency, materials and adiabatic floor/ceiling assumptions. Cell 3B is a separate test cell with measured partition/plenum/ground boundaries.

The candidate air energy balance, using heat gains positive into the zone, is:

`C_air dT_air/dt = Σ Q_surface_to_air + Q_internal,conv − Q_FCU,cooling + ρ cp Vdot (T_supply − T_air)`

Fabric states would retain the existing layer relations `R_layer = d/(k A)` and `C_layer = ρ cp d A`, plus explicitly specified surface convection/radiation and absorbed solar inputs. This is a **proposed methodology, not a newly executed model**. A single outdoor-only `(T_out−T_air)/R` term omits the observed adjacent/ground boundaries. Measured exterior-face temperatures could incorporate outdoor solar/longwave effects for those surfaces; do not additionally impose weather-film/solar heat terms on the same prescribed face. Covered-window transmitted solar still needs a documented treatment.

| Parameter or decision | Verified source / current status |
|---|---|
| Main dimensions | 6.08 × 7.57 × 2.63 m, report Appendix B, Figs B-1–B-6. Derived area 46.0256 m²; volume 121.047328 m³. |
| Covered-window U / SHGC | 0.350 W/(m² K) / 0.004, report Table A-1. Nonzero SHGC must not silently become zero absorbed solar. |
| Ceiling assembly | Report Table3-1 p4 describes metal radiant panels/pipes; `Construction.csv` line5 and IDF lines589–591 specify cotton batt + acoustic tile. Resolve the selected representation and capacitance. No active radiant cooling is inferred. |
| Cotton-batt properties | `Materials.csv` line18, IDF lines264–272 and report Table B-2 all give d=0.178 m, k=0.059 W/(m K), rho=1480 kg/m³, cp=1307 J/(kg K). This agreement does not establish physical plausibility. No guessed replacement density is used. |
| Consequence of that transcription | Calculated batt-only areal capacity 344,316 J/(m² K), or 15.85 MJ/K over the derived ceiling area. This is a source-property consequence, not a measured effective room capacitance. Review before interpreting transient agreement. |
| Temporary north wall | `Construction.csv` line7 uses NorthFacing then SouthFacing foam; IDF lines599–603 uses SouthFacing twice, agreeing with the previously flagged Appendix B table. Names/absorptances conflict; no silent merge. |
| Surface subdivisions/areas and boundary assignments | Sources exist, but no complete reviewed Cell3B-to-THERMA registry is frozen. Main area alone is insufficient to configure every edge/corner/door/window construction. |
| Initial air state | First target mean is available; may initialize air once. Complete through-wall temperature states are unobserved. Do not copy C3.7's 20 °C fabric initialization as if measured. |
| Preconditioning | Recommended by report p31. Need a stated convergence/tolerance or an initial-state sensitivity check and a complete forcing interval. A regulated air temperature does not prove equilibrated fabric. |
| Effective R and C / estimation bounds | **Not specified or fitted.** Source review and an explicit reduction are required; do not copy a residential R/C or hide unresolved boundaries inside a fitted scalar. |

The selected air mean varies only 0.177 K while the maximum spatial sensor spread is 0.460 K. This supports caution about the information available for R/C estimation; it is **not** a demonstrated sensor uncertainty, confidence interval or mathematical non-identifiability result. No fit, rank/uncertainty study or defensible bounds have been completed. Calibration must not compensate for an unresolved ceiling/state/input model. A later fit requires a disjoint conditioning/calibration interval, a frozen holdout, declared bounds and a sensitivity/identifiability assessment. The authors' energy-closure CVRMSE/NMBE are not THERMA temperature errors or acceptance thresholds.

## Results, integration and stopping decision

| Requested validation result | Status |
|---|---|
| Predicted air-temperature trajectory | Not generated; Cell3B configuration/state gate open |
| MAE / RMSE / MBE / maximum absolute error | Unavailable (`null` in JSON), not zero |
| Measured-versus-predicted and error plots | Not generated without predictions; existing [authentic measured-temperature plot](../results/C42B/c146fd42ee036a3a/measured_temperatures.png) remains an inspection plot |
| Independent empirical validation | Not established |

For a later prediction, define `e = T_predicted − T_measured`, MAE=`mean(abs(e))`, RMSE=`sqrt(mean(e²))`, MBE=`mean(e)`, and maximum error=`max(abs(e))`, using identical finite, aligned **held-out** timestamps and excluding conditioning. Do not score a model driven by that same measured air-temperature target as an independent temperature prediction.

Existing `load_boptest_zone_parameters.m` loads the frozen BESTEST registry and `build_boptest_zone_c2.m` uses a fixed 11-input interface and six construction paths. They are not a Cell3B runner. The C3 residential branch additionally embeds its own adjacency and gains. Reusing layer primitives in a separate Cell3B configuration is feasible, but a MATLAB baseline should establish the mapping before any Simulink integration. Historical models, benchmark parameters and C4.2B workflows remain untouched.

**Smallest next step:** freeze a Cell3B surface/layer/boundary registry using the already acquired report/CSV/IDF; resolve or explicitly qualify the ceiling/density/north-wall choices, and document gain/sign allocation. Then select a common finite conditioning/holdout pair from the recorded runs and test initial-state sensitivity. Clarification can come from the named report contacts or an explicitly justified published-source baseline with bounded uncertainty; do not substitute typical material properties. No new download of all 13 archives, new equipment physics or parameter sweep is needed.

## Reproduction and checks

With the existing THERMA Python development environment and the already downloaded **original upstream** files:

```bash
uv run --offline --frozen python scripts/reference/assess_c43.py /path/to/FLEXLAB-ASHRAE140 --output outputs/c43/readiness.json
```

Use a new output filename. The assessment authenticates all eleven inputs, preserves original files, checks full-file timestamp order/duplicates, selects exact finite minute rows, converts flow units, and writes metadata/statistics only. It never simulates or fits. It rejects output under the raw source directory. No machine-specific root paths or raw measurements are published.

The original [C4.2B source manifest](results/c42b/source_audit.json) supplies direct immutable download URLs if any of these eleven files are absent. Raw redistribution rights remain unconfirmed: public access alone is not a licence. This affects redistribution, not the existence of the acquired data; no raw-data packet is published here.

Synthetic software tests cover authenticated loading, altered bytes, duplicate/unordered/invalid timestamps, missing/extra selected samples, nonfinite measurements, fixed-PST alignment and signed flow conversion. **249 Python tests passed, 3 optional plotting tests skipped**; Ruff lint/format, mypy and existing archive/replay checks passed. No new MATLAB code was introduced or executed. Numerical prediction/metric tests and MATLAB simulation delivery are deferred with the explicitly blocked experiment; no fabricated MATLAB results or offline model package is provided.
