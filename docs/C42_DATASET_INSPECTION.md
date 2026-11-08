# C4.2 — Annex58 acquisition and inspection status

**Original measurements unavailable; no processed reference data or temperature
plot generated.** Access checked2026-11-08. The user's specification PDF was not
attached; workspace search found no copy. Dataset identity/2013 period/CC BY4.0
come from the request, not independently downloaded metadata.

## Exact access failures

All entries below failed with **HTTP403 from the network proxy during HTTPS
CONNECT**. No publisher-origin HTTP response was obtained; this is not evidence
that the repository requires authentication or is globally unavailable.

| Requested URL | Role / outcome |
|---|---|
|https://doi.org/10.15129/8a86bbbb-7be8-4a87-be76-0372985ea228|Official DOI; proxy403|
|https://api.datacite.org/dois/10.15129/8a86bbbb-7be8-4a87-be76-0372985ea228|DOI metadata alternative; proxy403|
|https://pureportal.strath.ac.uk/en/datasets/annex-58-twin-houses-empirical-data-set-experiment-1|Candidate university record route, not a confirmed DOI target; proxy403|
|https://strathprints.strath.ac.uk/|Alternative university repository root; proxy403; no dataset mirror established|

Because no publisher record was accessible, **no published direct URL** for
`Supplementary_files.zip`, `Supplementary_file_structure` or the specification
was discovered. Their origin HTTP status and download sizes remain unknown.
No guessed file URL, authentication bypass or unverified replacement was used.
Public repository citation searches did not establish a publisher-hosted mirror.

## Manual acquisition — original names and bytes

1. Open the official DOI in a normal browser, preferably on the university PC.
   Follow the publisher's actual file/download links; do not use our unconfirmed
   candidate route as proof of the correct record.
2. Save `Empirical_Modelling_Specification_200514.pdf`, `Supplementary_files.zip`
   and `Supplementary_file_structure` (preserve its real extension). Record the
   actual download URLs, citation/version/licence notices, byte counts and SHA256.
3. Put originals under local `data/reference_building/raw/annex58_experiment1/`;
   that directory is ignored by Git. Do not rename or edit raw measurements.
4. Supply the PDF and archive structure for authoritative review. Use the structure
   to identify only Experiment1 files and a short contiguous period; do not replace
   them with Annex71 or simulated outputs. The archive has not been sized here.
5. If browser download also fails, record the actual file URL and its observed
   response. Do not change credentials or access controls to get around a refusal.

No raw archive, PDF or measurement file is redistributed in the update ZIP.
The user's CC BY4.0 identification is recorded; original creator attribution and
file-specific notices remain to be captured when the record is accessible.

## What cannot yet be inspected

Original filenames beyond the three named deliverables, room signal columns,
units, measured/prescribed/simulated classification, timestamp timezone/format,
sampling interval, missing-value tokens and initial states are **unverified**.
There is no data-completeness percentage, ordering result or energy total to report.
No resampling, interpolation, gap filling, unit conversion or synthetic data was
performed. Structural checks on empty configuration arrays do not validate geometry.

First inspection will select **one complete contiguous24h segment** only after
checking actual coverage, units and the documented experimental phase within
21Aug–30Sep2013. No exact start/end or warm-up is invented now. A later validation
period must be chosen from the real experiment protocol before fitting: compare
measured room air with like-for-like model air using MAE/RMSE/bias, and assess
energy only with a documented heat-input boundary. Prescribed heat-energy agreement
would check input consistency, not independent plant prediction. Numerical checks,
independent-simulation comparison and empirical validation remain distinct.

## MATLAB R2025a missing-input entry point

Extract the source update into `THERMA_C35_MATLAB`, then run:

```matlab
folder = run_c42_reference_inspection;
```

Optionally pass the directory containing original files. It reports local presence,
unknown zones/signals/units and writes `inspection_summary.json` under a new
`outputs/c4/c42/` folder. Even present files are not automatically trusted/reviewed.
**No plot is expected in this blocked mode.** MATLAB execution is unperformed in
cloud. Once authoritative geometry and actual data are inspected, C4.2 must be
continued with a source-bound processed subset and real temperature plot; simply
flipping readiness flags will not enable it. No complete house simulation exists.

## FRP-2 fallback assessment — not selected

The requested [Nature article](https://www.nature.com/articles/s41597-022-01858-6)
also failed with proxy403. Legitimate metadata routes
[Crossref](https://api.crossref.org/works/10.1038/s41597-022-01858-6) and
[PubMed search](https://pubmed.ncbi.nlm.nih.gov/?term=s41597-022-01858-6) failed likewise.
A [secondary research README](https://github.com/goodekang/pace-hvac/blob/dab5532a35a6904dfa93c8e5a249f2d13ec723fd/README.md)
points to [OpenEI](https://openei.org/datasets/dataset/ornl-flexible-research-platforms-frp),
which also returned proxy403. That README explicitly does not redistribute the
FRP-2 traces; it is not an authenticated source for building parameters or data.

| Criterion | Annex58 Experiment1 | Oak Ridge FRP-2 |
|---|---|---|
|Identity/licence/period|DOI,CC BY4.0,2013 period supplied by user|Publication URL supplied; record/licence/period not retrieved|
|Geometry/constructions|Official PDF named, not available here|Not inspected; residential suitability not established here|
|Measured channels/units/sampling|Archive inaccessible; schema unknown|Original data not obtained; schema unknown|
|Readiness|Blocked pending official PDF/archive|Cannot establish a more accessible or suitable replacement|

Remain with Annex58. **No fallback switch is made or recommended as ready**.
A substantive FRP-2 selection requires primary documentation/data inspection and
user approval; no building type, room count or measurements are guessed.
C4.2 remains incomplete. C4.3 has not started.
