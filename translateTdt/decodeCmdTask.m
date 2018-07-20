function Task = decodeCmdTask(trialCodes,trialTimes,events,Eyes,varargin)

nTrs = size(trialCodes,1);

evntCnt = cellfun(@length,trialCodes);
allCodes = nan(nTrs,max(evntCnt));
% Task = struct('StimOnsetToTrial',[],'SRT',
Task.StimOnsetToTrial = nan(nTrs,1);
Task.SRT = nan(nTrs,1);
Task.SaccEnd = nan(nTrs,1);
Task.Reward = nan(nTrs,1);
Task.Tone = nan(nTrs,1);
Task.RewardTone = nan(nTrs,1);
Task.ErrorTone = nan(nTrs,1);
Task.FixSpotOn = nan(nTrs,1);
Task.FixSpotOff = nan(nTrs,1);
Task.SingletonColor = nan(nTrs,1);
Task.DistractorColor = nan(nTrs,1);
Task.CueType = nan(nTrs,1);
Task.Eccentricity = nan(nTrs,1);
Task.EndAngle = nan(nTrs,1);
Task.EndEcc = nan(nTrs,1);
Task.SetSize = nan(nTrs,1);
Task.StimLoc = nan(nTrs,4);
Task.StimDiff = nan(nTrs,4);
Task.TargetLoc = nan(nTrs,1);
Task.Congruent = nan(nTrs,1);
Task.Correct = nan(nTrs,1);
Task.Abort = nan(nTrs,1);
Task.Outcome = nan(nTrs,1);
Task.Error = nan(nTrs,1);

for it = 1:nTrs
    trCodes = trialCodes{it};
    trTimes = trialTimes{it};
    
    %% Get timings
    Task.StimOnsetToTrial(it)      = getEvTime(trCodes,trTimes,events.Target_);
    Task.SRT(it)            = getEvTime(trCodes,trTimes,events.Saccade_);
    Task.SaccEnd(it)        = getEvTime(trCodes,trTimes,events.Decide_);
    Task.Reward(it)         = getEvTime(trCodes,trTimes,events.Reward_);
    Task.Tone(it)           = getEvTime(trCodes,trTimes,events.Tone_);
    Task.RewardTone(it)     = getEvTime(trCodes,trTimes,events.Reward_tone);
    Task.ErrorTone(it)      = getEvTime(trCodes,trTimes,events.Error_tone);
    Task.FixSpotOn(it)      = getEvTime(trCodes,trTimes,events.FixSpotOn_);
    Task.FixSpotOff(it)     = getEvTime(trCodes,trTimes,events.FixSpotOff_);
    
    % Create MG Info Matrix
    trInfos = trCodes(find(trCodes == events.StartInfos_,1):find(trCodes == events.EndInfos_,1,'last'));
    infoVect = getInfos(trInfos);
    if mod(infoVect(20)-3000,45) ~= 0
      %  keyboard
    end
    
    Task.TargetLoc(it)      = infoVect(20)-3000;
    Task.Eccentricity(it)   = (infoVect(25)-3000)/100;
    Task.Outcome(it)        = infoVect(30)-3000;
    Task.Correct(it)        = any(trCodes == events.Correct_);
    Task.Abort(it)          = any(trCodes == events.Abort_);
end


Task.AlignTimes = Task.StimOnsetToTrial;
Task.SaccEnd    = Task.SaccEnd          - Task.StimOnsetToTrial;
Task.Reward     = Task.Reward           - Task.StimOnsetToTrial;
Task.Tone       = Task.Tone             - Task.StimOnsetToTrial;
Task.RewardTone = Task.RewardTone       - Task.StimOnsetToTrial;
Task.ErrorTone  = Task.ErrorTone        - Task.StimOnsetToTrial;
Task.FixSpotOn  = Task.FixSpotOn        - Task.StimOnsetToTrial;
Task.FixSpotOff = Task.FixSpotOff       - Task.StimOnsetToTrial;
Task.StimOnset  = Task.StimOnsetToTrial - Task.StimOnsetToTrial; % should be all zero aferwards
Task.GoCue 		= Task.FixSpotOff;
Task.SRT        = Task.SRT              - Task.StimOnsetToTrial - Task.GoCue;


function outTime = getEvTime(codes,times,match),
    tmp = find(codes==match,1);
    if ~isempty(tmp),
        outTime = times(tmp);
    else
        outTime = nan;
    end
end

function infoVect = getInfos(infos)
    % We're gonna have to do this in a complicated way perhaps, but I
    % suppose it's worth it
    infosRaw = infos;
    infoVect = nan(1,length(infos));
    minVals = [2998,ones(1,30).*3000,2999];
    maxVals = [2998,4000,3100,9999,9999,5000,5000,5000,3010,9999,3500,5000,3002,3255,3255,3255,3100,4000,4000,3360,3256,3255,3255,3255,5000,5000,4000,4000,9999,3020,3010,2999];
    
    
%     minVals = [2998,3000,4000,4050,4060,4100,4150,4200,4250,8000,8000,5000,5500,3800,4650,4660,4670,4700,4800,4900,6000,3000,2999];
%     maxVals = [2998,4000,5000,5000,5000,4200,4200,4300,4300,9000,9000,5500,6000,4500,4700,4700,4700,4800,4900,6000,10000,4000,2999];
    for ic = 1:length(minVals),
        cutStuff = find(infos >= minVals(ic) & infos <= maxVals(ic),1);
        if isempty(cutStuff),
            infoVect(ic) = nan;
        elseif cutStuff > 1 && ic ~= length(minVals)
            cutStuffNext = find(infos >= minVals(ic+1) & infos <= maxVals(ic+1),1);
            if cutStuffNext < cutStuff
                infoVect(ic) = nan;
            else
                infoVect(ic) = infos(cutStuff); infos = infos((cutStuff+1):end);
            end
        else
            infoVect(ic) = infos(cutStuff); infos = infos((cutStuff+1):end);
        end
    end
%     cutStuff = find(ismember(infos,[2222,1111]),1,'last');
%     if isempty(cutStuff),
%         infoVect(9) = nan;
%     else
%         infoVect(9) = infos(cutStuff); infos = infos((cutStuff+1):end);
%     end
%     for ic = 9:length(minVals),
%         cutStuff = find(infos >= minVals(ic) & infos <= maxVals(ic),1);
%         if isempty(cutStuff),
%             infoVect(ic+1) = nan;
%         else
%             infoVect(ic+1) = infos(cutStuff); infos = infos((cutStuff+1):end);
%         end
%     end
    
end


end

