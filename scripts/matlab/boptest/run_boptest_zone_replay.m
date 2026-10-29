function reportFile = run_boptest_zone_replay(replayFile,assumptionsFile,options)
%RUN_BOPTEST_ZONE_REPLAY Mixed-policy drivers around unchanged C2 equations.
% A partial replay is an exploratory experiment, not BOPTEST validation.
arguments
    replayFile (1,1) string
    assumptionsFile (1,1) string
    options.AllowPartial (1,1) logical = false
    options.MaxStepSeconds (1,1) double = NaN
end
assert(options.AllowPartial,'THERMA:PartialConsent', ...
    'Replay is a reduced partial-reference experiment. Explicit AllowPartial=true is required.');
assert(isnan(options.MaxStepSeconds) || ...
    (isfinite(options.MaxStepSeconds) && options.MaxStepSeconds>0), ...
    'THERMA:ReplayStep','MaxStepSeconds must be positive finite or NaN for original default.');
[metadata,data] = load_boptest_replay(replayFile);
root = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
parent = fullfile(root,'outputs','boptest','replays');
if ~isfolder(parent), mkdir(parent); end
folder = tempname(parent); mkdir(folder); reportFile = fullfile(folder,'replay_run.json');
report = struct('status','running','matlab_verified',false, ...
    'classification','exploratory_comparison','matlab_version',version, ...
    'simulink',ver('Simulink'),'replay_metadata',metadata, ...
    'replay_packet_sha256',boptest_file_sha256(replayFile), ...
    'stage','load_model','matlab_execution_completed',false, ...
    'simulation_returned',false);
