# C3.7 — Illustrative residential room

**Implementation ready for university MATLAB R2025a; native execution pending.**
The supplied Purmo operating point is now configured. No heating time, energy
or successful native verification is claimed before that run.

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

## Selected radiator and single-point match

**Purmo Compact Type 22, F062206010010P00**,600×1000×102mm. The user supplied
**864W at55/45/20°C**,6.6L water and listed mass31.356kg from the
[manufacturer page](https://www.purmo.com/de-de/produkte/14357/compact/?itempage=28).
The [archived specification](../verification/c3/c37/purmo_user_supplied_specification.json)
is explicitly a **user-supplied transcription**, hashed in the
[rating config](../configs/c37/radiator_rating.json). The page still returned
HTTP403 here; no manufacturer HTML or independently checked datasheet is claimed.

The existing model uses `Qwater=flow*cp*(Ts−Tr)` and `Qroom=UA*(Tr−Ta)` at
steady state, where the mixed radiator temperature equals its outlet/return.
Thus, at the one rated point:

| Quantity | Value and basis |
|---|---|
| Water flow |`864/[4180*(55−45)]`=**0.020670kg/s**,74.411kg/h|
| Effective linear UA |`864/(45−20)`=**34.56W/K**|
| Manufacturer rating at20°C room |**864W**, supplied catalogue point|
| Model prediction at21°C room /55°C supply |**839.31W**, full opening, same flow|
| Room steady demand at21°C /0°C |**339.27W**, existing network with21°C adjacent rooms and65/35 heat split|
| Static capacity margin |**500.05W**; sufficient to maintain21°C under these assumptions|

The339.27W calculation reuses the existing C2 static nodal diagnostic, correcting
the two partition boundaries to21°C; the simpler outdoor-only estimate is328W.
This is static algebra, not a simulation or a design-standard calculation.
The emitter is sufficient at steady state; this does not establish the first
21°C crossing time or guarantee identical real-room behavior.

**Water/metal storage uncertainty:** the supplied listing does not state whether
31.356kg includes water, and the inaccessible page prevents resolving that here.
For this one illustrative run, assume the listed mass includes the6.6L water:
water density1kg/L gives6.6kg water and **24.756kg effective metal**. Retain
existing metal cp500J/(kgK), an effective steel approximation including uncertain
fittings, and water cp4180J/(kgK). Total capacitance is **39,966J/K**. This is
an explicitly chosen interpretation, **not a manufacturer dry-mass statement**.
If31.356kg is instead dry mass, the corresponding capacitance is43,266J/K.
These are two interpretations, not certified bounds on every possible accessory
or packaging convention. Their full-open fixed-room radiator time constants are
5.51/5.96min; no extra dynamic experiment or sensitivity sweep was run.

Only this rated steady operating point is matched. Linear UA, uniform water/metal
temperature, imposed flow/supply,35% radiant fraction and air-as-radiant-sink remain
approximations. No manufacturer validation of dynamics, other temperatures or
thermostat behavior is implied. Existing1K thermostat hysteresis and60/90s valve
opening/closing time constants are unchanged. No pressure network, boiler, heat
pump, nonlinear emitter, thermal bridges or humidity model is added.

## Execution and interpretation

Extract the update directly into the existing `THERMA_C35_MATLAB` folder,
replacing the C3.7 preparation files if present. No internet is needed.
MATLAB R2025a, from that folder:

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

No actual C3.7 simulation result is available. Run the entry point on the
university PC, then supply `residential_result.json` and `residential_trajectory.csv`
from its printed output directory. The two static MATLAB tests and full24h run
remain unexecuted here. C3.7 native verification is pending; C3.8 has not started.
