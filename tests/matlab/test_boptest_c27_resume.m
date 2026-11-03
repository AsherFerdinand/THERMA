function tests = test_boptest_c27_resume
% Synthetic receipt contracts only; no benchmark run is fabricated.
tests = functiontests(localfunctions);
end

function testCorruptionAndContractChangesPreventResume(testCase)
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPath=path; pathCleanup=onCleanup(@() path(oldPath));
addpath(fullfile(root,'scripts','matlab','boptest'));
folder=tempname; mkdir(folder); cleanup=onCleanup(@() rmdir(folder,'s'));
expected=struct('matlab_version','synthetic fixture','max_step_s',30, ...
    'packet_sha256',repmat('a',1,64),'contract_sha256',repmat('b',1,64),'experiment_id','solar_30');
report=struct('status','executed_partial_not_validated','matlab_execution_completed',true, ...
    'simulation_returned',true,'matlab_version',expected.matlab_version, ...
    'replay_packet_sha256',expected.packet_sha256,'solver',struct('MaxStep_s','30'), ...
    'stop_time_s','60','replay_metadata',struct('duration_s',60));
write_boptest_json(fullfile(folder,'replay_run.json'),report);
files={'evaluation.csv','comparison_metadata.json','solver_metadata.json','energy_events.csv'};
for j=1:numel(files)
    fid=fopen(fullfile(folder,files{j}),'w'); fprintf(fid,'synthetic unit fixture\n'); fclose(fid);
end
files=[files {'replay_run.json'}]; artifacts=cell(1,numel(files));
for j=1:numel(files)
    artifacts{j}=struct('name',files{j},'sha256',boptest_file_sha256(fullfile(folder,files{j})));
end
write_boptest_json(fullfile(folder,'completion.json'), ...
    struct('status','completed','expected',expected,'artifacts',{artifacts}));
verifyTrue(testCase,boptest_c27_completed(folder,expected));
% A failed export is ineligible even if someone produced a complete-looking receipt.
report.export_completed=false;
write_boptest_json(fullfile(folder,'replay_run.json'),report);
artifacts{end}.sha256=boptest_file_sha256(fullfile(folder,'replay_run.json'));
write_boptest_json(fullfile(folder,'completion.json'), ...
    struct('status','completed','expected',expected,'artifacts',{artifacts}));
verifyFalse(testCase,boptest_c27_completed(folder,expected));
report.export_completed=true;
write_boptest_json(fullfile(folder,'replay_run.json'),report);
artifacts{end}.sha256=boptest_file_sha256(fullfile(folder,'replay_run.json'));
write_boptest_json(fullfile(folder,'completion.json'), ...
    struct('status','completed','expected',expected,'artifacts',{artifacts}));
verifyTrue(testCase,boptest_c27_completed(folder,expected));
% New exporter success is reusable; failed/changed exporter metadata is not.
report.energy_event_export=struct('status','verified','sha256', ...
    boptest_file_sha256(fullfile(folder,'energy_events.csv')),'verification',struct('row_count',1));
write_boptest_json(fullfile(folder,'replay_run.json'),report);
artifacts{end}.sha256=boptest_file_sha256(fullfile(folder,'replay_run.json'));
write_boptest_json(fullfile(folder,'completion.json'), ...
    struct('status','completed','expected',expected,'artifacts',{artifacts}));
verifyTrue(testCase,boptest_c27_completed(folder,expected));
report.energy_event_export.status='failed';
write_boptest_json(fullfile(folder,'replay_run.json'),report);
artifacts{end}.sha256=boptest_file_sha256(fullfile(folder,'replay_run.json'));
write_boptest_json(fullfile(folder,'completion.json'), ...
    struct('status','completed','expected',expected,'artifacts',{artifacts}));
verifyFalse(testCase,boptest_c27_completed(folder,expected));
other=expected; other.max_step_s=15;
verifyFalse(testCase,boptest_c27_completed(folder,other));
fid=fopen(fullfile(folder,'evaluation.csv'),'a'); fprintf(fid,'corrupt'); fclose(fid);
verifyFalse(testCase,boptest_c27_completed(folder,expected));
end
