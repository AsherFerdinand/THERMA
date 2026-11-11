# THERMA incremental archiver —80MB free-space workflow

Use this guide instead of the older all-at-once guide. Base MATLAB R2025a/JVM;
no Git,Python,WSL or Simulink. New incremental MATLAB code remains native-unverified.
The original C4.2B runner and legacy history archiver are unchanged.

The supplied Release model ZIP was downloaded and all36 originals matched full
relative paths,size and SHA256. See history_reference/remote_models_verified.json.
Its SHA256 is5fab723d165a242974ad5de3dd78fd3d95434b8720c307106b33f7e6d2eb5328.
Models are skipped only for those exact verified versions;source drift blocks the run.
A Release URL can change:always verify recorded hashes when downloading/recovering.

## Generate ONE part

Extract toolkit into a NEW folder and select it in MATLAB:

```matlab
addpath(pwd,'tools/matlab','scripts/matlab/boptest')
therma_history_packet(pwd);
r=runtests('test_therma_history_archiver.m'); assertSuccess(r)
source=uigetdir(pwd,'Select original THERMA_C35_MATLAB');
destination=uigetdir(pwd,'Select incremental WORK folder outside originals');
assert(ischar(source)&&ischar(destination),'Selection cancelled')
[part,job]=archive_therma_history_incremental(source,destination);
```

Each call creates at most ONE ZIP. Source payload<=40,000,000bytes;hard final ZIP
cap45,000,000bytes (45MB decimal,<50MB). Deflate level0 bounds overhead rather
than assuming compression. Each part needs at most about43MB free,not446MB.
No uncompressed staging copy is made. Reserve a few MB for toolkit/catalog;native
software tests create temporary fixtures. Host free-space queries may overstate
network user quota. Failed partials stay untouched and can consume working space.

Originals larger than40MB are losslessly segmented by BYTE OFFSET,not by CSV rows.
The original path,total size,original SHA256 and every range/member are recorded.
This preserves duplicate timestamps,CRLF,all digits and binary bytes. It is not
standalone CSV data until all ranges are reassembled. No individual source is
silently truncated or assumed to compress below50MB.

## Upload,DOWNLOAD-VERIFY,then resume

1. In GitHub browser,open an appropriate Release,Edit,attach the generated ZIP and
   save. Privacy-review originals before publishing;use approved controlled storage
   if models/reports contain private information. Do not commit large history to Git.
2. Copy the direct asset link (not the Release page). Verify a FRESH download:

```matlab
[~,name,ext]=fileparts(part);
verify_therma_history_remote(job,[name ext], ...
 'https://github.com/AsherFerdinand/THERMA/releases/download/YOUR_TAG/YOUR_PART.zip');
```

This streams HTTPS through SHA256 in RAM;it does NOT save a second45MB copy.
Actual byte count/hash must match the locally verified ZIP before status changes
to remote_verified. HTML pages,failed/partial/wrong downloads do not change receipts.
Record asset IDs/immutable URLs where available. Keep the catalog and always recheck
hashes on retrieval;upload success or a link alone is never evidence of backup.
3. Using Explorer,move ONLY this remotely verified GENERATED ZIP to external
   storage outside the working job folder. Originals are never moved/deleted.
   Keep catalog JSONs and plan in place. The utility contains no deletion code.
4. Generate next:

```matlab
[part,job]=archive_therma_history_incremental(source,destination,'next');
archive_therma_history_incremental(source,destination,'status');
% Recheck a pending local part without creating another:
archive_therma_history_incremental(source,destination,'verify-local');
```

A locally verified pending ZIP is returned/reverified rather than regenerated.
A completed stage/final ZIP from an interrupted call is recovered after validation.
An incomplete `.partial` causes a safe stop:move that GENERATED failed stage to
external storage for diagnosis before retrying. Never remove original source files.
Next generation is blocked while any previous working ZIP remains,preventing
accumulation beyond the80MB budget. If space cannot be freed externally,stop and
choose a separate working drive. No original-file cleanup is authorized.

The persistent incremental_catalog.json plus snapshots track outstanding,local
and remote part states. incremental_plan.json maps every original/range to its
parts. A file is remotely covered only when ALL its ranges' assets verify;the36
model proofs are separate. Send catalog and plan to Codex for final file-by-file
review;new files outside the audited snapshot still need review.

## Recovery (later,on a spacious separate drive)

Download all assets using catalog URLs and verify SHA256. Then:

```matlab
restore_therma_history_incremental(job,'D:\DOWNLOADED_PARTS','D:\NEW_RECOVERY');
```

The recovery folder must not exist. Reassembly retains original relative paths and
checks the full original SHA256 after all ranges. Recover36 models separately from
their verified Release ZIP,checking its hash and member identities. Recovery needs
enough space for original bytes;the80MB constraint applies to archival WORK space.
Nothing is deleted or marked cleanup-approved. No C4.3 development is included.
