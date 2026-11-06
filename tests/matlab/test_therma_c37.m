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
