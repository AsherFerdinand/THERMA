function [P,rating]=c37_radiator_parameters()
%C37_RADIATOR_PARAMETERS Match one user-supplied Purmo point; no power-law model.
root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
rating=jsondecode(fileread(fullfile(root,'configs','c37','radiator_rating.json')));
assert(rating.schema_version==1 && strcmp(rating.status,'user_supplied_manufacturer_specifications'), ...
    'THERMA:C37Rating','Expected the documented user-supplied manufacturer specifications.');
for key={'manufacturer','model_and_dimensions','source_url','source_location','source_file','source_sha256'}
    assert(ischar(rating.(key{1})) && ~isempty(strtrim(rating.(key{1}))), ...
        'THERMA:C37Rating','Missing manufacturer citation: %s.',key{1});
end
for key={'rated_output_W','supply_C','return_C','room_C','water_content_L', ...
        'manufacturer_listed_mass_kg','water_density_kg_L'}
    validateattributes(rating.(key{1}),{'numeric'},{'scalar','real','finite','positive'});
end
assert(rating.supply_C==55 && rating.supply_C>rating.return_C && rating.return_C>rating.room_C, ...
    'THERMA:C37Rating','Need the documented55 C supply point with supply>return>room.');
relative=rating.source_file;
assert(~startsWith(relative,'/') && ~contains(relative,{'\',':'}) && ...
    ~any(strcmp(strsplit(relative,'/'),'..')),'THERMA:C37Rating','Unsafe relative evidence path.');
assert(strcmp(boptest_file_sha256(fullfile(root,relative)),rating.source_sha256), ...
    'THERMA:C37Rating','Supplied specification transcription is missing or changed.');
evidence=jsondecode(fileread(fullfile(root,relative)));
assert(strcmp(evidence.evidence_kind,rating.source_kind), ...
    'THERMA:C37Rating','Evidence is a user transcription, not an independently downloaded datasheet.');
for key={'manufacturer','product_code','dimensions_height_length_depth_mm','source_url', ...
        'rated_output_W','supply_C','return_C','room_C','water_content_L','manufacturer_listed_mass_kg'}
    assert(isequal(evidence.(key{1}),rating.(key{1})),'THERMA:C37Rating', ...
        'Configuration differs from supplied specification: %s.',key{1});
end
P=load_c3_parameters();
% In this mixed-lump model the steady radiator temperature equals the return.
P.nominal_flow_kg_s=rating.rated_output_W/(P.water_cp_J_kgK*(rating.supply_C-rating.return_C));
P.UA_W_K=rating.rated_output_W/(rating.return_C-rating.room_C);
P.water_mass_kg=rating.water_content_L*rating.water_density_kg_L;
assert(isempty(rating.listed_mass_includes_water) && strcmp(rating.model_mass_interpretation, ...
    'listed_mass_minus_full_water_mass_as_effective_metal_assumption'), ...
    'THERMA:C37Mass','Review any resolved mass interpretation explicitly.');
% Explicit assumption, NOT proof that the listed product weight includes water.
P.metal_mass_kg=rating.manufacturer_listed_mass_kg-P.water_mass_kg;
assert(P.metal_mass_kg>0,'THERMA:C37Mass','Invalid effective metal mass.');
P.capacitance_J_K=P.water_mass_kg*P.water_cp_J_kgK+P.metal_mass_kg*P.metal_cp_J_kgK;
rating.model_capacitance_J_K=P.capacitance_J_K;
rating.alternative_if_listed_mass_is_dry_J_K=P.water_mass_kg*P.water_cp_J_kgK+ ...
    rating.manufacturer_listed_mass_kg*P.metal_cp_J_kgK;
rating.model_output_at_rating_W=P.nominal_flow_kg_s*P.water_cp_J_kgK*P.UA_W_K/ ...
    (P.nominal_flow_kg_s*P.water_cp_J_kgK+P.UA_W_K)*(rating.supply_C-rating.room_C);
rating.model_output_at_air21_W=P.nominal_flow_kg_s*P.water_cp_J_kgK*P.UA_W_K/ ...
    (P.nominal_flow_kg_s*P.water_cp_J_kgK+P.UA_W_K)*(55-21);
assert(abs(rating.model_output_at_rating_W-rating.rated_output_W)<1e-8*rating.rated_output_W, ...
    'THERMA:C37Rating','Steady rating match failed.');
end
