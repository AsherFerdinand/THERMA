function p = room_heating_parameters()
%ROOM_HEATING_PARAMETERS Fill with documented values before building the model.
% NaN deliberately prevents invented physical parameters from becoming defaults.
% Use SI units; convert degrees Celsius by adding 273.15.
p.provenance = "";                 % Sources for capacities, radiator, water and flow.
p.standard_reference = "";         % Exact EN 12831 edition used by your calculation.
p.national_rules = "";             % Country and applicable national supplement.
p.load_calculation_reference = ""; % Reference to your checked room-load calculation.
p.design_indoor_K = NaN;
p.design_outdoor_K = NaN;
p.design_transmission_loss_W = NaN; % From the external EN 12831 calculation.
p.design_ventilation_loss_W = NaN;  % From that calculation; exclude reheating power.
p.room_capacity_J_K = NaN;          % Effective room capacity (air + justified fabric).
% Builder derives an equivalent loss conductance from the design losses above.
p.radiator_capacity_J_K = NaN;      % Lumped water + metal thermal capacity.
p.radiator_UA_W_K = NaN;            % Linear water-to-room heat-transfer conductance.
p.water_cp_J_kg_K = NaN;            % Constant water specific heat over chosen range.
p.open_flow_kg_s = NaN;             % Prescribed mass flow with ideal valve open.
p.initial_room_K = NaN;
p.initial_radiator_K = NaN;
p.outdoor_K = NaN;
p.supply_K = NaN;
p.setpoint_K = NaN;
p.thermostat_deadband_K = NaN;       % Full band: opens/closes at setpoint +/- band/2.
% Numerical starting settings, not physical parameters or verified convergence:
p.duration_s = 3600;
p.max_step_s = 1;
p.relative_tolerance = 1e-6;
p.absolute_tolerance_K = 1e-8;
end
