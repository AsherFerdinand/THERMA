function I=load_c34_experiment(file)
%LOAD_C34_EXPERIMENT Explicit integration boundaries; no replay inputs or tuning.
if nargin<1
    root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
    file=fullfile(root,'configs','c3','integration_c34.json');
end
raw=jsondecode(fileread(file));
assert(raw.schema_version==1 && strcmp(raw.classification, ...
    'illustrative_C34_integration_not_BOPTEST_benchmark'),'THERMA:C34Schema','Wrong C3.4 fixture.');
names={'initial_zone_K','initial_radiator_K','setpoint_K','supply_K','outdoor_K', ...
    'internal_convective_W','internal_radiative_W','solar_W','duration_s','max_step_s'};
units={'K','K','K','K','K','W','W','W','s','s'};
for k=1:numel(names)
    e=raw.parameters.(names{k});
    assert(strcmp(e.unit,units{k}) && ~isempty(e.source),'THERMA:C34Units','Wrong unit/source for %s.',names{k});
    validateattributes(e.value,{'numeric'},{'real','finite','nonnegative','nonempty'});
    if strcmp(names{k},'solar_W')
        assert(numel(e.value)==6,'THERMA:C34Solar','Exactly six absorbed solar powers required.');
        I.(names{k})=reshape(e.value,1,6);
    else
        assert(isscalar(e.value),'THERMA:C34Scalar','Scalar required for %s.',names{k});
        I.(names{k})=e.value;
    end
end
for name={'initial_zone_K','initial_radiator_K','setpoint_K','supply_K','outdoor_K','duration_s','max_step_s'}
    assert(I.(name{1})>0,'THERMA:C34Positive','Positive %s required.',name{1});
end
assert(islogical(raw.heating_enabled) && isscalar(raw.heating_enabled), ...
    'THERMA:C34Enable','Boolean heating_enabled required.');
I.heating_enabled=raw.heating_enabled; I.disable_at_s=raw.disable_at_s;
assert(isempty(I.disable_at_s) || (isscalar(I.disable_at_s) && isfinite(I.disable_at_s) && ...
    I.disable_at_s>0 && I.disable_at_s<I.duration_s),'THERMA:C34Disable','Invalid disable time.');
assert(strcmp(raw.solver.name,'ode15s'),'THERMA:C34Solver','Review a change of solver family explicitly.');
for k={'RelTol','AbsTol'}
    tolerance=str2double(raw.solver.(k{1}));
    assert(isfinite(tolerance) && tolerance>0,'THERMA:C34Solver','Invalid tolerance.');
end
for k={'instantaneous_balance_W','energy_absolute_J','energy_relative','temperature_envelope_margin_K'}
    validateattributes(raw.checks.(k{1}),{'numeric'},{'scalar','finite','positive'});
end
I.solver=raw.solver; I.checks=raw.checks; I.configuration=raw;
end
