function reportFile=run_c34_verification()
%RUN_C34_VERIFICATION Component regression + integration gate + one cold-start run.
root=fileparts(mfilename('fullpath'));
addpath(fullfile(root,'scripts','matlab','c3'),fullfile(root,'scripts','matlab','boptest'));
parent=fullfile(root,'outputs','c3','c34'); if ~isfolder(parent), mkdir(parent); end
folder=tempname(parent); mkdir(folder); reportFile=fullfile(folder,'c34_verification.json');
report=struct('status','running','stage','package_and_gate','matlab_version',version, ...
    'simulink',ver('Simulink'),'nominal_simulation_completed',false,'reference_validation',false, ...
    'C35_C36_started',false);
try
    manifest=fullfile(root,'C34_PACKAGE_SHA256SUMS');
    if isfile(manifest)
        lines=splitlines(string(fileread(manifest)));
        for k=1:numel(lines)
            if strlength(lines(k))==0, continue; end
            item=regexp(char(lines(k)),'^([0-9a-f]{64})  (.+)$','tokens','once');
            assert(~isempty(item) && ~startsWith(item{2},'/') && ~contains(item{2},':') && ...
                ~contains(item{2},'\') && ~any(strcmp(strsplit(item{2},'/'),'..')), ...
                'THERMA:C34Manifest','Unsafe manifest entry.');
            assert(strcmp(boptest_file_sha256(fullfile(root,strrep(item{2},'/',filesep))),item{1}), ...
                'THERMA:C34Integrity','Missing/changed package file: %s',item{2});
        end
        provenance=jsondecode(fileread(fullfile(root,'C34_PACKAGE_PROVENANCE.json')));
        report.source_commit=provenance.source_commit;
    end
    gateFile=fullfile(root,'verification','c3','component_gate','summary.json');
    gate=jsondecode(fileread(gateFile));
    assert(gate.tests_passed==13 && gate.tests_failed==0 && gate.tests_incomplete==0 && ...
        strcmp(gate.status,'component_tests_passed_in_MATLAB_integration_review_pending'), ...
        'THERMA:C34Gate','Component execution gate is not passed.');
    for k=1:numel(gate.source_files)
        item=gate.source_files(k);
        assert(strcmp(boptest_file_sha256(fullfile(root,item.name)),item.sha256), ...
            'THERMA:C34Gate','Previously verified component source changed: %s',item.name);
    end
    assert(strcmp(boptest_file_sha256(fullfile(root,'configs','c3','illustrative_components.json')), ...
        gate.assumptions_sha256),'THERMA:C34Gate','Verified component assumptions changed.');
    assert(strcmp(boptest_file_sha256(fullfile(fileparts(gateFile),'matlab_component_test_log.txt')), ...
        gate.original_test_log_sha256),'THERMA:C34Gate','Original component test log changed.');
    listing=dir(fullfile(root,'scripts','matlab','c3','*.m')); report.integration_sources=cell(1,numel(listing)+2);
    for k=1:numel(listing)
        relative=['scripts/matlab/c3/' listing(k).name];
        report.integration_sources{k}=struct('name',relative,'sha256',boptest_file_sha256(fullfile(root,relative)));
    end
    extra={'run_c34_verification.m','tests/matlab/test_therma_c34_integration.m'};
    for k=1:2
        report.integration_sources{numel(listing)+k}=struct('name',extra{k},'sha256',boptest_file_sha256(fullfile(root,extra{k})));
    end
    report.component_gate=gate; report.component_gate_summary_sha256=boptest_file_sha256(gateFile);
    report.stage='tests';
    suite=matlab.unittest.TestSuite.fromFile(fullfile(root,'tests','matlab','test_therma_c3_components.m'));
    integrationSuite=matlab.unittest.TestSuite.fromFile(fullfile(root,'tests','matlab','test_therma_c34_integration.m'));
    suite=[suite(:);integrationSuite(:)];
    fprintf('Running verified component regressions and new integration fixtures.\n');
    text=evalc('results=run(suite);'); fprintf('%s',text);
    saveLog(fullfile(folder,'matlab_integration_test_log.txt'),text);
    report.tests_passed=sum([results.Passed]); report.tests_failed=sum([results.Failed]);
    report.tests_incomplete=sum([results.Incomplete]); report.test_duration_s=sum([results.Duration]);
    report.test_cases=cell(1,numel(results));
    for k=1:numel(results)
        report.test_cases{k}=struct('name',results(k).Name,'passed',results(k).Passed, ...
            'failed',results(k).Failed,'incomplete',results(k).Incomplete,'duration_s',results(k).Duration);
    end
    write_boptest_json(reportFile,report);
    assert(numel(results)==17,'THERMA:C34TestCount','Expected 13 component plus 4 integration/CSV tests.');
    assertSuccess(results);
    report.stage='cold_start_simulation'; I=load_c34_experiment();
    report.integration_config_sha256=boptest_file_sha256(fullfile(root,'configs','c3','integration_c34.json'));
    [time,values,info,D]=simulate_c34_model(I,folder);
    report.nominal_simulation_completed=true; report.integration=info; report.diagnostics=D;
    report.model_sha256=boptest_file_sha256(info.model_file);
    report.stage='exports'; export_c34_results(folder,time,values,info,D);
    assert(strcmp(D.status,'integration_numerical_checks_passed'), ...
        'THERMA:C34Checks','Integration checks failed. Inspect actual traces/diagnostics; do not proceed to C3.5.');
    report.status='C34_integration_checks_passed_not_reference_validated'; report.stage='completed';
    write_boptest_json(reportFile,report);
catch problem
    report.status='failed'; report.error=boptest_exception_diagnostic(problem);
    write_boptest_json(reportFile,report); print_boptest_exception(problem,reportFile); rethrow(problem);
end
fprintf('C3.4 report: %s\n',reportFile);
end
function saveLog(file,text)
fid=fopen(file,'w','n','UTF-8'); assert(fid>=0,'THERMA:C34Log','Cannot create actual MATLAB log.');
cleanup=onCleanup(@() fclose(fid)); fprintf(fid,'%s',text);
end
