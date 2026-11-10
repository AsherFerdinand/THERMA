function file = therma_safe_path(root,relative)
%THERMA_SAFE_PATH Resolve portable manifest paths inside a declared root only.
root = char(root);
relative = char(relative);
assert(~isempty(relative) && ~contains(relative,'\') && ...
    ~startsWith(relative,'/') && ~contains(relative,':'), ...
    'THERMA:UnsafePath','Manifest path must be a relative slash-separated path.');
parts = strsplit(relative,'/');
assert(~any(ismember(parts,{'','..','.'})), ...
    'THERMA:UnsafePath','Empty/traversal path components are forbidden.');
base = char(java.io.File(root).getCanonicalPath());
file = char(java.io.File(fullfile(root,parts{:})).getCanonicalPath());
prefix = [base filesep];
if ispc
    valid = startsWith(lower(file),lower(prefix));
else
    valid = startsWith(file,prefix);
end
assert(valid,'THERMA:UnsafePath','Path escapes declared root.');
end
