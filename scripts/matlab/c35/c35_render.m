function c35_render(folder,results,paths,controllerID,plan,mode)
%C35_RENDER Reports/plots only for actual successful case outputs.
metrics=cellfun(@(x) x.metrics,results,'UniformOutput',false);
table=struct2table([metrics{:}]); baseline=results{1}.metrics;
table.delivered_change_percent=100*(table.delivered_kWh-baseline.delivered_kWh)/baseline.delivered_kWh;
table.peak_change_percent=100*(table.peak_delivered_W-baseline.peak_delivered_W)/baseline.peak_delivered_W;
writetable(table,fullfile(folder,'results_table.csv'));
write_boptest_json(fullfile(folder,'results_table.json'),table2struct(table));
ids=cellfun(@(x) x.case_definition.id,results,'UniformOutput',false);
plotGroup(folder,results,paths,ids,'A_capacity',{'baseline','A_UA_90','A_UA_120','A_UA_180'});
if strcmp(mode,'all')
    plotGroup(folder,results,paths,ids,'B_supply',{'B_supply_40','B_supply_45','baseline','B_supply_65'});
    plotGroup(folder,results,paths,ids,'D_outdoor',{'D_outdoor_minus5','D_outdoor_plus0','baseline','D_outdoor_plus10'});
    plotGroup(folder,results,paths,ids,'E_solar',{'baseline','E_solar'});
end
comparisons={};
for k=1:numel(results)
    if strcmp(results{k}.case_definition.group,'F')
        original=erase(regexprep(results{k}.case_definition.id,'_step_\d+$',''),'F_');
        first=find(strcmp(ids,original),1);
        comparisons{end+1}=c35_compare_cases(paths{first},paths{k},plan.sampling_for_comparisons_s); %#ok<AGROW>
    end
end
write_boptest_json(fullfile(folder,'numerical_sensitivity.json'),struct('comparisons',{comparisons}, ...
    'controller_case',controllerID,'claim','Measured differences only; no automatic convergence/accuracy claim.'));
if ~isempty(controllerID)
    selected=find(strcmp(ids,controllerID),1);
    plotController(folder,controllerID,paths{selected},results{selected});
end
report=fullfile(folder,'engineering_report.md'); fid=fopen(report,'w','n','UTF-8');
assert(fid>=0,'THERMA:C35Report','Cannot create report.'); cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'# C3.5 actual MATLAB engineering investigation\n\nMode: %s. MATLAB %s.\n',mode,version);
fprintf(fid,'Every reported case passed its recorded numerical and controller checks. This is illustrative-model analysis, not real-world/BOPTEST validation.\n\n');
fprintf(fid,'## Measured case summary\n\n| Case | Final °C | Max °C | MAE K | Below h | Above h | Delivered kWh | Water kWh | Peak W | Switches |\n|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|\n');
for k=1:numel(results)
    m=results{k}.metrics;
    fprintf(fid,'| %s | %.5f | %.5f | %.5f | %.4f | %.4f | %.6f | %.6f | %.4f | %d |\n', ...
        ids{k},m.final_air_degC,m.maximum_air_degC,m.tracking_MAE_K,m.below_band_h,m.above_band_h, ...
        m.delivered_kWh,m.water_kWh,m.peak_delivered_W,m.thermostat_transitions);
end
fprintf(fid,'\n## UA-only percentage changes relative to baseline\n\n');
reached=false;
for k=1:numel(results)
    if ~strcmp(results{k}.case_definition.group,'A'), continue; end
    m=results{k}.metrics; reached=reached || m.reach_21_0_observed;
    fprintf(fid,'- %s: delivered energy change %+.5f%%; peak power change %+.5f%%; 21 °C observed=%d.\n', ...
        ids{k},100*(m.delivered_kWh-baseline.delivered_kWh)/baseline.delivered_kWh, ...
        100*(m.peak_delivered_W-baseline.peak_delivered_W)/baseline.peak_delivered_W,m.reach_21_0_observed);
end
if ~reached, fprintf(fid,'No UA case reached the 21 °C setpoint within this 24-hour observation. Parameters were not changed to conceal that result.\n'); end
fprintf(fid,'\n![UA comparison](A_capacity.png)\n');
fprintf(fid,'\nThreshold times in the CSV use -1 with observed=false when never reached; they are not negative physical times. First-attainment estimates use linear temperature interpolation.\n');
fprintf(fid,'\n## Capacity, inertia and losses: separate evidence\n\n');
for k=1:numel(results)
    r=results{k}; s=r.steady_diagnostics; m=r.metrics;
    fprintf(fid,['- %s: conditional full-open zero-solar steady air %.5f °C; required/available heat at setpoint %.4f / %.4f W; ' ...
        'slowest all-on time scale %.3f h (stable=%d). Actual zone storage increase %.6f kWh; ' ...
        'exterior/ventilation/window signed losses %.6f / %.6f / %.6f kWh; last-six-hour slope %.5f K/h.\n'], ...
        ids{k},s.all_on_steady_air_degC,s.required_room_heat_at_setpoint_W,s.available_full_open_heat_at_setpoint_W, ...
        s.slowest_time_constant_s/3600,s.stable_all_on_linear_plant,m.zone_storage_change_kWh, ...
        m.exterior_loss_kWh,m.ventilation_loss_kWh,m.window_loss_kWh,m.late_slope_K_h);
end
fprintf(fid,['\nA negative steady capacity margin supports insufficient constant-condition capacity within this model. ' ...
    'A positive margin with a long time scale and ongoing storage/temperature rise supports finite warm-up as another explanation. ' ...
    'Measured loss energies identify where heat leaves. None alone establishes a real building diagnosis.\n']);
