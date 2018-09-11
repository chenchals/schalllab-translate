% load edf data
%sessDir = 'data/Leonardo/Eyelink-EDF/Leonardo-180904-105502';
% sessDir = 'data/Leonardo/Eyelink-EDF/Leonardo-180910-112920';
% edf=load(fullfile(sessDir,'LE180910.mat'));
% 
% sessDir = 'data/Leonardo/Eyelink-EDF/Leonardo-180910-120113';
% edf=load(fullfile(sessDir,'LE180910.mat'));
% large session
sessDir = 'data/Leonardo/Eyelink-EDF/Leonardo-180910-122025';
%edf=load(fullfile(sessDir,'LE180910.mat'));
edf=load(fullfile(sessDir,'dataEDF.mat'));

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
slidingWinList = [10 20 30 60 100 200]';
% do classic way that is slide one vector over other....
for ii = 1:numel(slidingWinList)
    fprintf('Doing %d secs sliding window\n',slidingWinList(ii));
    [edfVec{ii,1}, startIndices(ii,1)] = eyeAlignEdfWithTdt(edfX, tdtX,edfFs,tdtFs,slidingWinList(ii));
end

t = table();
t.slidingWinList = slidingWinList;
t.alignStartIndex = startIndices;

% Do using xcorr function
[xcorrEdfVec,xcorrStartIndex] = eyeAlignEdfWithTdt(edfX, tdtX,edfFs,tdtFs);

% Plot some data after aligning... not yet hashed out.....
edfStartIndex = startIndices(end);
voltRange = [-5 5];
signalRange = [-0.2 1.2];
pixelRangeX = [0 1024]; % Eye-X
plot(tdtTime,tdtAnalog2Pixels(tdtX,[-5 5],[-0.2 1.2],pixelRangeX),'b');
hold on
edfTime = 0:ceil(max(tdtTime));
plot(edfTime,edfX(edfStartIndex:edfStartIndex+numel(edfTime)-1),'r');
hold on
ylabel('screen pixels');
xlabel('time (ms)');
hold off

