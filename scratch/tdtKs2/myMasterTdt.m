% Modified to use DataAdapter
clear ops
projectPath = '~/Projects/lab-schall/schalllab-translate';
configPath = 'scratch/tdtKs2';
%% Add npy-matlab and Kilosort2 to matlab path
npyMatlabPath = '~/Projects/lab-schall/npy-matlab/npy-matlab';
%KS2 path -- also has default waveforms for the simulation
% add Kilosort2 paths to the matlab path
kilosortPath = '~/Projects/lab-schall/MyKilosort2';
addKilosort2NpyPaths(kilosortPath,npyMatlabPath);

%% Setup for Matlab for processing
useGPU = 1; % do you have a GPU? Kilosorting 1000sec of 32chan simulated data takes 55 seconds on gtx 1080 + M2 SSD.
useParPool = 1; % use parpool; will speed up simulation if local cluster has > 10 cores.
sortData = 1;

%% Read config file for Kilosort processing information / instructions
% path to config file
ksConfigFile = fullfile(projectPath,configPath, 'myTdtConfig.m');
% Run the configuration file, it builds the structure of options (ops)
run(ksConfigFile)

%% Check existence of fields for directory paths and/or files
% check if channel map file vars exists
assert(isfield(ops,'chanMapPath') && isfield(ops,'chanMapName'),...
    'ErrorInConfig: Config file does not contain ops.chanMapPath and/or ops.chanMapName');
% check session data file vars exists
assert(isfield(ops,'dataPath') && isfield(ops,'dataSession'),...
    'ErrorInConfig: Config file does not contain ops.dataPath and/or ops.dataSession');
% check results paths (rez is saved as python files as well as .mat file) 
assert(isfield(ops,'resultsPhyPath') && isfield(ops,'resultsMatPath'),...
    'ErrorInConfig: Config file does not contain ops.resultsPhyPath and/or ops.resultsMatPath');

%% Check Channel Map paths / files exist
chanMapFile = fullfile(ops.chanMapPath,ops.chanMapName);
assert(exist(chanMapFile,'file')==2, sprintf(['ErrorInConfig: File not found, channel map file [%s].\n' ...
    'Check values for ops.chanMapPath, ops.chanMapName in config file [%s]'],chanMapFile,ksConfigFile));

ops.chanMapFile = fullfile(ops.chanMapPath,ops.chanMapName);
ops.chanMap = ops.chanMapFile;
%% Check source data directory / files exists for tdt data
assert(isfield(ops,'recordingSystem') && isfield(ops,'sevFilenamePart'),...
    'ErrorInConfig: Config file does not contain ops.recordingSystem and/or ops.sevFilenamePart');
ops.rawFilePattern = fullfile(ops.dataPath, ops.dataSession,['*' ops.sevFilenamePart '*.sev']);
d = dir(ops.rawFilePattern);
assert(sum(contains({d.name},'_Wav1_'))>0,...
    sprintf('ErrorInConfig: Waveform/raw data files not found. Searched pattern [%s]', ops.rawFilePattern));
    
% used for call to DataAdapter
ops.fbinary = ops.rawFilePattern;

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
if strcmp(ops.recordingSystem,'tdt') %emouse, tdt
    ops.dataAdapter = DataAdapter.newDataAdapter(ops.recordingSystem,ops.fbinary);
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
% NA for TDT data
%if runBenchmark
% load(fullfile(resultsMatPath, 'rezFinal.mat'));
% benchmark_drift_simulation(rez, ops.groundTruthFile,ops.simulationRecordFile);
%end
