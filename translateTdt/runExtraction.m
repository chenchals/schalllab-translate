function [Task, TaskInfos, TrialEyes, EventCodec, InfosCodec, SessionInfos] = runExtraction(sessionDir,saveBaseDir,eventDefFile,infosDefFile, edfOptions, varargin)
%RUNEXTRACTION Summary of this function goes here
%   Detailed explanation goes here

    saveOutput = 1;
    useSessionNamePrefix = 1;
    if numel(varargin) == 1
        useSessionNamePrefix = varargin{1};
    end
        
    sessionName = regexp(sessionDir,'[-\w]+$','match');
    sessionName = sessionName{1};    
    
    if useSessionNamePrefix
        saveFilePrefix = [sessionName '_'];
    else
        saveFilePrefix = '';
    end
    
    [Task, TaskInfos, EventCodec, InfosCodec, SessionInfos] = tdtExtractEvents(sessionDir,eventDefFile,infosDefFile);

    % Save translated mat file if needed
    if saveOutput
        saveFile = fullfile(saveBaseDir,sessionName,[saveFilePrefix 'Events.mat']);
        [oDir,~] = fileparts(saveFile);
        if ~exist(oDir,'dir')
            mkdir(oDir);
        end
        fprintf('Saving Event data to file %s\n',saveFile);
        save(saveFile,'Task','TaskInfos','EventCodec', 'InfosCodec', 'SessionInfos');
    end
    fprintf('Extracting Eye data...\n');
    [TrialEyes] = tdtExtractEyes(sessionDir, Task.TrialStart_, edfOptions); 
    if saveOutput
        saveFile = fullfile(saveBaseDir,sessionName,[saveFilePrefix 'Eyes.mat']);
        [oDir,~] = fileparts(saveFile);
        if ~exist(oDir,'dir')
            mkdir(oDir);
        end
        fprintf('Saving Eye data to file %s\n',saveFile);
        save(saveFile, '-struct', 'TrialEyes');
    end
    

end