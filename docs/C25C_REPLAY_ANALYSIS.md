# C2.5C replay post-processing and comparison

The user reports successful 21-day MATLAB R2025a/Simulink R2025a execution:
`executed_partial_not_validated`, `simulation_returned=true` and
`matlab_execution_completed=true`, eleven drivers and 60,481 input samples. The
three actual export files have **not yet been supplied to Codex**. No THERMA replay
plots, temperature errors or new replay evidence archive have been invented.
The earlier ten-scenario C2 verification report remains a separate evidence category.

## Files needed from the university computer

From the same successful unique `outputs/boptest/replays/<run>/` directory, upload:

1. `evaluation.csv`
2. `comparison_metadata.json`
3. `replay_run.json`

Keep filenames/content unchanged; do not export through Excel or round timestamps.
No new MATLAB simulation is needed. No large simulation.mat, generated model, FMU
or native libraries are required for ordinary analysis. All three files must refer
to the same run. If working on Windows, a ZIP containing just these three files is
also suitable. The source datasets are already available in Codex.

## Reproducible analysis command

From THERMA root on a Python 3.12 computer with uv, replace ACTUAL_RUN:

```sh
uv run --frozen --with matplotlib==3.10.8 python -m therma.validation.analysis analyze \
  --run-dir outputs/boptest/replays/ACTUAL_RUN \
  --reference-run outputs/boptest/runs/typical_heat_day_ailcox5y \
  --output outputs/boptest/analysis/first_typical
```

Use a new output directory; overwrites are refused. With `--reference-run` omitted,
the tool searches local original-run manifests for the exact manifest hash recorded
in the replay. It does not guess a scenario from a similar filename. If no matching
reference is available, the five replay diagnostic plots can still be produced and
the report marks reference comparison blocked, with no temperature metrics.
`--no-auto-reference` deliberately disables automatic lookup. `--no-plots` permits
numerical analysis without Matplotlib, an optional plotting dependency only.

For a laptop outside Codex, the reference directory needs the original
`evaluation.csv`, `signals.json` and `manifest.json` (about 33 MB plus metadata for
typical). These are ignored datasets, not part of GitHub source. The existing transfer
ZIP's normalized reference can still be used with the older generic comparison CLI,
but this command's `--reference-run` expects the **original FMU run**, not the
normalized folder. Alternatively upload the three MATLAB files and run analysis
in Codex, which already holds the matching reference.

## Checks and output

The module validates completion flags, model/scenario/revision identity, frozen
registry identity, CSV checksum, unique signal contracts, compatible units, finite
values, strictly increasing timestamps and exact evaluation coverage. Warm-up is
excluded explicitly; no automatic time shift, extrapolation, trimming or averaging
of duplicate event samples is performed. Optional recorded driver coverage is also
checked. Source hashes, conversion contracts and analysis code hash are recorded.
A bad/failed/inconsistent source export stops analysis rather than producing a
misleading complete report.

Generated files:

- `metrics.json`: execution/provenance, sampling, physical checks, signed heating,
  storage/residual diagnostics, reference comparison or blocker, and limitations.
- `engineering_summary.md`: readable engineering summary and next recommendations.
- PNG at 300 dpi and vector PDF figures under `plots/`:
  `01_air_and_outdoor`, `02_heating_and_air`, `03_heating_components`,
  `04_ventilation`, `05_energy_and_residual` and, when reference checks pass,
  `06_reference_air_comparison`.

Plots label units, model/scenario identity and evaluation time. Negative values remain
visible. Powers follow declared interpolation; temperatures are displayed in °C,
with error metrics in K. Full-resolution arrays drive numerical metrics; no smoothing,
clamping, coefficient fitting or calibration compensates for omitted solar.

Numerical CSV loading selects only needed columns; SHA hashing streams files; the
pipeline does not load simulation.mat or create a thermal solver. Typical reference
data has 40,321 evaluation samples and the numeric reference columns occupy only a
few MB. Memory scales with selected samples/columns and plotted arrays, not the
entire FMU variable set. No unmeasured laptop performance/RAM bound is claimed.

