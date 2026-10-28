# BOPTEST Phase B — executed reference baseline

**Status: COMPLETE for the pinned FMU/direct-FMI baseline, 2026-10-28.** Both original
heating scenarios executed with their seven-day warm-up and fourteen-day evaluation.
This establishes reference outputs for future THERMA work. It does **not** validate
BOPTEST experimentally or demonstrate any Simulink/THERMA model equivalence.
No Simulink model was built. No original thesis model, source extraction JSON or FMU
was changed. No control, physical parameter or weather override was applied.

## Model and runtime

- BOPTEST commit: `a29024f8c453517ccbd1186006a3fa6af8de1ae2`.
- IDEAS build dependency: `f1fdd8b22d39dc50297c47b6433e44381e40d0ff`.
- Original `testcases/bestest_hydronic/models/wrapped.fmu`, SHA-256:
  `365b3085d97cc4620c06b6036156126a056d7f160fcc4f181d6b2fac4b05743b`.
- FMI 2.0 **Co-Simulation**, Linux x86-64 binary only; `needsExecutionTool=false`.
  No Modelica compiler, IDEAS installation or FMU rebuild is needed for execution.
- Tested with Python 3.12.14, FMPy 0.3.20, NumPy 1.26.4 and Matplotlib 3.10.8 on
  Debian 13 x86-64. Exact dependencies/hashes are in the isolated runtime requirements.
- The FMU's embedded JModelica solver is used. It is **not** integrated by a new Python
  ODE solver. The exported `_cs_solver` ID is 0, `_cs_rel_tol=1e-6`,
  `_cs_step_size=0.001`, `_events_default_tol=1e-10`. All exposed solver/event/nonlinear
  settings are recorded in each manifest. These were queried, not changed.
- `setupExperiment` receives no tolerance override. The numeric solver ID and exposed
  settings are retained without guessing hidden absolute tolerances or asserting that
  `_cs_step_size` is the active internal step. Internal integration differs from the
  **30 s FMI communication/measurement interval** and 900 s forecast-resource grid.

Native compatibility initially failed because Debian supplies libgfortran.so.5 while
the original binary requires **libgfortran.so.4**. We did not rename/symlink ABI 5 to ABI 4,
patch the FMU, or rebuild it. The helper obtains the real library through signed APT
metadata/package verification in a disposable pinned Ubuntu 18.04 container:

- Image `ubuntu@sha256:152dc042452c496007f07ca9127571cb9c29697f42acbfad72324b2bb2e43c98`.
- `libgfortran4=7.5.0-3ubuntu1~18.04`.
- Library SHA-256 `d87b8024db66386051efbabb393cce9b8a580bb9be6e461043f74fd7653c9894`.

Only that library is copied to ignored output storage; no system package installation
is performed. `ldd`, hashes of the loaded native libraries and native-library provenance
are included in run manifests. The helper was actually executed successfully. Docker is
used to obtain this compatibility library; no BOPTEST service container runs during the
simulation. Direct FMI avoids installing the large JModelica/PyFMI build environment.

## Scenario and clock semantics

Definitions follow pinned `models/days.json` and `testcase.py:set_scenario/initialize`:

| Scenario | FMU initialization / warm-up start | Evaluation start | Evaluation end |
|---|---:|---:|---:|
| typical_heat_day | Day 327 = 28252800 s | Day 334 = 28857600 s | Day 348 = 30067200 s |
| peak_heat_day | Day 304 = 26265600 s | Day 311 = 26870400 s | Day 325 = 28080000 s |

Time is elapsed **model-year seconds**; day index is time/86400, not a human one-based
day-of-year label. Source CalendarTime uses NY2019 and the weather uses its original
Brussels timezone convention. No conversion to today's date, German climate, UTC wall
clock or daylight-saving schedule is imposed. Wall-clock timestamps in manifests are
UTC provenance only.

Initialize the original FMU at the warm-up start, using its own initialization equations,
then advance continuously across evaluation start without reset/reinitialization.
The first output row is after initialization; subsequent rows are after each doStep.
All activation flags remain false; no setReal/setBoolean/setInteger controls are called.
The checked active weather resource is Brussels.mos. All packaged resource hashes and
ZIP integrity are verified before loading the binary; originals are rehashed afterward.

Each full trajectory has **60481 rows** covering 21 days, and each evaluation CSV has
**40321 rows** including both fourteen-day endpoints. The evaluation-start row also
appears in the full trajectory; there are no duplicate timestamps within either CSV.

## Executed results

Energies below use composite trapezoidal integration of the recorded W samples over
model seconds, divided by 3,600,000 for kWh. They are sampled numerical integrals, not
exact continuous-time energy meters. Event/communication-grid quadrature error is not
independently bounded. Gas input and pump electricity are separate commodities.

