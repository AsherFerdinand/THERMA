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


## C2.6 solar-resolved partial replay

Download [THERMA_C26_solar_replay.zip](THERMA_C26_solar_replay.zip). SHA-256: `117ce27286e078080fb6766c77b1e9ad0939d6ecb39ae2b86f1f354d666364aa`.
Use updated work-branch source and docs/C26_SOLAR_BENCHMARK.md. This archive contains
actual original-FMU reference data, not a completed solar-resolved MATLAB replay.
No transfer-branch merge into development is intended.


## Standalone Windows MATLAB R2025a package (2026-11-02)

Download [THERMA_C26C_MATLAB_R2025a_e6c7d41_2026-11-02.zip](THERMA_C26C_MATLAB_R2025a_e6c7d41_2026-11-02.zip), extract and read START_HERE.md.
Includes pinned work source, tests/configuration, verified solar packet in place,
and run_verification.m. No Git/Python/Docker needed on the MATLAB computer.
The unchanged model builders generate SLX in MATLAB; no pre-generated SLX is claimed.
SHA-256: `bf872ff3700b2c14e7ab02e48470de105f5817c4f482b9280fb00072dad2fb63`. Source commit: `e6c7d41848701fa678b974ef7e343e40d0f8e3dd`.
No source-branch changes or artifact overwrites. MATLAB execution remains pending.


## C2.7 offline R2021a controlled numerical study (prepared)

Download [THERMA_C27_MATLAB_R2021a_2026-11-03.zip](THERMA_C27_MATLAB_R2021a_2026-11-03.zip), extract and read START_HERE.md.
Run run_verification("quick"), then run_verification("full") in MATLAB.
Full mode: no-solar/30 s and solar/30/15/5 s sequentially; hash-checked resume.
No MATLAB C2.7 execution or convergence results are claimed. C3 is design only.
SHA-256: `01b093ce8c684d62a1e90912af2d837672251faab8cc74158e590e061d575db6`. Source: `7516fd073fdf590162812048eaf3a844dc7e26f5`.


## C2.7 R2024a event export fix (university verification pending)

Download [THERMA_C27_EVENT_EXPORT_FIX_R2024a_2026-11-03.zip](THERMA_C27_EVENT_EXPORT_FIX_R2024a_2026-11-03.zip), extract and read START_HERE.md.
Run run_verification("quick"), then run_verification("full") in MATLAB.
Chunked %.17g staging, streaming verification, SHA256 publication and export diagnostics. Physics/solver inputs unchanged.
No MATLAB C2.7 execution or convergence results are claimed. C3 is design only.
SHA-256: `fd6a09d46981df83dfb68b3167c600107580465c841053b040572a1ac1587a96`. Source: `202df140773bc74a4fda3342cc543e580863a730`.


## C2.7 R2024a CSV EOF and cleanup correction (execution pending)

Download [THERMA_C27_EOF_CLEANUP_FIX_R2024a_2026-11-03.zip](THERMA_C27_EOF_CLEANUP_FIX_R2024a_2026-11-03.zip), extract and read START_HERE.md.
Run run_verification("quick"), then run_verification("full") in MATLAB.
Confirmed EOF distinguished from read failures; independent cleanup owner prevents destroyed fid access. CSV checks/physics unchanged.
No MATLAB C2.7 execution or convergence results are claimed. C3 is design only.
SHA-256: `b680eb85123d1bcc5a648ca74b8d8c9c43d81e0d0cccbe2bb21721c6a359e4a9`. Source: `28965ed1c83068b7d92d6a1e325584122b24a0b1`.


## C2.7 R2024a byte-bounded reader revision (MATLAB confirmation pending)

Download [THERMA_C27_R2024A_READER_FIX_2026-11-03.zip](THERMA_C27_R2024A_READER_FIX_2026-11-03.zip), extract and read START_HERE.md.
Run run_verification("quick"), then run_verification("full") in MATLAB.
Confirmed EOF distinguished from read failures; independent cleanup owner prevents destroyed fid access. CSV checks/physics unchanged.
No MATLAB C2.7 execution or convergence results are claimed. C3 is design only.
SHA-256: `6147bc270ff95be5c94637c236b123ce6bc0ca25c09e925840156b4e12827d86`. Source: `945acca7cbd8c43bd8050b7a768811ac5f1902b9`.


## C2.7 R2024a SHA-256 compatibility revision (MATLAB confirmation pending)

Download [THERMA_C27_SHA256_FIX_R2024a_2026-11-03.zip](THERMA_C27_SHA256_FIX_R2024a_2026-11-03.zip), extract and read START_HERE.md.
Run run_verification("quick"), then run_verification("full") in MATLAB.
Explicit primitive byte-array update handles empty/singleton chunks. CSV checks, cleanup and physics unchanged.
No MATLAB C2.7 execution or convergence results are claimed. C3 is design only.
SHA-256: `77e70085bbb45256a734195b7ea9e0adbbbdabdb43d330423a5562e565fc1fd6`. Source: `d63b98320c69d72043dd23ecd51dca7b49c2c84d`.


## C2.8 reference-temperature comparison (MATLAB confirmation pending)

Download [THERMA_C28_REFERENCE_MATLAB_2026-11-05.zip](THERMA_C28_REFERENCE_MATLAB_2026-11-05.zip), extract and read START_C28.md.
Follow START_C28.md to compare existing C2.7 results; do not rerun simulations.
Includes genuine BOPTEST reference temperatures, derived C2.8 metrics/figures and comparison code. Physics unchanged.
Python comparison is complete; MATLAB reproduction and duplicate prior solar-CSV execution lineage remain pending. No convergence certification is claimed.
SHA-256: `c27596e46cc6d89a081d5515f023311cd04331141032962acb8782d1c286f6a3`. Source: `a2a7f1be518f4a8f1b09e8b7b4cc961daf2610c7`.
