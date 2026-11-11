# Milestone preservation inventory — 2026-11-10

This inventory separates **source**, **generated native models**, and **execution
evidence**. Builders are not archived `.slx` models. Source snapshot
`a57a62aa823624688a62ccde0ac7ed8a039a210e` contains all milestones below. GitHub
branch tips were checked on2026-11-10; main/work/feature branches were retained.
The source tree contains **no tracked `.slx`, `.mat` or execution ZIP**. There are
also no native `.slx` models in any of the22 preserved transfer ZIPs. Cloud local
`.slx` count is0. The original thesis SLX is an external reference, not vendored.

| Milestone | Recoverable source commit | Source/configuration | Actual model artifact | Results and reproducibility |
|---|---|---|---|---|
| C1/C2 | `7b2e943b196c919684caf1abccb29d09507f6d1b` (work; also in source snapshot) | scripts/matlab/boptest/build_boptest_envelope_c1.m,build_boptest_zone_c2.m,load/verify scripts;configs/references/ | Native SLX **NOT YET BACKED UP** | C2 original verification.json+provenance at verification/c2/matlab-r2025a/b00092e4236789a4/; recorded execution revision071269e. C1 full report **NOT YET BACKED UP**. Current builders are source, not independently executed in cloud. |
| C2.5/C2.6C | Same snapshot/work history | Replay/solar/comparison scripts;configs/references/ | Native generated SLX/MAT **NOT YET BACKED UP** | Compact numerical reports/figures at docs/results/; prepared packets on replay-transfer. Raw uploads/FMU runs are ignored local files, not automatically backed up by plots or results-only ZIPs. Preserve originals separately. |
| C2.8 | `5001234d24964991b1348b122bd7929a8a866715` | compare_boptest_c28.m,run_verification.m;docs/results/c28/ | No native SLX in archive; comparison can post-process without one | THERMA_C28_STANDALONE_MATLAB_2026-11-05.zip contains original verified no_solar_30/solar_30 evaluation trajectories,study_index,provenance and pinned reference. Hash026801895c81ba6442f79530172bf7b6b359606e612c013a90dd0be19e369714. Execution-lineage qualifications remain. |
| C3.1–C3.3 | `d553cf4b67f0d954bd2aabacc700d474ac645a9c` | scripts/matlab/c3/{add_c3_thermostat,add_c3_valve,add_c3_radiator,build_c3_component}.m;configs/c3/ | Generated native component SLX **NOT YET BACKED UP** | verification/c3/component_gate/ contains selected summary and actual log:13/0/0,R2025a. Original private JSON is ignored/cloud-only: **NOT YET BACKED UP ON GITHUB**. Do not mistake summary for original. |
| C3.4 | Same component branch/source snapshot | run_c34_verification.m,build_c34_model.m,assess/export/simulate helpers;configs/c3/integration_c34.json | Native SLX and trajectory **NOT YET BACKED UP** | verification/c3/c34_gate/ selected summary:17/0/0,R2025a; redacted log separately labelled. Original private report/log ignored/cloud-only, not publicly backed up. |
| C3.5 | `ebb5f865a0cdf0353c3b176655d77888ea16a037` | run_c35_investigation.m,scripts/matlab/c35/,configs/c35/ | Native study SLX/MAT **NOT YET BACKED UP** |16 tests user-reported; no original test log archived. Selected case reports/completion at verification/c3/c36/; see next row for original CSV recovery. |
| C3.6 | `ad709a0a76a3abe939db7f22ecccb4bd941d4c81` | run_c36_physical_check.m,c36_specs.m;docs/C36_PHYSICAL_CHECK.md | No new model (read-only investigation); old native models unbacked | Actual UA60/180 case reports/completion tracked. The C36 transfer ZIP contains the report/derived plots and scripts, **not the original two trajectory CSVs**. Those original CSVs, other C3.5 cases and MAT/model files are **NOT YET BACKED UP ON GITHUB**. Preserve PC/cloud originals separately. |
| C3.7 | `1dfdbb68798b428287bf0a79c699214cb0939e3a` | run_c37_residential_heating.m,scripts/matlab/c37/,configs/c37/ | Native residential SLX **NOT YET BACKED UP** | Successful R2025a execution user-reported; original report/trajectory/MAT **NOT YET BACKED UP**. Manufacturer transcription preserved at verification/c3/c37/. |
| C3.8 | `435d66b06af8361e9b74372525641703d3868026` | run_c38_thermostat_comparison.m,scripts/matlab/c38/ | Native generated models **NOT YET BACKED UP** | Supplied comparison summary reviewed and metrics documented. Original supplied JSON and both original trajectories/full native logs are not tracked: **NOT YET BACKED UP**. |
| C3.9 | `3c9cb2074eb8395169b1dd917f9208668aeab61d` | run_c39_boptest_comparison.m,c39_metrics.m;docs/results/c39/ | Post-processing, no new physical model | Existing genuine baseline/reference reused; C39 transfer ZIP preserves comparison inputs. R2025a reproduction user-reported; native returned outputs/log **NOT YET BACKED UP**. |
| C4.0 | `73deb0b694bd17534ba42f32c7f981ffdab410e1` | run_c40_heating_system.m,scripts/matlab/c40/ | THERMA_C40_HeatingSystem.slx **NOT YET BACKED UP** | Reproduction user-reported; actual native verification,figure/MAT/SLX **NOT YET BACKED UP**. Builder/config preserved, not a saved generated model. |
| C4.1 | `69e4af0e16fea1c5bd10445468852951a81feabd` | C41 assessment/diagram,data/reference_building/README.md | No model intended | Documentation-only conditional assessment; original measurements unavailable. |
| C4.2 | `3debf556067e11976bc31ff0f60924af86ca77a8` | run_c42_reference_inspection.m,configs/buildings/annex58_experiment1.json,C42 docs | No model intended | Blocked scaffold; original Annex58 PDF/data not acquired. Inspection-only ZIP is not an integrated dataset. |
| C4.2B | `a57a62aa823624688a62ccde0ac7ed8a039a210e` | run_c42b_flexlab_inspection.m,C42B docs,source_audit.json | No model intended | Genuine-source audit/plots tracked. Actual R2025a inspection accepted2026-11-11 at results/C42B/c146fd42ee036a3a/. Original returned ZIP recoverable encrypted;private key separate. No simulation/model validation. Raw FLEXLAB originals remain external. |

