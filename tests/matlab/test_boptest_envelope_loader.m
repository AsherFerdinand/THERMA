function tests = test_boptest_envelope_loader
% Loader regression; requires MATLAB only, not Simulink. Not run in the cloud.
tests = functiontests(localfunctions);
end

function testLayerSchemaAndRegistryValues(testCase)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPath = path;
cleanup = onCleanup(@() path(oldPath));
addpath(fullfile(root, 'scripts', 'matlab', 'boptest'));
P = load_boptest_envelope_parameters();
registry = jsondecode(fileread(fullfile(root, 'configs', 'references', ...
    'boptest_bestest_hydronic.json')));
entries = registry.parameters;
if isstruct(entries), entries = num2cell(entries); end
ids = cellfun(@(e) e.id, entries, 'UniformOutput', false);
fields = {'material'; 'd_m'; 'k_W_mK'; 'rho_kg_m3'; 'cp_J_kgK'; ...
    'n_source'; 'R_K_W'; 'C_J_K'; 'local_C_J_K'};
verifyEqual(testCase, [P.components.n_states], [5 5 5 5 4 3]);
verifyEqual(testCase, arrayfun(@(c) numel(c.layers), P.components), [3 3 3 3 3 2]);
registryFields = {'material', 'thickness', 'k', 'rho', 'c', 'material_node_count'};
outputFields = fields(1:6);
for face = 1:numel(P.components)
    c = P.components(face);
    for layer = 1:numel(c.layers)
        actual = c.layers(layer);
        verifyEqual(testCase, fieldnames(actual), fields);
        prefix = sprintf('%s.layer%d.', c.kind, layer);
        for property = 1:numel(registryFields)
            entry = entries{find(strcmp(ids, [prefix registryFields{property}]), 1)};
            verifyNotEmpty(testCase, entry.sources);
            verifyTrue(testCase, ismember(string(entry.status), ["explicit", "derived"]));
            verifyEqual(testCase, actual.(outputFields{property}), entry.value);
        end
        verifyEqual(testCase, actual.R_K_W, actual.d_m/(actual.k_W_mK*c.area_m2));
        verifyEqual(testCase, actual.C_J_K, ...
            actual.rho_kg_m3*actual.cp_J_kgK*actual.d_m*c.area_m2);
        verifyEqual(testCase, sum(actual.local_C_J_K), actual.C_J_K, ...
            'AbsTol', 64*eps(max(1,actual.C_J_K)));
    end
end
verifyEqual(testCase, P.registry_sha256, ...
    "f91141d78668908525d484a4900dc69af1a163c4c5e07f5a5fbd0c43eae4451c");
end
