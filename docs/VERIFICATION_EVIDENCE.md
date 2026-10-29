# Verification evidence and provenance

C1 and C2 passed on university MATLAB R2025a according to the user. The original C2
report is now [archived unchanged](../verification/c2/matlab-r2025a/b00092e4236789a4/verification.json)
with [separate provenance](../verification/c2/matlab-r2025a/b00092e4236789a4/metadata.json).
C1's full report is still awaiting import.

The actual C2 JSON records `status=passed`, `matlab_verified=true`, ten passed
scenarios, coarse/refined metrics, convergence, MATLAB `25.1.0.2943329 (R2025a)`,
Simulink `25.1`, and input interpolation `off`. All 15 recorded MATLAB source hashes
match the repository and commit `071269ef6c1d558785b58b6e82ade540c2fc6d39`.
Registry SHA-256 is `f91141d78668908525d484a4900dc69af1a163c4c5e07f5a5fbd0c43eae4451c`;
assumptions SHA-256 is `de81bc5fe282ff6f91c95a167d4db797cce66f0deeb4806bc6a0db3cfc1ffc61`.
Original report SHA-256:
`b00092e4236789a4fca959fc0a18d779b038d4b686064d8d876a402e22c8babe`.

The user separately reports **7/7 MATLAB unit tests**, zero failed/incomplete, about
10.21 s at Technische Hochschule Ingolstadt. That unit-test log is not part of the
uploaded JSON, so it remains a user-reported result rather than an archived test log.
The ten actual report scenarios are equilibrium, cold_outdoor, constant_heating,
heating_step, heating_shutdown, outdoor_step, internal_step, solar_step,
warm_ventilation and surface_perturbation.

This is local MATLAB engineering verification of the reduced equations, connections,
conservation and numerical response under synthetic scenarios. It is not independent
Codex/CI MATLAB execution, experimental building validation, exact BOPTEST equivalence
or evidence that provisional coefficients are calibrated. Evidence is unsigned: hashes
protect integrity against changes relative to recorded metadata, not authenticity
against an adversary replacing every artifact and hash.

## Importing another original report

Do not reformat the JSON. Copy only the selected report into `evidence_import/`, not
the whole generated output directory. For the known university report the source was:
`outputs/boptest/simulink_c2/verification/tp162a8b0d_9b5a_43fa_ae6b_40df1daa4474/verification.json`.
From repository root:

```sh
uv run --frozen python -m therma.validation.archive \
  --phase C2 --report evidence_import/verification.json --matlab-release R2025a \
  --source-commit 071269ef6c1d558785b58b6e82ade540c2fc6d39
uv run --frozen python -m therma.validation.archive --check
```

The supplied report is already imported; importing identical bytes again is refused.
For future reports omit `--source-commit` when the actual compatible source revision
is unknown. Never assume HEAD produced the report. The tool compares all recorded
source hashes against `--source-root` (default current project), including the frozen
registry and assumptions, and optionally against an explicit Git commit. A mismatch
is rejected: provide the actual source snapshot rather than editing hashes. New
unrecorded source files do not invalidate old evidence. Legacy C1 lacks full source
hashes; its Git source provenance stays unresolved.

The importer supports legacy unversioned C1/C2 reports; an explicit unsupported
schema version is rejected. It requires passed overall status, MATLAB verification,
exact nonduplicate scenario coverage and passed per-case results. C2 also requires
coarse/refined solver metrics, convergence and required source/assumption hashes.
It preserves input report bytes, creates a new hash-named evidence directory, writes
separate metadata and refuses duplicates/overwrites. Verification date is recorded
only when supplied as `--verification-date YYYY-MM-DD`, labelled user-supplied.
It is not inferred from import time or Simulink's product release date.

## Without Git or Python on the university PC

Git is not required. If Python 3.12 is available, use the downloaded source ZIP:

```powershell
py -3.12 -m venv .venv
.venv\Scripts\python -m pip install -e .
.venv\Scripts\python -m therma.validation.archive --phase C2 --report evidence_import\verification.json --matlab-release R2025a
```

Omit `--source-commit` without Git. Copy the selected archived report and metadata
back to Codex for review/commit. If Python is unavailable, upload the original JSON
to Codex; the uploaded C2 report was imported that way. Include exact source files if
the importer finds a mismatch. Never fabricate a replacement report or silently
normalize line endings. `.gitattributes` disables report text conversion.

CI runs report/schema/hash integrity checks and Python regressions, plus static
MATLAB lint. Only university execution has generated the archived MATLAB results.
