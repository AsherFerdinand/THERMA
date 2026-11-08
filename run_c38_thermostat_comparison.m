function folder=run_c38_thermostat_comparison(baselineFolder)
%RUN_C38_THERMOSTAT_COMPARISON Compare1.0/0.5 K; reuse verified C3.7 if available.
root=fileparts(mfilename('fullpath'));
addpath(fullfile(root,'scripts','matlab','c38'),fullfile(root,'scripts','matlab','c37'), ...
    fullfile(root,'scripts','matlab','c35'),fullfile(root,'scripts','matlab','c3'), ...
    fullfile(root,'scripts','matlab','boptest'));
[Z,room]=c37_room_parameters(); [P,~]=c37_radiator_parameters();
assert(P.deadband_K==1 && room.conditions.setpoint_C==21 && room.conditions.duration_s==86400, ...
    'THERMA:C38Settings','Expected original C3.7 setup.');
curves=cell(1,2);
if nargin>=1 && strlength(string(baselineFolder))>0
    % Explicit incompatible data is an error, not a request to rerun silently.
    curves{1}=c38_read_baseline(root,Z,P,room,char(baselineFolder));
else
    candidates=dir(fullfile(root,'outputs','c3','c37','*','residential_result.json'));
    signatures={};
    for k=1:numel(candidates)
        try
            C=c38_read_baseline(root,Z,P,room,candidates(k).folder);
            signature=C.sources(2).sha256;
            if ~any(strcmp(signatures,signature))
                signatures{end+1}=signature; curves{1}=C; %#ok<AGROW>
            end
        catch problem
            fprintf('C3.7 candidate not reusable (%s): %s\n',candidates(k).folder,problem.message);
        end
    end
    assert(numel(signatures)<=1,'THERMA:C38Select','Multiple different compatible baselines; pass its folder explicitly.');
end
parent=fullfile(root,'outputs','c3','c38'); if ~isfolder(parent), mkdir(parent); end
folder=tempname(parent); mkdir(folder);
% Protect old sources/configs and original selected result/model/CSV bytes.
files=[dir(fullfile(root,'scripts','matlab','c3','*.m'));dir(fullfile(root,'scripts','matlab','c35','*.m')); ...
    dir(fullfile(root,'scripts','matlab','c37','*.m'));dir(fullfile(root,'scripts','matlab','boptest','*.m')); ...
    dir(fullfile(root,'configs','references','*.json'));dir(fullfile(root,'configs','c3','*.json')); ...
    dir(fullfile(root,'configs','c37','*.json'));dir(fullfile(root,'run_c37_residential_heating.m')); ...
    dir(fullfile(root,'docs','C37_RESIDENTIAL_HEATING.md'))];
protected=cell(1,numel(files));
for k=1:numel(files)
    name=fullfile(files(k).folder,files(k).name); protected{k}=struct('name',name,'sha256',boptest_file_sha256(name));
end
if ~isempty(curves{1})
    for k=1:numel(curves{1}.sources), protected{end+1}=curves{1}.sources(k); end %#ok<AGROW>
end
newSimulations=0;
try
    source=''; signals={};
    if ~isempty(curves{1}), source=curves{1}.source_model; signals=curves{1}.names; end
    for k=1:2
        if k==1 && ~isempty(curves{1}), continue; end
        deadbands=[1 0.5]; caseFolder=fullfile(folder,sprintf('deadband_%g',deadbands(k))); mkdir(caseFolder);
        [model,file,info]=c38_build_case(caseFolder,deadbands(k),Z,P,room,source,signals);
        cleanup=onCleanup(@() closeIfLoaded(model));
        set_param(model,'SimulationCommand','update'); output=sim(Simulink.SimulationInput(model));
        newSimulations=newSimulations+1;
        ts=output.get('c34_signals'); t=ts.Time(:); y=reshape(ts.Data,numel(t),[]);
        C=c38_check_trace(t,y,info); states=output.get('T_states_K');
        assert(all(isfinite(states.Data),'all') && all(states.Data>0,'all'), ...
            'THERMA:C38States','Invalid zone states.');
        csv=fullfile(caseFolder,'trajectory.csv');
        writetable(array2table([t y],'VariableNames',[{'time_s'} info.signals]),csv);
        C.source_model=file; C.reused=false;
        C.sources=struct('name',{csv,file},'sha256',{boptest_file_sha256(csv),boptest_file_sha256(file)});
        write_boptest_json(fullfile(caseFolder,'case_result.json'),small(C));
        curves{k}=C; clear cleanup;
        if k==1, source=file; signals=info.signals; end
    end
    for k=1:numel(protected)
        item=protected{k}; assert(strcmp(boptest_file_sha256(item.name),item.sha256), ...
            'THERMA:C38Preservation','Existing C3.7/reference artifact changed: %s',item.name);
    end
    % Only two figures; full adaptive trajectories retained, display2-8h.
    fig=figure('Color','w','Visible','off'); hold on;
    for k=1:2, plot(curves{k}.time/3600,curves{k}.air_K-273.15,'LineWidth',1); end
    yline(21,'k--','Setpoint'); xlim([2 8]); grid on;
    xlabel('Elapsed time (h)'); ylabel('Indoor temperature (°C)');
    legend('1.0 °C total deadband','0.5 °C total deadband','Location','best');
    savePlot(fig,fullfile(folder,'temperature_comparison.png'));
    fig=figure('Color','w','Visible','off');
    for k=1:2
        subplot(2,1,k); stairs(curves{k}.time/3600,curves{k}.demand); xlim([2 8]); ylim([-0.1 1.1]);
        grid on; ylabel('Demand'); title(sprintf('Total hysteresis %.1f °C',curves{k}.metrics.deadband_K));
    end
    xlabel('Elapsed time (h)'); savePlot(fig,fullfile(folder,'thermostat_comparison.png'));
    summary=struct('status','executed_numerically_checked_not_real_world_validated','matlab_version',version, ...
        'new_simulations',newSimulations,'comparison_interval_h',[2 24],'plot_interval_h',[2 8], ...
        'baseline',small(curves{1}),'modified',small(curves{2}),'original_sources_and_baseline_preserved',true);
    writeReport(fullfile(root,'docs','C38_THERMOSTAT_COMPARISON.md'),curves,newSimulations,folder,root);
    write_boptest_json(fullfile(folder,'comparison.json'),summary);
    fprintf('C3.8 comparison: %s\nNew simulations: %d. Send comparison.json and the two PNGs for review.\n',folder,newSimulations);
