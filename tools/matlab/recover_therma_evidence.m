function output = recover_therma_evidence(encryptedFile,keyHex,output,expectedSHA)
%RECOVER_THERMA_EVIDENCE Recover original ZIP bytes; secret key is never stored.
assert(usejava('jvm'),'THERMA:JVM','MATLAB JVM is required.');
assert(~isfile(output),'THERMA:RecoveryExists','Choose a new private output filename.');
keyHex=char(keyHex);
assert(numel(keyHex)==64 && all(isstrprop(keyHex,'xdigit')), ...
    'THERMA:RecoveryKey','Supply the separate64-character hexadecimal recovery key.');
key=uint8(sscanf(keyHex,'%2x').');
fid=fopen(encryptedFile,'rb');
assert(fid>=0,'THERMA:RecoveryRead','Cannot read encrypted archive.');
cleanup=onCleanup(@() fclose(fid));
bytes=fread(fid,inf,'*uint8');
clear cleanup;
header=uint8(sprintf('THERMA-AES256-GCM-v1\n'));
n=numel(header);
assert(numel(bytes)>n+12+16 && isequal(bytes(1:n)',header), ...
    'THERMA:RecoveryFormat','Unexpected encrypted-archive format.');
nonce=typecast(bytes(n+1:n+12),'int8');
cipher=javax.crypto.Cipher.getInstance('AES/GCM/NoPadding');
secret=javax.crypto.spec.SecretKeySpec(typecast(key,'int8'),'AES');
parameters=javax.crypto.spec.GCMParameterSpec(int32(128),nonce);
cipher.init(int32(2),secret,parameters);
aad=typecast(header,'int8');
cipher.updateAAD(aad,int32(0),int32(numel(aad)));
payload=typecast(bytes(n+13:end),'int8');
plain=typecast(cipher.doFinal(payload,int32(0),int32(numel(payload))),'uint8');
digest=java.security.MessageDigest.getInstance('SHA-256');
boptest_sha256_update(digest,plain);
hash=lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2).',1,[]));
assert(strcmp(hash,expectedSHA),'THERMA:RecoveryHash','Original ZIP hash differs. Nothing written.');
fid=fopen(output,'wb');
assert(fid>=0,'THERMA:RecoveryWrite','Cannot create private recovery file.');
cleanup=onCleanup(@() fclose(fid));
assert(fwrite(fid,plain,'uint8')==numel(plain),'THERMA:RecoveryWrite','Short recovery write.');
clear cleanup;
assert(strcmp(boptest_file_sha256(output),expectedSHA),'THERMA:RecoveryHash','Written ZIP differs.');
fprintf('Original ZIP recovered and hash checked. Keep the recovery key private.\n');
end
