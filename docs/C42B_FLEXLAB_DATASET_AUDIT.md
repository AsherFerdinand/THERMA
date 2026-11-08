# C4.2B — FLEXLAB dataset audit

**Acquisition succeeded; recommendation: CONDITIONAL, separate test-cell benchmark.**
This is an experimental facility, not a residential house. No thermal simulation,
calibration or empirical validation was performed. MATLAB execution is pending.

## Source and acquisition

Official repository: <https://github.com/LBNL-ETA/FLEXLAB-ASHRAE140>.
Pinned commit: `265312ec3843c97d5a24b7d5671ee2891f326af6`, inspected 2026-11-08.
A partial shallow Git clone was used, then selected genuine Git blobs downloaded.
Original bytes remain outside THERMA; no large raw data are committed.
[Source audit JSON](results/c42b/source_audit.json) lists every acquired filename,
byte size, SHA-256, immutable raw URL and time-series channel/count statistics.
It is acquisition/inspection evidence, not a MATLAB execution report.

Primary report: **Measured dataset for validation of building energy modeling
programs.pdf**, Christian Kohler, Zhaoyun Zeng, Ji-Hyun Kim, Ralph Muehleisen and
Philip Haves, April2023. Page references here and in the companion documents use
its printed page numbers; e.g. B-1 is PDF page47.

| Requested source | Actual inspection and limitations |
|---|---|
| README.md | Opened; identifies supporting measured results/construction files for ASHRAE SSPC140 research. Not a certification of THERMA. |
| Main report PDF | Opened/text extracted; geometry figures B-1–B-6 rendered and visually read. |
| Architectural and Structural Drawings | Both original PDFs acquired and text extracted. Detailed experimental geometry taken from updated report AppendixB, not older schematic dimensions. |
| Appendix C - Walls - THERM Files | Tree inspected; Wall Uvalues.xlsx opened as XLSX/XML; one original H-Middle-Full Model.THM acquired. Binary THERM7.2.9 signature inspected; THERM solver unavailable. Equivalent-layer definitions are also in AppendixB and Materials.csv. Not every historical THERM revision downloaded or solved. |
| Window Models | Tree inspected; Window_Avg.idf is readable EnergyPlus text. The file called `w78-FLEXLAB detailed report.txt` has a Microsoft Access/Jet database signature, **not readable plain text**, despite its extension. No native WINDOW/MDB execution claimed. Report TableA-1 supplies window results. |
| Input Data | All five original CSVs acquired and parsed. |
| Direct Validation Data | Both original CSVs acquired and parsed. |
| Indirect Validation Data | All13 surface-temperature, flux and transfer CSVs acquired and parsed. |
| Auxiliary Data | All files acquired: material/construction/air-gap CSVs, EnergyPlus IDF, pressure CSV and sensor-location workbook. Worksheets/rows opened through standard ZIP/XML, without Excel execution. |
| Meta data.xlsx | All four metadata worksheets opened/read. Source names/units checked against CSV headers; conflicts below. |

No root LICENSE/COPYING file exists in the pinned tree and README grants no explicit
data licence. The report's copyright notice (PDF page2) describes US Government
rights to the manuscript; it does **not** establish CC-BY rights for all CSVs/drawings.
Public access is established; general redistribution terms remain unresolved.
The update ZIP therefore contains our inspection code/metadata/docs, not raw data.
Download originals directly from the official repository; clarify rights with the
report/README contacts before republishing or distributing a complete data packet.

## Measurement mapping

All timestamps are **Pacific Standard Time, fixed UTC−08:00, no DST** (pp23,31).
The CSVs actually have nominal **60s** records, although p23 describes 10-minute
averages. Original acquisition filtering/averaging is not inferred from row spacing.
No timestamps or measurements have been interpolated, resampled or clamped.

