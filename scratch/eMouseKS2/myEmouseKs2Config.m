% Modified to use DataAdapter
clear ops

% data paths
basePath =  '~/Projects/lab-schall/schalllab-translate/scratch/eMouseKS2'; % root dir for processed files
% This will be the session path for processed data also
fpath    = [basePath '/drift_simulations/test/']; % where on disk do you want the simulation? ideally an SSD...
% only for generating simulated data
if ~exist(fpath, 'dir'); mkdir(fpath); end

ops.root                = fpath; % 'openEphys' only: where raw files are
ops.datatype            = 'dat';  % binary ('dat', 'bin') or 'openEphys'
ops.fbinary             = fullfile(fpath, 'sim_binary.imec.ap.bin'); % will be created for 'openEphys'
ops.fproc               = fullfile(fpath, 'temp_wh.dat'); % residual from RAM of preprocessed data

% define the channel map as a filename (string) or simply an array
ops.chanMap               = fullfile(ops.root, 'chanMap_3A_64sites.mat'); % make this file using make_eMouseChannelMap_3A_short.m
% ops.chanMap             = 'D:\GitHub\KiloSort2\configFiles\neuropixPhase3A_kilosortChanMap.mat';
% ops.chanMap = 1:ops.Nchan; % treated as linear probe if no chanMap file

ops.recordingSystem     = 'emouse'; %emouse, tdt

ops.dataTypeBytes       = 2; % datatpe for the sample point -int16=2 4=single
ops.dataTypeString      = 'int16'; % datatype of sample point - 'int16' or 'single'
ops.percentSamplesToUse = 20; %percentSamplesToUse ; % of data per channel to use. useful for troubleshooting purposes

% for ops.GPU see below, no CPU sopport for KS2
ops.parfor              = 1; % whether to use parfor to accelerate some parts of the algorithm
ops.verbose             = 1; % whether to print command line progress
ops.showfigures         = 1; % whether to plot figures during optimization


% sampling rate
ops.fs = 30000;

% frequency for high pass filtering (150)
ops.fshigh = 150;
% low frquency, if we need bandpass filtering
% ops.fslow = 0.1;

% minimum firing rate on a "good" channel (0 to skip)
ops.minfr_goodchannels = 0.1;

% the following options can improve/deteriorate results. 		
% when multiple values are provided for an option, the first two are beginning and ending anneal values, 		
% the third is the value used in the final pass. 		
ops.nannealpasses    = 4;            % should be less than nfullpasses (4)		

% threshold on projections (like in Kilosort1, can be different for last pass like [10 4])
% threshold for detecting spikes on template-filtered data ([6 12 12]) (KS1)
ops.Th = [10 4];

% how important is the amplitude penalty (like in Kilosort1, 0 means not used, 10 is average, 50 is a lot)
 % large means amplitudes are forced around the mean ([10 30 30]) (KS1)
ops.lam = 10;

% splitting a cluster at the end requires at least this much isolation for each sub-cluster (max = 1)
ops.AUCsplit = 0.9;

% minimum spike rate (Hz), if a cluster falls below this for too long it gets removed
ops.minFR = 1/50;

% number of samples to average over (annealed from first to second value)
ops.momentum = [20 400];

% spatial constant in um for computing residual variance of spike
% KS1: ops.maskMaxChannel, computes nearest neighbors
ops.sigmaMask = 30;

% threshold crossings for pre-clustering (in PCA projection space)
ops.ThPre = 8;
%% danger, changing these settings can lead to fatal errors
% options for determining PCs
ops.spkTh           = -6;      % spike threshold in standard deviations (-6)
ops.reorder         = 1;       % whether to reorder batches for drift correction.
ops.nskip           = 25;  % how many batches to skip for determining spike PCs

ops.GPU                 = 1; % has to be 1, no CPU version yet, sorry;  whether to run this code on an Nvidia GPU (much faster, mexGPUall first)
% ops.Nfilt               = 1024; % max number of clusters
ops.nfilt_factor        = 4; % max number of clusters per good channel (even temporary ones)
ops.ntbuff              = 64;    % samples of symmetrical buffer for whitening and spike detection
ops.NT                  = 64*1024+ ops.ntbuff; % must be multiple of 32 + ntbuff. This is the batch size (try decreasing if out of memory).
ops.whiteningRange      = 32; % number of channels to use for whitening each channel
ops.nSkipCov            = 25; % compute whitening matrix from every N-th batch
ops.scaleproc           = 200;   % int16 scaling of whitened data
ops.nPCs                = 3; % how many PCs to project the spikes into
ops.useRAM              = 0; % not yet available

%%