function reportFile = run_boptest_solar_batch(packetFolder,options)
%RUN_BOPTEST_SOLAR_BATCH One entry point; equations/parameters remain unchanged.
% From repository root: addpath('scripts/matlab/boptest');
% run_boptest_solar_batch('path/to/typical_solar_v2');
arguments
    packetFolder (1,1) string
    options.MaxStepSeconds (1,1) double = NaN
end
root = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
file = fullfile(packetFolder,'replay.json');
[metadata,~] = load_boptest_replay(file);
assert(metadata.schema_version==2,'THERMA:SolarBatchSchema','Expected solar v2 packet.');
reportFile = run_boptest_zone_replay(file, ...
    fullfile(root,'configs','references','c2_reduced_assumptions.json'),'AllowPartial',true, ...
    'MaxStepSeconds',options.MaxStepSeconds);
end
