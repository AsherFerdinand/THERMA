function therma_history_bytes(stream,bytes)
%THERMA_HISTORY_BYTES Select write(byte[],int,int), including single-byte chunks.
if isempty(bytes), return; end
assert(isa(bytes,'uint8'),'THERMA:HistoryBytes','Expected unmodified uint8 bytes.');
count=numel(bytes);
signed=reshape(typecast(bytes(:),'int8'),1,[]);
if count==1, signed(2)=int8(0); end
stream.write(signed,int32(0),int32(count));
end
