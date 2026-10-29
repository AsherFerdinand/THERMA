function exact = boptest_piecewise_reference(A,B,initial,time_s,values,query_s)
%BOPTEST_PIECEWISE_REFERENCE Verification-only linear-system step propagator.
% Integrate each old segment, keep states continuous, then apply the new hold.
% Supports duplicate output/event timestamps without inventing state jumps.
boptest_hold_values(time_s,values,query_s,"right");
assert(all(diff(query_s)>=0),'THERMA:ReferenceTime','Output times must be nondecreasing.');
n = numel(initial);
assert(isequal(size(A),[n n]) && size(B,1)==n && size(B,2)==size(values,2), ...
    'THERMA:ReferenceDimensions','Reference matrices and input dimensions differ.');
exact = zeros(numel(query_s),n); state = initial(:); previous = time_s(1);
for sample = 1:numel(query_s)
    edges = unique([previous;time_s(time_s>previous & time_s<query_s(sample));query_s(sample)]);
    for interval = 1:numel(edges)-1
        u = boptest_hold_values(time_s,values,edges(interval),"right")';
        augmented = [A B*u;zeros(1,n+1)];
        propagated = expm(augmented*(edges(interval+1)-edges(interval)))*[state;1];
        state = propagated(1:n);
    end
    exact(sample,:) = state'; previous = query_s(sample);
end
end
