function [hash,total] = therma_history_zip_hash(archive,entry)
% Hash inside Java: do not rely on Java reads mutating a MATLAB buffer by reference.
digest=java.security.MessageDigest.getInstance('SHA-256');
stream=java.security.DigestInputStream(archive.getInputStream(entry),digest);
cleanup=onCleanup(@() stream.close());
buffer=zeros(1,65536,'int8');
total=0;
while true
    count=double(stream.read(buffer,int32(0),int32(numel(buffer))));
    if count==-1, break; end
    assert(count>0,'THERMA:HistoryZIP','No-progress archive read.');
    total=total+count;
    assert(total<=double(entry.getSize()),'THERMA:HistoryZIP','Unexpected extra archive data.');
end
hash=lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2).',1,[]));
end
