function P = load_boptest_envelope_parameters(registryFile)
%LOAD_BOPTEST_ENVELOPE_PARAMETERS Read the frozen Phase A registry, no defaults.
% IDEAS f1fdd8b: Material.mo:27-40, MonoLayerDynamic.mo:8-39,
% MultiLayer.mo:88-119. Nodes here are ordered exterior -> interior.
arguments
    registryFile (1,1) string = ""
end
root = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
if strlength(registryFile) == 0
    registryFile = fullfile(root, 'configs', 'references', 'boptest_bestest_hydronic.json');
end
assert(isfile(registryFile), 'THERMA:MissingRegistry', 'Registry does not exist.');
actualHash = sha256(registryFile);
expectedHash = "f91141d78668908525d484a4900dc69af1a163c4c5e07f5a5fbd0c43eae4451c";
assert(actualHash == expectedHash, 'THERMA:RegistryIdentity', ...
    'Registry differs from the reviewed Phase A snapshot; do not bypass this check.');
registry = jsondecode(fileread(registryFile));
assert(registry.schema_version == 1, 'THERMA:RegistrySchema', 'Unsupported registry schema.');
assert(strcmp(registry.repositories.boptest.commit, ...
    'a29024f8c453517ccbd1186006a3fa6af8de1ae2'), 'THERMA:Revision', 'Wrong BOPTEST revision.');
assert(strcmp(registry.repositories.ideas.commit, ...
    'f1fdd8b22d39dc50297c47b6433e44381e40d0ff'), 'THERMA:Revision', 'Wrong IDEAS revision.');
entries = registry.parameters;
if isstruct(entries), entries = num2cell(entries); end
assert(iscell(entries), 'THERMA:RegistrySchema', 'Parameters must be an object array.');
ids = strings(numel(entries),1);
for index = 1:numel(entries), ids(index) = string(entries{index}.id); end
assert(numel(unique(ids)) == numel(ids), 'THERMA:DuplicateID', 'Duplicate registry IDs.');
P = struct('schema_version', 1, 'registry_sha256', actualHash, ...
    'boptest_commit', registry.repositories.boptest.commit, ...
    'ideas_commit', registry.repositories.ideas.commit, ...
    'ordering', 'exterior_to_interior', 'boundary_mode', 'heat_flow', ...
    'source_addRes_b', false);
P.geometry.length_m = number('building.length', 'm');
P.geometry.width_m = number('building.width', 'm');
P.geometry.height_m = number('building.height', 'm');
P.geometry.window_m2 = number('building.window_area', 'm2');
P.geometry.floor_m2 = number('building.floor_area', 'm2');
P.geometry.volume_m3 = number('building.volume', 'm3');
near(P.geometry.floor_m2, P.geometry.length_m*P.geometry.width_m, 'Floor area');
near(P.geometry.volume_m3, P.geometry.floor_m2*P.geometry.height_m, 'Zone volume');
initialTemperature = number('building.initial_temperature', 'K');
for flag = ["use_T_fixed", "use_T_in", "use_Q_in"]
    e = entry("floor." + flag);
    assert(islogical(e.value) && ~e.value, 'THERMA:FloorBoundary', ...
        'Floor no longer has an adiabatic outer boundary.');
end
names = {'South_Wall', 'North_Wall', 'East_Wall', 'West_Wall', 'Roof', 'Floor'};
kinds = {'wall', 'wall', 'wall', 'wall', 'roof', 'floor'};
areas = {'building.wall_south_opaque_area', 'building.wall_north_opaque_area', ...
    'building.wall_east_opaque_area', 'building.wall_west_opaque_area', ...
    'building.roof_area', 'building.floor_area'};
expectedAreas = [P.geometry.length_m*P.geometry.height_m-P.geometry.window_m2, ...
    P.geometry.length_m*P.geometry.height_m, ...
    P.geometry.width_m*P.geometry.height_m, P.geometry.width_m*P.geometry.height_m, ...
    P.geometry.floor_m2, P.geometry.floor_m2];
% Explicit schema: indexed assignment must never target a fieldless struct.
layerTemplate = struct('material', '', 'd_m', [], 'k_W_mK', [], ...
    'rho_kg_m3', [], 'cp_J_kgK', [], 'n_source', [], ...
    'R_K_W', [], 'C_J_K', [], 'local_C_J_K', []);
