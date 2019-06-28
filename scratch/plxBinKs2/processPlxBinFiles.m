%% Path Configuration
projectPath = '~/Projects/lab-schall/schalllab-translate';
npyMatlabPath = '~/Projects/lab-schall/npy-matlab/npy-matlab';
kilosortPath = '~/Projects/lab-schall/MyKilosort2';
% will be already in path: lok: toolbox/spk-cluster/channelMaps
chanMapFilename='linear-probes-1-24-chan-150mu-40KFs.mat';
% SSD drive
% in cmdBinaryRepo/[session] files: are countermanding files
ksConfigFile = fullfile(projectPath,'scratch/plxBinKs2/myPlxBinConfig.m');
dataPath = '/scratch/Chenchal/cmdBinaryRepo';
resultsBasePath = '/scratch/ksDataProcessed/cmdBinaryRepo';

%% Setup for Matlab for processing
% Add npy-matlab and Kilosort2 to matlab path
addKilosort2NpyPaths(kilosortPath,npyMatlabPath);
% get sessions...(only binary files, int16, )
sessions = dir(fullfile(dataPath,'*.bin'));
sessions([sessions.bytes]==0)=[];
%% Process..for each session.....
for jj = 1:numel(sessions)
    try
    % Read config file
    % Run the configuration file, it builds the structure of options (ops)
    run(ksConfigFile)
    ops.fig = 0;
    % we need Total number of channels recorded for reading the binary file.
    % This will remain the same after ops.chanMap file is read/loaded
    ops.NchanTOT = 24;
    ops.channelOffset = 0;
    sessionFile = sessions(jj).name;
    [~,ops.dataSession] = fileparts(sessionFile);
    ops.dataSessionFile = fullfile(dataPath,sessionFile);
    ops.resultsPhyPath = fullfile(resultsBasePath, ops.dataSession, 'phy');
    % Modified to use DataAdapter
    ops.recordingSystem     = 'bin'; %emouse:bin, tdt:sev
    ops.rawDataMultiplier = 1; % Ensure raw values are in uV
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
    rez = myMasterPlxBin(ops);
    clear ops rez
    toc

    catch ME
        disp(getReport(ME,'extended'));
    end
    diary off
end



