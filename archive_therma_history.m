function archiveFolder = archive_therma_history(source,destination,reference)
%ARCHIVE_THERMA_HISTORY Preserve original bytes without copying/deleting the source.
% Native MATLAB R2025a acceptance is pending; no model is loaded or simulated.
root=fileparts(mfilename('fullpath'));
oldPath=path;
pathCleanup=onCleanup(@() path(oldPath));
addpath(root,fullfile(root,'tools','matlab'),fullfile(root,'scripts','matlab','boptest'));
assert(usejava('jvm') && strcmp(version('-release'),'2025a'), ...
    'THERMA:HistoryRelease','Use base MATLAB R2025a with JVM. No Simulink needed.');
package=therma_history_packet(root);
if nargin<3, reference=fullfile(root,'history_reference'); end
assert(isfolder(source),'THERMA:HistorySource','Original installation folder is missing.');
source=char(java.io.File(char(source)).getCanonicalPath());
destination=char(java.io.File(char(destination)).getCanonicalPath());
a=source; b=destination;
if ispc, a=lower(a); b=lower(b); end
assert(~strcmp(a,b) && ~startsWith(b,[a filesep]), ...
    'THERMA:HistoryDestination','Archive destination must be outside the source tree.');
[plan,~]=therma_history_load(reference);
assert(plan.archive_files>0,'THERMA:HistoryEmpty','No unbacked source files selected.');
if ~isfolder(destination), mkdir(destination); end
archiveFolder=fullfile(destination,['THERMA_HISTORY_' plan.audit_sha256(1:16)]);
if ~isfolder(archiveFolder), mkdir(archiveFolder); end
catalog=struct('schema_version',1,'audit_sha256',plan.audit_sha256, ...
    'toolkit_source_commit',package.source_commit,'matlab_release',version('-release'), ...
    'status','preflight_pending','remote_recovery_confirmed',false,'cleanup_approved',false, ...
    'archives',[],'error',[]);
try
    report=therma_history_preflight(source,plan);
    write_boptest_json(fullfile(archiveFolder,'preflight.json'),report);
    assert(strcmp(report.status,'source_matches_audit'),'THERMA:HistoryPreflight', ...
        'Missing/changed/new files: read preflight.json. Obtain a fresh audit/reviewed plan.');
    existing=false(1,numel(plan.parts));
    entries=struct('name',{},'sha256',{},'bytes',{},'verification',{});
    for k=1:numel(plan.parts)
        part=plan.parts(k);
        file=fullfile(archiveFolder,part.name);
        if isfile(file)
            records=plan.records(strcmp({plan.records.part},part.name));
            therma_history_verify_part(file,source,part.name,records,plan.audit_sha256);
            entries(end+1)=receipt(file,part.name); %#ok<AGROW>
            existing(k)=true;
        end
    end
    % Completed jobs are read/verified and reused;do not rewrite catalog timestamps.
    oldCatalog=fullfile(archiveFolder,'archive_catalog.json');
    oldZIP=fullfile(archiveFolder,'THERMA_HISTORY_CATALOG.zip');
    if all(existing) && isfile(oldCatalog) && isfile(oldZIP)
        previous=jsondecode(fileread(oldCatalog));
        assert(strcmp(previous.status,'locally_verified_only') && ...
            strcmp(previous.audit_sha256,plan.audit_sha256) && ...
            numel(previous.archives)==numel(entries), ...
            'THERMA:HistoryResume','Existing catalog is incomplete or inconsistent.');
        for j=1:numel(entries)
            match=find(strcmp({previous.archives.name},entries(j).name));
            assert(isscalar(match) && strcmp(previous.archives(match).sha256,entries(j).sha256) && ...
                previous.archives(match).bytes==entries(j).bytes, ...
                'THERMA:HistoryResume','Existing part receipt differs.');
        end
        therma_history_verify_catalog(oldZIP,archiveFolder);
        fprintf('Reused all verified archives/catalog. No source or archive overwritten.\n');
        fprintf('Return all part ZIPs and THERMA_HISTORY_CATALOG.zip;no cleanup approved.\n');
        return;
    end
    required=ceil(sum([plan.parts(~existing).source_bytes])*1.05)+4*1024^2;
    available=therma_history_space(archiveFolder,required);
    catalog.space_estimate_bytes=required;
    catalog.volume_free_bytes=available;
    fprintf('Archive %d original files including all%d SLX. Remaining worst-case budget %.1f MB.\n', ...
        plan.archive_files,plan.all_audited_slx,required/1e6);
    fprintf('Volume free space does not establish a smaller university quota. Use another drive if needed.\n');
    for k=1:numel(plan.parts)
        part=plan.parts(k);
        if existing(k)
            fprintf('Reused verified archive: %s\n',part.name);
            continue;
        end
        therma_history_space(archiveFolder,ceil(part.source_bytes*1.05)+4*1024^2);
        records=plan.records(strcmp({plan.records.part},part.name));
        stage=[tempname(archiveFolder) '.partial'];
        therma_history_write_part(source,stage,part.name,records,plan.audit_sha256);
        therma_history_verify_part(stage,source,part.name,records,plan.audit_sha256);
        file=fullfile(archiveFolder,part.name);
        assert(~isfile(file),'THERMA:HistoryExists','Never overwrite an existing archive.');
        [ok,message]=movefile(stage,file);
        assert(ok,'THERMA:HistoryPublish','Cannot publish verified part: %s',message);
        entries(end+1)=receipt(file,part.name); %#ok<AGROW>
        fprintf('Locally verified: %s (%d original files)\n',part.name,numel(records));
    end
    final=therma_history_preflight(source,plan);
    write_boptest_json(fullfile(archiveFolder,'final_source_check.json'),final);
    assert(strcmp(final.status,'source_matches_audit'),'THERMA:HistoryChanged', ...
        'Source changed while archiving. No complete-backup claim is permitted.');
    cells=cell(1,numel(entries));
    for k=1:numel(entries), cells{k}=entries(k); end
    catalog.archives=cells;
    catalog.status='locally_verified_only';
    write_boptest_json(fullfile(archiveFolder,'archive_catalog.json'),catalog);
    metadata_catalog(archiveFolder,reference,root);
