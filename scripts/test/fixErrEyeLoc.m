load('T:\Users\Chenchal\Tempo_NewCode\dataProcessed\Joule-190408-092206\Events.mat');
load('T:\Users\Chenchal\Tempo_NewCode\dataProcessed\Joule-190408-092206\Eyes.mat');

Task = struct2table(Task);
TaskInfos = struct2table(TaskInfos);

maxVoltage = 10;
adcUnits = 2^15;
xGain = 3.622;
yGain = 3.837;
xOffset = 0;
yOffset = 0;

fxDeg = @(x,gain,offset)(x.* ((maxVoltage * 2.0)/adcUnits) * gain) - offset;
fxAngle = @(x,y) atan2d(y,x);
fxEcc = @(x,y) sqrt(x.^2 + y.^2);
% Eye components in degrees
eyeXDeg = cellfun(@(x) fxDeg(x,xGain,xOffset),tdtEyeX,'UniformOutput',false); 
eyeYDeg = cellfun(@(x) fxDeg(x,yGain,yOffset),tdtEyeY,'UniformOutput',false); 
% Eye in angle and eccentricity
eyeAngle = cellfun(@(x,y) fxAngle(x,y),eyeXDeg,eyeYDeg,'UniformOutput',false);
eyeEcc = cellfun(@(x,y) fxEcc(x,y),eyeXDeg,eyeYDeg,'UniformOutput',false);



figure
%% Fix break
% Idx of FixBreak_ trial
trlIdx = find(Task.FixBreak_>0);
% Time of fix break from trial start
trlTim = ceil(Task.FixBreak_(trlIdx) - Task.TrialStart_(trlIdx));
for ii = 1:numel(trlIdx)
    trl = trlIdx(ii);
    tim = trlTim(ii);
    polar(deg2rad(eyeAngle{trl}(tim)),eyeEcc{trl}(tim),'or')
    hold on
end

%% Fixate
trlIdx = find(Task.Fixate_>0);
trlTim = ceil(Task.Fixate_(trlIdx) - Task.TrialStart_(trlIdx));

for ii = 1:numel(trlIdx)
    trl = trlIdx(ii);
    tim = trlTim(ii);
    polar(deg2rad(eyeAngle{trl}(tim)),eyeEcc{trl}(tim),'xb')
    hold on
end

%% Targ hold
trlIdx = find(Task.TargetHold_>0);
trlTim = ceil(Task.TargetHold_(trlIdx) - Task.TrialStart_(trlIdx));

for ii = 1:numel(trlIdx)
    trl = trlIdx(ii);
    tim = trlTim(ii);
    polar(deg2rad(eyeAngle{trl}(tim)),eyeEcc{trl}(tim),'.c')
    hold on
end
