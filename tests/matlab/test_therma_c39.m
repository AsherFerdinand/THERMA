function tests=test_therma_c39
tests=functiontests(localfunctions);
end
function testEquivalentAirAndSignedHeldHeat(testCase)
root=fileparts(fileparts(fileparts(mfilename('fullpath')))); old=path;
cleanup=onCleanup(@() path(old));
addpath(fullfile(root,'scripts','matlab','c39'),fullfile(root,'scripts','matlab','boptest'));
% Tiny synthetic SOFTWARE fixture, not a BOPTEST trajectory.
m=fixture(); t=[0;30;60]; temperature=[t,294.15*ones(3,1),293.15*ones(3,1),-100*ones(3,1)];
heating=[t,-100*ones(3,2)]; S=c39_metrics(temperature,heating,m);
verifyEqual(testCase,S.temperature.MAE_degC,1,'AbsTol',1e-10);
verifyEqual(testCase,S.temperature.RMSE_degC,1,'AbsTol',1e-10);
verifyEqual(testCase,S.heating.reference_30s_hold_kWh,-1/600,'AbsTol',1e-12);
verifyEqual(testCase,S.heating.max_logged_input_discrepancy_W,0);
end
function testOperativeCannotReplaceAir(testCase)
root=fileparts(fileparts(fileparts(mfilename('fullpath')))); old=path;
cleanup=onCleanup(@() path(old));
addpath(fullfile(root,'scripts','matlab','c39'),fullfile(root,'scripts','matlab','boptest'));
m=fixture(); m.reference_temperature_source='reaTRoo_y';
verifyError(testCase,@() c39_metrics(zeros(3,4),zeros(3,3),m),'THERMA:C39Quantity');
end
function m=fixture()
m=struct('temperature_quantity','air_temperature','reference_temperature_source','mod.case900Template.TAir', ...
    'temperature_unit','K','power_unit','W','heating_quantity','delivered_zone_heat', ...
    'heating_source','-(mod.rad.QCon_flow + mod.rad.QRad_flow)','sample_count',3, ...
    'scenario',struct('evaluation_start_s',0,'evaluation_end_s',60));
end
