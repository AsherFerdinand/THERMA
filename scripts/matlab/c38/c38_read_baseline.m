function C=c38_read_baseline(root,Z,P,room,folder)
%C38_READ_BASELINE Read original C3.7 artifacts; never edit or execute them.
resultFile=fullfile(folder,'residential_result.json'); csv=fullfile(folder,'residential_trajectory.csv');
r=jsondecode(fileread(resultFile)); P.radiator_initial_K=room.conditions.radiator_initial_C+273.15;
assert(strcmp(r.status,'executed_numerically_checked_not_real_world_validated') && ...
    r.metrics.checks_passed && r.existing_sources_preserved && strcmp(r.matlab_version,version) && ...
    strcmp(r.room_config_sha256,Z.residential_config_sha256) && isequaln(r.room,room) && ...
    isequaln(orderfields(r.effective_components),orderfields(rmfield(P,'assumptions'))), ...
    'THERMA:C38Baseline','Baseline status, room, radiator, release or initialization differs.');
assert(strcmp(boptest_file_sha256(csv),r.trajectory_sha256), ...
    'THERMA:C38Baseline','Baseline trajectory hash changed.');
models=dir(fullfile(folder,'**','THERMA_C37_Residential.slx'));
assert(numel(models)==1,'THERMA:C38Baseline','Need the original saved C3.7 model beside its results.');
modelFile=fullfile(models(1).folder,models(1).name);
assert(strcmp(boptest_file_sha256(modelFile),r.model_sha256),'THERMA:C38Baseline','Baseline model hash changed.');
fid=fopen(csv,'r'); assert(fid>=0,'THERMA:C38Read','Cannot open baseline CSV.');
cleanup=onCleanup(@() fclose(fid)); header=strsplit(fgetl(fid),','); names=header(2:end);
assert(strcmp(header{1},'time_s') && numel(names)==33 && numel(unique(names))==33, ...
    'THERMA:C38Baseline','Unexpected original C3.7 signal schema.');
data=readmatrix(csv,'NumHeaderLines',1);
assert(size(data,2)==34 && size(data,1)==r.diagnostics.samples,'THERMA:C38Baseline','Baseline CSV dimensions differ.');
a=room.conditions; I=load_c34_experiment();
I.supply_K=a.supply_C+273.15; I.outdoor_K=a.outdoor_C+273.15;
I.initial_zone_K=a.air_initial_C+273.15; I.initial_radiator_K=a.radiator_initial_C+273.15;
I.duration_s=a.duration_s; I.max_step_s=10; I.setpoint_K=a.setpoint_C+273.15;
I.internal_convective_W=0; I.internal_radiative_W=0; I.solar_W=zeros(1,6);
info=struct('signals',{names},'experiment',I,'effective_components',rmfield(P,'assumptions'), ...
    'case_definition',struct('id','C37_baseline_reused','group','C38'));
C=c38_check_trace(data(:,1),data(:,2:end),info);
assert(abs(C.metrics.delivered_0_24_kWh-r.metrics.delivered_kWh)<1e-8 && ...
    C.metrics.full_day_transitions==r.metrics.thermostat_transitions, ...
    'THERMA:C38Baseline','Original summary and recalculated trace metrics disagree.');
C.source_model=modelFile; C.names=names; C.reused=true;
C.sources=struct('name',{resultFile,csv,modelFile}, ...
    'sha256',{boptest_file_sha256(resultFile),r.trajectory_sha256,r.model_sha256});
% Keep original absolute paths local to outputs; nothing is added to Git.
fprintf('Reusing compatible C3.7 baseline: %s\n',erase(folder,[root filesep]));
end
