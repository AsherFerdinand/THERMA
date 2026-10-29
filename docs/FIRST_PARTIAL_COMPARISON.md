# First partial comparison — university transfer

Current priority: execute one typical-heating partial replay and compare its outputs
before C2.6 physics development. No Git, Python, FMU binary, native runtime or Docker
is required on the university MATLAB computer when using the prepared transfer ZIP.

## Latest MATLAB test evidence

The user reports executing the latest work-branch MATLAB tests on R2025a:
**8 passed, 0 failed, 0 incomplete, 23.5779 seconds**, including test_boptest_replay.
No raw test log was supplied or archived. This is university execution reported by
the user, not execution reproduced in Codex. Passing the packet test does not mean
that the full 21-day reference replay has run or that reference agreement is established.
The original successful ten-scenario C2 report remains archived unchanged.

## Recommended transfer: existing source plus prepared data

1. Keep the latest THERMA source already downloaded from the work branch. If needed,
   use https://github.com/AsherFerdinand/THERMA/archive/refs/heads/work.zip and extract it.
2. [Download THERMA_first_typical_replay.zip from the separate transfer branch](https://github.com/AsherFerdinand/THERMA/raw/refs/heads/replay-transfer/THERMA_first_typical_replay.zip).
   Copy it by USB, approved university storage or direct browser download.
   The transfer branch contains data only; keep using work for THERMA source.
3. Set MATLAB Current Folder to the THERMA root (the directory with scripts/configs).
   Extract the data ZIP into that root, not into scripts/matlab.

The data ZIP is excluded from the development branches. It is hosted only on the
independent replay-transfer branch, which must never be merged into work or main.
Its SHA-256, verified after upload using a fresh isolated Git fetch, is
`b8a9e791b26554781360a07454db63c38bc0ff9410a60bb4a90561d675c5787d`.
It contains:

```text
outputs/boptest/replay_inputs/first_typical/inputs.csv
outputs/boptest/replay_inputs/first_typical/replay.json
outputs/boptest/normalized/first_typical/normalized.csv
outputs/boptest/normalized/first_typical/metadata.json
outputs/boptest/reference_provenance/first_typical/manifest.json
outputs/boptest/reference_provenance/first_typical/signals.json
outputs/boptest/transfer/first_typical/bundle_manifest.json
outputs/boptest/transfer/first_typical/README.md
```

Only the first two files are needed for the MATLAB run. The normalized reference is
included for offline comparison, and original provenance plus per-file hashes make
the transfer traceable. Full original 61-column datasets and the FMU are unnecessary
for this run; original-data reproduction remains available on Linux if needed.

## Exact MATLAB commands

Save and close any old generated C2 model before building another. Replace example
paths with your real THERMA root and downloaded ZIP location:

```matlab
cd('C:\YOUR\PATH\THERMA');
addpath(fullfile(pwd,'scripts','matlab','boptest'));
% Skip this line if you already extracted the ZIP into this repository root.
unzip('C:\YOUR\DOWNLOADS\THERMA_first_typical_replay.zip',pwd);

% Verify every included data file before execution.
manifestFile = fullfile(pwd,'outputs','boptest','transfer', ...
    'first_typical','bundle_manifest.json');
transfer = jsondecode(fileread(manifestFile));
for k = 1:numel(transfer.files)
    file = fullfile(pwd,transfer.files(k).path);
    assert(strcmp(boptest_file_sha256(file),transfer.files(k).sha256), ...
        'Transferred file hash mismatch: %s',file);
end

packet = fullfile(pwd,'outputs','boptest','replay_inputs', ...
    'first_typical','replay.json');
assumptions = fullfile(pwd,'configs','references','c2_reduced_assumptions.json');
[info,data] = load_boptest_replay(packet);
size(data)  % expected 60481 rows, 12 columns: time plus 11 inputs
reportFile = run_boptest_zone_replay(packet,assumptions,'AllowPartial',true);
disp(reportFile);
runReport = jsondecode(fileread(reportFile));
disp(runReport.status);
```

Use a fresh extraction directory if these packet paths already contain valuable
files; MATLAB unzip can overwrite files. The model outputs use a new unique directory.

The period is seven warm-up days plus fourteen evaluation days: 1,814,400 solver
seconds (not a wall-clock runtime estimate), 60,481 forcing samples at 30 s spacing.
Outdoor temperature is piecewise linear; powers are held. Evaluation remains original
absolute seconds 28,857,600 through 30,067,200; initialization starts at 28,252,800.

Expected successful execution status is `executed_partial_not_validated`. The report
intentionally keeps `matlab_verified=false`: this replay is not the verification suite.
Missing absorbed solar is explicitly omitted, uniform initial fabric/air temperatures
are provisional, and reduced physics differs from BOPTEST. No closeness threshold
or accuracy pass is assumed. The new long replay has not executed in Codex.

## Return these results for the first comparison

From the unique folder printed by reportFile, upload to Codex:

- `evaluation.csv`
- `comparison_metadata.json`
- `replay_run.json`

Do not transfer the large simulation.mat or generated .slx unless needed for debugging.
If execution fails, send replay_run.json and the full MATLAB diagnostic instead.
The first comparison and plots can run in Codex, so Python is unnecessary at university.

If Python/uv is available on another computer, copy those three files back while
keeping their contents unchanged, and run from THERMA root:

```sh
uv run --frozen --with matplotlib==3.10.8 python scripts/boptest/compare_results.py \
  outputs/boptest/normalized/first_typical/normalized.csv \
  outputs/boptest/normalized/first_typical/metadata.json \
  outputs/boptest/replays/ACTUAL_RUN/evaluation.csv \
  outputs/boptest/replays/ACTUAL_RUN/comparison_metadata.json \
  outputs/boptest/comparisons/first_typical.json \
  --classification exploratory_comparison --allow-scenario-difference \
  --plots outputs/boptest/comparisons/first_typical_plots
```

Replace ACTUAL_RUN with the copied unique run folder. Reports preserve both scenario
IDs and the missing-input limitations. Compare air with air, delivered heat with
transformed radiator port heat, never with fuel or pump electricity. Prescribed
heating-input agreement is an input-routing check, not heating-equipment validation.

## Reproduce the prepared files if the transfer ZIP is lost

On the existing Codex workspace, or a Python computer possessing the original
hash-checked typical run directory, use new output directories if these already exist:

```sh
uv run --frozen python -m therma.validation.replay \
  --run outputs/boptest/runs/typical_heat_day_ailcox5y \
  --output outputs/boptest/replay_inputs/first_typical --partial
uv run --frozen python scripts/boptest/normalize_results.py \
  outputs/boptest/runs/typical_heat_day_ailcox5y \
  outputs/boptest/normalized/first_typical
```

Both utilities verify source artifact hashes; the prepared file byte hashes can be
checked with bundle_manifest.json. Preparation metadata has the actual original
manifest/trajectory/signal hashes, transformations and initialization policy. The
transfer manifest also identifies source commit 18b520088fae88cfeb6abb955c2f8892e104c979.

If the original datasets are unavailable, regenerate Phase B on **Linux x86-64**
using the exact [FMU reproduction commands](BOPTEST_BASELINE.md#reproduction-commands).
The stored FMU's native binary requires Linux and libgfortran4; running it directly
on university Windows is not the simple path. A source ZIP works without Git, but
the documented native-runtime bootstrap still needs Docker on the Linux machine.
Use the new run directory printed by the runner in the two preparation commands.
Reproduced manifest timestamps/hashes can differ; retain the new actual provenance
and do not relabel it as the archived original run.
