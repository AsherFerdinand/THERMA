# C4.2 — Annex58 Experiment1 building specification

**Blocked; no authoritative geometry has been extracted. C4.2 is not complete.**
The official PDF is not in the supplied attachments/workspace. The DOI and
university access routes could not be retrieved. Do not use the previous Annex71
N2 catalogue, ten-zone diagram, materials or2018–2019 conditions as substitutes.

## Source identity and evidence level

- Dataset: *IEA EBC Annex58 Twin Houses Empirical Dataset, Experiment1*.
- DOI: [10.15129/8a86bbbb-7be8-4a87-be76-0372985ea228](https://doi.org/10.15129/8a86bbbb-7be8-4a87-be76-0372985ea228).
- Publisher: University of Strathclyde. Reported experiment:21Aug–30Sep2013.
- Licence: **CC BY4.0**, as explicitly reported by the user from the publisher.
  Publisher metadata, formal creator list and archive-specific notices were not
  independently retrieved here. Attribution must retain the dataset title, DOI,
  publisher and original creator/version citation when recovered; mark derivatives.
- Required authoritative file: `Empirical_Modelling_Specification_200514.pdf`.
  No PDF SHA256, source page or parameter value is invented.

## Traceable configuration scaffold

[configs/buildings/annex58_experiment1.json](../configs/buildings/annex58_experiment1.json)
is a **blocked scaffold, not a runnable building definition**. Known dataset
identifiers are attributed to the user's source description. Physical unknowns
remain `null`; collections are empty because extraction has not occurred, not
because the real house has no zones/windows/walls.

| Required information | Current status / evidence required |
|---|---|
|House identifier, location, footprint, storeys|Unknown; official specification pages needed|
|Actual rooms, dimensions, volumes|Unknown; no seven-/ten-zone count adopted|
|Exterior and shared interior surfaces|Unknown; no adjacency or area inferred|
|Roof, floor, cellar boundaries|Unknown; no adiabatic/default temperature assigned|
|Windows/orientation/glazing areas/properties|Unknown; no default U-value or solar factor|
|Layer thickness,k,rho,cp|Unknown; no C3.7/BESTEST materials copied|
|Ventilation/infiltration|Unknown; no default air-change rate|
|Initial air/fabric states|Unknown; no uniform20°C start assumed|
|Source pages/classification|None reviewed; all physical values remain unextracted|

After receiving the PDF, each approved zone/surface/construction/window record
must carry its source filename,SHA256,page and classification: measured,
specified, calculated or assumed. Store lengths in m, areas m², volumes m³ and
preserve original units/conversion notes. Calculations require documented inputs.
Give each shared physical partition one identifier and one stored construction,
with the two correct zone endpoints; do not double-count area or wall mass.
These are extraction requirements, **not checks already passed on this house**.

The existing multilayer thermal-envelope approach may be reused after these
records exist. No Simulink blocks, equations or preprocessing transforms are
introduced. A verified house architecture cannot be approved from this scaffold.
See [inspection/access report](C42_DATASET_INSPECTION.md) and
[unresolved topology diagram](C42_THERMAL_ZONE_DIAGRAM.md).

**Next required input:** attach the user's existing specification PDF and
`Supplementary_file_structure`, then provide the original archive or its actual
publisher download link. Continue C4.2 extraction before any C4.3 implementation.
