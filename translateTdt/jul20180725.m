
% Base dir for data
%baseDir = '/Volumes/schalllab/data/Joule/tdtData/troubleshootEventCodes';
baseDir = 'data/Joule/tdtData/troubleshootEventCodes';
%saveDir = fullfile(baseDir,'processed');
saveDir = 'dataProcessed/data/Joule/tdtData/troubleshootEventCodes';
eventDefFile = 'data/Joule/TEMPO/currProcLib_15/EVENTDEF.pro';
infosDefFile = 'data/Joule/TEMPO/currProcLib_15/CMD/INFOS.pro';


%Dirs
jDatedSessions=dir(fullfile(baseDir,'Joule-180806-1344*'));

saveOutput = 1;

%blocks
blockPaths=strcat({jDatedSessions.folder}',filesep,{jDatedSessions.name}');


for ii = 1:numel(blockPaths)
    verifyEventCodes(blockPaths{ii},eventDefFile);
end

outTrials = struct();
outInfos = struct();
for ii = 1:numel(blockPaths)
    [~,sessionName] = fileparts(blockPaths{ii});
    [eventTable, taskInfos] = tdtExtractBehavior(blockPaths{ii},'junk',eventDefFile,infosDefFile);
    % prune all NaN
     eventTable = eventTable(:,any(~ismissing(eventTable)));
     Task = table2struct(eventTable,'ToScalar',true);

    % Save translated mat file if needed
    if saveOutput
        oDir = fullfile(saveDir,sessionName);
        if ~exist(oDir,'dir')
            mkdir(oDir);
        end
        fprintf('Saving to file %s\n',fullfile(oDir,'Behav.mat'));
        save(fullfile(oDir,'Behav.mat'),'Task');
        save(fullfile(oDir,'Behav.mat'),'-append','taskInfos');
    end
    outTrials.(regexprep(sessionName,'-','_')) = eventTable;
    outInfos.(regexprep(sessionName,'-','_')) = taskInfos;

end


