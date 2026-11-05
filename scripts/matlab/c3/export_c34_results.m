function export_c34_results(folder,time,y,info,D)
%EXPORT_C34_RESULTS Actual traces only, including original duplicate event times.
I=info.experiment; names=info.signals; s=@(name) y(:,find(strcmp(names,name),1));
% Stage a modest integration trace on the local filesystem before network copying.
staging=[tempname '.csv']; cleanup=onCleanup(@() removeStaging(staging));
write_c34_csv(staging,time,y,names);
file=fullfile(folder,'integration_trajectory.csv');
assert(~isfile(file),'THERMA:C34Overwrite','Refusing to overwrite an integration trace.');
[ok,message]=copyfile(staging,file); assert(ok,'THERMA:C34Export','CSV copy failed: %s',message);
assert(strcmp(boptest_file_sha256(file),boptest_file_sha256(staging)), ...
    'THERMA:C34Export','Copied integration trace hash mismatch.');
write_boptest_json(fullfile(folder,'trajectory_metadata.json'),struct('rows',numel(time), ...
    'columns',{{'time_s',names{:}}},'sha256',boptest_file_sha256(file), ...
    'time_basis','elapsed simulation seconds','event_order_and_duplicates_preserved',true));
hours=time/3600;
fig=figure('Visible','off','Color','w','Position',[100 100 1200 850]); tiledlayout(3,2,'TileSpacing','compact');
nexttile; plot(hours,s('air_K')-273.15,'b',hours,s('setpoint_K')-273.15,'k--');
ylabel('Air / setpoint (°C)'); legend('Air','Setpoint','Location','best'); grid on;
nexttile; stairs(hours,s('demand'),'k'); ylabel('Thermostat demand'); ylim([-0.1 1.1]); grid on;
nexttile; plot(hours,s('opening'),'b'); ylabel('Valve opening'); ylim([-0.05 1.05]); grid on;
nexttile; plot(hours,s('radiator_K')-273.15,'r',hours,s('air_K')-273.15,'b', ...
    hours,s('opaque_mean_K')-273.15,'k:');
ylabel('Temperature (°C)'); legend('Radiator','Air: radiant proxy','Opaque mean: diagnostic','Location','best'); grid on;
nexttile; plot(hours,s('convective_W'),hours,s('radiative_W'),hours,s('delivered_W'));
ylabel('Delivered power (W)'); legend('Convective','Radiative','Total','Location','best'); grid on;
nexttile; plot(hours,s('delivered_J')/3.6e6,hours,s('water_J')/3.6e6);
ylabel('Signed thermal energy (kWh)'); legend('Delivered to zone','From water','Location','best'); grid on;
for k=1:6, nexttile(k); xlabel('Elapsed time (h)'); end
sgtitle('C3.4 illustrative closed-loop integration — not reference validation');
finishFigure(fig,folder,'closed_loop_traces');
zoneChange=s('zone_stored_J')-y(1,strcmp(names,'zone_stored_J'));
radChange=s('radiator_stored_J')-y(1,strcmp(names,'radiator_stored_J'));
fig=figure('Visible','off','Color','w','Position',[100 100 1100 700]); tiledlayout(2,2,'TileSpacing','compact');
nexttile; plot(hours,s('water_J')-s('delivered_J')-radChange); ylabel('Radiator energy error (J)'); grid on;
nexttile; plot(hours,s('external_J')-zoneChange-radChange); ylabel('Combined energy error (J)'); grid on;
nexttile; plot(hours,s('radiator_residual_W'),hours,s('zone_residual_W'),hours,s('combined_residual_W'));
ylabel('Instantaneous residual (W)'); legend('Radiator','Zone','Combined','Location','best'); grid on;
nexttile; plot(hours,s('water_W'),hours,s('environment_W')); ylabel('External power (W)');
legend('Water input','Environment into zone','Location','best'); grid on;
for k=1:4, nexttile(k); xlabel('Elapsed time (h)'); end
sgtitle('C3.4 numerical energy accounting — native energy integrators');
finishFigure(fig,folder,'energy_balances');
fid=fopen(fullfile(folder,'engineering_report.md'),'w','n','UTF-8');
assert(fid>=0,'THERMA:C34Report','Cannot create integration report.');
closeReport=onCleanup(@() fclose(fid));
fprintf(fid,'# C3.4 illustrative integration: %s\n\n',D.status);
fprintf(fid,'Actual execution: MATLAB %s. No reference or real-world validation.\n\n',info.matlab_version);
fprintf(fid,'Initial air/fabric %.2f °C; radiator %.2f °C; setpoint %.2f °C; supply %.2f °C; outdoor %.2f °C.\n', ...
    I.initial_zone_K-273.15,I.initial_radiator_K-273.15,I.setpoint_K-273.15,I.supply_K-273.15,I.outdoor_K-273.15);
