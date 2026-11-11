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


## C2.8 standalone reference-temperature comparison (MATLAB confirmation pending)

Download [THERMA_C28_STANDALONE_MATLAB_2026-11-05.zip](THERMA_C28_STANDALONE_MATLAB_2026-11-05.zip), extract and read START_C28.md.
Follow START_C28.md: compare_boptest_c28() uses the bundled original study inputs; no external C2.7 folder or simulation is required.
Includes the ten original C2.7 study files, genuine BOPTEST reference temperatures and C2.8 comparison code/results. Original hashes and physics unchanged.
Python comparison is complete; MATLAB reproduction and duplicate prior solar-CSV execution lineage remain pending. No convergence certification is claimed.
SHA-256: `026801895c81ba6442f79530172bf7b6b359606e612c013a90dd0be19e369714`. Source: `58d97674a697f4ccbeb34563b40b5ce734d7aec2`.


## C3.1-C3.3 isolated component verification (MATLAB confirmation pending)

Download [THERMA_C3_COMPONENT_VERIFICATION_R2024a_2026-11-05.zip](THERMA_C3_COMPONENT_VERIFICATION_R2024a_2026-11-05.zip), extract and read START_C3.md.
Run run_c3_verification() in MATLAB R2024a to execute the 13 native Simulink component tests. No reference datasets or external project folder is needed.
Includes thermostat, asymmetric valve and mixed radiator builders, illustrative parameters and analytical tests. C1/C2 physics and prior results preserved.
MATLAB execution remains pending. C3.4 integration and C3.5/C3.6 experiments are blocked at the requested component verification gate; no closed-loop C3 result is claimed.
SHA-256: `c56dd84a80e10f3214379a75f320ef11fc45144004adb0ec04999b20751f9355`. Source: `b5fd807d2e329d82d468e429655dafa9630d7f8e`.


## C3.4 independent closed-loop integration (MATLAB confirmation pending)

Download [THERMA_C34_CLOSED_LOOP_R2024a_2026-11-05.zip](THERMA_C34_CLOSED_LOOP_R2024a_2026-11-05.zip), extract and read START_C34.md.
Run run_c34_verification() in MATLAB R2024a: 13 component plus 4 integration/CSV tests, followed by one illustrative cold-start run. No external dataset/project folder is needed.
Includes copied-C2 integration builder, unchanged verified C3 components, explicit boundary conditions, source-only public R2025a component evidence summary, energy diagnostics and plotting code. C2/C2.8 results preserved.
Component evidence: 13 passed, R2025a. C3.4 MATLAB execution remains pending; no actual integration result or plot is claimed. C3.5/C3.6 remain gated.
SHA-256: `690da942c3311cc1d803ba830d949500edf00fe4f919224ae5f0a8a8ecda3cf2`. Source: `cd95158c28ee125dfb2a92ea74fb7365761f2ebb`.


## C3.5 heating-system engineering investigation (MATLAB confirmation pending)

Download [THERMA_C35_ENGINEERING_INVESTIGATION_2026-11-05.zip](THERMA_C35_ENGINEERING_INVESTIGATION_2026-11-05.zip), extract and read START_C35.md.
Run run_c35_investigation("quick"), then "capacity", then "all" in university MATLAB. Runs sequentially and reuses only source/contract/hash-verified cases. No old project/data folder is needed.
Includes UA/supply/outdoor/solar studies, conditional controller selection, native-energy/steady-load diagnostics and max-step comparisons. Original C3.4 baseline and sources preserved.
C3.4 actual evidence: 17 passed, R2025a, energy checks passed. New C3.5 MATLAB cases/results remain pending; no regulation, solar-saving or convergence claim is made. No C4.
SHA-256: `0cb342a0a75d11319c20c690d8a8bbfe0476fb33971a4888c76e26a095a66472`. Source: `b044bf082dbd5f337e0f17267435deb95eed71e8`.


## C3.6 physical check update

Download [THERMA_C36_PHYSICAL_CHECK_UPDATE_2026-11-06.zip](THERMA_C36_PHYSICAL_CHECK_UPDATE_2026-11-06.zip). Extract directly INTO your existing THERMA_C35_MATLAB folder, retaining completed C3.5 outputs. Read C36_UPDATE_INSTRUCTIONS.txt; run run_c36_physical_check. This is a small overlay, not a standalone replacement project. Reuses original baseline/UA180 results; zero new simulations. Includes concise report, exactly two actual-data plots and provenance metrics. New MATLAB entry/test unexecuted in cloud.

SHA256: `c1b36c656e44ef3afbb17310dd068892cf273c45542c874d71103c32f29c05e9`. Source `ddd7b11add29bd298d2ce76a1aa7fca8ae0be5dc`.


## C3.7 residential PREPARATION - manufacturer evidence missing

Download [THERMA_C37_RESIDENTIAL_PREPARATION_2026-11-06.zip](THERMA_C37_RESIDENTIAL_PREPARATION_2026-11-06.zip). Extract INTO the existing THERMA_C35_MATLAB folder. Read C37_PREPARATION_README.txt. This is a preparation overlay, NOT READY for the heating run: manufacturer rating missing and MATLAB execution pending. Room-only static test may be run. No fabricated rating, UA, flow or results; the entry point intentionally stops until a reviewed manufacturer document is supplied. Existing components/benchmark untouched.

