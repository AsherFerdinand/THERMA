function reportFile=run_c36_physical_check(studyFile)
%RUN_C36_PHYSICAL_CHECK Read existing C3.5 cases; static checks only, NO simulations.
root=fileparts(mfilename('fullpath'));
addpath(fullfile(root,'scripts','matlab','c36'),fullfile(root,'scripts','matlab','c35'), ...
    fullfile(root,'scripts','matlab','c3'),fullfile(root,'scripts','matlab','boptest'));
S=c36_specs(); reportFile=fullfile(root,'docs','C36_PHYSICAL_CHECK.md');
if nargin<1 || strlength(string(studyFile))==0
    candidates=[dir(fullfile(root,'outputs','c3','c35','*','study_capacity.json')); ...
        dir(fullfile(root,'outputs','c3','c35','*','study_all.json'))];
    chosen={}; signatures={};
    for k=1:numel(candidates)
        file=fullfile(candidates(k).folder,candidates(k).name); study=jsondecode(fileread(file));
        if isempty(study.cases), continue; end
        ids={study.cases.id}; a=find(strcmp(ids,'baseline')); b=find(strcmp(ids,'A_UA_180'));
        if numel(a)==1 && numel(b)==1
            signature=[study.cases(a).completion_sha256 study.cases(b).completion_sha256];
            if ~any(strcmp(signatures,signature)), chosen{end+1}=file; signatures{end+1}=signature; end %#ok<AGROW>
        end
    end
    if isempty(chosen)
        writeReport(reportFile,S,{},'');
        warning('THERMA:C36MissingData',['Static report written, but the existing baseline/A_UA_180 data are absent. ' ...
            'Copy the completed C3.5 study/data tree here or pass its study JSON path. No simulation was run.']);
        return;
    end
    assert(numel(chosen)==1,'THERMA:C36Study','Several distinct pairs exist; pass the intended study JSON path explicitly.');
    studyFile=chosen{1};
end
study=jsondecode(fileread(studyFile)); contractFile=fullfile(fileparts(studyFile),'study_contract.json');
assert(strcmp(boptest_file_sha256(contractFile),study.study_contract_sha256),'THERMA:C36Contract','Study contract changed.');
contract=jsondecode(fileread(contractFile));
assert(strcmp(contract.component_config_sha256,boptest_file_sha256(fullfile(root,'configs','c3','illustrative_components.json'))), ...
    'THERMA:C36Inputs','Component defaults differ from recorded study.');
recorded=[contract.physics_sources(:);contract.sources(:)];
for k=1:numel(recorded)
    item=recorded(k);
    assert(strcmp(boptest_file_sha256(fullfile(root,item.name)),item.sha256), ...
        'THERMA:C36Inputs','Recorded source changed: %s',item.name);
end
ids={'baseline','A_UA_180'}; curves=cell(1,2); expectedUA=[60 180];
for k=1:2, curves{k}=readCase(studyFile,study,ids{k},expectedUA(k)); end
assert(strcmp(curves{1}.release,curves{2}.release),'THERMA:C36Release','Do not mix releases.');
parent=fullfile(root,'outputs','c3','c36'); if ~isfolder(parent), mkdir(parent); end
folder=tempname(parent); mkdir(folder);
fig=figure('Visible','off','Color','w','Position',[100 100 1050 440]); hold on;
for k=1:2, plot(curves{k}.time/3600,curves{k}.air-273.15,'LineWidth',1.3); end
yline(21,'k--','21 °C'); xlabel('Elapsed time (h)'); ylabel('Indoor air temperature (°C)');
legend('UA 60 W/K','UA 180 W/K','Location','best'); grid on; title('Existing C3.5 cold-start results');
finish(fig,fullfile(folder,'temperature.png'));
fig=figure('Visible','off','Color','w','Position',[100 100 1050 440]); hold on;
colors={'b','r'};
for k=1:2
    c=curves{k}; plot(c.time/3600,c.power,colors{k},'LineWidth',1.2);
    estimate=S.approximate_H_W_K*(c.air-278.15);
    plot(c.time/3600,estimate,[colors{k} '--'],'LineWidth',1.0);
