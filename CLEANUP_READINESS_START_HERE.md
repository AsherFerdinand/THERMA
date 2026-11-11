# Read-only cleanup readiness — MATLAB R2025a

Do not extract this package into `THERMA_C35_MATLAB`. Use a separate folder, for example `THERMA_CLEANUP_READINESS`. No Git, Python, WSL or MATLAB toolboxes are required; MATLAB's JVM must be enabled. Leave at least 30 MB available for recovery ZIP + extracted originals; use a separate drive if necessary. The source folder is never modified or deleted.

1. Save the ZIP, its published SHA-256, and the separate recovery key somewhere safe. Do not publish the key or new scan reports. Extract the toolkit outside the historical installation. Close running models/simulations and avoid other writes to the original folder during the scan.
2. In MATLAB, change `cd` to the extracted toolkit folder. Run:

```matlab
verify_cleanup_package
results = runtests(fullfile(pwd,'tools','matlab','test_cleanup_readiness.m'));
assertSuccess(results);
```

3. Rescan the historical folder. Replace both example paths with your actual paths. Use a NEW output folder, outside the historical installation, for every scan:

```matlab
report = run_cleanup_readiness( ...
    'D:\MATLAB\THERMA_C35_MATLAB', ...
    'D:\THERMA_cleanup_scan_01');
```

UNC paths are accepted, for example `original = '\\server\share\THERMA_C35_MATLAB'`. Do not copy these examples literally. Open `file_changes.csv` and `cleanup_readiness.json` in the output folder. Counts cover added/modified/deleted/unchanged/unreadable files. `preservation_required = true` identifies new/changed non-cache files requiring a separate archive and fresh-download hash verification. Review cache candidates and every scan error manually. No status authorizes deletion.

4. Recover the independent 291-file historical copy. Use the **separate key supplied in the conversation**, never a key from GitHub. Choose a private output location outside the original installation:

```matlab
addpath(fullfile(pwd,'tools','matlab'));
delivery = jsondecode(fileread('GIT_RECOVERY_DELIVERY.json'));
key = input('Paste the private 64-character recovery key: ','s');
privateZip = fullfile(tempdir,'THERMA_GIT_RECOVERY_private.zip'); % must not exist
recover_therma_evidence(fullfile(pwd,delivery.encrypted_name), ...
    key,privateZip,delivery.sha256);
clear key
recoveryFolder = 'D:\THERMA_verified_git_recovery'; % choose a NEW private folder
assert(~isfolder(recoveryFolder),'Use a new recovery folder');
unzip(privateZip,recoveryFolder);
verify_git_recovery(recoveryFolder)
```

Expected: **291 files, 11,098,106 original bytes**. AES-GCM authenticates the payload, the decrypted ZIP SHA-256 is checked, and all 291 extracted originals are checked against the preserved audit. Keep the encrypted toolkit, separate key, and checksum on an independent device/location. Merely copying to another folder on the same university disk is not independent preservation. Do not overwrite the historical installation with recovered files.

5. Keep all 13 original bulk assets too. Together they and the embedded 291-file recovery payload cover all 570 non-cache originals without future Git access. They are not a backup of files created/changed after the original audit.

6. Read `docs/CLEANUP_READINESS.md`. Preserve any drift, resolve privacy/rights/policy issues, and perform a final fresh scan before requesting explicit approval for manual cleanup. **Do not delete the university folder yet.**

If a test, hash, decryption, read, or output check fails: stop, retain originals, and return the error privately. Native MATLAB execution of this new toolkit has not been performed in Codex.
