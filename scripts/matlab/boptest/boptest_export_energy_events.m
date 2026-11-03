function info = boptest_export_energy_events(file,logs,options)
%BOPTEST_EXPORT_ENERGY_EVENTS Chunked full-precision staging and checked publication.
% No full event matrix/table is created. Inputs are references to existing log arrays.
arguments
    file (1,:) char
    logs (1,1) struct
    options.TimeOriginSeconds (1,1) double = 0
    options.StartSeconds (1,1) double = -Inf
    options.EndSeconds (1,1) double = Inf
    options.ChunkRows (1,1) double = 4096
    options.StagingDirectory (1,:) char = tempdir
end
fid=-1; staging=''; temporary=''; success=false;
cleanup=onCleanup(@cleanupOwned);
inputRows=numel(logs.time_s); expected=0;
context=boptest_event_export_context(file,expected,inputRows); context.stage='validate_input';
try
    assert(isfinite(options.TimeOriginSeconds) && ~isnan(options.StartSeconds) && ...
        ~isnan(options.EndSeconds) && options.StartSeconds<=options.EndSeconds, ...
        'THERMA:EventBounds','Invalid event export bounds.');
    assert(isfinite(options.ChunkRows) && options.ChunkRows>=1 && ...
        options.ChunkRows<=65536 && options.ChunkRows==floor(options.ChunkRows), ...
        'THERMA:EventChunk','ChunkRows must be an integer from 1 to 65536.');
    names={'time_s','stored_thermal_energy','net_external_power','stored_energy_derivative','power_balance_residual'};
    for j=1:numel(names)
        values=logs.(names{j});
        assert(isnumeric(values) && isreal(values) && isvector(values) && numel(values)==inputRows, ...
            'THERMA:EventShape','Each scalar event log must match the time vector.');
    end
    assert(isnumeric(logs.prescribed_inputs) && isreal(logs.prescribed_inputs) && ...
        isequal(size(logs.prescribed_inputs),[inputRows 11]), ...
        'THERMA:EventShape','Expected original N-by-11 prescribed input log.');
    previous=-Inf;
    for first=1:options.ChunkRows:inputRows
        last=min(first+options.ChunkRows-1,inputRows);
        time=logs.time_s(first:last)+options.TimeOriginSeconds; time=time(:);
        assert(all(isfinite(time)) && time(1)>=previous && all(diff(time)>=0), ...
            'THERMA:EventOrder','Original event timestamps must be finite and nondecreasing.');
        previous=time(end);
        expected=expected+nnz(time>=options.StartSeconds & time<=options.EndSeconds);
    end
    context=boptest_event_export_context(file,expected,inputRows); context.stage='validate_destination';
    assert(expected>0,'THERMA:EventNoRows','No events cover the requested evaluation interval.');
    assert(context.directory_exists,'THERMA:EventDirectory','Output directory does not exist.');
    assert(~isfile(file) && ~isfolder(file),'THERMA:EventDestinationExists', ...
        'Refusing to overwrite an existing event destination: %s',file);
    assert(isfolder(options.StagingDirectory),'THERMA:EventStaging','Staging directory does not exist.');
    context.stage='create_staging';
    staging=[tempname(options.StagingDirectory) '.events.csv'];
    context.staging_file=staging;
    [fid,message]=fopen(staging,'wb');
    assert(fid>=0,'THERMA:EventOpen','Cannot create staging file: %s',message);
    header=sprintf('time_s,stored_thermal_energy,net_external_power,stored_energy_derivative,prescribed_power,power_balance_residual\n');
    assert(fwrite(fid,uint8(header),'uint8')==numel(header),'THERMA:EventWrite','Short header write.');
    writtenRows=0;
    for first=1:options.ChunkRows:inputRows
        last=min(first+options.ChunkRows-1,inputRows);
        time=logs.time_s(first:last)+options.TimeOriginSeconds; time=time(:);
        selected=find(time>=options.StartSeconds & time<=options.EndSeconds);
        if isempty(selected), continue; end
        indices=first-1+selected;
        block=[time(selected) reshape(logs.stored_thermal_energy(indices),[],1) ...
            reshape(logs.net_external_power(indices),[],1) ...
            reshape(logs.stored_energy_derivative(indices),[],1) ...
            sum(logs.prescribed_inputs(indices,2:11),2) ...
            reshape(logs.power_balance_residual(indices),[],1)];
        assert(all(isfinite(block),'all'),'THERMA:EventFinite','Nonfinite event values.');
        text=sprintf('%.17g,%.17g,%.17g,%.17g,%.17g,%.17g\n',block');
        count=fwrite(fid,uint8(text),'uint8');
        assert(count==numel(text),'THERMA:EventWrite','Short event chunk write.');
        [message,number]=ferror(fid);
        assert(number==0,'THERMA:EventWrite','Event write failed: %s',message);
        writtenRows=writtenRows+size(block,1);
    end
    result=fclose(fid); fid=-1;
    assert(result==0,'THERMA:EventClose','Could not flush/close event staging file.');
    assert(writtenRows==expected,'THERMA:EventRows','Not all selected events were written.');
    context.stage='verify_staging';
    verified=boptest_verify_energy_csv(staging,expected);
    checksum=boptest_file_sha256(staging);
    context.stage='copy_to_destination';
    copyErrors={};
    for attempt=1:3
        temporary=[tempname(context.output_directory) '.events.partial'];
        try
            [copied,message,identifier]=copyfile(staging,temporary);
            assert(copied,'THERMA:EventCopy','Copy failed (%s): %s',identifier,message);
            break;
        catch problem
            copyErrors{end+1}=boptest_exception_diagnostic(problem); %#ok<AGROW>
            removeTemporary();
            if attempt==3, rethrow(problem); end
            pause(0.2);
        end
    end
    assert(~isfile(file) && ~isfolder(file),'THERMA:EventDestinationExists', ...
        'Destination appeared during export; refusing to replace it.');
    context.stage='promote_destination';
    [moved,message,identifier]=movefile(temporary,file);
    assert(moved,'THERMA:EventPromote','Cannot publish event file (%s): %s',identifier,message);
    temporary='';
    assert(isfile(file),'THERMA:EventMissing','Published event file is missing.');
    listing=dir(file);
    assert(listing.bytes==verified.file_bytes && listing.bytes>0,'THERMA:EventSize','Final byte count mismatch.');
    context.stage='verify_destination_hash';
    assert(strcmp(boptest_file_sha256(file),checksum),'THERMA:EventHash','Final event file SHA-256 differs from verified staging data.');
    info=context; info.status='verified'; info.verification=verified;
    info.sha256=checksum; info.copy_attempts=attempt; info.copy_errors=copyErrors;
    info.precision='%.17g, binary64 round trip';
    info.verification_method='Bounded staging CSV scan; final byte count and SHA256 identity';
    info.staging_file=[]; success=true;
catch problem
    % Close before diagnosis, preserving the original exception even if cleanup fails.
    if fid>=0, try, fclose(fid); catch, end; fid=-1; end
    if exist('copyErrors','var'), context.copy_errors=copyErrors; end
    context.status='failed'; context.original_exception=boptest_exception_diagnostic(problem);
    context.staging_file=staging;
    diagnostic='unavailable';
    try
        diagnosticParent=options.StagingDirectory;
        if ~isfolder(diagnosticParent), diagnosticParent=tempdir; end
        diagnostic=[tempname(diagnosticParent) '.event_export_failure.json'];
        write_boptest_json(diagnostic,context);
    catch
        diagnostic='unavailable; see original exception and context below';
    end
    fprintf(2,'Event export failed. MATLAB %s\nTarget: %s\nDirectory exists: %d\nRows: %d; numeric bytes estimate: %.0f\nDisk observation: %s\nOriginal: %s: %s\nDiagnostic: %s\n', ...
        context.matlab_version,file,context.directory_exists,expected,context.estimated_numeric_bytes, ...
        context.disk_space_status,problem.identifier,problem.message,diagnostic);
    failure=MException('THERMA:EventExport', ...
        'Event export failed. Context: %s. Diagnostic: %s',jsonencode(context),diagnostic);
    failure=addCause(failure,problem); throw(failure);
end
    function removeTemporary()
        if ~isempty(temporary) && isfile(temporary)
            try, delete(temporary); catch, end
        end
        temporary='';
    end
    function cleanupOwned()
        if fid>=0, try, fclose(fid); catch, end; end
        removeTemporary();
        if success && ~isempty(staging) && isfile(staging)
            try, delete(staging); catch, end
        end
    end
end
