# THERMA C3.4 — standalone closed-loop integration verification

This package includes the C2 building generator/frozen parameter registry, verified
C3 component sources, new integration builder, explicit conditions, evidence
summary, tests and plotting/report code. **No C2.7/C2.8 folder, FMU, dataset, Git,
Python, Docker, WSL or internet is needed on the university computer.**

The prior component evidence is **R2025a: 13 passed / 0 failed / 0 incomplete**,
34.125 s. This package targets MATLAB/Simulink R2024a using native blocks. C3.4 has
not been executed in Codex Cloud. There are no fabricated integration results,
plots or prebuilt SLX files; MATLAB builds/saves the new model locally.

1. Extract All into a **new writable local directory**, preferably a short path
   such as C:\THERMA_C34. Open the extracted THERMA_C34_MATLAB folder in MATLAB.
   Do not overwrite an earlier project or run inside the ZIP. Close existing C2
   and C3 component/integration models before starting; the builder refuses to
   overwrite an open model.
2. Run:

   ```matlab
   cd('PATH_TO_THERMA_C34_MATLAB')
   reportFile = run_c34_verification();
   ```

3. The runner checks every package hash and prior source/configuration gate, then
   executes **13 component regression tests plus 4 integration/CSV tests**. If
   they pass, it runs the single illustrative 24-hour cold-start integration and
   writes actual diagnostics and plots. No six-scenario C3.5/C3.6 study runs.
4. Inspect the new printed outputs/c3/c34/... directory:

   - c34_verification.json: actual version, test counts, status, source/config
     identity, model hash and numerical checks.
   - matlab_integration_test_log.txt: actual MATLAB console test diagnostics.
   - closed_loop_traces.png/.fig and energy_balances.png/.fig.
   - integration_trajectory.csv and trajectory_metadata.json (hash, row count).
   - engineering_report.md with observed temperatures/powers and energy closure.
   - A nested build directory containing THERMA_C34_ClosedLoop.slx and the build
     and integration-diagnostics JSON files.

The default starts air/fabric/radiator at 15 °C, setpoint 21 °C, imposed supply
55 °C, held outdoor 5 °C, zero internal gains, zero absorbed solar and enabled
heating. Those boundaries are explicit illustrative assumptions, not BOPTEST data.
The radiator need not be correctly sized or attain the setpoint.

A passed status means numerical integration checks, **not** reference or real-world
validation. Inspect every failed check and the actual plots; no result is clamped
or recalibrated. Partial/failed runs remain in their own folders. Failure diagnostics
retain nested MATLAB causes. No existing C2.8 result or component evidence is
modified. If the initial test suite fails, no nominal 24-hour run is attempted.

Return c34_verification.json and matlab_integration_test_log.txt together with the
new engineering report/figures and trajectory for review. Do not begin C3.5/C3.6
until C3.4 results have passed review. See docs/C34_INTEGRATION.md for equations,
checks and approximation limits.
