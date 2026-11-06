function folder=run_c37_residential_heating()
%RUN_C37_RESIDENTIAL_HEATING One24h native Simulink run, using existing components.
root=fileparts(mfilename('fullpath'));
addpath(fullfile(root,'scripts','matlab','c37'),fullfile(root,'scripts','matlab','c35'), ...
    fullfile(root,'scripts','matlab','c3'),fullfile(root,'scripts','matlab','boptest'));
[Z,room]=c37_room_parameters(); [P,rating]=c37_radiator_parameters();
% User-supplied rating/source hash is checked before model construction.
steady=c37_steady_demand(Z,P,room);
fprintf('Purmo rating match %.1f W; UA %.3f W/K; flow %.6f kg/s; capacitance %.0f J/K\n', ...
    rating.model_output_at_rating_W,P.UA_W_K,P.nominal_flow_kg_s,P.capacitance_J_K);
fprintf('Static room demand %.1f W; radiator at21 C %.1f W. Mass inclusion is unresolved; see report.\n', ...
    steady.required_heat_at_setpoint_W,steady.available_heat_at_setpoint_W);
[~,plan]=c35_plan(); a=room.conditions;
c=struct('id','C37_residential','group','C37','UA_W_K',P.UA_W_K,'supply_K',a.supply_C+273.15, ...
    'outdoor_K',a.outdoor_C+273.15,'initial_zone_K',a.air_initial_C+273.15, ...
    'initial_radiator_K',a.radiator_initial_C+273.15,'max_step_s',10,'solar',false, ...
    'purpose','Single illustrative residential room; separate from BESTEST');
parent=fullfile(root,'outputs','c3','c37'); if ~isfolder(parent), mkdir(parent); end
folder=tempname(parent); mkdir(folder);
% Verify all previous physical/config files byte-for-byte before/after the run.
fixed=[dir(fullfile(root,'scripts','matlab','c3','*.m'));dir(fullfile(root,'scripts','matlab','c35','*.m')); ...
    dir(fullfile(root,'scripts','matlab','boptest','*.m'));dir(fullfile(root,'configs','references','*.json')); ...
    dir(fullfile(root,'configs','c3','*.json'))];
