function tests=test_therma_c3_components
% Actual native-Simulink component tests; illustrative fixtures, not BOPTEST.
tests=functiontests(localfunctions);
end
function setupOnce(testCase)
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
testCase.TestData.oldPath=path;
addpath(fullfile(root,'scripts','matlab','c3'),fullfile(root,'scripts','matlab','boptest'));
end
function teardownOnce(testCase)
path(testCase.TestData.oldPath);
end
function testThermostatThresholdsRetentionAndDisable(testCase)
P=load_c3_parameters(); target=P.setpoint_K; half=P.deadband_K/2;
t=(0:10:60)'; room=[target;target-half;target;target+half;target;target-half-0.1;target-half-0.1];
[t,y]=simulate_c3_component('thermostat',P,t,[target*ones(7,1) room [1;1;1;1;1;0;1]]);
expected=[0;1;1;0;0;0;1];
for j=1:7
    candidates=find(abs(t-(j-1)*10)<1e-7); verifyNotEmpty(testCase,candidates);
    k=candidates(end); % Retain the post-event sample if both event sides are logged.
    verifyEqual(testCase,y(k),expected(j));
end
verifyTrue(testCase,all(ismember(y,[0 1])));
end
function testThermostatInitialOnInsideBand(testCase)
P=load_c3_parameters(); P.controller_initial=1;
[~,y]=simulate_c3_component('thermostat',P,[0;40], ...
    [P.setpoint_K P.setpoint_K 1; P.setpoint_K P.setpoint_K 1]);
verifyEqual(testCase,y,ones(size(y)));
end
function testValveOpeningAnalytic(testCase)
P=load_c3_parameters();
[t,y]=simulate_c3_component('valve',P,[0;300],[1;1]);
verifyEqual(testCase,y,1-exp(-t/P.opening_tau_s),'AbsTol',2e-6);
verifyTrue(testCase,all(y>=0 & y<=1));
end
function testValveClosingAnalytic(testCase)
P=load_c3_parameters(); P.valve_initial=1;
[t,y]=simulate_c3_component('valve',P,[0;450],[0;0]);
verifyEqual(testCase,y,exp(-t/P.closing_tau_s),'AbsTol',2e-6);
verifyTrue(testCase,all(y>=0 & y<=1));
end
function testValveDemandSaturation(testCase)
P=load_c3_parameters(); P.valve_initial=0.3;
[t,y]=simulate_c3_component('valve',P,[0;90],[-5;-5]);
verifyEqual(testCase,y,0.3*exp(-t/P.closing_tau_s),'AbsTol',2e-6);
[t,y]=simulate_c3_component('valve',P,[0;60],[5;5]);
verifyEqual(testCase,y,1-0.7*exp(-t/P.opening_tau_s),'AbsTol',2e-6);
end
function testRadiatorHeatingAnalyticAndEnergy(testCase)
P=load_c3_parameters(); x=0.5;
[t,y]=simulate_c3_component('radiator',P,[0;1000], ...
    repmat([x P.supply_example_K P.room_example_K],2,1));
H=x*P.nominal_flow_kg_s*P.water_cp_J_kgK;
equilibrium=(H*P.supply_example_K+P.UA_W_K*P.room_example_K)/(H+P.UA_W_K);
expected=equilibrium+(P.radiator_initial_K-equilibrium)*exp(-(H+P.UA_W_K)*t/P.capacitance_J_K);
verifyEqual(testCase,y(:,1),expected,'AbsTol',1e-5);
verifyEqual(testCase,y(:,4),y(:,2)+y(:,3),'AbsTol',1e-9);
verifyEqual(testCase,y(:,5),ones(size(t))*x*P.nominal_flow_kg_s,'AbsTol',1e-12);
verifyLessThan(testCase,max(abs(y(:,8)-y(:,7)-y(:,9))),0.05);
verifyLessThan(testCase,max(abs(y(:,10))),1e-8);
verifyGreaterThan(testCase,y(end,1),y(1,1));
end
function testNoHeatAtClosedEquilibrium(testCase)
P=load_c3_parameters();
[~,y]=simulate_c3_component('radiator',P,[0;300], ...
    repmat([0 P.supply_example_K P.radiator_initial_K],2,1));
