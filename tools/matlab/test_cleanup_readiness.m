function tests = test_cleanup_readiness
tests=functiontests(localfunctions);
end
function testAllChangeClasses(testCase)
original=struct('path',{'same','changed','gone'},'bytes',{1,1,1}, ...
    'sha256',{'a','b','c'});
current=struct('path',{'same','changed','new','slprj/new.mat','bad'}, ...
    'bytes',{1,1,2,1,0},'sha256',{'a','x','y','z',''}, ...
    'error',{'','','','','TEST:Unreadable'});
r=therma_cleanup_compare(original,current);
verifyEqual(testCase,{r.status},{'unreadable','modified','deleted','added','unchanged','added'});
verifyEqual(testCase,{r([r.preservation_required]).path},{'bad','changed','new'});
end
function testSameHashDifferentSizeIsModified(testCase)
a=struct('path','x','bytes',1,'sha256','a');
b=struct('path','x','bytes',2,'sha256','a','error','');
r=therma_cleanup_compare(a,b);verifyEqual(testCase,r.status,'modified');
end
function testCaseCollisionBlocks(testCase)
a=struct('path','x','bytes',1,'sha256','a');
b=struct('path',{'x','X'},'bytes',{1,1},'sha256',{'a','a'},'error',{'',''});
verifyError(testCase,@() therma_cleanup_compare(a,b),'THERMA:AmbiguousInventory');
end
