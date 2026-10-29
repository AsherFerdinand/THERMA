function [model, modelFile, Z] = build_boptest_zone_c2(assumptionsFile, options)
%BUILD_BOPTEST_ZONE_C2 Reduced 28-state dry-air zone, not exact BOPTEST.
% Input u=[Tout_K,Qheat_conv_W,Qheat_rad_W,Qinternal_conv_W,Qinternal_rad_W,
%          Qsolar_absorbed_W(1:6)]. Every gain is delivered power, never gas input.
arguments
    assumptionsFile (1,1) string
    options.ShowModel (1,1) logical = true
end
Z = load_boptest_zone_parameters(assumptionsFile);
assert(exist('new_system','file') ~= 0 || exist('new_system','builtin') == 5, ...
    'THERMA:NoSimulink','MATLAB with Simulink is required.');
model = 'THERMA_BOPTEST_ThermalZone_C2';
assert(~bdIsLoaded(model),'THERMA:AlreadyLoaded','Save/close %s before rebuilding.',model);
root = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
parent = fullfile(root,'outputs','boptest','simulink_c2');
if ~isfolder(parent), mkdir(parent); end
folder = tempname(parent); mkdir(folder);
modelFile = fullfile(folder,[model '.slx']);
load_system('simulink');
new_system(model);
try
    workspace = get_param(model,'ModelWorkspace'); assignin(workspace,'Z',Z);
    set_param(model,'SolverType','Variable-step','Solver','ode15s', ...
        'RelTol','1e-7','AbsTol','1e-9','MaxStep','30','StopTime','7200', ...
        'ReturnWorkspaceOutputs','on');
    Simulink.Annotation(model, ['REDUCED C2: 28 states. Explicit provisional dry-air/' ...
        'surface assumptions. Not an exact BOPTEST reconstruction. ' ...
        'All material parameters remain in frozen Model Workspace Z.envelope.']);
    add_block('simulink/Sources/In1',[model '/Inputs'], ...
        'PortDimensions','11','Position',[20 40 50 60]);
    cursor = 0;
    tout = select('Outdoor_K','Inputs/1','1',11);
    heatC = select('Heating_conv_W','Inputs/1','2',11);
    heatR = select('Heating_rad_W','Inputs/1','3',11);
    internalC = select('Internal_conv_W','Inputs/1','4',11);
    internalR = select('Internal_rad_W','Inputs/1','5',11);
    solar = select('Solar_absorbed_W','Inputs/1','6:11',11);
    % Editable air storage, driven by its net heat input.
    air = [model '/Zone_Air'];
    add_block('built-in/Subsystem',air,'Position',[900 20 1080 100]);
    add_block('simulink/Sources/In1',[air '/Net_power_W'],'Position',[20 50 50 70]);
    add_block('simulink/Math Operations/Gain',[air '/Inverse_capacity'], ...
        'Gain','1/Z.C_air_J_K','Position',[80 40 180 80]);
    add_block('simulink/Continuous/Integrator',[air '/T_air_K'], ...
        'InitialCondition','Z.initial_K','Position',[230 40 270 80]);
    add_block('simulink/Sinks/Out1',[air '/Temperature_K'],'Position',[320 50 350 70]);
    add_line(air,'Net_power_W/1','Inverse_capacity/1');
    add_line(air,'Inverse_capacity/1','T_air_K/1');
    add_line(air,'T_air_K/1','Temperature_K/1');
    ta = 'Zone_Air/1';
    te = cell(1,6); ti = te; stored = te; rates = te; states = te;
    for face = 1:6
        c = Z.envelope.components(face);
        add_boptest_construction(model,c.name,c,sprintf('Z.envelope.components(%d)',face), ...
            'heat_flow',[460 150+(face-1)*160 650 240+(face-1)*160]);
        width = 7+c.n_states;
        te{face} = select([c.name '_Exterior_K'],[c.name '/1'],'1',width);
        ti{face} = select([c.name '_Interior_K'],[c.name '/1'],'2',width);
        stored{face} = select([c.name '_Energy_J'],[c.name '/1'],'5',width);
        rates{face} = select([c.name '_Rate_W'],[c.name '/1'],'6',width);
        states{face} = select([c.name '_States_K'],[c.name '/1'],sprintf('8:%d',width),width);
    end
    surface = mux('Interior_surfaces_K',ti);
    radiative = gain('Surface_Radiation','Z.radiation_matrix_W_K',surface,true);
    radGains = sumSignals('Radiant_gains_W',{heatR,internalR},'++');
    distributed = gain('Radiant_distribution','Z.radiant_weights''',radGains,true);
    radNet = sumSignals('Net_radiation_solar_W',{radiative,distributed,solar},'+++');
    conv = cell(1,6); exterior = cell(1,5);
    for face = 1:6
        c = Z.envelope.components(face);
        conv{face} = exchange(['Interior_Convection_' c.name], ...
            sprintf('Z.H_interior_W_K(%d)',face),ta,ti{face});
        radFace = select(['Radiation_to_' c.name],radNet,num2str(face),6);
        qint = sumSignals(['Power_into_' c.name],{conv{face},radFace},'++');
        wire(qint,sprintf('%s/%d',c.name,2-c.adiabatic_exterior));
        if face <= 5
            exterior{face} = exchange(['Exterior_Convection_' c.name], ...
                sprintf('Z.H_exterior_W_K(%d)',face),tout,te{face});
            wire(exterior{face},[c.name '/1']);
        end
    end
    qconv = sumSignals('Total_air_to_surface_W',conv,'++++++');
    qext = sumSignals('Exterior_power_W',exterior,'+++++');
    qvent = exchange('Ventilation_Infiltration','Z.H_vent_W_K',tout,ta);
    qwindow = exchange('Static_Window','Z.UA_window_W_K',tout,ta);
    qair = sumSignals('Net_air_power_W',{heatC,internalC,qvent,qwindow,qconv},'++++-');
    wire(qair,'Zone_Air/1');
    airDelta = sumSignals('Air_temperature_offset_K',{ta,constant('Reference_K','Z.initial_K')},'+-');
    airEnergy = gain('Air_energy_J','Z.C_air_J_K',airDelta,false);
    energy = sumSignals('Stored_energy_J',[stored {airEnergy}],'+++++++');
    derivative = sumSignals('Energy_derivative_W',[rates {qair}],'+++++++');
    solarTotal = gain('Total_solar_W','ones(1,6)',solar,true);
    qnet = sumSignals('External_net_power_W', ...
        {qext,qvent,qwindow,heatC,heatR,internalC,internalR,solarTotal},'++++++++');
    residual = sumSignals('Balance_residual_W',{derivative,qnet},'+-');
    ts = mux('All_states_K',[states {ta}]);
    % Area-weighted opaque-surface diagnostic; not source TRad/operative temperature.
    trad = gain('Opaque_mean_surface_K','Z.radiant_weights',surface,true);
    outputs = {ta,surface,mux('Exterior_surfaces_K',te),qext,qconv,qvent,qwindow, ...
        sumSignals('Total_heating_W',{heatC,heatR},'++'), ...
        sumSignals('Total_internal_W',{internalC,internalR},'++'),solarTotal, ...
        energy,derivative,qnet,residual,ts,trad,radiative};
    names = {'T_air_K','T_interior_K','T_exterior_K','q_exterior_W', ...
        'q_air_to_surfaces_W','q_vent_W','q_window_W','q_heating_W', ...
        'q_internal_W','q_solar_W','E_J','dE_dt_W','q_net_W','residual_W', ...
        'T_states_K','T_opaque_mean_K','q_radiation_exchange_W'};
    for j = 1:numel(outputs)
        add_block('simulink/Sinks/Out1',[model '/' names{j} '_out'], ...
            'Port',num2str(j),'Position',[1800 j*65 1830 j*65+20]);
        add_block('simulink/Sinks/To Workspace',[model '/Log_' names{j}], ...
            'VariableName',names{j},'SaveFormat','Timeseries','MaxDataPoints','inf', ...
            'Position',[1600 j*65 1740 j*65+30]);
        wire(outputs{j},[names{j} '_out/1']); wire(outputs{j},['Log_' names{j} '/1']);
    end
    % Layout affects positions only. Deterministic names/physical topology are above.
    Simulink.BlockDiagram.arrangeSystem(model);
    save_system(model,modelFile);
    write_boptest_json(fullfile(folder,'parameters.json'),Z);
    write_boptest_json(fullfile(folder,'build.json'),struct('status','generated_not_verified', ...
        'matlab_verified',false,'model_version',Z.version, ...
        'registry_sha256',Z.envelope.registry_sha256,'total_states',Z.total_states));
