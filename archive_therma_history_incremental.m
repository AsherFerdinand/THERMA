function [partFile,job] = archive_therma_history_incremental(source,destination,action)
% One bounded ZIP per call. Keep original installation completely untouched.
if nargin<3, action='next'; end
root=fileparts(mfilename('fullpath'));oldPath=path;
cleanup=onCleanup(@() path(oldPath));
addpath(root,fullfile(root,'tools','matlab'),fullfile(root,'scripts','matlab','boptest'));
assert(strcmp(version('-release'),'2025a') && usejava('jvm'),'THERMA:IncrementalRelease','Use MATLAB R2025a/JVM.');
package=therma_history_packet(root);
assert(ismember(string(action),["next","status","verify-local"]),'THERMA:IncrementalAction','Use next,status or verify-local.');
source=char(java.io.File(char(source)).getCanonicalPath());
destination=char(java.io.File(char(destination)).getCanonicalPath());
a=source;b=destination;if ispc,a=lower(a);b=lower(b);end
assert(~strcmp(a,b) && ~startsWith(b,[a filesep]),'THERMA:IncrementalDestination','Destination must be outside originals.');
ref=fullfile(root,'history_reference');[legacy,~]=therma_history_load(ref);
plan=jsondecode(fileread(fullfile(ref,'incremental_plan.json')));
assert(strcmp(plan.audit_sha256,legacy.audit_sha256),'THERMA:IncrementalPlan','Audit identity differs.');
if ~isfolder(destination),mkdir(destination);end
job=fullfile(destination,['THERMA_INCREMENTAL_' plan.audit_sha256(1:16)]);
if ~isfolder(job),mkdir(job);end
partFile='';catalogFile=fullfile(job,'incremental_catalog.json');
if isfile(catalogFile)
    catalog=jsondecode(fileread(catalogFile));
    assert(strcmp(catalog.plan_sha256,boptest_file_sha256(fullfile(ref,'incremental_plan.json'))), ...
        'THERMA:IncrementalResume','Different plan;use another job directory.');
else
    check=therma_history_preflight(source,legacy);
    write_boptest_json(fullfile(job,'initial_preflight.json'),check);
    % Added backup ZIPs/reports must not prevent preserving the audited snapshot.
    % They remain explicitly outstanding for a later fresh inventory;never discarded.
    extra={};blocked=false;
    for j=1:numel(check.issues)
        issue=check.issues{j};
        if startsWith(issue.problem,'New file absent from original audit;')
            extra{end+1}=issue; %#ok<AGROW>
        else
            blocked=true;
        end
    end
    assert(~blocked,'THERMA:IncrementalPreflight','Read initial_preflight.json;audited originals changed/missing/unreadable.');
    entries=struct('name',{},'status',{},'sha256',{},'bytes',{},'asset_url',{},'download_checked_utc',{});
    for k=1:numel(plan.parts)
        entries(k)=struct('name',plan.parts(k).name,'status','outstanding','sha256','', ...
            'bytes',0,'asset_url','','download_checked_utc','');
    end
    catalog=struct('schema_version',2,'audit_sha256',plan.audit_sha256, ...
        'plan_sha256',boptest_file_sha256(fullfile(ref,'incremental_plan.json')), ...
        'toolkit_source_commit',package.source_commit,'parts',entries, ...
        'remote_models',jsondecode(fileread(fullfile(ref,'remote_models_verified.json'))), ...
        'cleanup_approved',false,'uncatalogued_files',{extra}, ...
        'scope','audited snapshot;not a final live-folder cleanup authorization');
    copyfile(fullfile(ref,'incremental_plan.json'),fullfile(job,'incremental_plan.json'));
    copyfile(fullfile(ref,'remote_models_verified.json'),fullfile(job,'remote_models_verified.json'));
    copyfile(fullfile(root,'HISTORY_PACKAGE_MANIFEST.json'),fullfile(job,'HISTORY_PACKAGE_MANIFEST.json'));
    therma_incremental_save(job,catalog);
