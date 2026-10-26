function reportFile = diagnose_reference(sourceFile, options)
%DIAGNOSE_REFERENCE Two-stage, non-simulating diagnostics for the pinned thesis SLX.
% First: diagnose_reference("C:/reference/model/Main_SpeedOptimisedVersionTannenweg.slx")
% Review callbacks_review.json and extracted XML BEFORE authorising load/compile.
% See docs/MATLAB_DIAGNOSTICS.md. MATLAB R2024b; no model settings are changed.
arguments
    sourceFile (1,1) string
    options.ReviewedHash (1,1) string = ""
    options.Compile (1,1) logical = false
end
expected = "2b797e2b23320cf9514e1b761efeb7c39d8bf56f761b307776ade23330c1651f";
projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
outputRoot = fullfile(projectRoot, 'outputs', 'matlab');
if ~isfolder(outputRoot), mkdir(outputRoot); end
runDir = string(tempname(outputRoot));
mkdir(runDir);
reportFile = fullfile(runDir, 'diagnostics.json');
r = struct('schema_version', 1, 'workflow', 'THERMA Phase 1B.1', ...
    'expected_sha256', expected, 'load_status', "not_attempted", ...
    'compile_status', "not_requested", 'simulation_status', "not_run", ...
    'errors', {{}}, 'notes', {{}});
r.matlab_version = version;
v = ver;
r.products = rmfield(v, intersect(fieldnames(v), {'Date'}));
r.licences = checkLicences();
% ver returns names/versions, not licence numbers, servers or user identities.
source = ""; originalHash = ""; workDir = ""; model = ""; ownsModel = false;
oldFolder = pwd;
outcome = struct; % Predeclare for evalc in this nested-function/static workspace.
cleanup = onCleanup(@restoreSession);
try
    assert(isfile(sourceFile), 'THERMA:MissingSource', 'Select an existing SLX file.');
    source = string(java.io.File(char(sourceFile)).getCanonicalPath());
    [~, model, extension] = fileparts(source);
    assert(strcmpi(extension, '.slx'), 'THERMA:NotSLX', 'Expected an SLX file.');
    originalHash = sha256(source);
    r.source_sha256 = originalHash;
    r.source_filename = model + extension; % Deliberately omit absolute source path.
    assert(originalHash == expected, 'THERMA:HashMismatch', ...
        'Source differs from the Phase 1A reference. Do not bypass this check.');
    workDir = string(tempname);
    mkdir(workDir);
    copy = fullfile(workDir, model + extension);
    copyfile(source, copy);
    assert(sha256(copy) == originalHash, 'THERMA:CopyMismatch', 'Copy hash mismatch.');
    archiveDir = fullfile(runDir, 'archive_review');
    unzip(copy, archiveDir); % Data extraction only; never load_system in review stage.
    r.archive = inspectArchive(archiveDir);
    writeJSON(fullfile(runDir, 'callbacks_review.json'), r.archive.code_review);
    writeJSON(reportFile, r); % Preserve evidence even if subsequent stages fail.
    fprintf('Review-only evidence written to %s\n', reportFile);
    if options.ReviewedHash ~= originalHash
        r.notes{end+1} = 'Load blocked: review the archive/code and supply ReviewedHash.';
        if options.Compile
            r.compile_status = "blocked_pending_review";
        end
    else
        assert(exist('load_system', 'file') ~= 0, 'THERMA:NoSimulink', ...
            'Simulink is unavailable. Static evidence is retained.');
        assert(~bdIsLoaded(model), 'THERMA:AlreadyLoaded', ...
            'A model with this name is already loaded. Close it yourself before retrying.');
        % Approved callbacks/masks can execute here. This is not a security sandbox.
        cd(workDir);
        ownsModel = true; % Includes a partially loaded model if load_system fails.
        lastwarn('');
        try
            r.load_console = evalc('outcome = attempt(@() load_system(char(copy)));');
            if outcome.succeeded
                r.load_status = "loaded";
            else
                r.load_status = "failed";
                r.errors{end+1} = outcome.error;
            end
        catch problem
            r.load_status = "failed";
            r.errors{end+1} = issue(problem);
        end
        [message, identifier] = lastwarn;
        r.load_last_warning = struct('identifier', identifier, 'message', message);
        writeJSON(reportFile, r);
        if r.load_status == "loaded"
            % Each inspection stage is isolated so a failed query cannot lose the rest.
            stages = {'solver', 'workspace', 'blocks', 'controllers'};
            for k = 1:numel(stages)
                try
                    switch stages{k}
                        case 'solver'
                            r.solver = inspectSolver(model);
                        case 'workspace'
                            r.workspace = inspectWorkspace(model);
                        case 'blocks'
                            r.blocks = inspectBlocks(model);
                        case 'controllers'
                            r.controllers = inspectControllers(model);
                    end
                catch problem
                    r.errors{end+1} = issue(problem);
                end
                writeJSON(reportFile, r);
            end
            if options.Compile
                % Compile only: never sim(), change switch/parameters, or save_system().
                lastwarn('');
                try
                    r.compile_console = evalc('outcome = attempt(@() feval(char(model), [], [], [], ''compile''));');
                    if outcome.succeeded
                        r.compile_status = "compiled";
                        r.compiled_ports = inspectCompiledPorts(model);
                    else
                        r.compile_status = "failed";
                        r.errors{end+1} = outcome.error;
                    end
                catch problem
                    r.errors{end+1} = issue(problem);
                    if r.compile_status == "compiled"
                        r.notes{end+1} = 'Compile succeeded; compiled-port inspection failed.';
                    else
                        r.compile_status = "failed";
                    end
                end
                [message, identifier] = lastwarn;
                r.compile_last_warning = struct('identifier', identifier, 'message', message);
                try
                    r.terminate_console = evalc('feval(char(model), [], [], [], ''term'');');
                catch problem
                    r.errors{end+1} = issue(problem);
                end
            end
        end
    end
