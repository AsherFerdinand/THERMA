# Selected engineering verification evidence

Only small selected original reports and separate provenance metadata belong here.
Generated models, trajectories, plots, runtime environments and raw datasets remain
under ignored outputs/. Original report bytes must never be reformatted.

- C2: [original R2025a report](c2/matlab-r2025a/b00092e4236789a4/verification.json)
  and [import provenance](c2/matlab-r2025a/b00092e4236789a4/metadata.json).
- C1: university pass is user-reported; its full original report is not archived.

The C2 report was supplied by the user from university MATLAB execution. Import and
CI check integrity; they do not independently execute MATLAB or establish BOPTEST
validation. The separate 7/7 MATLAB unit-test result is user-reported, not encoded
as a test-results artifact in this C2 JSON. See docs/VERIFICATION_EVIDENCE.md.

```sh
uv run --frozen python -m therma.validation.archive --check
```
