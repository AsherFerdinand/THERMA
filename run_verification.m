function indexFile = run_verification(mode,options)
%RUN_VERIFICATION Offline THERMA C2.7 verification: quick (default) or full.
% From this folder: run_verification("quick") or run_verification("full").
arguments
    mode (1,1) string = "quick"
    options.Resume (1,1) logical = true
    options.SaveSimulation (1,1) logical = false
    options.SaveTrajectory (1,1) logical = false
end
root=fileparts(mfilename('fullpath'));
assert(usejava('jvm'),'THERMA:C27Java','Use normal MATLAB with Java enabled.');
assert(~isempty(ver('Simulink')) && license('test','Simulink'), ...
    'THERMA:C27Simulink','An installed and licensed Simulink is required.');
if ~ismember(string(version('-release')),["2021a","2024a","2025a"])
    warning('THERMA:C27Release','Target is R2024a; R2021a/R2025a interfaces retained. Actual version will be recorded.');
end
oldPath=path; cleanup=onCleanup(@() path(oldPath));
addpath(fullfile(root,'scripts','matlab','boptest'));
manifestFile=fullfile(root,'PACKAGE_SHA256SUMS');
assert(isfile(manifestFile),'THERMA:C27Package', ...
    'Use the self-contained C2.7 ZIP. A source-only GitHub checkout lacks the verified input data.');
lines=splitlines(string(fileread(manifestFile))); checked=0;
for j=1:numel(lines)
    entry=char(lines(j)); if isempty(strtrim(entry)), continue; end
    parts=regexp(entry,'^([0-9a-f]{64})  (.+)$','tokens','once');
    assert(~isempty(parts),'THERMA:C27Manifest','Malformed checksum entry.');
    relative=parts{2};
    assert(~startsWith(relative,'/') && ~contains(relative,'\') && ~contains(relative,':') && ...
        ~any(strcmp(strsplit(relative,'/'),'..')),'THERMA:C27Manifest','Unsafe checksum path.');
    file=fullfile(root,strrep(relative,'/',filesep));
    assert(isfile(file) && strcmp(boptest_file_sha256(file),parts{1}), ...
        'THERMA:C27Integrity','Missing/changed package file: %s. Extract a fresh copy.',relative);
    checked=checked+1;
end
assert(checked>0,'THERMA:C27Manifest','Empty checksum manifest.');
fprintf('Verified %d package files. Mode: %s\n',checked,mode);
indexFile=run_boptest_c27(mode,'Resume',options.Resume, ...
    'SaveSimulation',options.SaveSimulation,'SaveTrajectory',options.SaveTrajectory);
fprintf('Result/report: %s\n',indexFile);
end
