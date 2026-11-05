function tests=test_boptest_temperature_validation
tests=functiontests(localfunctions);
end
function setupOnce(testCase)
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
testCase.TestData.oldPath=path; addpath(fullfile(root,'scripts','matlab','boptest'));
end
function teardownOnce(testCase)
path(testCase.TestData.oldPath);
end
function testAlignmentUnitsAndKnownErrors(testCase)
t=[0;30;60]; target=(0:15:60)'; reference=target/30;
[values,m]=boptest_temperature_metrics(t,[274.15;275.15;276.15],'K',target,reference,'air_temperature');
verifyEqual(testCase,values,reference+1,'AbsTol',1e-12);
verifyEqual(testCase,m.MAE_degC,1,'AbsTol',1e-12);
verifyEqual(testCase,m.RMSE_degC,1,'AbsTol',1e-12);
verifyEqual(testCase,m.sample_count,5);
end
function testInvalidDataAndDefinitions(testCase)
base=@(t,y,u,q) boptest_temperature_metrics(t,y,u,[0;30;60],[0;1;2],q);
verifyError(testCase,@() base([0;0;60],[0;1;2],'degC','air_temperature'),'THERMA:C28Samples');
verifyError(testCase,@() base([0;30;60],[0;NaN;2],'degC','air_temperature'),'THERMA:C28Samples');
verifyError(testCase,@() base([1;30;60],[0;1;2],'degC','air_temperature'),'THERMA:C28Coverage');
verifyError(testCase,@() base([0;30;60],[0;1;2],'degC','operative_temperature'),'THERMA:C28Quantity');
end
