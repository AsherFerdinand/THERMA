# C3.7 — Illustrative residential room

**Prepared, not executed. Radiator selection is blocked pending a verified
manufacturer datasheet.** No room temperature/heating-energy result or successful
MATLAB verification is claimed. Manufacturer/search websites returned HTTP403
from this environment; no catalogue rating was substituted from memory.

## Room and boundaries

A separate **5×4×2.5m room:20m²,50m³**, modeled as a corner room on an
intermediate apartment floor. South opaque wall10.5m² plus2m² glazing and east
wall10m² face0°C outdoors. North12.5m² and west10m² partitions face rooms held
at21°C. Ceiling/floor20m² each have zero exterior heat flux, approximating
symmetry with similarly operated rooms above/below. They do not face outdoors
or ground. This approximation omits inter-storey exchange during unequal warm-up.

All following construction properties are **illustrative assumptions**, not a
surveyed German dwelling or a DIN EN12831/EN442 compliance calculation. Values
and units are explicit in [the new room config](../configs/c37/residential_room.json).
No BESTEST material was scaled by floor area.

| Construction, outside/adjacent → inside | Thickness; conductivity; density; specific heat |
|---|---|
| External render |15mm;0.70W/(mK);1600kg/m³;840J/(kgK)|
| External mineral wool |100mm;0.035;40;840|
| External lightweight masonry |175mm;0.18;600;840; interior plaster omitted|
| Partitions |12.5mm plaster /100mm lightweight masonry /12.5mm plaster|
| Partition properties |Plaster0.25;900;1000. Masonry0.35;800;840|
| Ceiling |80mm concrete plus12.5mm plaster; concrete split into two40mm layers to retain existing topology|
| Floor |80mm concrete plus20mm finish|
| Slab/finish properties |Concrete1.7;2300;880. Finish0.7;1600;840|
| Glazing / ventilation |U=1.2W/(m²K);0.5ACH=0.00694m³/s|

Slabs represent each room's half of a160mm shared slab, with symmetry at the
mid-plane. Fixed film assumptions remain inside3/outside15W/(m²K), radiant
exchange4W/(m²K), air density1.2kg/m³ and cp1006J/(kgK), inherited explicitly
from C2. Adjacent partition faces use the indoor film3W/(m²K).
Approximate external wall U=**0.235W/(m²K)**; outdoor loss H≈**15.61W/K**,
so simple HΔT at21/0°C is **328W**. That excludes net partition exchange and
surface/radiant redistribution; it is not a full design heat-load calculation.
Adjacent rooms can supply heat during warm-up, and their energy is included in
the existing external-energy balance. Lower outdoor exposure, new insulation and
warm initial fabric are separate scenario choices: any shorter heating time cannot
be attributed to radiator sizing alone.

Air and radiator start15°C; fabric20°C. This represents idealized reheating
with warm walls, not a fully cold-soaked room or a simulated preceding cooling
history. Setpoint21°C, supply55°C, duration24h; zero solar/internal gains.
The construction uses the existing multilayer C2 nodes and linear exchanges.

## Radiator: evidence still needed

No manufacturer/product/output has been verified. The empty
[rating file](../configs/c37/radiator_rating.json) deliberately blocks execution
before model construction. Please supply one manufacturer table at55°C supply
(e.g.55/45/20°C), identifying model, size, output, return/room temperatures and
source/table location. An archived document is hashed, and its relative path,
SHA256 and citation are recorded in that file after review. A merely illustrative
number or a retailer's unsupported conversion is insufficient.

For a documented operating point Qrated, Ts, Tr, Ta, the **existing** mixed-radiator
model is matched using `flow=Qrated/[cp*(Ts−Tr)]` and `UA=Qrated/(Tr−Ta)`.
Its lump temperature equals its outlet/return at steady state. This matches
one catalogue point; it does not reproduce a real panel's distributed water
profile or nonlinear rating curve. The model's output at21°C air is calculated
separately; it is not labeled a manufacturer's21°C rating.

Thermostat hysteresis, valve dynamics,3kg water/20kg metal storage and35% radiant
fraction are retained as existing illustrative assumptions, not product facts.
Radiation still uses air as a sink proxy. No pressure-network, boiler, heat pump,
new controller or nonlinear emitter model is introduced.

## Execution and interpretation

After a manufacturer source is supplied and the rating config reviewed, extract
the small update into the existing `THERMA_C35_MATLAB` folder. MATLAB R2025a:

```matlab
results = runtests(fullfile('tests','matlab','test_therma_c37.m'));
assertSuccess(results);
run_c37_residential_heating
```

One new generated C3.7 model uses the unchanged C3.4/C3.5 builders/components;
only its workspace parameters and adjacent-room boundary sources differ. One
24h simulation is requested, no sweep. Existing native-energy, sampled hysteresis
and analytic valve checks are reused. The actual radiator constitutive equation,
finite states and previous source/config hashes are checked. Failure writes a
nested diagnostic; it is not marked as a passed run. Reaching21°C is not a pass
condition: failure to reach it will be reported without resizing the radiator.

Only two PNG plots are generated: room/setpoint/first crossing; radiator heat and
thermostat demand. Native delivered energy, first21°C time, final temperature
and checks are saved under `outputs/c3/c37/` and summarized below after successful
execution. No cloud MATLAB execution or real-world validation is claimed.
C3.8 has not started.

<!-- C37_RESULTS -->

No actual C3.7 simulation result is available. Awaiting manufacturer evidence,
then university MATLAB execution. This phase is not complete.
