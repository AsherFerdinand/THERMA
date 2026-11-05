function write_c34_csv(file,time,y,names)
%WRITE_C34_CSV Bounded, 17-digit local staging writer; event order retained.
assert(isvector(time),'THERMA:C34CSV','Time must be a vector.'); time=time(:);
assert(size(y,1)==numel(time) && size(y,2)==numel(names) && ...
    all(isfinite(time)) && all(isfinite(y),'all') && all(diff(time)>=0), ...
    'THERMA:C34CSV','Malformed/nonfinite/unordered trace.');
headers=[{'time_s'} names];
assert(numel(unique(headers))==numel(headers),'THERMA:C34CSV','Duplicate CSV columns.');
assert(~isfile(file),'THERMA:C34Overwrite','Refusing to overwrite CSV.');
fid=fopen(file,'wb'); assert(fid>=0,'THERMA:C34CSV','Cannot create local staging CSV.');
cleanup=onCleanup(@() fclose(fid));
text=[strjoin(headers,',') char(10)];
assert(fwrite(fid,uint8(text),'uint8')==numel(text),'THERMA:C34CSV','Incomplete header write.');
format=[repmat('%.17g,',1,numel(names)) '%.17g\n']; rows=0;
for first=1:4096:numel(time)
    selected=first:min(first+4095,numel(time)); data=[time(selected) y(selected,:)];
    text=sprintf(format,data.');
    assert(fwrite(fid,uint8(text),'uint8')==numel(text),'THERMA:C34CSV','Incomplete chunk write.');
    rows=rows+numel(selected);
end
assert(rows==numel(time),'THERMA:C34CSV','Trace rows omitted.');
end