end
xlabel('Elapsed time (h)'); ylabel('Thermal power (W)'); grid on;
legend('UA60 radiator','UA60 steady HΔT estimate','UA180 radiator','UA180 steady HΔT estimate','Location','best');
title('Radiator heat versus approximate steady building loss (HΔT)');
finish(fig,fullfile(folder,'power_and_loss.png'));
summary=struct('specifications',S,'cases',{{curves{1}.budget,curves{2}.budget}}, ...
    'source_study_sha256',boptest_file_sha256(studyFile),'matlab_version',version, ...
    'new_simulations',0,'power_plot_loss_basis','Approximate steady H*(air-outdoor); native energy states define the actual loss budget','plots',{{'temperature.png','power_and_loss.png'}});
write_boptest_json(fullfile(folder,'physical_check.json'),summary);
writeReport(reportFile,S,curves,strrep(erase(folder,[root filesep]),filesep,'/'));
fprintf('C3.6 report: %s\nTwo plots: %s\nNo simulation was performed.\n',reportFile,folder);
end
function C=readCase(studyFile,study,id,ua)
entry=study.cases(strcmp({study.cases.id},id));
assert(numel(entry)==1,'THERMA:C36Case','Required existing case missing: %s',id);
relative=entry.folder;
assert(~startsWith(relative,'/') && ~contains(relative,{'\',':'}) && ...
    ~any(strcmp(strsplit(relative,'/'),'..')),'THERMA:C36Path','Unsafe case folder.');
folder=fullfile(fileparts(studyFile),strrep(relative,'/',filesep));
receiptFile=fullfile(folder,'completion.json');
assert(strcmp(boptest_file_sha256(receiptFile),entry.completion_sha256),'THERMA:C36Hash','Receipt changed.');
r=jsondecode(fileread(receiptFile));
assert(strcmp(r.status,'completed') && strcmp(r.expected.study_contract_sha256,study.study_contract_sha256), ...
    'THERMA:C36Case','Incomplete/mixed study case.');
for name={'case_result.json','integration_trajectory.csv'}
    hit=find(strcmp({r.artifacts.name},name{1}));
    assert(numel(hit)==1 && strcmp(boptest_file_sha256(fullfile(folder,name{1})),r.artifacts(hit).sha256), ...
        'THERMA:C36Hash','Changed/missing original case file: %s',name{1});
end
result=jsondecode(fileread(fullfile(folder,'case_result.json'))); c=result.case_definition;
assert(result.metrics.checks_passed && strcmp(result.status,'executed_numerically_checked_not_reference_validated') && ...
    isequal(c,r.expected.case_definition) && c.UA_W_K==ua && c.supply_K==328.15 && c.outdoor_K==278.15 && ...
    c.initial_zone_K==288.15 && c.initial_radiator_K==288.15 && c.max_step_s==10 && ~c.solar, ...
    'THERMA:C36Inputs','Cases must be the original UA-only cold starts, not other boundaries.');
file=fullfile(folder,'integration_trajectory.csv'); fid=fopen(file,'r');
assert(fid>=0,'THERMA:C36Read','Cannot open existing trace.'); cleanup=onCleanup(@() fclose(fid));
header=fgetl(fid); assert(strcmp(header,strjoin([{'time_s'} reshape(result.signals,1,[])],',')), ...
    'THERMA:C36Columns','Trace columns differ from metadata.');
data=readmatrix(file,'NumHeaderLines',1); t=data(:,1); y=data(:,2:end); names=result.signals;
assert(size(y,2)==numel(names) && all(isfinite(data),'all') && all(diff(t)>=0) && ...
    t(1)==0 && t(end)==86400,'THERMA:C36Trace','Incomplete/nonfinite/unordered 24 h trace.');
s=@(name) y(:,find(strcmp(names,name),1));
assert(all(abs(s('setpoint_K')-294.15)<1e-9) && all(abs(s('solar_J'))<1e-6), ...
    'THERMA:C36Inputs','Expected 21 °C setpoint and no absorbed solar.');
M=c35_time_metrics(t,s('air_K'),s('setpoint_K'),1);
first=find(s('air_K')>=294.15,1); reached=~isempty(first);
if ~reached, first=numel(t); end
water=s('water_J'); delivered=s('delivered_J'); storage=s('zone_stored_J'); rad=s('radiator_stored_J');
lossJ=-(s('exterior_J')+s('window_J')+s('ventilation_J'));
budget=struct('case_id',id,'UA_W_K',ua,'reached21',reached,'estimated_reach21_h',M.reach_21_0_s/3600, ...
    'checkpoint_h',t(first)/3600,'delivered_kWh',delivered(first)/3.6e6, ...
    'water_kWh',water(first)/3.6e6,'loss_kWh',lossJ(first)/3.6e6, ...
    'zone_storage_kWh',(storage(first)-storage(1))/3.6e6, ...
    'radiator_storage_kWh',(rad(first)-rad(1))/3.6e6, ...
    'final_air_degC',M.final_air_degC,'maximum_air_degC',M.maximum_air_degC, ...
    'csv_sha256',boptest_file_sha256(file));
if ~reached, budget.estimated_reach21_h=-1; end
budget.energy_error_J=water(first)-lossJ(first)-(storage(first)-storage(1))-(rad(first)-rad(1));
assert(abs(budget.energy_error_J)<=result.diagnostics.energy_budget_J, ...
    'THERMA:C36Energy','Native-state energy budget does not close.');
C=struct('time',t,'air',s('air_K'),'power',s('delivered_W'), ...
    'budget',budget,'release',result.matlab_version);
end
function finish(fig,file)
cleanup=onCleanup(@() close(fig)); exportgraphics(fig,file,'Resolution',300);
end
function writeReport(file,S,curves,folder)
fid=fopen(file,'w','n','UTF-8'); assert(fid>=0,'THERMA:C36Report','Cannot write C3.6 report.');
cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'# C3.6 — Building and radiator reality check\n\n');
fprintf(fid,'## What building?\n\nOne BESTEST heavy benchmark zone, **%.0f m²**, **%.1f m³**, %.0f × %.0f × %.1f m; not a whole house or the 36-room thesis. Window area %.0f m², U %.1f W/(m² K).\n\n', ...
    S.geometry.floor_m2,S.geometry.volume_m3,S.geometry.length_m,S.geometry.width_m,S.geometry.height_m,S.geometry.window_m2,S.window_U_W_m2K);
fprintf(fid,'Wall material R %.4f m² K/W, roof R %.4f; current film-only U estimates %.3f / %.3f W/(m² K). Floor exterior is adiabatic, so it stores heat but has no outdoor loss path.\n\n', ...
    S.components(1).R_total_K_W*S.components(1).area_m2,S.components(5).R_total_K_W*S.components(5).area_m2, ...
    S.opaque_film_only_U_W_m2K(1),S.opaque_film_only_U_W_m2K(5));
fprintf(fid,'Approximate envelope+window+infiltration H **%.1f W/K**. Existing full-network/radiant-split equivalent %.1f W/K: steady heat demand at 21 °C / 5 °C is **%.3f kW**. These are model calculations, not DIN EN 12831 compliance or measured building ratings.\n\n', ...
    S.approximate_H_W_K,S.split_consistent_H_W_K,S.heat_demand_at_21C_outdoor5_W/1000);
fprintf(fid,'## Radiator capacity at 55 °C supply and 21 °C air\n\n');
for k=1:2
    a=S.radiators{k}; fprintf(fid,'- UA %.0f W/K: **%.3f kW** available; margin %.3f kW; conditional full-open steady air %.2f °C; mixed return %.1f °C.\n', ...
        a.UA_W_K,a.available_full_open_heat_at_setpoint_W/1000,a.capacity_margin_at_setpoint_W/1000,a.all_on_steady_air_degC,a.mixed_return_at_air21_degC);
end
fprintf(fid,['\nUsing the existing mixed radiator equation, Q = Hwater*UA/(Hwater+UA)*(55−21), Hwater = 0.03*4180 = 125.4 W/K. ' ...
    'UA 60 is insufficient even at steady state for this boundary condition; UA 180 has steady capacity headroom. ' ...
    'UA is illustrative, not a commercial radiator rating. Increasing UA with unchanged 3 kg water / 20 kg metal is a sensitivity test, not a realistic product resizing rule.\n\n']);
fprintf(fid,'## Why many hours?\n\nFabric capacity is **%.2f MJ/K**; air only %.3f MJ/K. Raising every node by 6 K would store %.1f kWh, versus only %.2f kWh for the air. This is a scale illustration, not actual heat required when air first reaches 21 °C: fabric temperatures are not uniform.\n\n', ...
    S.fabric_capacity_J_K/1e6,S.air_capacity_J_K/1e6,S.uniform_six_K_storage_kWh,S.air_capacity_J_K*6/3.6e6);
if isempty(curves)
    fprintf(fid,['The 16 passed C3.5 tests and approximately 12.5 h warm-up are user-reported; their logs/trajectories were not supplied here. ' ...
        'Large cold concrete mass plus ongoing losses makes that duration plausible, but it is not independently reproduced. ' ...
        'Exact storage-versus-loss contributions and the two plots remain blocked until the existing baseline and A_UA_180 traces are available. No new simulation was performed.\n\n']);
else
    fprintf(fid,'Existing results, MATLAB %s; no new simulation.\n\n| UA W/K | First 21 °C h | Budget checkpoint h | Delivered kWh | Loss kWh | Zone storage kWh | Radiator storage kWh |\n|---|---:|---:|---:|---:|---:|---:|\n',curves{1}.release);
    for k=1:2
        b=curves{k}.budget; hit='not reached'; if b.reached21, hit=sprintf('%.3f',b.estimated_reach21_h); end
        fprintf(fid,'| %.0f | %s | %.3f | %.3f | %.3f | %.3f | %.3f |\n',b.UA_W_K,hit,b.checkpoint_h,b.delivered_kWh,b.loss_kWh,b.zone_storage_kWh,b.radiator_storage_kWh);
    end
    b=curves{2}.budget;
    if b.reached21 && b.delivered_kWh>0
        fprintf(fid,['\nAt UA 180 first reaching 21 °C, net zone storage accounts for %.1f%% and outgoing losses %.1f%% of delivered heat. ' ...
            'These are measured energy shares, not separate fractions of the warm-up duration.\n'], ...
            100*b.zone_storage_kWh/b.delivered_kWh,100*b.loss_kWh/b.delivered_kWh);
    end
    fprintf(fid,['\nBudgets use native cumulative energy states at the first logged sample at/above 21 °C, or 24 h if not reached. ' ...
        'First crossing is interpolated separately. The power plot uses a steady HΔT loss estimate, not instantaneous exterior-layer cooling; actual loss energies come only from native integrators. Loss and storage shares are not separate additive causes of elapsed hours. ' ...
        'For UA 180, steady capacity is sufficient. Losses consume the larger energy share in the supplied case, while fabric mass creates the slow response. Neither is negligible; baseline undersizing is a separate limit.\n\n']);
    fprintf(fid,'![Indoor temperatures](../%s/temperature.png)\n\n![Radiator power and estimated losses](../%s/power_and_loss.png)\n\n',folder,folder);
end
fprintf(fid,['## Limits and C3.7 recommendation\n\nThis is a heavy benchmark cell: thin external foam, concrete walls/slab, U=3 glazing, ' ...
    'a deliberately adiabatic floor and unusual benchmark floor-insulation properties. It is not evidence of a particular real house. ' ...
    'All fabric starts at 15 °C: a deep cold soak, not ordinary reheating with warm walls. Constant surface films, imposed water flow/supply, ' ...
    'linear emitter UA and air-as-radiant-sink remain approximations.\n\n' ...
    'Next, agree on the intended real building and check its construction, ground boundary, initial fabric temperature and a manufacturer radiator rating. ' ...
    'Do not calibrate the benchmark or add nonlinear models until those inputs are established. C3.7 has not started.\n']);
end