fprintf(fid,'\n## Controller evidence\n\n');
if isempty(controllerID)
    fprintf(fid,'No tested A/B/fallback case exhibited an off transition. Controller cycling investigation and switched-case convergence are blocked; no successful regulation is claimed.\n');
else
    k=find(strcmp(ids,controllerID),1); m=results{k}.metrics;
    fprintf(fid,['Selected %s: on/off transitions %d/%d; hysteresis violations %d; valve analytic max error %.9g. ' ...
        'Demand-off delivered/water/storage-release energies %.7f / %.7f / %.7f kWh. ' ...
        'Near-closed warming intervals %d (opening <= %.4g is approximate closure, not zero flow).\n'], ...
        controllerID,m.on_events,m.off_events,m.hysteresis_violations,m.valve_analytic_max_error, ...
        m.heat_during_off_kWh,m.water_heat_during_off_kWh,m.storage_release_during_off_kWh,m.near_closed_warming_intervals,plan.near_closed_opening);
    fprintf(fid,'An off event alone is not proof of sustained regulation. Residual water flow and thermal storage are accounted separately; wall storage/solar may also warm the air.\n');
end
if any(strcmp(ids,'E_solar'))
    k=find(strcmp(ids,'E_solar'),1); m=results{k}.metrics;
    fprintf(fid,'\n## Paired solar effect\n\nAbsorbed solar %.7f kWh; signed radiator energy reduction %.7f kWh (%.5f%%); below-band time change %.5f h.\n', ...
        m.solar_kWh,baseline.delivered_kWh-m.delivered_kWh,100*(baseline.delivered_kWh-m.delivered_kWh)/baseline.delivered_kWh,m.below_band_h-baseline.below_band_h);
    if m.thermostat_transitions==0
        fprintf(fid,'The thermostat did not switch; do not assume an energy-saving response. Air/radiator temperature differences can change heat delivery at continuous full demand.\n');
    end
end
fprintf(fid,'\n## Measured maximum-step differences (relative to 10 s)\n\n');
for k=1:numel(comparisons)
    r=comparisons{k};
    fprintf(fid,'- %s versus %s: final air %+.9g K; delivered energy %+.9g kWh; switching count %+d; maximum sampled difference %.9g K; event pairing valid=%d.\n', ...
        r.second_case,r.first_case,r.final_air_difference_K,r.delivered_energy_difference_kWh, ...
        r.switching_count_difference,r.temperature_max_abs_difference_K,r.event_pairing_valid);
end
if isempty(comparisons), fprintf(fid,'No maximum-step comparison requested/completed in this mode.\n'); end
fprintf(fid,['\n## Numerical sensitivity and limitations\n\nSee numerical_sensitivity.json for 10-versus-5/1 s temperature, energy, count and paired event-time differences. ' ...
    'Unequal event counts are not falsely paired. Solver family/tolerances are held fixed. No convergence claim is inferred automatically. ' ...
    'Native cumulative states supply every energy diagnostic; sparse trace integration is used only for temperature/time metrics.\n\n' ...
    'Radiator UA-only changes retain water/metal capacity and imposed nominal flow: larger UA need not yield proportional power. ' ...
    'Supply input energy is not fuel/electric consumption. The air-radiant-sink proxy, reduced envelope and imposed-flow assumptions remain. ' ...
    'No calibration, C2.8 accuracy reuse, ML or C4 work was performed.\n']);

end

function plotGroup(folder,results,paths,ids,stem,wanted)
        fig=figure('Visible','off','Color','w','Position',[100 100 1100 500]); hold on;
        labels={};
        for j=1:numel(wanted)
            i=find(strcmp(ids,wanted{j}),1); if isempty(i), continue; end
            data=readmatrix(fullfile(paths{i},'integration_trajectory.csv'),'NumHeaderLines',1);
            plot(data(:,1)/3600,data(:,1+find(strcmp(results{i}.signals,'air_K')))-273.15,'LineWidth',1.1);
            labels{end+1}=wanted{j}; %#ok<AGROW>
        end
        yline(21,'k--','Setpoint 21 °C'); xlabel('Elapsed time (h)'); ylabel('Indoor air temperature (°C)');
        title(['C3.5 ' strrep(stem,'_',' ')]); grid on; legend(labels,'Interpreter','none','Location','best');
        exportgraphics(fig,fullfile(folder,[stem '.png']),'Resolution',300); savefig(fig,fullfile(folder,[stem '.fig'])); close(fig);
    end
function plotController(folder,controllerID,path,r)
        data=readmatrix(fullfile(path,'integration_trajectory.csv'),'NumHeaderLines',1);
        col=@(name) data(:,1+find(strcmp(r.signals,name)));
        fig=figure('Visible','off','Color','w','Position',[100 100 1100 750]); tiledlayout(4,1);
        nexttile; plot(data(:,1)/3600,col('air_K')-273.15); yline(20.5,'k:'); yline(21.5,'k:'); ylabel('Air (°C)'); grid on;
        nexttile; stairs(data(:,1)/3600,col('demand')); ylabel('Demand'); grid on;
        nexttile; plot(data(:,1)/3600,col('opening')); ylabel('Opening'); grid on;
        nexttile; plot(data(:,1)/3600,col('delivered_W')); ylabel('Heat (W)'); xlabel('Elapsed time (h)'); grid on;
        sgtitle(['Controller evidence: ' controllerID],'Interpreter','none');
        exportgraphics(fig,fullfile(folder,'C_controller.png'),'Resolution',300); savefig(fig,fullfile(folder,'C_controller.fig')); close(fig);
    end
