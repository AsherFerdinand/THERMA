# First-room data worksheet

Current decision: Germany; EN 12831 heating-load basis requested. No completed room
heat-load calculation has been supplied. Keep unknown values blank and record sources.
This worksheet collects inputs; it does not calculate or certify a DIN heating load.

## 1. Identify one room

- Thesis room ID and floor:
- Location/city (for applicable design climate data):
- Room use:
- Length / width / height (m):
- Desired indoor temperature (°C):
- Drawing or parameter-file reference:

## 2. Describe its boundaries

Fill one row per distinct surface. Use net opaque wall area where windows/doors are
listed separately, avoiding double-counting. Do not guess U-values from appearance.

| Surface | Area (m²) | Adjacent space / outdoors / ground | Construction or verified U-value (W/(m² K)) | Source |
|---|---|---|---|---|
| External wall(s) | | | | |
| Window(s) | | | | |
| Door(s) | | | | |
| Internal wall(s) | | | | |
| Floor | | | | |
| Ceiling / roof | | | | |

Also collect thermal-bridge information, adjacent-space design conditions, ground
boundary information where applicable, and ventilation/infiltration assumptions.
Obtain the applicable DIN EN 12831 edition, German supplementary rules and climate
inputs through the university's approved calculation method; none are assumed here.

## 3. Describe the heating equipment

- Radiator manufacturer/model/type and dimensions:
- Manufacturer heat-output/rating data and rating conditions:
- Intended supply/return temperatures (°C):
- Measured/design water mass flow (kg/s), if available:
- Radiator water volume and metal mass/material, if available:
- Thermostat setpoint, deadband and initial state:

## 4. Inputs needed for the simplified dynamic model

After a checked heating-load calculation, record design indoor/outdoor temperatures,
transmission loss (W), ventilation loss (W), and any reheating allowance separately.
Do not use reheating allowance as continuous envelope heat loss.

Additional dynamic inputs are effective room capacity (J/K), radiator capacity (J/K),
a justified radiator heat-transfer conductance (W/K), water specific heat (J/(kg K)),
initial temperatures and experiment duration. EN 12831 design load alone does not
supply these dynamic properties. A radiator rating alone does not establish constant UA.

The one-room builder uses an equivalent outdoor heat-loss coefficient derived from
checked design losses. This is a simplification, not the full DIN calculation.
See [the builder guide](ROOM_REFERENCE_MODEL.md) for assumptions and missing inputs.

## Next handoff

Start by supplying the room ID, city, dimensions and available construction/radiator
records. We can identify remaining gaps before requesting every technical parameter.
Keep personal addresses and restricted university documents out of public commits.
Original thesis diagnostics remain a separate pending check; no Phase 1B.2 or Python
physics implementation is authorised by completing this worksheet.
