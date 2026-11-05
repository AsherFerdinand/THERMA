# THERMA C3.5 — heating-system engineering investigation

The supplied C3.4 report confirms 17/17 tests and a 24-hour integration passed in
MATLAB/Simulink R2025a. This package prepares **new** actual simulations; no C3.5
UA/supply/weather/solar sweep was executed in Codex Cloud.

1. Extract All into a new short writable local folder. Open THERMA_C35_MATLAB in
   university MATLAB/Simulink (R2025a evidence; R2024a API compatibility intended,
   not yet executed here). No Simscape, Git, Python, Docker, WSL, internet, FMU or
   old C2.7/C2.8/C3.4 directory is required. All source/configuration is included.
2. First run the short verification gate:

   ```matlab
   cd('PATH_TO_THERMA_C35_MATLAB')
   quickReport = run_c35_investigation("quick");
   ```

   This executes 13 unchanged component regressions plus three new tests, including
   an actual 120-second solar-source compile/energy probe. Stop if anything fails.
3. Run the highest-priority four-case UA investigation:

   ```matlab
   capacityReport = run_c35_investigation("capacity");
   ```

   Four new 24-hour runs: UA 60/90/120/180 W/K, all other physical assumptions
   identical. The original C3.4 configuration/evidence is never edited.
4. Then run the remaining requested investigation:

   ```matlab
   fullReport = run_c35_investigation("all");
   ```

   Verified capacity cases and the passed test gate are reused under the same
   source/configuration/release contract; their logs/hashes remain available. Cases run sequentially, not in parallel.
   The study covers supply 40/45/55/65 °C, outdoor −5/0/5/10 °C, paired absorbed
   solar/no-solar, conditional controller selection and 10/5/1 s sensitivity for
   baseline plus a case with an observed off event. Shared baseline cases are
   reused, not falsely presented as independent repetitions.

Outputs are under outputs/c3/c35/<contract-hash>/. The printed report references
completed cases and a unique summary folder containing results_table.csv/.json,
A/B/D/E temperature PNG/FIG plots, controller plot when available,
numerical_sensitivity.json and engineering_report.md. Individual cases contain
native cumulative energies, trace CSV, source/model metadata, diagnostics, figures
and completion checksums. Keep the entire tree for reproducibility.

Rerun the same command after interruption: only completed hash-verified cases with
the same source/configuration/MATLAB contract are skipped. Failed attempts remain
for diagnosis. Changing code, plan, release or baseline input creates a different
contract; no force-reuse across those changes is allowed. Close previously open
C2/C3 models before running. Disk use includes new generated SLX files and CSVs;
full simulations save no large simulation.mat objects.

If no A/B case reaches 21 °C, a separately labeled fallback controller probe uses
UA 180, supply 65 °C, outdoor 20 °C and initial air/fabric/radiator 20 °C. It does
not replace a failed baseline. If an A/B case reaches 21 °C but never switches off,
that partial controller evidence is reported without silently altering it. If no
selected case switches off, switched-case convergence is explicitly blocked.

Inspect actual results before asserting regulation, undersizing, solar savings or
convergence. Water-side energy is not boiler fuel/electric consumption. Send the
study JSON and complete summary folder first; case trajectories are needed for
further analysis. See docs/C35_INVESTIGATION.md for equations, metric definitions,
solar assumptions, inference limits and the incoming baseline evidence.
