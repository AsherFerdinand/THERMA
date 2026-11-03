function info = boptest_verify_energy_csv(file,expectedRows)
%BOPTEST_VERIFY_ENERGY_CSV Verify a byte-bounded snapshot, not numeric EOF codes.
% fread COUNT/ftell and checked fseek operations govern progress. ferror/feof
% are diagnostics on failure only: R2024a reports EOF as -4 on the user's PC.
header = 'time_s,stored_thermal_energy,net_external_power,stored_energy_derivative,prescribed_power,power_balance_residual';
assert(isscalar(expectedRows) && isfinite(expectedRows) && expectedRows>=0 && ...
    expectedRows==floor(expectedRows),'THERMA:EventCSVRows','Expected row count must be a nonnegative integer.');
[fid,message]=fopen(file,'rb');
assert(fid>=0,'THERMA:EventCSVOpen','Cannot open event CSV: %s (%s)',file,message);
cleanup=onCleanup(@() fclose(fid));
if fseek(fid,0,'eof')~=0, failRead(fid,'Cannot seek to determine file length.'); end
fileBytes=ftell(fid);
if fileBytes<0 || ~isfinite(fileBytes), failRead(fid,'Cannot determine file length.'); end
if fseek(fid,0,'bof')~=0 || ftell(fid)~=0, failRead(fid,'Cannot rewind event file.'); end
digest=java.security.MessageDigest.getInstance('SHA-256');
position=0; rows=0; previous=-Inf; first=[]; last=[]; pending=''; headerSeen=false;
while position<fileBytes
    requested=min(1024*1024,fileBytes-position);
    [bytes,count]=fread(fid,requested,'*uint8');
    nextPosition=ftell(fid);
    if count~=requested || nextPosition~=position+requested
        failRead(fid,sprintf('Short/no-progress read: requested %.0f bytes, received %.0f at position %.0f.', ...
            requested,count,position));
    end
    position=nextPosition;
    boptest_sha256_update(digest,bytes);
    pending=[pending char(bytes(:)')]; %#ok<AGROW>
    if ~headerSeen
        ending=find(pending==char(10),1);
        if isempty(ending)
            assert(numel(pending)<=numel(header)+1,'THERMA:EventCSVHeader','Invalid/unterminated CSV header.');
            continue;
        end
        actualHeader=pending(1:ending-1);
        % Preserve fgetl's CRLF line-ending handling; hashes retain original bytes.
        if ~isempty(actualHeader) && actualHeader(end)==char(13), actualHeader=actualHeader(1:end-1); end
        assert(strcmp(actualHeader,header),'THERMA:EventCSVHeader','Event CSV header mismatch.');
        pending=pending(ending+1:end); headerSeen=true;
    end
    if isempty(pending), continue; end
    endings=find(pending==char(10));
    if isempty(endings)
        assert(numel(pending)<=4096,'THERMA:EventCSVRecord','Unterminated event record.');
        continue;
    end
    text=pending(1:endings(end)); pending=pending(endings(end)+1:end);
    commas=cumsum(text==',');
    assert(all(diff([0 commas(endings)])==5),'THERMA:EventCSVColumns', ...
        'Each event record must contain exactly six columns.');
    % Normalize only CRLF terminators for textscan, after hashing/counting raw bytes.
    text=strrep(text,[char(13) char(10)],char(10));
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
assert(headerSeen,'THERMA:EventCSVHeader','Missing/unterminated CSV header.');
assert(isempty(pending),'THERMA:EventCSVTruncated','Final event record is truncated/missing newline.');
assert(rows==expectedRows,'THERMA:EventCSVRows','Expected %d event rows, read %d.',expectedRows,rows);
% A changing length is an error, never normal EOF. No read past the snapshot occurs.
if fseek(fid,0,'eof')~=0 || ftell(fid)~=fileBytes
    failRead(fid,'Event file length changed during verification.');
end
assert(fileBytes>0,'THERMA:EventCSVEmpty','Empty event file.');
checksum=lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2).',1,[]));
info=struct('row_count',rows,'column_names',{{'time_s','stored_thermal_energy', ...
    'net_external_power','stored_energy_derivative','prescribed_power','power_balance_residual'}}, ...
    'first_time_s',first,'last_time_s',last,'file_bytes',fileBytes,'sha256',checksum, ...
    'reader_method','Snapshot byte length; exact read counts/positions; no numeric EOF classification');
end

function failRead(fid,detail)
% A local function (not nested) does not share the reader's cleanup workspace.
[message,number]=ferror(fid);
error('THERMA:EventCSVRead','%s [ferror=%d, feof=%d]: %s',detail,number,feof(fid),message);
end
