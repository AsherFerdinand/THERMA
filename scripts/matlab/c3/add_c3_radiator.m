function add_c3_radiator(parent)
%ADD_C3_RADIATOR Well-mixed water+metal storage, signed linear heat transfer.
% Air is the explicit radiative-sink proxy at this isolated component stage.
add_block('simulink/Ports & Subsystems/Subsystem',parent); Simulink.SubSystem.deleteContents(parent);
b=@(name,lib,pos,varargin) c3_block(parent,name,lib,pos,varargin{:});
b('Valve','Sources/In1',[20 35 50 55],'Port','1');
b('Supply_K','Sources/In1',[20 115 50 135],'Port','2');
b('Air_K','Sources/In1',[20 300 50 320],'Port','3');
b('Bound_opening','Discontinuities/Saturation',[80 25 140 65],'LowerLimit','0','UpperLimit','1');
b('Mass_flow_kg_s','Math Operations/Gain',[180 25 275 65],'Gain','C3.nominal_flow_kg_s');
b('Supply_minus_radiator_K','Math Operations/Sum',[175 105 210 145],'Inputs','+-');
b('Water_cp_J_kgK','Math Operations/Gain',[250 105 340 145],'Gain','C3.water_cp_J_kgK');
b('Water_power_W','Math Operations/Product',[385 60 430 105],'Inputs','**');
b('Radiator_K','Continuous/Integrator',[630 165 685 205],'InitialCondition','C3.radiator_initial_K');
b('Radiator_minus_air_K','Math Operations/Sum',[170 285 205 325],'Inputs','+-');
b('Conductance_W_K','Math Operations/Gain',[250 275 345 315],'Gain','C3.UA_W_K');
b('Convective_W','Math Operations/Gain',[390 245 485 280],'Gain','1-C3.radiative_fraction');
b('Radiative_W','Math Operations/Gain',[390 325 485 360],'Gain','C3.radiative_fraction');
b('Delivered_W','Math Operations/Sum',[530 285 560 325],'Inputs','++');
b('Storage_power_W','Math Operations/Sum',[475 155 510 195],'Inputs','+-');
b('Inverse_capacitance_K_J','Math Operations/Gain',[535 150 610 200],'Gain','1/C3.capacitance_J_K');
b('Delivered_energy_J','Continuous/Integrator',[625 285 690 325],'InitialCondition','0');
b('Water_energy_J','Continuous/Integrator',[475 30 540 70],'InitialCondition','0');
b('Initial_K','Sources/Constant',[640 385 710 415],'Value','C3.radiator_initial_K');
b('Temperature_change_K','Math Operations/Sum',[735 360 770 400],'Inputs','+-');
b('Stored_energy_change_J','Math Operations/Gain',[800 350 895 395],'Gain','C3.capacitance_J_K');
b('Capacitance_J_K','Math Operations/Gain',[730 175 820 215],'Gain','C3.capacitance_J_K');
b('Balance_residual_W','Math Operations/Sum',[865 170 900 210],'Inputs','+-');
sources={'Radiator_K','Convective_W','Radiative_W','Delivered_W','Mass_flow_kg_s', ...
    'Water_power_W','Delivered_energy_J','Water_energy_J','Stored_energy_change_J','Balance_residual_W'};
for j=1:numel(sources)
    b([sources{j} '_out'],'Sinks/Out1',[1020 20+50*j 1050 40+50*j], ...
        'Port',num2str(j));
end
w=@(a,z) add_line(parent,a,z,'autorouting','on');
w('Valve/1','Bound_opening/1'); w('Bound_opening/1','Mass_flow_kg_s/1');
w('Supply_K/1','Supply_minus_radiator_K/1'); w('Radiator_K/1','Supply_minus_radiator_K/2');
w('Supply_minus_radiator_K/1','Water_cp_J_kgK/1'); w('Water_cp_J_kgK/1','Water_power_W/1');
w('Mass_flow_kg_s/1','Water_power_W/2'); w('Radiator_K/1','Radiator_minus_air_K/1');
w('Air_K/1','Radiator_minus_air_K/2'); w('Radiator_minus_air_K/1','Conductance_W_K/1');
w('Conductance_W_K/1','Convective_W/1'); w('Conductance_W_K/1','Radiative_W/1');
w('Convective_W/1','Delivered_W/1'); w('Radiative_W/1','Delivered_W/2');
w('Water_power_W/1','Storage_power_W/1'); w('Delivered_W/1','Storage_power_W/2');
w('Storage_power_W/1','Inverse_capacitance_K_J/1'); w('Inverse_capacitance_K_J/1','Radiator_K/1');
w('Water_power_W/1','Water_energy_J/1'); w('Delivered_W/1','Delivered_energy_J/1');
w('Radiator_K/1','Temperature_change_K/1'); w('Initial_K/1','Temperature_change_K/2');
w('Temperature_change_K/1','Stored_energy_change_J/1');
w('Inverse_capacitance_K_J/1','Capacitance_J_K/1'); w('Capacitance_J_K/1','Balance_residual_W/1');
w('Storage_power_W/1','Balance_residual_W/2');
for j=1:numel(sources), w([sources{j} '/1'],[sources{j} '_out/1']); end
end
