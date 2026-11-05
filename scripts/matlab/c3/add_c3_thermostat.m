function add_c3_thermostat(parent)
%ADD_C3_THERMOSTAT Sampled inclusive hysteresis with explicit retained state.
add_block('simulink/Ports & Subsystems/Subsystem',parent); Simulink.SubSystem.deleteContents(parent);
b=@(name,lib,pos,varargin) c3_block(parent,name,lib,pos,varargin{:});
b('Setpoint_K','Sources/In1',[20 30 50 50],'Port','1');
b('Air_K','Sources/In1',[20 100 50 120],'Port','2');
b('Enable','Sources/In1',[20 260 50 280],'Port','3');
b('Sample_setpoint','Discrete/Zero-Order Hold',[85 25 150 55],'SampleTime','C3.controller_period_s');
b('Sample_air','Discrete/Zero-Order Hold',[85 95 150 125],'SampleTime','C3.controller_period_s');
b('Sample_enable','Discrete/Zero-Order Hold',[85 255 150 285],'SampleTime','C3.controller_period_s');
b('Cold_error_K','Math Operations/Sum',[185 50 215 100],'Inputs','+-');
b('Half_band_K','Sources/Constant',[180 140 250 170],'Value','C3.deadband_K/2');
b('Negative_half_band_K','Sources/Constant',[180 195 250 225],'Value','-C3.deadband_K/2');
b('Cold','Logic and Bit Operations/Relational Operator',[290 45 330 85],'Operator','>=');
b('Hot','Logic and Bit Operations/Relational Operator',[290 130 330 170],'Operator','<=');
b('Off','Sources/Constant',[360 220 395 240],'Value','0');
b('On','Sources/Constant',[445 15 480 35],'Value','1');
b('Previous_demand','Discrete/Unit Delay',[550 250 625 285], ...
    'InitialCondition','C3.controller_initial','SampleTime','C3.controller_period_s');
b('Retain_or_off','Signal Routing/Switch',[415 110 465 170], ...
    'Criteria','u2 >= Threshold','Threshold','0.5');
b('Cold_on','Signal Routing/Switch',[510 50 560 110], ...
    'Criteria','u2 >= Threshold','Threshold','0.5');
b('Enabled_demand','Math Operations/Product',[610 75 650 115],'Inputs','**');
b('Demand','Sinks/Out1',[715 80 745 100]);
w=@(a,z) add_line(parent,a,z,'autorouting','on');
w('Setpoint_K/1','Sample_setpoint/1'); w('Air_K/1','Sample_air/1');
w('Enable/1','Sample_enable/1'); w('Sample_setpoint/1','Cold_error_K/1');
w('Sample_air/1','Cold_error_K/2'); w('Cold_error_K/1','Cold/1');
w('Half_band_K/1','Cold/2'); w('Cold_error_K/1','Hot/1'); w('Negative_half_band_K/1','Hot/2');
w('Off/1','Retain_or_off/1'); w('Hot/1','Retain_or_off/2');
w('Previous_demand/1','Retain_or_off/3'); w('On/1','Cold_on/1');
w('Cold/1','Cold_on/2'); w('Retain_or_off/1','Cold_on/3');
w('Cold_on/1','Enabled_demand/1'); w('Sample_enable/1','Enabled_demand/2');
w('Enabled_demand/1','Previous_demand/1'); w('Enabled_demand/1','Demand/1');
end
