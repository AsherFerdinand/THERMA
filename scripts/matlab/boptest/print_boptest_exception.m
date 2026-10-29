function print_boptest_exception(problem,reportFile)
%PRINT_BOPTEST_EXCEPTION Show extended MATLAB diagnostic, all causes and stacks.
fprintf(2,'\nTHERMA replay failed. Full diagnostic JSON: %s\n',reportFile);
fprintf(2,'%s\n',getReport(problem,'extended','hyperlinks','off'));
% Explicit recursion prevents aggregate getReport formatting from hiding children.
printCause(problem,0);
end

function printCause(problem,depth)
indent = repmat(' ',1,2*depth);
fprintf(2,'%s[%s] %s\n',indent,problem.identifier,problem.message);
for frame = 1:numel(problem.stack)
    item = problem.stack(frame);
    fprintf(2,'%s  at %s (%s:%d)\n',indent,item.name,item.file,item.line);
end
for child = 1:numel(problem.cause), printCause(problem.cause{child},depth+1); end
end