SHA256: `c94bcb81da726b01eac550f558f4cd5b38eb65dc3feddd00597796cc8cde7774`. Source `afaa57b8604f3af6e30a228cebe33bd2e86010d0`.


## C3.7 Purmo residential update - native MATLAB execution pending

Download [THERMA_C37_PURMO_RESIDENTIAL_UPDATE_2026-11-06.zip](THERMA_C37_PURMO_RESIDENTIAL_UPDATE_2026-11-06.zip). Extract directly INTO the existing THERMA_C35_MATLAB folder, replacing old C3.7 preparation files only. Read START_C37.txt. This supersedes the earlier preparation-only package. Run the two C3.7 static tests, then run_c37_residential_heating for one24h simulation and exactly two plots. Purmo864W at55/45/20C is user supplied; matches UA34.56W/K,flow0.02066985646kg/s. Listed weight water inclusion remains unresolved: wet-mass interpretation is explicitly assumed. MATLAB execution remains pending; no dynamic manufacturer or real-world validation. Existing BESTEST/components unchanged.

SHA256: `f68326e515e68c5381b9a98b5b7fed6df1dd8e822a65623bfc15b4c342901cdb`. Source `224eec64e6696a467d187c334763ad1801a922f0`.


## C3.8 thermostat comparison - native execution pending

Download [THERMA_C38_THERMOSTAT_UPDATE_2026-11-08.zip](THERMA_C38_THERMOSTAT_UPDATE_2026-11-08.zip). Extract INTO the existing THERMA_C35_MATLAB folder containing the C3.7 Purmo update and completed outputs. Read START_C38.txt. Run the two C3.8 software metric tests, then run_c38_thermostat_comparison. Reuses a compatible original C3.7 result/CSV/saved model; only the0.5C case is simulated when baseline artifacts pass. Otherwise runs two cases in C3.8 outputs. Primary interval2-24h, exactly two plots showing2-8h. C3.7 sources/results and BESTEST remain unchanged; no efficiency or native comparison result claimed in cloud. No C3.9.

SHA256: `628695c1e8c842bca231b8dbe5b4d1e1171e1b425bcf9639b0b1940bf69ba9e8`. Source `c9b5469e2744ec38814c6a2304b9b9c55becedd8`.


## C3.9 preserved BOPTEST air comparison - no simulations

Download [THERMA_C39_BOPTEST_COMPARISON_UPDATE_2026-11-08.zip](THERMA_C39_BOPTEST_COMPARISON_UPDATE_2026-11-08.zip). Extract INTO the existing THERMA_C35_MATLAB folder. Read START_C39.txt; run the two C3.9 software tests then run_c39_boptest_comparison. Includes compact verified DERIVED actual-data tables and exactly two plots, with no old C2.7/C2.8 folder dependency. Solar air MAE0.792534195K,RMSE0.923975534K; operative reaTRoo_y is excluded. Heating input consistency only, not independent equipment validation. Retains solar execution-lineage and sampled-energy limitations. Actual Python post-processing complete; native MATLAB reproduction unexecuted in cloud. C3.7/C3.8 and BESTEST unchanged; no C4.0.

SHA256: `3fd6c9974c5201ae61c5869eba0c5ebb49ab0998502672535b576085c38217db`. Source `30ea3c50f71b95957cf5b5f75d22950d3e44c5e4`.


## C4.0 integrated residential heating workbench - native build pending

Download [THERMA_C40_HEATING_SYSTEM_UPDATE_2026-11-08.zip](THERMA_C40_HEATING_SYSTEM_UPDATE_2026-11-08.zip). Extract INTO the existing THERMA_C35_MATLAB folder with C3.7/C3.8 updates and original C3.7 result/CSV/model. Read START_C40.txt; run two comparator software tests then run_c40_heating_system. The script generates/opens THERMA_C40_HeatingSystem.slx, runs one24h demonstration and compares C3.7 temperature/power/demand/energy. Four named physical subsystems plus one passive results group; no changed thermal equations or solver settings. This SOURCE update contains no prebuilt SLX or fabricated result: native model/layout/test/run/reproduction remain pending. One result figure only; original artifacts preserved. No subsequent phase.

SHA256: `f7964f6609f62f450ba80e3c07b857ed0aeaa94753e0c9beae58dea689c8ca45`. Source `40973742501e0930c24786b72b91613fdbffc0c0`.


## C4.2 Annex58 inspection - BLOCKED, not integrated

Download [THERMA_C42_ANNEX58_INSPECTION_BLOCKED_2026-11-08.zip](THERMA_C42_ANNEX58_INSPECTION_BLOCKED_2026-11-08.zip). Extract into existing THERMA_C35_MATLAB; read START_C42.txt. run_c42_reference_inspection reports missing originals/unknown geometry/signals and writes a summary only. No actual PDF or measurement archive obtained; no geometry, processed data or temperature plot fabricated. DOI and publisher/metadata routes blocked locally by proxy403; file download URL/status unknown. User must provide the official specification PDF, archive structure and genuine measurements for continuation. No Annex71 substitution or automatic FRP-2 fallback. C4.2 incomplete; no C4.3.

