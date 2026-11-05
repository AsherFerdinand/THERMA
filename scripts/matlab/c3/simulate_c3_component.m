function [time,values,signals]=simulate_c3_component(kind,P,time,inputs,outputParent)
%SIMULATE_C3_COMPONENT Actual MATLAB/Simulink unit-test driver, never a zone solver.
% Signals are piecewise held; breakpoints must be finite and strictly ordered.
validateattributes(time,{'numeric'},{'column','real','finite','nonnegative','increasing'});
assert(numel(time)>=2 && time(1)==0 && size(inputs,1)==numel(time) && ...
    all(isfinite(inputs),'all'),'THERMA:C3Inputs','Invalid component test time/input matrix.');
if nargin<5, outputParent=fullfile(tempdir,'THERMA_C3_component_tests'); end
[model,~,signals]=build_c3_component(kind,P,outputParent);
cleanup=onCleanup(@() close_system(model,0));
switch char(kind)
    case 'thermostat'
        names={'Setpoint_K','Air_K','Enable'};
        assert(all(inputs(:,1:2)>0,'all') && all(ismember(inputs(:,3),[0 1])), ...
            'THERMA:C3Inputs','Positive Kelvin and binary enable required.');
    case 'valve', names={'Demand'};
    case 'radiator'
        names={'Valve','Supply_K','Air_K'};
        assert(all(inputs(:,2:3)>0,'all'),'THERMA:C3Inputs','Positive Kelvin required.');
end
assert(size(inputs,2)==numel(names),'THERMA:C3Inputs','Wrong input column count.');
data=Simulink.SimulationData.Dataset;
for j=1:numel(names)
    series=timeseries(inputs(:,j),time); series=setinterpmethod(series,'zoh');
    data=data.addElement(series,names{j});
end
simulation=Simulink.SimulationInput(model);
simulation=simulation.setExternalInput(data);
simulation=simulation.setModelParameter('StopTime',num2str(time(end),17));
output=sim(simulation);
logged=output.get('c3_signals'); time=logged.Time(:); values=reshape(logged.Data,numel(time),[]);
assert(size(values,2)==numel(signals) && all(isfinite(values),'all'), ...
    'THERMA:C3Output','Unexpected/nonfinite component output.');
end
