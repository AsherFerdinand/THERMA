# Reference normalization and comparison contracts

These tools execute without MATLAB and do not implement a thermal solver. They do
not infer accuracy thresholds or mark THERMA validated. Original Phase B artifacts
stay unchanged. Current C2 is reduced and has not produced verified outputs here.

## Canonical scalar time series

`therma.comparison.Series` records strictly increasing model seconds, finite scalar
values, unit, physical quantity, explicit `linear` or `previous` interpolation,
scenario ID, model version, pinned reference version and source CSV SHA-256.
At least two samples are required. Duplicate/nonfinite times, missing/nonfinite data,
unknown units, absent metadata and invalid provenance hashes are rejected.
An optional maximum gap catches missing samples without assuming every dataset is
uniformly sampled. Extrapolation is forbidden. Arrays are copied and made read-only.

Supported conversions: K/degC, W/kW, J/kWh and dimensionless 1. Conversion across
physical dimensions is rejected. Quantities must also match: gas input power cannot
be compared as radiator-delivered power; operative and air temperature cannot be
compared interchangeably. Scenario and reference revision must match, and the same
start/end times are required. Trimming must be an explicit preprocessing decision;
the comparator never silently discards warm-up or missing coverage.

Alignment uses the union of known timestamps to retain both datasets' sampled event
times. `previous` is a right-continuous zero-order hold. `linear` is for explicitly
continuous signals such as temperature. No hidden switching time is inferred.
Unweighted MAE, RMSE, maximum absolute error, candidate-minus-reference bias and
peak-value difference are calculated on this union grid, so irregular sampling can
change sample weighting. Reports explicitly state this limitation.

Power energy uses left rectangles for previous holds and trapezoids for piecewise
linear reconstructions. Cumulative energy uses the final-minus-initial difference;
no power/energy integration is applied to temperature. Relative energy difference
is `(candidate-reference)/abs(reference)`; zero reference energy returns null.
No power-to-energy claim spans outside the common coverage.

`compare_collection` reports missing quantities on both sides. No shared signals
returns `comparison_not_ready`. Otherwise status is
`compared_no_accuracy_threshold_applied`, never a validation pass.

## Original-FMU normalizer

From project root:

```sh
uv run --frozen python scripts/boptest/normalize_results.py \
  outputs/boptest/runs/typical_heat_day_ailcox5y \
  outputs/boptest/normalized/typical
```

Choose a new output directory; existing directories are refused. The tool verifies
the successful unchanged-source manifest and the evaluation CSV/signal registry
hashes, preserves original model seconds and all manifest/signal metadata, verifies
units and evaluation boundaries, and limits time gaps to the known 30 s Phase B grid.
It exports `normalized.csv` plus `metadata.json`, listing missing optional signals.

Mapping:

| Source | Canonical quantity | Reconstruction/sign |
|---|---|---|
| `reaTRoo_y` | operative_temperature K | Linear, unchanged |
| `mod.case900Template.TAir` | air_temperature K | Linear, unchanged |
| `mod.case900Template.TRad` | radiative_temperature K | Linear, unchanged |
| `weaSta_reaWeaTDryBul_y` | outdoor_temperature K | Linear, unchanged |
| `reaQHea_y` | gas_input_power W | Previous, unchanged |
| `reaPPum_y` | pump_electrical_power W | Previous, unchanged |
| `mod.rad.QCon_flow` | delivered_heating_convective_power W | Previous, negate source port sign |
| `mod.rad.QRad_flow` | delivered_heating_radiative_power W | Previous, negate source port sign |
| `...intGaiOcc.portCon.Q_flow` | internal_convective_power W | Previous, negate source port sign |
| `...intGaiOcc.portRad.Q_flow` | internal_radiative_power W | Previous, negate source port sign |

Power-hold energy can differ from Phase B's trapezoidal sampled-power totals.
This is an explicit reconstruction policy, not a correction to the original results.
Discontinuities inside 30 s intervals and interpolation sensitivity remain unresolved.

## Generic CSV comparison CLI

CSV has unique column names and `time_s`; metadata has:

```json
{
  "schema_version": 1,
  "scenario_id": "actual_experiment_id",
  "model_version": "actual_model_source_revision",
  "reference_version": "actual_pinned_upstream_revision",
  "csv_sha256": "actual_lowercase_64_character_hash",
  "signals": [
    {"quantity": "air_temperature", "column": "T_state_28_K", "unit": "K", "interpolation": "linear"}
  ]
}
```

`column` defaults to the quantity name. Use the real file hash, not the explanatory
placeholder above. Never copy reference scenario metadata onto an incompatible
synthetic C2 run. C2 verification CSVs use synthetic scenario IDs and are not ready
for comparison with typical/peak BOPTEST weather runs.

```sh
uv run --frozen python scripts/boptest/compare_results.py \
  REFERENCE.csv REFERENCE_METADATA.json CANDIDATE.csv CANDIDATE_METADATA.json \
  outputs/comparison/report.json
```

Reports preserve source CSV/metadata hashes, model/reference versions, scenario,
units, interpolation/coverage diagnostics, metrics, missing quantities and limits.
Identical input CSVs are labelled self-comparison, not independent validation.

## Evidence from this sprint

Actually normalized the existing original typical run and its fresh-process repeat,
with no missing selected signals. Their ten normalized quantities compare with
zero maximum absolute difference. This checks processing/repeatability, **not C2
accuracy**. Outputs are ignored under `outputs/boptest/normalized/`.
No Simulink or new original-FMU simulations were executed in Codex during this sprint.
Next: local C2 numerical verification, then matched warm-up/forcing/state initialization
and reference-physics gap resolution before a scientifically meaningful comparison.
