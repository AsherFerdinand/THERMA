function info = boptest_event_export_context(file,rows,inputRows)
%BOPTEST_EVENT_EXPORT_CONTEXT Report observations without inferring a disk-space cause.
folder=fileparts(file); if isempty(folder), folder=pwd; end
info=struct('matlab_version',version,'target_file',char(file),'output_directory',folder, ...
    'directory_exists',isfolder(folder),'is_unc_path',startsWith(char(file),'\\') || startsWith(char(file),'//'), ...
    'row_count',rows,'input_row_count',inputRows,'estimated_numeric_bytes',rows*6*8, ...
    'estimated_csv_upper_bound_bytes',128+rows*192,'available_disk_space_bytes',[], ...
    'disk_space_status','unavailable');
if startsWith(char(file),'\\') && ~ispc
    info.directory_exists=false;
    info.disk_space_status='Windows UNC location is not queried on a non-Windows host';
    return;
end
if info.directory_exists && usejava('jvm')
    try
        directory=java.io.File(folder); available=double(directory.getUsableSpace());
        if available>0 && isfinite(available)
            info.available_disk_space_bytes=available;
            info.disk_space_status='Java getUsableSpace observation; not a quota guarantee';
        else
            info.disk_space_status='zero or unavailable; not treated as proof of no space';
        end
    catch problem
        info.disk_space_status=['query failed: ' problem.identifier];
    end
end
end
