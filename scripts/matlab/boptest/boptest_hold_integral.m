function result = boptest_hold_integral(time_s, values, query_s)
%BOPTEST_HOLD_INTEGRAL Exact integral of prescribed holds from first event time.
% Values at final endpoints have zero measure; duplicate timestamps add no area.
boptest_hold_values(time_s,values,query_s,"right"); % Validate shared contract.
result = zeros(numel(query_s),size(values,2));
for sample = 1:numel(query_s)
    edges = unique([time_s(1);time_s(time_s>time_s(1) & time_s<query_s(sample));query_s(sample)]);
    if numel(edges)>1
        u = boptest_hold_values(time_s,values,edges(1:end-1),"right");
        result(sample,:) = sum(diff(edges).*u,1);
    end
end
end
