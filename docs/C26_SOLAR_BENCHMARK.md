# C2.6A/B — Solar-resolved partial thermal benchmarking

C2.6A/B implements reference observation, checked packet preparation and MATLAB
replay support. **C2.6C is pending actual MATLAB execution.** No verified thermal
ODE, physical parameter, baseline dataset, weather/control input or FMU was changed.
This is benchmark preparation and numerical verification, not real-world validation.

## Architecture and source equations

The pinned BOPTEST BESTEST Hydronic reference couples a heavyweight Case 900
single-zone envelope, moist air, dynamic glazing, infiltration and weather to a
radiator, water circuit, heat source and controller. THERMA C2 retains the 27 opaque
thermal states plus one dry-air state, simplified surface exchange and static window
UA. It prescribes the original radiator heat instead of predicting equipment feedback.

Sources and exact IDEAS line links, FMU variable references and construction-state
mapping are in [C26_PREREQUISITES.md](C26_PREREQUISITES.md). Pins remain BOPTEST
`a29024f8c453517ccbd1186006a3fa6af8de1ae2`, IDEAS
`f1fdd8b22d39dc50297c47b6433e44381e40d0ff`, original FMU SHA-256
`365b3085d97cc4620c06b6036156126a056d7f160fcc4f181d6b2fac4b05743b`.

The original IDEAS ZoneLwGainDistribution equation is:

```text
port[i].Q_flow = -wDir[i]*Qdir - wDif[i]*Qdif - wGain[i]*Qgain
solar_only_into_surface[i] = wDir[i]*Qdir + wDif[i]*Qdif
```

Qdir/Qdif are transmitted solar **W**, not irradiance; weights are dimensionless.
Do not multiply by area again. Qgain contains radiator/occupant longwave gains already
supplied to C2. Negating the complete surface port would double-count these gains.
Direct, diffuse and total solar sums are checked independently; the combined port
equation is checked as an additional source/sign consistency test. Powers are not
clamped. A 1e-7 W arithmetic residual allowance and 1e-8 W sign allowance detect
contract failures; these are not physical accuracy acceptance thresholds.

| Source index | Receiver | C2 solar port | Handling |
|---|---|---|---|
| 1 | South | input_06 | Solar-only W, held |
| 2 | West | input_09 | Solar-only W, held |
| 3 | North | input_07 | Solar-only W, held |
| 4 | East | input_08 | Solar-only W, held |
| 5 | Floor | input_11 | Solar-only W, held |
| 6 | Roof | input_10 | Solar-only W, held |
| 7 | Glazing | none | Preserved independently, never redistributed |

C2 selects source indices **[1,3,4,2,6,5]**. The seventh interior glazing allocation
is distinct from direct absorption inside glass layers. Neither is faithfully
represented by static window UA. This replay therefore remains explicitly partial.

## Actual reference observations

The original FMU was executed online without parameter/control/tolerance overrides,
at the original 30 s communication step over 28,252,800–30,067,200 s: seven warm-up
days and fourteen evaluation days, 60,481 samples. Evaluation starts at 28,857,600 s.
Every common channel matches the preserved original typical reference **bit for bit**.
A default exporter run without --solar also reproduced every original channel exactly.
No MATLAB was available or executed.

- Combined source distribution residual: at most 2.256e-13 W.
- Seven-surface solar sum residual: at most 1.365e-12 W.
- Evaluation solar allocation (30 s hold reconstruction): total 65.42872 kWh,
  opaque 61.29195 kWh and separate glazing 4.13678 kWh.
- All 39 declared continuous states and air temperature were readable at both boundaries.
- All 27 opaque temperatures initialize at 293.15 K, matching existing C2.
- At evaluation start the opaque temperatures span 270.380878–294.714344 K.
- Full state order, source names, VRs, units and snapshots accompany replay.json.

`docs/C26_ARTIFACTS.json` records actual dataset hashes and checks. Reports include
source-only solar/state PNG/PDF pairs. These are not solar-resolved THERMA results.

The original no-solar MAE 2.34053 K and bias -2.33520 K show a colder reduced model,
not proof that all discrepancy is solar. Initialization at the original start already
matches; different subsequent surface, glazing, exterior and moist-air physics remain
confounded. No temperature improvement is claimed until the paired replay is executed.

## State mapping and restart limits

The FMI derivative table resolves one-based variable indices to 39 states: 27 opaque
K, two glazing K, moist-air U (J), mass/water/trace inventories (kg), five radiator
fluid energies (J) and a dimensionless controller integrator. Source state order and
C2 exterior-to-interior opaque ordering are both recorded. Shared-interface aliases
are not extra states. Air temperature is a separate readable algebraic quantity.

Initial and evaluation-start snapshots are observations. Co-Simulation does not
supply Model Exchange continuous-state access; the FMU does not advertise portable
get/set/serialized state support. No local state is assigned. Source moist-air U can
be negative because of its energy datum; it cannot replace C2 relative stored energy.
The supported packet keeps the complete warm-up and original uniform 293.15 K start,
not an evaluation-start restart.

## Replay schema v2 and compatibility

The existing `therma.validation.replay --partial` schema v1 path is unchanged.
The new opt-in `therma.validation.solar` creates a new directory and refuses overwrite.

- `inputs.csv`: relative seconds, exactly input_01..input_11; first five unchanged
  original forcing channels, six source-derived opaque solar powers in C2 order.
- `solar_seven.csv`: original absolute seconds and seven named surface powers.
- `solar_sources.csv`: absolute seconds and original 31 FMU solar variable names.
- `replay.json`: schema_version=2, solar_resolved_partial; source hashes, pins,
  units, VRs, weights, state mappings/snapshots and baseline preservation report.

