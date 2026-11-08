function [model,file,info]=c38_build_case(folder,deadband,Z,P,room,sourceModel,sourceSignals)
%C38_BUILD_CASE Copy baseline if available; otherwise reuse existing C3.7 recipe.
a=room.conditions; [~,plan]=c35_plan();
I=load_c34_experiment(); I.supply_K=a.supply_C+273.15; I.outdoor_K=a.outdoor_C+273.15;
I.initial_zone_K=a.air_initial_C+273.15; I.initial_radiator_K=a.radiator_initial_C+273.15;
I.duration_s=a.duration_s; I.max_step_s=10; I.setpoint_K=a.setpoint_C+273.15;
I.internal_convective_W=0; I.internal_radiative_W=0; I.solar_W=zeros(1,6);
P.radiator_initial_K=I.initial_radiator_K;
c=struct('id','C38','group','C38','UA_W_K',P.UA_W_K,'supply_K',I.supply_K,'outdoor_K',I.outdoor_K, ...
    'initial_zone_K',I.initial_zone_K,'initial_radiator_K',I.initial_radiator_K, ...
    'max_step_s',10,'solar',false,'purpose','Deadband-only comparison');
model='THERMA_C38_Thermostat'; file=fullfile(folder,[model '.slx']);
assert(~bdIsLoaded(model),'THERMA:C38Open','Save/close the open C3.8 model first.');
if ~isempty(sourceModel)
    copyfile(sourceModel,file); load_system(file);
    try
        workspace=get_param(model,'ModelWorkspace');
        actualP=getVariable(workspace,'C3');
        assert(isequaln(getVariable(workspace,'Z'),Z) && isequaln(getVariable(workspace,'C34'),I) && ...
            isequaln(orderfields(actualP),orderfields(P)), ...
            'THERMA:C38Baseline','Saved baseline workspace differs from current C3.7 parameters.');
        assert(strcmp(get_param(model,'SolverType'),'Variable-step') && strcmp(get_param(model,'Solver'),I.solver.name) && ...
            str2double(get_param(model,'RelTol'))==str2double(I.solver.RelTol) && ...
            str2double(get_param(model,'AbsTol'))==str2double(I.solver.AbsTol) && ...
            str2double(get_param(model,'MaxStep'))==I.max_step_s && ...
            str2double(get_param(model,'StopTime'))==I.duration_s && str2double(get_param(model,'StartTime'))==0 && ...
            strcmp(get_param(model,'LoadInitialState'),'off'), ...
            'THERMA:C38Baseline','Saved baseline solver/initial-state settings differ.');
        info=struct('signals',{sourceSignals},'experiment',I,'case_definition',c);
    catch problem
        close_system(model,0); rethrow(problem);
    end
else
    [original,~,info]=c35_build_case(c,plan,folder,I.duration_s);
    cleanup=onCleanup(@() closeIfLoaded(original));
    workspace=get_param(original,'ModelWorkspace');
    assignin(workspace,'Z',Z); assignin(workspace,'C34',I);
    zone=[original '/Thermal_zone'];
    add_block('simulink/Sources/Constant',[zone '/Adjacent_K'],'Value',num2str(a.adjacent_C+273.15,17));
    for name={'North_Wall','West_Wall'}
        target=['Exterior_Convection_' name{1} '/1'];
        delete_line(zone,'Outdoor_K/1',target); add_line(zone,'Adjacent_K/1',target,'autorouting','on');
    end
    assignin(workspace,'C3',P); save_system(original,file); clear cleanup;
    if ~bdIsLoaded(model), load_system(file); end
end
try
    workspace=get_param(model,'ModelWorkspace'); P.deadband_K=deadband;
    assignin(workspace,'C3',P); save_system(model,file);
    info.experiment=I; info.effective_components=rmfield(P,'assumptions');
catch problem
    close_system(model,0); rethrow(problem);
end
end
function closeIfLoaded(model)
if bdIsLoaded(model), close_system(model,0); end
end