verifyEqual(testCase,y(:,1),ones(size(y,1),1)*P.radiator_initial_K,'AbsTol',1e-10);
verifyEqual(testCase,y(:,2:10),zeros(size(y,1),9),'AbsTol',1e-8);
end
function testStoredHeatReleaseAfterValveClosure(testCase)
P=load_c3_parameters(); P.radiator_initial_K=P.room_example_K+20;
[t,y]=simulate_c3_component('radiator',P,[0;600], ...
    repmat([0 P.supply_example_K P.room_example_K],2,1));
expected=P.room_example_K+20*exp(-P.UA_W_K*t/P.capacitance_J_K);
verifyEqual(testCase,y(:,1),expected,'AbsTol',1e-5);
verifyTrue(testCase,all(y(:,4)>0));
verifyEqual(testCase,y(:,6),zeros(size(t)),'AbsTol',1e-12);
verifyLessThan(testCase,max(abs(y(:,7)+y(:,9))),0.05);
end
function testAdiabaticWaterEnergy(testCase)
P=load_c3_parameters(); P.UA_W_K=0; x=1;
[t,y]=simulate_c3_component('radiator',P,[0;300], ...
    repmat([x P.supply_example_K P.room_example_K],2,1));
H=P.nominal_flow_kg_s*P.water_cp_J_kgK;
expected=P.supply_example_K+(P.radiator_initial_K-P.supply_example_K)*exp(-H*t/P.capacitance_J_K);
verifyEqual(testCase,y(:,1),expected,'AbsTol',1e-5);
verifyEqual(testCase,y(:,4),zeros(size(t)),'AbsTol',1e-12);
verifyLessThan(testCase,max(abs(y(:,8)-y(:,9))),0.05);
end
function testSignedRoomToRadiatorExchange(testCase)
P=load_c3_parameters(); P.radiator_initial_K=P.room_example_K-5;
[~,y]=simulate_c3_component('radiator',P,[0;120], ...
    repmat([0 P.supply_example_K P.room_example_K],2,1));
verifyTrue(testCase,all(y(:,4)<0));
verifyGreaterThan(testCase,y(end,1),y(1,1));
verifyLessThan(testCase,max(abs(y(:,7)+y(:,9))),0.05);
end
function testConfigurationProvenanceAndCapacity(testCase)
P=load_c3_parameters();
verifyEqual(testCase,P.capacitance_J_K,22540);
verifyEqual(testCase,P.assumptions.classification,'illustrative_assumptions_not_calibrated_not_BOPTEST');
end

function testRuntimeSetpointChange(testCase)
P=load_c3_parameters();
[time,y]=simulate_c3_component('thermostat',P,[0;10;20], ...
    [P.setpoint_K P.setpoint_K+0.4 1; P.setpoint_K+2 P.setpoint_K+0.4 1; ...
     P.setpoint_K+2 P.setpoint_K+0.4 1]);
verifyEqual(testCase,y(time<10),zeros(sum(time<10),1));
verifyEqual(testCase,y(time>10),ones(sum(time>10),1));
end
function testValveSwitchesOpeningAndClosingTau(testCase)
P=load_c3_parameters();
[time,y]=simulate_c3_component('valve',P,[0;60;180],[1;0;0]);
expected=1-exp(-time/P.opening_tau_s);
closed=time>=60;
expected(closed)=(1-exp(-60/P.opening_tau_s))*exp(-(time(closed)-60)/P.closing_tau_s);
verifyEqual(testCase,y,expected,'AbsTol',3e-6);
end
