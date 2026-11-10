# MATLAB quickstart — one experiment, one temporary folder

The current lightweight package supports **C42B measurement inspection only**.
It does not simulate a building. Native execution of this maintenance wrapper is
pending university verification. MATLAB **R2025a with JVM**, base MATLAB only;
no Simulink, Git, Python, WSL or Docker is required for C42B.

1. Keep `THERMA_C35_MATLAB` intact. Extract `THERMA_C42B_RUN.zip` into a **new empty
   folder**. Never overlay this package on the historical installation.
2. Keep the six original FLEXLAB CSVs in one shared folder outside the temporary
   execution folder. Their original subfolders must remain:
   `Direct Validation Data/` and `Input Data/`. Reuse your existing dataset directory.
3. In MATLAB select the fresh package folder and run:

```matlab
cd('C:\PATH\TO\NEW\THERMA_C42B_RUN')
result = run_therma_experiment("C42B", "C:\FLEXLAB_DATA");
```

The runner checks every package dependency/hash, release, required product and all
six original input hashes. It inspects23June2021,00:00–12:00 fixed PST(UTC−08),
produces the existing temperature/cooling plots and saves a new
`outputs/executions/<unique run>/THERMA_RESULTS_C42B.zip` plus its `.sha256` receipt.
No measured values are filled/clamped and no solver is invoked. Logs and error
receipts are also packaged on ordinary execution failure; failed runs are never
labelled successful. Package-integrity failure stops before execution.

**Missing data:** the error identifies the filename, official immutable URL and
expected hash. For an optional download directly from LBNL (requires Internet):

```matlab
addpath('tools/matlab','scripts/matlab/boptest')
verify_therma_package(pwd);
acquire_therma_inputs('C:\FLEXLAB_DATA','download',pwd);
% Existing local data, without downloading:
acquire_therma_inputs('C:\FLEXLAB_DATA','verify',pwd);
```

The helper downloads only missing files, verifies before publishing and refuses
to overwrite changed originals. Do not put the entire FLEXLAB repository into the
run folder or return raw CSVs. Redistribution rights remain unresolved.

**Before removing the old installation**, from the new package run:

```matlab
auditFolder = audit_therma_local_storage('C:\PATH\TO\THERMA_C35_MATLAB');
```

Return the results ZIP and the audit's `storage_audit.json`/`cleanup_review.csv` to
Codex. Logs/errors may contain personal paths; review before public sharing.
Codex checks hashes/source/status, reviews privacy and archives important results.
Wait for a verified GitHub commit/archive receipt, then explicitly approve a
specific cleanup list. **Do not delete unmatched `.slx`, `.mat`, results or
unsaved `.asv` files.** Nothing in these utilities deletes anything.

Existing C1–C4 simulations still use their original runners/packages and numerical
settings. They are not silently migrated to this wrapper. See the preservation
inventory and workflow documents in the full GitHub repository for their gates.
