function [trialEvents, trialInfos, evCodec, infosCodec, tdtInfos ] = tdtExtractEvents(sessionDir, eventCodecFile, infosCodecFile)
%TDTEXTRACTEVENTS Extract Event data from TDT session
%
%   sessionDir: Location where TDT data files are saved
%   eventCodecFile : File that contains the event code definitions.  This
%                    can be one of the following files:
%                    (1) EVENTDEF.pro file used to acquire data (preferred) OR
%                    (2) [not tested] TEMPO_XXXX_rigDDD.m file used for translation
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
%    evDefFile = 'data/Joule/TEMPO/currentProcLib/EVENTDEF.pro'; %...TEMPO_EV_SEAS_rig029.m
%    infosDefFile = 'data/Joule/TEMPO/currentProcLib/CMD/INFOS.pro';
%
%    [trialEvents, trialInfos, evCodec, infosCodec, tdtInfos] = ...
%            tdtExtractEvents(sessDir, evDefFile, infosDefFile);
%
%    [trialEvents, trialInfos, evCodec, infosCodec, tdtInfos ] = ...
%            tdtExtractEvents(sessDir, evDefFile, infosDefFile);
%
%    [trialEvents, trialInfos, evCodec, infosCodec, tdtInfos ] = ...
%            tdtExtractEvents(sessDir, evDefFile, infosDefFile);

    useTaskEndCode = false;
    % Offset for Info Code values
    infosOffestValue = 3000;
        
    % Since multiple rewards may be given use a separate table output
    %juiceStartCode = decodeEvent('JuiceStart_');
    %juiceEndCode = decodeEvent('JuiceEnd_');
    % use in separate table..
    % ignoreDuplicateEvents = [juiceStartCode juiceEndCode];% manual juice...
    ignoreDuplicateEvents = [2777 2776];% manual juice...
    
    % Normalize input path and extract sessionName
    blockPath = regexprep(sessionDir,'[/\\]',filesep);
      
    %%  Process Rig specific event codes and event names   %
    [evCodec.code2Name, evCodec.name2Code] = ...
        getCodeDefs(regexprep(eventCodecFile,'[/\\]',filesep));
    
  %%  Process Infos specific codes  %%
  %   Infos specific names are indexed by their order of occurrance in the
  %   INFOS.pro file (see INFOS.pro file for details)
  infosCodec = struct();
  if ~isempty(infosCodecFile)
    [infosCodec.code2Name, infosCodec.name2Code] = ...
        getCodeDefs(regexprep(infosCodecFile,'[/\\]',filesep));
  end    
    hasInfosCodec =  isfield(infosCodec, 'code2Name');
    %%  Read TDT events and event times   %%
    [tdtEvents, tdtEventTimes, tdtInfos] = getTdtEvents(blockPath);
    % TDT events have '0' for code due to the way the TEMPO ring buffer is
    % written to TDT. We do not send negative codes. 
    % Remove all eventCodes that are '0' or less and corresponding event
    % times from the raw data
    removeLtEq0 = true;
    if removeLtEq0
        tdtEventTimes(tdtEvents <= 0) = [];
        tdtEvents(tdtEvents <= 0) = [];
    end
    % why should we do this? We are not sending negatives
    % if any(tdtEvents > 2^15)
    %   tdtEvents = tdtEvents-2^15;
    % end
    %%  TODO: Process TDT events and infoCodes into trials  %%
    decodeEvent = @(x)  evCodec.name2Code(x);
    taskStartCodes = (1501:1510)';
    
    % codes
    trialStartCode = decodeEvent('TrialStart_');
    eotCode = decodeEvent('Eot_');
    startInfosCode = decodeEvent('StartInfos_');
    endInfosCode = decodeEvent('EndInfos_');
    
    % Now check for valid TASK blocks
    nEvents = numel(tdtEvents);
    iTaskStart =  find(ismember(tdtEvents,taskStartCodes));
    if useTaskEndCode    
        iTaskEnd = find(ismember(tdtEvents,decodeEvent('TaskEnd_'))); %#ok<UNRCH>
    else
        iTaskEnd = [iTaskStart(2:end)-1;nEvents];
    end
    % Split event codes and times into task chunks
    [evCodes, evTimes]=arrayfun(@(i) deal(...
        tdtEvents(iTaskStart(i):iTaskEnd(i)),...
        tdtEventTimes(iTaskStart(i):iTaskEnd(i))),...% convert to ms
        (1:length(iTaskStart))','UniformOutput',false);
    nTasks = size(evCodes,1);
    %% Create table for all Event Codes and set column name as Event_Name
    colNames = evCodec.name2Code.keys';
    colCodes = cell2mat(evCodec.name2Code.values'); 
    colNames = [colNames;'TaskBlock';'TaskType_';'GoodTrial';'HasInfosCodes';'HasTrialStartAndEot';'HasStartInfosAndEndInfos'];
    % Initialize trialEventsTbl to [number of task_rows x event_names]
    trialEventsTbl = array2table(nan(nTasks,numel(colNames)));
    trialEventsTbl.DuplicateEventCodes = cell(nTasks,1);
    trialEventsTbl.DuplicateEventCodesCounts = cell(nTasks,1);
    trialEventsTbl.DuplicateEventCodesTimes = cell(nTasks,1);
    trialEventsTbl.UniqueEventCodes = cell(nTasks,1);
    trialEventsTbl.UniqueEventCodesCounts = cell(nTasks,1);
    trialEventsTbl.Properties.VariableNames(1:end-5) = colNames;
    
    %% Create a trial PDTrigger matrix to process PDtrigger_s if collected
    maxPDTriggers = 10;
    trialPDTriggerMat = nan(nTasks,maxPDTriggers);
       
    %% Create table for all Infos and set column name as Info_Name
    trialInfos = struct();
    if hasInfosCodec
    infoNames = infosCodec.code2Name.values';
    startInfosOffset = infosOffestValue;
    end
    
    warning('OFF','MATLAB:table:RowsAddedExistingVars');
tic
    for t = 1:nTasks
        allC = evCodes{t};
        allT = evTimes{t};
        evCodesTemp = allC(allC < infosOffestValue);
        tmsTemp = allT(allC < infosOffestValue);
        % Process PDTrigger_ event code is present. Since there will be
        % multiple of these, need to do it before finding uniq codes
        if evCodec.name2Code.isKey('PDTrigger_')
            pdTrigIdx = find(evCodesTemp==evCodec.name2Code('PDTrigger_'));
            if ~isempty(pdTrigIdx)
                trialPDTriggerMat(t,1:numel(pdTrigIdx)) = tmsTemp(pdTrigIdx);
                if numel(pdTrigIdx) > 1
                    % remove all PDTrigger_ codes except the first
                    evCodesTemp(pdTrigIdx(2:end)) = [];
                    % remove all times for PDTrigger_ except the first
                    tmsTemp(pdTrigIdx(2:end)) = [];
                end
            end
        end % if eventcodes has code for PDTrigger_
        % check unique Event codes
        [evs,iUniq] = unique(evCodesTemp,'stable');
        tms = tmsTemp(iUniq);
        % default some vars to be present
        trialEventsTbl.TaskBlock(t) = t;

        trialEventsTbl.HasInfosCodes(t) = 1;
        trialEventsTbl.HasTrialStartAndEot(t) = ismember(trialStartCode, evs) && ismember(eotCode, evs);
        trialEventsTbl.HasStartInfosAndEndInfos(t) = ismember(startInfosCode, evs) && ismember(endInfosCode, evs);
        trialEventsTbl.GoodTrial(t) = trialEventsTbl.HasTrialStartAndEot(t) && trialEventsTbl.HasStartInfosAndEndInfos(t);
        % Housekeeping
        [evGt0Counts,evsGt0] = hist(evs(evs>0),unique(evs(evs>0)));
        trialEventsTbl.UniqueEventCodes(t) = {evsGt0'}; 
        trialEventsTbl.UniqueEventCodesCounts(t) = {evGt0Counts'};       
        
        if numel(evs) ~= sum(evCodesTemp < infosOffestValue)
            % In case we want to count zeros, using hist (as histc 
            % does not count zeros) by incrementing all codes by 1
            [dupsCount,uniqDups]= hist(evCodesTemp+1,unique(evs+1));
            uniqDups = uniqDups(dupsCount > 1) - 1;
            dupsCount = dupsCount(dupsCount > 1);
            uniqDups = uniqDups(:)';
            warning('Task block %d has duplicate event codes {%s}, counts{%s}\n',...
                t,num2str(uniqDups,'[%d], '),num2str(dupsCount,'[%d] '));
            trialEventsTbl.DuplicateEventCodes(t) = {uniqDups'}; 
            trialEventsTbl.DuplicateEventCodesCounts(t) = {dupsCount'}; 
            trialEventsTbl.DuplicateEventCodesTimes(t) = {arrayfun(@(x) tmsTemp(evCodesTemp==x),uniqDups(:),'UniformOutput',false)}; 
            
            
            if setdiff(unique(uniqDups),ignoreDuplicateEvents)
               trialEventsTbl.GoodTrial(t) = 0;
            end
        end
        if hasInfosCodec
            if ~sum(allC >= 3000)
                warning('Task block %d has NO INFO codes\n',t);
                trialEventsTbl.HasInfosCodes(t) = 0;
                trialEventsTbl.GoodTrial(t) = 0;
            end
        end
        if intersect(taskStartCodes, evs)
            trialEventsTbl.TaskType_(t) = intersect(taskStartCodes, evs);
        end
        % Events: Get indices to column names for codes
        iTblCols = arrayfun(@(x) min([find(colCodes==x,1),NaN]),evs);
        trialEventsTbl(t,iTblCols(~isnan(iTblCols))) = array2table(tms(~isnan(iTblCols))');
        % Process Infos for the task/trial
        if hasInfosCodec
            % for infoes always use code2name as info codes may be duplicated
            % in INFOS.pro (see tone_duration, trial_length)
            if ismember(startInfosCode, evs) && ismember(endInfosCode, evs)
                infos = allC(find(allC==startInfosCode)+1:find(allC==endInfosCode)-1);
                fprintf('Number of infos codes including start and end infos = %d of total: %d InfoCodec Codes\n',...
                    numel(infos),numel(infosCodec.code2Name.keys));
                % InfoCode annot be less than startInfosOffset
                trialInfos.numberOfInfoCodeValuesLowerThanOffset(t,1) = 0;
                if find(infos < startInfosOffset) % Negative value for info codes??
                    trialInfos.numberOfInfoCodeValuesLowerThanOffset(t,1) = sum(infos < startInfosOffset);
                    warning('****Removing %d InfoCodes that are SMALLER startInfosOffset of %d, before parsing InfoCodes into fields***\n',...
                        sum(infos < startInfosOffset),startInfosOffset);
                    infos = infos(infos>=startInfosOffset);
                end
                % Parse infos into fields
                for kk = 1:numel(infos)
                    try
                        trialInfos.(infoNames{kk})(t,1) = infos(kk) - startInfosOffset;
                    catch me
                        warning(me.message);
                        fprintf('No. of Infos %d of total %d\n',numel(infos),numel(infosCodec.code2Name.keys));
                    end
                end
                
            end
        end

        
    end
   toc 
   % Prune trialPDTriggerMat
   trialPDTriggerMat(:,all(ismissing(trialPDTriggerMat))) = [];
   % prune all NaN
   trialEventsTbl = trialEventsTbl(:,any(~ismissing(trialEventsTbl)));
   % Add pdTrigger to table
   trialEventsTbl.PDTriggersAll = trialPDTriggerMat;
   trialEvents = table2struct(trialEventsTbl,'ToScalar',true);
   
    %%  TODO: Read TDT Eye data including times   %%
    % Read Eye_X stream, and Eye_Y Stream from TDT
    % assume STORE names are 'EyeX', 'EyeY'
%     [tdtEyeX, tdtEyeY, tdtEyeFs] = getTdtEyeData(blockPath);
%     tdtTime = (0:numel(tdtEyeX)-1).*(1000/tdtEyeFs);

    
    %% TODO: Process TDT eye data into trials %%

    %% TODO: Save processed data into file/files %%
    
    %%  TOTO: Done ....ready for cleanup...   %%
    
    %% TODO: Timeit and optimize??.. %%
    
end


%% Sub-functions %%


function [tdtEvents, tdtEventTimes, tdtInfos] = getTdtEvents(blockPath)
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
    % Always return rows
    tdtEvents = tdtEvents(:);
    tdtEventTimes = tdtEventTimes(:);
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

