function tests=test_therma_c37
tests=functiontests(localfunctions);
end
function testResidentialGeometryAndLayerAccounting(testCase)
root=fileparts(fileparts(fileparts(mfilename('fullpath')))); old=path;
cleanup=onCleanup(@() path(old));
addpath(fullfile(root,'scripts','matlab','c37'),fullfile(root,'scripts','matlab','boptest'));
[Z,room]=c37_room_parameters();
verifyEqual(testCase,Z.envelope.geometry.floor_m2,20);
verifyEqual(testCase,Z.envelope.geometry.volume_m3,50);
verifyEqual(testCase,Z.area_m2,[10.5 12.5 10 10 20 20]);
verifyEqual(testCase,Z.H_exterior_W_K(5),0);
verifyEqual(testCase,Z.initial_K,288.15,'AbsTol',1e-10);
verifyEmpty(testCase,Z.envelope.registry_sha256);
for k=1:6
    c=Z.envelope.components(k);
    verifyEqual(testCase,sum(1./c.G_W_K),c.R_total_K_W,'RelTol',1e-12);
    verifyEqual(testCase,sum(c.C_J_K),sum([c.layers.C_J_K]),'RelTol',1e-12);
    verifyEqual(testCase,c.initial_K,ones(size(c.initial_K))*293.15,'AbsTol',1e-10);
end
verifyEqual(testCase,room.conditions.duration_s,86400);
end

function testPurmoRatingMassAndAdjacentBoundaryDemand(testCase)
root=fileparts(fileparts(fileparts(mfilename('fullpath')))); old=path;
cleanup=onCleanup(@() path(old));
addpath(fullfile(root,'scripts','matlab','c37'),fullfile(root,'scripts','matlab','c3'), ...
    fullfile(root,'scripts','matlab','boptest'));
[Z,room]=c37_room_parameters(); [P,rating]=c37_radiator_parameters();
verifyEqual(testCase,P.UA_W_K,34.56,'AbsTol',1e-10);
verifyEqual(testCase,P.nominal_flow_kg_s,864/(4180*10),'AbsTol',1e-12);
verifyEqual(testCase,rating.model_output_at_rating_W,864,'AbsTol',1e-9);
verifyEqual(testCase,rating.model_output_at_air21_W,839.3142857143,'AbsTol',1e-7);
verifyEqual(testCase,P.water_mass_kg,6.6,'AbsTol',1e-10);
verifyEqual(testCase,P.metal_mass_kg,24.756,'AbsTol',1e-10);
verifyEqual(testCase,P.capacitance_J_K,39966,'AbsTol',1e-6);
verifyEqual(testCase,rating.alternative_if_listed_mass_is_dry_J_K,43266,'AbsTol',1e-6);
verifyEmpty(testCase,rating.listed_mass_includes_water);
S=c37_steady_demand(Z,P,room);
verifyEqual(testCase,S.required_heat_at_setpoint_W,339.267051231,'AbsTol',1e-6);
verifyEqual(testCase,S.capacity_margin_W,500.047234483,'AbsTol',1e-6);
verifyTrue(testCase,S.steady_capacity_sufficient);
end
