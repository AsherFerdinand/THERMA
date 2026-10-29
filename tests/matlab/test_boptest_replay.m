function tests = test_boptest_replay
% Replay packet/driver static-data regression; no reference simulation is run.
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
testCase.TestData.oldPath = path;
addpath(fullfile(root,'scripts','matlab','boptest'));
end

function teardownOnce(testCase)
path(testCase.TestData.oldPath);
end

function testPacketIntegrityAndMixedPolicies(testCase)
folder = tempname; mkdir(folder); cleanup = onCleanup(@() rmdir(folder,'s'));
columns = [{'time_s'},cellstr(compose('input_%02d',1:11))];
data = [0 293.15 zeros(1,10); 1 283.15 650 350 zeros(1,8); 2 283.15 650 350 zeros(1,8)];
writetable(array2table(data,'VariableNames',columns),fullfile(folder,'inputs.csv'));
channels = cell(1,11);
quantities = {'outdoor_temperature','delivered_heating_convective_power', ...
    'delivered_heating_radiative_power','internal_convective_power','internal_radiative_power'};
for j = 1:11
    if j==1, unit='K'; policy='linear'; else, unit='W'; policy='previous'; end
    if j<=5, quantity=quantities{j}; else, quantity=sprintf('omitted_absorbed_solar_%d',j-5); end
    channels{j} = struct('column',sprintf('input_%02d',j),'unit',unit, ...
        'interpolation',policy,'quantity',quantity);
end
metadata = struct('schema_version',1,'status','partial_replay_ready', ...
    'classification','exploratory_comparison','duration_s',2,'time_origin_s',0, ...
    'evaluation_start_s',1,'evaluation_end_s',2,'channels',{channels}, ...
    'initial_conditions',struct('status','provisional_uniform_declared_start_not_full_FMU_state', ...
        'temperature_K',ones(1,28)*293.15),'inputs_sha256',boptest_file_sha256(fullfile(folder,'inputs.csv')));
file = fullfile(folder,'replay.json'); write_boptest_json(file,metadata);
[actual,values] = load_boptest_replay(file);
verifyEqual(testCase,values,data); verifyEqual(testCase,actual.classification,'exploratory_comparison');
metadata.inputs_sha256 = repmat('0',1,64); write_boptest_json(file,metadata);
verifyError(testCase,@() load_boptest_replay(file),'THERMA:ReplayHash');
end