catch problem
    catalog.status='failed_or_incomplete';
    catalog.error=boptest_exception_diagnostic(problem);
    try
        write_boptest_json(fullfile(archiveFolder,'last_attempt_failure.json'),catalog);
        if ~isfile(fullfile(archiveFolder,'archive_catalog.json'))
            write_boptest_json(fullfile(archiveFolder,'archive_catalog.json'),catalog);
        end
    catch saveProblem
        fprintf(2,'Could not save diagnostic metadata: %s\n',saveProblem.message);
    end
    fprintf(2,'Archiving stopped;retain partials/verified parts. Source untouched.\n%s\n', ...
        getReport(problem,'extended','hyperlinks','off'));
    rethrow(problem);
end
fprintf('Return all%d part ZIPs plus THERMA_HISTORY_CATALOG.zip from: %s\n',numel(plan.parts),archiveFolder);
fprintf('Local ZIP verification is NOT remote backup. No cleanup is approved or performed.\n');
end

function item = receipt(file,name)
info=dir(file);
item=struct('name',name,'sha256',boptest_file_sha256(file),'bytes',info.bytes, ...
    'verification','locally_verified_original_bytes');
end

function metadata_catalog(folder,reference,root)
names={'history_plan.json','storage_audit.json','preservation_manifest.json'};
for k=1:numel(names), copyfile(fullfile(reference,names{k}),fullfile(folder,names{k})); end
file=fullfile(folder,'RECOVERY.txt');
fid=fopen(file,'w');
assert(fid>=0,'THERMA:HistoryMetadata','Cannot write recovery instructions.');
cleanup=onCleanup(@() fclose(fid));
fprintf(fid,['Return all part ZIPs and this catalog to Codex. Verify every original hash against the source audit.\n' ...
    'Parts retain original relative paths;extract only after validation to an EMPTY recovery folder.\n' ...
    'Existing exact Git matches and declared caches are enumerated in history_plan.json.\n' ...
    'Do not delete the installation. Remote archival/privacy review and explicit user approval remain required.\n']);
clear cleanup;
copyfile(fullfile(root,'HISTORY_PACKAGE_MANIFEST.json'),fullfile(folder,'HISTORY_PACKAGE_MANIFEST.json'));
files=[names {'archive_catalog.json','RECOVERY.txt','HISTORY_PACKAGE_MANIFEST.json'}];
stage=[tempname(folder) '.catalog.zip'];
zip(stage,files,folder); % small metadata only; originals were streamed directly
therma_history_verify_catalog(stage,folder);
hash=boptest_file_sha256(stage);
final=fullfile(folder,'THERMA_HISTORY_CATALOG.zip');
if isfile(final)
    assert(strcmp(boptest_file_sha256(final),hash),'THERMA:HistoryCatalogExists', ...
        'A catalog already exists;retain it. Use the loose updated JSON for diagnosis.');
else
    [ok,message]=movefile(stage,final);
    assert(ok,'THERMA:HistoryPublish','Cannot publish metadata catalog: %s',message);
end
fid=fopen(fullfile(folder,'SHA256SUMS.txt'),'w');
assert(fid>=0,'THERMA:HistoryMetadata','Cannot write checksum list.');
cleanup=onCleanup(@() fclose(fid));
catalog=jsondecode(fileread(fullfile(folder,'archive_catalog.json')));
for k=1:numel(catalog.archives)
    fprintf(fid,'%s  %s\n',catalog.archives(k).sha256,catalog.archives(k).name);
end
fprintf(fid,'%s  THERMA_HISTORY_CATALOG.zip\n',boptest_file_sha256(final));
end
