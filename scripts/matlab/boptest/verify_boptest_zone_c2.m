function reportFile = verify_boptest_zone_c2(assumptionsFile)
%VERIFY_BOPTEST_ZONE_C2 Execute generated blocks, independent analytical oracle.
% Does not assert equivalence to the full BOPTEST moist-air/glazing model.
arguments
    assumptionsFile (1,1) string
end
root = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
parent = fullfile(root,'outputs','boptest','simulink_c2','verification');
if ~isfolder(parent), mkdir(parent); end
folder = tempname(parent); mkdir(folder);
reportFile = fullfile(folder,'verification.json');
report = struct('status','running','matlab_verified',false,'matlab_version',version, ...
    'simulink_version',ver('Simulink'),'cases',{{}},'model_version','C2-reduced-v1', ...
    'scope','reduced model component verification, not BOPTEST validation');
write_boptest_json(reportFile,report);
try
    [model,modelFile,Z] = build_boptest_zone_c2(assumptionsFile,'ShowModel',false);
    cleanup = onCleanup(@() close_system(model,0));
    report.generated_model = modelFile;
    report.registry_sha256 = Z.envelope.registry_sha256;
    report.assumptions = Z.assumptions;
    report.assumptions_sha256 = Z.assumptions_sha256;
    sourceFiles = dir(fullfile(fileparts(mfilename('fullpath')),'*.m'));
    report.source_sha256 = struct();
    for source = 1:numel(sourceFiles)
        key = matlab.lang.makeValidName(sourceFiles(source).name);
        report.source_sha256.(key) = boptest_file_sha256( ...
            fullfile(sourceFiles(source).folder,sourceFiles(source).name));
    end
    assert(strcmp(get_param([model '/Inputs'],'Interpolate'),'off'), ...
        'THERMA:C2Interpolation','Root input must disable interpolation for step scenarios.');
    report.input_interpolation = get_param([model '/Inputs'],'Interpolate');
    set_param(model,'SimulationCommand','update');
    assert(numel(find_system(model,'BlockType','Integrator')) == 28, ...
        'THERMA:C2StateCount','Expected 27 fabric + 1 air states.');
    cases = boptest_zone_scenarios();
    for j = 1:numel(cases)
        c = cases(j); result = struct('name',c.name,'status','running');
        caseFolder = fullfile(folder,c.name); mkdir(caseFolder);
        try
            parameters = Z;
            parameters.envelope.components(1).initial_K(end) = ...
                parameters.envelope.components(1).initial_K(end)+c.surface_offset_K;
            [A,B,C,initial] = boptest_zone_analytical_network(parameters);
            coarse = runCase(model,parameters,c,1e-7,1e-9,30);
            writeTrace(fullfile(caseFolder,'coarse.csv'),coarse);
            fine = runCase(model,parameters,c,1e-8,1e-10,15);
            writeTrace(fullfile(caseFolder,'refined.csv'),fine);
            result.coarse = analyse(coarse,c,parameters,A,B,C,initial);
            result.refined = analyse(fine,c,parameters,A,B,C,initial);
            result.temperature_discrepancy_K = max(abs( ...
                interp1(coarse.t,coarse.states,fine.t,'linear')-fine.states),[],'all');
            result.convergence_improved = result.refined.temperature_error_K <= ...
                result.coarse.temperature_error_K+64*eps(max(abs(fine.states),[],'all'));
            plotCase(caseFolder,coarse,fine,c.name);
            assert(result.coarse.passed && result.refined.passed && result.convergence_improved, ...
                'THERMA:C2Verification','Inspect temperature/energy/direction metrics and wiring.');
            result.status = 'passed';
        catch problem
            result.status = 'failed';
            result.failure = struct('identifier',problem.identifier,'message',problem.message, ...
                'inspect','Case CSVs, independent modal response, convection/gain sign and port order.');
        end
        report.cases{end+1} = result; write_boptest_json(reportFile,report);
    end
    success = all(cellfun(@(c) strcmp(c.status,'passed'),report.cases));
    if success, report.status = 'passed'; report.matlab_verified = true;
    else, report.status = 'failed'; end
