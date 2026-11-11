function manifest = therma_history_packet(root)
%THERMA_HISTORY_PACKET Verify the delivered toolkit, not an old THERMA installation.
manifest=jsondecode(fileread(fullfile(root,'HISTORY_PACKAGE_MANIFEST.json')));
assert(manifest.schema_version==1,'THERMA:HistoryPackage','Unsupported toolkit schema.');
for k=1:numel(manifest.files)
    item=manifest.files(k);
    file=therma_safe_path(root,item.path);
    assert(isfile(file),'THERMA:HistoryPackage','Missing toolkit file: %s',item.path);
    info=dir(file);
    assert(info.bytes==item.bytes && strcmp(boptest_file_sha256(file),item.sha256), ...
        'THERMA:HistoryPackage','Changed toolkit file: %s',item.path);
    if endsWith(item.path,'.m')
        [~,name]=fileparts(item.path);
        found=which(name);
        assert(~isempty(found),'THERMA:HistoryPackage','Unresolved toolkit function.');
        actual=char(java.io.File(found).getCanonicalPath());
        same=strcmp(actual,file);
        if ispc, same=strcmpi(actual,file); end
        assert(same,'THERMA:HistoryShadow','Change folder to the fresh toolkit;old helpers shadow %s.',name);
    end
end
end
