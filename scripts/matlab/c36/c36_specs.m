function S=c36_specs()
%C36_SPECS Static algebra using existing parameter loaders and steady diagnostic.
root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
Z=load_boptest_zone_parameters(string(fullfile(root,'configs','references','c2_reduced_assumptions.json')));
P=load_c3_parameters(); I=load_c34_experiment();
gate=jsondecode(fileread(fullfile(root,'verification','c3','c34_gate','summary.json')));
component=jsondecode(fileread(fullfile(root,'verification','c3','component_gate','summary.json')));
assert(strcmp(boptest_file_sha256(fullfile(root,'configs','c3','illustrative_components.json')),component.assumptions_sha256) && ...
    strcmp(boptest_file_sha256(fullfile(root,'configs','c3','integration_c34.json')),gate.integration_config_sha256) && ...
    strcmp(boptest_file_sha256(fullfile(root,'configs','references','c2_reduced_assumptions.json')), ...
        gate.integration.zone_assumptions_sha256),'THERMA:C36Defaults','Verified baseline parameters were changed.');
hi=Z.assumptions.parameters.h_interior_W_m2K.value;
ho=Z.assumptions.parameters.h_exterior_W_m2K.value;
components=Z.envelope.components; opaque=0;
S=struct('classification','existing_model_static_calculation_not_new_simulation', ...
    'geometry',Z.envelope.geometry,'components',components,'window_U_W_m2K',Z.UA_window_W_K/Z.envelope.geometry.window_m2, ...
    'window_H_W_K',Z.UA_window_W_K,'ventilation_H_W_K',Z.H_vent_W_K, ...
    'air_capacity_J_K',Z.C_air_J_K,'fabric_capacity_J_K',sum([components.C_total_J_K]), ...
    'interior_film_W_m2K',hi,'exterior_film_W_m2K',ho);
U=zeros(1,numel(components));
for k=1:numel(components)
    c=components(k); U(k)=1/(1/hi+c.R_total_K_W*c.area_m2+1/ho);
    if ~c.adiabatic_exterior, opaque=opaque+U(k)*c.area_m2; end
end
S.opaque_film_only_U_W_m2K=U;
S.approximate_H_W_K=opaque+Z.UA_window_W_K+Z.H_vent_W_K;
S.total_capacity_J_K=S.fabric_capacity_J_K+S.air_capacity_J_K;
S.uniform_six_K_storage_kWh=S.total_capacity_J_K*6/3.6e6;
S.radiators=cell(1,2);
for k=1:2
    ua=[60 180]; effective=P; effective.UA_W_K=ua(k);
    steady=c35_steady_diagnostics(Z,effective,I);
    steady.UA_W_K=ua(k);
    H=P.nominal_flow_kg_s*P.water_cp_J_kgK;
    steady.mixed_return_at_air21_degC=(H*55+ua(k)*21)/(H+ua(k));
    S.radiators{k}=steady;
end
S.split_consistent_H_W_K=1/S.radiators{1}.zone_heat_response_K_W;
S.heat_demand_at_21C_outdoor5_W=S.radiators{1}.required_room_heat_at_setpoint_W;
S.nominal_mass_flow_kg_s=P.nominal_flow_kg_s; S.radiator_capacity_J_K=P.capacitance_J_K;
S.registry_sha256=Z.envelope.registry_sha256;
end
