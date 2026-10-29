function tests = test_boptest_step_inputs
% Executable MATLAB regressions. Pure helpers need no Simulink; model test does.
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
testCase.TestData.originalPath = path;
testCase.TestData.root = root;
addpath(fullfile(root,'scripts','matlab','boptest'));
end

function teardownOnce(testCase)
path(testCase.TestData.originalPath);
end

function testAllScenarioAreasAndLimits(testCase)
cases = boptest_zone_scenarios();
for j = 1:numel(cases)
    c = cases(j);
    right = boptest_hold_values(c.time_s,c.values,[0;3599;3600;3601;7200],"right");
    verifyEqual(testCase,right,[c.values(1,:);c.values(1,:); ...
        c.values(2,:);c.values(2,:);c.values(3,:)]);
    verifyEqual(testCase,boptest_hold_values(c.time_s,c.values,3600,"left"),c.values(1,:));
    expectedArea = 3600*(c.values(1,:)+c.values(2,:));
    verifyEqual(testCase,boptest_hold_integral(c.time_s,c.values,7200),expectedArea,'AbsTol',1e-9);
    propagated = boptest_piecewise_reference(zeros(11),eye(11),zeros(11,1), ...
        c.time_s,c.values,[0;3600;7200]);
    verifyEqual(testCase,propagated,[zeros(1,11);3600*c.values(1,:);expectedArea], ...
        'AbsTol',1e-7);
end
end

function testNonGridAlignedStepAndContinuousState(testCase)
step = 37.25; time = [0;step;100]; values = [0;2;2]; query = [0;20;step;step;50;100];
result = boptest_piecewise_reference(-0.2,1,0,time,values,query);
expected = 10*(1-exp(-0.2*max(0,query-step)));
verifyEqual(testCase,result,expected,'AbsTol',1e-12);
verifyEqual(testCase,result(3),result(4));
end

function testInitialAndFinalStepsAndDuplicates(testCase)
time = [0;0;1;2]; values = [0;5;5;5];
verifyEqual(testCase,boptest_hold_values(time,values,0,"left"),0);
verifyEqual(testCase,boptest_hold_values(time,values,0,"right"),5);
verifyEqual(testCase,boptest_hold_integral(time,values,[0;1;2]),[0;5;10]);
time = [0;1;2]; values = [0;0;5];
verifyEqual(testCase,boptest_hold_values(time,values,2,"left"),0);
verifyEqual(testCase,boptest_hold_values(time,values,2,"right"),5);
verifyEqual(testCase,boptest_piecewise_reference(0,1,0,time,values,[0;1;2]),zeros(3,1));
time = [0;1;1;2]; values = [0;0;2;2]; query = [0;1;1;1.5;2];
verifyEqual(testCase,boptest_hold_values(time,values,query,"right"),[0;2;2;2;2]);
verifyEqual(testCase,boptest_hold_values(time,values,query,"left"),[0;0;0;2;2]);
verifyEqual(testCase,boptest_hold_integral(time,values,query),[0;0;0;1;2]);
verifyEqual(testCase,boptest_piecewise_reference(0,1,0,time,values,query),[0;0;0;1;2], ...
    'AbsTol',1e-12);
end

function testDiagnosticsDetectRampAndMixedLimits(testCase)
c = struct('time_s',[0;1;2],'values',[0 0;650 350;650 350]);
t = [0;0.5;1;1.5;2];
right = boptest_hold_values(c.time_s,c.values,t,"right");
[diagnostics,~,~] = boptest_input_diagnostics(c,t,right);
verifyTrue(testCase,diagnostics.passed);
leftEvent = right; leftEvent(3,:) = [0 0];
diagnostics = boptest_input_diagnostics(c,t,leftEvent);
verifyTrue(testCase,diagnostics.passed);
mixed = right; mixed(3,:) = [650 0];
diagnostics = boptest_input_diagnostics(c,t,mixed);
verifyFalse(testCase,diagnostics.passed);
ramp = interp1(c.time_s,c.values,t,'linear');
diagnostics = boptest_input_diagnostics(c,t,ramp);
verifyFalse(testCase,diagnostics.passed);
verifyEqual(testCase,diagnostics.max_non_event_input_error_by_channel,[325 175]);
end

function testGeneratedInportAndSelectors(testCase)
assumptions = fullfile(testCase.TestData.root,'configs','references','c2_reduced_assumptions.json');
[model,~] = build_boptest_zone_c2(assumptions,'ShowModel',false);
cleanup = onCleanup(@() close_system(model,0));
verifyEqual(testCase,get_param([model '/Inputs'],'Interpolate'),'off');
verifyEqual(testCase,get_param([model '/Log_inputs_used'],'VariableName'),'inputs_used');
names = {'Outdoor_K','Heating_conv_W','Heating_rad_W','Internal_conv_W','Internal_rad_W','Solar_absorbed_W'};
indices = {'1','2','3','4','5','6:11'};
for j = 1:numel(names)
    verifyEqual(testCase,get_param([model '/' names{j}],'IndexParamArray'),indices(j));
end
end
