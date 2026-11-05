function [model,file,info]=c35_build_case(c,plan,outputParent,duration)
%C35_BUILD_CASE Modify only newly generated case workspaces/sources, not C3.4 code.
I=load_c34_experiment();
I.supply_K=c.supply_K; I.outdoor_K=c.outdoor_K; I.max_step_s=c.max_step_s;
I.initial_zone_K=c.initial_zone_K; I.initial_radiator_K=c.initial_radiator_K;
if nargin>=4, I.duration_s=duration; end
if c.solar
    I.solar_W=reshape(plan.solar.surface_weights,1,6)*plan.solar.peak_total_W;
end
[model,file,info]=build_c34_model(I,outputParent);
try
    workspace=get_param(model,'ModelWorkspace'); P=getVariable(workspace,'C3');
    P.UA_W_K=c.UA_W_K; assignin(workspace,'C3',P);
    if c.solar
        time=plan.solar.time_fraction(:)*I.duration_s;
        data=plan.solar.relative_power(:)*I.solar_W;
        series=timeseries(data,time); series=setinterpmethod(series,'linear');
        assignin(workspace,'C35_solar',series);
        location=get_param([model '/Solar_W'],'Position');
        delete_line(model,'Solar_W/1','Zone_inputs/6'); delete_block([model '/Solar_W']);
        add_block('simulink/Sources/From Workspace',[model '/Solar_W'],'Position',location, ...
            'VariableName','C35_solar','SampleTime','0','Interpolate','on', ...
            'OutputAfterFinalValue','Holding final value');
        add_line(model,'Solar_W/1','Zone_inputs/6','autorouting','on');
    end
    % New diagnostic integrators have no feedback into the unchanged physical graph.
    names=info.signals; ports=[10 4 6 7]; labels={'solar','exterior','ventilation','window'};
    originalCount=numel(names); set_param([model '/Diagnostics'],'Inputs',num2str(originalCount+8));
    for k=1:4
        name=[labels{k} '_energy_J'];
        add_block('simulink/Continuous/Integrator',[model '/' name],'InitialCondition','0', ...
            'Position',[1140 850+60*k 1240 885+60*k]);
        add_line(model,sprintf('Thermal_zone/%d',ports(k)),[name '/1'],'autorouting','on');
        add_line(model,sprintf('Thermal_zone/%d',ports(k)),sprintf('Diagnostics/%d',originalCount+2*k-1),'autorouting','on');
        add_line(model,[name '/1'],sprintf('Diagnostics/%d',originalCount+2*k),'autorouting','on');
        names=[names {[labels{k} '_W'],[labels{k} '_J']}]; %#ok<AGROW>
    end
    info.signals=names; info.effective_components=rmfield(P,'assumptions');
    info.case_definition=c; info.solar_profile=plan.solar;
    info.solar_metadata_note='For solar case I.solar_W is peak envelope; actual forcing is saved C35_solar timeseries.';
    save_system(model,file); info.model_file=file;
    write_boptest_json(fullfile(fileparts(file),'c35_build.json'),info);
catch problem
    close_system(model,0); rethrow(problem);
end
end