SHA256: `bac92878c4b5bdc638308ffc8181d385b151695037e0a9593435bc11c18c8aa2`. Source `65383b49d73d2b5854592957d4af2c1003586bc0`.


## C4.2B FLEXLAB measurement inspection

Download [THERMA_C42B_FLEXLAB_INSPECTION_UPDATE_2026-11-08.zip](THERMA_C42B_FLEXLAB_INSPECTION_UPDATE_2026-11-08.zip). Extract into existing THERMA_C35_MATLAB and read START_C42B.md. Inspection code/docs and genuine-measurement previews only; six original CSVs must be downloaded directly from pinned official source URLs in the ZIP. No raw datasets redistributed. No simulation/model change. CONDITIONAL separate Cell3B benchmark; not a residential building. Native MATLAB execution pending.

SHA256: `5a808c3731d38c632a35849f4a8f2fd51f87b1cbfad8c8c8f5fafca40c6548f3`. Source `cf8a6b73e2be305e3669f645b2960f92af9fa01a`.


## Lightweight MATLAB execution — 2026-11-10

[THERMA_C42B_RUN_2026-11-10.zip](THERMA_C42B_RUN_2026-11-10.zip): 67079bytes,17files. Extract in a NEW EMPTY folder; read MATLAB_QUICKSTART.md. C42B inspection only, base MATLAB R2025a/JVM; six external original CSVs verified by hash, not bundled. Includes a read-only audit of the old university folder. No simulation, no deletion and no native verification of this new wrapper claimed. Preserve original SLX/results until archival gaps close. Source `c408225aaaaf07f3394e1646ce140b4ea3fcca0c`.

SHA256 `472d1e74bb34cc59f63a8c829c6100946dc3220d96a28740ce659e78adbf84ee`.


## University history preservation — 2026-11-11

[THERMA_HISTORY_ARCHIVER.zip](THERMA_HISTORY_ARCHIVER.zip) — 140327bytes. Extract separately;read HISTORY_ARCHIVER_README.md and run its native self-tests. Base MATLAB R2025a/JVM only. Plan279 original files includingall36 audited SLX,12 parts plus catalog. Worst-case destination budget446,046,747bytes;choose a separate location with at least450MB capacity. No historical bodies included in this toolkit. New native archiver unexecuted in cloud;no remote-backup/deletion claim.

SHA256 `0c46c1aaeca0708db1573614b622ad4df79c59c7798200bb89b9a44d61f8e5e1`;source `8968ffa4fa396f27499a714a9336e31b2082080d`.


##80MB incremental history archival

[THERMA_HISTORY_ARCHIVER_INCREMENTAL_2026-11-11.zip](THERMA_HISTORY_ARCHIVER_INCREMENTAL_2026-11-11.zip) — 169670bytes. Read INCREMENTAL_HISTORY_README.md. ONE ZIP per call,40MB source payload/hard45MB ZIP cap;oversized originals use lossless byte ranges. Stream fresh download verification without a second disk copy;move only remotely verified generated ZIP externally before next call.36 separately released model versions downloaded/SHA-verified;243 originals remain. Catalog tracks file/range/part progress. No original deletion/modification;new MATLAB code native-pending.

SHA256 `10c0f32b7c24ea594fcff41bc95a6bd70bf4a6de30f557dc212ec476bf999aa8`.


##80MB incremental history archival

[THERMA_HISTORY_ARCHIVER_INCREMENTAL_2026-11-11_r2.zip](THERMA_HISTORY_ARCHIVER_INCREMENTAL_2026-11-11_r2.zip) — 170028bytes. Read INCREMENTAL_HISTORY_README.md. ONE ZIP per call,40MB source payload/hard45MB ZIP cap;oversized originals use lossless byte ranges. Stream fresh download verification without a second disk copy;move only remotely verified generated ZIP externally before next call.36 separately released model versions downloaded/SHA-verified;243 originals remain. Catalog tracks file/range/part progress. No original deletion/modification;new MATLAB code native-pending.

SHA256 `7c3732b559e04c92be8c553561017a25198454232f2ef9938dc29dece157d945`.


##80MB incremental history archival

[THERMA_HISTORY_ARCHIVER_INCREMENTAL_2026-11-11_r3.zip](THERMA_HISTORY_ARCHIVER_INCREMENTAL_2026-11-11_r3.zip) — 170124bytes. Read INCREMENTAL_HISTORY_README.md. ONE ZIP per call,40MB source payload/hard45MB ZIP cap;oversized originals use lossless byte ranges. Stream fresh download verification without a second disk copy;move only remotely verified generated ZIP externally before next call.36 separately released model versions downloaded/SHA-verified;243 originals remain. Catalog tracks file/range/part progress. No original deletion/modification;new MATLAB code native-pending.

SHA256 `b992fe92fbf47009140e64570f258b28a0251e286defe7fea08a33c6e113e043`.
