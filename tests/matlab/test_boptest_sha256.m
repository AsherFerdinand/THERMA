function tests = test_boptest_sha256
% Known vectors independently checked with Python hashlib and OpenSSL.
tests=functiontests(localfunctions);
end
function testKnownFileAndIncrementalVectors(testCase)
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPath=path; pathCleanup=onCleanup(@() path(oldPath));
addpath(fullfile(root,'scripts','matlab','boptest'));
vectors=jsondecode(fileread(fullfile(root,'tests','fixtures','sha256_vectors.json')));
folder=tempname; mkdir(folder); cleanup=onCleanup(@() rmdir(folder,'s'));
for index=1:numel(vectors)
    v=vectors(index); file=fullfile(folder,v.name);
    fid=fopen(file,'wb'); assert(fid>=0);
    closeFile=onCleanup(@() fclose(fid));
    digest=java.security.MessageDigest.getInstance('SHA-256');
    boptest_sha256_update(digest,uint8([]));
    offset=0;
    while offset<v.length
        count=min(65536,v.length-offset);
        if strcmp(v.pattern,'abc')
            bytes=uint8('abc');
        elseif strcmp(v.pattern,'ff')
            bytes=uint8(255);
        else
            bytes=uint8(mod(offset+(0:count-1),256));
        end
        verifyEqual(testCase,fwrite(fid,bytes,'uint8'),count);
        boptest_sha256_update(digest,bytes);
        offset=offset+count;
    end
    clear closeFile;
    actual=boptest_file_sha256(file);
    verifyEqual(testCase,actual,v.sha256,sprintf('File vector %s',v.name));
    incremental=lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2).',1,[]));
    verifyEqual(testCase,incremental,v.sha256,sprintf('Incremental vector %s',v.name));
    verifyNotEmpty(testCase,regexp(actual,'^[0-9a-f]{64}$','once'));
end
end
