# Historical archive final verification

Independent audit: 11 November 2026. **Recovery of the audited non-cache files passed; deletion of `THERMA_C35_MATLAB` is not recommended.**

## Results

Downloaded all 13 bulk assets from the [GitHub Release](https://github.com/AsherFerdinand/THERMA/releases/tag/archive-matlab-models-2026-11): 12 archive parts and one catalog, totaling 193,857,511 bytes. Incremental archives and the separate model backup were not used.

| Coverage of the original 602-file audit | Files | Original bytes |
|---|---:|---:|
| Recovered from the 12 Release parts | 279 | 420,811,850 |
| Recovered from recorded Git snapshots/transfer ZIP members | 291 | 11,098,106 |
| Deliberately excluded generated caches | 32 | 56,663 |
| Missing, corrupted or unaccounted non-cache files | **0** | **0** |

Extracted into a fresh temporary recovery directory with original relative paths. All **570 reconstructed files / 431,909,956 bytes** match their original sizes and SHA-256 hashes. All **36 `.slx` files** are recoverable and also pass their internal ZIP CRC checks. Duplicate-content originals retain their distinct paths. Every `cleanup_review.csv` row matches `storage_audit.json` for path, size and digest.

## Integrity and provenance

All 13 downloaded assets were hashed. All 12 part digests and sizes match the catalog; part manifests, member sets, original hashes and ZIP CRCs pass the existing verifier. Catalog audit/preservation data match the repository originals, its plan matches recomputation, and toolkit hashes match its pinned source commit.

Catalog ZIP SHA-256:
`fb2f876ae19aadabc5ca1f19a319a74cddda536fb8dfcf953513cdbe3bc1363c`

No separately supplied expected catalog-ZIP digest was available for independent comparison. Its digest is recorded for future checks; embedded contents were independently checked. The user's MATLAB remote-digest verification remains separately reported evidence.

See [all 13 asset checksums](../history_reference/HISTORY_ARCHIVE_SHA256SUMS) and [machine-readable audit](../history_reference/final_archive_verification.json). The original catalog's historical `locally_verified_only` flags remain untouched; this report records the subsequent remote-download recovery check.

## Future recovery

The catalog contains original paths, byte counts, SHA-256 values, archive assignments, exclusions, and pinned Git recovery locations. It is sufficient to locate and verify audited non-cache originals **provided those Git objects and transfer ZIPs remain available**. The 13 assets alone do not contain the 291 Git-preserved files.

1. Download the catalog and all 12 parts; compare with the checksum list.
2. Run `python tools/history_archive.py --returned PATH_TO_DOWNLOADS` from THERMA.
3. Extract validated original members into an empty directory, retaining relative paths and excluding `__THERMA_ARCHIVE__` metadata from the original tree.
4. For `github_preserved` records, use the audit's `commit:path` or `commit:ZIP#member` locations to restore the exact bytes. These were recovered from locally available pinned Git objects during this audit.
5. Check every restored size and SHA against `storage_audit.json`. The 32 excluded `.slxc`/`slprj` cache files are regenerable, not preserved originals.

Retain an independent copy of both pinned Git snapshots and required transfer ZIPs; a moving branch or Release alone is insufficient preservation. Source snapshot: `a57a62aa823624688a62ccde0ac7ed8a039a210e`; transfer snapshot: `647a7a81a00ab9462e9c754e190b45a962fae513`.

## Privacy, restrictions and remaining risks

Static review covered text/CSV, nested SLX XML/metadata, decoded MATLAB FIG structures, and extracted PDF text. Confirmed university network paths occur in build JSON/reports/logs; all 36 SLX files contain creator/last-modifier metadata. Review these for account/identity disclosure before further public distribution. Do not rewrite preservation originals to redact them; any public redacted copies must be separately identified.

Licence/copyright wording requires manual review where third-party content is involved; keyword matches do not establish a restriction. No credential-assignment candidates were detected by the limited scan. This is not comprehensive secret detection or legal clearance. PNGs and rendered PDF/FIG content have not received full visual review.

**Keep the original university folder for now.** Resolve the privacy/restriction review, independently preserve the Git dependencies, and compare a fresh university inventory against the original audit before considering deletion. Files added or changed after that audit are outside this result.

## Checks and limits

Existing archive verifier passed; fresh reconstruction and original-file hashes passed; all SLX ZIP checks passed. Python: **238 passed, 3 optional plotting tests skipped**. Ruff lint/format, mypy, archived-report checks and replay mapping checks passed. No MATLAB execution or thermal-model validation was performed. No original university files, simulation physics, or existing archive assets were modified.
