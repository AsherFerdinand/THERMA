# Reference building — C4.1 assessment only

**Conditional target:** Fraunhofer IBP Twin House **N2**, Holzkirchen,Germany,
Annex71 2018–2019 campaign. Original measured N2 payload and primary geometry/data
licence are still missing. This folder is not a ready simulation configuration.
See [assessment](../../docs/C41_BUILDING_DATASET_ASSESSMENT.md) and
[conditional zone diagram](../../docs/C41_BUILDING_ZONE_DIAGRAM.md).

## Obtain the original sources

1. Open the [official IBP dataset page](https://www.ibp.fraunhofer.de/en/projects-references/bes_model_validation_validation_datasets_from_the_fraunhofer_ibp_twin_houses.html)
   in a browser. It was blocked by this environment's proxy(HTTP403); availability
   on the university PC is not established. Obtain the **Annex71 N2** campaign,
   not an assumed equivalent Annex58/seven-zone archive.
2. Obtain `Plans_TwinHouses.pdf`, `01_Constructions_TwinHouses.xlsx`, the campaign
   experimental specification and revision/change notes. The inspected report
   referencesv4.6; the later exercise description referencesv5.0. Establish one
   consistent input revision rather than combining them silently.
3. Request/download original **N2 measured** room/weather/heater/ventilation and
   door/window/blind records with units, timezone, sampling/averaging convention,
   quality flags and licence/citation. The inspected mirror's data listing mostly
   names O5 files; no N2 measurement workbook was verified there. Do not substitute
   simulated `*_BWFKULEUVEN_v2.xls` results or the emulator's
   `Twin_house_O5_exp1_60min.xlsx` for measurements.
4. Save raw files under local `data/reference_building/raw/`, which is ignored.
   Preserve original bytes/names; record URL, retrieval date, byte size, SHA256,
   campaign/version and rights in a local manifest.
   No Git is needed to download individual files using the browser.

Small inspected documentation is available from the research mirror at commit
`ae7614bed0d7e5f5e73b3d52e6bcec8efe5f85f9`:
[description](https://raw.githubusercontent.com/gmor/annex71_st2_common_exercices/ae7614bed0d7e5f5e73b3d52e6bcec8efe5f85f9/docu/DescrptionR1.pdf),
[channel catalogue](https://raw.githubusercontent.com/gmor/annex71_st2_common_exercices/ae7614bed0d7e5f5e73b3d52e6bcec8efe5f85f9/docu/Measurement%20Channel%20List.xlsx),
[technical report](https://raw.githubusercontent.com/gmor/annex71_st2_common_exercices/ae7614bed0d7e5f5e73b3d52e6bcec8efe5f85f9/docu/Report_v2.pdf).
These are **mirrored research documents, not authenticated primary data releases**.
Downloaded only to temporary local research storage, not committed:

| Document | Bytes | SHA256 |
|---|---:|---|
|DescrptionR1.pdf|198063|`fe35d153190f3f8de264e6f508ecac6933276b0cfde0d7fca0a80ea514f47d9d`|
|Measurement Channel List.xlsx|33786|`acaf4b0a24cfcbe32da6758ea1693ccc1483bee1799b15e9f466446e793cf047`|
|Report_v2.pdf|3865747|`6a4955081e32e5e41f771cf9ec70d8086f2a135f53bdf19258e264831b3c00f1`|

The mirror's [GPL-3.0 licence](https://github.com/gmor/annex71_st2_common_exercices/blob/ae7614bed0d7e5f5e73b3d52e6bcec8efe5f85f9/LICENSE)
is not confirmation that third-party measurement/PDF/XLSX redistribution is licensed.
Obtain original IBP reuse terms before redistribution; C4.1 copies no raw files.

## Formats and required preprocessing — future work, not implemented

- Inspected documentation: PDF and XLSX. Channel sheet is `MainExperiment_Blind`;
  columnS names N2 channels, columnF units. Original measurement file schema is
  not yet verified. Do not infer duration/resolution from a filename alone.
- Resolve timestamp timezone, daylight-saving convention, interval start/end/mean
  semantics and duplicates/gaps. Do not manufacture missing values for validation.
- Map `_110_AT` air-temperature sensors to verified rooms; convert°C toK when
  required. `_GT` is globe temperature, explicitly not operative or air temperature.
- Keep weather radiationW/m² separate from absorbed surface heatW; require verified
  orientations, areas, glazing, shading/blinds before computing surface forcing.
- Ventilation volume flow is m³/h; heater channels are W. Reconcile heater/internal
  gain schedules and meter boundaries before integration; avoid double counting
  `_heat_elP` with derived `_IHS_elP`. Do not use plant electricity as room heat.
- Build a room-to-wall/window/floor/roof table from the primary geometry; shared
  partitions are single constructions exchanging energy between both zones.
- Only after data/rights/geometry review, define conditioning and an independent
  holdout interval. No preprocessing, fitting, simulation or empirical validation
  was performed during C4.1.

[ForDatis486/ThermBuild](https://fordatis.fraunhofer.de/handle/fordatis/486?locale=en)
was inaccessible here; formats/licence/buildings/signals remain unverified.
Simulation-only fallback: inspect a single pinned [ResStock HPXML example](https://github.com/NREL/resstock/blob/33433157aa52d1a97f35b9640bdf7a2c46f5d908/resources/hpxml-measures/workflow/sample_files/base.xml),
its EPW weather and independent simulation output. HPXML/R-values/U-factors need
schema-unit conversion; software [custom licence](https://github.com/NREL/resstock/blob/33433157aa52d1a97f35b9640bdf7a2c46f5d908/LICENSE.md)
does not automatically license every dataset release. This would establish a
simulation comparison, **not measured-building validation**. No fallback run begun.