catch problem
    report.status = 'failed';
    report.failure = struct('identifier',problem.identifier,'message',problem.message);
end
write_boptest_json(reportFile,report); fprintf('C2 report: %s\n',reportFile);
assert(report.matlab_verified,'THERMA:C2Failed','See preserved report: %s',reportFile);
end

function trace = runCase(model,Z,c,relative,absolute,step)
signal = timeseries(c.values,c.time_s); signal = setinterpmethod(signal,'zoh');
input = Simulink.SimulationInput(model);
input = input.setVariable('Z',Z,'Workspace',model);
input = input.setExternalInput(signal);
input = input.setModelParameter('StopTime',num2str(c.time_s(end)), ...
    'RelTol',num2str(relative,17),'AbsTol',num2str(absolute,17),'MaxStep',num2str(step));
% Additional output samples expose exact event limits without interpolating inputs.
input = input.setModelParameter('OutputOption','AdditionalOutputTimes', ...
    'OutputTimes',mat2str(unique(c.time_s)',17));
output = sim(input);
names = {'T_states_K','E_J','dE_dt_W','q_net_W','residual_W','q_vent_W','q_window_W', ...
    'q_air_to_surfaces_W','T_interior_K','q_exterior_W','q_heating_W', ...
    'q_internal_W','q_solar_W','q_radiation_exchange_W'};
series = output.get(names{1}); t = series.Time(:);
assert(all(isfinite(t)) && all(diff(t)>=0),'THERMA:C2Time', ...
    'Output timestamps must be finite/nondecreasing; duplicate events are permitted.');
% Keep rightmost event sample; never average across a discontinuity.
[t,index] = unique(t,'last');
trace = struct('t',t,'solver',struct('name','ode15s','RelTol',relative, ...
    'AbsTol_K',absolute,'MaxStep_s',step));
for j = 1:numel(names)
    s = output.get(names{j}); data = squeeze(s.Data);
    if size(data,1) ~= numel(s.Time), data = data'; end
    assert(isequal(s.Time(:),series.Time(:)),'THERMA:C2Time','Log time grids differ.');
    trace.(names{j}) = data(index,:);
end
rawInputs = output.get('inputs_used');
trace.raw_input_time_s = rawInputs.Time(:);
trace.raw_inputs = squeeze(rawInputs.Data);
if size(trace.raw_inputs,1) ~= numel(trace.raw_input_time_s), trace.raw_inputs = trace.raw_inputs'; end
assert(size(trace.raw_inputs,2)==11,'THERMA:C2Inputs','Expected 11 logged input channels.');
trace.inputs_used = boptest_hold_values(trace.raw_input_time_s,trace.raw_inputs,t,"right");
trace.duplicate_output_samples = numel(series.Time)-numel(t);
trace.states = trace.T_states_K;
assert(all(isfinite(trace.states),'all') && size(trace.states,2)==28, ...
    'THERMA:C2Trace','Invalid state count or nonfinite temperatures.');
end

function metrics = analyse(trace,c,Z,A,B,C,initial)
t = trace.t;
% Analytical trajectory always follows the prescribed holds, never a possibly
% misconfigured logged waveform. Offset only the outdoor-temperature channel.
reference = Z.initial_K;
values = c.values; values(:,1) = values(:,1)-reference;
exact = boptest_piecewise_reference(A,B,initial-reference,c.time_s,values,t)+reference;
budgetK = 20*(trace.solver.AbsTol_K+trace.solver.RelTol*max(abs(exact),[],'all'));
[inputDiagnostics,expectedInputs,eventMask] = boptest_input_diagnostics(c,t,trace.inputs_used);
u = trace.inputs_used; % Accounting uses signals actually entering the model.
expectedVent = Z.assumptions.parameters.rho_air_kg_m3.value * ...
    Z.assumptions.parameters.cp_air_J_kgK.value * Z.volume_flow_m3_s * ...
    (u(:,1)-trace.states(:,end));
expectedConv = sum((trace.states(:,end)-trace.T_interior_K).*Z.H_interior_W_K,2);
ventError = max(abs(trace.q_vent_W-expectedVent));
convError = max(abs(trace.q_air_to_surfaces_W-expectedConv));
expectedHeating = u(:,2)+u(:,3);
expectedInternal = u(:,4)+u(:,5); expectedSolar = sum(u(:,6:11),2);
inputError = max(abs([trace.q_heating_W-expectedHeating, ...
    trace.q_internal_W-expectedInternal,trace.q_solar_W-expectedSolar]),[],'all');
% Compute reference energy integral analytically from exact state changes, and
% retain raw sampled quadrature error separately (step events are right-continuous).
exactEnergy = (exact-reference)*C;
stateEnergy = (trace.states-reference)*C;
raw = trace.E_J-trace.E_J(1)-cumtrapz(t,trace.q_net_W);
exactPower = zeros(size(t));
for sample = 1:numel(t)
    exactPower(sample) = C'*(A*(exact(sample,:)'-reference)+ ...
        B*(u(sample,:)'-[reference;zeros(10,1)]));
end
bias = exactEnergy-exactEnergy(1)-cumtrapz(t,exactPower);
% Remove the known input jump before quadrature. The state-dependent power
% is continuous; integrate prescribed direct-feedthrough powers exactly by segment.
D = C'*B;
offsetInputs = u; offsetInputs(:,1) = offsetInputs(:,1)-reference;
continuousPower = trace.q_net_W-offsetInputs*D';
exactContinuousPower = (exact-reference)*(C'*A)';
directEnergy = boptest_hold_integral(c.time_s,values,t)*D';
directEnergy = directEnergy-directEnergy(1);
piecewiseRaw = trace.E_J-trace.E_J(1)-cumtrapz(t,continuousPower)-directEnergy;
piecewiseBias = exactEnergy-exactEnergy(1)-cumtrapz(t,exactContinuousPower)-directEnergy;
corrected = piecewiseRaw-piecewiseBias;
boundaryH = sum(Z.H_exterior_W_K)+Z.H_vent_W_K+Z.UA_window_W_K;
energyBudget = 2*sum(C)*budgetK+2*t(end)*boundaryH*budgetK;
% Include absolute-temperature products that cancel in surface matrix arithmetic.
scaleW = max([1;abs(trace.dE_dt_W);abs(trace.q_net_W); ...
    (sum(Z.H_interior_W_K)+sum(Z.H_exterior_W_K)+ ...
    sum(abs(Z.radiation_matrix_W_K),'all'))*max(abs(trace.states),[],'all')]);
powerBudget = 512*eps(scaleW);
temperatureError = max(abs(trace.states-exact),[],'all');
direction = true;
if strcmp(c.name,'cold_outdoor') || strcmp(c.name,'outdoor_step')
    direction = min(trace.states(:,end)) < reference && max(trace.q_vent_W) <= powerBudget;
elseif strcmp(c.name,'constant_heating') || strcmp(c.name,'heating_step')
    direction = max(trace.states(:,end)) > reference && min(trace.states,[],'all') >= reference-budgetK;
elseif strcmp(c.name,'warm_ventilation')
    direction = max(trace.states(:,end)) > reference && min(trace.q_vent_W) >= -powerBudget;
end
metrics = struct('solver',trace.solver,'temperature_error_K',temperatureError, ...
    'temperature_budget_K',budgetK,'max_power_residual_W',max(abs(trace.residual_W)), ...
    'power_roundoff_budget_W',powerBudget,'raw_integral_residual_J',max(abs(raw)), ...
    'analytical_quadrature_bias_J',max(abs(bias)), ...
    'corrected_integral_residual_J',max(abs(corrected)), ...
    'relative_integral_residual',max(abs(corrected))/max(1,max(abs(exactEnergy-exactEnergy(1)))), ...
    'energy_budget_J',energyBudget,'stored_energy_identity_error_J',max(abs(trace.E_J-stateEnergy)), ...
    'ventilation_error_W',ventError,'surface_convection_error_W',convError, ...
    'input_accounting_error_W',inputError,'physical_direction',direction, ...
    'input_diagnostics',inputDiagnostics, ...
    'input_accounting_error_excluding_events_W',outsideMax( ...
        [trace.q_heating_W-(expectedInputs(:,2)+expectedInputs(:,3)), ...
        trace.q_internal_W-(expectedInputs(:,4)+expectedInputs(:,5)), ...
        trace.q_solar_W-sum(expectedInputs(:,6:11),2)],eventMask), ...
    'piecewise_integral_residual_J',max(abs(piecewiseRaw)), ...
    'piecewise_analytical_quadrature_bias_J',max(abs(piecewiseBias)), ...
    'ventilation_error_excluding_events_W',outsideMax( ...
        trace.q_vent_W-Z.H_vent_W_K*(expectedInputs(:,1)-trace.states(:,end)),eventMask), ...
    'duplicate_output_samples',trace.duplicate_output_samples, ...
    'temperature_error_before_after_steps',{{}});
for event = 1:numel(inputDiagnostics.step_times_s)
    stepTime = inputDiagnostics.step_times_s(event);
    metrics.temperature_error_before_after_steps{end+1} = struct('step_time_s',stepTime, ...
        'before_K',subsetMax(abs(trace.states-exact),t<stepTime), ...
        'at_or_after_K',subsetMax(abs(trace.states-exact),t>=stepTime));
end
metrics.passed = temperatureError<=budgetK && max(abs(trace.residual_W))<=powerBudget && ...
    max(abs(corrected))<=energyBudget && max(abs(trace.E_J-stateEnergy))<=energyBudget && ...
    ventError<=powerBudget && convError<=powerBudget && inputError<=powerBudget && direction && ...
    inputDiagnostics.passed && ...
    max(abs(sum(trace.q_radiation_exchange_W,2)))<=powerBudget;
if strcmp(c.name,'equilibrium')
    metrics.equilibrium_drift_K = max(abs(trace.states-reference),[],'all');
    metrics.passed = metrics.passed && metrics.equilibrium_drift_K <= budgetK;
end
end

function writeTrace(file,trace)
header = [{'time_s'},cellstr(compose('T_state_%02d_K',1:28)), ...
    {'E_J','q_net_W','residual_W','q_vent_W','q_heating_W','q_exterior_W'}, ...
    cellstr(compose('input_%02d',1:11))];
data = [trace.t trace.states trace.E_J trace.q_net_W trace.residual_W ...
    trace.q_vent_W trace.q_heating_W trace.q_exterior_W trace.inputs_used];
writetable(array2table(data,'VariableNames',header),file);
[parent,name] = fileparts(file);
rawHeader = [{'time_s'},cellstr(compose('input_%02d',1:11))];
writetable(array2table([trace.raw_input_time_s trace.raw_inputs], ...
    'VariableNames',rawHeader),fullfile(parent,[name '_inputs_raw.csv']));
end

function plotCase(folder,coarse,fine,name)
f = figure('Visible','off'); cleanup = onCleanup(@() close(f));
subplot(3,2,1); plot(fine.t/3600,fine.states(:,end)-273.15); ylabel('Air degC');
subplot(3,2,2); plot(fine.t/3600,fine.T_interior_K-273.15); ylabel('Surfaces degC');
subplot(3,2,3); plot(fine.t/3600,fine.q_heating_W); ylabel('Heating W');
subplot(3,2,4); plot(fine.t/3600,fine.q_exterior_W); ylabel('Envelope W');
subplot(3,2,5); plot(fine.t/3600,fine.residual_W); ylabel('Power residual W');
subplot(3,2,6); plot(coarse.t/3600,coarse.states(:,end),fine.t/3600,fine.states(:,end));
ylabel('Air K'); legend('Coarse','Refined'); sgtitle(name,'Interpreter','none');
exportgraphics(f,fullfile(folder,'diagnostics.png'));
end

function value = subsetMax(data,mask)
if any(mask), value = max(data(mask,:),[],'all'); else, value = []; end
end

function value = outsideMax(data,eventMask)
value = subsetMax(abs(data),~eventMask);
end
