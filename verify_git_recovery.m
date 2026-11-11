function result = verify_git_recovery(recoveryFolder)
%VERIFY_GIT_RECOVERY Verify independently extracted historical Git originals.
packet=fileparts(mfilename('fullpath'));
addpath(fullfile(packet,'tools','matlab'));
addpath(fullfile(packet,'scripts','matlab','boptest'));
auditFile=fullfile(packet,'history_reference','storage_audit.json');
expected='5854d0a727fed8604eaadf7aacbcb1e3bcb00a585050ca53157e4d3e9927d8c4';
assert(strcmp(boptest_file_sha256(auditFile),expected),'THERMA:AuditIntegrity','Audit hash mismatch.');
audit=jsondecode(fileread(auditFile));
files=audit.files(logical([audit.files.github_bytes_preserved]));
assert(numel(files)==291,'THERMA:AuditIntegrity','Expected 291 Git-dependent files.');
bytes=0;
for k=1:numel(files)
    original=therma_safe_path(fullfile(recoveryFolder,'originals'),files(k).path);
    info=dir(original);
    assert(numel(info)==1 && ~info.isdir && info.bytes==files(k).bytes, ...
        'THERMA:RecoverySize','Missing/size mismatch: %s',files(k).path);
    assert(strcmp(boptest_file_sha256(original),files(k).sha256), ...
        'THERMA:RecoveryHash','Hash mismatch: %s',files(k).path);
    bytes=bytes+info.bytes;
end
result=struct('verified_files',numel(files),'verified_original_bytes',bytes, ...
    'audit_sha256',expected,'cleanup_approved',false);
disp(result);
end
