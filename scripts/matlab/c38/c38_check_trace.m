function C=c38_check_trace(t,y,info)
%C38_CHECK_TRACE Reuse numerical, hysteresis and analytic-valve verification.
[~,plan]=c35_plan(); P=info.effective_components; I=info.experiment; names=info.signals;
D=assess_c34(t,y,names,I,P); full=c35_metrics(t,y,info,D,plan);
assert(full.checks_passed,'THERMA:C38Checks','Existing energy/controller/valve checks failed.');
s=@(name) y(:,find(strcmp(names,name),1));
assert(all(abs(s('setpoint_K')-294.15)<1e-9), ...
    'THERMA:C38Setpoint','Expected21 C setpoint.');
assert(abs(y(1,strcmp(names,'air_K'))-I.initial_zone_K)<1e-9 && ...
    abs(y(1,strcmp(names,'radiator_K'))-I.initial_radiator_K)<1e-9, ...
    'THERMA:C38Initial','Initial air/radiator differ.');
radiatorError=max(abs(s('delivered_W')-P.UA_W_K*(s('radiator_K')-s('air_K'))));
waterError=max(abs(s('water_W')-s('mass_flow_kg_s')*P.water_cp_J_kgK.*(I.supply_K-s('radiator_K'))));
assert(max(radiatorError,waterError)<1e-6,'THERMA:C38Power','Radiator/water equation mismatch.');
M=c38_interval_metrics(t,s('air_K'),s('setpoint_K'),s('delivered_J'),s('demand'),P.deadband_K);
C=struct('time',t,'air_K',s('air_K'),'demand',s('demand'),'metrics',M,'full_day_metrics',full, ...
    'diagnostics',D,'power_equation_error_max_W',max(radiatorError,waterError), ...
    'names',{names});
end
