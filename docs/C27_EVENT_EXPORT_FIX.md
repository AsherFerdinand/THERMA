# C2.7 event export failure — scoped fix, university verification pending

## Evidence and investigation

The user reports that C2.7 quick verification (all MATLAB tests and smoke simulation)
succeeds on **R2024a**, but the first full no_solar_30 experiment fails at the old
`writetable(array2table(raw,...), energy_events.csv)` call with
`MATLAB:fopen:InvalidFileLocation`. The target is a Windows UNC home directory,
exists, has a reported path length of 128 characters, and accepts both a small CSV
and a 1,000-row/six-column CSV. The final event CSV is absent. No original detailed
error report was supplied here beyond those diagnostics.

**Root cause remains unconfirmed.** These observations do not prove excessive file
size, insufficient RAM, a path-length limit, permissions, locking or a network outage.
Inspection does establish avoidable allocation: the old path constructed a complete
six-column raw matrix, copied the evaluation subset, and converted it to a table.
The reported fopen identifier is a file-creation failure, not evidence of out-of-memory.
We cannot reproduce the university UNC filesystem or run MATLAB in Codex.

Only export plumbing, verification, status reporting, related tests and packaging
are changed. No C1/C2 equation/material/physical assumption, solver setting, reference
packet or C2.6C result is changed. No C3 work is included.

## New export path

`boptest_export_energy_events.m` receives references to existing scalar logs and the
original N-by-11 input log. It processes **4096 rows at a time** by default. It adds
the original absolute time origin per chunk and applies the same inclusive evaluation
bounds as before. Rows are neither sorted nor deduplicated. Prescribed power remains
the sum of original columns 2:11, evaluated per chunk in the same column order.

The six unchanged columns are:

```text
time_s,stored_thermal_energy,net_external_power,stored_energy_derivative,prescribed_power,power_balance_residual
```

1. Count selected events and check original timestamp order in bounded chunks.
2. Write a unique staging CSV using binary fwrite and **%.17g** numeric formatting
   with LF line endings. Each chunk/header write count and ferror/close status is
   checked. Binary64 values round-trip without the old default text-precision loss.
3. Close the staging handle before any copy/hash/rename. Stream-verify the staging
   header, exactly six columns per record, finite values, row count and nondecreasing
   timestamps. Equal timestamps remain valid. No entire CSV is reloaded into memory.
4. SHA-256 the staging file. Copy it to a unique sibling `.events.partial` target,
   with at most three bounded copy attempts for possible transient failures. This is
   not an assertion that the original failure was transient.
5. Refuse an already-existing final target. Promote the sibling file and verify final
   existence, nonzero/exact byte count and SHA-256 equality. The final byte identity
   establishes the same header/row/order properties verified in the staging scan.

The system temporary directory is used for staging. It is often local on Windows
but may be redirected; no locality or extra free-space guarantee is assumed. Its
actual path is recorded. UNC rename atomicity is not promised. No verified final CSV
is overwritten. Owned partial copies are cleaned up best-effort. Successful staging
files are removed; failed staging files remain available for diagnosis, not as
completed benchmark exports.

Other CSV writers are unchanged: this bug fix targets the reported event exporter.
It does not claim to fix every possible network-filesystem failure.

## Diagnostics and completion semantics

The context contains MATLAB version, exact target/directory, UNC classification,
directory existence, input/selected row counts, six-column numeric-size estimate,
conservative CSV-size estimate and export stage. Java getUsableSpace is recorded only
when it gives a positive finite observation; zero/unsupported queries remain unknown,
not “disk full.” The observation is not a network-user quota guarantee.

A failed export prints context and the original identifier/message to the Command
Window, attempts a uniquely named failure JSON in the staging directory (system-temp
fallback if needed), and throws a chained exception preserving the original stack and
nested causes. The context is also embedded in the exception message, so it survives
inside replay_run.json even if diagnostic-file creation fails. No guessed available
space or fabricated original MATLAB identifier is supplied for APIs that return a
status/message rather than throwing.

Before export, replay_run.json records stage export_energy_events and status writing.
On success `energy_event_export.status=verified` includes row/column/time checks,
byte count, SHA-256 and copy attempts. After **all** exports complete,
`export_completed=true` is set. solver_metadata.json includes these export fields.
On failure overall status remains failed and export_completed=false. Simulation
return/execution flags may remain true because the solver really returned; this does
not mean the experiment/export completed. Completion receipts are never created for
that failed runner call.

Resume retains original file/contract checks. A new report explicitly marking failed
export, or a verified-export hash that differs, cannot qualify. Intact matching-
contract successful attempts still qualify and are not rerun. Legacy completed
reports without the new marker retain their old validity rules. Package upgrades
still change code contracts: do not merge packages or silently adopt older code's
results into a new controlled study. Old successful results remain preserved; cross-
package reuse is not automatically authorized by this fix.

## Offline package and exact commands

[Download the updated R2024a package](https://github.com/AsherFerdinand/THERMA/raw/refs/heads/replay-transfer/THERMA_C27_EVENT_EXPORT_FIX_R2024a_2026-11-03.zip)

Extract All to a **fresh** short writable folder. A local folder is preferable if
university policy permits; a UNC folder is supported by the prepared writer but has
not been independently tested here. Do not overwrite the previous package/results.
R2021a interfaces are retained; R2024a is now explicitly recognized by the launcher.
No Git, Python, Docker, internet or FMU runtime is required on the university PC.

Set MATLAB Current Folder to THERMA_C27_MATLAB, then:

```matlab
run_verification("quick")   % all tests, including new event IO regressions, then smoke
run_verification("full")    % sequential control/refinement study with verified event export
```

Within this same updated package, repeat `run_verification("full")` to resume valid
completed attempts; failed attempts rerun into new folders. Default retention is
still lean. No solver/physics setting was changed to work around an IO error.

If it fails, preserve the diary, replay_run.json, solver_metadata.json where present,
study_index.json and the `.event_export_failure.json` location printed in MATLAB.
The diagnostic includes staging-path information; failed staging files can be retained
for investigation. Do not manually fabricate completion receipts or bypass integrity
checks. **University resolution is pending until these commands actually succeed.**

## Regression coverage and limits

Prepared MATLAB tests cover:

- Exact small six-column round-trip with duplicate timestamps, bounds and extreme
  finite double values.
- 50,000-row synthetic export across many chunks and streaming re-verification.
- Invalid/missing output directories and original-cause/context preservation.
- Refusal to overwrite an existing verified target.
- Truncated/interrupted CSV rejection and decreasing timestamps.
- UNC path classification without network assumptions; an actual 5,000-row UNC
  export is additionally exercised when the test installation itself is on UNC Windows.
- Resume rejecting failed export, accepting intact verified export and rejecting corruption.

These synthetic fixtures are software tests, **not BOPTEST benchmark data**. MATLAB
execution of these new tests is unavailable in cloud. Python static-contract guards,
existing numerical regressions, lint/type checks and static MATLAB syntax checks can
run here; they cannot establish UNC behavior or MATLAB runtime success. Delivery
checksums/commits and executed check counts are recorded in the delivery receipt.
