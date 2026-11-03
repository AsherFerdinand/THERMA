# C2.7 CSV EOF and cleanup correction — MATLAB execution pending

Superseded by [the R2024a byte-bounded reader](C27_R2024A_READER_FIX.md) after the
user observed EOF diagnostic −4. The −1-based classification below is historical
and is not the current reader implementation. Original archive preserved.

## Reported failure and scope

The user reports R2024a package integrity succeeds (158 manifest payloads), existing
thermal tests complete, but event-export tests fail at CSV verification with
`THERMA:EventCSVRead: At end-of-file.` A secondary cleanup exception reports an
already-destroyed `fid` variable. These are defects in the new verification/resource
plumbing, not evidence of thermal-model, solver or BOPTEST-input problems.

The original university UNC file-creation cause remains unconfirmed. This patch
addresses the two newly identified implementation bugs only. No equations, physical
parameters, solver settings, original reference inputs, C26C results or C3 code changed.

## A. Normal EOF versus read failures

The old verifier rejected every nonzero `ferror` value after deliberately reading
to EOF. MATLAB can report expected EOF with status **−1** and message “At end-of-file.”
That is not a failed transfer or invalid CSV. The new verifier checks immediately
after **each fread**, including a short final chunk and the final empty read:

- status 0 is accepted;
- status −1 is accepted **only when feof also confirms EOF**;
- every other status remains a read failure, even if an EOF flag is also present;
- an empty read without EOF is rejected rather than silently ending the scan.

No localized English message is used to classify EOF, and no error state is cleared
to hide a failure. Normal EOF does not skip final validation: pending unterminated
text is rejected as truncated; exact expected row count, exact header, six columns
per record, finite numeric values and nondecreasing time are still mandatory.
Duplicate timestamps remain in original order. Extra complete records fail the row
count, while missing/extra fields and nonfinite values fail their own checks.
Staging and destination SHA-256 verification remains unchanged.

## B. Cleanup lifetime and file-handle ownership

The old `onCleanup(@cleanupOwned)` pointed to a nested function sharing the exporter
workspace. During error unwinding that callback could access `fid` after MATLAB had
destroyed the shared variable, producing a secondary exception that obscured the
original export failure.

The exporter now uses a small, independent handle object,
`BoptestEventExportResources`, captured **by value** in an anonymous cleanup callback.
It owns only the current file ID, staging/partial paths and the success cleanup flag;
it does not reference the exporter's workspace, arrays or verified final destination.
All nested cleanup functions have been removed from the exporter.

`closeFile` disarms the owned ID before calling fclose. An explicit successful close
therefore cannot be repeated by the callback or accidentally close a later file that
reuses the same numeric ID. Cleanup is idempotent, closes owned handles, removes owned
partial copies best-effort, deletes staging only after verified success, and retains
failed staging for diagnosis. Final output files are never cleanup targets.

The verifier's existing anonymous callback captures its numeric read ID by value;
it has no nested shared workspace and only one close owner. It remains unchanged.
Invalid-directory errors retain their original `THERMA:EventDirectory` cause beneath
`THERMA:EventExport`, together with original stack/context diagnostics. Overall
export failure still cannot qualify for a completed/resumable experiment.

## Regression coverage

The six original MATLAB export tests remain in place:

1. testSmallPrecisionDuplicateTimesAndBounds
2. testLargeChunkedExport (50,000 synthetic rows)
3. testInvalidOutputDiagnosticAndOriginalCause
4. testNeverOverwriteVerifiedTarget
5. testInterruptedAndMisorderedCSVRejected
6. testUNCContextWithoutAssumingNetworkAvailability

Added independent-file tests for normal EOF with duplicate complete records, extra
records, missing fields and NaN rejection. Existing truncation tests must now reach
the truncation guard rather than being masked by EOF handling. Added resource tests
for repeated cleanup, an independently reopened/reused file ID, no leaked handles,
no cleanup warning during failed export, and original invalid-directory cause.
Python static guards protect the EOF predicate and absence of shared nested cleanup.
All synthetic files are temporary software fixtures, never benchmark evidence.

**MATLAB is unavailable in Codex Cloud. These MATLAB tests have not been executed
here; none are claimed to pass on the university PC yet.** Python/static quality
results and publication hashes are recorded in the delivery receipt and progress log.

## Updated offline package and commands

[Download THERMA_C27_EOF_CLEANUP_FIX_R2024a_2026-11-03.zip](https://github.com/AsherFerdinand/THERMA/raw/refs/heads/replay-transfer/THERMA_C27_EOF_CLEANUP_FIX_R2024a_2026-11-03.zip)

Use **Extract All into a fresh folder**. Do not merge with the failing package or edit
files covered by its integrity manifest. Keep the old package/results for diagnosis.
Set MATLAB Current Folder to the new THERMA_C27_MATLAB folder, then run:

```matlab
run_verification("quick")
```

This runs all MATLAB tests, including the original six and new regressions, followed
by the smoke simulation. Proceed only if quick verification succeeds:

```matlab
run_verification("full")
```

No Git, Python, Docker or internet is required. Existing model builders generate SLX
on the PC. R2021a-compatible interfaces remain; actual R2024a execution is pending.
Matched-contract completed attempts remain resumable; source-code upgrades continue
to have distinct contracts, so old results are preserved rather than silently adopted.
If it fails, preserve the MATLAB diary, test-results CSV, replay_run.json and printed
failure JSON path. No successful university verification is claimed by this delivery.
