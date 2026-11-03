function info = boptest_verify_energy_csv(file,expectedRows)
%BOPTEST_VERIFY_ENERGY_CSV Bounded-memory six-column/row/time/finite-value check.
header = 'time_s,stored_thermal_energy,net_external_power,stored_energy_derivative,prescribed_power,power_balance_residual';
fid=fopen(file,'rb');
assert(fid>=0,'THERMA:EventCSVOpen','Cannot open event CSV for verification: %s',file);
cleanup=onCleanup(@() fclose(fid));
actual=fgetl(fid);
assert(ischar(actual) && strcmp(actual,header),'THERMA:EventCSVHeader','Event CSV header mismatch.');
rows=0; previous=-Inf; first=[]; last=[]; pending='';
while true
    bytes=fread(fid,1024*1024,'*uint8')';
    if isempty(bytes), break; end
    pending=[pending char(bytes)]; %#ok<AGROW>
    endings=find(pending==char(10));
    if isempty(endings)
        assert(numel(pending)<=4096,'THERMA:EventCSVRecord','Unterminated event record.');
        continue;
    end
    text=pending(1:endings(end)); pending=pending(endings(end)+1:end);
    commas=cumsum(text==',');
    assert(all(diff([0 commas(endings)])==5),'THERMA:EventCSVColumns', ...
        'Each event record must contain exactly six columns.');
    parsed=textscan(text,'%f%f%f%f%f%f','Delimiter',',','CollectOutput',true, ...
        'ReturnOnError',false,'EndOfLine',char(10));
    block=parsed{1};
    assert(size(block,1)==numel(endings) && size(block,2)==6 && ...
        all(isfinite(block),'all'),'THERMA:EventCSVValues','Invalid/nonfinite event records.');
    assert(block(1,1)>=previous && all(diff(block(:,1))>=0), ...
        'THERMA:EventCSVOrder','Event times decreased; duplicate times must remain ordered.');
    if isempty(first), first=block(1,1); end
    last=block(end,1); previous=last; rows=rows+size(block,1);
end
[message,number]=ferror(fid);
assert(number==0,'THERMA:EventCSVRead','CSV verification read error: %s',message);
assert(isempty(pending),'THERMA:EventCSVTruncated','Final event record is truncated/missing newline.');
assert(rows==expectedRows,'THERMA:EventCSVRows','Expected %d event rows, read %d.',expectedRows,rows);
listing=dir(file);
assert(~isempty(listing) && listing.bytes>0,'THERMA:EventCSVEmpty','Missing/empty event file.');
info=struct('row_count',rows,'column_names',{{'time_s','stored_thermal_energy', ...
    'net_external_power','stored_energy_derivative','prescribed_power','power_balance_residual'}}, ...
    'first_time_s',first,'last_time_s',last,'file_bytes',listing.bytes);
end