| Quantity | Original filename and channel | Units; role |
|---|---|---|
| Indoor air | Direct Validation Data/Air temperature.csv: all26 supplied `X3B-stree1_*`, `X2B-stree2_*`, `X2B-stree3_*`, `X2B-stree4_*` headers (exact names in JSON) | °C, measured outputs. PrefixX2B does not imply a second measured validation zone: pp25–26 identify these as Cell3B stratification trees. |
| Outdoor air | Input Data/Weather data.csv: `W-OAT-2`, `3-OAT_South`, `3-OAT_North` | °C, measured inputs; inspection plot selects weather-station W-OAT-2, not wall-local alternatives. |
| Solar/longwave | Same CSV: `GHI`, `DNI`, `DHI`, `PIRin` | W/m², measured/processed weather inputs; absorbed interior solar is not directly provided. |
| Other weather | `W-3DUA-WINDSPD`, `W-3DUA-WINDDIR`, `W-CMH-DEWPT`, `W-OAP-1` | m/s, degrees, °C; **pressure unit unresolved**. Workbook Input!F12 says Pa, report Table4-1 says mbar; observed values near990 are not converted by this inspection. |
| Internal gain | Input Data/Internal heat gain rate.csv: `Internal heat gain rate [W]` | W, measured aggregate electrical load, not a heating-system output. |
| FCU cooling | Direct Validation Data/Fan coil units.csv: `Total cooling rate [W]`, individual Cooling_2/4, supply/return temperatures and Flow_2/4 | W, °C, m³/s. Cooling is water-side **derived** from measured flow/temperature, not independent electrical input. In backward envelope validation it becomes prescribed input. Retain signs, including negative records. |
| Ventilation | Input Data/Duct blaster.csv: `Flow adjusted [m3/h]`, `Ventilation air temperature [C]`, `Ventilation heat transfer rate [W]`, P1/P2/Flow/Coefficient | m³/h, °C, W, Pa. Adjusted flow and heat transfer are derived. Do not count both derived power and an airflow heat term. |
| Surrounding surfaces | Input Data/Exterior surface temperature.csv: DropCeiling, TemporaryNorthWall, EastWall, SouthWall, WestWall, Ground (trailing space), Floor | °C, measured boundary observations; ground-depth channels separately available. |
| Additional outputs | Indirect Validation Data: interior temperatures, heat flux, integrated surface transfer | °C, W/m², W. Transfer rates involve spatial weighting/regression, not independent raw calorimetry (pp13–16). |

The workbook lists additional stree5 channels absent from the air CSV and uses
`Internal heat power`/`Flow power` names differing from actual CSV headers. The
inspection uses exact supplied CSV names and all26 available air sensors. Their
arithmetic mean is labelled explicitly; no volume weighting or operative-temperature
interpretation is implied. Whole-file missing cells/gaps and per-channel selected
extrema are recorded in JSON; absence of a timestamp is counted separately from
NaN cells. Do not fill missing records silently.

## Selected continuous period

**2021-06-23 00:00–12:00 PST inclusive:721 rows,720 intervals,12h.**
Nineteen of20 inspected time-series CSVs have721 selected rows and no missing
selected cells. WestWall heat flux.csv has only172 rows in this period:549 expected
timestamps are absent, even though its present cells have no NaNs. This blocks a
complete same-period west-wall flux comparison. The six core input/output CSVs
pass finite-value checks at every expected minute. Full files have gaps/NaNs; this statement applies only to the selected period.
This is within the authors' recommended conditioned experiment (22–27June2021),
before the additional heaters on25June15:00. It is a short feasibility/inspection
window, not proof of a sufficiently informative final holdout or an equilibrated start.

The co-heating experiment (8June14:00–14June08:00) is **not selected**: report
pp30–31 says it failed satisfactory whole-cell energy balance. The conditioned
experiment is preferred by the authors; their reported30-minute CVRMSE32.8% and
NMBE3.79% describe experimental closure, not THERMA errors or acceptance limits.
Observed air/boundary values at the first timestamp do not supply all internal
fabric states. Preconditioning is recommended on p31; a defensible procedure and
uncertainty assessment are still needed before validation.

## MATLAB R2025a inspection

Download these **six original files** from the immutable URLs in source_audit.json:

- `Direct Validation Data/Air temperature.csv`
- `Direct Validation Data/Fan coil units.csv`
- `Input Data/Weather data.csv`
- `Input Data/Internal heat gain rate.csv`
- `Input Data/Duct blaster.csv`
- `Input Data/Exterior surface temperature.csv`

In a browser, navigate to the pinned repository commit, open each file and use
**Raw → Download**. Preserve filenames/subfolders under
`data/reference_building/raw/flexlab/` inside the existing THERMA folder. Do not
save a GitHub HTML page as a CSV. Alternatively pass the extracted official source
folder explicitly. No Git/Python/WSL is needed on the university computer.

Extract the C4.2B update into the existing THERMA folder, then:

```matlab
cd('C:\PATH\TO\THERMA_C35_MATLAB')
output = run_c42b_flexlab_inspection;
% Or: output = run_c42b_flexlab_inspection('C:\PATH\TO\FLEXLAB-ASHRAE140');
```

The script verifies pinned file SHA-256, displays channels/full-file missing/gap
counts, requires every selected minute/finite value, produces temperature/cooling
plots and `inspection_summary.json` in a new ignored `outputs/c4/c42b/` folder.
No network operation or simulation occurs in MATLAB. Missing files/hash changes/
selected gaps stop explicitly. MATLAB execution remains **pending**; only static
checks were possible here. Two genuine measurement previews under results/c42b/
were generated using Python, not MATLAB, and are labelled inspection-only.

Cloud audit reproduction with already-downloaded sources and existing dependencies:

```bash
uv run --frozen python scripts/reference/audit_flexlab.py /path/to/pinned/source /tmp/source_audit.json
```
