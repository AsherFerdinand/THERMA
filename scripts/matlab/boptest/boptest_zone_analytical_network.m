function [A, B, capacities, initial] = boptest_zone_analytical_network(Z)
%BOPTEST_ZONE_ANALYTICAL_NETWORK Verification-only independent nodal assembly.
% C*dT/dt=K*T+Bpower*u. Not the generated Simulink physics implementation.
n = Z.total_states; air = n;
K = zeros(n); power = zeros(n,11); capacities = zeros(n,1); initial = capacities;
first = 1;
for face = 1:6
    c = Z.envelope.components(face); indices = first:first+c.n_states-1;
    capacities(indices) = c.C_J_K; initial(indices) = c.initial_K;
    for edge = 1:c.n_states-1
        pair = indices(edge:edge+1);
        K(pair,pair) = K(pair,pair) + c.G_W_K(edge)*[-1 1;1 -1];
    end
    inside(face) = indices(end); %#ok<AGROW>
    pair = [indices(end),air];
    K(pair,pair) = K(pair,pair)+Z.H_interior_W_K(face)*[-1 1;1 -1];
    if face <= 5
        K(indices(1),indices(1)) = K(indices(1),indices(1))-Z.H_exterior_W_K(face);
        power(indices(1),1) = Z.H_exterior_W_K(face);
    end
    power(indices(end),[3 5]) = Z.radiant_weights(face);
    power(indices(end),5+face) = 1;
    first = first+c.n_states;
end
K(inside,inside) = K(inside,inside)+Z.radiation_matrix_W_K;
H = Z.H_vent_W_K+Z.UA_window_W_K;
K(air,air) = K(air,air)-H; power(air,1) = H;
power(air,[2 4]) = 1;
capacities(air) = Z.C_air_J_K; initial(air) = Z.initial_K;
A = K./capacities; B = power./capacities;
end
