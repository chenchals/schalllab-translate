% load edf data
%sessDir = 'data/Leonardo/Eyelink-EDF/Leonardo-180904-105502';
sessDir = 'data/Leonardo/Eyelink-EDF/Leonardo-180907-114555';

edf=load(fullfile(sessDir,'LE180907.mat'));
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

%useDataFrac = [1e-2, 5e-2, 1e-1, 2e-1, 4e-1]';
% 1, 2, 5% of TDT data to use
useDataFrac = [1e-2, 2e-2,5e-2]';

startIndices = nan(numel(useDataFrac),1);
for ii = 1:numel(useDataFrac)
    fprintf('Doing frac %f\n',useDataFrac(ii)); 
    nTdtDataPoints = round(numel(tdtX)*useDataFrac(ii));
    [~, startIndices(ii)] = eyeAlignEdfWithTdt(edfX, tdtX(1:nTdtDataPoints),edfFs,tdtFs,100)
end

t = table();
t.dataFraction = useDataFrac;
t.alignStartIndex = startIndices;

% Plot some data after aligning... not yet hashed out.....
edfRawX = edf.(edfData).FSAMPLE.rx(1,:);

nEdfRaw = (edfRawX - min(edfRawX))./range(edfRawX);
nTdtX = (tdtX - min(tdtX))./range(tdtX);

plot(nEdfRaw(startIndices(3):end));
hold on
plot(tdtTime,nTdtX);
hold off