## Reference temperature comparison

Compare `air_temperature` only against `mod.case900Template.TAir` [K], never against
`reaTRoo_y` operative temperature or source TRad. The latter differ physically from
air and the C2 opaque-surface mean. The original reference CSV, signal registry,
manifest, FMU/revision/scenario identity and recorded source trajectory/signals hashes
must match the replay provenance. Missing/bad reference data yields blocked comparison,
not fabricated or fallback values.

Candidate continuous temperature is interpolated onto the native reference grid
(30 s for these baselines), so adaptive THERMA logging does not change the sample
weights. Coverage must agree exactly. MAE, RMSE, sampled maximum absolute error and
bias (THERMA minus BOPTEST) describe that grid, not unobserved continuous peaks.
Candidate/reference sampling and interpolation are reported. Explicit partial scenario
IDs are retained; common evaluation periods do not make the models/forcing equivalent.

Source heating signs and raw input-alignment metrics are reported alongside thermal
errors. Exact switching timestamps can have different one-sided log conventions;
large raw instantaneous input errors there require inspection, not arbitrary smoothing.
No numerical accuracy threshold or BOPTEST validation pass is inferred.

## Negative delivered heating: what the real reference shows

The original source mapping is `Q_room_conv=-mod.rad.QCon_flow` and
`Q_room_rad=-mod.rad.QRad_flow`. Positive delivered power adds energy to the room;
negative is reverse exchange into the radiator. Radiative exchange is with the
radiative environment, not necessarily the air. Fuel input and pump electricity are
separate quantities. Radiator storage/exchange need not stay positive when equipment
is inactive. Temperature-cause attribution would need the water/air/radiative states.

Actual original-reference evaluation findings (no THERMA outputs used):

| Reference | Negative convective samples | Negative radiative samples | Negative total samples | Minimum total W |
|---|---:|---:|---:|---:|
| Typical heating | 0 | 580 | 392 | -27.82465885 |
| Peak heating | 1456 | 4059 | 2761 | -59.19742692 |

Typical radiative minimum is -32.38455799 W. Peak convective/radiative minima are
-16.56090998/-46.46236973 W. These are genuine signed source measurements, not a
reason to clamp values. Counts are sample counts, not durations. The pipeline reports
negative reconstructed duration, signed negative energy, total signed energy and
component sum consistency without modifying the arrays. Power energy depends on
the declared hold/linear reconstruction, not exact unknown continuous FMU exchange.

Reproduce source-only JSON/summary/plots without a MATLAB replay file:

```sh
uv run --frozen --with matplotlib==3.10.8 python -m therma.validation.analysis reference-signs \
  --reference-run outputs/boptest/runs/typical_heat_day_ailcox5y \
  --output outputs/boptest/analysis/source_typical
```

Use `peak_heat_day_wfla_b__` and a new output folder for peak. Source-only outputs are
explicitly labelled original BOPTEST, not THERMA. Both audits were executed in Codex.
Actual replay negative-power behavior still awaits the uploaded MATLAB CSV.

## Energy diagnostics and limits

The standard replay CSV exports total stored energy and instantaneous power residual,
but **not total external net power**. Heating + internal gains + infiltration omit
opaque-exterior and window fluxes and cannot close the system energy balance.
Therefore a full `Delta E - integral Qnet` check is explicitly blocked for that export.
The report still presents stored-energy change, maximum/RMS instantaneous residual,
its sampled signed integral and heating component accounting. Negative relative
stored energy is valid and is not a negative-capacity diagnostic.

If a future, correctly documented export includes the optional canonical
`net_external_power` [W] signal in metadata/CSV, the pipeline computes a sampled
integral residual with declared event reconstruction; it still does not infer a
conservation acceptance pass. This phase does not alter MATLAB export code or physics
and does not demand rerunning the successful simulation just to create plots.

Next steps: obtain and analyze the actual three files first; then prioritize missing
absorbed solar, consistent initialization/warm-up, glazing/solar, exterior exchange
and radiative environment for C2.6. These remain recommendations only. No C2.6 or
hydronic implementation is introduced here.