| Evaluation | Gas input (kWh) | Pump electricity (kWh) | Operative min/max (degC) | Peak gas input (W) |
|---|---:|---:|---:|---:|
| typical_heat_day | 583.464515 | 4.115407 | 15.010045 / 22.146363 | 5665.743407 |
| peak_heat_day | 428.051986 | 4.115407 | 15.053664 / 24.483090 | 5665.051029 |

The label "peak" selects a period around a peak-load day; it does not guarantee that
its fourteen-day gas total exceeds the typical window. The prescribed windows were
not changed to impose an expected ordering. Gas input may exceed 5000 W because the
5000 W cap is heater thermal output, not gas fuel input. The plots show plausible
heating/setback responses and solar-driven excursions; absolute temperatures, CO2 and
nonnegative power contracts pass. This is a limited trajectory sanity assessment, not
a building-model validation or a claim of comfort compliance.

Final successful run directories and manifests (generated, ignored, not committed):

- `typical_heat_day_ailcox5y`: [typical_heat_day manifest](../outputs/boptest/runs/typical_heat_day_ailcox5y/manifest.json), [evaluation CSV](../outputs/boptest/runs/typical_heat_day_ailcox5y/evaluation.csv).
- `peak_heat_day_wfla_b__`: [peak_heat_day manifest](../outputs/boptest/runs/peak_heat_day_wfla_b__/manifest.json), [evaluation CSV](../outputs/boptest/runs/peak_heat_day_wfla_b__/evaluation.csv).
- `typical_heat_day_t8_7qbxh`: [repeat manifest](../outputs/boptest/runs/typical_heat_day_t8_7qbxh/manifest.json).
- [Baseline artifact index](../outputs/boptest/baseline_index.json) records manifest hashes.

Earlier smoke/development runs remain identifiable by their separate manifests,
including one failed bytes-to-string adapter attempt before stepping. Only the final
runs listed above support this report. No failed/partial run is counted as a baseline.

## Generated plots

All plots use evaluation-only data. PNGs are local generated artifacts; after a fresh
checkout, rerun the commands below to generate new run directories/plots.

| Plot | Typical | Peak |
|---|---|---|
| Operative temperature | [PNG](../outputs/boptest/runs/typical_heat_day_ailcox5y/operative_temperature.png) | [PNG](../outputs/boptest/runs/peak_heat_day_wfla_b__/operative_temperature.png) |
| Gas input power | [PNG](../outputs/boptest/runs/typical_heat_day_ailcox5y/gas_input_power.png) | [PNG](../outputs/boptest/runs/peak_heat_day_wfla_b__/gas_input_power.png) |
| Pump electrical power | [PNG](../outputs/boptest/runs/typical_heat_day_ailcox5y/pump_electrical_power.png) | [PNG](../outputs/boptest/runs/peak_heat_day_wfla_b__/pump_electrical_power.png) |
| Outdoor versus operative temperature | [PNG](../outputs/boptest/runs/typical_heat_day_ailcox5y/outdoor_and_operative.png) | [PNG](../outputs/boptest/runs/peak_heat_day_wfla_b__/outdoor_and_operative.png) |
| Cumulative gas/electric energy | [PNG](../outputs/boptest/runs/typical_heat_day_ailcox5y/cumulative_energy.png) | [PNG](../outputs/boptest/runs/peak_heat_day_wfla_b__/cumulative_energy.png) |

## Data format and accessible signals

`trajectory.csv` includes warm-up and evaluation; `evaluation.csv` includes evaluation
only. The first column `time_s` is absolute model time. To plot evaluation-relative
seconds subtract the manifest's evaluation_start_s. CSV uses 17 significant digits
for binary64 round-trip preservation. No timestamps or values are interpolated or
fabricated. `signals.json` records names, units, FMI types, value references, causality,
descriptions and whether each signal is internal.

There are **60 variable columns plus time**: 39 public wrapper input/output variables
and 21 internal variables verified to exist in this exact FMU. Public data include:

- reaTRoo_y [K], operative temperature, distinct from air temperature.
- reaQHea_y [W], **gas input**, distinct from heater/radiator thermal power.
- reaPPum_y [W], pump electricity, and reaCO2RooAir_y [ppm].
- All available weaSta_reaWea* weather outputs and four effective overwrite-command outputs.
- All four override activation flags and their input values. Inactive input values can
  remain zero (including K-valued inputs); these are not active temperature commands.