Outdoor temperature remains linear; all powers use previous-sample hold. All From
Workspace blocks retain **Holding final value**, including held channels. V2 rejects
missing/nonfinite/duplicate/off-grid timestamps, wrong column/surface order, wrong
units, incompatible identity, invalid source equations or checksums. Python also
checks the seven-source reconstruction independently after serialization. The MATLAB
loader checks units, hashes, opaque routing and observed initialization before use.
No sub-30-second source switching is reconstructed.

## Reproduction in Codex Cloud

Use the existing pinned native runtime (setup documented in BOPTEST_BASELINE.md).
Run the FMU in its isolated NumPy 1.x environment, not the main NumPy 2.x environment.
Each invocation creates a fresh run directory; substitute the printed path for RUN.

```sh
PYTHONPATH=src LD_LIBRARY_PATH="$PWD/outputs/boptest/native" \
  outputs/boptest/runtime/bin/python scripts/boptest/run_reference.py \
  --fmu outputs/boptest/input/wrapped.fmu --scenario typical_heat_day \
  --solar --output-root outputs/boptest/solar_runs

uv run --frozen python -m therma.validation.solar \
  --run RUN --baseline outputs/boptest/runs/typical_heat_day_ailcox5y \
  --output outputs/boptest/c26/NEW_PACKET

uv run --frozen --with matplotlib==3.10.8 python -m therma.validation.solar \
  --verify outputs/boptest/c26/NEW_PACKET --report outputs/boptest/c26/NEW_REPORTS
```

Each analysis output also uses a fresh directory. Plotting is optional for verification:
run --verify without --report for JSON-only checks. No additional mandatory dependency
was introduced. CSVs contain only scalar signals, and no simulation.mat is loaded.

## Prepared download and eventual MATLAB execution

[Download THERMA_C26_solar_replay.zip](https://github.com/AsherFerdinand/THERMA/raw/refs/heads/replay-transfer/THERMA_C26_solar_replay.zip).
It contains packet/, reference/ (evaluation CSV, manifest, signal definitions), reports/
and SHA256SUMS under THERMA_C26_solar_replay/. It excludes the native runtime, FMU,
original MATLAB uploads, models and caches. Only replay-transfer stores this dataset.
The work-branch source ZIP is available from GitHub's Code → Download ZIP menu; Git
is not required on the MATLAB computer. Extract both ZIPs and use the updated work
source, not a transfer-branch source checkout.

From the extracted THERMA work repository root, put THERMA_C26_solar_replay/ under
outputs/boptest/ and eventually run:

```matlab
addpath(fullfile(pwd,'scripts','matlab','boptest'));
results = runtests('tests/matlab');
assertSuccess(results);
reportFile = run_boptest_solar_batch( ...
    fullfile(pwd,'outputs','boptest','THERMA_C26_solar_replay','packet'));
disp(reportFile)
```

Equivalent batch entry point after tests:

```sh
matlab -batch "addpath('scripts/matlab/boptest'); run_boptest_solar_batch('outputs/boptest/THERMA_C26_solar_replay/packet');"
```

This command is provided for later; **Codex has not run it**. MATLAB + Simulink are
required for the reduced model; the Modelica/FMU native runtime is not required there.
New outputs go to a fresh outputs/boptest/replays/ directory. Preserve evaluation.csv,
comparison_metadata.json, replay_run.json and simulation.mat unchanged. Export now
includes net_external_power, stored_energy_derivative, absorbed_solar_power and
internal_gain_power from existing logs. Nested exception diagnostics are preserved.

## C2.6C comparison and completion gates

Once actual SOLAR_EXPORTS exist (the three MATLAB export files), run online:

```sh
uv run --frozen --with matplotlib==3.10.8 python -m therma.validation.benchmark \
  --baseline outputs/boptest/replays/first_typical_actual --solar SOLAR_EXPORTS \
  --reference outputs/boptest/solar_runs/typical_heat_day_u7x05kpz \
  --output outputs/boptest/analysis/NEW_C26_COMPARISON
```

The transferred reference/ directory can replace the solar_runs path for analysis.
The tool requires matching model/parameter identity, initial vector, period and
baseline preservation provenance. Air metrics use the native reference grid, excluding
warm-up: MAE, RMSE, max absolute error, bias and day-wise error. Each run gets existing
six PNG/PDF plots and engineering diagnostics; a paired overlay, signed input energies
and JSON comparison are added. Original baseline integral closure stays blocked when
its old exports lack net power. Missing solar export also stays missing, not inferred
as a measured zero. Full new net-power exports enable sampled Delta E - integral Qnet.
These quadratures include event/log reconstruction error; small instantaneous power
residual alone does not establish integrated energy closure.

Optionally pass --step-run ACTUAL_SECOND_SOLAR_EXPORTS with identical packet, parameters
and changed solver step settings. For example, the later MATLAB command
`run_boptest_solar_batch(packetPath,'MaxStepSeconds',15)` creates a separate run
without changing equations/parameters; omit the option to retain original defaults.
Differences are measured; identical settings are
reported as repeatability only. Do not invent solver sensitivity without two runs.

C2.6C requires actual MATLAB tests/replay, input/channel/endpoint checks, source
alignment, complete energy diagnostics and controlled no-solar/solar comparison with
solver sensitivity where available. Report measured changes even if errors increase.
No calibration or full benchmark-equivalence claim follows automatically. Next physics
scope (dynamic glazing, exterior solar/sky/nonlinear exchange, moist air and gain
allocation) must be chosen from that evidence before hydronic/network development.
