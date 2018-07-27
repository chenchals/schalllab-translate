%% Photodiode data... %%%%

    sess='data/Joule/tdtData/troubleshootEventCodes/Joule-180726-153819';
    
    rawStream = TDTbin2mat(sess,'TYPE',{'streams'},'VERBOSE',0);
    
    
%     pdRaw = TDTbin2mat(fullfile(rawDir,sessName),'TYPE',{'streams'},'STORE',{'PD__'},'VERBOSE',0);
%     pdStream = pdRaw.streams.PD__.data;
%     % for some reason, pdTime, if turned into milliseconds, gives 0 dt
%     % values which really mess with the saccade detector... I guess all of
%     % this will need to be done post-detection
%     if pdRaw.streams.PD__.fs > 2000
%         load('slowSamplingRate.mat');
%         pdTime = (0:(length(pdStream)-1)).*(1/sampRate);
%     else
%         pdTime = (0:(length(pdStream)-1)).*(1/pdRaw.streams.PD__.fs);
%     end
% 




%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
taskCodes = [1500:1510]';
trialStartCode = 1666;
eotCode = 1667;
endInfosCode = 2999;

tdtEvents=[];
tdtEventTimes=[];



% Now check for trial blocks that are valid...(?)
nEvents = numel(tdtEvents);
iTaskStart =  find(ismember(tdtEvents,taskCodes));% all TaskType find(ismember(tdtEvs,[1501:1503]'));
iTaskEnd = [iTaskStart(2:end);length(tdtEvents)];

% Split event codes and times into task chunks
[evCodes, evTimes]=arrayfun(@(i) deal(...
                   tdtEvents(iTaskStart(i):iTaskEnd(i)),...
                   tdtEventTimes(iTaskStart(i):iTaskEnd(i))),...
                   (1:length(iTaskStart))','UniformOutput',false);

% Add an extra Event at the end to help in arryfun below
iTrialStartTemp = [find(tdtEvents==trialStartCode);nEvents+1];% all TrialStart_
iEotTemp = [find(tdtEvents==eotCode);nEvents+1];% all Eot_
iEndInfosTemp = [find(tdtEvents==endInfosCode);nEvents+1];% all endInfos

% find iTrialStart,iEot,iEndInfos between currTask and nextTask
% It is possible that more than 1 of the same eventCXode is sent
% successively, hence take the minimum of such index. If empty, min() will use the lastIndex   

% example
% iEot = arrayfun(@(i) min([find(iEotTemp>iTask(i) & iEotTemp<iTaskTemp(i));NaN]),[1:length(iTask)]');

iTrialStart = iTrialStartTemp(arrayfun(@(i) min([find(iTrialStartTemp>iTaskStart(i) & iTrialStartTemp<iTaskEnd(i));numel(iTrialStartTemp)]),...
              (1:length(iTaskStart))'));

iEot = iEotTemp(arrayfun(@(i) min([find(iEotTemp>iTaskStart(i) & iEotTemp<iTaskEnd(i));numel(iEotTemp)]),...
              (1:length(iTaskStart))'));

iEndInfos = iEndInfosTemp(arrayfun(@(i) min([find(iEndInfosTemp>iTaskStart(i) & iEndInfosTemp<iTaskEnd(i));numel(iEndInfosTemp)]),...
              (1:length(iTaskStart))'));
 
 iTrialStart(iTrialStart>nEvents) = NaN;
 iEot(iEot>nEvents) = NaN;
 iEndInfos(iEndInfos>nEvents) = NaN;

% Get the augmented index into the codeIndex above.  These are indices into
% tdtEvs/tdtEvTms, the row number will be putative trial that corresponds
% to the evCodeTimeCellArr above
augmented = [iTrialStart iEot iEndInfos];

% Find indices into the augmented above where 
% the indices for iTrialStart, iEot, iEndInfos are NOT GREATER than
% (nEvents-1) for the trial/row 
% aka complete cases, but we are using only those trials where InfosEnd
% code is written
trialsWithEndInfos = find(sum(isnan(augmented(:,3)),2)==0);
%validEndInfosIndices = iEndInfos(trialsWithEndInfos);
validTrials = trialsWithEndInfos;
% prune evCodes and evTimes to valid task chunks
evCodes = evCodes(validTrials);
evTimes = evTimes(validTrials);


%% Read Rig event codes %%
eventFile = 'data/Joule/tdtSetup/TEMPO_EV_SEAS_rig029.m';

matchExpr = '(EV\.[A-Z]\w*)\s*=\s*(\d{1,4});';

rFid = fopen(eventFile,'r');
count = 0;
while ~feof(rFid)
    toks = regexp(fgetl(rFid),matchExpr,'tokens');
    if ~isempty(toks)
        count = count + 1;
        ev.name{count,1} = toks{1}{1};
        ev.code{count,1} = str2double(toks{1}{2});
    end
end
fclose(rFid);
evCode2Name = containers.Map(ev.code, ev.name);
evName2Code = containers.Map(ev.name, ev.code);


%% Read INFOS.pro for InfosCodec %%
eventFile = 'data/Joule/INFOS.pro';
% Event_fifo[Set_event] = InfosZero + Allowed_fix_time;
% or
% Event_fifo[Set_event] = InfosZero + (Stop_weight * 100);
% or 
% Event_fifo[Set_event] = InfosZero + (Y_Gain * 100) + 1000;
matchExpr = 'InfosZero\s*\+\s*\(*(\w*)\s*.*;';

rFid = fopen(eventFile,'r');
count = 0;
while ~feof(rFid)
    l = fgetl(rFid);
    toks = regexp(l,matchExpr,'tokens');
    if ~isempty(toks)
        count = count + 1;
        ev.name{count,1} = toks{1}{1};
        ev.code{count,1} = count;
    end
end
fclose(rFid);
evCode2Name = containers.Map(ev.code, ev.name);
evName2Code = containers.Map(ev.name, ev.code);


% Check evCodes from new and old....
old=load('oldEvCodesEvTimes.mat');
new=load('myEvCodesEvTimes.mat');

nTrialsOld = numel(old.trialCodes);
nTrialsNew = numel(new.trialCodes);
compareCodes = cell(max(nTrialsOld,nTrialsNew),1);

for ii = 1:max(nTrialsOld, nTrialsNew)
    o = NaN; ot = NaN;
    n = NaN; nt = NaN;
    if ii <= nTrialsOld
        o = old.trialCodes{ii};
        ot = old.trialTimes{ii};
    end
    if ii <= nTrialsNew
        n = new.trialCodes{ii};
        nt = new.trialCodes{ii};
    end
    z = nan(max(numel(o),numel(n)),1);
    oCodes = z; oCodes(1:length(o)) = o;
    nCodes = z; nCodes(1:length(n)) = n;
    oMinusNCodes = oCodes - nCodes;
    oTimes = z; oTimes(1:length(ot)) = ot;
    nTimes = z; nTimes(1:length(nt)) = nt;
    oMinusNTimes = oTimes - nTimes;
    compareCodes{ii,1} = [oCodes nCodes oMinusNCodes oTimes nTimes oMinusNTimes];
    
end

%% Convert cell array of eventCodes and eventTimeStamps to trialEventTimesTbl %%
nTrials = numel(trialCodes);
names = evCodec.name2Code.keys';
codes = cell2mat(evCodec.name2Code.values');
nNames = numel(names);
trialEventTimesTbl = array2table(nan(nTrials,nNames));
trialEventTimesTbl.Properties.VariableNames = names;

% convert cods to chr vector for finding index into code and thereby the
% right column for event time
charCodes = cellstr(num2str(codes,'%04d'));

trlColIndices = arrayfun(@(x) find(contains(charCodes,cellstr(num2str(trialCodes{x},'%04d')))),...
                        (1:nTrials)','UniformOutput',false);
  tic               
unknownCodes = [];
unknownCodeCount = 0;
for trlNo = 1:nTrials
    tCodes = unique(trialCodes{trlNo},'stable'); tCodes(tCodes>=3000)=[];
    for jj = 1:numel(tCodes)
        code = tCodes(jj);
        try
            TT.(evCodec.code2Name(code))(trlNo) = trialTimes{trlNo}(find(trialCodes{trlNo} == code,1,'first'));
        catch me
            warning('*** Trial# %d --> unknown code %d\n',trlNo,code);
            unknownCodeCount = unknownCodeCount + 1;
            unknownCodes(unknownCodeCount) = code;
        end
    end
end
 
 toc
 
 
 tTimes = arrayfun(@(c) trialTimes{1}(find(trialCodes{1}==c,1,'first')),tCodes);
 tCodesInd = find(contains(charCodes,cellstr(num2str(tCodes,'%04d'))))
 
 
%%% Kaleb stuff testing %%

tdtFun = @TDTbin2mat;
normFilepath = @(x) regexprep(x,'[/\\]',filesep);

tdtRaw = tdtFun(fileName,'TYPE',{'epocs','scalars'},'VERBOSE',0);
%> read up to t=14395.19s
tEv = tdtRaw.epocs.STRB.data;
tTm = tdtRaw.epocs.STRB.onset.*1000;
tTm(tEv==0)=[];
tEv(tEv==0)=[];

%%%%%
t1666 = find(tEv==1666); 
t1667 = find(tEv==1667);
t2999 = find(tEv==2999);
clear endInfosCS2
tic
% endInfosCS2 = arrayfun(@(x) t2999(find(t2999 > t1667(x) & t2999 < t1666(x+1),1,'first')),(1:numel(t1666)-1)');
endInfosCS2 = arrayfun(@(x) t2999(find(t2999 > t1667(x) & t2999 < t1666(x+1),1)),(1:numel(t1666)-1)');
 try
     endInfosCS2(end+1) = t2999(t2999 > t1667(end) & t2999 < numel(tEv));
     %endInfosCS(end+1) = t2999(find(t2999 > t1667(end) & t2999 < numel(tEv)));
 catch
     endInfosCS2(end+1) = NaN;
 end
toc

%% Infos reading form INFOS is not correct...
infosDefFile = 'data/Joule/TEMPO/currentProcLib/INFOS.pro';
fid = fopen(infosDefFile,'r');
% Clean codelines
lines = {''};
while ~feof(fid)
    l = fgetl(fid);
    l = regexprep(l,'[ \t]+',' ');
    l = regexprep(l,'^ | $','');
    lines = [lines;l];
end
fclose(fid);
codeLines = {''};

inCommentBloc = false;
isCommented = zeros(numel(lines),1);
for ii = 1:numel(lines)    
    isCommented(ii) = startsWith(lines{ii},'//') ;
    
end