catch problem
    write_boptest_json(fullfile(folder,'failure.json'),struct('status','failed', ...
        'identifier',problem.identifier,'message',problem.message));
    close_system(model,0); rethrow(problem);
end
if options.ShowModel, open_system(model); end
fprintf('Reduced C2 model: %s\n',modelFile);

    function p = position()
        cursor = cursor+1;
        x = 40+mod(cursor-1,8)*170; y = 120+floor((cursor-1)/8)*80;
        p = [x y x+110 y+35];
    end
    function wire(source,destination)
        add_line(model,source,destination,'autorouting','on');
    end
    function out = select(name,source,indices,width)
        add_block('simulink/Signal Routing/Selector',[model '/' name], ...
            'NumberOfDimensions','1','InputPortWidth',num2str(width),'IndexMode','One-based', ...
            'IndexOptionArray',{'Index vector (dialog)'},'IndexParamArray',{indices},'Position',position());
        wire(source,[name '/1']); out = [name '/1'];
    end
    function out = gain(name,value,source,matrix)
        add_block('simulink/Math Operations/Gain',[model '/' name], ...
            'Gain',value,'Position',position());
        if matrix, set_param([model '/' name],'Multiplication','Matrix(K*u)'); end
        wire(source,[name '/1']); out = [name '/1'];
    end
    function out = constant(name,value)
        add_block('simulink/Sources/Constant',[model '/' name],'Value',value,'Position',position());
        out = [name '/1'];
    end
    function out = sumSignals(name,sources,signs)
        add_block('simulink/Math Operations/Sum',[model '/' name], ...
            'Inputs',signs,'Position',position());
        for port = 1:numel(sources), wire(sources{port},sprintf('%s/%d',name,port)); end
        out = [name '/1'];
    end
    function out = mux(name,sources)
        add_block('simulink/Signal Routing/Mux',[model '/' name], ...
            'Inputs',num2str(numel(sources)),'Position',position());
        for port = 1:numel(sources), wire(sources{port},sprintf('%s/%d',name,port)); end
        out = [name '/1'];
    end
    function out = exchange(name,H,left,right)
        path = [model '/' name];
        add_block('built-in/Subsystem',path,'Position',position());
        add_block('simulink/Sources/In1',[path '/Left_K'],'Port','1','Position',[20 30 50 50]);
        add_block('simulink/Sources/In1',[path '/Right_K'],'Port','2','Position',[20 100 50 120]);
        add_block('simulink/Math Operations/Sum',[path '/Delta_K'], ...
            'Inputs','+-','Position',[100 40 130 100]);
        add_block('simulink/Math Operations/Gain',[path '/Conductance_W_K'], ...
            'Gain',H,'Position',[180 50 290 90]);
        add_block('simulink/Sinks/Out1',[path '/Power_W'],'Position',[340 60 370 80]);
        add_line(path,'Left_K/1','Delta_K/1'); add_line(path,'Right_K/1','Delta_K/2');
        add_line(path,'Delta_K/1','Conductance_W_K/1');
        add_line(path,'Conductance_W_K/1','Power_W/1');
        wire(left,[name '/1']); wire(right,[name '/2']); out = [name '/1'];
    end
end
