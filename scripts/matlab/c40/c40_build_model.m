function [model,file,info]=c40_build_model(folder,Z,P,room,baseline)
%C40_BUILD_MODEL Presentation-only copy of verified C3.7, not new thermal physics.
model='THERMA_C40_HeatingSystem'; file=fullfile(folder,[model '.slx']);
assert(~bdIsLoaded(model),'THERMA:C40Open','Save/close the open C4.0 model before rebuilding.');
% The verified C3.8 copy helper checks workspace/solver identity; deadband stays1K.
[original,temporary,info]=c38_build_case(folder,1,Z,P,room,baseline.source_model,baseline.names);
try
    keep={'Thermal_zone','Thermostat','Valve','Radiator','Setpoint_K','Supply_K','Outdoor_K', ...
        'Enable','Zone_inputs','Internal_convective_W','Internal_radiative_W','Solar_W'};
    blocks=find_system(original,'SearchDepth',1,'Type','Block'); handles=[];
    for k=1:numel(blocks)
        if ~any(strcmp(get_param(blocks{k},'Name'),keep))
            handles(end+1)=get_param(blocks{k},'Handle'); %#ok<AGROW>
        end
    end
    % Automatic grouping preserves every existing diagnostic connection/integrator.
    before=find_system(original,'SearchDepth',1,'BlockType','SubSystem');
    Simulink.BlockDiagram.createSubsystem(handles);
    after=find_system(original,'SearchDepth',1,'BlockType','SubSystem'); added=setdiff(after,before);
    assert(numel(added)==1,'THERMA:C40Layout','Expected one passive results group.');
    set_param(added{1},'Name','Results and checks','ShowPortLabels','none');
    pairs={'Thermal_zone','Building Thermal Zone';'Thermostat','Room Thermostat'; ...
        'Valve','Control Valve';'Radiator','Hydronic Radiator'; ...
        'Setpoint_K','Setpoint 21 C (K)';'Supply_K','Water supply 55 C (K)'; ...
        'Outdoor_K','Outdoor 0 C (K)';'Enable','Heating enabled';'Zone_inputs','Thermal inputs'; ...
        'Internal_convective_W','Internal convection 0 W'; ...
        'Internal_radiative_W','Internal radiation 0 W';'Solar_W','Solar 0 W'};
    for k=1:size(pairs,1), set_param([original '/' pairs{k,1}],'Name',pairs{k,2}); end
    positions={'Room Thermostat',[200 200 360 330];'Control Valve',[430 220 570 300]; ...
        'Hydronic Radiator',[650 190 850 490];'Building Thermal Zone',[1120 190 1340 590]; ...
        'Setpoint 21 C (K)',[30 180 115 210];'Heating enabled',[30 290 115 320]; ...
        'Water supply 55 C (K)',[600 70 730 100];'Outdoor 0 C (K)',[890 100 1020 130]; ...
        'Thermal inputs',[1050 200 1055 570]; ...
        'Internal convection 0 W',[850 560 985 590]; ...
        'Internal radiation 0 W',[850 630 985 660];'Solar 0 W',[850 700 985 730]; ...
        'Results and checks',[1450 650 1680 1060]};
    for k=1:size(positions,1), set_param([original '/' positions{k,1}],'Position',positions{k,2},'FontSize','12'); end
    Simulink.BlockDiagram.arrangeSystem([original '/Results and checks']);
    labels={'Room Thermostat',1,'Thermostat demand';'Control Valve',1,'Valve opening (0 to 1)'; ...
        'Hydronic Radiator',2,'Convective heat (W)';'Hydronic Radiator',3,'Radiative heat (W)'; ...
        'Hydronic Radiator',4,'Delivered heating (W)';'Hydronic Radiator',5,'Water mass flow (kg/s)'; ...
        'Hydronic Radiator',1,'Radiator temperature (K)';'Building Thermal Zone',1,'Indoor air feedback (K)'; ...
        'Outdoor 0 C (K)',1,'Outdoor temperature (K)';'Water supply 55 C (K)',1,'Water supply (K)'};
    for k=1:size(labels,1)
        ports=get_param([original '/' labels{k,1}],'PortHandles');
        line=get_param(ports.Outport(labels{k,2}),'Line'); set_param(line,'Name',labels{k,3});
    end
    % Assert that all main heating/control connections still have the original sources.
    links={'Building Thermal Zone',1,'Room Thermostat',2;'Room Thermostat',1,'Control Valve',1; ...
        'Control Valve',1,'Hydronic Radiator',1;'Water supply 55 C (K)',1,'Hydronic Radiator',2; ...
        'Building Thermal Zone',1,'Hydronic Radiator',3;'Hydronic Radiator',2,'Thermal inputs',2; ...
        'Hydronic Radiator',3,'Thermal inputs',3;'Outdoor 0 C (K)',1,'Thermal inputs',1; ...
        'Thermal inputs',1,'Building Thermal Zone',1};
    for k=1:size(links,1)
        a=get_param([original '/' links{k,1}],'PortHandles'); b=get_param([original '/' links{k,3}],'PortHandles');
        line=get_param(b.Inport(links{k,4}),'Line');
        assert(sourcePort(line)==a.Outport(links{k,2}), ...
            'THERMA:C40Wiring','Main physical connection changed.');
    end
    notes=find_system(original,'SearchDepth',1,'FindAll','on','Type','annotation');
    for k=1:numel(notes)
        note=get_param(notes(k),'Object');
        note.Text='C4.0 residential workbench: unchanged C3.7 physics; temperature signals K, heat W.';
    end
    info.case_definition.id='C40'; info.case_definition.group='C40';
    save_system(original,file);
    if bdIsLoaded(original), close_system(original,0); end
    if ~bdIsLoaded(model), load_system(file); end
    assert(strcmp(fileparts(temporary),folder),'THERMA:C40Temporary','Unexpected intermediate file.');
    delete(temporary); % Only this run's new intermediate copy, never the original C3.7 model.
catch problem
    if bdIsLoaded(original), close_system(original,0); end
    if bdIsLoaded(model), close_system(model,0); end
    rethrow(problem);
end
end

function port=sourcePort(line)
assert(line~=-1,'THERMA:C40Wiring','Missing connection.');
port=get_param(line,'SrcPortHandle');
while port==-1
    line=get_param(line,'LineParent');
    assert(line~=-1,'THERMA:C40Wiring','Disconnected branch.');
    port=get_param(line,'SrcPortHandle');
end
end
