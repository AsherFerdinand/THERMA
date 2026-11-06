function S=c37_steady_demand(Z,P,room)
%C37_STEADY_DEMAND Reuse C2 static network; apply the two adjacent boundaries.
[A,B,capacities]=boptest_zone_analytical_network(Z);
a=room.conditions; f=B(:,1)*(a.outdoor_C+273.15); first=1;
for face=1:6
    % Original diagnostic uses common outdoor input; correct just the two partitions.
    if ismember(face,[2 4])
        f(first)=f(first)+Z.H_exterior_W_K(face)/capacities(first)*(a.adjacent_C-a.outdoor_C);
    end
    first=first+Z.envelope.components(face).n_states;
end
b=(1-P.radiative_fraction)*B(:,2)+P.radiative_fraction*B(:,3);
free=-(A\f); response=-(A\b);
required=(a.setpoint_C+273.15-free(end))/response(end);
H=P.nominal_flow_kg_s*P.water_cp_J_kgK; effective=H*P.UA_W_K/(H+P.UA_W_K);
available=effective*(a.supply_C-a.setpoint_C);
S=struct('classification','static_existing_network_calculation_not_simulation', ...
    'required_heat_at_setpoint_W',required,'available_heat_at_setpoint_W',available, ...
    'capacity_margin_W',available-required,'steady_capacity_sufficient',available>=required, ...
    'approximate_outdoor_H_W_K',Z.approximate_outdoor_H_W_K, ...
    'boundary_note','Outdoor0C, adjacent21C, ceiling/floor adiabatic, zero gains; existing65/35 split');
end
