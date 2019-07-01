%% Path Configuration
projectPath = '~/Projects/lab-schall/schalllab-translate';
npyMatlabPath = '~/Projects/lab-schall/npy-matlab/npy-matlab';
kilosortPath = '~/Projects/lab-schall/MyKilosort2';
% will be already in path: lok: toolbox/spk-cluster/channelMaps
chanMapFilename='linear-probes-1-16-chan-150mu.mat';
% SSD drive
% in cmdBinaryRepo/[session] files: are countermanding files
ksConfigFile = fullfile(projectPath,'scratch/tdtKs2/myTdtConfig.m');
dataPath = '/scratch/ksData/Joule/cmanding/ephys/TESTDATA';
resultsBasePath = '/scratch/ksDataProcessed/Joule/cmanding/ephys/TESTDATA';

%% Setup for Matlab for processing
% Add npy-matlab and Kilosort2 to matlab path
addKilosort2NpyPaths(kilosortPath,npyMatlabPath);
sessions = dir(fullfile(dataPath,'Joule*'));
%% use ksBinaryFormat
useKsBinaryFormat = false;
%% Process..for each session.....
for jj = 1:1 %numel(sessions)
    try
    % Read config file
    % Run the configuration file, it builds the structure of options (ops)
    run(ksConfigFile)
    ops.fig = 0;
    % we need Total number of channels recorded for reading the binary file.
    % This will remain the same after ops.chanMap file is read/loaded
    ops.NchanTOT = 16;
    ops.channelOffset = 0;
    ops.dataSession = sessions(jj).name;
    sessionFile = sessions(jj).name;
    if useKsBinaryFormat
        ops.recordingSystem   = 'bin'; %emouse:bin, tdt:sev
        ops.dataSessionFile = fullfile(dataPath,...
                               ops.dataSession,...
                               [ops.dataSession '_RSn1.bin']);
        ops.rawDataMultiplier = 1; % Ensure raw values are in uV
        ops.resultsPhyPath = fullfile(resultsBasePath, ops.dataSession, 'phyRSn1Bin');
    else % use tdtd format sev files
        ops.recordingSystem   = 'sev'; %emouse:bin, tdt:sev
        ops.dataSessionFile = fullfile(dataPath,...
                               ops.dataSession,...
                               '*_Wav1_*.sev');
        ops.rawDataMultiplier = 1E3; % Ensure raw values are in uV
        ops.resultsPhyPath = fullfile(resultsBasePath, ops.dataSession, 'phy');
    end
    % Modified to use DataAdapter
    % Results / output dir / files
    if ~exist(ops.resultsPhyPath ,'dir')
        mkdir(ops.resultsPhyPath );
    end
    diary(fullfile(ops.resultsPhyPath,'console_output.txt'));
    tic
    fprintf('Processing binary file: %s output fir: %s ...\n',...
        ops.dataSessionFile, ops.resultsPhyPath);
    % from here all ops are as per Kilosort2
    ops.chanMap = chanMapFilename;
    ops.rootZ = ops.resultsPhyPath;
    % path to whitened filtered proc, after processing this file is deleted
    ops.fproc = fullfile(ops.resultsPhyPath,'temp_wh.dat');
    rez = myMasterTdt(ops);
    clear ops rez
    toc

    catch ME
        disp(getReport(ME,'extended'));
    end
    diary off
end
