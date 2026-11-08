function tests=test_therma_c38
tests=functiontests(localfunctions);
end
function testWindowWeightsDuplicateEventsAndNativeEnergy(testCase)
root=fileparts(fileparts(fileparts(mfilename('fullpath')))); old=path;
cleanup=onCleanup(@() path(old));
addpath(fullfile(root,'scripts','matlab','c38'),fullfile(root,'scripts','matlab','c35'));
% Synthetic SOFTWARE fixture, not a heating simulation or a benchmark result.
t=[0;7200;7200;36000;86400]; air=[15;20;20;22;20]+273.15;
energy=100*t; demand=[0;0;1;0;1]; setpoint=ones(size(t))*294.15;
M=c38_interval_metrics(t,air,setpoint,energy,demand,1);
verifyEqual(testCase,M.mean_room_degC,21,'AbsTol',1e-10);
verifyEqual(testCase,M.minimum_room_degC,20,'AbsTol',1e-10);
verifyEqual(testCase,M.maximum_room_degC,22,'AbsTol',1e-10);
verifyEqual(testCase,M.MAE_from_setpoint_K,0.5,'AbsTol',1e-10);
verifyEqual(testCase,M.transitions,2); %2h event excluded;24h event included.
verifyEqual(testCase,M.on_transitions,1); verifyEqual(testCase,M.off_transitions,1);
verifyEqual(testCase,M.delivered_2_24_kWh,2.2,'AbsTol',1e-12);
verifyEqual(testCase,M.delivered_0_24_kWh,2.4,'AbsTol',1e-12);
end
function testInterpolatedBoundaryAndCoverageFailure(testCase)
root=fileparts(fileparts(fileparts(mfilename('fullpath')))); old=path;
cleanup=onCleanup(@() path(old));
addpath(fullfile(root,'scripts','matlab','c38'),fullfile(root,'scripts','matlab','c35'));
t=[0;4000;8000;86400]; air=273.15+20+t/86400; setpoint=ones(size(t))*294.15;
M=c38_interval_metrics(t,air,setpoint,50*t,zeros(size(t)),0.5);
verifyEqual(testCase,M.minimum_room_degC,20+2/24,'AbsTol',1e-10);
verifyEqual(testCase,M.mean_room_degC,20+(1+2/24)/2,'AbsTol',1e-10);
verifyEqual(testCase,M.delivered_2_24_kWh,1.1,'AbsTol',1e-12);
verifyError(testCase,@() c38_interval_metrics(t(1:3),air(1:3),setpoint(1:3),50*t(1:3),zeros(3,1),0.5), ...
    'THERMA:C38Window');
end
