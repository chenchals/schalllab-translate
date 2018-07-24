function [oFiles, trialEventTimesTbl, trialUnknownEventTimesTbl, trialCodes, trialTimes, evCodec, infosCodec, tdtEvents,tdtEventTimes, tdtInfos ] = tdtExtractBehavior(sessionDir, outputBaseDir, eventCodecFile, infosCodecFile)
%TDTEXTRACTBEHAVIOR Summary of this function goes here
%   Detailed explanation goes here
%
%   oFiles : Processed filenames (fullpath)
%
%   sessionDir: Location where TDT data files are saved
%   outputDir : Location of procesed base directory, a sub-dir with
%               sessionName will be created here for processed session
%   eventCodecFile : File that contains the event code definitions.  This
%                    can be one of the following files:
%                    (1) EVENTDEF.pro file used to acquire data (preferred) OR
%                    (2) TEMPO_XXXX_rigDDD.m file used for translation
%   infosdCodecFile : The INFOS.pro file that has Names for InfoCodes
%
% Example:
%    sessDir = 'data/Joule/tdtData/Countermanding/Joule-180714-093508';
%    sessDir10 = ...
%    'data/Joule/tdtData/troubleshootEventCodes/Joule-180720-121327'; %//<10
%    sessDir5 = ...
%    'data/Joule/tdtData/troubleshootEventCodes/Joule-180720-120340'; %//<5
%    sessDir2 = ...
%    'data/Joule/tdtData/troubleshootEventCodes/Joule-180720-120804'; %//<2
%    outDir = 'dataProcessed/Joule/Countermanding';
%    evDefFile = 'data/Joule/TEMPO/currentProcLib/EVENTDEF.pro'; %...TEMPO_EV_SEAS_rig029.m
%    infosDefFile = 'data/Joule/TEMPO/currentProcLib/CMD/INFOS.pro';
%
%    [oFiles, trialEventTimesTbl, trialUnknownEventTimesTbl] = ...
%            tdtExtractBehavior(sessDir, outDir, evDefFile, infosDefFile);
%
%    [oFiles, trialEventTimesTbl, trialUnknownEventTimesTbl, trialCodes, trialTimes, evCodec, infosCodec] = ...
%            tdtExtractBehavior(sessDir, outDir, evDefFile, infosDefFile);
%
%    [oFiles, trialEventTimesTbl, trialUnknownEventTimesTbl, trialCodes, trialTimes, tdtEvents,tdtEventTimes, tdtInfos, evCodec, infosCodec] = ...
%            tdtExtractBehavior(sessDir, outDir, evDefFile, infosDefFile);
%
%    [oFiles] = tdtExtractBehavior(sessDir, outDir, evDefFile, infosDefFile);

    % Initialize output files
    oFiles = {};

    useTaskEndCode = false;
    
    
    % Normalize input path and extract sessionName
    blockPath = regexprep(sessionDir,'[/\\]',filesep);
    % sessionName
    sessionName = split(blockPath,filesep);
    sessionName = sessionName{end};
    % Normalize output path and create dir for processed output
    outputDir = fullfile(regexprep(outputBaseDir,'[/\\]',filesep),sessionName);
    if ~exist(outputDir,'dir')
        mkdir(outputDir);
    end
      
    %%  Process Rig specific event codes and event names   %
    [evCodec.code2Name, evCodec.name2Code] = ...
        getCodeDefs(regexprep(eventCodecFile,'[/\\]',filesep));
    
  %%  Process Infos specific codes  %%
  %   Infos specific names are indexed by their order of occurrance in the
  %   INFOS.pro file (see INFOS.pro file for details)
    [infosCodec.code2Name, infosCodec.name2Code] = ...
        getCodeDefs(regexprep(infosCodecFile,'[/\\]',filesep));
    
    %%  Read TDT events and event times   %%
    [tdtEvents, tdtEventTimes, tdtInfos] = getTdtEvents(blockPath);
    % TDT events have '0' for code due to the way the TEMPO ring buffer is
    % written to TDT. We do not send negative codes. 
    % Remove all eventCodes that are '0' or less and corresponding event
    % times from the raw data
    tdtEventTimes(tdtEvents <= 0) = [];
    tdtEvents(tdtEvents <= 0) = [];
    % why should we do this? We are not sending negatives
    % if any(tdtEvents > 2^15)
    %   tdtEvents = tdtEvents-2^15;
    % end
    %%  TODO: Process TDT events and infoCodes into trials  %%
    decodeEvent = @(x)  evCodec.name2Code(x);
    taskStartCodes = (1501:1510)';
    
    trialStartCode = decodeEvent('TrialStart_');
    eotCode = decodeEvent('Eot_');
    startInfosCode = decodeEvent('StartInfos_');
    endInfosCode = decodeEvent('EndInfos_');
    
    % Now check for valid TASK blocks
    nEvents = numel(tdtEvents);
    iTaskStart =  find(ismember(tdtEvents,taskStartCodes));
    if useTaskEndCode    
        iTaskEnd = find(ismember(tdtEvents,decodeEvent('CmanEnd_'))); %#ok<UNRCH>
    else
        iTaskEnd = [iTaskStart(2:end)-1;nEvents];
    end
    % Split event codes and times into task chunks
    [evCodes, evTimes]=arrayfun(@(i) deal(...
        tdtEvents(iTaskStart(i):iTaskEnd(i)),...
        tdtEventTimes(iTaskStart(i):iTaskEnd(i)).*1000),...% convert to ms
        (1:length(iTaskStart))','UniformOutput',false);
    nTasks = size(evCodes,1);
    colNames = evCodec.name2Code.keys';
    colCodes = cell2mat(evCodec.name2Code.values'); 
    colNames = [colNames;'TaskType_';'GoodTrial';'HasInfosCodes'];
    %trialsTbl = cell2table(cell(0,numel(colNames)));
    trialsTbl = array2table(nan(nTasks,numel(colNames)));
    trialsTbl.DuplicateEventCodes = cell(nTasks,1);
    trialsTbl.Properties.VariableNames(1:end-1) = colNames;
    warning('OFF','MATLAB:table:RowsAddedExistingVars');
    ignoreDuplicateEvents = [2777 2776];% manual juice...
tic
    for t = 1:nTasks
        allC = evCodes{t};
        allT = evTimes{t};
        ilt3000 = find(allC < 3000);
        evCodesTemp = allC(ilt3000);
        tmsTemp = allT(ilt3000);
        % check unique Event codes
        [evs,iUniq] = unique(evCodesTemp,'stable');
        dups = evCodesTemp(setdiff(1:numel(evCodesTemp),iUniq));
        tms = tmsTemp(iUniq);
        iInfos = allC(allC >= 3000);
        trialsTbl.GoodTrial(t) = 1;
        trialsTbl.HasInfoCodes(t) = 1;
        if numel(evs) ~= numel(ilt3000)
            warning('Task block %d has duplicate event codes\n',t);
            trialsTbl.DuplicateEventCodes(t) = {unique(dups)'}; 
            if setdiff(unique(dups),ignoreDuplicateEvents)
               trialsTbl.GoodTrial(t) = 0;
            end
        end
        if isempty(iInfos)
            warning('Task block %d has NO INFO codes\n',t);
            trialsTbl.HasInfoCodes(t) = 0;
            trialsTbl.GoodTrial(t) = 0;
        end
        if intersect(taskStartCodes, evs)
            trialsTbl.TaskType_(t) = intersect(taskStartCodes, evs);
        end

        iTblCols = arrayfun(@(x) min([find(colCodes==x,1),NaN]),evs);
        trialsTbl(t,iTblCols(~isnan(iTblCols))) = num2cell(tms(~isnan(iTblCols))');
    end
   toc 
    
    
    % Add an extra Event at the end to help in arryfun below
    iTrialStartTemp = [find(tdtEvents==trialStartCode);nEvents+1];% all TrialStart_
    iEotTemp = [find(tdtEvents==eotCode);nEvents+1];% all Eot_
    iEndInfosTemp = [find(tdtEvents==endInfosCode);nEvents+1];% all endInfos
    
    % find iTrialStart,iEot,iEndInfos between currTask and nextTask
    % It is possible that more than 1 of the same eventCXode is sent
    % successively, hence take the minimum of such index. If empty, min()
    % fx inside call to arrayfun() will use the nEvents+1 thast is setup
    % above as the index into the tdtEvents, hence lines below change the
    % nEvents+1 to NaN.  
    iTrialStart = iTrialStartTemp(arrayfun(@(i) min([...
        find(iTrialStartTemp>iTaskStart(i) & iTrialStartTemp<iTaskEnd(i),1);...
        numel(iTrialStartTemp)]),...% extra index here
        (1:length(iTaskStart))'));
    
    iEot = iEotTemp(arrayfun(@(i) min([...
        find(iEotTemp>iTaskStart(i) & iEotTemp<iTaskEnd(i),1);...
        numel(iEotTemp)]),...% extra index here
        (1:length(iTaskStart))'));
    
    iEndInfos = iEndInfosTemp(arrayfun(@(i) min([...
        find(iEndInfosTemp>iTaskStart(i) & iEndInfosTemp<iTaskEnd(i),1);...
        numel(iEndInfosTemp)]),...
        (1:length(iTaskStart))'));    
    % Set the extra index to NaN
    iTrialStart(iTrialStart>nEvents) = NaN;
    iEot(iEot>nEvents) = NaN;
    iEndInfos(iEndInfos>nEvents) = NaN;
    % augment thes above indices (into tdtEvs/tdtEvTms).
    % Rows of augment, evCodes evTimes correspond to putative trial numbers
    % 
    augmented = [iTrialStart iEot iEndInfos iTaskStart iTaskEnd];
    % Find indices row indicces of augmented above where iTrialStart, iEot,
    % iEndInfos are NOT NaN for the Row aka complete cases.
    % NOTE: Here we are using only  trials where iEndInfos is NOT NAN 
    % NOTE: Could have used al three indices above...
    if ~useTaskEndCode
        trialsWithEndInfos = find(sum(isnan(augmented(:,3)),2)==0);
        validTrials = trialsWithEndInfos;
    else        
        trialsWithTaskStartAndTaskEnd = find(sum(isnan(augmented(:,4:5)),2)==0);
        validTrials = trialsWithTaskStartAndTaskEnd;
    end
    % prune evCodes and evTimes to valid task chunks
    trialCodes = evCodes(validTrials);
    trialTimes = evTimes(validTrials);
    
    save('myEvCodesEvTimes.mat','trialCodes','trialTimes','evCodec','infosCodec');
    
    %% Convert cell array of trialCodes and trialTimes to trialEventTimesTbl %%
    defTaskCodes = [1501:1510];
    nTrials = numel(trialCodes);
    names = evCodec.name2Code.keys';
    names = ['TaskType_';names];
    trialEventTimesTbl = array2table(nan(nTrials,numel(names)));
    trialEventTimesTbl.Properties.VariableNames = names;
    tic
    % Keep track of unknown codes
    unknownCodes = [];
    unknownCodeCount = 0;
    trialUnknownEventTimesTbl = table();% dynamically add columns when unknown code is encountered
    for trlNo = 1:nTrials
        tCodes = unique(trialCodes{trlNo},'stable'); tCodes(tCodes>=3000)=[];
        for jj = 1:numel(tCodes)
            code = tCodes(jj);
            codeTime = trialTimes{trlNo}(find(trialCodes{trlNo} == code,1,'first'));
            try
                trialEventTimesTbl.(evCodec.code2Name(code))(trlNo) = codeTime;
                if find(defTaskCodes==code)
                    trialEventTimesTbl.TaskType_(trlNo) = code;
                end
            catch me
                %warning('*** Trial# %d --> unknown code %d',trlNo,code);
                unknownCodeCount = unknownCodeCount + 1;
                unknownCodes(unknownCodeCount) = code;
                dynCol = num2str(1,'code_%d');
                if ~any(contains(trialUnknownEventTimesTbl.Properties.VariableNames,dynCol))
                    trialUnknownEventTimesTbl.(dynCol)(trlNo) = codeTime;
                end
                
            end
        end
    end
    
    toc
    
    % Prune columns where values for all rows is NaN
    % Get only columns with at least one non NaN value in the colum
    % 
     %trialEventTimesTbl = trialEventTimesTbl(:,any(~ismissing(trialEventTimesTbl)));
     trialEventTimesTbl(:,all(ismissing(trialEventTimesTbl)))=[];
%     T2 = trialEventTimesTbl;
%     T2(:,all(ismissing(T2)))=[];
    
    %%  TODO: Read TDT Eye data including times   %%
    
    %% TODO: Process TDT eye data into trials %%

    %% TODO: Save processed data into file/files %%
    
    %%  TOTO: Done ....ready for cleanup...   %%
    
    %% TODO: Timeit and optimize??.. %%
    
end

%% Sub-functions %%
function [tdtEvents, tdtEventTimes, tdtInfos] = getTdtEvents(blockPath,varargin)
    % Using functions form TDTSDK for reading raw TDT files
    % 
    tdtFun = @TDTbin2mat;
    % Get raw TDT events codes and event times
    tdtRaw = tdtFun(blockPath,'TYPE',{'epocs','scalars'},'VERBOSE',0); 
    % Use STROBE data when available
    try
        fprintf('*** Trying tdtRaw.epocs.STRB field ***\n')
        tdtEvents = tdtRaw.epocs.STRB.data;
        tdtEventTimes = tdtRaw.epocs.STRB.onset.*1000;
    catch me
        fprintf('*** No tdtRaw.epocs.STRB field ***\n')
        fprintf('%s\n',getReport(me));
        try
            fprintf('*** Trying tdtRaw.scalars.EVNT field ***\n')
            tdtEvents = tdtRaw.scalars.EVNT.data;
            tdtEventTimes = tdtRaw.scalars.EVNT.ts.*1000;
        catch me
            fprintf('*** No tdtRaw.scalars.EVNT field ***\n');
            fprintf('%s\n',getReport(me));
            error('Exiting...See above messages');
        end
    end    
    fprintf('Successfully read TDT event data\n');
        % Info about the files etc
    %  info is struct with fields:
    % Example:
    %    tankpath: 'translateTdt/data/Joule/tdtData/Countermanding'
    %    blockname: 'Joule-180714-093508'
    %         date: '2018-Jul-14'
    % utcStartTime: '14:35:11'
    %  utcStopTime: '16:08:12'
    %     duration: '01:33:01'
    %streamChannel: 0
    %  snipChannel: 0
    tdtInfos = tdtRaw.info;
    % claim space
    clear tdtRaw

end


