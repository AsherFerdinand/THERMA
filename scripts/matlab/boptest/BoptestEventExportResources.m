classdef BoptestEventExportResources < handle
    %BOPTESTEVENTEXPORTRESOURCES Independent, idempotent event-export cleanup state.
    % No reference to the exporter's workspace or to any verified final file.
    properties
        FileId = -1
        StagingFile = ''
        TemporaryFile = ''
        RemoveStaging = false
    end
    methods
        function status = closeFile(obj)
            fileId=obj.FileId;
            obj.FileId=-1; % Disarm before closing: a later callback cannot close a reused ID.
            status=0;
            if fileId>=0, status=fclose(fileId); end
        end
        function removeTemporary(obj)
            file=obj.TemporaryFile; obj.TemporaryFile='';
            try
                if ~isempty(file) && isfile(file), delete(file); end
            catch
                % Cleanup probes/deletes must never replace the primary export error.
            end
        end
        function cleanup(obj)
            try, obj.closeFile(); catch, end
            obj.removeTemporary();
            if obj.RemoveStaging
                file=obj.StagingFile; obj.StagingFile='';
                try
                    if ~isempty(file) && isfile(file), delete(file); end
                catch
                    % A retained staging file is safer than a cleanup exception.
                end
            end
        end
    end
end
