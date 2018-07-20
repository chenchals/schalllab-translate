function Task = getTask(tdtEvs, tdtEvTms, Eyes)

eventCodeFile = '/Users/subravcr/teba/local/data/Joule/tdtSetup/TEMPO_EV_SEAS_rig029.m';

print = 0;

if nargin < 3
    Eyes.X = nan;
    Eyes.Y = nan;
    Eyes.R = nan;
    Eyes.Theta = nan;
    Eyes.Times = nan;
    Eyes.Good = 0;
end

% Set some code identifiers
trStartCode = 1666;
trEndCode = 1667;
taskHeaders = 1500:1510;
cmdHeader = 1501;
mgHeader = 1502;
antiHeader = 1509;
infoEndCode = 2999;

% CS: run an m-file for event codes 
% EV = TEMPO_EV_cosman_rig028;
run(eventCodeFile);
EV = ans;

% Find trial starts and ends
startInds = find(tdtEvs == trStartCode);
endInds = find(tdtEvs == trEndCode);
trHeadInds = find(ismember(tdtEvs,taskHeaders));
endInfoTmp = find(tdtEvs == infoEndCode);
endInfos = nan(1,length(trHeadInds));
trEnds = nan(1,length(trHeadInds));
for it = 1:(length(trHeadInds)-1)
    check = endInfoTmp(find(endInfoTmp > trHeadInds(it) & endInfoTmp < trHeadInds(it+1),1));
    checkEnd = endInds(find(endInds > trHeadInds(it) & endInds < trHeadInds(it+1),1));
    if ~isempty(check), endInfos(it) = check; else endInfos(it) = nan; end
    if ~isempty(checkEnd), trEnds(it) = checkEnd; else trEnds(it) = nan; end
end
check = endInfoTmp(find(endInfoTmp > trHeadInds(end),1));
checkEnd = endInds(find(endInds > trHeadInds(end),1));
if ~isempty(check), endInfos(it+1) = check; else endInfos(it+1) = nan; end
if ~isempty(checkEnd), trEnds(it+1) = checkEnd; else trEnds(it+1) = nan; end
trHeadInds(isnan(endInfos)) = [];
trEnds(isnan(endInfos)) = [];
endInfos(isnan(endInfos)) = [];

% Get the trial codes
nTrs = length(trHeadInds);%min([length(startInds),length(endInds)]);
for it = 1:nTrs
    trialCodes{it,1} = tdtEvs(trHeadInds(it):endInfos(it));
    trialTimes{it,1} = tdtEvTms(trHeadInds(it):endInfos(it));
end
% if nTrs < 100
%     Task.Good = 0;
%     return;
% end
Task.Good = 1;


% Get the trial headers
trHeads = tdtEvs(trHeadInds);
% Get unique task types
uTasks = unique(trHeads(~isnan(trHeads)));

% Now loop through them and run their respective analyses
for it = 1:length(uTasks)
    fprintf('Decoding trials with header %d...\n',uTasks(it));
    switch uTasks(it)
        case mgHeader
            taskTmp{it} = klDecodeMG(trialCodes(trHeads==uTasks(it),1),trialTimes(trHeads==uTasks(it),1),EV,Eyes,'-p',print);
        case antiHeader
            taskTmp{it} = klDecodeAnti(trialCodes(trHeads==uTasks(it),1),trialTimes(trHeads==uTasks(it),1),EV,Eyes,'-p',print);
        case cmdHeader
            taskTmp{it} = decodeCmdTask(trialCodes(trHeads==uTasks(it),1),trialTimes(trHeads==uTasks(it),1),EV,Eyes,'-p',print);
    end
end

Task = mergeTasks(taskTmp,trHeads);
Task.trStarts = tdtEvTms(trHeadInds);
Task.trEnds = tdtEvTms(trEnds);