## Exact-byte recovery

[tools/preservation_manifest.json](../tools/preservation_manifest.json) contains553
unique SHA-256 identities from the pinned source snapshot and all files/members in
22 transfer ZIPs at commit`647a7a81a00ab9462e9c754e190b45a962fae513`. Archive ZIPs
were CRC-read while hashing members. A location is either a Git file or a member
inside an immutable Git ZIP. Use the recorded commit rather than a moving branch:
`https://github.com/AsherFerdinand/THERMA/raw/<commit>/<path>`; for members download
that ZIP and extract the named member. This checks preservation, not native success.

Run `audit_therma_local_storage('C:\PATH\TO\THERMA_C35_MATLAB')` from the new
lightweight package before deleting anything. It hashes local files, identifies
byte matches (even under renamed folders), reports unbacked artifacts and exact ZIP
duplicates, and writes JSON/CSV. It never deletes. The current verified package's
source hashes supplement the older preservation snapshot. Unreadable files and
unmatched autosaves/models/results must be retained. The inventory cannot infer
that a file never existed merely because it was not uploaded.

**Before cleanup, return or privately archive the NOT YET BACKED UP files.** Native
SLX snapshots are valuable even with a verified builder. Preserve full original
reports privately if they contain network/user paths; public selected/redacted
copies must link original hashes and cannot substitute for original backup.
For large/private binaries, record an accessible controlled archive and its hash;
do not add large data to normal Git history or claim a local-only copy is a backup.

## 2026-11-11 actual C42B evidence

See [the archived native inspection](../results/C42B/c146fd42ee036a3a/README.md).
The original private-path ZIP is preserved encrypted at an immutable GitHub URL
with original/ciphertext hashes and separate private recovery key. Public redacted
log is explicitly derived;original JSON/PNG bytes unchanged. No cloud MATLAB run.
