function [result,folder]=c35_run_case(c,plan,parent,contractHash)
%C35_RUN_CASE Resume only hash-verified outputs under the identical study contract.
caseParent=fullfile(parent,c.id); if ~isfolder(caseParent), mkdir(caseParent); end
expected=struct('case_definition',c,'study_contract_sha256',contractHash,'matlab_version',version);
attempts=dir(caseParent);
for k=1:numel(attempts)
    if ~attempts(k).isdir || startsWith(attempts(k).name,'.'), continue; end
    candidate=fullfile(caseParent,attempts(k).name); receipt=fullfile(candidate,'completion.json');
    if ~isfile(receipt), continue; end
    try
        item=jsondecode(fileread(receipt));
        required={'case_result.json','integration_trajectory.csv','trajectory_metadata.json','engineering_report.md', ...
            'closed_loop_traces.png','closed_loop_traces.fig','energy_balances.png','energy_balances.fig'};
        names={item.artifacts.name};
        valid=all(ismember(required,names)) && numel(unique(names))==numel(names) && strcmp(item.status,'completed') && isequal(item.expected,expected);
        for j=1:numel(item.artifacts)
            a=item.artifacts(j); valid=valid && ~contains(a.name,{'/','\',':'}) && ...
                ~strcmp(a.name,'..') && strcmp(boptest_file_sha256(fullfile(candidate,a.name)),a.sha256);
        end
        if valid
            result=jsondecode(fileread(fullfile(candidate,'case_result.json')));
            if result.metrics.checks_passed
                folder=candidate; fprintf('Reusing verified %s\n',c.id); return;
            end
        end
    catch
        % Incomplete/corrupt attempts are retained and never reused.
    end
end
folder=tempname(caseParent); mkdir(folder);
try
    fprintf('Simulating %s: UA %g W/K, supply %.1f °C, outdoor %.1f °C, max step %g s\n', ...
        c.id,c.UA_W_K,c.supply_K-273.15,c.outdoor_K-273.15,c.max_step_s);
    [model,file,info]=c35_build_case(c,plan,folder); cleanup=onCleanup(@() close_system(model,0));
    set_param(model,'SimulationCommand','update'); start=tic;
    output=sim(Simulink.SimulationInput(model)); elapsed=toc(start);
    data=output.get('c34_signals'); time=data.Time(:); y=reshape(data.Data,numel(time),[]);
    D=assess_c34(time,y,info.signals,info.experiment,info.effective_components);
    state=output.get('T_states_K');
    assert(~isempty(state.Data) && all(isfinite(state.Data),'all') && all(state.Data>0,'all'), ...
        'THERMA:C35States','Invalid zone state temperatures.');
    if D.passive_zero_gain_envelope_checked
        I=info.experiment; low=min([I.outdoor_K I.initial_zone_K I.initial_radiator_K I.supply_K]);
        high=max([I.outdoor_K I.initial_zone_K I.initial_radiator_K I.supply_K]);
        D.checks.all_zone_states_passive=all(state.Data>=low-I.checks.temperature_envelope_margin_K & ...
            state.Data<=high+I.checks.temperature_envelope_margin_K,'all');
        if ~D.checks.all_zone_states_passive, D.status='integration_numerical_checks_failed'; end
    end
    M=c35_metrics(time,y,info,D,plan);
    workspace=get_param(model,'ModelWorkspace'); Z=getVariable(workspace,'Z');
    steady=c35_steady_diagnostics(Z,info.effective_components,info.experiment);
    % C3.4 exporter accepts the extended trace; all earlier fields retain their meanings.
    info.matlab_version=version; info.simulink=ver('Simulink');
    export_c34_results(folder,time,y,info,D);
    appendCaseNote(fullfile(folder,'engineering_report.md'),c,plan);
    result=struct('status','executed_checks_pending','case_definition',c,'metrics',M, ...
        'diagnostics',D,'steady_diagnostics',steady,'elapsed_simulation_s',elapsed, ...
        'matlab_version',version,'simulink',ver('Simulink'),'signals',{info.signals}, ...
        'model_file_relative',strrep(erase(file,[folder filesep]),filesep,'/'), ...
        'model_sha256',boptest_file_sha256(file));
    write_boptest_json(fullfile(folder,'case_result.json'),result);
    assert(M.checks_passed,'THERMA:C35Checks','Actual energy/controller/valve check failed; inspect %s.',folder);
    result.status='executed_numerically_checked_not_reference_validated';
    write_boptest_json(fullfile(folder,'case_result.json'),result);
    files={'case_result.json','integration_trajectory.csv','trajectory_metadata.json','engineering_report.md', ...
        'closed_loop_traces.png','closed_loop_traces.fig','energy_balances.png','energy_balances.fig'};
    artifacts=cell(1,numel(files));
    for k=1:numel(files), artifacts{k}=struct('name',files{k},'sha256',boptest_file_sha256(fullfile(folder,files{k}))); end
    write_boptest_json(fullfile(folder,'completion.json'),struct('status','completed','expected',expected,'artifacts',{artifacts}));
catch problem
    write_boptest_json(fullfile(folder,'failure.json'),struct('status','failed','case_definition',c, ...
        'matlab_version',version,'error',boptest_exception_diagnostic(problem)));
    rethrow(problem);
end
end

function appendCaseNote(file,c,plan)
fid=fopen(file,'a','n','UTF-8'); assert(fid>=0,'THERMA:C35Report','Cannot append case provenance.');
cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'\n## C3.5 case identity\n\nCase %s, UA %.9g W/K. This report uses the unchanged C3.4 export template for a new C3.5 case, not the preserved baseline result.\n',c.id,c.UA_W_K);
if c.solar
    fprintf(fid,['The six solar values printed above are the PEAK ENVELOPE, not held forcing. ' ...
        'Actual forcing is the saved piecewise-linear profile: %s Native solar_J records the measured absorbed energy.\n'],plan.solar.source);
end
end
