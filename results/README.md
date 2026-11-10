# Compact returned evidence

New reviewed results may be archived as `results/<experiment>/<ZIP-SHA256-prefix>/`.
Existing evidence stays at `verification/` and `docs/results/`; it is not moved.

Keep original returned ZIPs in ignored `evidence_import/` until integrity, source
hashes, status and privacy are reviewed. Preserve originals unchanged in an
appropriate verified archive; publish only permitted, reviewed compact artifacts
with a provenance receipt linking original ZIP hash and source commit. Never label
failed inspection receipts as successful verification or inspection as simulation.
Raw FLEXLAB arrays must not be committed without redistribution rights.

See `docs/LIGHTWEIGHT_MATLAB_WORKFLOW.md` for exact review and commit steps.
