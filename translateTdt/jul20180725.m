
% Base dir for data
%baseDir = '/Volumes/schalllab/data/Joule/tdtData/troubleshootEventCodes';
baseDir = '/Volumes/SchallLab/data/Joule/tdtData/troubleshootEventCodes';
%saveDir = fullfile(baseDir,'processed');
saveDir = '/Volumes/SchallLab/data/Joule/tdtData/troubleshootEventCodes/processed';
eventDefFile = '/Volumes/SchallLab/data/Joule/TEMPO/currProcLib_24/EVENTDEF.pro';
infosDefFile = '/Volumes/SchallLab/data/Joule/TEMPO/currProcLib_24/CMD/INFOS.pro';

%Dirs
jDatedSessions=dir(fullfile(baseDir,'Joule-180809-1546*'));

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
        outputFilename = ['SEF_Cmand_' jDatedSessions.name '.mat'];
        fprintf('Saving to file %s\n',fullfile(oDir,outputFilename));
        save(fullfile(oDir,outputFilename),'Task');
        save(fullfile(oDir,outputFilename),'-append','taskInfos');
    end
    outTrials.(regexprep(sessionName,'-','_')) = eventTable;
    outInfos.(regexprep(sessionName,'-','_')) = taskInfos;

end


