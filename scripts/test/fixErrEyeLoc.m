drive = '/Volumes/schalllab';
load(fullfile(drive,'Users/Chenchal/Tempo_NewCode/dataProcessed/Joule-190408-092206/Events.mat'));
load(fullfile(drive,'Users/Chenchal/Tempo_NewCode/dataProcessed/Joule-190408-092206/Eyes.mat'));
Task = struct2table(Task);
TaskInfos = struct2table(TaskInfos);

xGain = 3.622;
yGain = 3.837;
%% Eye vals in deg
fxVolts = @(x,gain)(x.* gain);
% Eye components
eyeBinWidth = tdt.BinWidthMs;
% in case we do by trials
eyeX = {tdt.EyeX};
eyeY = {tdt.EyeY};
% Eye components in degrees
eyeXDeg = cellfun(@(x) fxVolts(x,xGain),eyeX,'UniformOutput',false); 
eyeYDeg = cellfun(@(x) fxVolts(x,yGain),eyeY,'UniformOutput',false); 

%% 
figure
axes
hold on
fxTim = @(evtStr) ceil(Task.(evtStr)(~isnan(Task.(evtStr)))./eyeBinWidth);
fxCart = @(evtStr,markerStr) plot(eyeXDeg{1}(fxTim(evtStr)),eyeYDeg{1}(fxTim(evtStr)),markerStr);
evtToPlot = {'AcquireFix_','FixSpotOn_','FixBreak_','Fixate_'};
evtMarker ={'.r','.k','xb','^m'};

cellfun(@(ev,m) fxCart(ev,m), evtToPlot,evtMarker,'UniformOutput',false);
% draw fix window and fix window large
iWinDeg = 5;
iWinFactor = 1.5;
x=[-iWinDeg/2, iWinDeg/2, iWinDeg/2, -iWinDeg/2];
y=[-iWinDeg/2, -iWinDeg/2, iWinDeg/2, iWinDeg/2];
patch(x,y,'k','LineWidth',2,'FaceColor','none','LineWidth',1, 'LineStyle', '--')
patch(x.*iWinFactor,y.*iWinFactor,'k','LineWidth',2,'FaceColor','none','LineWidth',1,'LineStyle',':')
xlim([-10 10])
ylim([-10 10])
grid on
%% Trajectories....
figure
axes
hold on
iWinDeg = 5;
iWinFactor = 1.5;
x=[-iWinDeg/2, iWinDeg/2, iWinDeg/2, -iWinDeg/2];
y=[-iWinDeg/2, -iWinDeg/2, iWinDeg/2, iWinDeg/2];
patch(x,y,'k','LineWidth',2,'FaceColor','none','LineWidth',1, 'LineStyle', '--')
patch(x.*iWinFactor,y.*iWinFactor,'k','LineWidth',2,'FaceColor','none','LineWidth',1,'LineStyle',':')
xlim([-20 20])
ylim([-20 20])
grid on

iBinStart =  ceil(Task.FixSpotOn_ ./eyeBinWidth);
iBinEnd = ceil(Task.FixBreak_ ./eyeBinWidth);
idx = find(~isnan(Task.FixBreak_));
for ii =1:numel(idx)
    x = idx(ii);
    plot(eyeXDeg{1}(iBinStart(x):iBinEnd(x)), eyeYDeg{1}(iBinStart(x):iBinEnd(x)),'r')
    plot(eyeXDeg{1}(iBinStart(x)), eyeYDeg{1}(iBinStart(x)),'xr','MarkerSize',10)
    plot(eyeXDeg{1}(iBinEnd(x)), eyeYDeg{1}(iBinEnd(x)),'^r','MarkerSize',10)
    
    drawnow
    pause
end

iBinEnd = ceil(Task.Fixate_ ./eyeBinWidth);
idx = find(~isnan(Task.Fixate_));
for ii =1:numel(idx)
    x = idx(ii);
    plot(eyeXDeg{1}(iBinStart(x):iBinEnd(x)), eyeYDeg{1}(iBinStart(x):iBinEnd(x)),'b')
    plot(eyeXDeg{1}(iBinStart(x)), eyeYDeg{1}(iBinStart(x)),'+b','MarkerSize',10)
    plot(eyeXDeg{1}(iBinEnd(x)), eyeYDeg{1}(iBinEnd(x)),'<b','MarkerSize',10)
    
    drawnow
    pause
end




%%

function plotPolarCoord()

fxAng = @(x,y) atan2(y,x);
fxEcc = @(x,y) sqrt(x.^2 + y.^2);
% Eye in angle and eccentricity
eyeAngle = cellfun(@(x,y) fxAng(x,y),eyeXDeg,eyeYDeg,'UniformOutput',false);
eyeEcc = cellfun(@(x,y) fxEcc(x,y),eyeXDeg,eyeYDeg,'UniformOutput',false);


figure
polaraxes()
hold on
% since we cannot set marker transparency, but can overplot other marker
%tim =  ceil(Task.FixSpotOn_(Task.FixBreak_ > 0)./eyeBinWidth);
%polarplot(eyeAngle{1}(tim),eyeEcc{1}(tim),'dr','MarkerFaceColor','r')

fxTim = @(evtStr) ceil(Task.(evtStr)(~isnan(Task.(evtStr)))./eyeBinWidth);
fxPolar = @(evtStr,markerStr) polarplot(eyeAngle{1}(fxTim(evtStr)),eyeEcc{1}(fxTim(evtStr)),markerStr);
evtToPlot = {'AcquireFix_','FixSpotOn_','FixBreak_'};
evtMarker ={'or','.k','xr'};

cellfun(@(ev,m) fxPolar(ev,m), evtToPlot,evtMarker,'UniformOutput',false);

%evtToPlot = ['FixBreak_ & FixSpotOn_', evtToPlot];


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
rlim([0 5])

end
