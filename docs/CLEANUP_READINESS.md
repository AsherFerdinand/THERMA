# Final cleanup readiness

Prepared 11 November 2026. **Not ready for deletion: native rescan and manual preservation/privacy decisions are pending.** No original or archived evidence is changed by this workflow; C4.3 is not started.

## Preservation status

The independent [final audit](HISTORY_ARCHIVE_FINAL_VERIFICATION.md) recovered all 570 non-cache originals, including 36 SLX models. The original 602-file audit includes 32 intentionally excluded generated caches. The 279 bulk-archived originals occupy 420,811,850 bytes; the remaining 291 Git-dependent originals occupy 11,098,106 bytes.

The new small execution package embeds an **encrypted, self-contained 291-file recovery ZIP**, retaining original relative paths and exact SHA-256 identities. Its manifest records original audit rows and recovery locations; no Git is needed to recover it. The original audit and archived bytes remain unchanged. The encrypted payload plus the 13 existing bulk assets are sufficient for this audited non-cache snapshot. Keep the separate encryption key and independent copies of both sets of assets. Loss of the key prevents recovery from the encrypted copy.

## New rescan

`run_cleanup_readiness(originalFolder,outputFolder)` compares exact relative paths, SHA-256 and sizes against the preserved audit. It reports added, modified, deleted, unchanged and unreadable files, flags new/changed non-cache files for preservation, and records scan errors. A renamed file appears as added plus deleted. Case-only renames are also reviewed rather than silently matched.

The scanner streams file hashes, never loads a model, refuses output inside the original folder, skips linked/aliased paths with an explicit scan error, and checks file metadata for changes during hashing. A live scan is not an atomic filesystem snapshot: close simulations and avoid concurrent writes. Apparent deletions under unreadable directories are not accepted as confirmed absence. Cache candidates (`.slxc`, `slprj`) require manual confirmation; all scan errors block readiness. Reports contain relative paths and may still be sensitive. Do not publish them automatically.

## Disclosure review

Static review of recovered text, SLX XML, decoded FIG structures and PDF text found:

| Material | Evidence / required manual decision |
|---|---|
| Build reports and logs | Original university UNC/account paths, especially `c35_build.json`, C3.5 console logs, C3.8 comparison/case reports, C4.0 failure report and historical C2 verification JSON. Review with university IT/policy owner before public retention or redistribution. |
| All 36 SLX models | Creator/last-modifier metadata; check whether it identifies an individual or account and whether public disclosure is permitted. Do not run callbacks just to inspect metadata. |
| Third-party model/dataset descriptions, source notices and manufacturer information | Licence/copyright references are present. They do not prove a violation or confer redistribution rights. Review upstream terms, attribution and university ownership rules. |
| PNGs, rendered PDFs and FIGs | Automated text/structure review does not replace visual review for usernames, paths, branding or other restricted information. |

There were no credential-assignment candidates in the limited static scan. This does not establish absence of secrets or constitute legal clearance. Detailed raw path values are deliberately omitted here. The original public bulk assets may already contain disclosures: encrypting the new recovery copy does not retract them. Obtain an explicit decision on their public availability; retain an unchanged restricted/private preservation copy if public access must change. Never redact or replace the only original evidence. No Release assets are removed or altered by this task.

## Exact prerequisites for any deletion recommendation

1. Run the new MATLAB tests, package verification, rescan and 291-file recovery verification successfully on the university PC; retain the reports and SHA-256 results privately.
2. Account for every added/modified non-cache file since the original audit. Archive its original bytes/relative path/hash, download the remote copy afresh, and verify restoration. Reconcile deletions, cache classifications, unreadable files and linked directories; no unresolved scan errors may remain.
3. Retain independent copies of all 13 bulk assets, the encrypted 291-file package and its separate key, with checksums. Verify access/recovery from a location independent of the university disk. The original 570-file audit is already passed; verify new preservation material to the same standard.
4. Complete manual privacy, copyright and university-policy review, including a decision on existing public assets and any retention obligations. Preserve immutable originals privately where required. Document the decision without publishing personal data.
5. Perform a final rescan after the last write; preserve any further drift. Confirm the lightweight C4.2B workflow and required current project files remain accessible separately.
6. Only after all preceding conditions pass, request explicit approval naming the exact folder proposed for manual deletion. This toolkit neither approves nor performs deletion.

## Verification limits

Python packaging checks independently validate every recovered input hash, all ZIP members/CRCs, encrypted round-trip byte identity and fresh extraction. MATLAB regression cases cover inventory classification, cache candidates and ambiguous paths. **MATLAB R2025a execution remains pending at the university**; software tests are not simulation or physics validation. Thermal models, solver settings, existing C4.2B runners and prior results are untouched.
