function reportFile=run_c3_verification()
%RUN_C3_VERIFICATION C3.1-C3.3 gate only; does not generate a closed-loop zone.
root=fileparts(mfilename('fullpath'));
addpath(fullfile(root,'scripts','matlab','c3'),fullfile(root,'scripts','matlab','boptest'));
parent=fullfile(root,'outputs','c3','verification'); if ~isfolder(parent), mkdir(parent); end
folder=tempname(parent); mkdir(folder); reportFile=fullfile(folder,'component_verification.json');
report=struct('status','running','scope','C3.1-C3.3_components_only', ...
    'matlab_version',version,'simulink',ver('Simulink'),'illustrative_not_BOPTEST',true, ...
    'C3_4_integration_verified',false, ...
    'component_solver',struct('name','ode15s','RelTol',1e-8,'AbsTol',1e-10,'MaxStep_s',1));
try
    manifest=fullfile(root,'C3_PACKAGE_SHA256SUMS');
    if isfile(manifest)
        lines=splitlines(string(fileread(manifest)));
        for j=1:numel(lines)
            if strlength(lines(j))==0, continue; end
            parts=regexp(char(lines(j)),'^([0-9a-f]{64})  (.+)$','tokens','once');
            assert(~isempty(parts) && ~startsWith(parts{2},'/') && ~contains(parts{2},':') && ...
                ~contains(parts{2},'\') && ~any(strcmp(strsplit(parts{2},'/'),'..')), ...
                'THERMA:C3Manifest','Unsafe package manifest entry.');
            assert(strcmp(boptest_file_sha256(fullfile(root,strrep(parts{2},'/',filesep))),parts{1}), ...
                'THERMA:C3Integrity','Changed/missing package file: %s',parts{2});
        end
    end
    provenanceFile=fullfile(root,'C3_PACKAGE_PROVENANCE.json');
    if isfile(provenanceFile)
        provenance=jsondecode(fileread(provenanceFile));
        report.source_commit=provenance.source_commit;
        report.package_provenance_sha256=boptest_file_sha256(provenanceFile);
    end
    listing=dir(fullfile(root,'scripts','matlab','c3','*.m'));
    report.source_files=cell(1,numel(listing)+2);
    for k=1:numel(listing)
        relative=['scripts/matlab/c3/' listing(k).name];
        report.source_files{k}=struct('name',relative,'sha256',boptest_file_sha256(fullfile(root,relative)));
    end
    extras={'run_c3_verification.m','tests/matlab/test_therma_c3_components.m'};
    for k=1:2
        report.source_files{numel(listing)+k}=struct('name',extras{k}, ...
            'sha256',boptest_file_sha256(fullfile(root,extras{k})));
    end
    report.assumptions_sha256=boptest_file_sha256(fullfile(root,'configs','c3','illustrative_components.json'));
    fprintf('Running C3 component tests in native Simulink. No zone benchmark will run.\n');
    testText=evalc('results=runtests(fullfile(root,''tests'',''matlab'',''test_therma_c3_components.m''));');
    fprintf('%s',testText);
    writeTestLog(fullfile(folder,'matlab_component_test_log.txt'),testText);
    report.test_duration_s=sum([results.Duration]);
    report.tests_passed=sum([results.Passed]); report.tests_failed=sum([results.Failed]);
    report.tests_incomplete=sum([results.Incomplete]);
    write_boptest_json(reportFile,report);
    assertSuccess(results);
    P=load_c3_parameters(); kinds={'thermostat','valve','radiator'};
    report.models=cell(1,3);
    for j=1:3
        [model,file]=build_c3_component(kinds{j},P,folder); close_system(model,0);
        report.models{j}=struct('component',kinds{j},'file',file,'sha256',boptest_file_sha256(file));
    end
    report.status='component_tests_passed_in_MATLAB_integration_review_pending';
    report.next_step='Return report for review before C3.4 integration; no zone benchmark has run.';
    write_boptest_json(reportFile,report);
catch problem
    report.status='failed'; report.error=boptest_exception_diagnostic(problem);
    write_boptest_json(reportFile,report); print_boptest_exception(problem,reportFile); rethrow(problem);
end
fprintf('C3 component report: %s\n',reportFile);
end

function writeTestLog(file,text)
fid=fopen(file,'w','n','UTF-8');
assert(fid>=0,'THERMA:C3Log','Cannot write actual MATLAB test log.');
cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'%s',text);
end
