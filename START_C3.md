# THERMA C3 — isolated component verification, stages C3.1–C3.3

This is **not yet a closed-loop building model**. The requested development order
requires verification of the thermostat, valve and radiator before C2 integration
and six engineering experiments. MATLAB is unavailable in Codex Cloud, so that
execution gate is pending. No C3 room-temperature/comfort/energy result is claimed.

1. Extract the ZIP into a new writable local folder, for example C:\THERMA_C3.
   Open its THERMA_C3_MATLAB folder in MATLAB R2024a. MATLAB with Simulink and
   Java is required; no Simscape, Git, Python, Docker, WSL or internet is needed.
2. In the Command Window, run:

   ```matlab
   cd('PATH_TO_THERMA_C3_MATLAB')
   reportFile = run_c3_verification();
   ```

3. The runner verifies the package hashes and runs 13 actual Simulink component
   tests. It does not load the original thesis model, BOPTEST FMU or replay data.
   On success it saves three generated, editable SLX models (thermostat, valve,
   radiator) under a new outputs/c3/verification/ directory. There are no prebuilt
   SLX files: they are generated locally by the native-block builders.
4. Return the printed component_verification.json and the actual generated
   matlab_component_test_log.txt, including any failure diagnostics.
   Passing these tests establishes this component gate, not C3 building-reference
   validation. Review the actual results before proceeding to C3.4 integration.

To inspect a component after a successful run:

```matlab
addpath(fullfile(pwd,'scripts','matlab','c3'),fullfile(pwd,'scripts','matlab','boptest'))
P = load_c3_parameters();
[model, file, signals] = build_c3_component('radiator',P);
open_system(model)
```

The saved models have explicit root inputs. Use simulate_c3_component with declared
input data to execute them; do not interpret unspecified zero-Kelvin root inputs
as a physical experiment. Close/save an already open model before rebuilding. Models are
saved in new output directories, not over existing files. Test models and reports
may be numerous but contain no benchmark datasets. MATLAB tests stop the gate on
failure; the recursive exception report retains original messages/causes. A
missing toolbox/license must be resolved on the university installation. A package
hash mismatch requires fresh extraction, not editing the manifest.

Illustrative parameters are in configs/c3/illustrative_components.json. The runner
records their hash. To explore new assumptions, keep an untouched package and use
a separate configuration copy; changed source/config means a different experiment.
There is no boiler/pump pressure solve, source efficiency or fuel/electric energy
model. Delivered radiator heat and water-side heat are different quantities.

See docs/C3_COMPONENTS.md for equations, units, tests, limitations and the gated
C3.4–C3.6 plan. Existing C2.8 numerical results and execution-lineage qualifications
remain unchanged. Do not use C2.8 MAE as a C3 performance claim or proceed to C4.
