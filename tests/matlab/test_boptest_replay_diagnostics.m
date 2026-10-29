function tests = test_boptest_replay_diagnostics
% Real exception serialization and a two-second replay-source compile/sim test.
% No C1/C2 physics or reference dataset is needed for this driver regression.
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

function testRecursiveExceptionAndJSON(testCase)
leaf = capturedException();
grandchild = MException('THERMA:Grandchild','Detailed variable-resolution diagnostic.');
leaf = addCause(leaf,grandchild);
other = MException('THERMA:SecondCause','A second failing source block.');
root = MException('MATLAB:MException:MultipleErrors','Error due to multiple causes.');
root = addCause(addCause(root,leaf),other);
value = boptest_exception_diagnostic(root);
verifyEqual(testCase,value.identifier,'MATLAB:MException:MultipleErrors');
verifyEqual(testCase,numel(value.causes),2);
verifyEqual(testCase,value.causes{1}.identifier,'THERMA:CapturedLeaf');
verifyEqual(testCase,value.causes{1}.causes{1}.identifier,'THERMA:Grandchild');
verifyEqual(testCase,value.causes{2}.identifier,'THERMA:SecondCause');
verifyNotEmpty(testCase,value.causes{1}.stack);
verifyGreaterThan(testCase,value.causes{1}.stack{1}.line,0);
verifyNotEmpty(testCase,value.causes{1}.stack{1}.file);
file = [tempname '.json']; cleanup = onCleanup(@() delete(file));
write_boptest_json(file,struct('status','failed','error',value));
raw = fileread(file); parsed = jsondecode(raw);
verifyEqual(testCase,parsed.error.identifier,root.identifier);
verifyTrue(testCase,contains(raw,'THERMA:CapturedLeaf'));
verifyTrue(testCase,contains(raw,'THERMA:Grandchild'));
verifyTrue(testCase,contains(raw,'THERMA:SecondCause'));
text = evalc('print_boptest_exception(root,file)');
verifyTrue(testCase,contains(text,'THERMA:Grandchild'));
verifyTrue(testCase,contains(text,'THERMA:SecondCause'));
end

function exception = capturedException()
try
    error('THERMA:CapturedLeaf','Undefined replay input in a source block.');
catch exception
    % Keep the real stack from error(), not a fabricated stack fixture.
end
end

function testReplayDriverCompileAndMixedInputs(testCase)
[model,input,info] = driverModel(); cleanup = onCleanup(@() close_system(model,0));
verifyEqual(testCase,numel(info),11);
workspace = get_param(model,'ModelWorkspace');
for j = 1:11
    signal = getVariable(workspace,sprintf('Replay_input_%02d',j));
    verifyClass(testCase,signal,'timeseries');
    verifyEqual(testCase,signal.Time,[0;1;2]);
    verifyEqual(testCase,get_param(sprintf('%s/Replay_Source_%02d',model,j),'SampleTime'),'0');
    if j==1, interpolate='on'; else, interpolate='off'; end
    verifyEqual(testCase,get_param(sprintf('%s/Replay_Source_%02d',model,j),'Interpolate'),interpolate);
    verifyEqual(testCase,get_param(sprintf('%s/Replay_Source_%02d',model,j), ...
        'OutputAfterFinalValue'),'Holding final value');
    verifyEqual(testCase,info{j}.output_after_final_value,'Holding final value');
end
set_param(model,'SimulationCommand','update');
output = sim(input); series = output.get('driver_samples');
t = series.Time(:); values = squeeze(series.Data);
if size(values,1)~=numel(t), values=values'; end
verifyTrue(testCase,any(t>0 & t<1));
expectedOutdoor = interp1([0;1;2],[293.15;283.15;278.15],t,'linear');
verifyEqual(testCase,values(:,1),expectedOutdoor,'AbsTol',1e-10);
verifyEqual(testCase,values(t<1,2),zeros(sum(t<1),1));
between = t>1 & t<2;
verifyTrue(testCase,any(between));
verifyEqual(testCase,values(between,2),ones(sum(between),1)*650);
verifyEqual(testCase,values(between,3),ones(sum(between),1)*350);
verifyEqual(testCase,values(t<2,4:11),zeros(sum(t<2),8));
final = find(t==2,1,'last'); verifyNotEmpty(testCase,final);
verifyEqual(testCase,values(final,:),[278.15 800 400 50 60 1 2 3 4 5 6],'AbsTol',1e-10);
end

