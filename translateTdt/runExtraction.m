function [Task, TaskInfos] = runExtraction(sessionDir,saveBaseDir,eventDefFile,infosDefFile)
%RUNEXTRACTION Summary of this function goes here
%   Detailed explanation goes here

    saveOutput = 1;

    
    [Task, TaskInfos, EventCodec, InfosCodec, SessionInfos] = tdtExtractBehavior(sessionDir,eventDefFile,infosDefFile);

    % Save translated mat file if needed
    if saveOutput
        sessionName = regexp(sessionDir,'[-\w]+$','match');
        sessionName = sessionName{1};
        saveFile = fullfile(saveBaseDir,sessionName,[sessionName '.mat']);
        
        [oDir,~] = fileparts(saveFile);
        if ~exist(oDir,'dir')
            mkdir(oDir);
        end
        fprintf('Saving to file %s\n',saveFile);
        save(saveFile,'Task','TaskInfos','EventCodec', 'InfosCodec', 'SessionInfos');
    end
end