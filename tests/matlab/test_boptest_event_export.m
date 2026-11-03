function tests = test_boptest_event_export
% Synthetic IO tests only; not real BOPTEST/MATLAB benchmark evidence.
tests=functiontests(localfunctions);
end
function setupOnce(testCase)
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
testCase.TestData.oldPath=path;
addpath(fullfile(root,'scripts','matlab','boptest'));
end
function teardownOnce(testCase)
path(testCase.TestData.oldPath);
end
function logs = fixture(n)
t=floor((0:n-1)'/2);
logs=struct('time_s',t,'stored_thermal_energy',sin(t),'net_external_power',cos(t), ...
    'stored_energy_derivative',cos(t),'prescribed_inputs',zeros(n,11), ...
    'power_balance_residual',ones(n,1)*eps);
logs.prescribed_inputs(:,2)=pi;
end
function testSmallPrecisionDuplicateTimesAndBounds(testCase)
folder=tempname; mkdir(folder); cleanup=onCleanup(@() rmdir(folder,'s'));
logs=fixture(12); logs.stored_thermal_energy(3)=realmin;
logs.net_external_power(4)=-realmax;
file=fullfile(folder,'energy_events.csv');
info=boptest_export_energy_events(file,logs,'StagingDirectory',folder, ...
    'ChunkRows',3,'TimeOriginSeconds',100,'StartSeconds',101,'EndSeconds',104);
actual=readmatrix(file,'NumHeaderLines',1); indices=3:10;
expected=[logs.time_s(indices)+100 logs.stored_thermal_energy(indices) ...
    logs.net_external_power(indices) logs.stored_energy_derivative(indices) ...
    sum(logs.prescribed_inputs(indices,2:11),2) logs.power_balance_residual(indices)];
verifyEqual(testCase,actual,expected);
verifyEqual(testCase,info.status,'verified'); verifyEqual(testCase,info.verification.row_count,8);
verifyEqual(testCase,info.sha256,boptest_file_sha256(file));
verifyEqual(testCase,sum(diff(actual(:,1))==0),4);
end
function testLargeChunkedExport(testCase)
folder=tempname; mkdir(folder); cleanup=onCleanup(@() rmdir(folder,'s'));
file=fullfile(folder,'large.csv'); logs=fixture(50000);
info=boptest_export_energy_events(file,logs,'StagingDirectory',folder,'ChunkRows',257);
verifyEqual(testCase,info.verification.row_count,50000);
verifyEqual(testCase,info.sha256,boptest_file_sha256(file));
verified=boptest_verify_energy_csv(file,50000); verifyEqual(testCase,verified.last_time_s,24999);
end
function testInvalidOutputDiagnosticAndOriginalCause(testCase)
folder=tempname; mkdir(folder); cleanup=onCleanup(@() rmdir(folder,'s'));
file=fullfile(folder,'missing','energy_events.csv');
try
    boptest_export_energy_events(file,fixture(4),'StagingDirectory',folder);
    verifyFail(testCase,'Expected failure.');
catch problem
    verifyEqual(testCase,problem.identifier,'THERMA:EventExport');
    verifyEqual(testCase,problem.cause{1}.identifier,'THERMA:EventDirectory');
    verifyTrue(testCase,contains(problem.message,file));
    verifyTrue(testCase,contains(problem.message,'estimated_numeric_bytes'));
end
verifyFalse(testCase,isfile(file));
end
function testNeverOverwriteVerifiedTarget(testCase)
folder=tempname; mkdir(folder); cleanup=onCleanup(@() rmdir(folder,'s'));
file=fullfile(folder,'energy.csv');
boptest_export_energy_events(file,fixture(8),'StagingDirectory',folder);
original=boptest_file_sha256(file);
verifyError(testCase,@() boptest_export_energy_events(file,fixture(9), ...
    'StagingDirectory',folder),'THERMA:EventExport');
verifyEqual(testCase,boptest_file_sha256(file),original);
end
function testInterruptedAndMisorderedCSVRejected(testCase)
folder=tempname; mkdir(folder); cleanup=onCleanup(@() rmdir(folder,'s'));
file=fullfile(folder,'energy.csv');
boptest_export_energy_events(file,fixture(8),'StagingDirectory',folder);
raw=fileread(file); fid=fopen(file,'wb'); fwrite(fid,uint8(raw(1:end-5)),'uint8'); fclose(fid);
verifyError(testCase,@() boptest_verify_energy_csv(file,8),'THERMA:EventCSVTruncated');
logs=fixture(8); logs.time_s(5)=-1;
verifyError(testCase,@() boptest_export_energy_events(fullfile(folder,'bad.csv'),logs, ...
    'StagingDirectory',folder),'THERMA:EventExport');
verifyFalse(testCase,isfile(fullfile(folder,'bad.csv')));
end
function testUNCContextWithoutAssumingNetworkAvailability(testCase)
% Path classification is testable offline; this does not claim actual UNC IO success.
info=boptest_event_export_context('\\server\share\Eigene Dateien\energy.csv',100,120);
verifyTrue(testCase,info.is_unc_path);
verifyEqual(testCase,info.estimated_numeric_bytes,100*6*8);
verifyTrue(testCase,isfield(info,'available_disk_space_bytes'));
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
if ispc && startsWith(root,'\\')
    % A real UNC write is tested only when the actual test installation is on UNC.
    parent=fullfile(root,'outputs','boptest');
    if ~isfolder(parent), mkdir(parent); end
    folder=tempname(parent); mkdir(folder); cleanup=onCleanup(@() rmdir(folder,'s'));
    exported=boptest_export_energy_events(fullfile(folder,'network.csv'),fixture(5000));
    verifyEqual(testCase,exported.status,'verified');
    verifyEqual(testCase,exported.verification.row_count,5000);
end
end