function testFinalValueHoldBeyondDataEnd(testCase)
[model,input] = driverModel(); cleanup = onCleanup(@() close_system(model,0));
% Deliberate driver-only extension AFTER the normal covered setup. Production
% packets are still required to cover their complete requested interval.
input = input.setModelParameter('StopTime','2.5','OutputTimes','[0 0.5 1 1.5 2 2.25 2.5]');
output = sim(input); series = output.get('driver_samples');
t = series.Time(:); values = squeeze(series.Data);
if size(values,1)~=numel(t), values=values'; end
beyond = t>2;
verifyTrue(testCase,any(beyond));
verifyEqual(testCase,values(beyond,:), ...
    repmat([278.15 800 400 50 60 1 2 3 4 5 6],sum(beyond),1),'AbsTol',1e-10);
end

function testIncompleteCoverageRejected(testCase)
[model,~] = driverModel(); cleanup = onCleanup(@() close_system(model,0));
% Coverage is validated before blocks are added, so these deliberately bad
% requests fail with a coverage diagnostic rather than a duplicate-block error.
metadata.duration_s = 3;
data = [0 293.15 zeros(1,10);2 283.15 zeros(1,10)];
verifyError(testCase,@() configure_boptest_replay_sources(model,metadata,data), ...
    'THERMA:ReplayDriverCoverage');
metadata.duration_s = 2;
set_param(model,'StopTime','3');
verifyError(testCase,@() configure_boptest_replay_sources(model,metadata,data), ...
    'THERMA:ReplayDriverCoverage');
metadata.duration_s = NaN;
verifyError(testCase,@() configure_boptest_replay_sources(model,metadata,data), ...
    'THERMA:ReplayDriverCoverage');
end

function testDriverFailureRetainsOriginalSourceDiagnostic(testCase)
[model,input] = driverModel(); cleanup = onCleanup(@() close_system(model,0));
set_param([model '/Replay_Source_02'],'VariableName','THERMA_IntentionallyMissingReplayVariable');
failed = false;
try
    sim(input);
catch problem
    failed = true;
    serialized = jsonencode(boptest_exception_diagnostic(problem));
    verifyTrue(testCase,contains(serialized,'THERMA_IntentionallyMissingReplayVariable'));
    verifyTrue(testCase,contains(serialized,'Replay_Source_02'));
end
verifyTrue(testCase,failed,'The intentionally broken From Workspace source must fail.');
end

function [model,input,info] = driverModel()
model = 'THERMA_Replay_Driver_Regression';
assert(~bdIsLoaded(model),'THERMA:AlreadyLoaded','Save/close the replay-driver test model.');
load_system('simulink'); new_system(model);
try
    set_param(model,'SolverType','Variable-step','Solver','ode45','StopTime','2', ...
        'MaxStep','0.1','ReturnWorkspaceOutputs','on', ...
        'OutputOption','AdditionalOutputTimes','OutputTimes','[0 0.5 0.999999 1 1.000001 1.5 2]');
    add_block('simulink/Signal Routing/Mux',[model '/Inputs'],'Inputs','11');
    add_block('simulink/Sinks/To Workspace',[model '/Log'],'VariableName','driver_samples', ...
        'SaveFormat','Timeseries','MaxDataPoints','inf');
    add_line(model,'Inputs/1','Log/1');
    % Signal integration forces a continuous solver in this small driver-only fixture.
    add_block('simulink/Continuous/Integrator',[model '/SignalIntegral']);
    add_block('simulink/Sinks/Terminator',[model '/Discard']);
    add_line(model,'Inputs/1','SignalIntegral/1'); add_line(model,'SignalIntegral/1','Discard/1');
    metadata.duration_s = 2;
    metadata.channels = cell(1,11);
    for j = 1:11
        if j==1, policy='linear'; else, policy='previous'; end
        metadata.channels{j} = struct('interpolation',policy);
    end
    data = [0 293.15 zeros(1,10);1 283.15 650 350 zeros(1,8);2 278.15 800 400 50 60 1 2 3 4 5 6];
    [input,info] = configure_boptest_replay_sources(model,metadata,data);
catch problem
    close_system(model,0); rethrow(problem);
end
end