catch problem
    r.errors{end+1} = issue(problem);
end
% Close our copy without saving BEFORE the final original-file preservation check.
restoreSession();
clear cleanup;
r.source_unchanged = []; % Unknown until verified, not a fabricated false/pass result.
try
    if strlength(source) > 0 && strlength(originalHash) > 0
        r.source_sha256_after = sha256(source);
        r.source_unchanged = r.source_sha256_after == originalHash;
    end
catch problem
    r.errors{end+1} = issue(problem);
end
r.notes{end+1} = ['Saved fields are not necessarily active physical parameters. ' ...
    'Missing compiled physical units and local-controller behaviour remain unresolved.'];
writeJSON(reportFile, r);
fprintf('Diagnostic report: %s\n', reportFile);

    function restoreSession()
        % Never close an unrelated/pre-existing model and never save the copy.
        if ownsModel
            try
                if bdIsLoaded(model), close_system(model, 0); end
                ownsModel = false;
            catch problem
                r.errors{end+1} = issue(problem);
            end
        end
        try
            cd(oldFolder);
        catch problem
            r.errors{end+1} = issue(problem);
        end
        if strlength(workDir) > 0 && isfolder(workDir) && ~ownsModel
            try
                rmdir(workDir, 's');
            catch problem
                r.errors{end+1} = issue(problem);
            end
        end
    end
end

function hash = sha256(file)
fid = fopen(file, 'rb');
assert(fid ~= -1, 'THERMA:ReadFailed', 'Cannot read file for hashing.');
cleanup = onCleanup(@() fclose(fid));
digest = java.security.MessageDigest.getInstance('SHA-256');
while ~feof(fid)
    bytes = fread(fid, 1024*1024, '*uint8');
    digest.update(typecast(bytes, 'int8'));
