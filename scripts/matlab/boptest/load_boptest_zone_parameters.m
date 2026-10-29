function Z = load_boptest_zone_parameters(assumptionsFile)
%LOAD_BOPTEST_ZONE_PARAMETERS Explicit reduced C2 fixture; never exact BOPTEST.
% No assumption file means an error; there are no silent physical defaults.
arguments
    assumptionsFile (1,1) string
end
P = load_boptest_envelope_parameters();
a = jsondecode(fileread(assumptionsFile));
assert(a.schema_version == 1 && strcmp(a.model_kind, ...
    'reduced_dry_air_zone_not_exact_BOPTEST'), 'THERMA:C2Schema', 'Wrong C2 assumption schema.');
keys = {'rho_air_kg_m3','cp_air_J_kgK','h_interior_W_m2K', ...
    'h_exterior_W_m2K','h_radiation_W_m2K'};
units = {'kg/m3','J/(kg.K)','W/(m2.K)','W/(m2.K)','W/(m2.K)'};
for j = 1:numel(keys)
    assert(isfield(a.parameters,keys{j}), 'THERMA:C2Missing', 'Missing explicit %s.', keys{j});
    e = a.parameters.(keys{j});
    assert(strcmp(e.unit,units{j}) && strcmp(e.status,'provisional') && ~isempty(e.source), ...
        'THERMA:C2Provenance', 'Wrong unit/status/source for %s.', keys{j});
    validateattributes(e.value, {'numeric'}, {'scalar','real','finite','positive'});
end
Z.envelope = P;
Z.model_kind = a.model_kind;
Z.assumptions = a;
Z.assumptions_sha256 = boptest_file_sha256(assumptionsFile);
Z.area_m2 = [P.components.area_m2];
Z.radiant_weights = Z.area_m2/sum(Z.area_m2);
Z.C_air_J_K = a.parameters.rho_air_kg_m3.value * ...
    a.parameters.cp_air_J_kgK.value * P.geometry.volume_m3;
Z.H_interior_W_K = a.parameters.h_interior_W_m2K.value*Z.area_m2;
Z.H_exterior_W_K = a.parameters.h_exterior_W_m2K.value*Z.area_m2(1:5);
% Pairwise G_ij=hr*A_i*A_j/sum(A); equal/opposite exchange, zero self links.
G = a.parameters.h_radiation_W_m2K.value * ...
    (Z.area_m2'*Z.area_m2)/sum(Z.area_m2);
G(1:7:end) = 0;
Z.radiation_matrix_W_K = G-diag(sum(G,2));
root = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
r = jsondecode(fileread(fullfile(root,'configs','references','boptest_bestest_hydronic.json')));
entries = r.parameters;
if isstruct(entries), entries = num2cell(entries); end
Z.UA_window_W_K = scalar('window.U_rating','W/(m2.K)')*P.geometry.window_m2;
Z.volume_flow_m3_s = scalar('infiltration.volume_flow','m3/s');
Z.H_vent_W_K = a.parameters.rho_air_kg_m3.value * ...
    a.parameters.cp_air_J_kgK.value * Z.volume_flow_m3_s;
Z.initial_K = P.components(1).reference_K;
Z.total_states = P.total_states+1;
Z.version = 'C2-reduced-v1';

    function value = scalar(id, unit)
        found = cellfun(@(e) strcmp(e.id,id),entries);
        assert(sum(found)==1, 'THERMA:C2Missing', 'Missing %s.', id);
        e = entries{find(found,1)};
        assert(strcmp(e.unit,unit) && ~isempty(e.sources) && ...
            ismember(string(e.status),["explicit","derived"]), ...
            'THERMA:C2Provenance','Unverified %s.', id);
        validateattributes(e.value,{'numeric'},{'scalar','real','finite','positive'});
        value = e.value;
    end
end
