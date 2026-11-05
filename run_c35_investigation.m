function reportFile=run_c35_investigation(mode)
%RUN_C35_INVESTIGATION Sequential, resumable actual MATLAB cases; no reference claims.
if nargin<1, mode="capacity"; end
mode=char(mode); assert(ismember(mode,{'quick','capacity','all'}),'THERMA:C35Mode','Use quick, capacity or all.');
root=fileparts(mfilename('fullpath'));
addpath(fullfile(root,'scripts','matlab','c35'),fullfile(root,'scripts','matlab','c3'), ...
    fullfile(root,'scripts','matlab','boptest'));
[cases,plan]=c35_plan(); contract=makeContract(root); parent=fullfile(root,'outputs','c3','c35',contract.sha256(1:16));
if ~isfolder(parent), mkdir(parent); end
write_boptest_json(fullfile(parent,'study_contract.json'),contract.value);
reportFile=fullfile(parent,['study_' mode '.json']);
report=struct('status','running','mode',mode,'matlab_version',version,'simulink',ver('Simulink'), ...
    'study_contract_sha256',contract.sha256,'reference_validation',false,'cases',{{}},'controller_case','');
try
    testGateFile=fullfile(parent,'test_gate.json'); reusable=false;
    if isfile(testGateFile)
        try
            testGate=jsondecode(fileread(testGateFile));
            reusable=strcmp(testGate.contract_sha256,contract.sha256) && testGate.passed==16 && ...
                testGate.failed==0 && testGate.incomplete==0 && ...
                ~contains(testGate.log_name,{'/','\',':'}) && ...
                strcmp(boptest_file_sha256(fullfile(parent,testGate.log_name)),testGate.log_sha256);
        catch
            reusable=false;
        end
    end
    if ~reusable
        suite=matlab.unittest.TestSuite.fromFile(fullfile(root,'tests','matlab','test_therma_c3_components.m'));
        additions=matlab.unittest.TestSuite.fromFile(fullfile(root,'tests','matlab','test_therma_c35.m'));
        suite=[suite(:);additions(:)];
        text=evalc('testResults=run(suite);'); fprintf('%s',text);
        logFile=[tempname(parent) '.txt']; saveText(logFile,text); [~,logName,extension]=fileparts(logFile);
        testGate=struct('contract_sha256',contract.sha256,'passed',sum([testResults.Passed]), ...
            'failed',sum([testResults.Failed]),'incomplete',sum([testResults.Incomplete]), ...
            'log_name',[logName extension],'log_sha256',boptest_file_sha256(logFile));
        report.tests_passed=testGate.passed; report.tests_failed=testGate.failed;
        report.tests_incomplete=testGate.incomplete; write_boptest_json(reportFile,report);
        assert(numel(testResults)==16,'THERMA:C35TestCount','Expected 13 component plus 3 C3.5 tests.');
        assertSuccess(testResults); write_boptest_json(testGateFile,testGate);
    else
        fprintf('Reusing hash-verified 16-test gate for this source/release contract.\n');
    end
    report.tests_passed=testGate.passed; report.tests_failed=testGate.failed;
    report.tests_incomplete=testGate.incomplete; report.test_gate_reused=reusable;
    report.test_gate_sha256=boptest_file_sha256(testGateFile);
    if strcmp(mode,'quick')
        report.status='quick_tests_passed_no_24h_cases'; write_boptest_json(reportFile,report); return;
    end
    if strcmp(mode,'capacity'), cases=cases(1:4); end
    results={}; paths={};
    for k=1:numel(cases)
        [results{k},paths{k}]=c35_run_case(cases(k),plan,parent,contract.sha256);
        report.cases{k}=struct('id',cases(k).id,'folder',portable(paths{k},parent), ...
            'completion_sha256',boptest_file_sha256(fullfile(paths{k},'completion.json')));
        write_boptest_json(reportFile,report);
    end
    controllerID=''; selected=0;
    if strcmp(mode,'all')
        % Prefer an observed upper-threshold off event; otherwise use a case
        % reaching 21 C without pretending it proves upper-threshold regulation.
        for k=1:7
            if results{k}.metrics.off_events>0, selected=k; break; end
        end
        if selected==0
            for k=1:7
                if results{k}.metrics.reach_21_0_observed, selected=k; break; end
            end
        end
        if selected==0
            c=cases(1); f=plan.controller_fallback; c.id='C_controller_fallback'; c.group='C';
            c.UA_W_K=f.UA_W_K; c.supply_K=f.supply_degC+273.15; c.outdoor_K=f.outdoor_degC+273.15;
            c.initial_zone_K=f.initial_zone_degC+273.15; c.initial_radiator_K=f.initial_radiator_degC+273.15;
            c.purpose=f.source;
            [result,path]=c35_run_case(c,plan,parent,contract.sha256);
            results{end+1}=result; paths{end+1}=path; selected=numel(results);
        end
        controllerID=results{selected}.case_definition.id; report.controller_case=controllerID;
        % F is always attempted for baseline; switched-case F requires observed switching.
        convergenceCases=1;
        if results{selected}.metrics.off_events>0, convergenceCases=[1 selected];
        else, report.controller_off_and_switched_convergence_blocked=true; end
        for original=convergenceCases
            for step=[5 1]
                c=results{original}.case_definition; c.id=sprintf('F_%s_step_%d',c.id,step);
                c.group='F'; c.max_step_s=step;
                [result,path]=c35_run_case(c,plan,parent,contract.sha256);
                results{end+1}=result; paths{end+1}=path;
            end
        end
    end
    report.cases=cell(1,numel(results));
    for k=1:numel(results)
        report.cases{k}=struct('id',results{k}.case_definition.id,'folder',portable(paths{k},parent), ...
            'completion_sha256',boptest_file_sha256(fullfile(paths{k},'completion.json')));
    end
    viewParent=fullfile(parent,'summaries'); if ~isfolder(viewParent), mkdir(viewParent); end
    view=tempname(viewParent); mkdir(view);
    c35_render(view,results,paths,controllerID,plan,mode); report.summary_folder=portable(view,parent);
    gate=jsondecode(fileread(fullfile(root,'verification','c3','c34_gate','summary.json')));
    b=results{1}.metrics; d=gate.diagnostics;
    report.baseline_reproduction=struct('maximum_air_difference_K',b.maximum_air_degC-(d.air_max_K-273.15), ...
        'delivered_energy_difference_kWh',b.delivered_kWh-d.delivered_final_J/3.6e6, ...
        'peak_absolute_power_difference_W',b.maximum_absolute_delivered_W-d.maximum_abs_delivered_W, ...
        'note','Extra diagnostic integrators may change adaptive sample times; original baseline/configuration remains unmodified.');
    report.status=[mode '_actual_cases_completed_not_reference_validated'];
    if isfield(report,'controller_off_and_switched_convergence_blocked')
        report.status='actual_available_cases_completed_controller_off_and_switched_convergence_blocked';
    end
    write_boptest_json(reportFile,report);
catch problem
    report.status='failed'; report.error=boptest_exception_diagnostic(problem);
    write_boptest_json(reportFile,report); print_boptest_exception(problem,reportFile); rethrow(problem);
end
fprintf('C3.5 study: %s\n',reportFile);
end
function contract=makeContract(root)
manifest=fullfile(root,'C35_PACKAGE_SHA256SUMS');
if isfile(manifest)
    lines=splitlines(string(fileread(manifest)));
    for k=1:numel(lines)
        if strlength(lines(k))==0, continue; end
        item=regexp(char(lines(k)),'^([0-9a-f]{64})  (.+)$','tokens','once');
        assert(~isempty(item) && ~startsWith(item{2},'/') && ~contains(item{2},':') && ...
            ~contains(item{2},'\') && ~any(strcmp(strsplit(item{2},'/'),'..')), ...
            'THERMA:C35Manifest','Unsafe manifest entry.');
        assert(strcmp(boptest_file_sha256(fullfile(root,item{2})),item{1}), ...
            'THERMA:C35Integrity','Missing/changed packaged file: %s',item{2});
    end
end
gateFile=fullfile(root,'verification','c3','c34_gate','summary.json'); gate=jsondecode(fileread(gateFile));
assert(gate.tests_passed==17 && gate.tests_failed==0 && gate.tests_incomplete==0 && ...
    gate.nominal_simulation_completed && strcmp(gate.status,'C34_integration_checks_passed_not_reference_validated') && ...
    all(structfun(@(v) logical(v),gate.diagnostics.checks)),'THERMA:C35Gate','C3.4 gate is not passed.');
for k=1:numel(gate.integration_sources)
    item=gate.integration_sources(k);
    assert(strcmp(boptest_file_sha256(fullfile(root,item.name)),item.sha256), ...
        'THERMA:C35Gate','Verified C3.4 source changed: %s',item.name);
end
assert(strcmp(boptest_file_sha256(fullfile(root,'configs','c3','integration_c34.json')),gate.integration_config_sha256), ...
    'THERMA:C35Gate','Frozen C3.4 baseline configuration changed.');
value=struct('matlab_version',version,'simulink',ver('Simulink'), ...
    'gate_sha256',boptest_file_sha256(gateFile), ...
    'plan_sha256',boptest_file_sha256(fullfile(root,'configs','c35','investigation.json')), ...
    'component_config_sha256',boptest_file_sha256(fullfile(root,'configs','c3','illustrative_components.json')));
oldGate=fullfile(root,'verification','c3','component_gate','summary.json');
assert(strcmp(boptest_file_sha256(oldGate),gate.component_gate_summary_sha256), ...
    'THERMA:C35Gate','Original component-gate summary changed.');
component=jsondecode(fileread(oldGate));
assert(strcmp(value.component_config_sha256,component.assumptions_sha256), ...
    'THERMA:C35Gate','Verified component defaults changed; use new case workspaces only.');
for k=1:numel(component.source_files)
    item=component.source_files(k);
    assert(strcmp(boptest_file_sha256(fullfile(root,item.name)),item.sha256), ...
        'THERMA:C35Gate','Original component source/test changed: %s',item.name);
end
physics={'build_boptest_zone_c2.m','load_boptest_zone_parameters.m','load_boptest_envelope_parameters.m', ...
    'add_boptest_construction.m','boptest_zone_analytical_network.m'};
value.physics_sources=cell(1,numel(physics));
for k=1:numel(physics)
    relative=['scripts/matlab/boptest/' physics{k}];
    value.physics_sources{k}=struct('name',relative,'sha256',boptest_file_sha256(fullfile(root,relative)));
end
files=dir(fullfile(root,'scripts','matlab','c35','*.m')); value.sources=cell(1,numel(files)+2);
for k=1:numel(files)
    relative=['scripts/matlab/c35/' files(k).name]; value.sources{k}=struct('name',relative,'sha256',boptest_file_sha256(fullfile(root,relative)));
end
extra={'run_c35_investigation.m','tests/matlab/test_therma_c35.m'};
for k=1:2, value.sources{numel(files)+k}=struct('name',extra{k},'sha256',boptest_file_sha256(fullfile(root,extra{k}))); end
file=[tempname '.json']; cleanup=onCleanup(@() delete(file)); write_boptest_json(file,value);
contract=struct('sha256',boptest_file_sha256(file),'value',value);
end
function name=portable(path,parent)
name=strrep(erase(path,[parent filesep]),filesep,'/');
end
function saveText(file,text)
fid=fopen(file,'w','n','UTF-8'); assert(fid>=0,'THERMA:C35Log','Cannot save actual test log.');
cleanup=onCleanup(@() fclose(fid)); fprintf(fid,'%s',text);
end
