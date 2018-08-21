function [Task, TaskInfos] = runExtraction(sessionDir,saveFile,eventDefFile,infosDefFile)
%RUNEXTRACTION Summary of this function goes here
%   Detailed explanation goes here

    saveOutput = 1;
    
    [Task, TaskInfos, EventCodec, InfosCodec, SessionInfos] = tdtExtractBehavior(sessionDir,eventDefFile,infosDefFile);

    % Save translated mat file if needed
    if saveOutput
        [oDir,~] = fileparts(saveFile);
        if ~exist(oDir,'dir')
            mkdir(oDir);
        end
        fprintf('Saving to file %s\n',fullfile(saveFile));
        save(saveFile,'Task','TaskInfos','EventCodec', 'InfosCodec', 'SessionInfos');
    end
end