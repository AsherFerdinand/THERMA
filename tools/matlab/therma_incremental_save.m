function therma_incremental_save(job,catalog)
% Retain timestamped catalog snapshots;replace only generated current pointer.
plan=jsondecode(fileread(fullfile(job,'incremental_plan.json')));
names=unique({plan.segments.path},'stable');
files=struct('path',{},'original_sha256',{},'bytes',{},'status',{},'remote_segments',{},'total_segments',{});
for k=1:numel(names)
    segments=plan.segments(strcmp({plan.segments.path},names{k}));
    states=cell(1,numel(segments));
    for j=1:numel(segments)
        match=find(strcmp({catalog.parts.name},segments(j).part));states{j}=catalog.parts(match).status;
    end
    status='outstanding';
    if all(strcmp(states,'remote_verified')),status='remote_verified';
    elseif all(ismember(states,{'local_verified','remote_verified'})),status='local_verified';
    elseif any(~strcmp(states,'outstanding')),status='partially_archived';end
    files(end+1)=struct('path',names{k},'original_sha256',segments(1).original_sha256, ...
        'bytes',segments(1).original_bytes,'status',status, ...
        'remote_segments',sum(strcmp(states,'remote_verified')),'total_segments',numel(segments)); %#ok<AGROW>
end
for k=1:numel(catalog.remote_models.verified_models)
    m=catalog.remote_models.verified_models(k);
    files(end+1)=struct('path',m.path,'original_sha256',m.sha256,'bytes',m.bytes, ...
        'status','remote_verified','remote_segments',1,'total_segments',1); %#ok<AGROW>
end
catalog.files=files;
file=[tempname(job) '.catalog.json'];
write_boptest_json(file,catalog);
[ok,message]=copyfile(file,fullfile(job,'incremental_catalog.json'),'f');
assert(ok,'THERMA:IncrementalCatalog','Could not save catalog pointer: %s',message);
end
