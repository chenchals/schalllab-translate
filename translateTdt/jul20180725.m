%Dirs
j20180725=dir('/Volumes/schalllab/data/Joule/tdtData/troubleshootEventCodes/Joule-180725-15*');

saveOutput = 1;
saveDir = '/Volumes/schalllab/data/Joule/tdtData/troubleshootEventCodes/processed';

%blocks
blockPaths=strcat({j20180725.folder}',filesep,{j20180725.name}');

eventDefFile = '/Volumes/schalllab/data/Joule/TEMPO/currentProcLib/EVENTDEF.pro';
infosDefFile = '/Volumes/schalllab/data/Joule/TEMPO/currentProcLib/CMD/INFOS.pro';

for ii = 1:numel(blockPaths)
    verifyEventCodes(blockPaths{ii},eventDefFile);
end

out = struct();
for ii = 1:numel(blockPaths)
    [~,sessionName] = fileparts(blockPaths{ii});
    eventTable = tdtExtractBehavior(blockPaths{ii},'junk',eventDefFile,infosDefFile);
    out.(regexprep(sessionName,'-','_')) = eventTable;
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
    end
end


