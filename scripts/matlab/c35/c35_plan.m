function [cases,plan]=c35_plan()
%C35_PLAN One-factor changes only; baseline untouched, A evaluated first.
root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
plan=jsondecode(fileread(fullfile(root,'configs','c35','investigation.json')));
assert(plan.schema_version==1 && strcmp(plan.classification, ...
    'illustrative_C35_one_factor_study_not_reference_validation'),'THERMA:C35Plan','Wrong study plan.');
assert(isequal(plan.UA_W_K(:)',[60 90 120 180]) && isequal(plan.supply_degC(:)',[40 45 55 65]) && ...
    isequal(plan.outdoor_degC(:)',[-5 0 5 10]) && isequal(plan.max_steps_s(:)',[10 5 1]), ...
    'THERMA:C35Plan','Review changed study factors explicitly.');
assert(numel(plan.solar.surface_weights)==6 && all(plan.solar.surface_weights>=0) && ...
    abs(sum(plan.solar.surface_weights)-1)<1e-12 && plan.solar.peak_total_W>0, ...
    'THERMA:C35Solar','Invalid absorbed-solar allocation.');
assert(plan.solar.time_fraction(1)==0 && plan.solar.time_fraction(end)==1 && ...
    all(diff(plan.solar.time_fraction)>0) && numel(plan.solar.relative_power)==numel(plan.solar.time_fraction) && ...
    all(plan.solar.relative_power>=0),'THERMA:C35Solar','Invalid profile time/shape.');
base=struct('id','baseline','group','A','UA_W_K',60,'supply_K',328.15,'outdoor_K',278.15, ...
    'initial_zone_K',288.15,'initial_radiator_K',288.15,'max_step_s',10,'solar',false, ...
    'purpose','C3.4 baseline reproduction; no sizing guarantee');
cases=base;
for ua=[90 120 180]
    c=base; c.id=sprintf('A_UA_%d',ua); c.UA_W_K=ua; cases(end+1)=c; %#ok<AGROW>
end
for supply=[40 45 65]
    c=base; c.id=sprintf('B_supply_%d',supply); c.group='B'; c.supply_K=supply+273.15; cases(end+1)=c; %#ok<AGROW>
end
for outdoor=[-5 0 10]
    c=base; c.id=sprintf('D_outdoor_%+d',outdoor); c.id=strrep(strrep(c.id,'-','minus'),'+','plus');
    c.group='D'; c.outdoor_K=outdoor+273.15; cases(end+1)=c; %#ok<AGROW>
end
c=base; c.id='E_solar'; c.group='E'; c.solar=true; cases(end+1)=c;
end
