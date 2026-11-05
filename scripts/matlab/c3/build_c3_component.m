function [model,file,signals]=build_c3_component(kind,P,outputParent)
%BUILD_C3_COMPONENT Generate one isolated native-Simulink component, not a C2 loop.
if nargin<2, P=load_c3_parameters(); end
root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
if nargin<3, outputParent=fullfile(root,'outputs','c3','components'); end
kind=char(kind);
switch kind
    case 'thermostat'
        inputs={'Setpoint_K','Air_K','Enable'}; signals={'demand'};
        builder=@add_c3_thermostat;
    case 'valve'
        inputs={'Demand'}; signals={'opening'}; builder=@add_c3_valve;
    case 'radiator'
        inputs={'Valve','Supply_K','Air_K'};
        signals={'radiator_K','convective_W','radiative_W','delivered_W','mass_flow_kg_s', ...
            'water_W','delivered_J','water_J','stored_change_J','balance_residual_W'};
        builder=@add_c3_radiator;
    otherwise
        error('THERMA:C3Component','Expected thermostat, valve or radiator.');
end
model=['THERMA_C3_' kind];
assert(~bdIsLoaded(model),'THERMA:C3OpenModel','Close existing %s before generating a new copy.',model);
if ~isfolder(outputParent), mkdir(outputParent); end
folder=tempname(outputParent); mkdir(folder); file=fullfile(folder,[model '.slx']);
load_system('simulink'); new_system(model);
try
    set_param(model,'SolverType','Variable-step','Solver','ode15s','RelTol','1e-8', ...
        'AbsTol','1e-10','MaxStep','1','StopTime','600','ReturnWorkspaceOutputs','on');
    Simulink.Annotation(model,['C3 isolated illustrative ' kind ...
        ': no C2 zone, prescribed BOPTEST heat, or reference validation.']);
    workspace=get_param(model,'ModelWorkspace'); assignin(workspace,'C3',P);
    builder([model '/Component']);
    set_param([model '/Component'],'Position',[220 40 435 110+40*numel(signals)]);
    for j=1:numel(inputs)
        c3_block(model,inputs{j},'Sources/In1',[30 30+60*j 60 50+60*j], ...
            'Port',num2str(j),'Interpolate','off');
        add_line(model,[inputs{j} '/1'],sprintf('Component/%d',j),'autorouting','on');
    end
    c3_block(model,'Signals','Signal Routing/Mux',[530 50 535 90+35*numel(signals)], ...
        'Inputs',num2str(numel(signals)));
    for j=1:numel(signals)
        add_line(model,sprintf('Component/%d',j),sprintf('Signals/%d',j),'autorouting','on');
    end
    c3_block(model,'Component_signals','Sinks/Out1',[675 70 705 90]);
    c3_block(model,'Log_components','Sinks/To Workspace',[625 140 745 175], ...
        'VariableName','c3_signals','SaveFormat','Timeseries','MaxDataPoints','inf');
    add_line(model,'Signals/1','Component_signals/1','autorouting','on');
    add_line(model,'Signals/1','Log_components/1','autorouting','on');
    save_system(model,file);
    write_boptest_json(fullfile(folder,'component.json'),struct('component',kind, ...
        'signals',{signals},'classification','illustrative_component_not_reference_validated', ...
        'MATLAB_execution_verified',false,'effective_parameters',rmfield(P,'assumptions')));
catch problem
    close_system(model,0); rethrow(problem);
end
end