Additional INTERNAL FMI getReal reads do not change the FMU or make these public REST
measurements: air/radiative temperatures, occupancy, heater thermal power, radiator
heat split, mass flow, efficiency, calibration/initialization parameters and five water
node temperatures. Their exact names are in the registry and runner INTERNAL list.
Missing internal variables are reported explicitly. Metadata units absent in XML remain
`unspecified` rather than being silently invented (e.g. the occupancy expression's Real).

Runtime values resolved at initialization in both scenarios include UAEle =
**11.325832677562174** (Modelica-declared W/K, used in its nonlinear emission formula),
n50_int=10 1/h, default infiltration air density=1.2 kg/m3 and infiltration mass flow=
**0.0216 kg/s**. These are queried original-FMU values, not assumed engineering inputs.
The Phase A reference JSON remains unchanged; runtime findings live in manifests.

## Reproduction commands

From the THERMA root on Linux x86-64 with Python 3.12, uv, Docker and curl installed:

```bash
mkdir -p outputs/boptest/input
curl --fail --location \
  https://raw.githubusercontent.com/ibpsa/project1-boptest/a29024f8c453517ccbd1186006a3fa6af8de1ae2/testcases/bestest_hydronic/models/wrapped.fmu \
  --output outputs/boptest/input/wrapped.fmu

export UV_CACHE_DIR="$PWD/outputs/boptest/uv-cache"
uv venv outputs/boptest/runtime --python 3.12
uv pip sync --require-hashes --python outputs/boptest/runtime/bin/python \
  scripts/boptest/requirements.txt
bash scripts/boptest/prepare_native_runtime.sh
export LD_LIBRARY_PATH="$PWD/outputs/boptest/native${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

outputs/boptest/runtime/bin/python scripts/boptest/run_reference.py \
  --fmu outputs/boptest/input/wrapped.fmu --scenario typical_heat_day
outputs/boptest/runtime/bin/python scripts/boptest/run_reference.py \
  --fmu outputs/boptest/input/wrapped.fmu --scenario peak_heat_day
```

Alternatively supply the unchanged wrapped.fmu from a checkout at the pinned revision.
Hash verification is mandatory in either case. No original resource paths need editing:
the archive is extracted to a private temporary directory and loads its bundled weather.
The compatibility helper requires valid signed Ubuntu package metadata and the pinned
library bytes; it fails rather than bypassing verification. Do not symlink libgfortran5
to libgfortran4. Windows/macOS/ARM machines need a compatible Linux x86-64 execution
machine/VM; this stored FMU has no matching native binary for those hosts.

The runner prints its unique output directory, saves checkpoints/failure details and
returns a nonzero exit status on errors. To repeat the typical scenario, run it again
in a **new Python process**, adding `--repeat-of outputs/boptest/runs/<first-run>`.
Its FMI metadata permits only one instance per process. Reusing or concurrently creating
a second instance in the same process is not supported.

The reference was repeated in a fresh process with identical runner/config/runtime/
solver/native-library provenance. All 40321 evaluation rows and all 61 columns matched
**exactly numerically**, with maximum absolute differences zero. No acceptance tolerance
was fitted. This establishes same-host repeatability for this run, not cross-platform
bitwise reproducibility or numerical convergence of the reference.

## Checks and limitations

The runner rejects bad FMU/resource hashes, missing libraries, wrong platform/mode,
incorrect scenario/grid boundaries, incomplete/duplicate/nonmonotonic timestamps,
nonfinite values, wrong required units, negative gas/pump power, invalid absolute
room/outdoor temperature, negative CO2, active override flags and non-binary pump stages.
These checks passed on full and evaluation data in both final scenarios and the repeat.
Artifact checksums and source-FMU preservation also passed. The isolated runtime is
hash-locked and reproducible installation was checked.

Repository tests cover these data/provenance contracts, energy units and scenario
semantics. **34 tests pass**, along with Ruff lint/format and strict mypy for the existing
package. Shell syntax for the compatibility helper passes. These tests supplement actual
FMU execution; they do not substitute for it or assert physical-model accuracy.

No official BOPTEST REST service, KPI calculator, forecast-uncertainty mode or Modelica
rebuild was used. This is a recorded direct-FMI execution of the original binary with
BOPTEST scenario semantics; it does not prove equality to a separately hosted service
with different importer/runtime defaults. Absolute solver tolerances and the exact old
compiler-bundled MSL patch revision are not inferred. Complete solid-layer state vectors
were not exported. No MATLAB model exists for comparison yet.

All generated data, downloaded FMUs, native libraries, virtual environments and plot
caches remain under ignored outputs/boptest/. Do not commit them. No commit/push is
performed in this phase. Next implementation requirements are in
[BOPTEST_SIMULINK_CONTRACT.md](BOPTEST_SIMULINK_CONTRACT.md).
