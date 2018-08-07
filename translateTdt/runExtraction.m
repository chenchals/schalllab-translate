function [Task, taskInfos] = runExtraction(sessionDir,saveFile,eventDefFile,infosDefFile)
%RUNEXTRACTION Summary of this function goes here
%   Detailed explanation goes here

    saveOutput = 1;
    
    [eventTable, taskInfos] = tdtExtractBehavior(sessionDir,'junk',eventDefFile,infosDefFile);
    % prune all NaN
     eventTable = eventTable(:,any(~ismissing(eventTable)));
     Task = table2struct(eventTable,'ToScalar',true);

    % Save translated mat file if needed
    if saveOutput
        [oDir,~] = fileparts(saveFile);
        if ~exist(oDir,'dir')
            mkdir(oDir);
        end
        fprintf('Saving to file %s\n',fullfile(saveFile));
        save(saveFile,'Task','taskInfos');
    end
end