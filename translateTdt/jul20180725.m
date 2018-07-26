%Dirs
jDatedSessions=dir('/Volumes/schalllab/data/Joule/tdtData/troubleshootEventCodes/Joule-180726-13*');

saveOutput = 1;
saveDir = '/Volumes/schalllab/data/Joule/tdtData/troubleshootEventCodes/processed';

%blocks
blockPaths=strcat({jDatedSessions.folder}',filesep,{jDatedSessions.name}');

eventDefFile = '/Volumes/schalllab/data/Joule/TEMPO/currProcLib/EVENTDEF.pro';
infosDefFile = '/Volumes/schalllab/data/Joule/TEMPO/currProcLib/CMD/INFOS.pro';

for ii = 1:numel(blockPaths)
    verifyEventCodes(blockPaths{ii},eventDefFile);
end

outTrials = struct();
outInfos = struct();
for ii = 1:numel(blockPaths)
    [~,sessionName] = fileparts(blockPaths{ii});
    [eventTable, taskInfos] = tdtExtractBehavior(blockPaths{ii},'junk',eventDefFile,infosDefFile);
    % Save translated mat file if needed
    if saveOutput
        oDir = fullfile(saveDir,sessionName);
        if ~exist(oDir,'dir')
            mkdir(oDir);
        end
        % prune all NaN
        eventTable = eventTable(:,any(~ismissing(eventTable)));
        Task = table2struct(eventTable,'ToScalar',true);
        fprintf('Saving to file %s\n',fullfile(oDir,'Behav.mat'));
        save(fullfile(oDir,'Behav.mat'),'-struct','Task');
        save(fullfile(oDir,'Behav.mat'),'-append','taskInfos');
    end
    outTrials.(regexprep(sessionName,'-','_')) = eventTable;
    outInfos.(regexprep(sessionName,'-','_')) = taskInfos;

end