fprintf(fid,'Internal convective/radiative gains %.9g / %.9g W. Six absorbed solar gains: %s W.\n', ...
    I.internal_convective_W,I.internal_radiative_W,mat2str(I.solar_W));
fprintf(fid,'Heating enabled initially: %d; scheduled disable time: %s s.\n',I.heating_enabled,mat2str(I.disable_at_s));
fprintf(fid,'Duration %.9g s, maximum solver step %.9g s, %s, RelTol %s, AbsTol %s.\n\n', ...
    I.duration_s,I.max_step_s,I.solver.name,I.solver.RelTol,I.solver.AbsTol);
fprintf(fid,'Observed air range %.6f–%.6f °C; final %.6f °C. Radiator sizing/setpoint attainment is not assumed.\n', ...
    D.air_min_K-273.15,D.air_max_K-273.15,y(end,strcmp(names,'air_K'))-273.15);
fprintf(fid,'Maximum absolute delivered heat %.9g W; signed delivered energy %.9g J; water input %.9g J.\n\n', ...
    D.maximum_abs_delivered_W,D.delivered_final_J,D.water_final_J);
fprintf(fid,'Radiator integrated error max %.9g J; combined max %.9g J, final %.9g J; numerical budget %.9g J.\n', ...
    D.radiator_integrated_error_max_J,D.combined_integrated_error_max_J,D.combined_integrated_error_final_J,D.energy_budget_J);
fprintf(fid,'Instantaneous radiator/zone/combined residual maxima: %.9g / %.9g / %.9g W.\n', ...
    D.radiator_residual_max_W,D.zone_residual_max_W,D.combined_residual_max_W);
fprintf(fid,'Heating-port mismatch maximum: %.9g W. No prescribed BOPTEST radiator heat is connected.\n\n',D.heating_port_mismatch_max_W);
fprintf(fid,['Radiative transfer uses the verified air-temperature proxy, not exact mean radiant temperature. ' ...
    'Radiative power is deposited once through unchanged C2 area-weighted surface gains. ' ...
    'The proxy can alter local exchange/passivity; global energy closure does not validate this approximation.\n\n' ...
    'Illustrative mixed radiator, linear UA, imposed flow and fixed supply remain assumptions. ' ...
    'Water heat is not boiler fuel/electric input. Closure must not suppress signed storage release.\n\n' ...
    'Component evidence was supplied from R2025a. This report records the current execution release separately. ' ...
    'C3.5/C3.6 and C4 are not executed by this runner; review these integration results first.\n']);
fprintf(fid,'\n![Closed-loop traces](closed_loop_traces.png)\n\n![Energy balances](energy_balances.png)\n');
end
function finishFigure(fig,folder,name)
cleanup=onCleanup(@() close(fig));
exportgraphics(fig,fullfile(folder,[name '.png']),'Resolution',300);
savefig(fig,fullfile(folder,[name '.fig']));
end
function removeStaging(file)
if isfile(file), delete(file); end
end
