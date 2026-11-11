function restore_therma_history_incremental(job,assetFolder,restoreRoot)
% Reconstruct original bytes into a NEW EMPTY folder;no original files overwritten.
root=fileparts(mfilename('fullpath'));oldPath=path;cleanup=onCleanup(@() path(oldPath));
addpath(root,fullfile(root,'tools','matlab'),fullfile(root,'scripts','matlab','boptest'));
therma_history_packet(root);
assert(~isfolder(restoreRoot) && ~isfile(restoreRoot),'THERMA:RestoreExists','Choose a new empty recovery folder.');
plan=jsondecode(fileread(fullfile(job,'incremental_plan.json')));
catalog=jsondecode(fileread(fullfile(job,'incremental_catalog.json')));
for k=1:numel(catalog.parts)
    p=catalog.parts(k);file=fullfile(assetFolder,p.name);
    assert(strcmp(p.status,'remote_verified') && strcmp(boptest_file_sha256(file),p.sha256), ...
        'THERMA:RestoreAsset','Download every verified asset and check its hash first.');
end
mkdir(restoreRoot);
names=unique({plan.segments.path},'stable');
for k=1:numel(names)
    segments=plan.segments(strcmp({plan.segments.path},names{k}));
    file=therma_safe_path(restoreRoot,names{k});parent=fileparts(file);
    if ~isfolder(parent),mkdir(parent);end
    stage=[file '.recovery-partial'];
    assert(~isfile(file) && ~isfile(stage),'THERMA:RestoreExists','Never overwrite recovery content.');
    out=java.io.FileOutputStream(stage);outCleanup=onCleanup(@() out.close());
    position=0;
    for j=1:numel(segments)
        s=segments(j);assert(s.offset==position,'THERMA:RestoreRange','Noncontiguous ranges.');
        z=java.util.zip.ZipFile(fullfile(assetFolder,s.part));zCleanup=onCleanup(@() z.close());
        entry=z.getEntry(s.member);assert(double(entry.getSize())==s.bytes,'THERMA:RestoreSize','Range size differs.');
        in=z.getInputStream(entry);inCleanup=onCleanup(@() in.close());
        channel=java.nio.channels.Channels.newChannel(in);target=out.getChannel();
        copied=0;
        while copied<s.bytes
            n=double(target.transferFrom(channel,int64(position+copied),int64(s.bytes-copied)));
            assert(n>0,'THERMA:RestoreRead','No-progress recovery.');copied=copied+n;
        end
        position=position+copied;clear inCleanup zCleanup;
    end
    clear outCleanup;
    assert(position==segments(1).original_bytes && strcmp(boptest_file_sha256(stage),segments(1).original_sha256), ...
        'THERMA:RestoreHash','Reconstructed original SHA differs;partial retained.');
    [ok,message]=movefile(stage,file);assert(ok,'THERMA:RestoreWrite','%s',message);
end
fprintf('Recovered original paths and complete SHA256 identities. Restore the36 models separately from their verified Release ZIP.\n');
end
