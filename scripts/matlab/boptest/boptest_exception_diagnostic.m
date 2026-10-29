function diagnostic = boptest_exception_diagnostic(problem)
%BOPTEST_EXCEPTION_DIAGNOSTIC Lossless exception tree for replay JSON diagnostics.
% Do not flatten MultipleErrors: each child may identify a different source block.
arguments
    problem (1,1) MException
end
frames = problem.stack;
% A cell array yields stable JSON arrays for zero, one and multiple stack frames.
stack = cell(1,numel(frames));
for j = 1:numel(frames)
    stack{j} = struct('file',frames(j).file,'name',frames(j).name,'line',frames(j).line);
end
causes = cell(1,numel(problem.cause));
for j = 1:numel(problem.cause)
    causes{j} = boptest_exception_diagnostic(problem.cause{j});
end
diagnostic = struct('identifier',problem.identifier,'message',problem.message, ...
    'stack',{stack},'causes',{causes}, ...
    'extended_report',getReport(problem,'extended','hyperlinks','off'));
end
