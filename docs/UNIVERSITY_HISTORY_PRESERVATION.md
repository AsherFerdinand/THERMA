# University history preservation — 2026-11-11

**No cleanup is authorized.** The original C42B inspection ZIP is verified and
recoverably archived;historical model/result bodies have not yet been returned.
This report describes a preservation plan,not completed historical backup.

## Evidence reviewed

Both original audit reports are retained under history_reference/ with byte
preservation attributes. All602 JSON/CSV rows agree on path,size,SHA256 and
classification. Report totals match the user's summary in decimal MB:

| Classification | Files | Bytes | MB |
|---|---:|---:|---:|
| Exact known Git byte identities |291|11,098,106|11.098106|
| KEEP_NOT_YET_BACKED_UP |179|326,658,437|326.658437|
| Other REVIEW originals |100|94,153,413|94.153413|
| Declared regenerable caches |32|56,663|0.056663|
| Total |602|431,966,619|431.966619|

Original storage_audit.json SHA256:
`5854d0a727fed8604eaadf7aacbcb1e3bcb00a585050ca53157e4d3e9927d8c4`.
Original cleanup_review.csv SHA256:
`c652193579ed695396704d266745fdafee3842bc64efb6bde6ff6b2d274ec8ec`.
Audit's preservation-manifest SHA matches the previously published snapshot;
all291 flagged matches independently correspond to trusted preserved identities.
Neither report contains an absolute private university path. These are audited
file identities,not a fresh cloud read of the university file bodies.

Types:36 SLX/12,208,834B;25 CSV/319,729,849B;36 FIG/83,966,502B;16 MAT/12,248B.
All16 MAT files are explicitly slprj cache metadata,not observed standalone
simulation MAT exports. Do not infer that no other MAT/model files exist outside
this audited installation. Three exact-duplicate groups were found:17 build.json
copies,17 parameters.json copies and identical C3.7/C4.0 trajectory bytes. Extra
copies total15,838,811B. They are identified by SHA256,**not removed or elided**.

## Conservative plan

Archive all279 unmatched non-cache files/420,811,850B,including every one of the
36 SLX paths. Existing Git matches are skipped only after current bytes recheck;
all unknown/review material is kept. Preserve paths/content,not model-name guesses.
The machine-readable plan lists **all602 decisions**,not just chosen filenames.

| Milestone group | Archived files | Original bytes | Part ZIPs | SLX |
|---|---:|---:|---:|---:|
| C1/C2 envelope histories |51|5,593,174|1|17|
| C3.1–C3.6 component/integration investigations |202|363,759,824|7|15|
| C3.7 residential |10|16,550,270|1|2|
| C3.8 thermostat |7|18,534,353|1|1|
| C3.9 post-processing |3|271,717|1|0|
| C4.0 integrated system |6|16,102,512|1|1|
| Total |279|420,811,850|12|36|

There is no unmatched C2.8 part in this installation's plan;known preserved
comparison files retain their Git recovery locations. C42B actual evidence is
archived separately in results/C42B/c146fd42ee036a3a/. Absence from this scope is
not proof that every historical artifact outside the audited tree is backed up.

## Native utility and space

Extract THERMA_HISTORY_ARCHIVER.zip into a fresh toolkit folder. Follow its
HISTORY_ARCHIVER_README.md. Base MATLAB R2025a/JVM only;no Simulink/Git/Python/WSL.
Run its four focused software tests before archiving. They exercise empty/single/
chunk-boundary byte writes,duplicates,reverification,missing/changed originals,
corrupted ZIPs and the low-storage guard;**native tests remain unexecuted here**.

The archiver validates packet/reference hashes and all602 current source files,
reports missing/new/unreadable/changed entries and refuses an incomplete snapshot.
It streams original files directly into milestone ZIPs,using bounded byte buffers,
then streams each ZIP member through SHA256 and rehashes current originals. It
rechecks the full source inventory before issuing a locally-verified catalog.
All paths/duplicate timestamps/numerical representations retain exact bytes.
No model or callback is loaded and no source file is modified.

Parts target64MiB of original bytes;individual files are never split. There are
12 parts and a small metadata-only catalog ZIP. No additional uncompressed432MB
copy is made. Worst-case destination budget **446,046,747B**,so reserve at least
450MB on a suitable separate location. Do not assume compression of SLX/MAT/FIG
will substantially help. Java volume free-space checks cannot establish a user's
smaller network quota;zero/unknown or insufficient reported space blocks writing.
Actual write/quota failures stop safely and retain diagnostics/partial stages.
A different folder on the same home drive still shares that quota.

Rerunning with the same toolkit/source/destination rechecks/reuses completed parts.
Final archives are never overwritten;corrupt existing parts require review/another
destination. Failed .partial files remain and can consume space;there is no deletion
or automatic cleanup functionality. A local result is explicitly
`locally_verified_only`,not confirmed remote preservation.

## Return and final backup gate

Return all12 parts plus THERMA_HISTORY_CATALOG.zip (keep SHA256SUMS.txt). Codex runs:

```bash
uv run --frozen python tools/history_archive.py --returned /path/to/returned/folder
```

The verifier checks original audit/plan/source-toolkit identity,part hashes,all
original member hashes/sizes/paths/CRC,duplicates and complete model coverage.
It never executes or extracts model callbacks. Successful verification still says
**remote_recovery_confirmed:false**. Archive original bodies in privacy-reviewed
GitHub Releases or controlled external storage,not hundreds of MB of ordinary Git
history. Private originals can use encrypted controlled archives with separate keys.
Record immutable recovery locations,checksums and independent downloads before
updating preservation status.

Only after returned archives verify,remote recovery is confirmed,all changed/new/
unmatched files are reviewed,and the user explicitly approves a final file-by-file
proposal can old installation removal be considered. No such proposal or deletion
is issued in this delivery. C4.3 is not started. Existing lightweight C42B execution
and all verified physical parameters/equations remain unchanged.
