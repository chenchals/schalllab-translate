% Modified to use DataAdapter
clear ops
%% Add npy-matlab and Kilosort2 to matlab path
npyMatlabPath = '~/Projects/lab-schall/npy-matlab';
addpath(genpath(npyMatlabPath));
%KS2 path -- also has default waveforms for the simulation
% add Kilosort2 paths to the matlab path
KS2path = '~/Projects/lab-schall/Kilosort2';
if ~contains(matlabpath,'/Kilosort2')
    addpath(KS2path);
    dList = dir(KS2path);
    dList = dList([dList.isdir] & ~contains({dList.name},'.') & ~contains({dList.name},'eMouse'));
    for ii=1:size(dList) 
        addpath(fullfile(KS2path,dList(ii).name))
    end
end

%% Set up directory paths for data files and processed data
basePath = '~/Projects/lab-schall/schalllab-translate/scratch/eMouseKS2';
% path to config file; if running the default config, no need to change.
pathToYourConfigFile = basePath; % path to config file
% Run the configuration file, it builds the structure of options (ops)
%run(fullfile(pathToYourConfigFile, 'config_eMouse_drift_KS2.m'))
run(fullfile(pathToYourConfigFile, 'myEmouseKs2Config.m'))

%% Channel Map file
% default is a small 64 site probe with imec 3A geometry.
if ~isfield(ops,'chanMapFile')
    % where on disk do you want the simulation? ideally an SSD...
    chanMapPath    = [basePath '/drift_simulations/channelMaps/']; 
    if ~exist(chanMapPath, 'dir'); mkdir(chanMapPath); end
    NchanTOT = 64;
    chanMapName = make_eMouseChannelMap_3A_short(chanMapPath, NchanTOT);
    ops.chanMapFile     = fullfile(basePath, chanMapName);
end

ops.chanMap = ops.chanMapFile;
[~,chanMapName] = fileparts(ops.chanMap);
load(ops.chanMap)
NchanTOT = numel(chanMap);
ops.fs = fs;
ops.NchanTOT    = NchanTOT; % total number of channels in your recording

%% path to whitened, filtered proc file (on a fast SSD)
rootH = [basePath '/kilosort_datatemp'];
if ~exist(rootH,'dir'), mkdir(rootH), end
ops.fproc       = fullfile(rootH, 'temp_wh.dat'); % proc file on a fast SSD

%% path to binary data file and results
resultsPath     = [basePath '/drift_simulations/test5/'];
if ~exist(resultsPath,'dir'), mkdir(resultsPath), end
ops.rootZ = resultsPath;
% find the binary data file here
ops.fbinary     = fullfile(basePath, '/drift_simulations/test4',  'sim_binary.imec.ap.bin');

%% Data adapter for reading data
ops.recordingSystem     = 'emouse'; %emouse, tdt
ops.dataAdapter = DataAdapter.newDataAdapter(ops.recordingSystem,ops.fbinary,ops.NchanTOT);

ops.dataTypeBytes       = 2; % datatpe for the sample point -int16=2 4=single
ops.dataTypeString      = 'int16'; % datatype of sample point - 'int16' or 'single'

%% Setup for Matlab for processing
useGPU = 1; % do you have a GPU? Kilosorting 1000sec of 32chan simulated data takes 55 seconds on gtx 1080 + M2 SSD.
useParPool = 1; % use parpool; will speed up simulation if local cluater has > 10 cores.
makeNewData = 0; % set this to 0 to just resort a previously created data set
sortData = 1;
runBenchmark = 1; %set to 1 to compare sorted data to ground truth for the simulation

%% Simulate data, if needed
% This part simulates and saves data. There are many options you can change inside this 
% function, if you want to vary the SNR or firing rates, # of cells, etc.
% There are also parameters to set the amplitude and character of the tissue drift. 
% You can vary these to make the simulated data look more like your data
% or test the limits of the sorting with different parameters.

if( makeNewData )
    make_eMouseData_drift(chanMapPath, KS2path, chanMapName, useGPU, useParPool);
end
%
% Run kilosort2 on the simulated data

if( sortData ) 
   
        % common options for every probe
        gpuDevice(1);   %re-initialize GPU

        % preprocess data to create temp_wh.dat
        rez = preprocessDataKs2(ops);

        % pre-clustering to re-order batches by depth
        rez = clusterSingleBatches(rez);
        
        % main optimization
        % learnAndSolve8;
        rez = learnAndSolve8b(rez);
        
        % final splits
        rez = find_merges(rez, 1);
        

        % final splits by SVD
        rez    = splitAllClusters(rez, 1);
        
        % final splits by amplitudes
        rez = splitAllClusters(rez, 0);
    
        % decide on cutoff
        rez = set_cutoff(rez);
         
        % this saves to Phy
        rezToPhy(rez, resultsPath);

        % discard features in final rez file (too slow to save)
        rez.cProj = [];
        rez.cProjPC = [];
        
        fname = fullfile(resultsPath, 'rezFinal.mat');
        save(fname, 'rez', '-v7.3');
        
        sum(rez.good>0)
        fileID = fopen(fullfile(resultsPath, 'cluster_group.tsv'),'w');
        fprintf(fileID, 'cluster_id%sgroup', char(9));
        fprintf(fileID, char([13 10]));
        for k = 1:length(rez.good)
            if rez.good(k)
                fprintf(fileID, '%d%sgood', k-1, char(9));
                fprintf(fileID, char([13 10]));
            end
        end
        fclose(fileID);
        
        % remove temporary file
        delete(ops.fproc);
end


if runBenchmark
 load(fullfile(resultsPath, 'rezFinal.mat'));
 benchmark_drift_simulation(rez, fullfile(resultsPath, 'eMouseGroundTruth.mat'),...
     fullfile(resultsPath,'eMouseSimRecord.mat'));
end
