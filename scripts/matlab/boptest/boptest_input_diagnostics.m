function [diagnostics, expected, eventMask] = boptest_input_diagnostics(c,t,logged)
%BOPTEST_INPUT_DIAGNOSTICS Check prescribed holds independently of logged routing.
% At an exact event output sample either logged one-sided limit is permissible;
% all non-event samples must match the right-continuous prescribed signal.
expected = boptest_hold_values(c.time_s,c.values,t,"right");
left = boptest_hold_values(c.time_s,c.values,t,"left");
changes = find(any(diff(c.values,1,1)~=0,2))+1;
steps = unique(c.time_s(changes));
budget = 64*eps(max(1,max(abs(c.values),[],1)));
eventMask = false(size(t));
for j = 1:numel(steps)
    atEvent = abs(t-steps(j)) <= 64*eps(max(1,abs(steps(j))));
    eventMask = eventMask | atEvent;
    left(atEvent,:) = repmat(boptest_hold_values(c.time_s,c.values,steps(j),"left"), ...
        sum(atEvent),1);
end
error = abs(logged-expected);
policyError = error;
for sample = find(eventMask)'
    % Accept a complete left or right vector, never a mixture of channels.
    if all(abs(logged(sample,:)-left(sample,:))<=budget)
        policyError(sample,:) = abs(logged(sample,:)-left(sample,:));
    end
end
diagnostics = struct('step_times_s',steps', 'expected_policy','right-continuous zero-order hold', ...
    'exact_event_policy','complete left or right vector; never a ramp/intermediate vector', ...
    'max_input_error_by_channel',max(error,[],1), ...
    'max_non_event_input_error_by_channel',maximum(error(~eventMask,:)), ...
    'max_policy_error_by_channel',max(policyError,[],1), ...
    'input_roundoff_budget_by_channel',budget,'passed',all(policyError<=budget,'all'), ...
    'steps',{{}});
for j = 1:numel(steps)
    step = steps(j);
    before = find(t<step-64*eps(max(1,abs(step))),1,'last');
    after = find(t>step+64*eps(max(1,abs(step))),1,'first');
    at = find(abs(t-step)<=64*eps(max(1,abs(step))));
    diagnostics.steps{end+1} = struct('step_time_s',step, ...
        'expected_before',boptest_hold_values(c.time_s,c.values,step,"left"), ...
        'expected_after',boptest_hold_values(c.time_s,c.values,step,"right"), ...
        'logged_before_time_s',t(before),'logged_before',logged(before,:), ...
        'logged_after_time_s',t(after),'logged_after',logged(after,:), ...
        'logged_at_step',logged(at,:));
end
end

function result = maximum(values)
if isempty(values), result = []; else, result = max(values,[],1); end
end
