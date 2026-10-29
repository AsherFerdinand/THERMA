# C2/BOPTEST signal compatibility

Absolute original model seconds; replay solver time is shifted explicitly. Phase B post-communication samples every 30 s.

Compatibility describes physical quantities, not matched forcing, initial states or validated accuracy.

| Quantity | BOPTEST | THERMA | Unit | Category | Reason |
|---|---|---|---|---|---|
| air_temperature | mod.case900Template.TAir | T_air_K | K | directly_comparable | Same air-temperature quantity; matched forcing/initialization still required. |
| operative_temperature | reaTRoo_y | not implemented | K | missing | C2 has no operative-temperature output. |
| radiative_temperature | mod.case900Template.TRad | T_opaque_mean_K | K | proxy_only | Opaque area mean omits glazing/view factors; not source TRad. |
| outdoor_temperature | weaSta_reaWeaTDryBul_y | Inputs[1] | K | directly_comparable | Boundary replay signal, not a model-accuracy measurement. |
| delivered_heating_convective_power | mod.rad.QCon_flow | Inputs[2] | W | comparable_after_transformation | Negate source port sign; prescribed forcing, not equipment prediction. |
| delivered_heating_radiative_power | mod.rad.QRad_flow | Inputs[3] | W | comparable_after_transformation | Negate source port sign; reduced radiant distribution remains different. |
| internal_convective_power | mod.case900Template.intGaiOcc.portCon.Q_flow | Inputs[4] | W | comparable_after_transformation | Negate port sign. |
| internal_radiative_power | mod.case900Template.intGaiOcc.portRad.Q_flow | Inputs[5] | W | comparable_after_transformation | Negate port sign; no latent heat equivalence. |
| gas_input_power | reaQHea_y | not implemented | W | not_comparable | C2 has no boiler fuel model; delivered thermal heat is a different commodity. |
| pump_electrical_power | reaPPum_y | not implemented | W | not_comparable | C2 has no electrical pump model. |
| absorbed_solar_power | not exported | Inputs[6:11] | W | missing | Reference exports irradiance, not six absorbed interior powers. |
| ventilation_power | not exported | q_vent_W | W | missing | Leakage mass flow available, but source moist-air enthalpy flow not exported. |
| fabric_temperatures | not exported | T_states_K[1:27] | K | missing | Full reference fabric state vector not exported. |
| stored_thermal_energy | not exported | E_J | J | missing | No equivalent total reference storage output; C2 storage boundary differs. |

The machine-readable authority is [c2_signal_compatibility.json](../configs/references/c2_signal_compatibility.json).
Inventory periods and exact provenance are in [c2_reference_inventory.json](../configs/references/c2_reference_inventory.json).

Typical: warm-up days 327–334, evaluate 334–348. Peak: warm-up 304–311, evaluate 311–325.
Both trajectories have 60,481 samples over 21 days, with 40,321 evaluation samples over 14 days, at 30 s output spacing.
The original embedded solver is adaptive; 30 s is not its integration step.
Selected initialization snapshots include air/radiative temperatures 293.15 K and five radiator water nodes at 293.15 K;
they do not supply every fabric/moisture state. Brussels.mos remains the active weather.
Heating/internal port powers must be negated for delivered gains. Gas and pump electricity stay separate commodities.
The reference has 39 public I/O and 21 selected internal variables, plus time.
No full reference storage, six absorbed solar powers or source-consistent C2 restart vector was exported.
