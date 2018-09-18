function [trialEyes] = tdtExtractEyes(sessionDir, trialStartTimes)
%TDTEXTRACTEYES Extract Eye data from TDT. If file [SESSION_NAME]_EDF.mat
%               is present in the sessionDir, align TDT Eye data with EDF
%               eye data and cut it into trials. 
%
%   sessionDir: Location of TDT data files [and EDF data file translated
%               to .mat file see EDF-File* below] are saved 
%   trialStartTimes: [nx1] double vector of trial Start times [NaN ok]
%                    The Task.TrialStart_ vector, got by running
%                    tdtExtractEvents
%   EDF-File*: To use EDF data all of the followig had to be done: 
%              (a) Save eye data on Eyelink 
%              (b) Translate edf data to mat (see Edf2Mat
%                      https://github.com/uzh/edf-converter) 
%              (c) EDF mat full filepath sessionDir/dataEDF.mat
%          
%   **********ASSUMPTIONS of EDF file collection*********
%   Absolute time: ------------------------------------------------------->
%        EDF data: Start|---------------------------------------------|Stop
%        TDT data:       Start|----------------------------------|Stop
%      TEMPO data:             Start|-----------------------|Stop
%
%  TDT-Eye-data-Total-Time a subset of EDF-Eye-data-Total-Time
%
% Example: For using EDF data file:
%    Start to save data on Eyelink
%      Start TDT/Synapse
%         Start TEMPO
%           ....experiment running....
%         Stop TEMPO
%      Stop TDT/Synapse
%    Start saving data on Eyelink
%    Transfer the EDF file from Eyelink computer to the [loc-of-sessionDir]
%    and run Edf2Mat of the edf file.  Rename the converted file to
%    [SESSION_NAME]_EDF.mat
%
%    [trialEyes] = tdtExtractEyes(sessionDir, trialStartTimes)
% See also TDTEXTRACTEVENTS, TDTALIGNEYEWITHEDF

    % Normalize input path and extract sessionName
    blockPath = regexprep(sessionDir,'[/\\]',filesep);
    binsForTdtMovingAverage = 1; % no moving average
    maxTdtStartDelay = 100; % in seconds

    %% Function to parse data vector to trials omit 1st and last trial
    nTrials = numel(trialStartTimes);
    splitEyeDataIntoTrialsFx = @(eyeVec,timeBins)...
        [NaN;...
        arrayfun(@(ii) eyeVec(timeBins(ii):timeBins(ii+1)-1),(2:nTrials-1)','UniformOutput',false);...
        NaN];
    
    %% Initialize output
    trialEyes = struct();

    %% Read TDT Eye data
    fprintf('Reading TDT Eye Data...\n');
    [tdtX, tdtY, tdtFsHz, tdtStartTime] = getTdtEyeData(blockPath);
    tdtBinWidthMs = 1000/tdtFsHz;
    
    %% Parse TDT eye date into trials (before doing EDF), in case there is no EDF file
    trialStartTable = table();
    trialStartTable.trialStartMsFractional=trialStartTimes;
    trialStartTable.trialStartMs=round(trialStartTimes);
    trialStartTable.trialDurationMsFractional=[diff(trialStartTable.trialStartMsFractional);NaN];
    trialStartTable.trialDurationMs=round(trialStartTable.trialDurationMsFractional);
    trialStartTable.tdtTrialStartBinFractional=trialStartTable.trialStartMsFractional./tdtBinWidthMs;
    trialStartTable.tdtTrialStartBin=round(trialStartTable.trialStartMsFractional./tdtBinWidthMs);
        
    trialEyes.tdtEyeX = splitEyeDataIntoTrialsFx(tdtX,trialStartTable.tdtTrialStartBin);
    trialEyes.tdtEyeY = splitEyeDataIntoTrialsFx(tdtY,trialStartTable.tdtTrialStartBin);
    
    trialEyes.trialTimeTable = trialStartTable;
    trialEyes.tdt.sessionDir = blockPath;
    trialEyes.tdt.StartTime = tdtStartTime;
    trialEyes.tdt.FsHz = tdtFsHz;
    trialEyes.tdt.BinWidthMs = tdtBinWidthMs;
    trialEyes.tdt.EyeDataBins = numel(tdtX);

    trialEyes.DEFINITIONS = addDefinitions(trialEyes);
    
    %% If Eyelink translated data is present 
    %  Align TDT Eye data with Eyelink eye data and parse into trials
    fprintf('Reading EDF Eye Data...\n');
    edfMatFile = fullfile(sessionDir, 'dataEDF.mat');
    if ~exist(edfMatFile, 'file')
        warning('EDF Eye Data File [%s] not found.', edfMatFile);
        return;
    end
    edfDataField = 'dataEDF';
    edf = load(edfMatFile);
    edfX = edf.(edfDataField).FSAMPLE.gx(1,:);
    edfY = edf.(edfDataField).FSAMPLE.gy(1,:);
    edfFsHz = 1000;
    edfBinWidthMs = 1000/edfFsHz;
    
    %% Clean EDF eye data
    fprintf('Cleaning EDF Eye Data...\n');
    MISSING_DATA_VALUE  = -32768;
    EMPTY_VALUE         = 1e08;
    edfX = replaceValue(edfX,MISSING_DATA_VALUE,nan);
    edfX = replaceValue(edfX,EMPTY_VALUE,nan);
    edfY = replaceValue(edfY,MISSING_DATA_VALUE,nan);
    edfY = replaceValue(edfY,EMPTY_VALUE,nan);
    
    %% Align start of tdt (Eye) recording with the start in EDF recording
    slidingWindowSecs = round(linspace(0,maxTdtStartDelay,4));
    slidingWindowSecs = slidingWindowSecs(2:end);
    edfDataChunk = 2*maxTdtStartDelay*1000; % Twice the max delay bins
    tdtDataChunk = 0.1*edfDataChunk; % 10% of no of edfBins
    fprintf('Finding start index for aligning EDF Eye Data to start of TDT Eye data...\n');
    partialEdf = edfX(1:edfDataChunk); 
    partialTdt = tdtX(1:tdtDataChunk);        
    startIndices = findAlignmentIndices(partialEdf,partialTdt,binsForTdtMovingAverage,edfFsHz,tdtFsHz,slidingWindowSecs);
    
    %% Align end of tdt (Eye) recording with the end in EDF recording
    % Basically do te reverse of previous
    fprintf('Finding end index for aligning EDF Eye Data to end of TDT Eye data...\n');    
    partialEdf = fliplr(edfX(end-edfDataChunk:end)); 
    partialTdt = fliplr(tdtX(end-tdtDataChunk:end));    
    endIndices = findAlignmentIndices(partialEdf,partialTdt,binsForTdtMovingAverage,edfFsHz,tdtFsHz,slidingWindowSecs);    
    endIndices = numel(edfX)-endIndices;
    
    %% Linear function to convert TDT - TrialStart_ time (ms) to index on Eyelink collectd EDF data
    edfStartBin = startIndices(1);
    edfEndBin = endIndices(1);
    % Number of EDF bins per ms
    totalTimeMs = (numel(tdtX)*tdtBinWidthMs);
    edfBinsPerTdtMs = (edfEndBin-edfStartBin)/totalTimeMs;    
    %% Values for synchronizing Eylelink data with TDT
    edfSyncValues = struct();
    edfSyncValues.slidingWindowSecs = slidingWindowSecs(:);
    edfSyncValues.edfTrialStartOffsets = startIndices;
    edfSyncValues.edfTrialEndOffsets = endIndices;
    edfSyncValues.edfStartOffset = edfStartBin;
    edfSyncValues.edfEndOffset = edfEndBin;
    edfSyncValues.nTdtBins = numel(tdtX);
    edfSyncValues.tdtBinWidthMs = tdtBinWidthMs;
    edfSyncValues.nEdfBins = numel(edfX);
    edfSyncValues.edfBinWidthMs = edfBinWidthMs;
    edfSyncValues.linear.edfBinsPerTdtMs = edfBinsPerTdtMs;
    edfSyncValues.linear.edfStartOffset = edfStartBin;
    edfSyncValues.linear.edfBinIndexFx =  @(timeMs) timeMs.*edfSyncValues.linear.edfBinsPerTdtMs + edfSyncValues.linear.edfStartOffset;
    edfSyncValues.edfDataChunkSize = repmat(edfDataChunk,numel(slidingWindowSecs),1);
    edfSyncValues.tdtDataChunkSize = repmat(tdtDataChunk,numel(slidingWindowSecs),1);
    % add to output
    trialEyes.edfSyncValues = edfSyncValues;
    
    %% Parse edf Data into trials 
    trialEyes.trialTimeTable.edfTrialStartBinFractional=edfSyncValues.linear.edfBinIndexFx(trialStartTimes);
    trialEyes.trialTimeTable.edfTrialStartBin=round(trialEyes.trialTimeTable.edfTrialStartBinFractional);
        
    trialEyes.edfEyeX = splitEyeDataIntoTrialsFx(edfX,trialEyes.trialTimeTable.edfTrialStartBin); 
    trialEyes.edfEyeY = splitEyeDataIntoTrialsFx(edfY,trialEyes.trialTimeTable.edfTrialStartBin); 
    
    % Fill other output fields
    trialEyes.edf.EdfMatFile = edfMatFile;
    trialEyes.edf.FsHz = edfFsHz;
    trialEyes.edf.BinWidthMs = edfBinWidthMs;
    trialEyes.edf.Header = edf.(edfDataField).HEADER;
    trialEyes.edf.Recordings = edf.(edfDataField).RECORDINGS;
    trialEyes.edf.Fevent = edf.(edfDataField).FEVENT;
    trialEyes.DEFINITIONS = addDefinitions(trialEyes); 
   
        
end

%%
function [tdtEyeX, tdtEyeY, tdtEyeFs, tdtEyeZeroTime] = getTdtEyeData(blockPath)
    % Read Eye_X stream, and Eye_Y Stream from TDT
    % assume STORE names are 'EyeX', 'EyeY'
    % assume the sampling frequency same for both X and Y
    tdtFun = @TDTbin2mat;
    % Get raw TDT EyeX data
    tdtEye = tdtFun(blockPath,'TYPE',{'streams'},'STORE','EyeX','VERBOSE',0);
    tdtEyeX = tdtEye.streams.EyeX.data;
    % Get raw TDT EyeX data
    tdtEye = tdtFun(blockPath,'TYPE',{'streams'},'STORE','EyeY','VERBOSE',0);
    tdtEyeY = tdtEye.streams.EyeY.data;
    % Get sampling frequency
    tdtEyeFs = tdtEye.streams.EyeY.fs;
    % Usually very close to zero, but you never know
    tdtEyeZeroTime = tdtEye.streams.EyeY.startTime; 
end

function vec = replaceValue(vec,val,subVal)
      vec(vec==val)=subVal;
end

function indices = findAlignmentIndices(partialEdf, partialTdt, nBoxcarBins,edfHz, tdtHz, slidingWindowSecs)
    indices = nan(numel(slidingWindowSecs),1);
    tic
    for ii = 1:numel(slidingWindowSecs)
        fprintf('Aligning with time win %d secs...\n',slidingWindowSecs(ii));
        indices(ii,1) = tdtAlignEyeWithEdf(partialEdf,movmean(partialTdt,nBoxcarBins),edfHz,tdtHz,slidingWindowSecs(ii));
    end
    toc
end

function [out] = addDefinitions(inStruct)
   out = 'Not Yet';

end

