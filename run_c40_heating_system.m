function folder=run_c40_heating_system(baselineFolder)
%RUN_C40_HEATING_SYSTEM Build/open the visual C3.7 wrapper and verify one24h run.
root=fileparts(mfilename('fullpath'));
addpath(fullfile(root,'scripts','matlab','c40'),fullfile(root,'scripts','matlab','c38'), ...
    fullfile(root,'scripts','matlab','c37'),fullfile(root,'scripts','matlab','c35'), ...
    fullfile(root,'scripts','matlab','c3'),fullfile(root,'scripts','matlab','boptest'));
[Z,room]=c37_room_parameters(); [P,~]=c37_radiator_parameters(); a=room.conditions;
assert(Z.envelope.geometry.floor_m2==20 && Z.envelope.geometry.volume_m3==50 && ...
    a.air_initial_C==15 && a.fabric_initial_C==20 && a.outdoor_C==0 && a.adjacent_C==21 && ...
    a.setpoint_C==21 && a.supply_C==55 && a.duration_s==86400 && P.deadband_K==1 && ...
    abs(P.UA_W_K-34.56)<1e-10 && abs(P.nominal_flow_kg_s-864/(4180*10))<1e-12, ...
    'THERMA:C40Scenario','C4.0 must use the unchanged C3.7 scenario.');
baseline=[];
if nargin>=1 && strlength(string(baselineFolder))>0
    baseline=c38_read_baseline(root,Z,P,room,char(baselineFolder));
else
    candidates=dir(fullfile(root,'outputs','c3','c37','*','residential_result.json')); signatures={};
    for k=1:numel(candidates)
        try
            C=c38_read_baseline(root,Z,P,room,candidates(k).folder);
            signature=C.sources(2).sha256;
            if ~any(strcmp(signatures,signature))
                signatures{end+1}=signature; baseline=C; %#ok<AGROW>
            end
        catch problem
            fprintf('Cannot reuse C3.7 candidate: %s\n',problem.message);
        end
    end
    assert(numel(signatures)<=1,'THERMA:C40Select','Multiple C3.7 baselines; pass the chosen run folder.');
end
assert(~isempty(baseline),'THERMA:C40Baseline', ...
    ['Restore the original C3.7 residential_result.json, residential_trajectory.csv and generated ' ...
    'THERMA_C37_Residential.slx in its run folder, or pass that folder explicitly. No baseline is fabricated/rerun.']);
data=readmatrix(baseline.sources(2).name,'NumHeaderLines',1);
baseline.power_W=data(:,1+find(strcmp(baseline.names,'delivered_W'),1)); clear data;
% Preserve original source/config/report bytes and selected C3.7 artifacts.
files=[dir(fullfile(root,'scripts','matlab','c3','*.m'));dir(fullfile(root,'scripts','matlab','c35','*.m')); ...
    dir(fullfile(root,'scripts','matlab','c37','*.m'));dir(fullfile(root,'scripts','matlab','c38','*.m')); ...
    dir(fullfile(root,'scripts','matlab','boptest','*.m'));dir(fullfile(root,'configs','references','*.json')); ...
    dir(fullfile(root,'configs','c3','*.json'));dir(fullfile(root,'configs','c37','*.json')); ...
    dir(fullfile(root,'run_c37_residential_heating.m'));dir(fullfile(root,'run_c38_thermostat_comparison.m')); ...
    dir(fullfile(root,'docs','C37_RESIDENTIAL_HEATING.md'));dir(fullfile(root,'docs','C38_THERMOSTAT_COMPARISON.md'))];
protected=cell(1,numel(files));
for k=1:numel(files)
    name=fullfile(files(k).folder,files(k).name); protected{k}=struct('name',name,'sha256',boptest_file_sha256(name));
