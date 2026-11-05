function [model,file,info]=build_c34_model(I,outputParent)
%BUILD_C34_MODEL Copy unchanged C2 topology; substitute independent heat ports only.
if nargin<1, I=load_c34_experiment(); end
root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
if nargin<2, outputParent=fullfile(root,'outputs','c3','integration'); end
P=load_c3_parameters(); P.radiator_initial_K=I.initial_radiator_K;
assert(I.max_step_s<=P.controller_period_s,'THERMA:C34Step','Max step exceeds controller period.');
model='THERMA_C34_ClosedLoop';
assert(~bdIsLoaded(model) && ~bdIsLoaded('THERMA_BOPTEST_ThermalZone_C2'), ...
    'THERMA:C34OpenModel','Save/close the open C2/C3.4 model before generating a new copy.');
assumptions=fullfile(root,'configs','references','c2_reduced_assumptions.json');
[original,originalFile,Z]=build_boptest_zone_c2(string(assumptions),'ShowModel',false);
originalHash=boptest_file_sha256(originalFile);
sourceCleanup=onCleanup(@() closeOriginal(original));
if ~isfolder(outputParent), mkdir(outputParent); end
folder=tempname(outputParent); mkdir(folder); file=fullfile(folder,[model '.slx']);
new_system(model);
try
    add_block('built-in/Subsystem',[model '/Thermal_zone'],'Position',[750 40 990 570]);
    Simulink.SubSystem.deleteContents([model '/Thermal_zone']);
    Simulink.BlockDiagram.copyContentsToSubSystem(original,[model '/Thermal_zone']);
    % Initial conditions only: material/reference data and C2 equations stay unchanged.
    Z.initial_K=I.initial_zone_K;
    for k=1:numel(Z.envelope.components)
        Z.envelope.components(k).initial_K(:)=I.initial_zone_K;
    end
    workspace=get_param(model,'ModelWorkspace');
    assignin(workspace,'Z',Z); assignin(workspace,'C3',P); assignin(workspace,'C34',I);
    set_param(model,'SolverType','Variable-step','Solver',I.solver.name,'RelTol',I.solver.RelTol, ...
        'AbsTol',I.solver.AbsTol,'MaxStep',num2str(I.max_step_s,17),'StopTime',num2str(I.duration_s,17), ...
        'ReturnWorkspaceOutputs','on','SignalInfNanChecking','error','AlgebraicLoopMsg','error');
    Simulink.Annotation(model,['C3.4 illustrative closed loop; prescribed water supply/flow map, ' ...
        'air used as radiant-sink proxy. Not BOPTEST/system validation.']);
    add_c3_thermostat([model '/Thermostat']); set_param([model '/Thermostat'],'Position',[100 50 300 165]);
    add_c3_valve([model '/Valve']); set_param([model '/Valve'],'Position',[350 60 500 140]);
    add_c3_radiator([model '/Radiator']); set_param([model '/Radiator'],'Position',[545 180 720 530]);
    b=@(name,lib,pos,varargin) c3_block(model,name,lib,pos,varargin{:});
    b('Setpoint_K','Sources/Constant',[20 20 95 45],'Value','C34.setpoint_K');
    b('Supply_K','Sources/Constant',[360 190 440 220],'Value','C34.supply_K');
    if isempty(I.disable_at_s)
        b('Enable','Sources/Constant',[20 220 95 245],'Value','double(C34.heating_enabled)');
    else
        b('Enable','Sources/Step',[20 220 95 245],'Time','C34.disable_at_s', ...
            'Before','double(C34.heating_enabled)','After','0');
    end
    b('Outdoor_K','Sources/Constant',[390 610 480 635],'Value','C34.outdoor_K');
    b('Internal_convective_W','Sources/Constant',[390 670 500 695],'Value','C34.internal_convective_W');
    b('Internal_radiative_W','Sources/Constant',[390 730 500 755],'Value','C34.internal_radiative_W');
    b('Solar_W','Sources/Constant',[390 790 500 815],'Value','C34.solar_W');
    b('Zone_inputs','Signal Routing/Mux',[660 590 665 820],'Inputs','6');
    w=@(a,z) add_line(model,a,z,'autorouting','on');
    w('Setpoint_K/1','Thermostat/1'); w('Thermal_zone/1','Thermostat/2'); w('Enable/1','Thermostat/3');
    w('Thermostat/1','Valve/1'); w('Valve/1','Radiator/1');
    w('Supply_K/1','Radiator/2'); w('Thermal_zone/1','Radiator/3');
    % Mux width 11: Tout, independent Qconv/Qrad, internal gains, six solar gains.
    w('Outdoor_K/1','Zone_inputs/1'); w('Radiator/2','Zone_inputs/2'); w('Radiator/3','Zone_inputs/3');
    w('Internal_convective_W/1','Zone_inputs/4'); w('Internal_radiative_W/1','Zone_inputs/5');
    w('Solar_W/1','Zone_inputs/6'); w('Zone_inputs/1','Thermal_zone/1');
    % Shared exchange cancels from the combined zone+radiator external balance.
    b('Environmental_power_W','Math Operations/Sum',[1050 600 1100 690],'Inputs','+++++');
    ports=[4 6 7 9 10];
    for k=1:5, w(sprintf('Thermal_zone/%d',ports(k)),sprintf('Environmental_power_W/%d',k)); end
    b('Combined_external_W','Math Operations/Sum',[1160 600 1200 650],'Inputs','++');
    w('Environmental_power_W/1','Combined_external_W/1'); w('Radiator/6','Combined_external_W/2');
    b('External_energy_J','Continuous/Integrator',[1260 610 1340 650],'InitialCondition','0');
    w('Combined_external_W/1','External_energy_J/1');
    b('Radiator_net_W','Math Operations/Sum',[1050 740 1100 785],'Inputs','+-');
    w('Radiator/6','Radiator_net_W/1'); w('Radiator/4','Radiator_net_W/2');
    b('Combined_storage_rate_W','Math Operations/Sum',[1160 740 1220 785],'Inputs','++');
    w('Thermal_zone/12','Combined_storage_rate_W/1'); w('Radiator_net_W/1','Combined_storage_rate_W/2');
    b('Combined_residual_W','Math Operations/Sum',[1270 740 1320 785],'Inputs','+-');
    w('Combined_storage_rate_W/1','Combined_residual_W/1'); w('Combined_external_W/1','Combined_residual_W/2');
    sources={'Thermal_zone/1','Setpoint_K/1','Thermostat/1','Valve/1', ...
        'Radiator/1','Radiator/2','Radiator/3','Radiator/4','Radiator/5','Radiator/6', ...
        'Radiator/7','Radiator/8','Radiator/9','Radiator/10', ...
        'Thermal_zone/11','Thermal_zone/12','Thermal_zone/13','Thermal_zone/14','Thermal_zone/8', ...
        'Environmental_power_W/1','Combined_external_W/1','External_energy_J/1', ...
        'Combined_storage_rate_W/1','Combined_residual_W/1','Thermal_zone/16'};
    names={'air_K','setpoint_K','demand','opening','radiator_K','convective_W','radiative_W', ...
        'delivered_W','mass_flow_kg_s','water_W','delivered_J','water_J','radiator_stored_J', ...
        'radiator_residual_W','zone_stored_J','zone_storage_rate_W','zone_net_W','zone_residual_W', ...
        'zone_heating_W','environment_W','combined_external_W','external_J', ...
        'combined_storage_rate_W','combined_residual_W','opaque_mean_K'};
    b('Diagnostics','Signal Routing/Mux',[1430 40 1435 780],'Inputs',num2str(numel(sources)));
    for k=1:numel(sources), w(sources{k},sprintf('Diagnostics/%d',k)); end
    b('Log_C34','Sinks/To Workspace',[1530 70 1660 115],'VariableName','c34_signals', ...
        'SaveFormat','Timeseries','MaxDataPoints','inf','Decimation','1');
    w('Diagnostics/1','Log_C34/1');
    for port=[2 3 5 15 17]
        name=sprintf('Unused_zone_%d',port); b(name,'Sinks/Terminator',[1040 30+port*25 1060 50+port*25]);
        w(sprintf('Thermal_zone/%d',port),[name '/1']);
    end
    info=struct('signals',{names},'effective_components',rmfield(P,'assumptions'), ...
        'experiment',I,'frozen_registry_sha256',Z.envelope.registry_sha256, ...
        'zone_assumptions_sha256',Z.assumptions_sha256,'generated_C2_source_slx_sha256',originalHash, ...
        'C2_source_file_preserved',strcmp(originalHash,boptest_file_sha256(originalFile)), ...
        'status','generated_not_MATLAB_verified','radiative_sink','air_temperature_proxy');
    assert(info.C2_source_file_preserved,'THERMA:C34Preservation','Original generated C2 file changed.');
    save_system(model,file); write_boptest_json(fullfile(folder,'integration_build.json'),info);
catch problem
    close_system(model,0); rethrow(problem);
end
end
function closeOriginal(model)
if bdIsLoaded(model), close_system(model,0); end
end
