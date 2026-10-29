function result = boptest_hold_values(time_s, values, query_s, side)
%BOPTEST_HOLD_VALUES Explicit piecewise-constant left/right limits; no interpolation.
% Repeated event timestamps are permitted: last row wins on the right. The
% left limit uses the preceding strictly earlier time (first row at start).
arguments
    time_s (:,1) double
    values double
    query_s (:,1) double
    side (1,1) string {mustBeMember(side,["left","right"])} = "right"
end
assert(~isempty(time_s) && size(values,1)==numel(time_s) && ...
    all(isfinite(time_s)) && all(diff(time_s)>=0) && all(isfinite(values),'all'), ...
    'THERMA:HoldData','Expected finite values and nondecreasing event times.');
assert(all(isfinite(query_s)) && all(query_s>=time_s(1) & query_s<=time_s(end)), ...
    'THERMA:HoldCoverage','No extrapolation outside event coverage.');
result = zeros(numel(query_s),size(values,2));
for j = 1:numel(query_s)
    if side == "right", index = find(time_s<=query_s(j),1,'last');
    else, index = find(time_s<query_s(j),1,'last'); end
    if isempty(index), index = 1; end
    result(j,:) = values(index,:);
end
end