catch problem
    write_boptest_json(fullfile(folder,'failure.json'),struct('status','failed', ...
        'matlab_version',version,'error',boptest_exception_diagnostic(problem)));
    rethrow(problem);
end
end
function S=small(C)
S=rmfield(C,{'time','air_K','demand','names','source_model'});
end
function closeIfLoaded(model)
if bdIsLoaded(model), close_system(model,0); end
end
function savePlot(fig,file)
cleanup=onCleanup(@() close(fig)); exportgraphics(fig,file,'Resolution',200);
end
function writeReport(file,curves,newSimulations,folder,root)
text=fileread(file); marker='<!-- C38_RESULTS -->'; at=strfind(text,marker);
assert(numel(at)==1,'THERMA:C38Report','Report marker missing.');
fid=fopen(file,'w','n','UTF-8'); assert(fid>=0,'THERMA:C38Report','Cannot write comparison report.');
cleanup=onCleanup(@() fclose(fid)); fprintf(fid,'%s\n\n',text(1:at+numel(marker)-1));
fprintf(fid,['Actual MATLAB %s; %d new simulations. Baseline reused: %d. All existing energy, hysteresis, valve and power checks passed.\n\n' ...
    '**Primary interval2–24h (time weighted):**\n\n' ...
    '| Total deadband °C | Mean °C | Min °C | Max °C | MAE K | Switches | Heat2–24h kWh | Heat0–24h kWh |\n' ...
    '|---|---:|---:|---:|---:|---:|---:|---:|\n'],version,newSimulations,curves{1}.reused);
for k=1:2
    m=curves{k}.metrics;
    fprintf(fid,'| %.1f | %.4f | %.4f | %.4f | %.4f | %d | %.4f | %.4f |\n', ...
        m.deadband_K,m.mean_room_degC,m.minimum_room_degC,m.maximum_room_degC,m.MAE_from_setpoint_K, ...
        m.transitions,m.delivered_2_24_kWh,m.delivered_0_24_kWh);
end
b=curves{1}.metrics; m=curves{2}.metrics;
fprintf(fid,'\nNarrow minus baseline: MAE %+.4f K; switches %+d; heat2–24h %+.4f kWh.\n\n', ...
    m.MAE_from_setpoint_K-b.MAE_from_setpoint_K,m.transitions-b.transitions,m.delivered_2_24_kWh-b.delivered_2_24_kWh);
if m.MAE_from_setpoint_K<b.MAE_from_setpoint_K
    fprintf(fid,'The narrower band reduces the observed temperature deviation. Consider0.5°C when that regulation benefit justifies the measured switching count; no equipment-wear benefit is established.\n\n');
else
    fprintf(fid,'The narrower band does not reduce the observed temperature deviation. Retain1.0°C for now; reducing the threshold band alone has not demonstrated better regulation.\n\n');
end
fprintf(fid,['Valve lag and stored radiator heat can cause overshoot beyond either nominal band. Switching changes must be interpreted with that lag. ' ...
    'Delivered heat is not whole-system efficiency: no boiler/pump efficiency is modeled. Original C3.7/reference artifacts unchanged.\n\n' ...
    'Outputs: `%s`. Exactly two PNGs; structured comparison contains original source hashes and complete check diagnostics. C3.9 not started.\n'], ...
    strrep(erase(folder,[root filesep]),filesep,'/'));
end
