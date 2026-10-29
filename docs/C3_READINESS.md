# C3 hydronic integration contract and gates

No hydronic network is implemented in this sprint. The reduced C2 thermal zone is
prepared for local verification; it is not yet reference-exact or MATLAB-verified.

## Delivered heating interface

C2 receives **delivered** convective and radiative powers separately in W, at the
same model timestamps as other forcing. Positive values add room heat. The sum is
the thermal energy leaving the future radiator into this zone. A driver may instead
start with total delivered power and explicit fractions that sum to one, but it must
not also inject those fractions a second time. Do not use `reaQHea_y` gas input as
room heat. Reference radiator radiation fraction 0.35 is an extracted parameter for
the future radiator; C2 does not impose it on arbitrary external heating inputs.

Zone feedback to the radiator: air temperature and, eventually, a verified radiative
environment temperature. Current `T_opaque_mean_K` is a reduced diagnostic; it must
not silently replace reference radiative temperature for exact reconstruction.

Heating availability belongs to equipment/controller logic: unavailable means its
delivered powers are zero. Supply/return temperatures, water mass flow, pressure and
valve position are **future equipment variables**, not temperatures to inject into
C2 air. Interface records must include time_s, W/K/kg/s units, scenario/source hashes,
interpolation and sign. Fractional splits must be explicit and conservative.

## Future equipment relationships

```text
boiler -> pump -> supply distribution -> radiators -> return distribution -> boiler
                                 valves set branch flow
radiators -> delivered convective power -> zone air
radiators -> delivered radiative power -> surface/radiation network
zone temperatures -> thermostatic/supervisory controller -> equipment commands
```

Equipment stores water/metal energy and must balance enthalpy in/out with delivered
heat. Pump electric power and boiler fuel input remain separate commodities.
The selected BOPTEST testcase does not contain separate valve/pipe geometries;
do not invent them to fill this diagram. The original 36-room thesis remains a
separate later expansion, requiring its own source inventory and parameters.

## Gates before C3 implementation

- [ ] Archive full local C1 R2025a verification report and exact source version.
- [ ] Generate/compile C2 and run every scenario locally; inspect partial failures.
- [ ] Pass storage, energy balance, sign, radiation cancellation and refinement checks.
- [ ] Decide whether to retain reduced C2 or implement reference-exact moist-air,
  nonlinear exchange, glazing/solar, sky radiation and initialization.
- [ ] Establish a verified radiation-environment feedback quantity.
- [ ] Match recorded forcing, full warm-up and state ownership for reference replay.
- [ ] Review sampling/interpolation and define scientifically justified accuracy criteria.
- [ ] Demonstrate reference comparison with compatible physical quantities and versions.
- [x] Define separate delivered convective/radiative power interfaces.
- [x] Keep source/outputs separate and preserve frozen reference identity.

Next concrete task: run the documented MATLAB C2 suite, return its report and fix any
actual block/API/numerical failures before adding heating equipment complexity.
