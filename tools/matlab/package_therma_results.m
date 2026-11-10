function archive = package_therma_results(folder)
%PACKAGE_THERMA_RESULTS Hash and zip a compact inspection receipt, never raw data.
% Logs/diagnostics can contain private paths: review before public archival.
names={'verification.json','package_manifest.json','experiment.json','SOURCE_COMMIT.txt', ...
    'matlab_execution.log','inspection_summary.json', ...
    'measured_temperatures.png','measured_cooling.png'};
required=names(1:5);
for k=1:numel(required)
    assert(isfile(fullfile(folder,required{k})),'THERMA:ResultMissing', ...
        'Required result artifact missing: %s',required{k});
end
files=struct('path',{},'sha256',{},'bytes',{});
included={};
for k=1:numel(names)
    file=fullfile(folder,names{k});
    if ~isfile(file), continue; end
    info=dir(file);
    files(end+1)=struct('path',names{k},'sha256',boptest_file_sha256(file),'bytes',info.bytes); %#ok<AGROW>
    included{end+1}=names{k}; %#ok<AGROW>
end
verification=jsondecode(fileread(fullfile(folder,'verification.json')));
manifest=struct('schema_version',1,'experiment_id','C42B', ...
    'source_commit',verification.source_commit,'status',verification.status, ...
    'simulation_performed',false,'empirical_validation_performed',false, ...
    'raw_measurements_included',false,'files',files);
write_boptest_json(fullfile(folder,'result_manifest.json'),manifest);
included{end+1}='result_manifest.json';
archive=fullfile(folder,'THERMA_RESULTS_C42B.zip');
assert(~isfile(archive),'THERMA:ResultExists','Never overwrite an existing results ZIP.');
stage=[tempname(folder) '.zip'];
zip(stage,included,folder);
[ok,message]=movefile(stage,archive);
assert(ok,'THERMA:ResultPublish','Could not publish result ZIP: %s',message);
hash=boptest_file_sha256(archive);
fid=fopen([archive '.sha256'],'w');
assert(fid>=0,'THERMA:ResultChecksum','Cannot write ZIP checksum receipt.');
cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'%s  THERMA_RESULTS_C42B.zip\n',hash);
fprintf('Results ZIP: %s\nSHA256: %s\n',archive,hash);
end
