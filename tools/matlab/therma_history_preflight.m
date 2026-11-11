function report = therma_history_preflight(source,plan)
%THERMA_HISTORY_PREFLIGHT Recheck all original bytes and detect newly added files.
issues=struct('path',{},'problem',{});
for k=1:numel(plan.records)
    item=plan.records(k);
    try
        file=therma_safe_path(source,item.path);
        assert(isfile(file),'THERMA:HistoryMissing','Original source file is missing.');
        info=dir(file);
        assert(info.bytes==item.bytes,'THERMA:HistoryChanged','Source size changed since audit.');
        assert(strcmp(boptest_file_sha256(file),item.sha256), ...
            'THERMA:HistoryChanged','Source hash changed since audit.');
    catch problem
        issues(end+1)=struct('path',item.path,'problem',[problem.identifier ': ' problem.message]); %#ok<AGROW>
    end
end
base=char(java.io.File(char(source)).getCanonicalPath());
listing=dir(fullfile(base,'**','*'));
listing=listing(~[listing.isdir]);
for k=1:numel(listing)
    file=fullfile(listing(k).folder,listing(k).name);
    relative=strrep(file(numel(base)+2:end),'\','/');
    if ~any(strcmp({plan.records.path},relative))
        issues(end+1)=struct('path',relative, ...
            'problem','New file absent from original audit; obtain a fresh audit/reviewed plan.'); %#ok<AGROW>
    end
end
cells=cell(1,numel(issues));
for k=1:numel(issues), cells{k}=issues(k); end
report=struct('status','source_matches_audit','issues',{cells}, ...
    'audited_files',numel(plan.records),'observed_files',numel(listing));
if ~isempty(issues), report.status='blocked_source_changed_missing_or_new'; end
end
