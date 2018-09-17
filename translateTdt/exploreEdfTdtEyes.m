% load edf data
%sessDir = 'data/Leonardo/Eyelink-EDF/Leonardo-180904-105502';
% sessDir = 'data/Leonardo/Eyelink-EDF/Leonardo-180910-112920';
% edf=load(fullfile(sessDir,'LE180910.mat'));
% 
% sessDir = 'data/Leonardo/Eyelink-EDF/Leonardo-180910-120113';
% edf=load(fullfile(sessDir,'LE180910.mat'));
% large session
sessDir = 'data/Leonardo/Eyelink-EDF/Leonardo-180910-122025';
edf=load(fullfile(sessDir,'Leonardo-180910-122025_EDF.mat'));
% 
edfData = 'dataEDF'; % it was also just data
edfX = edf.(edfData).FSAMPLE.gx(1,:);
edfY = edf.(edfData).FSAMPLE.gy(1,:);
edfFs = 1000; 

% Read Eye_X stream, and Eye_Y Stream form TDT

tdtXStruct = TDTbin2mat(sessDir,'TYPE',{'streams'},'STORE','EyeX','VERBOSE',0);
tdtYStruct = TDTbin2mat(sessDir,'TYPE',{'streams'},'STORE','EyeY','VERBOSE',0);

tdtFs = tdtXStruct.streams.EyeX.fs;
tdtX = tdtXStruct.streams.EyeX.data;
tdtY = tdtYStruct.streams.EyeY.data;
tdtX10 = movmean(tdtX,10);

% % Different sliding windows in seconds
slidingWinList = [20,50]';

% do classic way that is slide one vector over other....
for ii = 1:numel(slidingWinList)
    tic
    fprintf('Doing %d secs sliding window\n',slidingWinList(ii));
    startIndices(ii,1) = tdtAlignEyeWithEdf(edfX(1:150000),tdtX10(1:10000),edfFs,tdtFs,slidingWinList(ii));
    toc
end

t = table();
t.slidingWinList = slidingWinList;
t.alignStartIndex = startIndices;
t

% See also EDF2MAT in edf-converter
% https://github.com/uzh/edf-converter.git for MISSING_DATA_VALUE and
% EMPTY_VALUE definitions
%
% From Edf2Mat.m in edf-converter
MISSING_DATA_VALUE  = -32768;
EMPTY_VALUE         = 1e08;

edfX(edfX==MISSING_DATA_VALUE)=nan;
edfX(edfX==EMPTY_VALUE)=nan;

edfY(edfY==MISSING_DATA_VALUE)=nan;
edfY(edfY==EMPTY_VALUE)=nan;

% Plot some data after aligning... not yet hashed out.....
%edfStartIndex = startIndices(1);
tdtTime = floor((0:numel(tdtX)-1).*(1000/tdtFs));
voltRange = [-5 5];
signalRange = [-0.2 1.2];
pixelRangeX = [0 1024]; % Eye-X
plot(tdtTime,tdtAnalog2Pixels(tdtX,[-5 5],[-0.2 1.2],pixelRangeX),'b','LineWidth',1);
hold on
edfTime = 0:ceil(max(tdtTime));
plot(edfTime,edfX(startIndices(1):startIndices(1)+numel(edfTime)-1),'r','LineWidth',2);
hold on
% plot(edfTime,edfX(startIndices(end):startIndices(end)+numel(edfTime)-1),'g','LineWidth',1);
% hold on
ylabel('screen pixels');
xlabel('time (ms)');
hold off
%legend('tdtData', num2str(startIndices(1),'startIndexfor 60 sec =%d'), num2str(startIndices(end),'startIndex for 120 sec=%d'))

%% Parse into trials based of First trial offset
load('dataProcessed/Leonardo/Eyelink-EDF/Leonardo-180910-122025/Leonardo-180910-122025/Leonardo-180910-122025.mat')
trialTable = table();
trialTable.trialTimeMs=round(Task.TrialStart_);
trialTable.trialDurationMs=[diff(trialTable.trialTimeMs);NaN];
tdtBinWidthMs = 1000/tdtFs;
trialTable.tdtTrialTimeBins=trialTable.trialTimeMs./tdtBinWidthMs;
trialTable.tdtTrialTimeBins=round(trialTable.trialTimeMs./tdtBinWidthMs);
edfTrialStartOffset = startIndices(1);
trialTable.edfTrialTimeBins=round(trialTable.trialTimeMs+edfTrialStartOffset);


tdtXClean = tdtX;
tdtXClean(tdtXClean>180)=NaN;
tdtXCleanPix = tdtAnalog2Pixels(tdtXClean,voltRange,signalRange,pixelRangeX);

nTrials = size(trialTable,1);
tdtTrialsEyeX = arrayfun(@(ii) tdtXCleanPix(trialTable.tdtTrialTimeBins(ii):trialTable.tdtTrialTimeBins(ii+1)-1), (2:nTrials-1)','UniformOutput',false);
edfTrialsEyeX = arrayfun(@(ii) edfX(trialTable.edfTrialTimeBins(ii):trialTable.edfTrialTimeBins(ii+1)-1), (2:nTrials-1)','UniformOutput',false);
% pad Nan as 1st and last trials
tdtTrialsEyeX = [NaN;tdtTrialsEyeX;NaN];
edfTrialsEyeX = [NaN;edfTrialsEyeX;NaN];

for ii = 2:20
    tx = tdtTrialsEyeX{ii};
    txTime = (0:numel(tx)-1)'.*tdtBinWidthMs;
    ex = edfTrialsEyeX{ii};
    exTime = (0:numel(ex)-1)';
    plot(txTime,tx,'b');
    hold on
    plot(exTime,ex,'r');
    hold off
    pause
    
end



%%

%Try align....
    edf = load(trialEyes.edfMatFile);
    edfX = edf.(edfData).FSAMPLE.gx(1,:);
    tempEdfX = edfX;
    fprintf('Aligning...\n');
    for ii = 2:nTrials-1
         fprintf('.');
        slidingWindow = 10;
        if ii <= 2
            slidingWindow = maxTdtStartDelay;
        end
        edfStartIndices(ii) = tdtAlignEyeWithEdf(tempEdfX,trialEyes.tdtEyeX{ii},edfFs,tdtFs,slidingWindow);
        tempEdfX = tempEdfX(edfStartIndices(ii):end);
        if mod(ii,100)==0
            fprintf('%d\n',ii);
        end
    end
    edfDataIndex = edfStartIndices;
    edfDataIndex(3:end) = edfDataIndex(3:end) + edfDataIndex(2);
   

    
 %% Filter TDT signal?
Fs = tdtFs; % sampling rate
cf = 50; % 50 Hz cut off
Hd = designfilt('lowpassfir','FilterOrder',100,'CutoffFrequency',cf, ...
       'DesignMethod','window','Window',{@kaiser,3},'SampleRate',Fs);
    
   
tdtXFilt = filter(Hd,tdtX);


plot(tdtTime,tdtX)
hold on
plot(tdtTime,tdtXFilt)
hold off
xlim([4800 5200])
hold on
plot(tdtTime,movmean(tdtX,10))

figure
plot(tdtTime,tdtX)
hold on
plot(tdtTime,movmean(tdtX,10))
xlim([4800 5200])
plot(tdtTime,movmean(tdtX,8))



