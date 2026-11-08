function tests=test_therma_c40
tests=functiontests(localfunctions);
end
function testIdenticalPresentationTracesPass(testCase)
root=fileparts(fileparts(fileparts(mfilename('fullpath')))); old=path;
cleanup=onCleanup(@() path(old)); addpath(fullfile(root,'scripts','matlab','c40'));
C=fixture(); S=c40_compare(C,C,10,20);
verifyTrue(testCase,S.passed); verifyEqual(testCase,S.max_air_difference_K,0);
verifyEqual(testCase,S.max_power_difference_W,0); verifyEqual(testCase,S.energy_difference_kWh,0);
end
function testChangedSwitchTimingCannotPassByEqualCounts(testCase)
root=fileparts(fileparts(fileparts(mfilename('fullpath')))); old=path;
cleanup=onCleanup(@() path(old)); addpath(fullfile(root,'scripts','matlab','c40'));
B=fixture(); C=B; C.demand=[1;0;0]; S=c40_compare(B,C,10,20);
verifyFalse(testCase,S.passed); verifyFalse(testCase,S.demand_samples_identical);
verifyEqual(testCase,S.baseline_transitions,S.current_transitions);
end
function C=fixture()
% Synthetic SOFTWARE test, not a simulated thermal-system result.
C=struct('time',[0;10;20],'air_K',[288.15;289.15;290.15],'power_W',[0;100;200], ...
    'demand',[1;1;0],'full_day_metrics',struct('thermostat_transitions',1,'delivered_kWh',0.001));
end
