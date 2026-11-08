# C4.1 — Residential reference-building assessment

**Decision: conditionally select Fraunhofer IBP Twin House N2, Annex71 main
experiment (2018–2019). Not yet execution-ready.** N2 has documented room-air
measurements and electric heating, allowing envelope/inter-room assessment without
introducing O5's embedded floor-heating plant. No new model or empirical-validation
result is claimed. This is a physical residential testhouse with synthetic-user
schedules, not an occupied-home monitoring study. Access checked2026-11-08;
no raw measurements/FMUs downloaded.

## Candidates and evidence

| Candidate | What was actually inspected | Suitability and remaining gaps |
|---|---|---|
|[IBP Twin Houses](https://www.ibp.fraunhofer.de/en/projects-references/bes_model_validation_validation_datasets_from_the_fraunhofer_ibp_twin_houses.html)|Primary page blocked here by proxy HTTP403. Accessible research mirror: KU Leuven technical report, channel catalogue, experiment description and file listings [R1–R3]. README locates the houses in **Holzkirchen,Germany**.|Best measured-data prospect. House N2 is electrically heated; O5 uses underfloor heating after co-heating. Full dimensioned plans, original construction workbook, N2 measurement payload and dataset rights not recovered. Mirror mixes real and simulated files.|
|[ThermBuild,ForDatis486](https://fordatis.fraunhofer.de/handle/fordatis/486?locale=en)|Supplied catalogue URL attempted; proxy HTTP403. No authoritative metadata/download inspected.|Location/type, dimensions/rooms, construction/U-values, weather, temperatures, heating, duration/interval, formats and licence **all unresolved**. Do not infer that it contains measured multi-room temperatures or reject its merits solely from this local access failure.|
|[ResStock](https://resstock.nlr.gov/)|Site blocked here; official repository README, licence, national-baseline YML and bundled HPXML example inspected [R4]. OpenStudio/EnergyPlus generates representative US dwellings.|Accessible **simulation** alternative, not a measured-house dataset. HPXML supplies assembly/geometry inputs, not a surveyed room plan. Example is Colorado detached housing with3 bedrooms/2 bathrooms and Denver TMY3 weather reference; bedrooms are not thermal zones. Config enables hourly zone-temperature/weather/load reporting over2007; no output trajectory or measured signals inspected.|

ResStock's example contains wall/roof/foundation/floor/window inputs, effective
R-values and glazing U-factors. Missing/defaulted thermal storage and generated
geometry must be audited before reproduction; no SI dimensions or material
properties are adopted here. Actual output column names/units and room-level
resolution require the selected release's output schema. Its software licence is
**custom ResStock terms**, not assumed BSD/CC-BY; data-release terms are separate.
Twin Houses mirror has GPL-3.0 repository text, which does **not establish rights
for every third-party IBP workbook/PDF**. Primary data reuse terms remain a gate.

## Selected N2: established facts versus model assumptions

[R1] is a **simulation-methodology report**, not the original building survey.
It documents10 model zones across ground/attic levels (§2.2), taking geometry from
`Plans_TwinHouses.pdf`. The channel catalogue independently lists10 named measurement
spaces: living,dining,kitchen,bedroom,bath,doorway,corridor,child1,child2,stairs.
Do not assume this proves a one-to-one room/zone mapping before inspecting plans.
Floor area, external dimensions, room dimensions, wall orientations/areas and all
window/glazing areas remain unverified. Reported model-input volumes212.394m³
ground floor and137.012m³ attic (Table1) are **not adopted as surveyed geometry**.

Available construction evidence: [R1]§§2.4–2.5 describes exterior walls/roof,
interior partitions, attic floor, windows, doors and thermal bridges. Table2 gives
an **adjusted modeller roof assembly**, not a measured roof; window-frame U=1W/(m²K)
is a model choice, not whole-window U. Exact original layers,k/rho/cp and glazing
specifications require `01_Constructions_TwinHouses.xlsx` and experiment specs.
The ground-floor boundary in that report is **measured cellar temperature**, not
an adiabatic surface or outdoor/ground temperature (§2.4.3). The attic floor couples
zones; the roof faces outdoors. Living-room south glass door and west-facing
living/kitchen windows are reported (§§2.1,2.8.6); their areas remain unknown.

## Signals and period

These are **catalogued channel names/units**, not verified downloaded time-series
headers. [R2],sheet `MainExperiment_Blind`,columnS identifies N2 channels:

| Signal | Unit; intended use | Source location |
|---|---|---|
|`N2_aroom_living_110_AT` and corresponding room `_110_AT` channels|°C; room air at1.10m, primary output|row93; other room rows in same sheet|
|`AmbientAirTemperature`|°C; measured weather-station boundary|row3|
|`Radiation_Global`, `Radiation_Diffuse`, `Radiation_North/East/South/West`|W/m²; station radiation, geometry/blind mapping still needed|rows in weather block; Global8,South10|
|`N2_aroom_living_heat_elP` and corresponding room heat channels|W; catalogued sensible heater input, verify meter boundary/storage before equating to delivered heat|row97|
|`N2_cellar_285_AT`, `N2_cellar_285_AT2`|°C; basement boundary observations|rows107–108|
|`N2_Vent_living_SUA_AT`, `N2_Vent_living_SUA_VFR`|°C,m³/h; supply-air boundary|rows141,144|
|`N2_aroom_kitchen_door_pos`, `N2_aroom_child1_win_pos`|dimensionless; opening states|rows90,51|

`_GT` is **globe temperature**, not air; row94 explicitly says **not operative
temperature**. Do not substitute it for `_AT`. Multiple air heights support a
stratification check, not an assumed well-mixed measured average. Heater/internal
gain channels need reconciliation: some `_IHS_elP` fields are calculated schedules,
not independent metered additions. Avoid double counting. Heat-pump electricity
or supply-temperature commands are not delivered zone heat.

[R1] reports campaign7Dec2018–1Mar2019 and10-minute simulation outputs subsequently
averaged hourly; these do not prove actual measurement timestamp semantics. Mirror
names advertise10/60-minute workbooks, but their complete sampling, gaps, timezone
and usable duration were not inspected. [R3] specifically describes
`Twin_house_O5_exp1_60min.xlsx` as emulator-generated excitation output: **not a
measured N2 reference**. The report's `*_BWFKULEUVEN_v2.xls` files are also simulated.

## Proposed zoning and validation — no implementation

Keep the10 instrumented spaces as **candidate** separate zones until plans confirm
the enclosed volumes. Do not merge living/dining, corridors/doorway or stairs/attic
merely to achieve an arbitrary zone count. Group only where verified open geometry,
operation and temperature measurements justify it; preserve sensor-to-zone mapping.
Doorway+living is a candidate aggregation because their opening is reported always
open, but it is **not approved without temperature/plan evidence**. Keep separately
heated child rooms distinct by default, even where doors to stairs remain open.
[Zone diagram](C41_BUILDING_ZONE_DIAGRAM.md) shows only source-reported openings.
For shared partitions, identify both rooms, area and layers, count wall storage
once, and conserve equal/opposite exchange. Door/trapdoor mixing is distinct from
solid-wall conduction. Do not copy C3.7's adiabatic floor/ceiling approximation.

Start with **N2 co-heating**, using measured electrical heating as prescribed input
with its conversion/storage/radiant-split assumptions explicit; do not build a heater
controller/plant. Proposed holdout **10–17Dec2018**, conditional on original records
confirming continuous co-heating, after7–10Dec input-driven conditioning. Dates are
a proposal, not a verified usable selection; full initial fabric states are unknown.
Pin one campaign/specification revision: [R1] referencesv4.6, [R3]v5.0; do not mix
these, nor presume an Annex58 archive or a seven-zone teaching model is the same
experiment.

Then align units/timestamps, exclude warm-up, flag gaps and door/blind changes,
and compare per-room air MAE,RMSE,bias and maximum error on a shared grid. Audit
heater energy over exactly the same period only after establishing the meter/heat
boundary and interval-averaging semantics. With prescribed heat, energy agreement
checks input consistency, not independent heating-system prediction. No arbitrary
accuracy threshold or
calibration to the holdout. Separate numerical conservation/regression checks,
comparison with independently simulated IDEAS/EnergyPlus output, and **empirical
validation against authenticated measured channels**. None is newly achieved here.

**Next engineering task:** recover matching primary plans, construction/specification,
N2 measurements/weather and explicit licence; perform a metadata/geometry audit
before authorizing C4.2. If those cannot be obtained, a pinned ResStock HPXML example
is a feasible **simulation-only** fallback, with no empirical-validation claim.
C4.1 stops at this assessment and documented blocker.

## Sources inspected

- **R1:** De Jaeger,Gonçalves,Protopapadaki,Saelens, KU Leuven, *Building Energy
  Simulation Validation Study*,26Sep2019: [Report_v2.pdf](https://github.com/gmor/annex71_st2_common_exercices/blob/ae7614bed0d7e5f5e73b3d52e6bcec8efe5f85f9/docu/Report_v2.pdf).
- **R2:** [Measurement Channel List.xlsx](https://github.com/gmor/annex71_st2_common_exercices/blob/ae7614bed0d7e5f5e73b3d52e6bcec8efe5f85f9/docu/Measurement%20Channel%20List.xlsx).
- **R3:** [DescrptionR1.pdf](https://github.com/gmor/annex71_st2_common_exercices/blob/ae7614bed0d7e5f5e73b3d52e6bcec8efe5f85f9/docu/DescrptionR1.pdf),
  [README](https://github.com/gmor/annex71_st2_common_exercices/blob/ae7614bed0d7e5f5e73b3d52e6bcec8efe5f85f9/README.md),
  [data listing](https://github.com/gmor/annex71_st2_common_exercices/tree/ae7614bed0d7e5f5e73b3d52e6bcec8efe5f85f9/data).
- **R4:** official [ResStock README](https://github.com/NREL/resstock/blob/33433157aa52d1a97f35b9640bdf7a2c46f5d908/README.md),
  [configuration](https://github.com/NREL/resstock/blob/33433157aa52d1a97f35b9640bdf7a2c46f5d908/project_national/national_baseline.yml),
  [HPXML example](https://github.com/NREL/resstock/blob/33433157aa52d1a97f35b9640bdf7a2c46f5d908/resources/hpxml-measures/workflow/sample_files/base.xml),
  [licence](https://github.com/NREL/resstock/blob/33433157aa52d1a97f35b9640bdf7a2c46f5d908/LICENSE.md).

Immutable links pin inspected sources. Download fingerprints/instructions:
[data/reference_building/README.md](../data/reference_building/README.md).
