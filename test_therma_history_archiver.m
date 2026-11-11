function tests = test_therma_history_archiver
% Software fixtures only. No Simulink models or benchmark results are generated.
tests=functiontests(localfunctions);
end

function testStreamBoundaryDuplicateAndResumeVerification(testCase)
[root,records]=fixture;
part=fullfile(root,'fixture.zip');
therma_history_write_part(root,part,'THERMA_HISTORY_REVIEW_001.zip',records,repmat('a',1,64));
therma_history_verify_part(part,root,'THERMA_HISTORY_REVIEW_001.zip',records,repmat('a',1,64));
% The same original paths/bytes can be reverified without writing another ZIP.
therma_history_verify_part(part,root,'THERMA_HISTORY_REVIEW_001.zip',records,repmat('a',1,64));
verifyTrue(testCase,isfile(part));
verifyError(testCase,@() therma_history_write_part(root,part,'x',records,'x'),'THERMA:HistoryExists');
end

function testChangedAndMissingSourcesBlocked(testCase)
[root,records]=fixture;
plan=struct('records',records);
% Fixture root must contain only declared sources at the first inventory.
report=therma_history_preflight(root,plan);
verifyEqual(testCase,report.status,'source_matches_audit');
file=fullfile(root,records(1).path);
fid=fopen(file,'ab');fwrite(fid,uint8(9));fclose(fid);
report=therma_history_preflight(root,plan);
verifyEqual(testCase,report.status,'blocked_source_changed_missing_or_new');
records(1).path='missing_original.bin';
report=therma_history_preflight(root,struct('records',records));
verifyNotEmpty(testCase,report.issues);
end

function testCorruptedZIPRejected(testCase)
[root,records]=fixture;
part=fullfile(root,'corrupt.zip');
fid=fopen(part,'wb');fwrite(fid,uint8('SOFTWARE TEST: NOT A ZIP'));fclose(fid);
failed=false;
try
    therma_history_verify_part(part,root,'x',records,repmat('a',1,64));
catch
    failed=true;
end
verifyTrue(testCase,failed);
end

function testLowStorageGuard(testCase)
verifyError(testCase,@() therma_history_space(tempdir,realmax),'THERMA:HistorySpace');
end

function [root,records] = fixture
root=tempname(tempdir);mkdir(root);
sizes=[0 1 1024*1024 1024*1024+1 2*1024*1024+1 1];
records=struct('path',{},'bytes',{},'sha256',{},'action',{},'group',{},'part',{});
for k=1:numel(sizes)
    name=sprintf('software_fixture_%d.bin',k);
    bytes=uint8(mod(0:sizes(k)-1,251));
    file=fullfile(root,name);
    fid=fopen(file,'wb');assert(fid>=0);fwrite(fid,bytes,'uint8');fclose(fid);
    records(k)=struct('path',name,'bytes',sizes(k),'sha256',boptest_file_sha256(file), ...
        'action','archive','group','REVIEW','part','THERMA_HISTORY_REVIEW_001.zip');
end
% Duplicate bytes at paths2/6 are deliberately retained as separate entries.
end