end
hash = string(lower(reshape(dec2hex(typecast(digest.digest(), 'uint8'), 2).', 1, [])));
end

function writeJSON(file, value)
fid = fopen(file, 'w', 'n', 'UTF-8');
assert(fid ~= -1, 'THERMA:WriteFailed', 'Cannot write local diagnostic output.');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s\n', jsonencode(value, 'PrettyPrint', true, 'ConvertInfAndNaN', true));
end

function outcome = attempt(action)
% Catch inside evalc so warnings printed before an error are retained as well.
outcome = struct('succeeded', false, 'error', []);
try
    action();
    outcome.succeeded = true;
catch problem
    outcome.error = issue(problem);
end
end

function result = issue(problem)
% Keep stack paths/license server details out of structured error records.
% MATLAB console text may still contain local details: review before sharing outputs.
result = struct('identifier', problem.identifier, 'message', problem.message);
end

function archive = inspectArchive(folder)
files = dir(fullfile(folder, '**', '*.xml'));
archive = struct('systems', {{}}, 'code_review', {{}}, 'notes', {{}});
for k = 1:numel(files)
    file = fullfile(files(k).folder, files(k).name);
    relative = erase(string(file), string(folder) + filesep);
    document = xmlread(file);
    % Review all named callback/function/script fields, not only known model callbacks.
    properties = document.getElementsByTagName('P');
    for j = 0:properties.getLength()-1
        node = properties.item(j);
        name = string(node.getAttribute('Name'));
        text = string(node.getTextContent());
        if ~isempty(regexpi(name, 'Fcn$|callback|initialization|script|code|DataSource')) ...
                && strlength(strtrim(text)) > 0
            archive.code_review{end+1} = struct('file', relative, 'field', name, 'text', text);
        end
    end
    % Mask initialization/callbacks may be XML elements rather than P fields.
    for tag = ["Initialization", "Callback", "Script", "Display"]
        nodes = document.getElementsByTagName(char(tag));
        for j = 0:nodes.getLength()-1
            text = string(nodes.item(j).getTextContent());
            if strlength(strtrim(text)) > 0
                archive.code_review{end+1} = struct('file', relative, 'field', tag, 'text', text);
            end
        end
    end
    if startsWith(files(k).name, 'system_')
        system = document.getDocumentElement();
        blocks = children(system, 'Block');
        entry = struct('file', files(k).name, 'blocks', {{}}, 'lines', {{}});
        for j = 1:numel(blocks)
            b = blocks{j};
            entry.blocks{end+1} = struct('sid', string(b.getAttribute('SID')), ...
                'name', string(b.getAttribute('Name')), ...
                'type', string(b.getAttribute('BlockType')), ...
                'properties', {propertiesOf(b)}, 'child_system', childRef(b));
        end
        lines = children(system, 'Line');
        for j = 1:numel(lines)
            % Include nested Branch Src/Dst fields; preserve raw port IDs and order.
            entry.lines{end+1} = propertiesOf(lines{j});
        end
        archive.systems{end+1} = entry;
    end
end
archive.notes = {'Code-field discovery is an aid, not a security proof. Review all extracted XML, masks, workspace data sources, S-functions and external dependencies before load/compile.'};
archive.room_and_valve_mapping = mapRoomsAndValves(archive.systems);
end

function nodes = children(parent, tag)
nodes = {};
child = parent.getFirstChild();
while ~isempty(child)
    if strcmp(char(child.getNodeName()), tag), nodes{end+1} = child; end
    child = child.getNextSibling();
end
end

function list = propertiesOf(node)
list = {};
nodes = node.getElementsByTagName('P');
for k = 0:nodes.getLength()-1
    p = nodes.item(k);
    list{end+1} = struct('name', string(p.getAttribute('Name')), 'value', string(p.getTextContent()));
end
end

function ref = childRef(node)
nodes = children(node, 'System');
ref = "";
if ~isempty(nodes), ref = string(nodes{1}.getAttribute('Ref')); end
end

function value = property(block, name, fallback)
if nargin < 3, fallback = ""; end
value = fallback;
for k = 1:numel(block.properties)
    if block.properties{k}.name == name
        value = block.properties{k}.value;
        return;
    end
end
end

function mapping = mapRoomsAndValves(systems)
% Follow saved floor Mux wiring, never assign room IDs by alphabetical ordering.
mapping = struct('rooms', {{}}, 'selectors', {{}}, 'valves', {{}}, 'unresolved', {{}});
for k = 1:numel(systems)
    system = systems{k};
    for j = 1:numel(system.blocks)
        b = system.blocks{j};
        if b.type == "Selector"
            mapping.selectors{end+1} = struct('system', system.file, 'sid', b.sid, ...
                'index_expression', property(b, 'Indices'), 'input_width', property(b, 'InputPortWidth'), ...
                'path', systemPath(systems, system.file) + "/" + b.name);
        end
        if contains(property(b, 'SourceBlock'), 'Gate Valve')
            mapping.valves{end+1} = struct('system', system.file, 'sid', b.sid, 'name', b.name, ...
                'parameters', {b.properties}, 'path', systemPath(systems, system.file) + "/" + b.name);
        end
        if ~isempty(regexp(b.name, '^Raum\d+$', 'once'))
            row = struct('floor_system', system.file, 'room_name', b.name, ...
                'room_sid', b.sid, 'room_system', b.child_system, 'floor_mux_port', "", ...
                'tag', "", 'global_index', [], 'path', systemPath(systems, system.file) + "/" + b.name, ...
                'evidence', "unresolved");
            % Raum output -> Goto(tag); From(tag) -> floor Mux input.
            gotoSID = destination(system, b.sid + "#out:1");
            g = blockBySID(system, extractBefore(gotoSID, '#'));
            if ~isempty(g) && g.type == "Goto"
                row.tag = property(g, 'GotoTag');
                for n = 1:numel(system.blocks)
                    f = system.blocks{n};
                    if f.type == "From" && property(f, 'GotoTag') == row.tag
                        target = destination(system, f.sid + "#out:1");
                        mux = blockBySID(system, extractBefore(target, '#'));
                        if ~isempty(mux) && mux.type == "Mux"
                            row.floor_mux_port = extractAfter(target, '#in:');
                            row.evidence = "saved_room_to_tag_to_floor_mux_wiring";
                        end
                    end
                end
            end
            mapping.rooms{end+1} = row;
        end
    end
end
% Derive global indices only when the root floor-Mux order is unambiguous.
root = systems{find(cellfun(@(s) strcmp(s.file, 'system_root.xml'), systems), 1)};
for k = 1:numel(mapping.rooms)
    row = mapping.rooms{k};
    floorBlock = [];
    for j = 1:numel(root.blocks)
        if root.blocks{j}.child_system + ".xml" == row.floor_system
            floorBlock = root.blocks{j};
        end
    end
    if ~isempty(floorBlock) && strlength(row.floor_mux_port) > 0
        g = blockBySID(root, extractBefore(destination(root, floorBlock.sid + "#out:1"), '#'));
        if ~isempty(g)
            for j = 1:numel(root.blocks)
                f = root.blocks{j};
                if f.type == "From" && property(f, 'GotoTag') == property(g, 'GotoTag')
                    target = destination(root, f.sid + "#out:1");
                    memory = blockBySID(root, extractBefore(target, '#'));
                    if ~isempty(memory) && memory.type == "Memory"
                        target = destination(root, memory.sid + "#out:1");
                    end
                    mux = blockBySID(root, extractBefore(target, '#'));
                    if ~isempty(mux) && mux.type == "Mux" && property(mux, 'Inputs') == "3" ...
                            && numel(mapping.rooms) == 36
                        % Pinned model: three equal-width floor vectors, verified below.
                        counts = cellfun(@(x) sum(cellfun(@(y) strcmp(y.floor_system, x.floor_system), ...
                            mapping.rooms)), mapping.rooms);
                        if all(counts == 12)
                            row.global_index = (str2double(extractAfter(target, '#in:')) - 1)*12 ...
                                + str2double(row.floor_mux_port);
                        end
                    end
                end
            end
        end
    end
    mapping.rooms{k} = row;
end
indices = cellfun(@(x) str2double(x.index_expression), mapping.selectors);
mapping.missing_selector_indices = setdiff(1:36, indices);
for k = 1:numel(mapping.valves)
    valve = mapping.valves{k};
    valve.selector_paths = {};
    heaterPath = systemPath(systems, valve.system);
    for j = 1:numel(mapping.selectors)
        selector = mapping.selectors{j};
        if startsWith(selector.path, heaterPath + "/")
            valve.selector_paths{end+1} = selector;
        end
    end
    mapping.valves{k} = valve;
end
mapping.missing_actuation_rooms = {};
for k = 1:numel(mapping.rooms)
    row = mapping.rooms{k};
    if ~isempty(row.global_index) && ismember(row.global_index, mapping.missing_selector_indices)
        row.saved_gate_valve_count = sum(cellfun(@(x) startsWith(x.path, row.path + "/"), mapping.valves));
        mapping.missing_actuation_rooms{end+1} = row;
    end
end
mapping.unresolved = {'Global indices are derived from saved Mux/tag/Memory wiring, not compilation. Empty indices mean tracing was ambiguous. Verify vector widths, scoped tags and active variants in MATLAB.', ...
    'Missing selectors identify uncommanded room indices, not author intent. Use room paths, valve paths and raw physical-port connections to explain the omission; do not reconstruct a scenario.'};
end

function path = systemPath(systems, file)
% Walk parent references in this pinned model's acyclic saved subsystem hierarchy.
path = "";
ref = erase(string(file), '.xml');
for depth = 1:numel(systems)
    if ref == "system_root", path = strip(path, 'right', "/"); return; end
    found = false;
    for k = 1:numel(systems)
        for j = 1:numel(systems{k}.blocks)
            b = systems{k}.blocks{j};
            if b.child_system == ref
                path = b.name + "/" + path;
                ref = erase(string(systems{k}.file), '.xml');
                found = true;
                break;
            end
        end
        if found, break; end
    end
    if ~found, path = "unresolved/" + path; return; end
end
error('THERMA:HierarchyCycle', 'Saved subsystem hierarchy is cyclic.');
end

function block = blockBySID(system, sid)
block = [];
for k = 1:numel(system.blocks)
    if system.blocks{k}.sid == sid, block = system.blocks{k}; return; end
end
end

function target = destination(system, source)
target = "";
for k = 1:numel(system.lines)
    fields = system.lines{k};
    sources = {}; targets = {};
    for j = 1:numel(fields)
        if fields{j}.name == "Src", sources{end+1} = fields{j}.value; end
        if fields{j}.name == "Dst", targets{end+1} = fields{j}.value; end
    end
    if numel(sources) == 1 && sources{1} == source && numel(targets) == 1
        target = targets{1}; return;
    end
end
end

function licences = checkLicences()
features = {'SIMULINK', 'Simscape', 'Simscape_Fluids', 'Stateflow'};
licences = {};
for k = 1:numel(features)
    try
        licences{end+1} = struct('feature', features{k}, 'available', logical(license('test', features{k})));
    catch problem
        licences{end+1} = struct('feature', features{k}, 'error', issue(problem));
    end
end
end

function solver = inspectSolver(model)
solver = struct;
for field = ["SolverType", "Solver", "StartTime", "StopTime", "RelTol", "AbsTol", ...
        "MaxStep", "FixedStep", "SignalLogging", "SignalLoggingName", "SimscapeLogType"]
    try
        solver.(field) = get_param(model, field);
    catch problem
        solver.(field) = issue(problem);
    end
end
% Resolve duration only as literal numeric arithmetic, never arbitrary eval of text.
solver.duration_seconds = [];
start = str2double(string(solver.StartTime));
stopText = string(solver.StopTime);
parts = split(stopText, '*');
values = str2double(parts);
if isfinite(start) && ~isempty(values) && all(isfinite(values))
    solver.duration_seconds = prod(values) - start;
end
end

function workspace = inspectWorkspace(model)
w = get_param(model, 'ModelWorkspace');
variables = whos(w);
workspace = struct('data_source', w.DataSource, 'variables', {{}});
for k = 1:numel(variables)
    info = variables(k);
    item = struct('name', info.name, 'class', info.class, 'size', info.size, 'value', []);
    % Restrict export to known scientific variables; do not dump the base workspace.
    if ismember(string(info.name), ["Ti","fa","fd","ips","ma","md","roomarea1","s"])
        value = getVariable(w, info.name);
        if isnumeric(value) && numel(value) <= 1000, item.value = value; end
    end
    workspace.variables{end+1} = item;
end
end

function blocks = inspectBlocks(model)
paths = find_system(model, 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'Type', 'Block');
blocks = {};
for k = 1:numel(paths)
    b = paths{k};
    item = struct('path', b, 'type', get_param(b, 'BlockType'), 'parameters', {{}}, ...
        'port_connectivity', {{}}, 'query_errors', {{}});
    names = {};
    try
        params = get_param(b, 'DialogParameters');
        if isstruct(params), names = fieldnames(params); end
    catch problem
        item.query_errors{end+1} = issue(problem);
    end
    % Query effective dialog fields, preserving expressions and paired unit fields.
    for j = 1:numel(names)
        try
            value = get_param(b, names{j});
            if ischar(value) || isstring(value) || isnumeric(value) || islogical(value)
                p = struct('name', names{j}, 'expression', value, 'resolved_numeric', []);
                % Only known arithmetic fields: slResolve can execute expressions,
                % hence it is used only after explicit archive review authorisation.
                if ismember(string(names{j}), ["Value","Gain","Indices","Denominator", ...
                        "mass","sp_heat","T","area","diam_orifice","Dh","length","T_I", ...
                        "mdot0","T0","p0","flow_rate_1D_TLU","head_1D_TLU","power_1D_TLU"])
                    try
                        resolved = slResolve(char(string(value)), b);
                        if isnumeric(resolved) && numel(resolved) <= 1000, p.resolved_numeric = resolved; end
                    catch problem
                        item.query_errors{end+1} = issue(problem);
                    end
                end
                item.parameters{end+1} = p;
            end
        catch problem
            item.query_errors{end+1} = issue(problem);
        end
    end
    for field = ["ReferenceBlock", "LinkStatus", "Commented", "CurrentSetting", ...
            "MaskNames", "MaskEnables", "MaskVisibilities"]
        try
            item.(field) = get_param(b, field);
        catch
            % Fields do not apply to every block.
        end
    end
    ports = get_param(b, 'PortConnectivity');
    for j = 1:numel(ports)
        port = ports(j);
        % Convert numeric handles to portable model paths, not session-local IDs.
        item.port_connectivity{end+1} = struct('type', port.Type, ...
            'source_blocks', {handlePaths(port.SrcBlock)}, 'source_ports', port.SrcPort, ...
            'destination_blocks', {handlePaths(port.DstBlock)}, 'destination_ports', port.DstPort);
    end
    blocks{end+1} = item;
end
end

function paths = handlePaths(handles)
paths = {};
for k = 1:numel(handles)
    if handles(k) > 0, paths{end+1} = getfullname(handles(k)); end
end
end

function controllers = inspectControllers(model)
controllers = struct('embedded_functions', {{}}, 'thermostat_candidates', {{}});
root = sfroot;
charts = root.find('-isa', 'Stateflow.EMChart');
for k = 1:numel(charts)
    if startsWith(string(charts(k).Path), string(model) + "/")
        controllers.embedded_functions{end+1} = struct('path', charts(k).Path, 'script', charts(k).Script);
    end
end
paths = find_system(model, 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'Type', 'Block');
for k = 1:numel(paths)
    type = get_param(paths{k}, 'BlockType');
    if ismember(string(type), ["Relay","Switch","RelaySwitch","Logic","RelationalOperator"]) ...
            || contains(lower(string(paths{k})), ["thermostat", "hysteresis"])
        controllers.thermostat_candidates{end+1} = struct('path', paths{k}, 'type', type);
    end
end
controllers.note = 'Candidates are not proof of a local thermostat. Inspect controller code, connectivity and relay ownership.';
end

function ports = inspectCompiledPorts(model)
ports = {};
paths = find_system(model, 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'Type', 'Block');
for k = 1:numel(paths)
    item = struct('path', paths{k});
    for field = ["CompiledPortUnits", "CompiledPortDimensions", "CompiledSampleTime"]
        try
            item.(field) = get_param(paths{k}, field);
        catch problem
            item.(field) = issue(problem);
        end
    end
    ports{end+1} = item;
end
% CompiledPortUnits describes Simulink ports, NOT every Simscape conserving port.
end
