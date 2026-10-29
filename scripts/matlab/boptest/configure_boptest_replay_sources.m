function [input,diagnostics] = configure_boptest_replay_sources(model,metadata,data)
%CONFIGURE_BOPTEST_REPLAY_SOURCES Explicit R2025a timeseries/workspace driver setup.
% Caller owns an existing 11-input Mux named Inputs; physical model is untouched.
assert(size(data,2)==12 && size(data,1)>=2 && all(isfinite(data),'all') && ...
    all(diff(data(:,1))>=0) && data(1,1)==0, ...
    'THERMA:ReplayDriverData','Expected finite nondecreasing [time,11 channels] from zero.');
workspace = get_param(model,'ModelWorkspace');
input = Simulink.SimulationInput(model);
[time,index] = unique(data(:,1),'last');
diagnostics = cell(1,11);
for channel = 1:11
    variable = sprintf('Replay_input_%02d',channel);
    name = sprintf('Replay_Source_%02d',channel);
    if iscell(metadata.channels), channelInfo = metadata.channels{channel};
    else, channelInfo = metadata.channels(channel); end
    values = data(index,channel+1);
    policy = string(channelInfo.interpolation);
    assert(ismember(policy,["linear","previous"]),'THERMA:ReplayDriverPolicy', ...
        'Unsupported interpolation for channel %d.',channel);
    if policy=="linear"
        changes = diff(data(:,channel+1)); repeated = diff(data(:,1))==0;
        assert(all(changes(repeated)==0),'THERMA:ReplayJump', ...
            'Continuous channel has duplicate-time jump; do not smooth it.');
        interpolate = 'on'; method = 'linear';
    else
        interpolate = 'off'; method = 'zoh';
    end
    % Explicit timeseries avoids ambiguity between a time column and signal
    % dimensions. Persist in the model AND bind the same object to SimulationInput.
    signal = timeseries(values,time,'Name',variable);
    signal = setinterpmethod(signal,method);
    assignin(workspace,variable,signal);
    input = input.setVariable(variable,signal,'Workspace',model);
    add_block('simulink/Sources/From Workspace',[model '/' name], ...
        'VariableName',variable,'Interpolate',interpolate,'SampleTime','0', ...
        'ZeroCross','on','Position',[20 channel*60 230 channel*60+35]);
    add_line(model,[name '/1'],sprintf('Inputs/%d',channel));
    diagnostics{channel} = struct('block',name,'variable',variable, ...
        'workspace','ModelWorkspace plus SimulationInput Workspace=model', ...
        'data_class',class(signal),'samples',numel(time),'data_size',size(signal.Data), ...
        'first_time_s',time(1),'last_time_s',time(end), ...
        'first_value',values(1),'last_value',values(end), ...
        'interpolation',char(policy),'block_interpolate',interpolate, ...
        'timeseries_method',method,'sample_time','0','zero_crossing','on');
end
end
