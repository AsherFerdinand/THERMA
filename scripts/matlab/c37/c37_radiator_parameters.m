function [P,rating]=c37_radiator_parameters()
%C37_RADIATOR_PARAMETERS Match one evidenced operating point; no power-law model.
root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
rating=jsondecode(fileread(fullfile(root,'configs','c37','radiator_rating.json')));
assert(rating.schema_version==1 && strcmp(rating.status,'verified_manufacturer_source'), ...
    'THERMA:C37RatingMissing',['A reviewed manufacturer rating is required. No radiator has been selected or sized. ' ...
    'See configs/c37/radiator_rating.json and docs/C37_RESIDENTIAL_HEATING.md.']);
for key={'manufacturer','model_and_dimensions','source_url','source_location','source_file','source_sha256'}
    assert(ischar(rating.(key{1})) && ~isempty(strtrim(rating.(key{1}))), ...
        'THERMA:C37Rating','Missing manufacturer evidence: %s.',key{1});
end
for key={'rated_output_W','supply_C','return_C','room_C'}
    validateattributes(rating.(key{1}),{'numeric'},{'scalar','real','finite'});
end
assert(rating.rated_output_W>0 && rating.supply_C==55 && rating.supply_C>rating.return_C && ...
    rating.return_C>rating.room_C,'THERMA:C37Rating', ...
    'Need a positive documented rating at55 C supply with supply>return>room; no unverified temperature conversion.');
relative=rating.source_file;
assert(~startsWith(relative,'/') && ~contains(relative,{'\',':'}) && ...
    ~any(strcmp(strsplit(relative,'/'),'..')),'THERMA:C37Rating','Unsafe relative evidence path.');
assert(strcmp(boptest_file_sha256(fullfile(root,relative)),rating.source_sha256), ...
    'THERMA:C37Rating','Manufacturer evidence file is missing or changed.');
P=load_c3_parameters();
% In this mixed-lump model, the steady radiator temperature equals the return.
P.nominal_flow_kg_s=rating.rated_output_W/(P.water_cp_J_kgK*(rating.supply_C-rating.return_C));
P.UA_W_K=rating.rated_output_W/(rating.return_C-rating.room_C);
rating.model_output_at_rating_W=P.nominal_flow_kg_s*P.water_cp_J_kgK*P.UA_W_K/ ...
    (P.nominal_flow_kg_s*P.water_cp_J_kgK+P.UA_W_K)*(rating.supply_C-rating.room_C);
rating.model_output_at_air21_W=P.nominal_flow_kg_s*P.water_cp_J_kgK*P.UA_W_K/ ...
    (P.nominal_flow_kg_s*P.water_cp_J_kgK+P.UA_W_K)*(55-21);
assert(abs(rating.model_output_at_rating_W-rating.rated_output_W)<1e-8*rating.rated_output_W, ...
    'THERMA:C37Rating','Steady rating match failed.');
% Unchanged 3kg water/20kg metal inventory and fixed radiant fraction are assumptions,
% not a statement about this manufacturer's product unless separately evidenced.
end
