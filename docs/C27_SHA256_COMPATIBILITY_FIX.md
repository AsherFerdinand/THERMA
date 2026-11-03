# C2.7 R2024a SHA-256 compatibility revision

University-reported execution: 164 package files verified, CSV reader probe passed,
and one remaining Java NonScalarArg failure in the exact-chunk event test.

MessageDigest has overloaded scalar-byte, byte-array and buffer update methods.
The previous one-argument numeric call is ambiguous for empty/singleton reads;
the previous file loop could issue an empty read at an exact chunk boundary.
MATLAB dispatch cannot be reproduced in this cloud environment.

The shared boptest_sha256_update selects update(byte[],int,int) with explicit
int32 offset/length. Empty input returns immediately. Singleton input uses a
nonscalar signed-byte backing array, but length remains one, so padding is never
hashed. typecast preserves high-bit byte identity. Both the CSV verifier and file
hasher use this helper. File reads are bounded by checked snapshot size, counts
and positions. Lowercase hexadecimal formatting is unchanged.

Seven fixed vectors (empty, abc, zero, 255, exactly 1 MiB, 1 MiB + 1 byte and
multiple chunks) agree independently in Python hashlib and OpenSSL. Prepared
MATLAB tests compare incremental and file hashing against those fixed hashes.
MATLAB tests remain unexecuted here. CSV integrity, cleanup, staging, resume,
physics, solver, reference inputs and previous results are preserved.

Download:
https://github.com/AsherFerdinand/THERMA/raw/refs/heads/replay-transfer/THERMA_C27_SHA256_FIX_R2024a_2026-11-03.zip

Extract into a fresh short local directory, open THERMA_C27_MATLAB in MATLAB
R2024a and run:

```matlab
run_verification("quick")
```

All tests must pass before running `run_verification("full")`. Preserve any failure
logs. This revision is not yet confirmed on the university computer.
