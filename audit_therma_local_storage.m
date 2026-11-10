function output = audit_therma_local_storage(folder,preservationFile)
%AUDIT_THERMA_LOCAL_STORAGE Read-only inventory; NEVER deletes or approves cleanup.
% Run on THERMA_C35_MATLAB BEFORE deleting any temporary/existing installation.
root=fileparts(mfilename('fullpath'));
if nargin<1, folder=root; end
if nargin<2, preservationFile=fullfile(root,'tools','preservation_manifest.json'); end
assert(isfolder(folder),'THERMA:AuditFolder','Choose the existing THERMA folder.');
assert(isfile(preservationFile),'THERMA:PreservationMissing','Preservation manifest is missing.');
oldPath=path;
pathCleanup=onCleanup(@() path(oldPath));
addpath(fullfile(root,'tools','matlab'),fullfile(root,'scripts','matlab','boptest'));
preserved=jsondecode(fileread(preservationFile));
% Include the current lightweight sources only after checking their package hashes.
if isfile(fullfile(root,'package_manifest.json'))
    current=verify_therma_package(root);
    for j=1:numel(current.files)
        item=current.files(j);
        location=struct('commit',current.source_commit,'path',item.path, ...
            'member','','kind','source');
        preserved.records(end+1)=struct('sha256',item.sha256,'bytes',item.bytes, ...
            'locations',location); %#ok<AGROW>
    end
end
known={preserved.records.sha256};
base=char(java.io.File(char(folder)).getCanonicalPath());
listing=dir(fullfile(base,'**','*'));
listing=listing(~[listing.isdir]); % snapshot before writing the audit itself
records=struct('path',{},'bytes',{},'sha256',{},'classification',{}, ...
    'github_bytes_preserved',{},'backup_location',{},'note',{});
for k=1:numel(listing)
    file=fullfile(listing(k).folder,listing(k).name);
    canonical=char(java.io.File(file).getCanonicalPath());
    relative=strrep(file(numel(base)+2:end),'\','/');
    note=''; hash=''; backup=''; backed=false;
    classification='REVIEW_NOT_YET_BACKED_UP';
    % Do not follow symlinks/junctions outside the inspected tree.
    prefix=[base filesep];
    within=startsWith(canonical,prefix);
    if ispc, within=startsWith(lower(canonical),lower(prefix)); end
    try
        assert(within,'THERMA:AuditLink','External link/junction: not read.');
        hash=boptest_file_sha256(file);
        match=find(strcmp(known,hash),1);
        if ~isempty(match)
            location=preserved.records(match).locations(1);
            backed=true;
            backup=[location.commit ':' location.path];
            if isfield(location,'member') && ~isempty(location.member)
                backup=[backup '#' location.member];
            end
            classification='ARCHIVE_REVIEW_AFTER_APPROVAL';
            note='Exact bytes recoverable at recorded Git commit; do not delete without approval.';
        elseif endsWith(lower(relative),'.slxc') || contains(lower(relative),'slprj/')
            classification='REGENERATE_CACHE_REVIEW';
            note='Likely generated Simulink cache; verify it contains no unique source/results.';
        elseif endsWith(lower(relative),{'.slx','.mat','.json','.csv','.asv','.m'})
            classification='KEEP_NOT_YET_BACKED_UP';
            note='Unmatched model, result, measurement, source or autosave. Preserve and review.';
        else
            note='Unknown/unmatched provenance; no deletion recommendation.';
        end
    catch problem
        classification='REVIEW_UNREADABLE';
        note=[problem.identifier ': ' problem.message];
    end
    records(k)=struct('path',relative,'bytes',listing(k).bytes,'sha256',hash, ...
        'classification',classification,'github_bytes_preserved',backed, ...
        'backup_location',backup,'note',note);
end
sizes=[records.bytes];
[~,order]=sort(sizes,'descend');
zipRows=find(endsWith(lower(string({records.path})),'.zip'));
duplicates=struct('sha256',{},'paths',{},'potential_duplicate_bytes',{});
zipHashes=unique(string({records(zipRows).sha256}));
for k=1:numel(zipHashes)
    if strlength(zipHashes(k))==0, continue; end
    matches=zipRows(strcmp({records(zipRows).sha256},zipHashes(k)));
    if numel(matches)>1
        duplicates(end+1)=struct('sha256',char(zipHashes(k)), ...
            'paths',{{records(matches).path}}, ...
            'potential_duplicate_bytes',sum(sizes(matches(2:end)))); %#ok<AGROW>
    end
end
parent=fullfile(root,'outputs','storage_audit');
if ~isfolder(parent), mkdir(parent); end
output=tempname(parent);
mkdir(output);
summary=struct('schema_version',1,'total_bytes',sum(sizes),'file_count',numel(records), ...
    'matlab_release',version('-release'),'files',records, ...
    'largest_files',records(order(1:min(20,numel(order)))),'duplicate_zips',duplicates, ...
    'preservation_source_commit',preserved.source_commit, ...
    'preservation_transfer_commit',preserved.transfer_commit, ...
    'manifest_sha256',boptest_file_sha256(preservationFile), ...
    'automatic_deletion_performed',false,'deletion_approved',false);
write_boptest_json(fullfile(output,'storage_audit.json'),summary);
if ~isempty(records)
    writetable(struct2table(records),fullfile(output,'cleanup_review.csv'));
end
fprintf('Audit only: %.2f MiB, %d files. Report: %s\n',sum(sizes)/1024^2,numel(records),output);
fprintf('NOT YET BACKED UP files must be preserved. No deletion is approved or performed.\n');
end
