function tests=test_therma_c34_integration
tests=functiontests(localfunctions);
end
function setupOnce(testCase)
root=fileparts(fileparts(fileparts(mfilename('fullpath')))); testCase.TestData.oldPath=path;
addpath(fullfile(root,'scripts','matlab','c3'),fullfile(root,'scripts','matlab','boptest'));
end
function teardownOnce(testCase)
path(testCase.TestData.oldPath);
end
function testColdStartTopologyAndBalances(testCase)
I=load_c34_experiment(); I.duration_s=120;
[t,y,info,D]=simulate_c34_model(I);
verifyEqual(testCase,D.status,'integration_numerical_checks_passed');
verifyTrue(testCase,info.C2_source_file_preserved);
verifyEqual(testCase,y(1,strcmp(info.signals,'air_K')),I.initial_zone_K,'AbsTol',1e-9);
verifyEqual(testCase,y(1,strcmp(info.signals,'radiator_K')),I.initial_radiator_K,'AbsTol',1e-9);
s=@(name) y(:,strcmp(info.signals,name));
verifyEqual(testCase,s('demand'),ones(size(t)));
verifyGreaterThan(testCase,s('opening'),-1e-10*ones(size(t)));
verifyGreaterThan(testCase,y(end,strcmp(info.signals,'opening')),0);
verifyGreaterThan(testCase,y(end,strcmp(info.signals,'radiator_K')),I.initial_radiator_K);
verifyLessThan(testCase,D.heating_port_mismatch_max_W,1e-6);
end
function testDisableAndActuatorClosure(testCase)
I=load_c34_experiment(); I.duration_s=1200; I.disable_at_s=300;
[t,y,info,D]=simulate_c34_model(I);
verifyEqual(testCase,D.status,'integration_numerical_checks_passed');
demand=y(:,strcmp(info.signals,'demand')); opening=y(:,strcmp(info.signals,'opening'));
verifyEqual(testCase,demand(t<300),ones(sum(t<300),1));
P=load_c3_parameters(); settled=t>=I.disable_at_s+P.controller_period_s;
verifyEqual(testCase,demand(settled),zeros(sum(settled),1));
verifyLessThan(testCase,opening(end),0.001);
verifyGreaterThan(testCase,max(opening),0.9);
end
function testDisabledWarmRadiatorReleasesStorage(testCase)
I=load_c34_experiment(); I.duration_s=600; I.heating_enabled=false; I.initial_radiator_K=I.initial_zone_K+5;
[~,y,info,D]=simulate_c34_model(I);
verifyEqual(testCase,D.status,'integration_numerical_checks_passed');
verifyEqual(testCase,y(:,strcmp(info.signals,'demand')),zeros(size(y,1),1));
verifyEqual(testCase,y(:,strcmp(info.signals,'mass_flow_kg_s')),zeros(size(y,1),1),'AbsTol',1e-12);
verifyEqual(testCase,y(:,strcmp(info.signals,'water_W')),zeros(size(y,1),1),'AbsTol',1e-8);
verifyGreaterThan(testCase,y(end,strcmp(info.signals,'delivered_J')),0);
verifyLessThan(testCase,y(end,strcmp(info.signals,'radiator_stored_J')),0);
end

function testTracePrecisionAndDuplicateEvents(testCase)
file=[tempname '.csv']; cleanup=onCleanup(@() delete(file));
time=[0;1;1;2]; values=[realmin;-pi;pi;realmax];
write_c34_csv(file,time,values,{'power_W'});
actual=readmatrix(file,'NumHeaderLines',1);
verifyEqual(testCase,actual,[time values]);
end
