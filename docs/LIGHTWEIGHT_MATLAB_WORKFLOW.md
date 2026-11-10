# Lightweight MATLAB execution and evidence return

## Scope and trust

This maintenance release supports **C42B inspection only**,using its existing
unchanged inspection script. Other milestones retain original runners;no unverified
migration of C1–C4 simulations or numerical settings is claimed. The declarative
experiment at experiments/C42B.json names entry points and transitive local MATLAB
dependencies. The cloud Python builder follows that closure,checks repository-local
calls against the selected files and excludes environments,tests,raw data,models,
old ZIPs and unrelated documents. Native toolbox/path/compiler behavior still
requires the university gate. This is not an automatic MATLAB dependency analyzer.

Cloud developer (not university PC):commit reviewed sources,then run

```bash
uv run --frozen python tools/build_matlab_package.py C42B --output outputs/fresh_run
```

Builds use committed Git bytes,not a mixture of dirty files with an old source
hash. Existing ZIPs are never overwritten. The resulting THERMA_C42B_RUN.zip has a
source commit,full per-file SHA256/size manifest,experiment configuration,one short
README/quickstart,the unchanged inspection and its exact helper closure. The
preservation manifest/read-only local audit are safety utilities,not copies of all
historical source. The packaged docs/results/c42b/source_audit.json is a declared derivative containing
only the six required external file identities/URLs/hashes and original metadata
hash;all prior measured extrema/statistics and plots are omitted. Its transformation
is rechecked against Git source when results return. No measurements are embedded. No native model/build script is needed for this inspection.

External inputs remain in a shared dataset folder. acquire_therma_inputs verifies
exact six original filenames/bytes/hashes from official immutable LBNL URLs. Its
default mode is verify;explicit download mode requires Internet and never overwrites
changed originals. No credentials or entire upstream repository are required.
A partial failed download is retained for review,not silently installed/deleted.

**University PC:**follow MATLAB_QUICKSTART.md in a fresh empty folder. The runner
checks package integrity,exact R2025a release and base MATLAB availability/JVM,
verifies external inputs,then calls the unchanged inspection. It uses explicit
helper paths and restores the previous MATLAB path. Simulink is not required.
There is no solver;solver metadata explicitly says not applicable. No thermal
physics,controller,reference inputs or previous results are modified.

## Result package

Each attempt has a new outputs/executions/<unique run>/ folder. On normal completion
or caught execution failure,the MATLAB packager creates **THERMA_RESULTS_C42B.zip**
and an adjacent SHA256 receipt. A failed run is labelled failed,contains original
nested diagnostics and is rethrown after the diagnostic ZIP is saved. Package
integrity/path-shadowing failure stops before execution. A packaging/filesystem failure itself
leaves the loose result folder for recovery;it must not be described as archived.

Included artifacts:verification.json,original package_manifest.json,exact experiment
configuration,SOURCE_COMMIT.txt,MATLAB diary,available inspection summary and two
measured PNGs,result_manifest.json with sizes/hashes. No raw measurement arrays,
large histories,reference datasets,old results or generated models are collected.
There is no simulation_results.mat because **no simulation occurs**. No essential
simulated history is silently downsampled. C42B's essential numerical evidence is
its complete721-row source/input checks and channel/missing/gap summary;original
measurements remain externally identifiable by hash. Future simulation manifests
must explicitly preserve essential signals/models before being supported.

Prefer<5MB result ZIPs;larger scientifically essential results need a documented
archive rather than silent reduction. Hashes bind content and source provenance;
they are not digital signatures or independent proof of MATLAB execution.
The new wrapper/audit/packager still need native university execution.

## Return,verify,archive

1. User supplies the actual generated ZIP and its checksum;retain the run folder
   and original measurements until receipt. Logs/errors may contain local/network
   paths and must be privacy-reviewed before public posting.
2. Codex saves original bytes under ignored evidence_import/ and verifies without
   altering them:

```bash
uv run --frozen python tools/verify_matlab_results.py evidence_import/THERMA_RESULTS_C42B.zip
```

3. The verifier rejects unsafe/duplicate/unlisted paths,changed/truncated files,
   excessive expanded size,missing artifacts,source/config hash mismatches,wrong
   successful-release/input identity and contradictory inspection/simulation status.
   It checks source objects at the recorded commit. Failed execution exits2 and is
   never treated as successful. Verification is software/provenance review,not
   independent MATLAB execution or empirical validation.
4. Review actual diagnostics/plots/numerical checks,execution claims and privacy.
   Preserve the original ZIP unchanged in an appropriate private/permissioned archive
   if it contains personal paths. Record its SHA256,source revision,status,location
   and any redaction mapping. Publish compact permitted originals or clearly-labelled
   derived/redacted copies under results/C42B/<original-ZIP-hash-prefix>/ with that
   receipt. Never claim a redacted summary is the complete original backup.
5. Update docs/PROGRESS.md and PROJECT_MILESTONE_ARCHIVE.md,then commit only the
   reviewed compact evidence/receipt to the appropriate development branch. Report
   the commit URL and verify remote bytes. Use a reviewed GitHub release or external
   archive for large/private binary originals;record an accessible recovery location
   and checksum. Do not commit raw FLEXLAB data without confirmed rights.
6. Only after verified archival receipts and explicit approval of a specific cleanup
   list may a temporary execution folder be removed manually. This release contains
   **no deletion utility**. A hash match means recoverable bytes,not blanket proof
   that all native artifacts/dependencies in a folder are backed up.

## Native acceptance gate

Run the package from an otherwise empty extracted directory using an external data
folder. Confirm package verification,721 source rows,completed_inspection status,
two measured figures and the returned ZIP;also test a nonexistent external folder
and confirm an actionable diagnostic ZIP labelled failed. Run the local audit on
the old installation and review its NOT YET BACKED UP list. Return these artifacts
before deleting anything. No C4.3 work starts automatically.
