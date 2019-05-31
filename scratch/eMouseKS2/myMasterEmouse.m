% Modified to use DataAdapter
clear ops
projectPath = '~/Projects/lab-schall/schalllab-translate';
session = 'scratch/eMouseKS2';
%% Add npy-matlab and Kilosort2 to matlab path
npyMatlabPath = '~/Projects/lab-schall/npy-matlab/npy-matlab';
%KS2 path -- also has default waveforms for the simulation
% add Kilosort2 paths to the matlab path
kilosortPath = '~/Projects/lab-schall/Kilosort2';
addKilosort2NpyPaths(kilosortPath,npyMatlabPath);

%% Setup for Matlab for processing
useGPU = 1; % do you have a GPU? Kilosorting 1000sec of 32chan simulated data takes 55 seconds on gtx 1080 + M2 SSD.
useParPool = 1; % use parpool; will speed up simulation if local cluater has > 10 cores.
makeNewChanMapFile = 0; % set this to 0 to use existing channel map file, 1 to overwrite
makeNewData = 1; % set this to 0 to just resort a previously created data set, 1 to overwrite
sortData = 1;
runBenchmark = 1; %set to 1 to compare sorted data to ground truth for the simulation

%% Read config file for Kilosort processing information / instructions
% path to config file
ksConfigFile = fullfile(projectPath,session, 'myEmouseConfig.m');
% Run the configuration file, it builds the structure of options (ops)
run(ksConfigFile)

%% Check existence of fields for directory paths and/or files
% check if channel map file vars exists
assert(isfield(ops,'chanMapPath') && isfield(ops,'chanMapName'),...
    'ErrorInConfig: Config file does not contain ops.chanMapPath and/or ops.chanMapName');
% check eMouse simulated data file vars exists
assert(isfield(ops,'dataPath') && isfield(ops,'dataSession') && isfield(ops,'dataSessionFile'),...
    'ErrorInConfig: Config file does not contain ops.dataPath and/or ops.dataSession  and/or ops.dataSessionFile');
% check eMouse simulated data groundtruth file vars exists
assert(isfield(ops,'groundTruthFile') && isfield(ops,'simulationRecordFile'),...
    'ErrorInConfig: Config file does not contain ops.groundTruthFile and/or ops.simulationRecordFile');
% check results paths (rez is saved as python files as well as .mat file) 
assert(isfield(ops,'resultsPhyPath') && isfield(ops,'resultsMatPath'),...
    'ErrorInConfig: Config file does not contain ops.resultsPhyPath and/or ops.resultsMatPath');

%% Check Channel Map paths / files exist
chanMapFile = fullfile(ops.chanMapPath,ops.chanMapName);
if makeNewChanMapFile
    if ~exist(ops.chanMapPath, 'dir'); mkdir(ops.chanMapPath); end %#ok<UNRCH>
    % FIXED ? 
    NchanTOT = 64;
    chanMapName = myMakeEmouseChannelMap(ops.chanMapPath, NchanTOT);
    ops.chanMapName = chanMapName;
else % ops.chanMapFile
    assert(exist(chanMapFile,'file')==2, sprintf(['ErrorInConfig: File not found, channel map file [%s].\n' ...
        'Check values for ops.chanMapPath, ops.chanMapName in config file [%s]'],chanMapFile,ksConfigFile));
end
ops.chanMapFile = fullfile(ops.chanMapPath,ops.chanMapName);
ops.chanMap = ops.chanMapFile;
%% Check source data directory / files exists or simulate for eMouse
if makeNewData
% Simulate data, if needed
% This part simulates and saves data. There are many options you can change inside this 
% function, if you want to vary the SNR or firing rates, # of cells, etc.
% There are also parameters to set the amplitude and character of the tissue drift. 
% You can vary these to make the simulated data look more like your data
% or test the limits of the sorting with different parameters.
    simDataPath = fileparts(ops.dataSessionFile);
    if ~exist(simDataPath, 'dir'); mkdir(simDataPath); end
    [ops.dataSessionFile,ops.groundTruthFile,ops.simulationRecordFile] ...
        = myMakeEmouseData(simDataPath,kilosortPath,ops.chanMapFile,useGPU,useParPool);
else
    assert(exist(ops.dataSessionFile,'file')==2 && ...
           exist(ops.groundTruthFile,'file')==2 && ...
           exist(ops.simulationRecordFile,'file')==2, ...
           sprintf(['ErrorInConfig: File(s) not found:\nops.dataSessionFile [%s]\n'...
                    'ops.groundTruthFile [%s]\nops.simulationRecordFile [%s].\n'...
                    ' Check their values in config file [%s]'],ops.dataSessionFile,...
                    ops.groundTruthFile,ops.simulationRecordFile,ksConfigFile)); %#ok<UNRCH>
end
ops.fbinary = ops.dataSessionFile;

%% Check and create results directory(ies)
if ~exist(ops.resultsMatPath,'dir'); mkdir(ops.resultsMatPath); end
if ~exist(ops.resultsPhyPath,'dir'); mkdir(ops.resultsPhyPath); end
ops.rootZ = ops.resultsPhyPath;
resultsPhyPath = ops.rootZ;
resultsMatPath = ops.resultsMatPath;

%% Channel Map file
useChanMap = fullfile(ops.resultsMatPath,ops.chanMapName);
copyfile(ops.chanMapFile, useChanMap,'f');
ops.chanMapUsed = useChanMap;
load(ops.chanMap)
NchanTOT = numel(chanMap);
ops.fs = fs;
ops.NchanTOT = NchanTOT; % total number of channels in your recording

%% Data adapter for reading data
if strcmp(ops.recordingSystem,'emouse') %emouse, tdt
    ops.dataAdapter = DataAdapter.newDataAdapter(ops.recordingSystem,ops.fbinary,ops.NchanTOT);
    ops.dataTypeBytes       = 2; % datatpe for the sample point -int16=2 4=single
    ops.dataTypeString      = 'int16'; % datatype of sample point - 'int16' or 'single'
end



%% Run kilosort2 on the simulated data
if( sortData ) 
   
        % common options for every probe
        gpuDevice(1);   %re-initialize GPU

        % preprocess data to create temp_wh.dat
        rez = clusterWithKilosort(ops);

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
        rezToPhy(rez, resultsPhyPath);

        % discard features in final rez file (too slow to save)
        rez.cProj = [];
        rez.cProjPC = [];
        
        fname = fullfile(resultsMatPath, 'rezFinal.mat');
        save(fname, 'rez', '-v7.3');
        
        sum(rez.good>0)
        fileID = fopen(fullfile(resultsPhyPath, 'cluster_group.tsv'),'w');
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
 load(fullfile(resultsMatPath, 'rezFinal.mat'));
 benchmark_drift_simulation(rez, ops.groundTruthFile,ops.simulationRecordFile);
end
