# First actual C2.5C typical replay comparison

Actual user-supplied MATLAB R2025a exports were analyzed against the corresponding
original BOPTEST `bestest_hydronic` reference. No synthetic replay data was used and
MATLAB was not rerun. This is an **exploratory partial-forcing comparison**, not
BOPTEST validation or a calibration result.

## Integrity and period

Original attachments were copied byte-for-byte into ignored
`outputs/boptest/replays/first_typical_actual/`:

| File | Bytes | SHA-256 |
|---|---:|---|
| evaluation.csv | 10,688,915 | `2f23cbda2c8c1c49e347004a2429ff2a1e9764798cbda33e2a6bd9d05539a424` |
| comparison_metadata.json | 2,207 | `e74f565fc3caf6517813b5ebe54395465686ef77208ee7b45ad9072f18cab669` |
| replay_run.json | 16,384 | `e2e85ecc486a7fe805a0e5754d9be9cec9b8c5a80b0386679f8e2668bbdf4d0c` |

CSV checksum matches its actual metadata. The supplied report records completed
partial execution, simulation return and completed export. The original reference
manifest hash `07f761b8cdf0e001b416419833b44bf62144698f6f24f17f1517616fc1f3f247`
matches the recorded replay provenance and run `typical_heat_day_ailcox5y`.
Source evaluation/signal artifact hashes, model/revision, units and period were checked.

The 14-day evaluation covers original model seconds **28,857,600–30,067,200**;
the preceding seven-day warm-up is excluded. The actual replay CSV contains **58,008
adaptive samples**, while the native reference has **40,321 samples at 30 s spacing**.
Comparison interpolates continuous THERMA air temperature onto those reference times,
without shifting, extrapolating or substituting operative temperature.

## Air-temperature results

| Metric | Result K |
|---|---:|
| MAE | 2.340532264 |
| RMSE | 2.805500413 |
| Maximum sampled absolute error | 7.434104854 |
| Bias, THERMA minus BOPTEST | -2.335196393 |

THERMA air ranges **12.3756–22.9304 °C**; reference air ranges **14.8034–25.0622 °C**.
The worst reference-grid sample is at elapsed evaluation day **5.69340**:
THERMA **13.2807 °C**, BOPTEST **20.7148 °C**. First/second-week biases are
**-3.15352 / -1.51691 K**. The changing bias does not uniquely identify a cause:
omitted solar, provisional initial states and reduced glazing/surface/air physics
are confounded. No acceptance threshold or numerical validation pass was imposed.

## Forcing and negative heating

A supplementary audit verifies the original full trajectory's hash and evaluates
its held powers at every actual MATLAB CSV timestamp. Convective and radiative
heating discrepancies are each at most **5.01e-12 W**, within binary64 arithmetic
roundoff. Outdoor piecewise-linear reconstruction differs by at most **3.61e-11 K**;
internal convective/radiative gain differences are **3.55e-15 / 0 W**.

The main pipeline's raw union-grid power comparisons reconstruct sparse output logs;
they can show switching-time differences and slightly different reconstructed energy.
They do not demonstrate an actual forcing/sign mismatch: the direct candidate-time
source audit matches. Do not silently smooth, retime or clamp values to remove these
output-reconstruction artifacts.

Actual replay negative powers match the source: **392 negative total samples**,
minimum total **-27.82466 W**; **580 negative radiative samples**, minimum
**-32.38456 W**; convective delivered power remains positive. Negative means reverse
thermal exchange, not negative gas consumption. No values were clamped. Heating
component sum discrepancy is at most **1.07e-11 W**.

## Energy diagnostics

Maximum absolute instantaneous power-balance residual is **2.81943e-11 W**;
sample-weighted RMS is **6.38965e-12 W**. The sensible infiltration formula agrees
within **2.27374e-11 W** under the recorded reduced-model assumptions.
Total relative stored energy changes by **49.47423 MJ** over evaluation. Negative
stored-energy values are permitted because the model uses a temperature reference.

These observations support internal arithmetic consistency. They do not establish
physical/reference agreement. Full `Delta E - integral Qnet` closure remains blocked:
standard evaluation.csv does not include the complete external net heat power.
The small integral of an instantaneous residual is not a substitute for that check.

## Generated outputs and reproduction

The run produced `metrics.json`, `engineering_summary.md`, six 300-dpi PNG/vector-PDF
figure pairs and supplementary attachment/input/temperature audit files under ignored
`outputs/boptest/analysis/first_typical_actual/`. Original source datasets and all three
uploads remain unchanged. A results-only ZIP is prepared locally, excluding raw
uploads, reference datasets, model files and runtime caches.

```sh
uv run --frozen --with matplotlib==3.10.8 python -m therma.validation.analysis analyze \
  --run-dir outputs/boptest/replays/first_typical_actual \
  --reference-run outputs/boptest/runs/typical_heat_day_ailcox5y \
  --output outputs/boptest/analysis/NEW_ACTUAL_ANALYSIS
```

Use a fresh output directory. Main analysis source is the implementation published
in commit `fec6115267fd8dc4f373b091b30cb022e4f29972`. The optional supplementary
script in the results directory reproduces the direct input-limit and temperature
trend audit; it writes derived files only.

Next: review these first comparative results and obtain missing absorbed solar and
consistent reference initialization before attributing errors or calibrating anything.
C2.6 remains unimplemented. A complete external-power export from the already saved
simulation could enable additional closure diagnostics without changing thermal physics.