end
for k=1:numel(baseline.sources), protected{end+1}=baseline.sources(k); end %#ok<AGROW>
parent=fullfile(root,'outputs','c4','c40'); if ~isfolder(parent), mkdir(parent); end
folder=tempname(parent); mkdir(folder);
try
    [model,file,info]=c40_build_model(folder,Z,P,room,baseline);
    open_system(model); set_param(model,'ZoomFactor','FitSystem');
    set_param(model,'SimulationCommand','update'); output=sim(Simulink.SimulationInput(model));
    ts=output.get('c34_signals'); t=ts.Time(:); y=reshape(ts.Data,numel(t),[]);
    current=c38_check_trace(t,y,info); current.power_W=y(:,strcmp(info.signals,'delivered_W'));
    states=output.get('T_states_K');
    assert(all(isfinite(states.Data),'all') && all(states.Data>0,'all'), ...
        'THERMA:C40States','Invalid zone states.');
    comparison=c40_compare(baseline,current,P.controller_period_s,a.duration_s);
    for k=1:numel(protected)
        item=protected{k}; assert(strcmp(boptest_file_sha256(item.name),item.sha256), ...
            'THERMA:C40Preservation','Old source/result changed: %s.',item.name);
    end
    writetable(array2table([t y],'VariableNames',[{'time_s'} info.signals]),fullfile(folder,'trajectory.csv'));
    % One figure only; the copied model stays open for student inspection.
    fig=figure('Color','w','Name','C4.0 residential heating');
    subplot(2,1,1); plot(baseline.time/3600,baseline.air_K-273.15,'k--',t/3600,current.air_K-273.15,'b');
    yline(21,':','Setpoint'); grid on; ylabel('Indoor air (°C)'); legend('C3.7','C4.0','Location','best');
    subplot(2,1,2); plot(baseline.time/3600,baseline.power_W,'k--',t/3600,current.power_W,'r');
    grid on; ylabel('Radiator heat (W)'); xlabel('Elapsed time (h)'); legend('C3.7','C4.0','Location','best');
    exportgraphics(fig,fullfile(folder,'heating_system.png'),'Resolution',250);
    sources=baseline.sources;
    for k=1:numel(sources)
        [~,name,extension]=fileparts(sources(k).name); sources(k).name=[name extension];
    end
    status='baseline_reproduction_failed'; if comparison.passed, status='baseline_reproduction_passed'; end
    result=struct('status',status,'matlab_version',version,'new_simulations',1,'presentation_wrapper_only',true, ...
        'comparison',comparison,'physical_checks',current.diagnostics,'behavior_checks',current.full_day_metrics, ...
        'model_sha256',boptest_file_sha256(file),'baseline_sources',sources,'original_artifacts_preserved',true, ...
        'trajectory_sha256',boptest_file_sha256(fullfile(folder,'trajectory.csv')));
    write_boptest_json(fullfile(folder,'verification.json'),result);
    report=fullfile(root,'docs','C40_HEATING_SYSTEM.md'); text=fileread(report); marker='<!-- C40_RESULTS -->'; at=strfind(text,marker);
    assert(numel(at)==1,'THERMA:C40Report','Report marker missing.');
    fid=fopen(report,'w','n','UTF-8'); assert(fid>=0,'THERMA:C40Report','Cannot write C4.0 report.');
    cleanup=onCleanup(@() fclose(fid)); fprintf(fid,'%s\n\n',text(1:at+numel(marker)-1));
    fprintf(fid,['Actual MATLAB %s: **%s**. Air max difference %.6gK; power %.6gW; energy delta %+.6gkWh. ' ...
        'Controller demands identical:%d; transitions C3.7/C4.0:%d/%d. Delivered heat C3.7/C4.0:%.6f/%.6fkWh. ' ...
        'Existing energy, hysteresis, valve and power checks passed. Original artifacts preserved.\n\nOutputs: `%s`.\n'], ...
        version,status,comparison.max_air_difference_K,comparison.max_power_difference_W,comparison.energy_difference_kWh, ...
        comparison.demand_samples_identical,comparison.baseline_transitions,comparison.current_transitions, ...
        comparison.baseline_delivered_kWh,comparison.current_delivered_kWh,strrep(erase(folder,[root filesep]),filesep,'/'));
    clear cleanup;
    assert(comparison.passed,'THERMA:C40Reproduction','C3.7 reproduction failed; inspect verification.json and the plot. Tolerances were not adjusted.');
    fprintf('C4.0 model: %s\nVerification and one plot: %s\n',file,folder);
catch problem
    write_boptest_json(fullfile(folder,'failure.json'),struct('status','failed', ...
        'matlab_version',version,'error',boptest_exception_diagnostic(problem)));
    rethrow(problem);
end
end
