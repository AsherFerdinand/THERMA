function verify_therma_history_remote(job,partName,assetURL)
% Stream a fresh HTTPS download: no second45MB disk copy required.
root=fileparts(mfilename('fullpath'));oldPath=path;cleanup=onCleanup(@() path(oldPath));
addpath(root,fullfile(root,'tools','matlab'),fullfile(root,'scripts','matlab','boptest'));
therma_history_packet(root);
assert(startsWith(char(assetURL),'https://'),'THERMA:RemoteURL','Use a direct HTTPS Release asset URL,not a page.');
catalog=jsondecode(fileread(fullfile(job,'incremental_catalog.json')));
k=find(strcmp({catalog.parts.name},partName));
assert(isscalar(k) && ismember(string(catalog.parts(k).status),["local_verified","remote_verified"]), ...
    'THERMA:RemotePart','Part must first pass local verification.');
connection=java.net.URL(char(assetURL)).openConnection();
connection.setConnectTimeout(int32(30000));connection.setReadTimeout(int32(60000));
connection.setRequestProperty('Accept','application/octet-stream');
digest=java.security.MessageDigest.getInstance('SHA-256');
stream=java.security.DigestInputStream(connection.getInputStream(),digest);
streamCleanup=onCleanup(@() stream.close());
buffer=zeros(1,65536,'int8');count=0;
while true
    n=double(stream.read(buffer,int32(0),int32(numel(buffer))));
    if n==-1,break;end
    assert(n>0,'THERMA:RemoteRead','No-progress download.');count=count+n;
    assert(count<=catalog.parts(k).bytes,'THERMA:RemoteSize','Downloaded content is larger/different;receipt unchanged.');
end
hash=lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2).',1,[]));
assert(count==catalog.parts(k).bytes && strcmp(hash,catalog.parts(k).sha256), ...
    'THERMA:RemoteHash','Fresh download differs;NOT marked remotely preserved.');
catalog.parts(k).status='remote_verified';catalog.parts(k).asset_url=char(assetURL);
catalog.parts(k).download_checked_utc=char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss''Z'''));
therma_incremental_save(job,catalog);
fprintf('Fresh downloaded asset bytes/SHA verified. Keep this catalog and URL;always recheck hashes on recovery.\n');
fprintf('Only the generated working ZIP may now be moved elsewhere manually. Original files stay untouched.\n');
end
