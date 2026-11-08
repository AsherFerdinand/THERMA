function output = run_c42b_flexlab_inspection(sourceRoot)
%RUN_C42B_FLEXLAB_INSPECTION Inspect measured Cell3B data; never simulate.
% Download the six original CSVs with original subfolders (see C42B audit).
root = fileparts(mfilename('fullpath'));
if nargin < 1
    sourceRoot = fullfile(root,'data','reference_building','raw','flexlab');
end
addpath(fullfile(root,'scripts','matlab','boptest'));
audit = jsondecode(fileread(fullfile(root,'docs','results','c42b','source_audit.json')));
startTime = datetime(2021,6,23,0,0,0);
endTime = datetime(2021,6,23,12,0,0);
expected = (startTime:minutes(1):endTime)';
names = cellstr(string(audit.selected_core_files));
data = cell(size(names));
records = struct('source',{},'sha256',{},'channels',{},'full_rows',{}, ...
    'full_missing_cells',{},'full_nonfinite_cells',{},'full_gap_count',{}, ...
    'full_interval_seconds',{},'selected_rows',{},'selected_missing_cells',{});
for k = 1:numel(names)
    file = fullfile(sourceRoot,names{k});
    assert(isfile(file),'THERMA:C42BMissingSource', ...
        'Download the original CSV, preserving its folder: %s',names{k});
    match = find(strcmp({audit.files.path},names{k}));
    assert(isscalar(match),'THERMA:C42BManifest','Ambiguous source manifest.');
    hash = boptest_file_sha256(file);
    assert(strcmp(hash,audit.files(match).sha256),'THERMA:C42BHash', ...
        'File differs from pinned upstream bytes: %s',names{k});
    opts = detectImportOptions(file,'VariableNamingRule','preserve');
    opts = setvartype(opts,opts.VariableNames(1),'char');
    opts = setvartype(opts,opts.VariableNames(2:end),'double');
    tableData = readtable(file,opts);
    if k <= 4
        format = 'M/d/yyyy H:mm';
    else
        format = 'yyyy-MM-dd HH:mm:ss';
    end
    times = datetime(string(tableData{:,1}),'InputFormat',format);
    assert(~any(isnat(times)) && all(diff(times)>seconds(0)), ...
        'THERMA:C42BTime','Invalid, duplicate or unordered timestamps.');
    values = tableData{:,2:end};
    selected = times>=startTime & times<=endTime;
    assert(isequal(times(selected),expected),'THERMA:C42BGap', ...
        'Selected period does not have all721 unaltered minute records.');
    assert(all(isfinite(values(selected,:)),'all'),'THERMA:C42BMissing', ...
        'Selected source values must be finite; no interpolation is allowed.');
    data{k} = values(selected,:);
    records(k) = struct('source',names{k},'sha256',hash, ...
        'channels',{tableData.Properties.VariableNames(2:end)}, ...
        'full_rows',height(tableData),'full_missing_cells',sum(isnan(values),'all'), ...
        'full_nonfinite_cells',sum(~isfinite(values),'all'), ...
        'full_gap_count',sum(seconds(diff(times))~=60), ...
        'full_interval_seconds',unique(seconds(diff(times)))', ...
        'selected_rows',sum(selected), ...
        'selected_missing_cells',sum(~isfinite(data{k}),'all'));
    fprintf('\n%s: %d rows; selected %d; missing in full file %d\n', ...
        names{k},height(tableData),sum(selected),records(k).full_missing_cells);
    disp(string(records(k).channels)');
end
% Names, not numeric guesses, select the inspected variables.
weatherNames = records(2).channels;
coolingNames = records(5).channels;
outdoorColumn = find(strcmp(weatherNames,'W-OAT-2'));
coolingColumn = find(strcmp(coolingNames,'Total cooling rate [W]'));
assert(isscalar(outdoorColumn) && isscalar(coolingColumn), ...
    'THERMA:C42BChannel','Required documented channels are absent.');
indoor = mean(data{1},2); % unweighted arithmetic mean of26 supplied sensors
outdoor = data{2}(:,outdoorColumn);
cooling = data{5}(:,coolingColumn); % retain signed source values, no clamp
hours = seconds(expected-startTime)/3600;
parent = fullfile(root,'outputs','c4','c42b');
if ~isfolder(parent), mkdir(parent); end
output = tempname(parent);
mkdir(output);
f = figure('Color','w');
plot(hours,indoor,'LineWidth',1.3); hold on;
plot(hours,outdoor,'LineWidth',1.3); grid on;
xlabel('Hours since2021-06-23 00:00 PST (UTC-08)'); ylabel('Temperature (degC)');
legend('Cell3B air: arithmetic mean of26 sensors','Outdoor: W-OAT-2','Location','best');
title('Authentic FLEXLAB measurements; no model prediction');
exportgraphics(f,fullfile(output,'measured_temperatures.png'),'Resolution',200);
g = figure('Color','w');
plot(hours,cooling,'LineWidth',1.2); grid on;
xlabel('Hours since2021-06-23 00:00 PST (UTC-08)'); ylabel('Source cooling rate (W)');
title('FCU total cooling: water-side derived, signed values retained');
exportgraphics(g,fullfile(output,'measured_cooling.png'),'Resolution',200);
summary = struct('status','authentic_data_inspected_not_simulated', ...
    'matlab_version',version,'source_commit',audit.source_commit, ...
    'timezone','PST fixed UTC-08:00; no DST', ...
    'start_inclusive','2021-06-23 00:00:00', ...
    'end_inclusive','2021-06-23 12:00:00','sampling_seconds',60, ...
    'selected_rows_per_source',numel(expected),'sources',records, ...
    'indoor_aggregation','unweighted arithmetic mean of26 source channels', ...
    'initial_fabric_states_known',false,'simulation_performed',false, ...
    'empirical_validation_performed',false,'measurements_modified',false, ...
    'cooling_negative_samples',sum(cooling<0));
write_boptest_json(fullfile(output,'inspection_summary.json'),summary);
fprintf('\nInspection only; no building simulation or validation.\nOutput: %s\n',output);
end
