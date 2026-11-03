function hash = boptest_file_sha256(file)
%BOPTEST_FILE_SHA256 Bounded byte-identical SHA-256, including empty/exact chunks.
[fid,message]=fopen(file,'rb');
assert(fid>=0,'THERMA:ReadFailed','Cannot hash source file: %s',message);
cleanup=onCleanup(@() fclose(fid));
assert(fseek(fid,0,'eof')==0,'THERMA:ReadFailed','Cannot seek hash input.');
fileBytes=ftell(fid);
assert(fileBytes>=0 && fseek(fid,0,'bof')==0,'THERMA:ReadFailed','Cannot rewind hash input.');
digest=java.security.MessageDigest.getInstance('SHA-256');
position=0;
while position<fileBytes
    requested=min(1024*1024,fileBytes-position);
    [bytes,count]=fread(fid,requested,'*uint8');
    assert(count==requested && ftell(fid)==position+requested, ...
        'THERMA:ReadFailed','Short/no-progress read while hashing.');
    boptest_sha256_update(digest,bytes);
    position=position+count;
end
assert(fseek(fid,0,'eof')==0 && ftell(fid)==fileBytes, ...
    'THERMA:ReadFailed','Hash input length changed during reading.');
hash=lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2).',1,[]));
end
