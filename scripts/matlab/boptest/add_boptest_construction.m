function path = add_boptest_construction(model, name, c, expression, mode, position)
%ADD_BOPTEST_CONSTRUCTION Editable integrator/sum/gain network, not a Function block.
% Heat-flow mode retains every surface state. fixed_temperature is used ONLY by
% constant-Dirichlet verification fixtures; prescribed endpoint states are eliminated.
arguments
    model (1,:) char
    name (1,:) char
    c (1,1) struct
    expression (1,:) char
    mode (1,1) string {mustBeMember(mode,["heat_flow","fixed_temperature"])}
    position (1,4) double = [100 100 300 220]
end
path = [model '/' name];
add_block('built-in/Subsystem', path, 'Position', position);
set_param(path, 'Description', sprintf([ ...
    '%s: %d unique temperature nodes, exterior -> interior.\n' ...
    'Positive boundary power enters the solid. No surface films.\n' ...
    'Output: [T_ext K,T_int K,q_ext W,q_int W,E J,dE/dt W,residual W,T_nodes K].'], ...
    c.kind, c.n_states));
n = c.n_states;
fixed = false(1,n);
if mode == "fixed_temperature"
    fixed(end) = true;
    fixed(1) = ~c.adiabatic_exterior;
end
for node = 1:n
    x = 100 + (node-1)*190;
    blockName = sprintf('T_%02d_K', node);
    if fixed(node)
        if node == n, field = '.fixed_interior_K'; else, field = '.fixed_exterior_K'; end
        add_block('simulink/Sources/Constant', [path '/' blockName], ...
            'Value', [expression field], 'Position', [x 90 x+85 125]);
        add_block('simulink/Sources/Constant', [path sprintf('/dT_%02d_K_s', node)], ...
            'Value', '0', 'Position', [x 245 x+65 275]);
    else
        add_block('simulink/Continuous/Integrator', [path '/' blockName], ...
            'InitialCondition', sprintf('%s.initial_K(%d)', expression, node), ...
            'Position', [x 90 x+45 130]);
    end
end
for edge = 1:n-1
    x = 120 + (edge-1)*190;
    add_block('simulink/Math Operations/Sum', [path sprintf('/DeltaT_%02d_K', edge)], ...
        'Inputs', '+-', 'Position', [x 355 x+25 395]);
    add_block('simulink/Math Operations/Gain', [path sprintf('/Phi_%02d_W', edge)], ...
        'Gain', sprintf('%s.G_W_K(%d)', expression, edge), ...
        'Position', [x+45 355 x+130 395]);
    wire(sprintf('T_%02d_K/1', edge), sprintf('DeltaT_%02d_K/1', edge));
    wire(sprintf('T_%02d_K/1', edge+1), sprintf('DeltaT_%02d_K/2', edge));
    wire(sprintf('DeltaT_%02d_K/1', edge), sprintf('Phi_%02d_W/1', edge));
end
if c.adiabatic_exterior
    add_block('simulink/Sources/Constant', [path '/q_exterior_W'], ...
        'Value', '0', 'Position', [10 15 65 45]);
    exteriorSignal = 'q_exterior_W/1';
elseif mode == "heat_flow"
    add_block('simulink/Sources/In1', [path '/q_exterior_W'], ...
        'Port', '1', 'Position', [10 15 40 35]);
    exteriorSignal = 'q_exterior_W/1';
else
    exteriorSignal = 'Phi_01_W/1';
end
if mode == "heat_flow"
    add_block('simulink/Sources/In1', [path '/q_interior_W'], ...
        'Port', num2str(2-c.adiabatic_exterior), 'Position', [10 175 40 195]);
else
    add_block('simulink/Math Operations/Gain', [path '/q_interior_W'], ...
        'Gain', '-1', 'Position', [n*190 355 n*190+60 390]);
    wire(sprintf('Phi_%02d_W/1', n-1), 'q_interior_W/1');
