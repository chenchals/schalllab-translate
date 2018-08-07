%% Joule setup
joule.sess = 'Joule-180806-134425';
joule.sessDir = fullfile('data/Joule/tdtData/troubleshootEventCodes',joule.sess);
joule.behavFile = fullfile('dataProcessed/data/Joule/tdtData/troubleshootEventCodes',joule.sess,'Behav.mat');

joule.eventDefFile = 'data/Joule/TEMPO/currProcLib_15/EVENTDEF.pro';
joule.infosDefFile = 'data/Joule/TEMPO/currProcLib_15/CMD/INFOS.pro';
joule.pdStreamNames = {'PhoL';'PhoR'};

%% Darwin setup
darwin.sess = 'Darwin-180806-123257';
darwin.sessDir = fullfile('data/Darwin/proAntiTraining',darwin.sess);
darwin.behavFile = fullfile('dataProcessed/data/Darwin/proAntiTraining',darwin.sess,'Behav.mat');

darwin.eventDefFile = 'KalebCodes/EVENTDEF.pro';
darwin.infosDefFile = '';
darwin.pdStreamNames = {'PD2_';'PD__'};

%% Leonardo setup
leonardo.sess = 'Leonardo-180806-130017';
leonardo.sessDir = fullfile('data/Leonardo/ColorDetectionTraining',leonardo.sess);
leonardo.behavFile = fullfile('dataProcessed/data/Leonardo/ColorDetectionTraining',leonardo.sess,'Behav.mat');

leonardo.eventDefFile = 'KalebCodes/EVENTDEF.pro';
leonardo.infosDefFile = '';
leonardo.pdStreamNames = {'PD2_';'PD__'};

%% Check for Behavior file....
monk = joule;

sessDir = monk.sessDir;
behavFile = monk.behavFile;
eventDefFile = monk.eventDefFile;
infosDefFile = monk.infosDefFile;
pdStreamNames = monk.pdStreamNames;

if ~exist(behavFile,'file')
    fprintf('Behav.mat file not found, translating TDT acquired data\n');
    [temp,temp2] = runExtraction(sessDir,behavFile,eventDefFile,infosDefFile);
    
end
% First to get signal, Last to get signal. Always triggered on Last
pdFirstName = pdStreamNames{1};
pdLastName = pdStreamNames{2};

% Read PhotoDiode data
heads = TDTbin2mat(sessDir, 'HEADERS', 1);

pdFirstStream = TDTbin2mat(sessDir,'TYPE',{'streams'},'STORE',pdFirstName,'VERBOSE',0);
pdLastStream = TDTbin2mat(sessDir,'TYPE',{'streams'},'STORE',pdLastName,'VERBOSE',0);

pdFs = pdFirstStream.streams.(pdFirstName).fs;

% Process PhotoDiode data
tic
[photodiodeEvents, pdFirstSignal, pdLastSignal] = processPhotodiode({pdFirstStream.streams.(pdFirstName).data, pdLastStream.streams.(pdLastName).data}, pdFs);
toc
pdFirstVolts = pdFirstSignal.pdVolts;
pdLastVolts = pdLastSignal.pdVolts;

nTimeBins = size(pdFirstVolts,2);
signalTimeMs = (-floor(nTimeBins/2):floor(nTimeBins/2))';

nFirst = size(pdFirstVolts,1);
nLast = size(pdLastVolts,1);

orphanVolts = [];
orphansInFirst = false;

if nFirst > nLast
    orphansInFirst = true;
    orphanVolts = pdFirstVolts(nLast+1:end,:);    
elseif nLast > nFirst
    orphansInFirst = false;
    orphanVolts = pdLastVolts(nFirst+1:end,:);
else %both are same size
end

nOrphans = size(orphanVolts,1);
orphansY = [orphanVolts';nan(1,nOrphans)];
orphansX = repmat([signalTimeMs;NaN],1,nOrphans);

figure
plot(orphansX(:),orphansY(:),'g')


pdLsmooth = movmean(pdFirstStream.streams.(pdFirstName).data,[2 0]);
pdRsmooth = movmean(pdLastStream.streams.(pdLastName).data,[2 0]);

beh = load(behavFile);
pdFirstMs = photodiodeEvents.PD_First_Ms;
pdLastMs = photodiodeEvents.PD_Last_Ms_Paired;

%eventName = 'PDtrigger_';
eventName = 'FixSpotOn_';
eventTime = beh.Task.(eventName);

% to find closest index into photodiode timestamps
% edges = [-Inf; pd1Start; +Inf];
% closestIdx = @(x) discretize(x, edges);
% Find closest index into PD timestamps for FixSPotOn_
% [closeFixOnIdx, closeFixOnMeanTs] = closestIdx(fixSpotOn);
closestIdx = nan(numel(eventTime),1);

for ii = 1:numel(eventTime)
    d = abs(pdLastMs-eventTime(ii));
    closestIdx(ii,1) = min([find(d==min(d),1);NaN]);
end
figure
nTimeBins = size(pdFirstVolts,2);
xTimeInTicks = (-floor(nTimeBins/2):floor(nTimeBins/2))';
xTimeMs = xTimeInTicks*1000/pdFs;
evRelT = nan(numel(closestIdx),1);
for ii = 1:numel(closestIdx)
    idx = closestIdx(ii);
    if isnan(idx)
        continue;
    end
    pdT = pdLastMs(idx);
    % rel Time
    xRel = xTimeMs;
    % abs time for event
    evT = eventTime(ii);
    % time rel to t
    evRelT(ii,1) = evT - pdT;
    y = pdLastVolts(idx,:);
    plot(xRel,y);
    
    line([0 0],ylim)
    line([evRelT(ii,1) evRelT(ii,1)],ylim,'color','r')
%     text(xRel(10),double(y(10)),...
%         sprintf('Photodiode time (ms) = %.3f\n [%s] event (ms) = %.3f',pdT,eventName,evT))    
    %drawnow
    hold on
end
xlabel('PD signal Relative time (millisec)');
ylabel('PD signal');




