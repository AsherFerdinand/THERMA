# Actual university C4.2B inspection — MATLAB R2025a

Original returned ZIP SHA256:
`c146fd42ee036a3ac1fa487dfd411d3e1e691adb109d83de9cc36e288ec1cd9f`.
Original bytes182600;source`c408225aaaaf07f3394e1646ce140b4ea3fcca0c`.
The existing verifier accepts all artifact/source/configuration/input hashes.
Actual verification status is **completed_inspection**,MATLAB25.1.0.2943329(R2025a).
Six original FLEXLAB file identities match the pinned reference;all six selected
periods have721 complete records,60-second spacing,23June2021,00:00–12:00 PST.
The two supplied MATLAB PNGs were inspected and are retained unchanged.

This is successful **measurement inspection**,not a thermal simulation,unit-test
suite execution,building-model validation or independent equipment validation.
No MATLAB execution occurred in Codex. The report has no exception and the supplied
log contains no reported warning/error. Initial fabric states remain unknown.

All public source/result JSONs and PNGs retain original bytes. The separately
named `matlab_execution.redacted.log` replaces one private university Output-path
line;provenance records original/redacted log hashes. `original_result_manifest.json`
is the original manifest and references the original private log,not its redacted
substitute. It is not a checksum manifest for this public derived evidence folder.

The **unchanged original ZIP** is preserved inside an AES-256-GCM encrypted archive;
immutable download URL,ciphertext hash and encryption details are in provenance.json.
Encryption round-trip and independently downloaded ciphertext were verified in
Python. Recovery returns exactly the original ZIP/hash. The separate64-hex-character
key is delivered only in the private user conversation and is **not committed**.
Save that key separately;loss of it prevents recovery of this encrypted original.
The user also retains the original uploaded ZIP. No plaintext private log is public.

MATLAB recovery helper (included in the historical archiver transfer package):

```matlab
recover_therma_evidence('C:\PRIVATE\original.aesgcm', ...
    'YOUR_SEPARATE_RECOVERY_KEY','C:\PRIVATE\THERMA_RESULTS_C42B.zip', ...
    'c146fd42ee036a3ac1fa487dfd411d3e1e691adb109d83de9cc36e288ec1cd9f');
```

The helper needs base MATLAB/JVM and the supplied SHA256 helpers. Recovery helper
native execution remains pending;encryption/decryption byte identity was tested
in Python. Do not publish the key or recovered private ZIP.
