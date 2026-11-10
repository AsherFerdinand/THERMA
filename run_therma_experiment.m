function archive = run_therma_experiment(experimentId,dataRoot)
%RUN_THERMA_EXPERIMENT Verify, inspect and package C42B; no physics changes.
root=fileparts(mfilename('fullpath'));
oldPath=path;
pathCleanup=onCleanup(@() path(oldPath));
addpath(root,fullfile(root,'tools','matlab'),fullfile(root,'scripts','matlab','boptest'));
assert(usejava('jvm'),'THERMA:JVM','The MATLAB JVM is required for SHA-256.');
manifest=verify_therma_package(root);
if nargin<1, experimentId='C42B'; end
assert(strcmpi(experimentId,manifest.experiment_id),'THERMA:Experiment', ...
    'This package supports only %s; do not dispatch another phase.',manifest.experiment_id);
configuration=jsondecode(fileread(fullfile(root,'experiments','C42B.json')));
parent=fullfile(root,'outputs','executions');
if ~isfolder(parent), mkdir(parent); end
folder=tempname(parent);
mkdir(folder);
copyfile(fullfile(root,'package_manifest.json'),fullfile(folder,'package_manifest.json'));
copyfile(fullfile(root,'experiments','C42B.json'),fullfile(folder,'experiment.json'));
write_boptest_json(fullfile(folder,'verification.json'),struct('status','started'));
write_source_commit(fullfile(folder,'SOURCE_COMMIT.txt'),manifest.source_commit);
diary(fullfile(folder,'matlab_execution.log'));
logCleanup=onCleanup(@() diary('off'));
verification=struct('schema_version',1,'experiment_id','C42B','kind','inspection', ...
    'source_commit',manifest.source_commit,'status','failed','matlab_executed',true, ...
    'matlab_version',version,'matlab_release',version('-release'), ...
    'simulation_performed',false,'empirical_validation_performed',false, ...
    'solver',struct('status','not_applicable_inspection'), ...
    'inputs_verified',false,'external_inputs',[], 'error',[]);
failure=[];
try
    assert(strcmp(version('-release'),configuration.matlab_release), ...
        'THERMA:Release','This package targets MATLAB R%s; detected R%s. Other releases need separate checks.', ...
        configuration.matlab_release,version('-release'));
    installed=ver;
    for k=1:numel(configuration.required_products)
        product=configuration.required_products{k};
        assert(any(strcmp({installed.Name},product)),'THERMA:Product','Required product unavailable: %s',product);
    end
    if nargin<2 || isempty(dataRoot)
        dataRoot=fullfile(root,'data','reference_building','raw','flexlab');
    end
    verification.external_inputs=acquire_therma_inputs(dataRoot,'verify',root);
    verification.inputs_verified=true;
    % Reuse the original inspection unchanged; no simulation/model dispatch.
    originalOutput=run_c42b_flexlab_inspection(dataRoot);
    names={'inspection_summary.json','measured_temperatures.png','measured_cooling.png'};
    for k=1:numel(names)
        assert(isfile(fullfile(originalOutput,names{k})),'THERMA:InspectionOutput', ...
            'Inspection did not produce required artifact: %s',names{k});
        copyfile(fullfile(originalOutput,names{k}),fullfile(folder,names{k}));
    end
    verification.status='completed_inspection';
catch problem
    failure=problem;
    verification.error=boptest_exception_diagnostic(problem);
    fprintf(2,'%s\n',getReport(problem,'extended','hyperlinks','off'));
end
write_boptest_json(fullfile(folder,'verification.json'),verification);
clear logCleanup; % close diary before hashing/packing its bytes
archive=package_therma_results(folder);
if ~isempty(failure)
    final=MException('THERMA:ExperimentFailed','Inspection failed. Retain diagnostic ZIP: %s',archive);
    final=addCause(final,failure);
    throw(final);
end
fprintf('Inspection completed; no simulation or empirical validation claimed.\n');
end

function write_source_commit(file,commit)
fid=fopen(file,'w');
assert(fid>=0,'THERMA:ResultWrite','Cannot write source receipt.');
cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',commit);
end
