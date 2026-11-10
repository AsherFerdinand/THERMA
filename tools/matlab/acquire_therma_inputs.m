function records = acquire_therma_inputs(dataRoot,mode,packageRoot)
%ACQUIRE_THERMA_INPUTS Verify existing FLEXLAB originals; optional explicit download.
% Default is offline verification. 'download' uses official immutable URLs only.
if nargin<2, mode='verify'; end
if nargin<3, packageRoot=fileparts(fileparts(fileparts(mfilename('fullpath')))); end
assert(ismember(string(mode),["verify","download"]),'THERMA:InputMode','Use verify or download.');
audit = jsondecode(fileread(fullfile(packageRoot,'docs','results','c42b','source_audit.json')));
names = cellstr(string(audit.selected_core_files));
records = struct('path',{},'sha256',{},'bytes',{},'source',{},'verified',{});
for k=1:numel(names)
    item = audit.files(strcmp({audit.files.path},names{k}));
    assert(isscalar(item),'THERMA:InputManifest','Ambiguous input metadata.');
    file = therma_safe_path(dataRoot,item.path);
    if ~isfile(file) && strcmp(mode,'download')
        parent=fileparts(file);
        if ~isfolder(parent), mkdir(parent); end
        stage=[tempname(parent) '.download'];
        % Preserve a failed/partial stage for diagnosis; never overwrite an original.
        websave(stage,item.source);
        assert(strcmp(boptest_file_sha256(stage),item.sha256), ...
            'THERMA:InputHash','Download hash mismatch; original not published: %s',item.path);
        assert(~isfile(file),'THERMA:InputExists','Destination appeared during download.');
        [ok,message]=movefile(stage,file);
        assert(ok,'THERMA:InputPublish','Cannot publish verified download: %s',message);
    end
    assert(isfile(file),'THERMA:MissingInput', ...
        'Missing %s. Download %s into the external data folder, preserving subfolders. Expected SHA256 %s.', ...
        item.path,item.source,item.sha256);
    info=dir(file);
    assert(info.bytes==item.bytes && strcmp(boptest_file_sha256(file),item.sha256), ...
        'THERMA:InputHash','Original differs from pinned source: %s; do not overwrite it.',item.path);
    records(k)=struct('path',item.path,'sha256',item.sha256,'bytes',item.bytes, ...
        'source',item.source,'verified',true);
end
fprintf('Verified %d external inputs. No originals modified.\n',numel(records));
end