end
for node = 1:n
    if fixed(node), continue; end
    x = 100 + (node-1)*190;
    if node == 1
        positive = exteriorSignal;
        negative = 'Phi_01_W/1';
        signs = '+-';
    elseif node == n
        positive = sprintf('Phi_%02d_W/1', n-1);
        negative = 'q_interior_W/1';
        signs = '++';
    else
        positive = sprintf('Phi_%02d_W/1', node-1);
        negative = sprintf('Phi_%02d_W/1', node);
        signs = '+-';
    end
    add_block('simulink/Math Operations/Sum', [path sprintf('/Net_%02d_W', node)], ...
        'Inputs', signs, 'Position', [x 180 x+25 220]);
    add_block('simulink/Math Operations/Gain', [path sprintf('/dT_%02d_K_s', node)], ...
        'Gain', sprintf('1/%s.C_J_K(%d)', expression, node), ...
        'Position', [x 245 x+100 280]);
    wire(positive, sprintf('Net_%02d_W/1', node));
    wire(negative, sprintf('Net_%02d_W/2', node));
    wire(sprintf('Net_%02d_W/1', node), sprintf('dT_%02d_K_s/1', node));
    wire(sprintf('dT_%02d_K_s/1', node), sprintf('T_%02d_K/1', node));
end
add_block('simulink/Signal Routing/Mux', [path '/T_states_K'], ...
    'Inputs', num2str(n), 'Position', [n*190+140 80 n*190+150 180]);
add_block('simulink/Signal Routing/Mux', [path '/State_derivatives_K_s'], ...
    'Inputs', num2str(n), 'Position', [n*190+140 240 n*190+150 330]);
for node = 1:n
    wire(sprintf('T_%02d_K/1', node), sprintf('T_states_K/%d', node));
    wire(sprintf('dT_%02d_K_s/1', node), sprintf('State_derivatives_K_s/%d', node));
end
x = n*190+210;
add_block('simulink/Math Operations/Bias', [path '/Delta_from_reference_K'], ...
    'Bias', ['-' expression '.reference_K'], 'Position', [x 90 x+95 125]);
add_block('simulink/Math Operations/Gain', [path '/Stored_energy_J'], ...
    'Gain', [expression '.C_J_K'], 'Multiplication', 'Matrix(K*u)', ...
    'Position', [x+130 90 x+230 125]);
add_block('simulink/Math Operations/Gain', [path '/Energy_rate_W'], ...
    'Gain', [expression '.C_J_K'], 'Multiplication', 'Matrix(K*u)', ...
    'Position', [x 250 x+100 285]);
add_block('simulink/Math Operations/Sum', [path '/Boundary_power_W'], ...
    'Inputs', '++', 'Position', [x 350 x+25 390]);
add_block('simulink/Math Operations/Sum', [path '/Balance_residual_W'], ...
    'Inputs', '+-', 'Position', [x+140 250 x+165 290]);
wire('T_states_K/1', 'Delta_from_reference_K/1');
wire('Delta_from_reference_K/1', 'Stored_energy_J/1');
wire('State_derivatives_K_s/1', 'Energy_rate_W/1');
wire(exteriorSignal, 'Boundary_power_W/1');
wire('q_interior_W/1', 'Boundary_power_W/2');
wire('Energy_rate_W/1', 'Balance_residual_W/1');
wire('Boundary_power_W/1', 'Balance_residual_W/2');
add_block('simulink/Signal Routing/Mux', [path '/Pack_signals'], ...
    'Inputs', '8', 'Position', [x+300 70 x+310 400]);
outputs = {'T_01_K/1', sprintf('T_%02d_K/1', n), exteriorSignal, ...
    'q_interior_W/1', 'Stored_energy_J/1', 'Energy_rate_W/1', ...
    'Balance_residual_W/1', 'T_states_K/1'};
for port = 1:numel(outputs), wire(outputs{port}, sprintf('Pack_signals/%d', port)); end
add_block('simulink/Sinks/Out1', [path '/ThermalSignals'], ...
    'Position', [x+370 220 x+400 240]);
wire('Pack_signals/1', 'ThermalSignals/1');

    function wire(from, to)
        add_line(path, from, to, 'autorouting', 'on');
    end
end
