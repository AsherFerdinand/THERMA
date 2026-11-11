function therma_incremental_part(mode,file,source,name,segments,auditSHA)
%THERMA_INCREMENTAL_PART Bounded lossless byte ranges; no compression assumption.
if strcmp(mode,'write')
    assert(~isfile(file),'THERMA:IncrementalExists','Never overwrite a part.');
    stream=java.util.zip.ZipOutputStream(java.io.BufferedOutputStream(java.io.FileOutputStream(char(file))));
    cleanup=onCleanup(@() stream.close());
    stream.setLevel(int32(0)); % bounded deflate overhead,not guessed compression
    for k=1:numel(segments)
        s=segments(k);
        stream.putNextEntry(java.util.zip.ZipEntry(s.member));
        range_hash(source,s,stream);
        stream.closeEntry();
    end
    cells=cell(1,numel(segments));
    for k=1:numel(segments), cells{k}=segments(k); end
    meta=struct('schema_version',2,'audit_sha256',auditSHA,'part',name,'segments',{cells});
    bytes=uint8(unicode2native(jsonencode(meta,'PrettyPrint',true),'UTF-8'));
    assert(numel(bytes)<1024^2,'THERMA:IncrementalMetadata','Unexpected metadata size.');
    stream.putNextEntry(java.util.zip.ZipEntry('__THERMA_ARCHIVE__/incremental.json'));
    therma_history_bytes(stream,bytes);stream.closeEntry();
    clear cleanup;
end
info=dir(file);
assert(info.bytes<=45000000,'THERMA:IncrementalCap','ZIP exceeds hard45MB cap;retained as partial,not completed.');
archive=java.util.zip.ZipFile(char(file));
cleanup=onCleanup(@() archive.close());
assert(double(archive.size())==numel(segments)+1,'THERMA:IncrementalZIP','Unexpected ZIP entries.');
for k=1:numel(segments)
    s=segments(k);entry=archive.getEntry(s.member);
    assert(~isempty(entry) && double(entry.getSize())==s.bytes,'THERMA:IncrementalZIP','Range missing/size differs.');
    [actual,count]=therma_history_zip_hash(archive,entry);
    expected=range_hash(source,s,[]);
    assert(count==s.bytes && strcmp(actual,expected),'THERMA:IncrementalZIP','Original byte-range differs.');
end
cells=cell(1,numel(segments));
for k=1:numel(segments),cells{k}=segments(k);end
meta=struct('schema_version',2,'audit_sha256',auditSHA,'part',name,'segments',{cells});
bytes=uint8(unicode2native(jsonencode(meta,'PrettyPrint',true),'UTF-8'));
digest=java.security.MessageDigest.getInstance('SHA-256');boptest_sha256_update(digest,bytes);
expected=lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2).',1,[]));
[actual,count]=therma_history_zip_hash(archive,archive.getEntry('__THERMA_ARCHIVE__/incremental.json'));
assert(count==numel(bytes) && strcmp(actual,expected),'THERMA:IncrementalMetadata','Range metadata differs.');
end

function hash=range_hash(source,s,stream)
file=therma_safe_path(source,s.path);
info=dir(file);
assert(info.bytes==s.original_bytes,'THERMA:IncrementalChanged','Original size changed.');
fid=fopen(file,'rb');assert(fid>=0,'THERMA:IncrementalRead','Cannot read original.');
cleanup=onCleanup(@() fclose(fid));
assert(fseek(fid,s.offset,'bof')==0,'THERMA:IncrementalRead','Cannot seek original range.');
digest=java.security.MessageDigest.getInstance('SHA-256');
position=0;
while position<s.bytes
    requested=min(1024*1024,s.bytes-position);
    [bytes,count]=fread(fid,requested,'*uint8');
    assert(count==requested,'THERMA:IncrementalRead','Short source read.');
    boptest_sha256_update(digest,bytes);
    if ~isempty(stream), therma_history_bytes(stream,bytes); end
    position=position+count;
end
hash=lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2).',1,[]));
end
