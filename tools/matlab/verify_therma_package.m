function manifest = verify_therma_package(root)
%VERIFY_THERMA_PACKAGE Check every declared file before dispatching an experiment.
manifest = jsondecode(fileread(fullfile(root,'package_manifest.json')));
assert(manifest.schema_version==1 && strcmp(manifest.experiment_id,'C42B'), ...
    'THERMA:PackageSchema','Unsupported package schema or experiment.');
paths = {manifest.files.path};
assert(numel(unique(lower(string(paths))))==numel(paths), ...
    'THERMA:PackageSchema','Duplicate package paths.');
for k = 1:numel(manifest.files)
    item = manifest.files(k);
    file = therma_safe_path(root,item.path);
    assert(isfile(file),'THERMA:PackageMissing','Missing package dependency: %s',item.path);
    info = dir(file);
    assert(info.bytes==item.bytes && strcmp(boptest_file_sha256(file),item.sha256), ...
        'THERMA:PackageHash','Changed package dependency: %s',item.path);
end
% Refuse stale functions from a previous extracted project/current folder.
for k=1:numel(manifest.files)
    item=manifest.files(k);
    if ~endsWith(item.path,'.m'), continue; end
    [~,name]=fileparts(item.path);
    resolved=which(name);
    expected=therma_safe_path(root,item.path);
    actual=char(java.io.File(resolved).getCanonicalPath());
    same=strcmp(actual,expected);
    if ispc, same=strcmpi(actual,expected); end
    assert(same,'THERMA:PathShadow', ...
        'Function %s is shadowed. Change folder to the fresh package and use its helpers.',name);
end
fprintf('Verified %d package files from source %s.\n',numel(paths),manifest.source_commit);
end
