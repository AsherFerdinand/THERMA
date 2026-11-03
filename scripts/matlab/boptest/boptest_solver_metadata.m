function boptest_solver_metadata(folder,report)
%BOPTEST_SOLVER_METADATA Export actual execution settings; never invent missing values.
metadata = struct('schema_version',1,'status',report.status, ...
    'matlab_version',report.matlab_version,'simulink',report.simulink, ...
    'matlab_execution_completed',report.matlab_execution_completed, ...
    'simulation_returned',report.simulation_returned, ...
    'replay_packet_sha256',report.replay_packet_sha256);
optional = {'model_version','registry_sha256','assumptions_sha256','driver_source_sha256', ...
    'solver','start_time_s','stop_time_s','elapsed_simulation_s','simulation_mat_saved'};
for j=1:numel(optional)
    field = optional{j};
    if isfield(report,field), metadata.(field) = report.(field); end
end
files = {'evaluation.csv','comparison_metadata.json','energy_events.csv','trajectory.csv', ...
    'simulation.mat','replay_run.json'};
artifacts = {};
for j=1:numel(files)
    file = fullfile(folder,files{j});
    if isfile(file)
        artifacts{end+1} = struct('name',files{j},'sha256',boptest_file_sha256(file)); %#ok<AGROW>
    end
end
metadata.artifacts = artifacts;
write_boptest_json(fullfile(folder,'solver_metadata.json'),metadata);
end
