function metadata = therma_history_write_part(source,file,part,records,auditSHA)
%THERMA_HISTORY_WRITE_PART Stream originals directly; no uncompressed staging copy.
assert(~isfile(file),'THERMA:HistoryExists','Never overwrite an existing archive/stage.');
fileCells=cell(1,numel(records));
for k=1:numel(records), fileCells{k}=records(k); end
metadata=struct('schema_version',1,'audit_sha256',auditSHA,'part',part, ...
    'files',{fileCells},'manifest_scope','original_file_identities');
stream=java.util.zip.ZipOutputStream(java.io.BufferedOutputStream(java.io.FileOutputStream(char(file))));
cleanup=onCleanup(@() stream.close());
for k=1:numel(records)
    record=records(k);
    original=therma_safe_path(source,record.path);
    info=dir(original);
    assert(isscalar(info) && info.bytes==record.bytes,'THERMA:HistoryChanged','Source size changed.');
    stream.putNextEntry(java.util.zip.ZipEntry(record.path));
    copy_original(stream,original,record);
    stream.closeEntry();
end
write_entry(stream,'__THERMA_ARCHIVE__/manifest.json', ...
    uint8(unicode2native(jsonencode(metadata,'PrettyPrint',true),'UTF-8')));
write_entry(stream,'__THERMA_ARCHIVE__/RECOVERY.txt',uint8(sprintf( ...
    'Original relative paths/bytes retained. Verify hashes before extraction.\nNo remote backup or cleanup approval is claimed.\n')));
clear cleanup; % close central directory before any verification/rename
end

function copy_original(stream,file,record)
[fid,message]=fopen(file,'rb');
assert(fid>=0,'THERMA:HistoryRead','Cannot read original: %s',message);
cleanup=onCleanup(@() fclose(fid));
digest=java.security.MessageDigest.getInstance('SHA-256');
position=0;
while position<record.bytes
    requested=min(1024*1024,record.bytes-position);
    [bytes,count]=fread(fid,requested,'*uint8');
    assert(count==requested && ftell(fid)==position+requested, ...
        'THERMA:HistoryRead','Short/no-progress source read.');
    boptest_sha256_update(digest,bytes);
    therma_history_bytes(stream,bytes);
    position=position+count;
end
assert(fseek(fid,0,'eof')==0 && ftell(fid)==record.bytes, ...
    'THERMA:HistoryChanged','Original length changed during archive write.');
hash=lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2).',1,[]));
assert(strcmp(hash,record.sha256),'THERMA:HistoryChanged','Original bytes changed during archive write.');
end

function write_entry(stream,name,bytes)
stream.putNextEntry(java.util.zip.ZipEntry(name));
therma_history_bytes(stream,bytes);
stream.closeEntry();
end