for face = 1:numel(names)
    kind = kinds{face};
    area = number(areas{face}, 'm2');
    near(area, expectedAreas(face), names{face});
    layerEntries = find(startsWith(ids, kind + ".layer") & endsWith(ids, '.material'));
    nLayers = numel(layerEntries);
    assert(nLayers >= 1, 'THERMA:MissingLayer', 'No material layers for %s.', kind);
    component = struct('name', names{face}, 'kind', kind, 'area_m2', area, ...
        'adiabatic_exterior', strcmp(kind, 'floor'), 'layers', [], ...
        'C_J_K', [], 'G_W_K', [], 'layer_nodes', {{}}, 'source_local_nodes', {{}});
    component.layers = repmat(layerTemplate, 1, nLayers);
    for layer = 1:nLayers
        prefix = sprintf('%s.layer%d', kind, layer);
        material = entry(prefix + ".material");
        assert(ischar(material.value) || isstring(material.value), ...
            'THERMA:Material', 'Material name must be text.');
        d = number(prefix + ".thickness", 'm');
        k = number(prefix + ".k", 'W/(m.K)');
        rho = number(prefix + ".rho", 'kg/m3');
        cp = number(prefix + ".c", 'J/(kg.K)');
        n = number(prefix + ".material_node_count", '1');
        % Discretisation constants below come from pinned Material.mo, not
        % assumed physical properties. Compare to the independently extracted count.
        nCalculated = max(2, ceil(3*d/sqrt(k/(rho*cp))/224));
        assert(n == nCalculated && n == fix(n), 'THERMA:NodeCount', ...
            'Inconsistent material node count: %s.', prefix);
        R = d/(k*area);
        C = rho*cp*d*area;
        near(R*area, number(prefix + ".R_areal", 'm2.K/W'), prefix + " R");
        near(C/area, number(prefix + ".C_areal", 'J/(m2.K)'), prefix + " C");
        if n <= 2
            weights = ones(1, n)/n;
        else
            weights = [0.5, ones(1, n-2), 0.5]/(n-1);
        end
        capacities = C*weights;
        if layer == 1
            first = 1;
            component.C_J_K = capacities;
        else
            first = numel(component.C_J_K);
            % Same interface temperature, two DISTINCT material contributions.
            component.C_J_K(end) = component.C_J_K(end) + capacities(1);
            component.C_J_K = [component.C_J_K, capacities(2:end)];
        end
        component.G_W_K = [component.G_W_K, repmat((n-1)/R, 1, n-1)];
        component.layer_nodes{layer} = first:first+n-1;
        component.source_local_nodes{layer} = n:-1:1;
        component.layers(layer) = struct('material', material.value, 'd_m', d, ...
            'k_W_mK', k, 'rho_kg_m3', rho, 'cp_J_kgK', cp, 'n_source', n, ...
            'R_K_W', R, 'C_J_K', C, 'local_C_J_K', capacities);
    end
    component.n_states = numel(component.C_J_K);
    component.R_total_K_W = sum([component.layers.R_K_W]);
    component.C_total_J_K = sum([component.layers.C_J_K]);
    component.reference_K = initialTemperature;
    component.initial_K = ones(1, component.n_states)*initialTemperature;
    near(sum(1./component.G_W_K), component.R_total_K_W, names{face} + " network R");
    near(sum(component.C_J_K), component.C_total_J_K, names{face} + " network C");
    near(component.R_total_K_W*area, ...
        number(kind + ".R_material_areal", 'm2.K/W'), names{face} + " registry R");
    if face == 1
        P.components = component;
    else
        P.components(face) = component;
    end
end
near(sum([P.components(1:4).area_m2]), ...
    number('building.wall_total_opaque_area', 'm2'), 'Opaque wall area');
for kind = ["wall", "roof", "floor"]
    members = strcmp({P.components.kind}, kind);
    near(sum([P.components(members).C_total_J_K]), ...
        number(kind + ".C_material_total", 'J/K'), kind + " total capacity");
end
P.total_states = sum([P.components.n_states]);

    function e = entry(id)
        index = find(ids == string(id));
        assert(numel(index) == 1, 'THERMA:MissingParameter', 'Missing parameter: %s.', id);
        e = entries{index};
        assert(ismember(string(e.status), ["explicit", "derived"]) && ...
            isfield(e, 'sources') && ~isempty(e.sources), 'THERMA:Unverified', ...
            'Parameter lacks verified source provenance: %s.', id);
    end

    function value = number(id, unit)
        e = entry(id);
        assert(strcmp(e.unit, unit), 'THERMA:Units', 'Wrong units for %s.', id);
        validateattributes(e.value, {'numeric'}, {'real', 'scalar', 'finite', 'positive'}, ...
            mfilename, char(id));
        value = double(e.value);
    end
end

function near(actual, expected, label)
% Arithmetic consistency only: 64 binary64 ULPs, not a physical validation tolerance.
assert(abs(actual-expected) <= 64*eps(max(1, abs(expected))), ...
    'THERMA:InconsistentParameter', 'Inconsistent %s.', label);
end

function hash = sha256(file)
fid = fopen(file, 'rb');
assert(fid >= 0, 'THERMA:ReadFailed', 'Cannot read registry.');
cleanup = onCleanup(@() fclose(fid));
d = java.security.MessageDigest.getInstance('SHA-256');
while ~feof(fid), d.update(typecast(fread(fid, 1024*1024, '*uint8'), 'int8')); end
hash = string(lower(reshape(dec2hex(typecast(d.digest(), 'uint8'), 2).', 1, [])));
end
