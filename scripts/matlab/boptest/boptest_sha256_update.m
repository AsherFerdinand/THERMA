function boptest_sha256_update(digest,bytes)
%BOPTEST_SHA256_UPDATE Select Java update(byte[],int,int), including singleton reads.
% MATLAB converts nonscalar int8 arrays to primitive Java byte[]. A singleton
% can select a scalar overload; pad its backing array but hash ORIGINAL count.
% typecast preserves unsigned byte bits (int8 conversion would saturate).
if isempty(bytes), return; end
assert(isa(bytes,'uint8'),'THERMA:HashBytes','Hash input must be uint8 bytes.');
count=numel(bytes);
signed=reshape(typecast(bytes(:),'int8'),1,[]);
if count==1, signed(2)=int8(0); end
% Explicit offset/length disambiguate MessageDigest's overloaded update API.
digest.update(signed,int32(0),int32(count));
end
