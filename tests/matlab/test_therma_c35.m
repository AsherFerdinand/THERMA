function tests=test_therma_c35
tests=functiontests(localfunctions);
end
function setupOnce(testCase)
root=fileparts(fileparts(fileparts(mfilename('fullpath')))); testCase.TestData.oldPath=path;
addpath(fullfile(root,'scripts','matlab','c35'),fullfile(root,'scripts','matlab','c3'),fullfile(root,'scripts','matlab','boptest'));
end
function teardownOnce(testCase)
path(testCase.TestData.oldPath);
end
function testContinuousTimeMetricsAndUnreachedThreshold(testCase)
M=c35_time_metrics([0;1;1;2],[293.15;294.15;294.15;295.15],294.15*ones(4,1),1);
verifyEqual(testCase,M.tracking_MAE_K,0.5,'AbsTol',1e-12);
verifyEqual(testCase,M.below_band_h,0.5/3600,'AbsTol',1e-12);
verifyEqual(testCase,M.above_band_h,0.5/3600,'AbsTol',1e-12);
verifyEqual(testCase,M.reach_20_5_s,0.5,'AbsTol',1e-12);
verifyEqual(testCase,M.reach_21_0_s,1,'AbsTol',1e-12);
M=c35_time_metrics([0;1],[288.15;289.15],[294.15;294.15],1);
verifyFalse(testCase,M.reach_21_0_observed); verifyEqual(testCase,M.reach_21_0_s,-1);
end
function testOneFactorPlanAndSolarEnergy(testCase)
[cases,plan]=c35_plan(); verifyEqual(testCase,numel(cases),11);
verifyEqual(testCase,[cases(1:4).UA_W_K],[60 90 120 180]);
verifyEqual(testCase,[cases(1:4).supply_K],ones(1,4)*328.15);
verifyEqual(testCase,[cases(1:4).outdoor_K],ones(1,4)*278.15);
energy=trapz(plan.solar.time_fraction*86400,plan.solar.relative_power*plan.solar.peak_total_W);
verifyEqual(testCase,energy/3.6e6,3.6,'AbsTol',1e-12);
end
function testNewSolarSourceCompileAndNativeEnergy(testCase)
[cases,plan]=c35_plan(); c=cases(end); c.UA_W_K=90;
parent=fullfile(tempdir,'THERMA_C35_smoke'); if ~isfolder(parent), mkdir(parent); end
[model,~,info]=c35_build_case(c,plan,parent,120); cleanup=onCleanup(@() close_system(model,0));
verifyEqual(testCase,get_param([model '/Solar_W'],'Interpolate'),'on');
verifyEqual(testCase,get_param([model '/Solar_W'],'OutputAfterFinalValue'),'Holding final value');
workspace=get_param(model,'ModelWorkspace'); P=getVariable(workspace,'C3'); verifyEqual(testCase,P.UA_W_K,90);
set_param(model,'SimulationCommand','update'); output=sim(Simulink.SimulationInput(model));
logged=output.get('c34_signals'); y=reshape(logged.Data,numel(logged.Time),[]);
D=assess_c34(logged.Time,y,info.signals,info.experiment,info.effective_components);
verifyEqual(testCase,D.status,'integration_numerical_checks_passed');
verifyEqual(testCase,y(end,strcmp(info.signals,'solar_J')),18000,'AbsTol',0.1);
end
