function [time,values,info,D]=simulate_c34_model(I,outputParent)
%SIMULATE_C34_MODEL Execute the new native feedback model, never a replay.
if nargin<1, I=load_c34_experiment(); end
if nargin<2
    root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
    outputParent=fullfile(root,'outputs','c3','integration');
end
[model,file,info]=build_c34_model(I,outputParent); info.model_file=file;
cleanup=onCleanup(@() close_system(model,0));
set_param(model,'SimulationCommand','update');
start=tic; output=sim(Simulink.SimulationInput(model)); info.elapsed_simulation_s=toc(start);
logged=output.get('c34_signals'); time=logged.Time(:); values=reshape(logged.Data,numel(time),[]);
D=assess_c34(time,values,info.signals,I,info.effective_components);
% Inspect every C2 temperature state, not just the air/opaque-mean diagnostics.
states=output.get('T_states_K'); stateValues=states.Data;
D.checks.all_zone_states_finite_positive=~isempty(stateValues) && all(isfinite(stateValues),'all') && all(stateValues>0,'all');
if D.passive_zero_gain_envelope_checked
    low=min([I.outdoor_K I.initial_zone_K I.initial_radiator_K I.supply_K]);
    high=max([I.outdoor_K I.initial_zone_K I.initial_radiator_K I.supply_K]);
    D.checks.all_zone_states_passive=all(stateValues>=low-I.checks.temperature_envelope_margin_K & ...
        stateValues<=high+I.checks.temperature_envelope_margin_K,'all');
end
if all(structfun(@(v) logical(v),D.checks)), D.status='integration_numerical_checks_passed';
else, D.status='integration_numerical_checks_failed'; end
info.status='executed_in_MATLAB_integration_checks_recorded';
info.MATLAB_execution_completed=true; info.matlab_version=version; info.simulink=ver('Simulink');
write_boptest_json(fullfile(fileparts(file),'integration_diagnostics.json'),D);
end
