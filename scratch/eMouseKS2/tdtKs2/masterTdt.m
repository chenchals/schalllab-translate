function [ ] = masterTdt(baseDataDir, baseResultDir, sessionDir, probeNum)
%MASTERTDT Runs KiloSort on .sev files collected on TDT system
% ***Navigate to KiloSort/CUDA and check that you have run
% ***mexGPUall.n --> you should see (these are GPU compiled files)
%    ***mexMPmuFEAT.mex*
%    ***mexMPregMU.mex*
%    ***mexWtW2.mex*
%
%   Inputs:
%   baseDataDir : Location of raw data raw data files (session dirs).
%                 Ideally SSD
%   baseResultDir : Location for results of KiloSort. New
%                   [baseResultDir/sessionDir] directory is created if not exist.
%
%   Dependencies:
%   KiloSort :
%   npy-matlab :
%
%  Schall Lab, Department of Psychology, Vanderbilt University

[ pathToConfigFile ] = addCodePaths();
dataPath = fullfile(baseDataDir, sessionDir, filesep);
probe = ['probe_' num2str(probeNum,'%02d') filesep];
sessionDir = fullfile(baseResultDir, sessionDir, filesep);
probeDir = fullfile(sessionDir, probe, filesep);

%% Setup vars used to update configTdt.m
% running configTdt.m creates the structured variable ops
run(fullfile(pathToConfigFile, 'configTdt.m'))
% Conserve inputs
ops.baseDataDir         = baseDataDir;
ops.baseResultDir       = baseResultDir;
ops.session             = sessionDir;
ops.probeDir            = probeDir;
% Reassign vars - make this explicit here
ops.GPU                 = 1; %useGPU; % whether to run this code on an Nvidia GPU (much faster, mexGPUall first)		
ops.percentSamplesToUse = 5;
ops.nSpikesPerBatch     = 4000;
ops.showfigures         = 0;		
ops.wvWind              = -25:25;
ops.fbinary             = dataPath;
% residual from RAM of preprocessed data
ops.fproc               = fullfile(probeDir, 'temp_wh.dat');	
ops.root                = baseDataDir;		
% define the channel map as a filename (string) or simply an array
ops.Nchan               = 32;
ops.chOffset            = ops.Nchan*(probeNum-1);
% treated as linear probe if unavailable chanMap file	
% 1:ops.Nchan; 
ops.chanMap = fullfile(pathToConfigFile, 'tdtChanMap');
% samples of symmetrical buffer for whitening and spike detection
ops.ntbuff              = 64;
% int16 scaling of whitened data
ops.scaleproc           = 1; 
% This is the batch size (try decreasing if out of memory) 	
% For GPU should be multiple of 32 + ntbuff
% 128*1024+ ops.ntbuff; 16*512*1024
ops.NT                  = 128*1024 + ops.ntbuff;

%% Start KiloSort Processing
if exist(probeDir, 'dir') ~= 7
    mkdir(probeDir);
end
% start timer
tic;
% initialize GPU (will erase any existing GPU arrays)
if ops.GPU
    gpuDevice(1);
end

[rez, DATA, uproj] = preprocessData(ops); % preprocess data and extract spikes for initialization
rez.ops.resultPath = probeDir;

gpuDevice(1);

rez = fitTemplates(rez, DATA, uproj); % fit templates iteratively

gpuDevice(1);

rez = fullMPMU(rez, DATA);% extract final spike times (overlapping extraction)

% AutoMerge. rez2Phy will use for clusters the new 5th column of st3 if you run this)
rez = merge_posthoc2(rez);

% Make sures spikes are within the data
T = DataAdapter.newDataAdapter('tdt',rez.ops.fbinary);
maxSamples = T.getSampsToRead(ops.Nchan);
goodSpikes = rez.st3(:,1) > (-1*ops.wvWind(1)) & rez.st3(:,1) < (maxSamples-ops.wvWind(end));

% Grab waveforms
rez.waves = nan(size(rez.st3,1),length(ops.wvWind),ops.Nchan);
rez.waves(goodSpikes,:,:) = T.getWaveforms(ops.wvWind,rez.st3(goodSpikes,1),1:ops.Nchan,rez.ops.chOffset);

% save matlab results file
save(fullfile(probeDir, 'rez.mat'), 'rez', '-v7.3');

% save python results file for Phy
rezToPhy(rez, probeDir);

% remove temporary file
delete(ops.fproc);

% Close all open file handles
fclose('all');
end

%%
function [masterTdtPath] = addCodePaths()
    masterTdtPath = fileparts(mfilename('fullpath'));
    % Directory containing: KiloSort, npy-matlab folders
    codeDir = regexp(masterTdtPath,'^(.*)/\w+$','tokens');
    codeDir = [char(codeDir{:}) filesep];
    % Add path to kilosort folder
    addpath(genpath([codeDir 'KiloSort']))
    % path to npy-matlab folder
    addpath(genpath([codeDir 'npy-matlab']))
end