end
% Recover a completed final ZIP if interruption preceded catalog publication.
for j=1:numel(catalog.parts)
    file=fullfile(job,catalog.parts(j).name);
    if strcmp(catalog.parts(j).status,'outstanding') && isfile(file)
        selected=plan.segments(strcmp({plan.segments.part},catalog.parts(j).name));
        therma_incremental_part('verify',file,source,catalog.parts(j).name,selected,plan.audit_sha256);
        catalog.parts(j).status='local_verified';catalog.parts(j).sha256=boptest_file_sha256(file);
        info=dir(file);catalog.parts(j).bytes=info.bytes;therma_incremental_save(job,catalog);
    end
end
fprintf('%d parts outstanding,%d locally verified,%d remotely verified;36 original models separately verified.\n', ...
    sum(strcmp({catalog.parts.status},'outstanding')),sum(strcmp({catalog.parts.status},'local_verified')), ...
    sum(strcmp({catalog.parts.status},'remote_verified')));
if isfield(catalog,'uncatalogued_files') && ~isempty(catalog.uncatalogued_files)
    fprintf('%d added files remain outside this snapshot and require fresh inventory/review.\n',numel(catalog.uncatalogued_files));
end
if strcmp(action,'status'),return;end
local=find(strcmp({catalog.parts.status},'local_verified'));
if ~isempty(local)
    k=local(1);partFile=fullfile(job,catalog.parts(k).name);
    assert(isfile(partFile),'THERMA:IncrementalMissing','Unverified local part is missing;restore it from storage.');
    selected=plan.segments(strcmp({plan.segments.part},catalog.parts(k).name));
    therma_incremental_part('verify',partFile,source,catalog.parts(k).name,selected,plan.audit_sha256);
    assert(strcmp(boptest_file_sha256(partFile),catalog.parts(k).sha256),'THERMA:IncrementalHash','Local ZIP changed.');
    fprintf('Existing part verified. Upload and verify its downloaded Release asset before continuing: %s\n',partFile);return;
end
if strcmp(action,'verify-local'),return;end
for k=1:numel(catalog.parts)
    assert(~isfile(fullfile(job,catalog.parts(k).name)),'THERMA:IncrementalWorkingSpace', ...
        'After remote verification,use Explorer to remove/move ONLY the GENERATED working ZIP. Never move/delete originals.');
end
k=find(strcmp({catalog.parts.status},'outstanding'),1);
if isempty(k),fprintf('All planned parts remotely verified. Fresh inventory/review still required;no cleanup approved.\n');return;end
name=catalog.parts(k).name;selected=plan.segments(strcmp({plan.segments.part},name));
required=ceil(sum([selected.bytes])*1.01)+2*1024^2;
therma_history_space(job,required);
for j=1:numel(selected)
    s=selected(j);
    assert(strcmp(boptest_file_sha256(therma_safe_path(source,s.path)),s.original_sha256), ...
        'THERMA:IncrementalChanged','Original changed since audit.');
end
% Stable stage enables recovery after interruption;never append/truncate an old stage.
stage=fullfile(job,[name '.partial']);
if isfile(stage)
    therma_incremental_part('verify',stage,source,name,selected,plan.audit_sha256);
else
    therma_incremental_part('write',stage,source,name,selected,plan.audit_sha256);
end
for j=1:numel(selected)
    assert(strcmp(boptest_file_sha256(therma_safe_path(source,selected(j).path)),selected(j).original_sha256), ...
        'THERMA:IncrementalChanged','Original changed during archive creation.');
end
partFile=fullfile(job,name);
assert(~isfile(partFile),'THERMA:IncrementalExists','Never overwrite an existing final part.');
[ok,message]=movefile(stage,partFile);assert(ok,'THERMA:IncrementalPublish','%s',message);
catalog.parts(k).status='local_verified';catalog.parts(k).sha256=boptest_file_sha256(partFile);
info=dir(partFile);catalog.parts(k).bytes=info.bytes;therma_incremental_save(job,catalog);
fprintf('ONE part completed: %s\nSHA256 %s\nUpload through Release browser;then verify the downloaded asset.\n',partFile,catalog.parts(k).sha256);
end
