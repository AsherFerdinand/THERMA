function add_c3_valve(parent)
%ADD_C3_VALVE Bounded first-order opening with asymmetric positive time constants.
add_block('simulink/Ports & Subsystems/Subsystem',parent); Simulink.SubSystem.deleteContents(parent);
b=@(name,lib,pos,varargin) c3_block(parent,name,lib,pos,varargin{:});
b('Demand','Sources/In1',[20 70 50 90]);
b('Limit_demand','Discontinuities/Saturation',[90 60 155 100],'LowerLimit','0','UpperLimit','1');
b('Demand_minus_opening','Math Operations/Sum',[195 65 225 105],'Inputs','+-');
b('Opening','Continuous/Integrator',[530 65 580 105],'InitialCondition','C3.valve_initial', ...
    'LimitOutput','on','LowerSaturationLimit','0','UpperSaturationLimit','1');
b('Zero_rate','Sources/Constant',[195 10 235 35],'Value','0');
b('Opening_direction','Logic and Bit Operations/Relational Operator',[275 10 320 45],'Operator','>=');
b('Opening_tau_s','Sources/Constant',[270 145 350 175],'Value','C3.opening_tau_s');
b('Closing_tau_s','Sources/Constant',[270 220 350 250],'Value','C3.closing_tau_s');
b('Select_tau_s','Signal Routing/Switch',[385 140 440 200], ...
    'Criteria','u2 >= Threshold','Threshold','0.5');
b('Rate_per_s','Math Operations/Product',[460 65 500 105],'Inputs','*/');
b('Valve_opening','Sinks/Out1',[635 75 665 95]);
w=@(a,z) add_line(parent,a,z,'autorouting','on');
w('Demand/1','Limit_demand/1'); w('Limit_demand/1','Demand_minus_opening/1');
w('Opening/1','Demand_minus_opening/2'); w('Demand_minus_opening/1','Opening_direction/1');
w('Zero_rate/1','Opening_direction/2');
w('Opening_direction/1','Select_tau_s/2'); w('Opening_tau_s/1','Select_tau_s/1');
w('Closing_tau_s/1','Select_tau_s/3'); w('Demand_minus_opening/1','Rate_per_s/1');
w('Select_tau_s/1','Rate_per_s/2'); w('Rate_per_s/1','Opening/1'); w('Opening/1','Valve_opening/1');
end
