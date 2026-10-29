function reportFile = verify_boptest_envelope_c1()
%VERIFY_BOPTEST_ENVELOPE_C1 A-G component checks, not BOPTEST/room validation.
% Creates only new models in ignored unique output directories. Requires Simulink.
P = load_boptest_envelope_parameters();
assert((exist('new_system', 'file') ~= 0 || exist('new_system', 'builtin') == 5), 'THERMA:NoSimulink', 'MATLAB/Simulink required.');
root = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
output = fullfile(root, 'outputs', 'boptest', 'simulink_c1', 'verification');
if ~isfolder(output), mkdir(output); end
runDir = tempname(output);
mkdir(runDir);
reportFile = fullfile(runDir, 'verification.json');
report = struct('status', 'running', 'matlab_verified', false, 'matlab_version', version, ...
    'simulink', ver('Simulink'), 'registry_sha256', P.registry_sha256, ...
    'core_state_counts', [P.components.n_states], 'cases', {{}}, ...
    'tolerance_policy', ['R/C arithmetic: 64 ULPs. Dynamic error budget: 20 times ' ...
    '(AbsTol+RelTol*temperature). This is a numerical diagnostic budget, not a ' ...
    'building accuracy criterion or a rigorous global solver-error bound.']);
writeJSON(reportFile, report);
try
    [model, modelFile] = build_boptest_envelope_c1('ShowModel', false);
    modelCleanup = onCleanup(@() closeOwned(model));
    set_param(model, 'SimulationCommand', 'update');
    report.generated_model = modelFile;
    report.core_integrator_blocks = numel(find_system(model, 'BlockType', 'Integrator'));
    assert(report.core_integrator_blocks == P.total_states, 'THERMA:StateCount', ...
        'Core does not have the expected scalar integrators.');
    for face = 1:numel(P.components)
        c = P.components(face);
        assertNear(sum(1./c.G_W_K), sum([c.layers.R_K_W]), 'Network resistance');
        assertNear(sum(c.C_J_K), sum([c.layers.C_J_K]), 'Network capacity');
    end
    report.cases{end+1} = struct('name', 'A_B_R_C', 'status', 'passed');
    % Uniform Neumann case exercises every original surface-state integrator.
    duration = 3600; % Verification horizon, not a physical material parameter.
    inputs = Simulink.SimulationData.Dataset;
    inputs = inputs.addElement(timeseries(zeros(2,5), [0;duration]), 'q_exterior_W');
    inputs = inputs.addElement(timeseries(zeros(2,6), [0;duration]), 'q_interior_W');
    input = Simulink.SimulationInput(model);
    input = input.setExternalInput(inputs);
    simulation = sim(input);
    uniformT = simulation.get('T_states_K');
    uniformE = simulation.get('E_J');
    uniformR = simulation.get('residual_W');
    assert(size(uniformT.Data,2) == P.total_states, 'THERMA:Dimensions', 'Wrong state width.');
    assert(size(uniformE.Data,2) == 6, 'THERMA:Dimensions', 'Wrong construction-output width.');
    delta = max(abs(uniformT.Data-P.components(1).reference_K), [], 'all');
    assert(delta <= 64*eps(P.components(1).reference_K), 'THERMA:UniformDrift', ...
        'Uniform zero-flux case drifted.');
    assert(max(abs(uniformE.Data),[],'all') == 0 && max(abs(uniformR.Data),[],'all') == 0, ...
        'THERMA:UniformEnergy', 'Uniform case has nonzero energy/heat balance.');
    report.cases{end+1} = struct('name', 'C_uniform_all_surfaces', ...
        'status', 'passed', 'max_drift_K', delta);
    save(fullfile(runDir, 'uniform.mat'), 'simulation');
    report.cases{end+1} = coreFluxCheck(model, P, runDir);
    clear modelCleanup;
    writeJSON(reportFile, report);
    for face = 1:numel(P.components)
        c = P.components(face);
        caseDir = fullfile(runDir, c.name);
        mkdir(caseDir);
        result = struct('name', c.name, 'status', 'running');
        fixture = ['THERMA_C1_Check_' c.name];
        try
            assert(~bdIsLoaded(fixture), 'THERMA:AlreadyLoaded', ...
                'A verification model is already open; close it yourself first.');
            new_system(fixture);
            fixtureCleanup = onCleanup(@() closeOwned(fixture));
            c.fixed_exterior_K = c.reference_K + 10; % Synthetic test excitation, K.
            c.fixed_interior_K = c.reference_K;
            if c.adiabatic_exterior, c.fixed_interior_K = c.reference_K+10; end
            workspace = get_param(fixture, 'ModelWorkspace');
            assignin(workspace, 'C1', c);
            set_param(fixture, 'SolverType', 'Variable-step', 'Solver', 'ode15s', ...
                'ReturnWorkspaceOutputs', 'on');
            add_boptest_construction(fixture, 'Construction', c, 'C1', ...
                'fixed_temperature', [100 100 320 240]);
            add_block('simulink/Sinks/To Workspace', [fixture '/Log'], ...
                'VariableName', 'thermal', 'SaveFormat', 'Timeseries', ...
                'MaxDataPoints', 'inf', 'Decimation', '1', 'Position', [400 150 520 190]);
            add_line(fixture, 'Construction/1', 'Log/1');
            save_system(fixture, fullfile(caseDir, [fixture '.slx']));
            set_param(fixture, 'SimulationCommand', 'update');
            [fixed, steady, U, rates] = referenceModes(c);
            horizon = 12/min(rates);
            result.horizon_s = horizon;
            result.free_state_count = sum(~fixed);
            result.source_temperature_nodes = c.n_states;
            result.test_D = steadyCheck(fixture, c, steady, horizon, caseDir);
            coarse = transient(fixture, c, horizon, 1e-7, 1e-9, horizon/250);
            fine = transient(fixture, c, horizon, 1e-8, 1e-10, horizon/500);
            writeTrace(fullfile(caseDir, 'transient_coarse.csv'), coarse);
            writeTrace(fullfile(caseDir, 'transient_refined.csv'), fine);
            result.coarse_solver = coarse.solver;
            result.refined_solver = fine.solver;
            coarseMetrics = analyse(coarse, c, fixed, steady, U, rates);
            fineMetrics = analyse(fine, c, fixed, steady, U, rates);
            result.coarse = coarseMetrics;
            result.refined = fineMetrics;
            result.convergence_observed = fineMetrics.max_temperature_error_K <= ...
                coarseMetrics.max_temperature_error_K + 64*eps(max(fine.data(:,8:end),[],'all'));
            result.initial_reservoir_energy_jump_J = ...
                sum(c.C_J_K(fixed).*(steady(fixed)'-c.initial_K(fixed)));
            result.energy_jump_note = ['Fixed-temperature step is at t=0. Boundary ' ...
                'capacities receive the reported ideal-reservoir impulse before the ' ...
                'first sample. Subsequent energy checks integrate from t=0+.'];
            makePlots(caseDir, fine, c);
            assert(coarseMetrics.passed && fineMetrics.passed && result.convergence_observed, ...
                'THERMA:TransientCheck', 'Transient/energy/refinement check failed; inspect metrics.');
            result.status = 'passed';
            clear fixtureCleanup;
        catch problem
            result.status = 'failed';
            result.error = struct('identifier', problem.identifier, 'message', problem.message);
            if exist('fixtureCleanup', 'var'), clear fixtureCleanup; end
        end
        report.cases{end+1} = result;
        writeJSON(reportFile, report);
    end
    passed = cellfun(@(x) strcmp(x.status, 'passed'), report.cases);
    if all(passed), report.status = 'passed'; report.matlab_verified = true;
    else, report.status = 'failed'; end
catch problem
    report.status = 'failed';
    report.error = struct('identifier', problem.identifier, 'message', problem.message);
    if exist('modelCleanup', 'var'), clear modelCleanup; end
end
writeJSON(reportFile, report);
fprintf('Verification report: %s\n', reportFile);
assert(strcmp(report.status, 'passed'), 'THERMA:VerificationFailed', ...
    'Verification failed. Report and completed case artifacts were preserved at %s.', reportFile);
end

function result = coreFluxCheck(model, P, folder)
% Nonuniform per-face test inputs identify routing/collector errors independently.
duration = 3600;
exterior = 1:5;
interior = 10:10:60;
inputs = Simulink.SimulationData.Dataset;
inputs = inputs.addElement(timeseries(repmat(exterior,2,1), [0;duration]), 'q_exterior_W');
inputs = inputs.addElement(timeseries(repmat(interior,2,1), [0;duration]), 'q_interior_W');
input = Simulink.SimulationInput(model);
input = input.setExternalInput(inputs);
simulation = sim(input);
qext = simulation.get('q_exterior_W');
qint = simulation.get('q_interior_W');
energy = simulation.get('E_J');
states = simulation.get('T_states_K');
residual = simulation.get('residual_W');
assert(all(qext.Data == [exterior 0],'all') && all(qint.Data == interior,'all'), ...
    'THERMA:Routing', 'Boundary or collector face order is wrong.');
expected = energy.Time(:)*([exterior 0]+interior);
budgetK = 20*(1e-9+1e-7*max(abs(states.Data),[],'all'));
energyBudget = budgetK*[P.components.C_total_J_K];
errorJ = max(abs(energy.Data-expected),[],1);
assert(all(errorJ <= energyBudget), 'THERMA:CoreEnergy', 'Constant-flux stored energy mismatch.');
assert(max(abs(residual.Data),[],'all') <= 128*eps(max(interior+ [exterior 0])), ...
    'THERMA:CorePower', 'Core power balance mismatch.');
first = 1;
for face = 1:6
    c = P.components(face);
    indices = first:first+c.n_states-1;
    fromStates = (states.Data(:,indices)-c.reference_K)*c.C_J_K';
    assert(max(abs(fromStates-energy.Data(:,face))) <= energyBudget(face), ...
        'THERMA:StateRouting', 'State/energy routing does not match component capacities.');
    first = first+c.n_states;
end
assert(all(qext.Data(:,6) == 0), 'THERMA:FloorFlux', 'Floor outer port is not insulated.');
floorGradient = max(abs(diff(states.Data(:,end-P.components(6).n_states+1:end),1,2)),[],'all');
assert(floorGradient > budgetK, 'THERMA:FloorStorage', 'Floor did not redistribute applied heat.');
result = struct('name', 'F_G_core_energy_and_floor', 'status', 'passed', ...
    'energy_error_J', errorJ, 'energy_budget_J', energyBudget, ...
    'floor_exterior_power_W', max(abs(qext.Data(:,6))), 'floor_gradient_K', floorGradient);
save(fullfile(folder,'constant_flux.mat'), 'simulation');
end

function [fixed, steady, U, rates] = referenceModes(c)
% Analytical linear-network reference, used ONLY to verify the generated blocks.
n = c.n_states;
L = zeros(n);
for edge = 1:n-1
    indices = [edge edge+1];
    L(indices,indices) = L(indices,indices) + c.G_W_K(edge)*[1 -1;-1 1];
end
fixed = false(1,n);
fixed(end) = true;
fixed(1) = ~c.adiabatic_exterior;
steady = ones(n,1)*c.fixed_interior_K;
if ~c.adiabatic_exterior, steady(1) = c.fixed_exterior_K; end
steady(~fixed) = -L(~fixed,~fixed)\(L(~fixed,fixed)*steady(fixed));
weights = sqrt(c.C_J_K(~fixed));
M = L(~fixed,~fixed)./(weights(:)*weights(:)');
[U, D] = eig((M+M')/2);
rates = diag(D);
assert(all(rates > 0), 'THERMA:UnstableNetwork', 'Invalid constrained network eigenvalues.');
end

function result = steadyCheck(model, c, steady, horizon, folder)
c.initial_K = steady';
trace = transient(model, c, horizon/12, 1e-7, 1e-9, horizon/250);
writeTrace(fullfile(folder, 'steady.csv'), trace);
if c.adiabatic_exterior, analytical = 0;
else, analytical = (c.fixed_exterior_K-c.fixed_interior_K)/c.R_total_K_W; end
budgetK = 20*(1e-9+1e-7*max(abs(steady)));
budgetW = budgetK*2*sum(c.G_W_K);
errorW = max(abs(trace.data(:,3)-analytical));
errorK = max(abs(trace.data(:,8:end)-steady'),[],'all');
assert(errorW <= budgetW && errorK <= budgetK, 'THERMA:SteadyFlux', ...
    'Steady fixed-temperature conduction differs from material resistance.');
result = struct('status', 'passed', 'expected_exterior_flux_W', analytical, ...
    'max_flux_error_W', errorW, 'max_drift_K', errorK, ...
    'numerical_budget_K', budgetK, 'numerical_budget_W', budgetW);
end

function trace = transient(model, c, horizon, rel, absolute, maxStep)
input = Simulink.SimulationInput(model);
input = input.setVariable('C1', c, 'Workspace', model);
input = input.setModelParameter('StopTime', num2str(horizon,17), ...
    'RelTol', num2str(rel,17), 'AbsTol', num2str(absolute,17), ...
    'MaxStep', num2str(maxStep,17));
simulation = sim(input);
series = simulation.get('thermal');
t = series.Time(:);
data = squeeze(series.Data);
if size(data,1) ~= numel(t) && size(data,2) == numel(t), data = data'; end
assert(size(data,1) == numel(t) && size(data,2) == 7+c.n_states && ...
    all(isfinite(data),'all') && all(diff(t)>0), 'THERMA:Trace', 'Invalid output dimensions/time/data.');
trace = struct('time_s', t, 'data', data, ...
    'solver', struct('name', 'ode15s', 'RelTol', rel, 'AbsTol_K', absolute, 'MaxStep_s', maxStep));
end

function metrics = analyse(trace, c, fixed, steady, U, rates)
t = trace.time_s;
y = trace.data;
free = ~fixed;
weights = sqrt(c.C_J_K(free));
a = U'*(weights(:).*(c.initial_K(free)'-steady(free)));
exact = repmat(steady', numel(t), 1);
exact(:,free) = (steady(free) + (U*(a.*exp(-rates*t')))./weights(:))';
qext = zeros(size(t));
if ~c.adiabatic_exterior, qext = c.G_W_K(1)*(exact(:,1)-exact(:,2)); end
qint = c.G_W_K(end)*(exact(:,end)-exact(:,end-1));
exactE = (exact-c.reference_K)*c.C_J_K';
exactQuadratureResidual = exactE-exactE(1)-cumtrapz(t, qext+qint);
rawResidual = y(:,5)-y(1,5)-cumtrapz(t, y(:,3)+y(:,4));
correctedResidual = rawResidual-exactQuadratureResidual;
scaleK = trace.solver.AbsTol_K + trace.solver.RelTol*max(abs(exact),[],'all');
budgetK = 20*scaleK;
% Bound for the difference between simulated and analytical sampled energy
% balances, assuming every state error is at most budgetK. Quadrature bias is
% computed independently on the analytical solution at these SAME timestamps.
edgeSensitivity = c.G_W_K(end);
if ~c.adiabatic_exterior, edgeSensitivity = edgeSensitivity+c.G_W_K(1); end
energyBudgetJ = 2*sum(c.C_J_K)*budgetK + t(end)*edgeSensitivity*budgetK;
roundingW = 128*eps(max(1,max(abs(y(:,3:4)),[],'all')));
maxErrorK = max(abs(y(:,8:end)-exact),[],'all');
storedErrorJ = max(abs(y(:,5)-(y(:,8:end)-c.reference_K)*c.C_J_K'));
monotonic = all(diff(y(:,8:end)) >= -budgetK,'all');
bounded = min(y(:,8:end),[],'all') >= c.reference_K-budgetK && ...
    max(y(:,8:end),[],'all') <= c.reference_K+10+budgetK;
direction = all(y(:,3) >= -roundingW) && all(y(:,4) <= roundingW);
if c.adiabatic_exterior, direction = all(y(:,3) == 0) && all(y(:,4) >= -roundingW); end
metrics = struct('max_temperature_error_K', maxErrorK, 'temperature_budget_K', budgetK, ...
    'max_power_residual_W', max(abs(y(:,7))), 'power_roundoff_budget_W', roundingW, ...
    'max_raw_integral_residual_J', max(abs(rawResidual)), ...
    'max_analytical_quadrature_residual_J', max(abs(exactQuadratureResidual)), ...
    'max_corrected_integral_residual_J', max(abs(correctedResidual)), ...
    'integral_error_budget_J', energyBudgetJ, 'stored_energy_identity_error_J', storedErrorJ, ...
    'monotonic', monotonic, 'bounded', bounded, 'correct_heat_direction', direction);
metrics.passed = maxErrorK <= budgetK && max(abs(y(:,7))) <= roundingW && ...
    max(abs(correctedResidual)) <= energyBudgetJ && storedErrorJ <= energyBudgetJ && ...
    monotonic && bounded && direction;
if c.adiabatic_exterior
    metrics.adiabatic_outer_flux_W = max(abs(y(:,3)));
    metrics.nonzero_internal_gradient_K = max(abs(diff(y(:,8:end),1,2)),[],'all');
    metrics.passed = metrics.passed && metrics.adiabatic_outer_flux_W == 0 && ...
        metrics.nonzero_internal_gradient_K > budgetK;
end
end

function writeTrace(path, trace)
n = size(trace.data,2)-7;
header = [{'time_s','T_exterior_K','T_interior_K','q_exterior_W','q_interior_W', ...
    'E_J','dE_dt_W','residual_W'}, cellstr(compose('T_state_%02d_K',1:n))];
writetable(array2table([trace.time_s trace.data], 'VariableNames', header), path);
end

function makePlots(folder, trace, c)
figureHandle = figure('Visible', 'off');
cleanup = onCleanup(@() close(figureHandle));
subplot(2,1,1);
plot(trace.time_s/3600, trace.data(:,8:end)-273.15);
xlabel('Time (h)'); ylabel('Node temperature (degC)'); title(c.name, 'Interpreter', 'none');
grid on;
subplot(2,1,2);
plot(trace.time_s/3600, [trace.data(:,5)-trace.data(1,5), ...
    cumtrapz(trace.time_s, trace.data(:,3)+trace.data(:,4))]);
xlabel('Time (h)'); ylabel('Energy change (J)'); legend('Stored', 'Boundary integral'); grid on;
exportgraphics(figureHandle, fullfile(folder, 'transient.png'));
end

function closeOwned(model)
if bdIsLoaded(model), close_system(model, 0); end
end

function assertNear(a, b, name)
assert(abs(a-b) <= 64*eps(max(1,abs(b))), 'THERMA:Arithmetic', '%s mismatch.', name);
end

function writeJSON(path, value)
fid = fopen(path, 'w', 'n', 'UTF-8');
assert(fid >= 0, 'THERMA:WriteFailed', 'Cannot write report.');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s\n', jsonencode(value, 'PrettyPrint', true));
end