write_boptest_json(reportFile,report);
try
    [model,~,Z] = build_boptest_zone_c2(assumptionsFile,'ShowModel',false);
    cleanup = onCleanup(@() close_system(model,0));
    report.stage = 'configure_drivers';
    report.model_name = model;
    report.generated_model = fullfile(folder,[model '.slx']);
    write_boptest_json(reportFile,report);
    initial = metadata.initial_conditions.temperature_K(:)'; first = 1;
    for face = 1:6
        n = Z.envelope.components(face).n_states;
        Z.envelope.components(face).initial_K = initial(first:first+n-1); first = first+n;
    end
    % Air initial/reference temperature is unchanged in supported uniform-start mode.
    assert(all(initial==Z.initial_K),'THERMA:ReplayInitial', ...
        'Only explicit uniform source-declared start is supported in partial mode.');
    workspace = get_param(model,'ModelWorkspace'); assignin(workspace,'Z',Z);
    % Replace ONLY the external driver in a fresh generated model. Root-port
    % Interpolate cannot express mixed channel policies; separate From Workspace
    % sources can. All downstream selectors, equations and output logs are reused.
    ports = get_param([model '/Inputs'],'PortHandles');
    line = get_param(ports.Outport,'Line');
    if line~=-1, delete_line(line); end
    delete_block([model '/Inputs']);
    add_block('simulink/Signal Routing/Mux',[model '/Inputs'],'Inputs','11', ...
        'Position',[300 20 310 400]);
    % Set the actual requested interval before the driver checks coverage.
    set_param(model,'StartTime','0','StopTime',num2str(metadata.duration_s,17));
    if ~isnan(options.MaxStepSeconds)
        set_param(model,'MaxStep',num2str(options.MaxStepSeconds,17));
    end
    [simulationInput,report.drivers] = configure_boptest_replay_sources(model,metadata,data);
    destinations = {'Outdoor_K','Heating_conv_W','Heating_rad_W', ...
        'Internal_conv_W','Internal_rad_W','Solar_absorbed_W','Log_inputs_used'};
    for j = 1:numel(destinations)
        add_line(model,'Inputs/1',[destinations{j} '/1'],'autorouting','on');
    end
    evaluationRelative = metadata.evaluation_start_s-metadata.time_origin_s;
    set_param(model,'OutputOption','AdditionalOutputTimes', ...
        'OutputTimes',mat2str([0 evaluationRelative metadata.duration_s],17));
    Simulink.BlockDiagram.arrangeSystem(model);
    save_system(model,fullfile(folder,[model '.slx']));
    report.registry_sha256 = Z.envelope.registry_sha256;
    report.assumptions_sha256 = Z.assumptions_sha256; report.assumptions = Z.assumptions;
    report.model_version = Z.version;
    report.driver_source_sha256 = boptest_file_sha256(mfilename('fullpath')+".m");
    report.solver = struct('name',get_param(model,'Solver'), ...
        'RelTol',get_param(model,'RelTol'),'AbsTol',get_param(model,'AbsTol'), ...
        'MaxStep_s',get_param(model,'MaxStep'));
    report.start_time_s = get_param(model,'StartTime');
    report.stop_time_s = get_param(model,'StopTime');
    report.simulation_input_class = class(simulationInput);
    report.stage = 'compile'; write_boptest_json(reportFile,report);
    set_param(model,'SimulationCommand','update');
    report.stage = 'simulate'; write_boptest_json(reportFile,report);
    result = sim(simulationInput);
    report.simulation_returned = true;
    report.matlab_execution_completed = true;
    report.stage = 'export'; write_boptest_json(reportFile,report);
    save(fullfile(folder,'simulation.mat'),'result');
    names = {'T_air_K','q_heating_W','q_vent_W','E_J','residual_W','T_opaque_mean_K', ...
        'q_net_W','dE_dt_W','q_solar_W','q_internal_W'};
    columns = {'air_temperature','delivered_heating_power','ventilation_sensible_power', ...
        'stored_thermal_energy','power_balance_residual','opaque_mean_surface_temperature', ...
        'net_external_power','stored_energy_derivative','absorbed_solar_power','internal_gain_power'};
    firstSeries = result.get(names{1}); [time,index] = unique(firstSeries.Time(:),'last');
    values = zeros(numel(time),numel(names));
    for j = 1:numel(names)
        series = result.get(names{j});
        assert(isequal(series.Time(:),firstSeries.Time(:)), ...
            'THERMA:ReplayLogs','Output time grids disagree.');
        sample = squeeze(series.Data); values(:,j) = sample(index);
    end
    used = result.get('inputs_used');
    assert(isequal(used.Time(:),firstSeries.Time(:)), ...
        'THERMA:ReplayInputLogs','Actual forcing/state log grids differ.');
    usedData = squeeze(used.Data);
    if size(usedData,1)~=numel(used.Time), usedData = usedData'; end
    values = [values usedData(index,1:5)];
    columns = [columns,{'outdoor_temperature','delivered_heating_convective_power', ...
        'delivered_heating_radiative_power','internal_convective_power','internal_radiative_power'}];
    assert(all(isfinite(values),'all'),'THERMA:ReplayFinite','Nonfinite replay output.');
    absolute = time+metadata.time_origin_s;
    output = array2table([absolute values],'VariableNames',[{'time_s'},columns]);
    writetable(output,fullfile(folder,'trajectory.csv'));
    selected = absolute>=metadata.evaluation_start_s & absolute<=metadata.evaluation_end_s;
    assert(any(selected) && absolute(find(selected,1))==metadata.evaluation_start_s && ...
        absolute(find(selected,1,'last'))==metadata.evaluation_end_s, ...
        'THERMA:ReplayCoverage','Exact evaluation samples missing; no silent trimming/extrapolation.');
    csvFile = fullfile(folder,'evaluation.csv'); writetable(output(selected,:),csvFile);
    unit = {'K','W','W','J','W','K','W','W','W','W','K','W','W','W','W'};
    policies = {'linear','previous','previous','linear','previous','linear', ...
        'previous','previous','previous','previous', ...
        'linear','previous','previous','previous','previous'};
    signals = cell(1,numel(columns));
    for j = 1:numel(columns)
        signals{j} = struct('quantity',columns{j},'unit',unit{j},'interpolation',policies{j});
    end
    comparison = struct('schema_version',1,'scenario_id',metadata.scenario_id, ...
        'reference_version',metadata.reference_version,'model_version',Z.version, ...
        'csv_sha256',boptest_file_sha256(csvFile),'signals',{signals}, ...
        'classification','exploratory_comparison','missing_inputs',{metadata.missing_inputs}, ...
        'assumptions',{metadata.assumptions},'limitations',{metadata.limitations});
    write_boptest_json(fullfile(folder,'comparison_metadata.json'),comparison);
    report.status = 'executed_partial_not_validated'; report.stage = 'completed';
catch problem
    report.status = 'failed';
    report.error = boptest_exception_diagnostic(problem);
    % Persist the original exception before printing/rethrowing anything else.
    write_boptest_json(reportFile,report);
    print_boptest_exception(problem,reportFile);
    failure = MException('THERMA:ReplayFailed', ...
        'Replay failed during %s. Full diagnostic report: %s',report.stage,reportFile);
    failure = addCause(failure,problem);
    throw(failure);
end
write_boptest_json(reportFile,report); fprintf('Replay report: %s\n',reportFile);
end
