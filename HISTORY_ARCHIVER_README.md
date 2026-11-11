# THERMA historical archiver — MATLAB R2025a

This toolkit preserves original file bytes. It never loads a model,simulates,
changes source files,downsamples data or deletes anything. Native execution of
this new archival utility is **pending university verification**.

1. Extract this small ZIP into a **new folder**,not the old THERMA installation.
2. Open MATLAB R2025a there. Base MATLAB with JVM is sufficient;no Simulink,Git,
   Python,WSL or additional software is required.
3. Check the ZIP checksum against the delivery message,then verify packet files:

```matlab
addpath(pwd,'tools/matlab','scripts/matlab/boptest')
disp(boptest_file_sha256('C:\PATH\TO\DOWNLOADS\THERMA_HISTORY_ARCHIVER.zip'))
therma_history_packet(pwd);
```

Run the focused software self-tests before touching the real installation:

```matlab
addpath(pwd,'tools/matlab','scripts/matlab/boptest')
r = runtests('test_therma_history_archiver.m');
assertSuccess(r)
```

Tests create about16MB of clearly labelled temporary software fixtures outside
the source installation;they do not generate benchmark/model evidence or delete
files. Do not proceed if they fail;send the reported exception.

4. Choose the original installation and a destination **outside it**:

```matlab
source = uigetdir(pwd,'Select existing THERMA_C35_MATLAB');
destination = uigetdir(pwd,'Select separate archive drive/location');
assert(ischar(source) && ischar(destination),'Selection cancelled')
archiveFolder = archive_therma_history(source,destination);
```

Or supply your two actual paths directly. The destination can be a USB/external
drive or a permitted separate network location. Merely choosing another folder
on the same home drive does not create a separate quota.

## Scope and storage

The reviewed audit lists602 files/431,966,619 bytes. Plan:archive279 files/
420,811,850 bytes,including all36 audit-listed native SLX paths. Skip291 exact
Git-preserved byte identities and32 declared regenerable caches;the complete
file-by-file decisions remain in history_reference/history_plan.json. All unknown
files and important figures are retained. Three exact-duplicate groups are
identified in the engineering report;duplicates are **not elided** from archives.

Expect12 milestone ZIPs plus one small catalog ZIP. C3.1–C3.6 history is split
into seven parts. Each part targets at most64MiB of original bytes;files are
never split. Reserve **at least450MB free destination capacity**,not another
432MB uncompressed source copy. The conservative estimate is446,046,747 bytes;
compression is not assumed to make SLX/MAT/FIG small. The tool queries volume
free space;your user quota can be smaller. Zero/unavailable space or insufficient
space blocks writing. Choose a different drive if the guard stops the run.

Original files stream directly into compressed parts using bounded buffers.
Only small metadata is copied uncompressed. Each source is checked against the
original audit before writing;each ZIP member is streamed through SHA256 and
compared again with current source bytes. New,missing,unreadable or changed files
stop the run and produce preflight/failure diagnostics where writable. Request
a fresh audit/reviewed plan rather than altering the expected hashes.

Completed parts are reverified/reused on the next call with the **same source,
destination and toolkit**. Existing final archives are never overwritten. A
failed `.partial` stage is retained for diagnosis;it is not a valid backup and
can consume space. There is no automatic partial/cache cleanup.

## Return and recovery

Return **all12 THERMA_HISTORY_*.zip parts and THERMA_HISTORY_CATALOG.zip** from the
printed archive folder. Keep SHA256SUMS.txt as well. Parts preserve original
relative paths. Do not publish them yourself:models,reports or logs may contain
private paths. Codex will verify every byte/hash against the original audit,
then arrange suitable Releases/controlled external archival with immutable
locations and receipts. Hundreds of MB must not enter ordinary Git history.

Local success means **locally_verified_only**,not remotely backed up. Do not remove
the old installation until returned archives pass verification,remote recovery is
confirmed,all unmatched/new files are reviewed,and you explicitly approve cleanup.
No deletion functionality is included. C4.3 is not started.

The optional recover_therma_evidence helper recovers the small encrypted original
C42B evidence ZIP using the separate private key. It does not decrypt historical
part ZIPs,which are ordinary lossless ZIP files. Recovery syntax and original ZIP
hash are in the public C42B evidence README;never commit the key or private ZIP.
