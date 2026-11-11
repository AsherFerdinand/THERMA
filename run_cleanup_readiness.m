function report = run_cleanup_readiness(originalFolder,outputFolder)
%RUN_CLEANUP_READINESS Read-only comparison; never authorizes or performs deletion.
% Keep this toolkit AND its output outside the historical installation.
packet=fileparts(mfilename('fullpath'));
addpath(fullfile(packet,'tools','matlab'));
addpath(fullfile(packet,'scripts','matlab','boptest'));
root=char(java.io.File(char(originalFolder)).getCanonicalPath());
output=char(java.io.File(char(outputFolder)).getCanonicalPath());
assert(isfolder(root),'THERMA:MissingOriginal','Original directory does not exist.');
assert(~inside(root,packet) && ~inside(root,output), ...
    'THERMA:OutputInsideOriginal','Toolkit/output must be outside the original folder.');
assert(~isfolder(output) && ~isfile(output),'THERMA:ExistingOutput', ...
    'Use a new output directory for each rescan.');
auditFile=fullfile(packet,'history_reference','storage_audit.json');
expected='5854d0a727fed8604eaadf7aacbcb1e3bcb00a585050ca53157e4d3e9927d8c4';
assert(strcmp(boptest_file_sha256(auditFile),expected), ...
    'THERMA:AuditIntegrity','Original audit hash mismatch.');
audit=jsondecode(fileread(auditFile));
assert(numel(audit.files)==602,'THERMA:AuditIntegrity','Expected 602 original records.');
for k=1:numel(audit.files)
    therma_safe_path(root,audit.files(k).path);
end
oldNames={audit.files.path};
assert(numel(unique(lower(string(oldNames))))==numel(oldNames), ...
    'THERMA:AuditIntegrity','Duplicate original paths.');
current=struct('path',{},'bytes',{},'sha256',{},'error',{});
queue={''}; scanErrors=struct('path',{},'identifier',{});
while ~isempty(queue)
    relative=queue{end}; queue(end)=[];
    if isempty(relative), folder=root; else, folder=fullfile(root,relative); end
    entries=dir(folder);
    % A concurrently missing/unlistable directory must never appear safely empty.
    [ok,attributes]=fileattrib(folder);
    if ~ok || isempty(entries) || ~attributes.UserRead
        scanErrors(end+1)=struct('path',relative,'identifier','THERMA:DirectoryUnreadable'); %#ok<AGROW>
        continue;
    end
    for k=1:numel(entries)
        e=entries(k);
        if ismember(e.name,{'.','..'}), continue; end
        name=strrep(fullfile(relative,e.name),filesep,'/');
        try
            file=therma_safe_path(root,name);
            lexical=fullfile(root,strrep(name,'/',filesep));
            % Do not traverse symlinks/junctions/aliases, including internal ones.
            if ~strcmpi(file,lexical)
                error('THERMA:LinkedPath','Linked/aliased path requires manual review.');
            end
            if e.isdir
                queue{end+1}=name; %#ok<AGROW>
                continue;
            end
            before=dir(file); sha=boptest_file_sha256(file); after=dir(file);
            assert(numel(before)==1 && numel(after)==1 && ...
                before.bytes==after.bytes && before.datenum==after.datenum, ...
                'THERMA:ConcurrentChange','File changed while hashing; close MATLAB models and retry.');
            current(end+1)=struct('path',name,'bytes',after.bytes,'sha256',sha,'error',''); %#ok<AGROW>
        catch exception
            scanErrors(end+1)=struct('path',name,'identifier',exception.identifier); %#ok<AGROW>
            if ~e.isdir
                current(end+1)=struct('path',name,'bytes',e.bytes, ...
                    'sha256','','error',exception.identifier); %#ok<AGROW>
            end
        end
    end
end
rows=therma_cleanup_compare(audit.files,current);
report=struct('schema_version',1,'matlab_release',version('-release'), ...
    'created_local',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')), ...
    'audit_sha256',expected,'files',rows,'scan_errors',scanErrors, ...
    'scan_complete',isempty(scanErrors),'cleanup_approved',false, ...
    'status','pending_manual_review_not_deletion_authorization');
for status={'added','modified','deleted','unchanged','unreadable'}
    report.counts.(status{1})=sum(strcmp({rows.status},status{1}));
end
report.new_or_changed_files_requiring_preservation= ...
    {rows([rows.preservation_required]).path};
assert(strcmp(boptest_file_sha256(auditFile),expected), ...
    'THERMA:AuditIntegrity','Audit changed during scan.');
mkdir(output);
write_boptest_json(fullfile(output,'cleanup_readiness.json'),report);
writetable(struct2table(rows),fullfile(output,'file_changes.csv'));
fid=fopen(fullfile(output,'READ_ME.txt'),'w');
assert(fid>=0,'THERMA:WriteFailed','Cannot write report.');
closer=onCleanup(@() fclose(fid));
fprintf(fid,['NO DELETION AUTHORIZED. Review file_changes.csv and cleanup_readiness.json.\n' ...
    'Preserve every added/modified non-cache file; resolve unreadable/linked paths.\n' ...
    'This is a point-in-time scan, not a filesystem snapshot. Recheck before cleanup.\n' ...
    'Obtain privacy/copyright/university approval; keep independently verified recovery copies.\n' ...
    'Do not upload these reports publicly without privacy review.\n']);
disp(report.counts);
fprintf('Files needing preservation: %d. Scan errors: %d. No deletion authorized.\n', ...
    numel(report.new_or_changed_files_requiring_preservation),numel(scanErrors));
end

function yes=inside(root,path)
root=lower(char(java.io.File(root).getCanonicalPath()));
path=lower(char(java.io.File(path).getCanonicalPath()));
yes=strcmp(root,path) || startsWith(path,[root filesep]);
end
