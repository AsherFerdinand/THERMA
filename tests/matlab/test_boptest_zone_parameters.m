function tests = test_boptest_zone_parameters
% MATLAB-only reduced C2 parameter/network invariants, not Simulink execution.
tests = functiontests(localfunctions);
end

function testReducedNetwork(testCase)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPath = path; cleanup = onCleanup(@() path(oldPath));
addpath(fullfile(root,'scripts','matlab','boptest'));
Z = load_boptest_zone_parameters(fullfile(root,'configs','references','c2_reduced_assumptions.json'));
[A,B,C,initial] = boptest_zone_analytical_network(Z);
verifySize(testCase,A,[28 28]); verifySize(testCase,B,[28 11]);
verifyTrue(testCase,all(C>0)); verifyEqual(testCase,initial,ones(28,1)*293.15);
verifyLessThan(testCase,max(real(eig(A))),0);
verifyEqual(testCase,sum(Z.radiant_weights),1,'AbsTol',64*eps(1));
verifyEqual(testCase,Z.radiation_matrix_W_K,Z.radiation_matrix_W_K');
verifyEqual(testCase,sum(Z.radiation_matrix_W_K,1),zeros(1,6),'AbsTol',1e-12);
verifyEqual(testCase,A*initial+B*[293.15;zeros(10,1)],zeros(28,1),'AbsTol',1e-10);
% Every injected W reaches storage exactly once; radiative heat avoids air directly.
verifyEqual(testCase,C'*B(:,2:11),ones(1,10),'AbsTol',64*eps(1));
verifyEqual(testCase,B(end,[3 5 6:11]),zeros(1,8));
verifyEqual(testCase,Z.UA_window_W_K,36);
verifyEqual(testCase,Z.C_air_J_K,1.2*1006*129.6);
verifyEqual(testCase,Z.envelope.components(6).adiabatic_exterior,true);
% Internal exchanges cancel for arbitrary state values; only boundary loss remains.
state = (1:28)';
expectedLoss = -(Z.H_vent_W_K+Z.UA_window_W_K)*state(end);
first = 1;
for face = 1:6
    if face <= 5, expectedLoss = expectedLoss-Z.H_exterior_W_K(face)*state(first); end
    first = first+Z.envelope.components(face).n_states;
end
verifyEqual(testCase,C'*A*state,expectedLoss,'AbsTol',1e-8);
end
