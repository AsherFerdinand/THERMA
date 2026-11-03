# C2.7 R2024a CSV reader: byte-bounded verification

## Evidence, correction and verification status

The user reports eight event-export test failures on R2024a after package integrity
passes (161 payloads). The primary diagnostic is ferror **−4**, “At end-of-file.”
The preceding correction assumed −1 was a portable EOF diagnostic. That assumption
was wrong for this observed R2024a runtime; this revision does **not** add −4 to an
allowlist or classify EOF by localized message text.

MATLAB is unavailable in Codex Cloud. A minimal MATLAB-compatible reproduction and
focused regressions are supplied, but the actual R2024a −4 observation cannot be
independently reproduced here. No successful university verification is claimed.
The older UNC file-creation root cause also remains unconfirmed.

## API semantics and complete state-machine review

The relevant documented interfaces are:

- [fgetl](https://www.mathworks.com/help/matlab/ref/fgetl.html): returns a character
  line, or numeric −1 when no line can be read at EOF. This return value is not an
  invariant value for ferror's diagnostic number.
- [feof](https://www.mathworks.com/help/matlab/ref/feof.html): reports the stream's
  EOF indicator, normally observed after a read reaches/passes the boundary.
- [ferror](https://www.mathworks.com/help/matlab/ref/ferror.html): reports the stream
  diagnostic. The observed −4 cannot be treated as a portable discriminator of a
  failed read versus expected exhaustion.
- [fread](https://www.mathworks.com/help/matlab/ref/fread.html): returns the actual
  element count read. With uint8 input, count is the number of bytes returned.
- [fseek](https://www.mathworks.com/help/matlab/ref/fseek.html) and
  [ftell](https://www.mathworks.com/help/matlab/ref/ftell.html): provide seek status
  and byte position for the ordinary seekable staging file.

Live retrieval of vendor/mirror documentation was blocked by the cloud HTTP proxy
(403); no live release-specific documentation or MATLAB experiment is claimed.
The implementation relies on counts, seek statuses and positions rather than any
unsupported numeric ferror mapping.

### Reader states

1. Open staging CSV in binary read mode; reject open failure. A by-value anonymous
   cleanup callback retains the reader's file ID and closes it once.
2. Check seek-to-end status, snapshot byte length using ftell, and check rewind to
   byte zero. Invalid seek/position is a read failure.
3. While position is smaller than the snapshot length, request exactly
   min(1 MiB, remaining bytes). Require fread count to equal the request and ftell
   to advance by that exact count. A short read/no progress is an error even if feof
   is true: it did not deliver the bytes promised by this file snapshot.
4. Parse the header from those same raw bytes; do not mix fgetl line reads into the
   production scanner. Carry an incomplete record across chunks with bounded memory.
5. Preserve fgetl-compatible LF/CRLF header terminators while hashing the raw bytes.
   Keep exact header/column count, finite numeric values, nondecreasing time, duplicates
   and exact row count checks. A missing final LF remains a truncated-record error;
   extra complete records fail expected row count. Missing/extra fields, NaN/Inf and
   decreasing times are still rejected.
6. Stop when all snapshot bytes have been consumed. **Do not make a terminal read
   past EOF.** No numeric ferror result is inspected on this success path.
7. Check final seek/length again to reject a length change. Compute SHA-256 over the
   exact bytes scanned. The writer compares this digest to a fresh staging-file hash
   before copying, then preserves the existing final destination SHA/byte verification.

ferror and feof remain available in failure diagnostics, not as success classifiers.
Thrown fread failures propagate; unsuccessful seeks, short counts and inconsistent
positions fail explicitly. This avoids suppressing a real error behind a generic
EOF flag. Ordinary files must be seekable, as expected for this staging CSV protocol.
A same-length post-scan replacement is detected by the writer's staging digest check.
No claim is made of OS fault injection or arbitrary concurrent-file locking tests.

## Minimal reproduction, without artificial error-code assertions

From the new extracted package root:

```matlab
addpath(fullfile(pwd,'scripts','matlab','boptest'));
probeFile = reproduce_boptest_csv_reader();
disp(probeFile)
```

This creates a two-record synthetic CSV, observes actual fgetl and deliberately
unbounded fread calls, records actual returned values/counts/positions/feof/ferror
numbers/messages, then runs the new bounded verifier on the same bytes. The resulting
reader_probe.json is an API diagnostic, **not BOPTEST benchmark evidence**. It records
whatever this MATLAB/OS returns, with no fabricated −4 or expected numeric code.
Preserve that JSON if any regression still fails.

## Invalid-directory diagnostic assertion

The old message only embedded the target in JSON. On Windows JSON escapes backslashes,
so `contains(problem.message,file)` can fail although the encoded target is correct.
The primary exception now prints the target as a plain `%s` argument before JSON.
The original cause chain is unchanged.

The test keeps the exact outer/cause identifier assertions and the plain-path check,
and additionally reads the actual failure JSON: target_file must equal the original
path, output_directory must match, directory_exists must be false, and the original
exception identifier must remain THERMA:EventDirectory. This strengthens the test's
intended requirement instead of dropping the failing assertion. The exact user's
assertion log was not supplied, so any other platform-specific failure still needs
its actual test output.

## Cleanup, precision, staging and resume

The independent BoptestEventExportResources owner remains unchanged. It captures no
parent workspace, disarms file IDs before close, is idempotent and never targets a
verified final output for deletion. Failed staging remains available; partial-copy
cleanup is best effort. Chunked writer, %.17g binary64 precision, source event order,
duplicate timestamps, original six columns and strict completion/receipt gates remain.
No solver, thermal equation, material, source input or prior benchmark was changed.
No C3 implementation is included.

## Regression coverage and offline delivery

All existing event-export tests remain. New cases cover:

- A file exactly one read chunk long, without a speculative extra EOF read.
- A complete final record whose LF falls into the next chunk.
- Windows CRLF header/records with raw-byte SHA identity (writer still emits LF).
- Actual fgetl/fread diagnostic recording plus bounded verification of the same file.
- Extra fields, Inf, decreasing timestamps and incomplete final record.
- Windows plain-path and structured diagnostic equality, with original cause retained.

Existing small/50,000-row, duplicate, truncation, extra-row, NaN, cleanup/reused-ID,
invalid-target, overwrite and conditional UNC tests are retained. Synthetic fixtures
are software tests only. MATLAB results for this revision remain unexecuted in cloud;
Python/static guards cannot establish that all eight university failures now pass.

[Download the new offline package](https://github.com/AsherFerdinand/THERMA/raw/refs/heads/replay-transfer/THERMA_C27_R2024A_READER_FIX_2026-11-03.zip)

Extract All to a fresh folder; do not merge with earlier packages. Set MATLAB Current
Folder to THERMA_C27_MATLAB. No Git, Python, Docker or internet is needed. First run:

```matlab
run_verification("quick")
```

To isolate the export regressions and API diagnostic before any full replay:

```matlab
addpath(fullfile(pwd,'scripts','matlab','boptest'));
results = runtests('tests/matlab/test_boptest_event_export.m');
assertSuccess(results);
probeFile = reproduce_boptest_csv_reader();
```

Only after quick mode passes, run `run_verification("full")`. If it fails, provide
reader_probe.json, test CSV/diary and the original replay/failure diagnostics. New
code contracts intentionally remain distinct from older packages; preserved old
successful results are not overwritten or silently adopted into a different study.