hashes=cell(numel(fixed),1);
for k=1:numel(fixed), hashes{k}=boptest_file_sha256(fullfile(fixed(k).folder,fixed(k).name)); end
[model,file,info]=c35_build_case(c,plan,folder,a.duration_s);
cleanup=onCleanup(@() closeIfLoaded(model));
try
    workspace=get_param(model,'ModelWorkspace');
    P.radiator_initial_K=a.radiator_initial_C+273.15;
    I=info.experiment; I.setpoint_K=a.setpoint_C+273.15; I.internal_convective_W=0; I.internal_radiative_W=0; I.solar_W=zeros(1,6);
    assignin(workspace,'Z',Z); assignin(workspace,'C3',P); assignin(workspace,'C34',I);
    info.experiment=I; info.frozen_registry_sha256=''; info.residential_config_sha256=Z.residential_config_sha256;
    zone=[model '/Thermal_zone'];
    add_block('simulink/Sources/Constant',[zone '/Adjacent_K'],'Value',num2str(a.adjacent_C+273.15,17), ...
        'Position',[20 400 100 430]);
    for name={'North_Wall','West_Wall'}
        target=['Exterior_Convection_' name{1} '/1'];
        delete_line(zone,'Outdoor_K/1',target); add_line(zone,'Adjacent_K/1',target,'autorouting','on');
    end
    % Existing roof H=0 and floor adiabatic exterior implement explicit symmetry boundaries.
    % No thermostat/valve/radiator blocks, equations or solver settings are changed.
    file=fullfile(fileparts(file),'THERMA_C37_Residential.slx'); save_system(model,file);
    clear cleanup; % Close the old name if save-as kept it loaded.
    model='THERMA_C37_Residential'; cleanup=onCleanup(@() closeIfLoaded(model));
    if ~bdIsLoaded(model), load_system(file); end
    info.model_file=file; info.effective_components=rmfield(P,'assumptions');
    write_boptest_json(fullfile(fileparts(file),'c37_build.json'),struct('status','generated_not_verified', ...
        'room',room,'radiator_rating',rating,'steady_demand',steady,'model_file', 'THERMA_C37_Residential.slx', ...
        'room_config_sha256',Z.residential_config_sha256,'interpretation','New residential parameters, not BESTEST'));
    set_param(model,'SimulationCommand','update'); output=sim(Simulink.SimulationInput(model));
    series=output.get('c34_signals'); t=series.Time(:); y=reshape(series.Data,numel(t),[]);
    info.effective_components=rmfield(P,'assumptions');
    D=assess_c34(t,y,info.signals,info.experiment,info.effective_components);
    M=c35_metrics(t,y,info,D,plan);
    for k=1:numel(fixed)
        assert(strcmp(hashes{k},boptest_file_sha256(fullfile(fixed(k).folder,fixed(k).name))), ...
            'THERMA:C37Preservation','Existing source/config changed.');
    end
    states=output.get('T_states_K');
    assert(all(isfinite(states.Data),'all') && all(states.Data>0,'all'), ...
        'THERMA:C37States','Invalid zone states.');
    assert(M.checks_passed,'THERMA:C37Checks','Energy/controller/valve checks failed.');
    names=info.signals; s=@(name) y(:,find(strcmp(names,name),1));
    % Existing radiator constitutive relation is checked on actual output samples.
    powerError=max(abs(s('delivered_W')-P.UA_W_K*(s('radiator_K')-s('air_K'))));
    waterError=max(abs(s('water_W')-s('mass_flow_kg_s')*P.water_cp_J_kgK.*(I.supply_K-s('radiator_K'))));
    assert(max(powerError,waterError)<1e-6,'THERMA:C37Power','Radiator/water constitutive relation failed.');
    writetable(array2table([t y],'VariableNames',[{'time_s'} reshape(names,1,[])]), ...
        fullfile(folder,'residential_trajectory.csv'));
    result=struct('status','executed_numerically_checked_not_real_world_validated', ...
        'matlab_version',version,'room',room,'radiator_rating',rating,'effective_components',info.effective_components, ...
        'steady_demand',steady,'metrics',M,'diagnostics',D,'power_equation_error_max_W',powerError,'water_equation_error_max_W',waterError,'existing_sources_preserved',true, ...
        'room_config_sha256',Z.residential_config_sha256,'model_sha256',boptest_file_sha256(file));
    fig=figure('Color','w','Visible','off'); plot(t/3600,s('air_K')-273.15,'LineWidth',1.3); hold on;
    yline(a.setpoint_C,'k--','Setpoint');
    if M.reach_21_0_s>=0, xline(M.reach_21_0_s/3600,'r:','First21 C'); end
    xlabel('Elapsed time (h)'); ylabel('Indoor temperature (°C)'); grid on;
    savePlot(fig,fullfile(folder,'room_heating.png'));
    fig=figure('Color','w','Visible','off'); yyaxis left;
    plot(t/3600,s('delivered_W'),'LineWidth',1); ylabel('Radiator heat (W)'); yyaxis right;
    stairs(t/3600,s('demand')); ylabel('Thermostat demand'); ylim([-0.05 1.05]);
    xlabel('Elapsed time (h)'); grid on; savePlot(fig,fullfile(folder,'heating_system.png'));
    report=fullfile(root,'docs','C37_RESIDENTIAL_HEATING.md');
    text=fileread(report); marker='<!-- C37_RESULTS -->'; at=strfind(text,marker);
    assert(numel(at)==1,'THERMA:C37Report','Report results marker missing.');
    reached='Not reached in24h'; if M.reach_21_0_s>=0, reached=sprintf('%.3f h',M.reach_21_0_s/3600); end
    actual=sprintf(['\n\nActual MATLAB %s execution. First21 °C: **%s**; final air %.3f °C; ' ...
        'delivered heat **%.3f kWh**; peak radiator %.1f W; thermostat transitions %d. ' ...
        'Native energy balances/hysteresis/valve checks passed. Maximum combined integral residual %.6g J ' ...
        '(allowed %.6g J). Original sources/configs unchanged.\n\n' ...
        'Output directory: `%s`. Contains exactly two plots, original trajectory and structured numerical report. ' ...
        'Passing numerical checks does not establish real-world accuracy.\n'],version,reached,M.final_air_degC, ...
        M.delivered_kWh,M.peak_delivered_W,M.thermostat_transitions,D.combined_integrated_error_max_J, ...
        D.energy_budget_J,strrep(erase(folder,[root filesep]),filesep,'/'));
    fid=fopen(report,'w','n','UTF-8'); assert(fid>=0,'THERMA:C37Report','Cannot write report.');
    fileCleanup=onCleanup(@() fclose(fid)); fprintf(fid,'%s', [text(1:at+numel(marker)-1) actual]);
    clear fileCleanup;
    result.trajectory_sha256=boptest_file_sha256(fullfile(folder,'residential_trajectory.csv'));
    result.plots={'room_heating.png','heating_system.png'};
    write_boptest_json(fullfile(folder,'residential_result.json'),result);
    fprintf('C3.7: %s\nFirst21 C: %s; delivered %.3f kWh\n',folder,reached,M.delivered_kWh);
catch problem
    write_boptest_json(fullfile(folder,'failure.json'),struct('status','failed', ...
        'matlab_version',version,'error',boptest_exception_diagnostic(problem)));
    rethrow(problem);
end
end
function closeIfLoaded(model)
if bdIsLoaded(model), close_system(model,0); end
end
function savePlot(fig,file)
cleanup=onCleanup(@() close(fig)); exportgraphics(fig,file,'Resolution',200);
end
