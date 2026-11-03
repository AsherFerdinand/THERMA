function indexFile = run_boptest_c27(mode,options)
%RUN_BOPTEST_C27 Sequential same-release controls; no equations/parameters changed.
arguments
    mode (1,1) string = "quick"
    options.Resume (1,1) logical = true
    options.SaveSimulation (1,1) logical = false
    options.SaveTrajectory (1,1) logical = false
end
assert(ismember(mode,["quick","full"]),'THERMA:C27Mode','Use quick or full.');
root = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
planFile = fullfile(root,'configs','references','c27_study.json');
plan = jsondecode(fileread(planFile));
assumptions = fullfile(root,'configs','references','c2_reduced_assumptions.json');
solar = fullfile(root,plan.solar_packet);
noSolar = fullfile(root,plan.no_solar_packet);
[sm,sd] = load_boptest_replay(solar); [nm,nd] = load_boptest_replay(noSolar);
assert(strcmp(boptest_file_sha256(solar),plan.solar_packet_sha256) && ...
    strcmp(boptest_file_sha256(noSolar),plan.no_solar_packet_sha256), ...
    'THERMA:C27InputHash','Study packet changed.');
assert(isequal(sd(:,1:6),nd(:,1:6)) && all(nd(:,7:12)==0,'all') && ...
    isequal(sm.initial_conditions.temperature_K,nm.initial_conditions.temperature_K) && ...
    sm.time_origin_s==nm.time_origin_s && sm.duration_s==nm.duration_s && ...
    sm.evaluation_start_s==nm.evaluation_start_s && sm.evaluation_end_s==nm.evaluation_end_s, ...
    'THERMA:C27Control','No-solar and solar control boundaries/first five channels differ.');
clear sd nd;
parent = fullfile(root,'outputs','boptest','c27');
if ~isfolder(parent), mkdir(parent); end
session = tempname(parent); mkdir(session);
diary(fullfile(session,'command_window.txt')); diaryCleanup=onCleanup(@() diary('off'));
results = runtests(fullfile(root,'tests','matlab'),'IncludeSubfolders',true);
save(fullfile(session,'unit_tests.mat'),'results');
writetable(table({results.Name}',[results.Passed]',[results.Failed]',[results.Incomplete]', ...
    [results.Duration]','VariableNames',{'Name','Passed','Failed','Incomplete','Duration_s'}), ...
    fullfile(session,'unit_tests.csv'));
assert(~isempty(results),'THERMA:C27Tests','No tests discovered.'); assertSuccess(results);
assert(all([results.Passed]),'THERMA:C27Tests','All tests must pass.');
if mode=="quick"
    indexFile = run_boptest_zone_replay(solar,assumptions,'AllowPartial',true, ...
        'MaxStepSeconds',30,'SmokeSeconds',plan.smoke_duration_s, ...
        'OutputParent',string(session),'SaveSimulation',false,'SaveTrajectory',true);
    fprintf('Quick verification only; no full benchmark or convergence result.\n');
    return;
end
% A contract guards resume across code, packet, release or parameter changes.
sourceFiles = dir(fullfile(root,'scripts','matlab','boptest','*.m'));
contract = struct('plan_sha256',boptest_file_sha256(planFile),'matlab_version',version, ...
    'simulink',ver('Simulink'),'assumptions_sha256',boptest_file_sha256(assumptions), ...
    'save_simulation',options.SaveSimulation,'save_trajectory',options.SaveTrajectory);
contract.sources = cell(1,numel(sourceFiles));
for j=1:numel(sourceFiles)
    contract.sources{j} = struct('name',sourceFiles(j).name,'sha256', ...
        boptest_file_sha256(fullfile(sourceFiles(j).folder,sourceFiles(j).name)));
end
contract.frozen_registry_sha256 = boptest_file_sha256(fullfile(root,'configs', ...
    'references','boptest_bestest_hydronic.json'));
write_boptest_json(fullfile(session,'contract.json'),contract);
contractHash = boptest_file_sha256(fullfile(session,'contract.json'));
indexFile = fullfile(session,'study_index.json');
index = struct('schema_version',1,'status','running','contract_sha256',contractHash, ...
    'matlab_version',version,'experiments',struct());
write_boptest_json(indexFile,index);
for j=1:numel(plan.experiments)
    e = plan.experiments(j);
    if strcmp(e.packet,'solar'), packet=solar; else, packet=noSolar; end
    expected = struct('experiment_id',e.id,'max_step_s',e.max_step_s, ...
        'packet_sha256',boptest_file_sha256(packet),'contract_sha256',contractHash, ...
        'matlab_version',version);
    experimentParent = fullfile(parent,e.id);
    if ~isfolder(experimentParent), mkdir(experimentParent); end
    folder = '';
    if options.Resume
        candidates = dir(experimentParent);
        for k=1:numel(candidates)
            if candidates(k).isdir && ~ismember(candidates(k).name,{'.','..'})
                candidate = fullfile(experimentParent,candidates(k).name);
                if boptest_c27_completed(candidate,expected), folder=candidate; break; end
            end
        end
    end
    try
        if isempty(folder)
            fprintf('Running %s sequentially (maximum step %g s).\n',e.id,e.max_step_s);
            reportFile = run_boptest_zone_replay(packet,assumptions,'AllowPartial',true, ...
                'MaxStepSeconds',e.max_step_s,'OutputParent',string(experimentParent), ...
                'SaveSimulation',options.SaveSimulation,'SaveTrajectory',options.SaveTrajectory, ...
                'ExportEvents',true);
            folder = fileparts(reportFile);
            artifacts = {}; listing = dir(folder);
            for k=1:numel(listing)
                if ~listing(k).isdir
                    artifacts{end+1} = struct('name',listing(k).name,'sha256', ...
                        boptest_file_sha256(fullfile(folder,listing(k).name))); %#ok<AGROW>
                end
            end
            write_boptest_json(fullfile(folder,'completion.json'), ...
                struct('status','completed','expected',expected,'artifacts',{artifacts}));
            assert(boptest_c27_completed(folder,expected),'THERMA:C27Receipt', ...
                'New output did not pass integrity/contract checks.');
        else
            fprintf('Skipping hash-verified completed %s: %s\n',e.id,folder);
        end
        [~,leaf]=fileparts(folder); portableFolder=strrep(fullfile(e.id,leaf),filesep,'/');
        index.experiments.(e.id) = struct('status','completed','folder',portableFolder, ...
            'completion_sha256',boptest_file_sha256(fullfile(folder,'completion.json')));
        write_boptest_json(indexFile,index);
    catch problem
        index.status='failed'; index.error=boptest_exception_diagnostic(problem);
        write_boptest_json(indexFile,index); rethrow(problem);
    end
end
index.status='completed'; write_boptest_json(indexFile,index);
fprintf('Full study outputs: %s\n',indexFile);
end
