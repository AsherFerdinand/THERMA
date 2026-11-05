# C2.8 — standalone MATLAB comparison

This ZIP includes the original verified no_solar_30 and solar_30 trajectories,
their unchanged study index/contract/receipts, genuine BOPTEST reference temperatures
and all comparison code. The old C2.7 folder is not needed. No simulation is rerun.

1. Extract the **standalone** ZIP into a new, writable local directory using
   Windows **Extract All**. Open its THERMA_C28_MATLAB folder in MATLAB R2024a.
   Keep the full outputs folder included in the ZIP.
2. Run:

   ```matlab
   cd('PATH_TO_THERMA_C28_MATLAB')
   addpath(fullfile(pwd,'scripts','matlab','boptest'))
   output = compare_boptest_c28();
   ```

   Replace PATH_TO_THERMA_C28_MATLAB with your extracted directory. The function
   locates the bundled study through C28_PACKAGE_PROVENANCE.json, verifies all ten
   original study artifact hashes and then performs the comparison.
3. Open the printed new directory under outputs/boptest/c28. It contains
   temperature_comparison.png/.fig, temperature_errors.png/.fig, metrics.csv,
   daily_metrics.csv, comparison_provenance.json and validation_report.md.
   Earlier numerical results and original inputs are not overwritten.

Optional focused software tests (no simulation):

```matlab
results = runtests(fullfile('tests','matlab','test_boptest_temperature_validation.m'));
assertSuccess(results)
```

No Git, Python, Docker, WSL, internet or separate C2.7 project is required on the
university PC. MATLAB execution of this package remains pending university testing;
cloud verification checked extraction, original hashes and actual Python comparison.

Missing/changed bundled artifact: extract a fresh copy of the standalone ZIP,
including its outputs directory. Do not edit receipts or substitute trajectories.
An older ZIP intentionally reports that it is incomplete rather than silently
searching for an external C2.7 directory.

Scientific qualifications remain unchanged: this evaluates reduced-zone response
to prescribed reference radiator heat. The solar CSV matches earlier R2021a
evidence while the supplied C2.7 reports state R2024a; execution lineage needs
review. Refinement trajectories and energy-event files were not supplied and are
not bundled or claimed verified. See docs/C28_ENGINEERING_REPORT.md.
