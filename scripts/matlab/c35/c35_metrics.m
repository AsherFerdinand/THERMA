function M=c35_metrics(time,y,info,D,plan)
%C35_METRICS Observed engineering quantities; energies from native integral states.
names=info.signals; s=@(name) y(:,find(strcmp(names,name),1)); P=info.effective_components;
M=c35_time_metrics(time,s('air_K'),s('setpoint_K'),P.deadband_K);
M.case_id=info.case_definition.id; M.group=info.case_definition.group;
M.UA_W_K=P.UA_W_K; M.supply_degC=info.experiment.supply_K-273.15;
M.outdoor_degC=info.experiment.outdoor_K-273.15; M.max_step_s=info.experiment.max_step_s;
demand=s('demand'); opening=s('opening'); changes=diff(demand);
M.thermostat_transitions=sum(changes~=0); M.on_events=sum(changes>0); M.off_events=sum(changes<0);
M.initial_heating_active=demand(1)==1;
M.peak_delivered_W=max(s('delivered_W')); M.maximum_absolute_delivered_W=max(abs(s('delivered_W')));
M.delivered_kWh=last(s('delivered_J'))/3.6e6; M.water_kWh=last(s('water_J'))/3.6e6;
M.solar_kWh=last(s('solar_J'))/3.6e6;
M.exterior_loss_kWh=-last(s('exterior_J'))/3.6e6;
M.ventilation_loss_kWh=-last(s('ventilation_J'))/3.6e6;
M.window_loss_kWh=-last(s('window_J'))/3.6e6;
M.zone_storage_change_kWh=(last(s('zone_stored_J'))-y(1,strcmp(names,'zone_stored_J')))/3.6e6;
M.radiator_storage_change_kWh=(last(s('radiator_stored_J'))-y(1,strcmp(names,'radiator_stored_J')))/3.6e6;
M.radiator_integrated_residual_J=D.radiator_integrated_error_max_J;
M.combined_integrated_residual_J=D.combined_integrated_error_max_J;
M.maximum_instantaneous_residual_W=max([D.radiator_residual_max_W D.zone_residual_max_W D.combined_residual_max_W]);
% Verify hysteresis using post-event samples at each actual controller instant.
previous=P.controller_initial; checked=0; violations=0;
controllerTick=round(time/P.controller_period_s); distance=abs(time-controllerTick*P.controller_period_s);
eligible=find(distance<=1e-6);
ordered=sortrows([controllerTick(eligible),distance(eligible),-eligible],[1 2 3]);
[keys,first]=unique(ordered(:,1),'first'); chosen=-ordered(first,3);
for index=1:numel(chosen)
    k=chosen(index);
    error=y(k,strcmp(names,'setpoint_K'))-y(k,strcmp(names,'air_K'));
    if error>=P.deadband_K/2, expected=1;
    elseif error<=-P.deadband_K/2, expected=0;
    else, expected=previous; end
    violations=violations+(demand(k)~=expected); checked=checked+1; previous=expected;
end
M.controller_samples_checked=checked; M.hysteresis_violations=violations;
M.controller_coverage_passed=isequal(keys,(0:floor(info.experiment.duration_s/P.controller_period_s))');
expected=P.valve_initial; maxError=abs(expected-opening(1));
for k=1:numel(time)-1
    if demand(k)>=expected, tau=P.opening_tau_s; else, tau=P.closing_tau_s; end
    expected=demand(k)+(expected-demand(k))*exp(-(time(k+1)-time(k))/tau);
    maxError=max(maxError,abs(expected-opening(k+1)));
end
M.valve_analytic_max_error=maxError;
off=demand(1:end-1)==0;
M.heat_during_off_kWh=sum(diff(s('delivered_J')).*off)/3.6e6;
M.water_heat_during_off_kWh=sum(diff(s('water_J')).*off)/3.6e6;
M.storage_release_during_off_kWh=-sum(diff(s('radiator_stored_J')).*off)/3.6e6;
near=off & opening(1:end-1)<=plan.near_closed_opening;
M.near_closed_warming_intervals=sum(near & diff(s('air_K'))>0 & diff(s('radiator_stored_J'))<0);
M.behavior_checks_passed=violations==0 && M.controller_coverage_passed && ...
    maxError<=plan.valve_reconstruction_tolerance;
M.checks_passed=strcmp(D.status,'integration_numerical_checks_passed') && M.behavior_checks_passed;
% Late slope uses a uniform grid, not adaptive output-density weighting.
uniqueMask=[diff(time)>0;true]; t=time(uniqueMask); air=s('air_K'); air=air(uniqueMask);
grid=linspace(max(t(1),t(end)-21600),t(end),361)';
fit=polyfit((grid-grid(1))/3600,interp1(t,air,grid,'linear'),1); M.late_slope_K_h=fit(1);
end
function value=last(values)
value=values(end);
end
