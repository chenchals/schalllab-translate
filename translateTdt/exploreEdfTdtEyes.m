% load edf data
%sessDir = 'data/Leonardo/Eyelink-EDF/Leonardo-180904-105502';
% sessDir = 'data/Leonardo/Eyelink-EDF/Leonardo-180910-112920';
% edf=load(fullfile(sessDir,'LE180910.mat'));
% 
sessDir = 'data/Leonardo/Eyelink-EDF/Leonardo-180910-120113';
edf=load(fullfile(sessDir,'LE180910.mat'));
% large session
% sessDir = 'data/Leonardo/Eyelink-EDF/Leonardo-180910-122025';
% edf=load(fullfile(sessDir,'dataEDF.mat'));
% 
edfData = 'dataEDF'; % it was also just data
if isfield(edf, 'data')
    edfData ='data';
end

edfX = edf.(edfData).FSAMPLE.gx(1,:);
edfY = edf.(edfData).FSAMPLE.gy(1,:);
edfTime = edf.(edfData).FSAMPLE.time;
edfFs = 1000; 

% Read Eye_X stream, and Eye_Y Stream form TDT

tdtXStruct = TDTbin2mat(sessDir,'TYPE',{'streams'},'STORE','EyeX','VERBOSE',0);
tdtYStruct = TDTbin2mat(sessDir,'TYPE',{'streams'},'STORE','EyeY','VERBOSE',0);

tdtFs = round(tdtXStruct.streams.EyeX.fs);
tdtX = tdtXStruct.streams.EyeX.data;
tdtY = tdtYStruct.streams.EyeY.data;
tdtTime = (0:numel(tdtX)-1).*(1000/tdtFs);
% % Different sliding windows in seconds
slidingWinList = [60:10:120]';
% do classic way that is slide one vector over other....
for ii = 1:numel(slidingWinList)
    tic
    fprintf('Doing %d secs sliding window\n',slidingWinList(ii));
    [~, startIndices(ii,1)] = tdtAlignEyeWithEdf(edfX,tdtX,edfFs,tdtFs,slidingWinList(ii));
    toc
end

t = table();
t.slidingWinList = slidingWinList;
t.alignStartIndex = startIndices;

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
voltRange = [-5 5];
signalRange = [-0.2 1.2];
pixelRangeX = [0 1024]; % Eye-X
plot(tdtTime,tdtAnalog2Pixels(tdtX,[-5 5],[-0.2 1.2],pixelRangeX),'b','LineWidth',1);
hold on
edfTime = 0:ceil(max(tdtTime));
plot(edfTime,edfX(startIndices(1):startIndices(1)+numel(edfTime)-1),'r','LineWidth',2);
hold on
plot(edfTime,edfX(startIndices(end):startIndices(end)+numel(edfTime)-1),'g','LineWidth',1);
hold on
ylabel('screen pixels');
xlabel('time (ms)');
hold off
legend('tdtData', num2str(startIndices(1),'startIndexfor 60 sec =%d'), num2str(startIndices(end),'startIndex for 120 sec=%d'))




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
   


