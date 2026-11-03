function valid = boptest_c27_completed(folder,expected)
%BOPTEST_C27_COMPLETED Resume only complete, hash-checked, same-contract full runs.
valid = false;
try
    file = fullfile(folder,'completion.json');
    if ~isfile(file), return; end
    receipt = jsondecode(fileread(file));
    if ~strcmp(receipt.status,'completed') || ~isequal(receipt.expected,expected), return; end
    names = cell(1,numel(receipt.artifacts));
    for j=1:numel(receipt.artifacts)
        if iscell(receipt.artifacts), item=receipt.artifacts{j}; else, item=receipt.artifacts(j); end
        name = item.name;
        if contains(name,'/') || contains(name,'\') || contains(name,':') || strcmp(name,'..'), return; end
        names{j} = name;
        if ~strcmp(boptest_file_sha256(fullfile(folder,name)),item.sha256), return; end
    end
    required = {'evaluation.csv','comparison_metadata.json','replay_run.json', ...
        'solver_metadata.json','energy_events.csv'};
    if ~all(ismember(required,names)), return; end
    report = jsondecode(fileread(fullfile(folder,'replay_run.json')));
    if ~strcmp(report.status,'executed_partial_not_validated') || ...
        ~report.matlab_execution_completed || ~report.simulation_returned || ...
        ~strcmp(report.matlab_version,expected.matlab_version) || ...
        ~strcmp(report.replay_packet_sha256,expected.packet_sha256) || ...
        str2double(report.solver.MaxStep_s)~=expected.max_step_s || ...
        str2double(report.stop_time_s)~=report.replay_metadata.duration_s, return; end
    valid = true;
catch
    % Corrupt/incomplete output never qualifies for resume. Preserve it for diagnosis.
    valid = false;
end
end
