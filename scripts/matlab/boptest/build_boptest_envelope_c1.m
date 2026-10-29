function [model, modelFile, P] = build_boptest_envelope_c1(options)
%BUILD_BOPTEST_ENVELOPE_C1 Generate new editable heat-flow-driven conduction solids.
% No original model/FMU is loaded; no convection, glazing or zone model is added.
arguments
    options.RegistryFile (1,1) string = ""
    options.OutputRoot (1,1) string = ""
    options.ShowModel (1,1) logical = true
end
P = load_boptest_envelope_parameters(options.RegistryFile);
assert((exist('new_system', 'file') ~= 0 || exist('new_system', 'builtin') == 5), 'THERMA:NoSimulink', 'MATLAB/Simulink required.');
model = 'THERMA_BOPTEST_Envelope_C1';
assert(~bdIsLoaded(model), 'THERMA:AlreadyLoaded', ...
    'Close/save your existing %s model before building another.', model);
root = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
if strlength(options.OutputRoot) == 0
    options.OutputRoot = fullfile(root, 'outputs', 'boptest', 'simulink_c1');
end
if ~isfolder(options.OutputRoot), mkdir(options.OutputRoot); end
runDir = tempname(options.OutputRoot);
mkdir(runDir);
modelFile = fullfile(runDir, [model '.slx']);
report = struct('status', 'building', 'matlab_verified', false, ...
    'registry_sha256', P.registry_sha256, 'total_temperature_states', P.total_states);
