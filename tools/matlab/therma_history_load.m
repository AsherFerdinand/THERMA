function [plan,audit] = therma_history_load(reference)
%THERMA_HISTORY_LOAD Validate conservative selection against the original audit.
auditFile=fullfile(reference,'storage_audit.json');
audit=jsondecode(fileread(auditFile));
plan=jsondecode(fileread(fullfile(reference,'history_plan.json')));
known=jsondecode(fileread(fullfile(reference,'preservation_manifest.json')));
assert(plan.schema_version==1 && strcmp(plan.audit_sha256,boptest_file_sha256(auditFile)), ...
    'THERMA:HistoryAudit','Audit hash differs from the reviewed plan.');
assert(strcmp(audit.manifest_sha256, ...
    boptest_file_sha256(fullfile(reference,'preservation_manifest.json'))), ...
    'THERMA:HistoryPreservation','Preservation snapshot differs from the original audit.');
assert(numel(audit.files)==plan.expected_source_files && numel(plan.records)==numel(audit.files), ...
    'THERMA:HistoryCoverage','Audit/plan file count differs.');
knownHashes={};
if ~isempty(known.records), knownHashes={known.records.sha256}; end
paths={plan.records.path};
assert(numel(unique(lower(string(paths))))==numel(paths), ...
    'THERMA:HistoryPaths','Ambiguous duplicate paths.');
for k=1:numel(plan.records)
    item=plan.records(k);
    therma_safe_path(reference,item.path); % validates traversal/portable spelling only
    assert(~startsWith(item.path,'__THERMA_ARCHIVE__/'),'THERMA:HistoryPaths','Reserved source prefix.');
    match=find(strcmp({audit.files.path},item.path));
    assert(isscalar(match),'THERMA:HistoryCoverage','Missing/duplicate audit record.');
    original=audit.files(match);
    assert(item.bytes==original.bytes && isfinite(item.bytes) && item.bytes>=0 && ...
        item.bytes==fix(item.bytes) && strcmp(item.sha256,original.sha256) && ...
        ~isempty(regexp(item.sha256,'^[a-f0-9]{64}$','once')), ...
        'THERMA:HistoryIdentity','Source identity differs from audit.');
    if endsWith(lower(item.path),'.slx')
        expected='archive';
    elseif any(strcmp(knownHashes,item.sha256))
        expected='github_preserved';
    elseif strcmp(original.classification,'REGENERATE_CACHE_REVIEW') && ...
            (endsWith(lower(item.path),'.slxc') || any(strcmpi(strsplit(item.path,'/'),'slprj')))
        expected='regenerable_cache';
    else
        expected='archive';
    end
    assert(strcmp(item.action,expected),'THERMA:HistorySelection','A required original was excluded.');
    if strcmp(expected,'archive')
        assert(any(strcmp({plan.parts.name},item.part)), ...
            'THERMA:HistoryParts','Unassigned original source file.');
    else
        assert(isempty(item.part),'THERMA:HistoryParts','Skipped entry assigned to a part.');
    end
end
assert(numel(unique({plan.parts.name}))==numel(plan.parts), ...
    'THERMA:HistoryParts','Duplicate part identifiers.');
for k=1:numel(plan.parts)
    part=plan.parts(k);
    assert(~isempty(regexp(part.name,'^THERMA_HISTORY_[A-Z0-9_]+\.zip$','once')), ...
        'THERMA:HistoryParts','Invalid part filename.');
    records=plan.records(strcmp({plan.records.part},part.name));
    assert(numel(records)==part.files && sum([records.bytes])==part.source_bytes, ...
        'THERMA:HistoryParts','Part coverage differs.');
end
assert(sum(strcmp({plan.records.action},'archive'))==plan.archive_files && ...
    sum(endsWith(lower(string(paths)),'.slx'))==plan.all_audited_slx, ...
    'THERMA:HistoryModels','Original model/file coverage differs.');
end
