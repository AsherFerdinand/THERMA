function tests=test_boptest_c28_standalone
tests=functiontests(localfunctions);
end
function testBundledNoArgumentComparison(testCase)
% Actual-data integration test only in the offline package, not a simulation.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
assumeTrue(testCase,isfile(fullfile(root,'C28_PACKAGE_PROVENANCE.json')), ...
    'Requires the standalone offline package containing original study inputs.');
oldPath=path; cleanup=onCleanup(@() path(oldPath));
addpath(fullfile(root,'scripts','matlab','boptest'));
output=compare_boptest_c28();
for name={'temperature_comparison.png','temperature_comparison.fig', ...
        'temperature_errors.png','temperature_errors.fig','metrics.csv','validation_report.md'}
    verifyTrue(testCase,isfile(fullfile(output,name{1})));
end
actual=readtable(fullfile(output,'metrics.csv'));
expected=jsondecode(fileread(fullfile(root,'docs','results','c28','metrics.json')));
verifyEqual(testCase,actual.MAE_degC, ...
    [expected.metrics.no_solar_30.MAE_K;expected.metrics.solar_30.MAE_K],'AbsTol',1e-10);
verifyEqual(testCase,actual.RMSE_degC, ...
    [expected.metrics.no_solar_30.RMSE_K;expected.metrics.solar_30.RMSE_K],'AbsTol',1e-10);
end