writeJSON(fullfile(runDir, 'build.json'), report);
load_system('simulink');
new_system(model);
try
    workspace = get_param(model, 'ModelWorkspace');
    assignin(workspace, 'P', P);
    set_param(model, 'SolverType', 'Variable-step', 'Solver', 'ode15s', ...
        'RelTol', '1e-7', 'AbsTol', '1e-9', 'MaxStep', '60', ...
        'StartTime', '0', 'StopTime', '3600', 'ReturnWorkspaceOutputs', 'on');
    add_block('built-in/Subsystem', [model '/Parameters'], 'Position', [260 20 430 80]);
    Simulink.Annotation([model '/Parameters'], sprintf([ ...
        'Model Workspace P: frozen registry SHA-256\n%s\n' ...
        'No base-workspace or initialization callback dependency.\n' ...
        'Material order exterior -> interior; interface capacities summed once.'], P.registry_sha256));
    add_block('simulink/Sources/In1', [model '/q_exterior_W'], ...
        'Port', '1', 'PortDimensions', '5', 'Position', [20 150 50 170]);
    add_block('simulink/Sources/In1', [model '/q_interior_W'], ...
        'Port', '2', 'PortDimensions', '6', 'Position', [20 230 50 250]);
    boundary = [model '/Boundary_Inputs'];
    add_block('built-in/Subsystem', boundary, 'Position', [100 130 220 760]);
    for j = 1:2
        if j == 1, name = 'q_exterior_W'; width = 5; else, name = 'q_interior_W'; width = 6; end
        add_block('simulink/Sources/In1', [boundary '/' name], ...
            'Port', num2str(j), 'PortDimensions', num2str(width), ...
            'Position', [20 j*100 50 j*100+20]);
        split = [name '_split'];
        add_block('simulink/Signal Routing/Demux', [boundary '/' split], ...
            'Outputs', num2str(width), 'Position', [120 j*100 125 j*100+70]);
        add_line(boundary, [name '/1'], [split '/1']);
        for face = 1:width
            outputPort = face + (j-1)*5;
            outputName = sprintf('Boundary_%02d_W', outputPort);
            add_block('simulink/Sinks/Out1', [boundary '/' outputName], ...
                'Port', num2str(outputPort), ...
                'Position', [250+100*(j-1) (outputPort-1)*65+30 280+100*(j-1) (outputPort-1)*65+50]);
            add_line(boundary, sprintf('%s/%d', split, face), [outputName '/1'], 'autorouting', 'on');
        end
    end
    add_line(model, 'q_exterior_W/1', 'Boundary_Inputs/1');
    add_line(model, 'q_interior_W/1', 'Boundary_Inputs/2');
    collector = [model '/Heat_Flow_Outputs'];
    add_block('built-in/Subsystem', collector, 'Position', [630 130 800 760]);
    groups = {'T_exterior_K', 'T_interior_K', 'q_exterior_W', 'q_interior_W', ...
        'E_J', 'dE_dt_W', 'residual_W', 'T_states_K'};
    for g = 1:numel(groups)
        add_block('simulink/Signal Routing/Mux', [collector '/' groups{g}], ...
            'Inputs', '6', 'Position', [860 g*100 865 g*100+65]);
    end
    for face = 1:numel(P.components)
        c = P.components(face);
        expression = sprintf('P.components(%d)', face);
        add_boptest_construction(model, c.name, c, expression, 'heat_flow', ...
            [310 130+(face-1)*115 490 215+(face-1)*115]);
        if ~c.adiabatic_exterior
            add_line(model, sprintf('Boundary_Inputs/%d', face), [c.name '/1'], 'autorouting', 'on');
        end
        add_line(model, sprintf('Boundary_Inputs/%d', face+5), ...
            sprintf('%s/%d', c.name, 2-c.adiabatic_exterior), 'autorouting', 'on');
        inName = sprintf('Construction_%d', face);
        add_block('simulink/Sources/In1', [collector '/' inName], ...
            'Port', num2str(face), 'PortDimensions', num2str(7+c.n_states), ...
            'Position', [20 face*100 50 face*100+20]);
        for g = 1:numel(groups)
            selector = sprintf('Select_%d_%d', face, g);
            if g == 8, indices = sprintf('8:%d', 7+c.n_states); else, indices = num2str(g); end
            add_block('simulink/Signal Routing/Selector', [collector '/' selector], ...
                'NumberOfDimensions', '1', 'InputPortWidth', num2str(7+c.n_states), ...
                'IndexMode', 'One-based', ...
                'IndexOptionArray', {'Index vector (dialog)'}, 'IndexParamArray', {indices}, ...
                'Position', [110+(face-1)*120 g*100 190+(face-1)*120 g*100+30]);
            add_line(collector, [inName '/1'], [selector '/1'], 'autorouting', 'on');
            add_line(collector, [selector '/1'], sprintf('%s/%d', groups{g}, face), 'autorouting', 'on');
        end
        add_line(model, [c.name '/1'], sprintf('Heat_Flow_Outputs/%d', face), 'autorouting', 'on');
    end
    for g = 1:numel(groups)
        output = [groups{g} '_out'];
        add_block('simulink/Sinks/Out1', [collector '/' output], ...
            'Port', num2str(g), 'Position', [950 g*100+20 980 g*100+40]);
        add_line(collector, [groups{g} '/1'], [output '/1']);
        add_block('simulink/Sinks/Out1', [model '/' output], ...
            'Port', num2str(g), 'Position', [1020 140+g*65 1050 160+g*65]);
        add_block('simulink/Sinks/To Workspace', [model '/Log_' groups{g}], ...
            'VariableName', groups{g}, 'SaveFormat', 'Timeseries', ...
            'MaxDataPoints', 'inf', 'Decimation', '1', ...
            'Position', [845 140+g*65 970 165+g*65]);
        add_line(model, sprintf('Heat_Flow_Outputs/%d', g), [output '/1'], 'autorouting', 'on');
        add_line(model, sprintf('Heat_Flow_Outputs/%d', g), ['Log_' groups{g} '/1'], 'autorouting', 'on');
    end
    save_system(model, modelFile);
    writeJSON(fullfile(runDir, 'parameters.json'), P);
    report.status = 'generated_not_compiled';
    report.model_file = [model '.slx'];
    report.component_names = {P.components.name};
    report.state_counts = [P.components.n_states];
    report.interfaces = struct('q_exterior_input_W', {{P.components(1:5).name}}, ...
        'q_interior_input_W', {{P.components.name}}, 'output_groups', {groups});
    writeJSON(fullfile(runDir, 'build.json'), report);
catch problem
    report.status = 'failed';
    report.error = struct('identifier', problem.identifier, 'message', problem.message);
    writeJSON(fullfile(runDir, 'build.json'), report);
    close_system(model, 0);
    rethrow(problem);
end
if options.ShowModel, open_system(model); end
fprintf('Generated (MATLAB compilation/physics checks still required): %s\n', modelFile);
end

function writeJSON(path, value)
fid = fopen(path, 'w', 'n', 'UTF-8');
assert(fid >= 0, 'THERMA:WriteFailed', 'Cannot write output.');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s\n', jsonencode(value, 'PrettyPrint', true));
end
