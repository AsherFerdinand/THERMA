# C2.8 — compare existing C2.7 simulations, without rerunning them

This package contains genuine BOPTEST reference temperatures and comparison code.
It does **not** contain the C2.7 results stored on your university PC. Python-generated metrics and three-curve plots are included under docs/results/c28
and docs/figures/c28. MATLAB reproduction has not been executed in cloud.

1. Extract this ZIP into a **new** local folder alongside your existing
   THERMA_C27_MATLAB folder. Keep existing C2.7 results unchanged.
2. Open the new THERMA_C28_MATLAB folder as MATLAB R2024a's Current Folder.
3. Run the focused software tests (no simulation):

   ```matlab
   addpath(fullfile(pwd,'scripts','matlab','boptest'))
   results = runtests(fullfile('tests','matlab','test_boptest_temperature_validation.m'));
   assertSuccess(results)
   ```

4. Set the relative location of your existing study index and compare:

   ```matlab
   index = fullfile('..','THERMA_C27_MATLAB','outputs','boptest','c27', ...
       'tp699bca3b_8a25_4758_bc2c_6cf11011e6b7','study_index.json');
   assert(isfile(index),'Adjust the relative path to your actual C2.7 study index.')
   output = compare_boptest_c28(index)
   ```

   If the C2.7 study is inside this repository instead, run
   `output = compare_boptest_c28()`; automatic discovery requires exactly one index.

5. The printed new directory under outputs/boptest/c28 contains PNG/FIG temperature
   and error plots, metrics.csv, daily_metrics.csv, comparison_provenance.json and
   validation_report.md. Original simulations are read only. No Git, Python,
   Docker, WSL or internet is needed on the university PC.

Missing receipt/contract files: preserve the full C2.7 folder tree. Hash mismatch:
stop, retain original files and investigate; do not edit receipts. Scenario/source
mismatch: stop rather than substituting another trajectory. Operative temperature
cannot supply air-temperature validation errors. There is no extrapolation.

Send the comparison output folder back for engineering review. The two attached cases pass supplied receipt/hash checks and the approximately
7.154 °C trajectory separation is reproduced. The refinements/event logs were not
supplied. The new reports state R2024a, but the solar CSV is byte-identical to
earlier R2021a evidence; original execution lineage needs review. See
docs/C28_ENGINEERING_REPORT.md. No MATLAB test execution is claimed in cloud. See docs/C28_REFERENCE_VALIDATION.md for provenance.
