# C2.5 reference replay and comparison workflow

C2's successful local verification report is archived, but no C2-versus-FMU replay
has been executed in Codex. Tools here prepare **partial exploratory** studies.
They cannot infer missing solar absorption, a full reference initial state or
reference-equivalent physics. See [compatibility](C2_SIGNAL_COMPATIBILITY.md),
[verification evidence](VERIFICATION_EVIDENCE.md) and [physics gaps](C2_PHYSICS_GAPS.md).

## 1. Inventory and prepare the original reference

Existing local original-FMU runs are documented in `configs/references/c2_reference_inventory.json`.
The source datasets stay untouched under ignored outputs/. They are not vendored
into GitHub; reproduce Phase B or transfer those actual hash-checked run directories.

```sh
uv run --frozen python -m therma.validation.replay --inventory outputs/boptest/runs/typical_heat_day_ailcox5y
uv run --frozen python -m therma.validation.replay --check-matrix
uv run --frozen python -m therma.validation.replay \
  --run outputs/boptest/runs/typical_heat_day_ailcox5y \
  --output outputs/boptest/replay_inputs/typical --partial
```

Use a new output directory. Without explicit `--partial`, preparation refuses the
missing absorbed solar and full initialized state. Metadata records six solar inputs
as **omitted in the experiment**, not reference zeros. A uniform source-declared
293.15 K start is explicitly provisional, not a reconstructed FMU restart. All
seven warm-up days remain; there is no evaluation-start reset. The scenario ID
retains a `__partial_no_solar_uniform_start` suffix to expose the experimental change.

Required outdoor temperature and separate convective/radiative radiator/internal
powers must actually exist with the correct source units; missing fields or bad
hashes stop preparation. Port sign transformations are recorded. The packet contains
`inputs.csv` in relative solver seconds and `replay.json` recording the absolute
original time origin, evaluation boundaries, channels/interpolation, original hashes,
initial state policy, omissions and limitations. The original reference manifest,
trajectory and signals files are hash-checked.

Outdoor temperature uses declared piecewise-linear reconstruction; gain powers
use right-continuous previous holds. Unknown sub-30 s events are not recovered.
The reusable event normalizer retains the last held value at repeated times and
rejects a duplicate-time jump on a declared continuous signal. Scalar comparison
Series continue to reject duplicate timestamps, so ambiguous data cannot slip into
metrics. Partial packets currently use the reference's strictly increasing 30 s grid.

The same command works for peak run `outputs/boptest/runs/peak_heat_day_wfla_b__`.
Transfer the entire prepared packet directory to the university PC along with the
updated repository. No Git is required there.

## 2. Run the partial experiment in university MATLAB R2025a

```matlab
cd('C:\YOUR\PATH\THERMA'); % replace with your actual repository root
addpath(fullfile(pwd,'scripts','matlab','boptest'));
results = runtests('tests/matlab');
assertSuccess(results);
packet = fullfile(pwd,'outputs','boptest','replay_inputs','typical','replay.json');
assumptions = fullfile(pwd,'configs','references','c2_reduced_assumptions.json');
reportFile = run_boptest_zone_replay(packet,assumptions,'AllowPartial',true);
disp(reportFile);
```

These new replay scripts have only been statically checked in Codex, **not executed
in MATLAB**. The supplied successful ten-scenario report verifies the earlier C2
suite, not this new replay runner.

The runner builds a fresh C2 model and replaces only its external driver. Eleven
From Workspace sources feed the same existing selector/input paths: continuous
outdoor data interpolate linearly; gain/solar data disable interpolation and enable
zero-crossing handling. A single root Interpolate flag cannot represent mixed policies.
C1/C2 equations, parameters and verification sources are not modified. Duplicate
sample handling rejects jumps on continuous channels and retains rightmost held values.

Model, result MAT, trajectory/evaluation CSV, solver/parameter/source/packet hashes
and partial/failure reports go to a new ignored `outputs/boptest/replays/<unique>/`.
The full warm-up is simulated before evaluation CSV export, using original absolute
model seconds. Exact evaluation boundary samples are requested and checked. Temperature
and actual forcing outputs retain distinct canonical quantity names. No source gas
or pump prediction is invented, and opaque mean temperature is not labelled TRad.

`AllowPartial` defaults false. Successful execution is labelled
`executed_partial_not_validated`, `classification=exploratory_comparison`, with
`matlab_verified=false`: replay execution is distinct from engineering verification
or reference validation. Preserve the failed report if model-source API or numerical
issues arise. Save/close a same-name model before rerunning.

## 3. Normalize the reference evaluation data

```sh
uv run --frozen python scripts/boptest/normalize_results.py \
  outputs/boptest/runs/typical_heat_day_ailcox5y outputs/boptest/normalized/typical
```

This now includes a derived delivered-heating power as the negative sum of the two
radiator port powers, preserving its split components too. Gas input, pump electricity
and room-delivered heat are not interchangeable. Power energy uses the declared hold
policy, which differs from Phase B's trapezoidal sampled-power integral convention.
No original reference file is overwritten.

## 4. Compare only compatible quantities

Copy the actual university replay outputs back. Substitute the actual unique run
folder below:

```sh
uv run --frozen python scripts/boptest/compare_results.py \
  outputs/boptest/normalized/typical/normalized.csv \
  outputs/boptest/normalized/typical/metadata.json \
  outputs/boptest/replays/ACTUAL_RUN/evaluation.csv \
  outputs/boptest/replays/ACTUAL_RUN/comparison_metadata.json \
  outputs/boptest/comparisons/typical_partial.json \
  --classification exploratory_comparison --allow-scenario-difference
```

The explicit scenario-difference switch is restricted to exploratory studies and
retains both original IDs. It does not make the inputs identical or rename a partial
experiment into the source scenario. Reports list missing inputs and assumptions.
Only matching physical quantities receive metrics; proxies, absent outputs and
different commodities remain missing/incompatible. Air is not operative temperature.

The tool exports JSON and Markdown with source hashes, versions, mapping, alignment,
MAE/RMSE/max/bias/peak metrics, power/cumulative-energy distinctions and readiness.
No accuracy threshold or validation pass is inferred. Classification options are
verification_only, exploratory_comparison, partial_reference_comparison,
reference_validation_candidate and not_comparable. The validation-candidate label
requires explicit complete-physics/input/initialization declarations and no missing
inputs; it is still only a candidate, never a numerical validation pass.

To generate plots with the optional Matplotlib dependency:

```sh
uv run --frozen --with matplotlib==3.10.8 python scripts/boptest/compare_results.py \
  REFERENCE.csv REFERENCE_METADATA.json ACTUAL_CANDIDATE.csv ACTUAL_CANDIDATE_METADATA.json \
  outputs/boptest/comparisons/result.json --classification exploratory_comparison \
  --allow-scenario-difference --plots outputs/boptest/comparisons/plots
```

Each compatible signal gets a reference/candidate overlay, error trace and cumulative
energy (power) or time-alignment panel. Known power steps use step plotting. Plot
titles contain scenario and model names; units are explicit. Optional plotting does
not add a dependency to evidence import or numerical metrics.

## What has actually run here

Python prepared the real typical and peak partial packets and checked their original
manifest/CSV/signal hashes. Python normalized the original typical run and its repeat,
compared 11 quantities including derived delivered heating, and generated JSON,
Markdown and 11 plots. All differences were zero for the repeat. This is reference
processing/repeatability, **not C2 replay or model validation**. No C2-versus-FMU
numbers have been fabricated. Next execute the partial MATLAB workflow, review the
missing-forcing limits, then proceed to C2.6 rather than unverified C3 feedback.
