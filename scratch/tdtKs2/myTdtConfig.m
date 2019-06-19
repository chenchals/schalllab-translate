%% Paths
ops.fig = 0;
projectPath = '~/Projects/lab-schall/schalllab-translate';
% SSD drive
%%
ops.dataPath = '/scratch/ksData/TESTDATA';
resultsBasePath = '/scratch/ksDataProcessed/TESTDATA';
% in TESTDATA/[session] files:
% Init_SetUp-160715-150111 : 2-probes(32 chans each);
%         use for ops.chanMapName: 'linear-probes-2-32-chan-150mu.mat'
% Init_SetUp-160811-145107 : 1-probes(32 chans each);
%         use for ops.chanMapName: 'linear-probes-1-32-chan-150mu.mat'
ops.dataSession = 'Init_SetUp-160715-150111';
ops.rawDataMultiplier = 1E6; % Ensuve raw values are in uV
nchansForWhitening = 1;
%%
% Data session / file
% in Joule/cmanding/ephys/TESTDATA/[session]/ files:
% Joule-190510-111052 *only* Lfp1
%         use for ops.chanMapName: 'linear-probes-1-16-chan-150mu.mat'
% Joule-190513-110456 *raw* RSn1, Wav1, Lfp1, and others 
% Joule-190517-111405 *only* RSn1
% Joule-190517-113527 Wav1, Lfp1, and others
% 
%  ops.dataPath = '/scratch/ksData/Joule/cmanding/ephys/TESTDATA';
%  resultsBasePath = '/scratch/ksDataProcessed/Joule/cmanding/ephys/TESTDATA';
%  ops.dataSession = 'Joule-190517-113527';
%  ops.rawDataMultiplier = 1E6; % For TDT simulator values range form -5 - +5 (volts?)...??
%  nchansForWhitening = 1;
%% Channel map file
ops.chanMapPath = fullfile(projectPath,'toolbox/spk-cluster/channelMaps');
ops.chanMapName='linear-probes-2-32-chan-150mu.mat';

% Results / output dir / files
ops.resultsPhyPath = fullfile(resultsBasePath, ops.dataSession, 'phy');
ops.resultsMatPath = fullfile(resultsBasePath, ops.dataSession);
% path to whitened filtered proc, after processing this file is deleted
ops.fproc = fullfile(ops.resultsPhyPath,'temp_wh.dat');
% Extract results as different channel files with names containg
% DSP01a,...,DSP32d.. that has spike times, waveforms etc vars
ops.resultsExtractChannels = 1;
%% Processing setup
% Modified to use DataAdapter
ops.recordingSystem     = 'tdt'; %emouse, tdt
% the raw file where waveforms for each channel is stored
% example file: CMD_TSK_029_EphysMulti-190510-092724_Joule-190517-113527_Wav1_Ch14.sev
ops.sevFilenamePart = '_Wav1_';% '_Wav1_';
% sampling rate
ops.fs = 24414;

% time range in seconds of data to process
% TIME RANGE IN SECONDS TO PROCESS
%ops.trange      = [0 60]; 
ops.trange      = [0 60];

% sorting type ...??
ops.sorting     = 1; % type of sorting, 2 is by rastermap, 1 is old

% frequency for high pass filtering (150)
ops.fshigh = 300;
% low frquency, if we need bandpass filtering
ops.fslow = 5000;

% minimum firing rate on a "good" channel (0 to skip)
ops.minfr_goodchannels = 0.1; %0.1;

% the following options can improve/deteriorate results. 		
% when multiple values are provided for an option, the first two are beginning and ending anneal values, 		
% the third is the value used in the final pass. 
ops.nfullpasses = 6;
ops.nannealpasses    = 4;            % should be less than nfullpasses (4)		

% threshold on projections (like in Kilosort1, can be different for last pass like [10 4])
% threshold for detecting spikes on template-filtered data ([6 12 12]) (KS1)
ops.Th = [6 12]; %[10 4];

% how important is the amplitude penalty (like in Kilosort1, 0 means not used, 10 is average, 50 is a lot)
 % large means amplitudes are forced around the mean ([10 30 30]) (KS1)
ops.lam = [10 30];

% splitting a cluster at the end requires at least this much isolation for each sub-cluster (max = 1)
ops.AUCsplit = 0.9;

% minimum spike rate (Hz), if a cluster falls below this for too long it gets removed
ops.minFR = 1/50;

% number of samples to average over (annealed from first to second value)
ops.momentum = 1./[20 400];

% spatial constant in um for computing residual variance of spike
% KS1: ops.maskMaxChannel, computes nearest neighbors
ops.sigmaMask = 30;% channel spacing? 

% threshold crossings for pre-clustering (in PCA projection space)
ops.ThPre = 8;
%% danger, changing these settings can lead to fatal errors
% options for determining PCs
ops.spkTh           = -4;      % spike threshold in standard deviations (-6)
ops.reorder         = 1;       % whether to reorder batches for drift correction.
ops.nskip           = 1;  % how many batches to skip for determining spike PCs

ops.GPU                 = 1; % has to be 1, no CPU version yet, sorry;  whether to run this code on an Nvidia GPU (much faster, mexGPUall first)
ops.nfilt_factor        = 4; % max number of clusters per good channel (even temporary ones)
ops.ntbuff              = 64;    % samples of symmetrical buffer for whitening and spike detection
ops.NT                  = 32*1024 + ops.ntbuff; % must be multiple of 32 + ntbuff. This is the batch size (try decreasing if out of memory).
ops.whiteningRange      = nchansForWhitening; % number of channels to use for whitening each channel
ops.nSkipCov            = 1; %5; % compute whitening matrix from every N-th batch
ops.scaleproc           = 1; % int16 scaling of whitened data
ops.nPCs                = 3; % how many PCs to project the spikes into
ops.useRAM              = 0; % not yet available

%%