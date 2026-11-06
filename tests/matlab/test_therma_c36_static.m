function tests=test_therma_c36_static
tests=functiontests(localfunctions);
end
function testExistingGeometryAndSteadyPower(testCase)
root=fileparts(fileparts(fileparts(mfilename('fullpath')))); oldPath=path;
cleanup=onCleanup(@() path(oldPath));
addpath(fullfile(root,'scripts','matlab','c36'),fullfile(root,'scripts','matlab','c35'), ...
    fullfile(root,'scripts','matlab','c3'),fullfile(root,'scripts','matlab','boptest'));
S=c36_specs();
verifyEqual(testCase,S.geometry.floor_m2,48); verifyEqual(testCase,S.geometry.volume_m3,129.6,'AbsTol',1e-10);
verifyEqual(testCase,S.approximate_H_W_K,100.8126637497,'AbsTol',1e-8);
verifyEqual(testCase,S.split_consistent_H_W_K,105.3415941195,'AbsTol',1e-7);
verifyEqual(testCase,S.total_capacity_J_K,15641238.432,'AbsTol',1e-5);
verifyEqual(testCase,S.radiators{1}.available_full_open_heat_at_setpoint_W,1379.8058252427,'AbsTol',1e-7);
verifyEqual(testCase,S.radiators{2}.available_full_open_heat_at_setpoint_W,2512.9273084479,'AbsTol',1e-7);
verifyLessThan(testCase,S.radiators{1}.capacity_margin_at_setpoint_W,0);
verifyGreaterThan(testCase,S.radiators{2}.capacity_margin_at_setpoint_W,0);
end
