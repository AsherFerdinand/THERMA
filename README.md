# THERMA replay transfer only

This independent branch carries generated transfer data. Do not merge it into work
or main. Development source and documentation remain on work.

Download THERMA_first_typical_replay.zip, verify SHA256SUMS, and extract the data ZIP
into your existing THERMA source root. Do not use this branch as the source checkout.
No Git, Python, FMU or Docker is needed at university for the prepared replay.

In MATLAB R2025a, save/close an existing generated C2 model and run:

```matlab
cd('C:\YOUR\PATH\THERMA');
addpath(fullfile(pwd,'scripts','matlab','boptest'));
unzip('C:\YOUR\DOWNLOADS\THERMA_first_typical_replay.zip',pwd);
packet = fullfile(pwd,'outputs','boptest','replay_inputs','first_typical','replay.json');
assumptions = fullfile(pwd,'configs','references','c2_reduced_assumptions.json');
[info,data] = load_boptest_replay(packet);
reportFile = run_boptest_zone_replay(packet,assumptions,'AllowPartial',true);
disp(reportFile);
```

Data must have 60481 rows and 12 columns. The experiment runs seven warm-up days
and fourteen evaluation days, not 21 days of wall time. It explicitly omits missing
absorbed solar and uses provisional uniform declared initial temperatures.
Successful status is executed_partial_not_validated, not a BOPTEST validation pass.

Return evaluation.csv, comparison_metadata.json and replay_run.json from the printed
run directory to Codex. On failure return replay_run.json and the MATLAB diagnostic.
The ZIP's bytes are unchanged from the originally prepared transfer artifact.


## Actual C2.5C results-only bundle

Download THERMA_first_typical_actual_analysis.zip for six PNG/PDF figure pairs,
metrics.json, engineering_summary.md and supplementary integrity/input/temperature
reports and reproduction script. Check C25C_ANALYSIS_SHA256SUMS. This bundle excludes
raw MATLAB uploads, reference CSV datasets, simulation models and runtime caches.
Results are exploratory partial-forcing comparisons, not BOPTEST validation.
