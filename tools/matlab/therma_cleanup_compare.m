function rows = therma_cleanup_compare(original,current)
%THERMA_CLEANUP_COMPARE Compare exact relative paths and SHA identities, not dates.
rows=struct('path',{},'status',{},'bytes',{},'sha256',{}, ...
    'original_sha256',{},'preservation_required',{},'note',{});
oldNames={original.path}; newNames={current.path};
assert(numel(unique(lower(string(newNames))))==numel(newNames), ...
    'THERMA:AmbiguousInventory','Case-colliding current paths require manual review.');
for k=1:numel(current)
    f=current(k); index=find(strcmp(oldNames,f.path)); previous='';
    if isempty(index)
        status='added';
    else
        previous=original(index).sha256;
        if strcmp(f.sha256,previous) && f.bytes==original(index).bytes
            status='unchanged';
        else
            status='modified';
        end
    end
    note='';
    if ~isempty(f.error), status='unreadable'; note=f.error; end
    parts=strsplit(lower(f.path),'/');
    cache=endsWith(lower(f.path),'.slxc') || any(strcmp(parts,'slprj'));
    need=ismember(status,{'added','modified','unreadable'}) && ~cache;
    if cache, note='Generated-cache candidate; manually confirm before disregarding.'; end
    rows(end+1)=struct('path',f.path,'status',status,'bytes',f.bytes, ...
        'sha256',f.sha256,'original_sha256',previous, ...
        'preservation_required',need,'note',note); %#ok<AGROW>
end
for k=1:numel(original)
    f=original(k);
    if any(strcmp(newNames,f.path)), continue; end
    rows(end+1)=struct('path',f.path,'status','deleted','bytes',0, ...
        'sha256','','original_sha256',f.sha256,'preservation_required',false, ...
        'note','Absent at scan time; check scan_errors before accepting absence.'); %#ok<AGROW>
end
if ~isempty(rows), [~,index]=sort({rows.path}); rows=rows(index); end
end
