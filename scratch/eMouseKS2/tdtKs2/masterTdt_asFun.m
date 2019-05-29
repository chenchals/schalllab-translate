function masterTdt_asFun(sessionDir,probeNum)

% default options are in parenthesis after the comment

useGPU = 1;
percentSamplesToUse = 100;
addpath(genpath('KiloSort')) % path to kilosort folder
addpath(genpath('npy-matlab')) % path to npy-matlab scripts

codeDir = './';%'/home/loweka/code/';
fpath = '/Volumes/scratch/Kaleb-data/dataRaw/';%'/home/loweka/dataRaw/'; % where on disk do you want the simulation? ideally and SSD...
rpath = './test2/dataProcessed/'; % For results
%sessionDir = 'Init_SetUp-160811-145107/';%'Init_SetUp-160715-150111/';

dataPath = [fpath sessionDir '/'];
resultPath = [rpath sessionDir '_probe' num2str(probeNum) '/'];

addpath(genpath([codeDir 'KiloSort'])) % path to kilosort folder
addpath(genpath([codeDir 'npy-matlab'])) % path to npy-matlab scripts

if exist(resultPath, 'dir') ~= 7
    mkdir(resultPath);
end

pathToYourConfigFile = [codeDir 'processTdt/'];
run(fullfile(pathToYourConfigFile, 'configTdt.m'))

ops.chOffset            = 32*(probeNum-1);

tic; % start timer
%
if ops.GPU     
    gpuDevice(1); % initialize GPU (will erase any existing GPU arrays)
end

% if strcmp(ops.datatype , 'sev') && ~exist([ops.fbinary],'file')
%    ops = convertTdtWavSevToRawBinary(ops);  % convert data, only for OpenEphys
% end
%
[rez, DATA, uproj] = preprocessData(ops); % preprocess data and extract spikes for initialization
rez.ops.resultPath = resultPath;

gpuDevice(1);

rez                = fitTemplates(rez, DATA, uproj);  % fit templates iteratively

gpuDevice(1);

rez                = fullMPMU(rez, DATA);% extract final spike times (overlapping extraction)

% AutoMerge. rez2Phy will use for clusters the new 5th column of st3 if you run this)
rez = merge_posthoc2(rez);

% Assign channels to each spike
%rez = timeToChanv2(rez,DATA);


% Make sures spikes are within the data
T=DataAdapter.newDataAdapter('tdt',rez.ops.fbinary);
maxSamples = T.getSampsToRead(ops.Nchan);
goodSpikes = rez.st3(:,1) > (-1*ops.wvWind(1)) & rez.st3(:,1) < (maxSamples-ops.wvWind(end));

% Grab waveforms
rez.waves = nan(size(rez.st3,1),length(ops.wvWind),ops.Nchan);
rez.waves(goodSpikes,:,:) = T.getWaveforms(ops.wvWind,rez.st3(goodSpikes,1),1:ops.Nchan,rez.ops.chOffset);

% save matlab results file
save(fullfile(resultPath,  'rez.mat'), 'rez', '-v7.3');

% save python results file for Phy
rezToPhy(rez, resultPath);

% remove temporary file
delete(ops.fproc);
%%
