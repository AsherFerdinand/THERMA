function folder=run_c39_boptest_comparison()
%RUN_C39_BOPTEST_COMPARISON Reproduce verified C2.8 post-processing; NO simulations.
root=fileparts(mfilename('fullpath'));
addpath(fullfile(root,'scripts','matlab','c39'),fullfile(root,'scripts','matlab','boptest'));
bundle=fullfile(root,'outputs','boptest','c39','verified_comparison');
file=fullfile(bundle,'metrics.json');
assert(isfile(file),'THERMA:C39Missing', ...
    'Missing C3.9 derived-data bundle. Extract the complete C3.9 update ZIP; no old C2.7/C2.8 folder is needed.');
m=jsondecode(fileread(file));
for name={'temperature.csv','heating.csv'}
    key=matlab.lang.makeValidName(name{1},'ReplacementStyle','underscore');
    assert(strcmp(boptest_file_sha256(fullfile(bundle,name{1})),m.derived_files.(key)), ...
        'THERMA:C39Hash','Derived data changed: %s.',name{1});
end
assert(m.sample_count==40321 && m.scenario.evaluation_start_s==28857600 && ...
    m.scenario.evaluation_end_s==30067200 && ~m.scenario.reset_at_evaluation_start && ...
    strcmp(m.boptest_commit,'a29024f8c453517ccbd1186006a3fa6af8de1ae2'), ...
    'THERMA:C39Scenario','Pinned reference scenario differs.');
a=readmatrix(fullfile(bundle,'temperature.csv'),'NumHeaderLines',1);
b=readmatrix(fullfile(bundle,'heating.csv'),'NumHeaderLines',1); S=c39_metrics(a,b,m);
assert(abs(S.temperature.MAE_degC-m.metrics.MAE_K)<1e-10 && ...
    abs(S.temperature.RMSE_degC-m.metrics.RMSE_K)<1e-10 && ...
    abs(S.heating.reference_30s_hold_kWh-m.heating_energy.reference_30s_hold_kWh)<1e-8 && ...
    abs(S.heating.THERMA_logged_hold_kWh-m.heating_energy.THERMA_logged_hold_kWh)<1e-8, ...
    'THERMA:C39Reproduction','Post-processing differs from preserved verified values.');
parent=fullfile(root,'outputs','boptest','c39'); folder=tempname(parent); mkdir(folder);
days=(a(:,1)-a(1,1))/86400;
fig=figure('Color','w','Visible','off');
plot(days,a(:,3)-273.15,days,a(:,2)-273.15,'LineWidth',1); grid on;
xlabel('Evaluation time (days)'); ylabel('Indoor air temperature (°C)');
legend('BOPTEST mod.case900Template.TAir','THERMA C2 air, solar-resolved','Location','best');
savePlot(fig,fullfile(folder,'temperature_comparison.png'));
fig=figure('Color','w','Visible','off'); plot(days,a(:,2)-a(:,3),'LineWidth',1); yline(0,'k--'); grid on;
xlabel('Evaluation time (days)'); ylabel('THERMA air minus BOPTEST air (K)');
savePlot(fig,fullfile(folder,'temperature_error.png'));
S.matlab_postprocessing_version=version; S.model_simulation_executed=false;
S.original_source_provenance=m.source_provenance;
write_boptest_json(fullfile(folder,'comparison.json'),S);
fprintf('C3.9 air MAE %.9f K, RMSE %.9f K; no simulations.\nOutputs: %s\n', ...
    S.temperature.MAE_degC,S.temperature.RMSE_degC,folder);
end
function savePlot(fig,file)
cleanup=onCleanup(@() close(fig)); exportgraphics(fig,file,'Resolution',250);
end
