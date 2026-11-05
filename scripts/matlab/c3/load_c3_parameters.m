function P=load_c3_parameters(file)
%LOAD_C3_PARAMETERS Explicit illustrative assumptions, separate from frozen C2.
if nargin<1
    root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
    file=fullfile(root,'configs','c3','illustrative_components.json');
end
raw=jsondecode(fileread(file));
assert(raw.schema_version==1 && strcmp(raw.classification, ...
    'illustrative_assumptions_not_calibrated_not_BOPTEST'), ...
    'THERMA:C3Schema','Expected explicitly illustrative C3 assumptions.');
names={'setpoint_K','deadband_K','controller_period_s','controller_initial', ...
    'opening_tau_s','closing_tau_s','valve_initial','water_mass_kg','water_cp_J_kgK', ...
    'metal_mass_kg','metal_cp_J_kgK','nominal_flow_kg_s','UA_W_K','radiative_fraction', ...
    'radiator_initial_K','room_example_K','supply_example_K'};
units={'K','K','s','1','s','s','1','kg','J/(kg.K)','kg','J/(kg.K)', ...
    'kg/s','W/K','1','K','K','K'};
for j=1:numel(names)
    item=raw.parameters.(names{j});
    assert(strcmp(item.unit,units{j}) && ~isempty(item.source), ...
        'THERMA:C3Provenance','Missing/wrong unit or source for %s.',names{j});
    validateattributes(item.value,{'numeric'},{'real','finite','scalar','nonnegative'});
    P.(names{j})=item.value;
end
positive=setdiff(names,{'controller_initial','valve_initial','radiative_fraction'});
for j=1:numel(positive)
    assert(P.(positive{j})>0,'THERMA:C3Parameter','%s must be positive.',positive{j});
end
assert(ismember(P.controller_initial,[0 1]) && P.valve_initial<=1 && P.radiative_fraction<=1, ...
    'THERMA:C3Parameter','Invalid controller state, valve opening or radiative fraction.');
P.capacitance_J_K=P.water_mass_kg*P.water_cp_J_kgK+P.metal_mass_kg*P.metal_cp_J_kgK;
P.assumptions=raw;
end
