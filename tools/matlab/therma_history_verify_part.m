function therma_history_verify_part(file,source,part,records,auditSHA)
%THERMA_HISTORY_VERIFY_PART Stream hashes inside ZIP and rehash current originals.
archive=java.util.zip.ZipFile(char(file));
cleanup=onCleanup(@() archive.close());
allowed=[{records.path} {'__THERMA_ARCHIVE__/manifest.json','__THERMA_ARCHIVE__/RECOVERY.txt'}];
entries=archive.entries();
names={};
while entries.hasMoreElements()
    item=entries.nextElement();
    names{end+1}=char(item.getName()); %#ok<AGROW>
end
assert(numel(names)==numel(allowed) && numel(unique(names))==numel(names) && ...
    all(ismember(names,allowed)),'THERMA:HistoryZIP','Unexpected,duplicate or missing ZIP entries.');
for k=1:numel(records)
    item=records(k);
    entry=archive.getEntry(item.path);
    assert(double(entry.getSize())==item.bytes,'THERMA:HistoryZIP','Archived source size differs.');
    [hash,count]=therma_history_zip_hash(archive,entry);
    assert(count==item.bytes && strcmp(hash,item.sha256), ...
        'THERMA:HistoryZIP','Archived original hash differs.');
    assert(strcmp(boptest_file_sha256(therma_safe_path(source,item.path)),item.sha256), ...
        'THERMA:HistoryChanged','Current original changed after writing.');
end
fileCells=cell(1,numel(records));
for k=1:numel(records), fileCells{k}=records(k); end
expected=struct('schema_version',1,'audit_sha256',auditSHA,'part',part, ...
    'files',{fileCells},'manifest_scope','original_file_identities');
bytes=uint8(unicode2native(jsonencode(expected,'PrettyPrint',true),'UTF-8'));
digest=java.security.MessageDigest.getInstance('SHA-256');
boptest_sha256_update(digest,bytes);
expectedHash=lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2).',1,[]));
[actual,count]=therma_history_zip_hash(archive,archive.getEntry('__THERMA_ARCHIVE__/manifest.json'));
assert(count==numel(bytes) && strcmp(actual,expectedHash), ...
    'THERMA:HistoryZIP','Archive manifest differs from reviewed plan.');
end
