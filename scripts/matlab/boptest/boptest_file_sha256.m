function hash = boptest_file_sha256(file)
%BOPTEST_FILE_SHA256 Byte identity for local C2 implementation provenance.
fid = fopen(file,'rb');
assert(fid >= 0,'THERMA:ReadFailed','Cannot hash source file.');
cleanup = onCleanup(@() fclose(fid));
digest = java.security.MessageDigest.getInstance('SHA-256');
while ~feof(fid), digest.update(typecast(fread(fid,1024*1024,'*uint8'),'int8')); end
hash = lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2).',1,[]));
end
