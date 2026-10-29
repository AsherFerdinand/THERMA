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

function testSolarV2RoutingAndUnits(testCase)
% Synthetic packet contract, not physical simulation or archived evidence.
folder = tempname; mkdir(folder); cleanup = onCleanup(@() rmdir(folder,'s'));
data = [0 293.15 zeros(1,4) 1 3 4 2 6 5; ...
    30 293.15 zeros(1,4) 2 6 8 4 12 10; ...
    60 293.15 zeros(1,4) 3 9 12 6 18 15];
columns = [{'time_s'},cellstr(compose('input_%02d',1:11))];
writetable(array2table(data,'VariableNames',columns),fullfile(folder,'inputs.csv'));
seven = [data(:,1) (1:3)'*(1:7)];
writetable(array2table(seven,'VariableNames', ...
    {'time_s','south','west','north','east','floor','roof','glazing'}), ...
    fullfile(folder,'solar_seven.csv'));
fid = fopen(fullfile(folder,'solar_sources.csv'),'w'); fprintf(fid,'synthetic fixture\n'); fclose(fid);
quantities = {'outdoor_temperature','delivered_heating_convective_power', ...
    'delivered_heating_radiative_power','internal_convective_power','internal_radiative_power'};
faces = {'south','north','east','west','roof','floor'};
channels = cell(1,11);
for j = 1:11
    if j==1, unit='K'; policy='linear'; else, unit='W'; policy='previous'; end
    if j<=5, quantity=quantities{j}; else, quantity=['absorbed_solar_' faces{j-5} '_power']; end
    channels{j} = struct('column',sprintf('input_%02d',j),'unit',unit, ...
        'interpolation',policy,'quantity',quantity,'status','derived_reference');
end
sources = repmat(struct('unit','W'),1,31);
for j=4:24, sources(j).unit='1'; end
metadata = struct('schema_version',2,'status','partial_replay_ready', ...
    'replay_mode','solar_resolved_partial','classification','exploratory_comparison', ...
    'duration_s',60,'time_origin_s',0,'evaluation_start_s',30,'evaluation_end_s',60, ...
    'channels',{channels},'c2_solar_order',{faces}, ...
    'solar_surface_order',{{'south','west','north','east','floor','roof','glazing'}}, ...
    'source_fmu_sha256','365b3085d97cc4620c06b6036156126a056d7f160fcc4f181d6b2fac4b05743b', ...
    'reference_version','a29024f8c453517ccbd1186006a3fa6af8de1ae2', ...
    'reference_scenario_id','synthetic','source_scenario',struct('name','synthetic'), ...
    'initial_conditions',struct('status','provisional_uniform_declared_start_not_full_FMU_state', ...
        'temperature_K',ones(1,28)*293.15), ...
    'inputs_sha256',boptest_file_sha256(fullfile(folder,'inputs.csv')), ...
    'solar_seven_sha256',boptest_file_sha256(fullfile(folder,'solar_seven.csv')), ...
    'solar_sources_sha256',boptest_file_sha256(fullfile(folder,'solar_sources.csv')), ...
    'solar_signals',sources);
metadata.initial_conditions.observed_temperature_K=ones(1,28)*293.15;
file = fullfile(folder,'replay.json'); write_boptest_json(file,metadata);
[~,actual] = load_boptest_replay(file); verifyEqual(testCase,actual,data);
metadata.channels{6}.interpolation='linear'; write_boptest_json(file,metadata);
verifyError(testCase,@() load_boptest_replay(file),'THERMA:ReplayPolicy');
metadata.channels{6}.interpolation='previous';
metadata.channels{6}.unit='W/m2'; write_boptest_json(file,metadata);
verifyError(testCase,@() load_boptest_replay(file),'THERMA:ReplayUnits');
end
