function therma_history_verify_catalog(file,folder)
%THERMA_HISTORY_VERIFY_CATALOG Stream-check the small metadata ZIP, without extraction.
names={'history_plan.json','storage_audit.json','preservation_manifest.json', ...
    'archive_catalog.json','RECOVERY.txt','HISTORY_PACKAGE_MANIFEST.json'};
archive=java.util.zip.ZipFile(char(file));
cleanup=onCleanup(@() archive.close());
entries=archive.entries();
seen={};
while entries.hasMoreElements()
    entry=entries.nextElement();
    seen{end+1}=char(entry.getName()); %#ok<AGROW>
end
assert(numel(seen)==numel(names) && numel(unique(seen))==numel(names) && ...
    all(ismember(seen,names)),'THERMA:HistoryCatalog','Unexpected catalog entries.');
for k=1:numel(names)
    original=fullfile(folder,names{k});
    info=dir(original);
    [hash,count]=therma_history_zip_hash(archive,archive.getEntry(names{k}));
    assert(isscalar(info) && count==info.bytes && strcmp(hash,boptest_file_sha256(original)), ...
        'THERMA:HistoryCatalog','Catalog metadata differs from loose originals.');
end
end
