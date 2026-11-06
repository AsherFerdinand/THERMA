function [Z,room]=c37_room_parameters()
%C37_ROOM_PARAMETERS New room data on unchanged C2 construction topology.
root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
file=fullfile(root,'configs','c37','residential_room.json'); room=jsondecode(fileread(file));
assert(room.schema_version==1 && isequal(room.boundaries(:)', ...
    {'outdoors','adjacent_conditioned','outdoors','adjacent_conditioned','adiabatic','adiabatic'}), ...
    'THERMA:C37Boundary','Review unsupported boundary topology.');
Z=load_boptest_zone_parameters(string(fullfile(root,'configs','references','c2_reduced_assumptions.json')));
g=room.geometry; A=g.length_m*g.width_m; V=A*g.height_m;
assert(A==20 && V==50 && g.window_m2>0 && g.window_m2<g.length_m*g.height_m, ...
    'THERMA:C37Geometry','Invalid requested room dimensions.');
Z.envelope.geometry=struct('length_m',g.length_m,'width_m',g.width_m,'height_m',g.height_m, ...
    'floor_m2',A,'volume_m3',V,'window_m2',g.window_m2);
areas=[g.length_m*g.height_m-g.window_m2,g.length_m*g.height_m, ...
    g.width_m*g.height_m,g.width_m*g.height_m,A,A];
kinds={'external_wall','partition','external_wall','partition','ceiling','floor'};
for face=1:6
    c=Z.envelope.components(face); c.area_m2=areas(face);
    values=room.(kinds{face}); labels=room.([kinds{face} '_materials']);
    assert(size(values,1)==numel(c.layers) && size(values,2)==4 && all(values>0,'all'), ...
        'THERMA:C37Layers','Invalid layer properties.');
    capacities=[]; conductances=[];
    for k=1:numel(c.layers)
        % Retain the existing node count and merged-interface layout, not BESTEST properties.
        n=c.layers(k).n_source; v=values(k,:); R=v(1)/(v(2)*areas(face)); C=v(1)*v(3)*v(4)*areas(face);
        if n==2, weights=[0.5 0.5]; else, weights=[0.5 ones(1,n-2) 0.5]/(n-1); end
        local=C*weights;
        c.layers(k)=struct('material',labels{k},'d_m',v(1),'k_W_mK',v(2), ...
            'rho_kg_m3',v(3),'cp_J_kgK',v(4),'n_source',n,'R_K_W',R,'C_J_K',C,'local_C_J_K',local);
        if k==1, capacities=local;
        else, capacities(end)=capacities(end)+local(1); capacities=[capacities local(2:end)]; end %#ok<AGROW>
        conductances=[conductances repmat((n-1)/R,1,n-1)]; %#ok<AGROW>
    end
    assert(numel(capacities)==c.n_states,'THERMA:C37Topology','Existing node topology changed.');
    c.C_J_K=capacities; c.G_W_K=conductances;
    c.R_total_K_W=sum([c.layers.R_K_W]); c.C_total_J_K=sum(capacities);
    c.reference_K=room.conditions.fabric_initial_C+273.15;
    c.initial_K=ones(size(capacities))*c.reference_K;
    Z.envelope.components(face)=c;
end
Z.area_m2=areas; Z.radiant_weights=areas/sum(areas);
p=Z.assumptions.parameters;
Z.C_air_J_K=p.rho_air_kg_m3.value*p.cp_air_J_kgK.value*V;
Z.H_interior_W_K=p.h_interior_W_m2K.value*areas;
% Indoor-side film also on the adjacent-room side of the partitions.
Z.H_exterior_W_K=[p.h_exterior_W_m2K.value*areas(1), ...
    p.h_interior_W_m2K.value*areas(2),p.h_exterior_W_m2K.value*areas(3), ...
    p.h_interior_W_m2K.value*areas(4),0];
G=p.h_radiation_W_m2K.value*(areas'*areas)/sum(areas); G(1:7:end)=0;
Z.radiation_matrix_W_K=G-diag(sum(G,2));
Z.UA_window_W_K=room.window_U_W_m2K*g.window_m2;
Z.volume_flow_m3_s=room.ventilation_ACH*V/3600;
Z.H_vent_W_K=p.rho_air_kg_m3.value*p.cp_air_J_kgK.value*Z.volume_flow_m3_s;
Z.initial_K=room.conditions.air_initial_C+273.15;
Z.version='C37-illustrative-residential'; Z.model_kind=room.classification;
Z.envelope.registry_sha256=''; % New construction is NOT the frozen BOPTEST registry.
Z.residential_config_sha256=boptest_file_sha256(file);
Z.approximate_outdoor_H_W_K=Z.UA_window_W_K+Z.H_vent_W_K;
for face=[1 3]
    Z.approximate_outdoor_H_W_K=Z.approximate_outdoor_H_W_K+1/( ...
        1/Z.H_exterior_W_K(face)+Z.envelope.components(face).R_total_K_W+1/Z.H_interior_W_K(face));
end
end
