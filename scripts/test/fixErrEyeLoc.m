drive = '/Volumes/schalllab';
load(fullfile(drive,'Users/Chenchal/Tempo_NewCode/dataProcessed/Joule-190408-092206/Events.mat'));
load(fullfile(drive,'Users/Chenchal/Tempo_NewCode/dataProcessed/Joule-190408-092206/Eyes.mat'));

Task = struct2table(Task);
TaskInfos = struct2table(TaskInfos);

xGain = 3.622;
yGain = 3.837;


fxVolts = @(x,gain)(x.* gain);
fxAng = @(x,y) atan2(y,x);
fxEcc = @(x,y) sqrt(x.^2 + y.^2);
% Eye components
eyeBinWidth = tdt.BinWidthMs;
eyeX = {tdt.EyeX};
eyeY = {tdt.EyeY};
% Eye components in degrees
eyeXDeg = cellfun(@(x) fxVolts(x,xGain),eyeX,'UniformOutput',false); 
eyeYDeg = cellfun(@(x) fxVolts(x,yGain),eyeY,'UniformOutput',false); 
% Eye in angle and eccentricity
eyeAngle = cellfun(@(x,y) fxAng(x,y),eyeXDeg,eyeYDeg,'UniformOutput',false);
eyeEcc = cellfun(@(x,y) fxEcc(x,y),eyeXDeg,eyeYDeg,'UniformOutput',false);


%%
figure
polaraxes()
hold on
% since we cannot set marker transparency, but can overplot other marker
tim =  ceil(Task.FixSpotOn_(Task.FixBreak_ > 0)./eyeBinWidth);
polarplot(eyeAngle{1}(tim),eyeEcc{1}(tim),'dr','MarkerFaceColor','r')

fxTim = @(evtStr) ceil(Task.(evtStr)(~isnan(Task.(evtStr)))./eyeBinWidth);
fxPolar = @(evtStr,markerStr) polarplot(eyeAngle{1}(fxTim(evtStr)),eyeEcc{1}(fxTim(evtStr)),markerStr);
evtToPlot = {'TargetHold_','Fixate_','FixBreak_','AcquireFixError_','FixSpotOn_'};
evtMarker ={'ob','or','xr','xc','.k'};

cellfun(@(ev,m) fxPolar(ev,m), evtToPlot,evtMarker,'UniformOutput',false);

evtToPlot = ['FixBreak_ & FixSpotOn_', evtToPlot];


% draw fix window and fix window large
iWinDeg = 5;
iWinFactor = 1.5;
t=0:.01:(2*pi);r=repmat(iWinDeg/2,1,numel(t));
polarplot(t,r,'--r','LineWidth',2)
polarplot(t,r.*iWinFactor,':r','LineWidth',2)

% draw target window and target window large
tEcc = 12.0;
iWinDeg = 8;
iWinFactor = 1.5;
t=0:.01:(2*pi);r=repmat(iWinDeg/2,1,numel(t));
[x,y]=pol2cart(t,r);
% translate x-cartisean to "left" or "right"
xLeft = x-tEcc;
xRight = x+tEcc;
[tLeft,rLeft] = cart2pol(xLeft,y);
[tRight,rRight] = cart2pol(xRight,y);

polarplot(tLeft,rLeft,'--b','LineWidth',2)
polarplot(tRight,rRight,'--b','LineWidth',2)

legend(evtToPlot,'Interpreter','none','Box','off')
rlim([0 20])








function byTrials()
% to be used only if eye data is split into trials during translation
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
end