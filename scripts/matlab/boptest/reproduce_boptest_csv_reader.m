function reportFile = reproduce_boptest_csv_reader(parent)
%REPRODUCE_BOPTEST_CSV_READER Minimal synthetic API probe, not physical evidence.
% Records actual fgetl/fread/feof/ferror observations; no assumed EOF error number.
arguments
    parent (1,:) char = tempdir
end
folder=tempname(parent); mkdir(folder); file=fullfile(folder,'two_events.csv');
header='time_s,stored_thermal_energy,net_external_power,stored_energy_derivative,prescribed_power,power_balance_residual';
fid=fopen(file,'wb'); assert(fid>=0,'THERMA:ReaderProbeOpen','Cannot create probe.');
writerCleanup=onCleanup(@() fclose(fid));
text=sprintf('%s\n0,1,2,3,4,0\n0,2,3,4,5,0\n',header);
assert(fwrite(fid,uint8(text),'uint8')==numel(text),'THERMA:ReaderProbeWrite','Short probe write.');
clear writerCleanup;
report=struct('scope','synthetic CSV reader API observations, not benchmark evidence', ...
    'matlab_version',version,'computer',computer,'csv_sha256',boptest_file_sha256(file));
report.fgetl=probeLines(file);
report.fread=probeBytes(file);
failure=[];
try
    report.snapshot_verification=boptest_verify_energy_csv(file,2);
    report.snapshot_verification.status='verified';
catch problem
    report.snapshot_verification=struct('status','failed','error',boptest_exception_diagnostic(problem));
    failure=problem;
end
reportFile=fullfile(folder,'reader_probe.json'); write_boptest_json(reportFile,report);
fprintf('Actual MATLAB reader observations: %s\n',reportFile);
if ~isempty(failure)
    problem=MException('THERMA:ReaderProbeFailed','Snapshot verification failed; observations saved in %s',reportFile);
    problem=addCause(problem,failure); throw(problem);
end
end

function observations = probeLines(file)
fid=fopen(file,'rb'); assert(fid>=0,'THERMA:ReaderProbeOpen','Cannot open probe.');
cleanup=onCleanup(@() fclose(fid)); observations={};
for j=1:5
    line=fgetl(fid); [message,number]=ferror(fid);
    observations{end+1}=struct('returned_character_line',ischar(line), ...
        'feof',logical(feof(fid)),'ferror_number',number,'ferror_message',message, ...
        'position',ftell(fid)); %#ok<AGROW>
    if ~ischar(line), break; end
end
end

function observations = probeBytes(file)
fid=fopen(file,'rb'); assert(fid>=0,'THERMA:ReaderProbeOpen','Cannot open probe.');
cleanup=onCleanup(@() fclose(fid)); observations={};
for j=1:3
    [~,count]=fread(fid,1024*1024,'*uint8'); [message,number]=ferror(fid);
    observations{end+1}=struct('requested_bytes',1024*1024,'returned_bytes',count, ...
        'feof',logical(feof(fid)),'ferror_number',number,'ferror_message',message, ...
        'position',ftell(fid)); %#ok<AGROW>
    if count==0, break; end
end
end
