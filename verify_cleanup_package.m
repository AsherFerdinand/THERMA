function verify_cleanup_package()
%VERIFY_CLEANUP_PACKAGE Verify packaged files; outer ZIP checksum is separate.
packet=fileparts(mfilename('fullpath'));
addpath(fullfile(packet,'scripts','matlab','boptest'));
addpath(fullfile(packet,'tools','matlab'));
manifest=jsondecode(fileread(fullfile(packet,'CLEANUP_PACKAGE_MANIFEST.json')));
for k=1:numel(manifest.files)
    f=manifest.files(k); file=therma_safe_path(packet,f.path); info=dir(file);
    assert(numel(info)==1 && info.bytes==f.bytes && ...
        strcmp(boptest_file_sha256(file),f.sha256), ...
        'THERMA:PackageIntegrity','Package file missing/changed: %s',f.path);
end
fprintf('Verified %d package files. Native execution gate remains separate.\n',numel(manifest.files));
end
