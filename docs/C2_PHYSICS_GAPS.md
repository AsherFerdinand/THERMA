# C2.6 priorities before hydronic integration

Rankings below are qualitative engineering judgments, not measured error attribution.
No numerical temperature/energy impact estimate is claimed. C2 verification proves
consistency of the reduced equations, not physical equivalence to BESTEST Hydronic.
Frozen source citations and parameter availability remain in BOPTEST_REFERENCE.md.

| Gap | Significance / expected effect | Complexity / verification | Data availability | C3 relevance |
|---|---|---|---|---|
| Six absorbed solar powers and exterior solar/sky forcing | High for daytime temperature and net energy; omission prevents matched replay | Medium extraction, high optical reconstruction; verify per-surface energy sums | Irradiance exists; absorbed powers not exported | High: radiator demand cannot be attributed without forcing |
| Complete initial fabric/moist-air state | High for startup/storage error; warm-up sensitivity unresolved | Medium extraction, conservation/restart tests | Selected snapshots only | High for reproducibility |
| Dynamic glazing and optics | High for solar response and window storage; static rating U is an intentional simplification | High; layer storage, optics and steady ratings independently testable | Source optical/material tables extracted | High for envelope demand |
| Nonlinear interior convection | Potentially important surface/air split; fixed h is provisional | Medium; reference correlations and sign/limit tests | Source flags/correlations, not a calibrated constant h | High for emitter/air coupling |
| Wind-dependent exterior convection and sky longwave | Potentially important outdoor losses and nighttime cooling | Medium/high; weather geometry and radiation balance tests | Wind/sky weather exported, algorithms not ported | Medium/high |
| Surface view factors and radiative environment | Changes surface distribution and radiator radiative feedback; area mean is only a proxy | High; reciprocity, closure and exchange tests | Source algorithms available, exact mapping still needed | Critical before exact radiator coupling |
| Moist-air cp/density, humidity, latent heat and CO2 | Changes storage and air enthalpy; dry constant properties intentionally simplify it | High coupling; medium-property and enthalpy conservation tests | Humidity/weather/latent source partly exported, not full state | Medium/high |
| Internal gain timing and radiant split | Sensible source powers can be replayed; latent path remains absent | Low replay, medium exact occupant coupling | Sensible split and occupancy available | Medium |
| Leakage/ventilation enthalpy | Sensible fixed-flow path is intentionally simplified; mass-flow default alone is not moist-air enthalpy | Medium; mass/energy balance tests | Leakage 0.0216 kg/s initialized, full enthalpy flow absent | Medium |
| Heating equipment and radiator dynamics | Intentionally prescribed in isolated-zone replay, not predictions | High C3 scope; water/metal/commodity energy tests | Nominal/source equations known; missing pipe/valve geometry must not be invented | Deferred C3 |
| Operative temperature | Missing output; air is not operative and opaque mean is not source TRad | Medium once radiative environment/glazing verified | Source TAir, TRad and reaTRoo available | High for proper reference/controller comparison |

Recommended C2.6 order: (1) export missing absorbed forcing and full initial state or
establish an explicitly tested warm-up policy; (2) implement/test glazing/solar and
exterior exchange; (3) verify radiative environment/view factors and nonlinear interior
exchange; (4) resolve moist-air storage/latent assumptions for reference equivalence.
Run matched open-loop weather and split heating/gain replay before changing hydronic
feedback. Keep provisional assumptions explicit and compare input reconstruction
sensitivity separately from model error. Do not tune coefficients solely to hide
missing forcing. C3 should remain pending until emitter feedback and demand estimates
have a defensible reference boundary.
