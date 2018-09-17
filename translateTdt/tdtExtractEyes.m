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
%              (c) EDF mat full filepath sessionDir/[SESSION_NAME]_EDF.mat
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
    binsForTdtMovingAverage = 1;
    maxTdtStartDelay = 100; % in seconds

    
    trialEyes = struct();
    [tdtX, tdtY, tdtFsHz, tdtStartTime] = getTdtEyeData(blockPath);
    tdtBinWidthMs = 1000/tdtFsHz;
    %% If EDF translated data is present align trial data with edf data and parse edfData
    edfMatFile = dir([sessionDir '/dataEDF.mat']);
    if isempty(edfMatFile)
        return;
    end
    edfDataField = 'dataEDF';
    trialEyes.edfMatFile = fullfile(edfMatFile.folder, edfMatFile.name);
    edf = load(trialEyes.edfMatFile);
    edfX = edf.(edfDataField).FSAMPLE.gx(1,:);
    edfY = edf.(edfDataField).FSAMPLE.gy(1,:);
    edfFsHz = 1000;
    edfBinWidthMs = 1000/edfFsHz;
    
    %% Clean EDF eye data
    MISSING_DATA_VALUE  = -32768;
    EMPTY_VALUE         = 1e08;
    edfX = replaceValue(edfX,MISSING_DATA_VALUE,nan);
    edfX = replaceValue(edfX,EMPTY_VALUE,nan);
    edfY = replaceValue(edfY,MISSING_DATA_VALUE,nan);
    edfY = replaceValue(edfY,EMPTY_VALUE,nan);
    
    %% Align start of tdt (Eye) recording with the start of EDF recording
    slidingWindowSecs = round(linspace(0,maxTdtStartDelay,4));
    slidingWindowSecs = slidingWindowSecs(2:end);
    edfDataChunk = 2*maxTdtStartDelay*1000; % Twice the max delay bins
    tdtDataChunk = 0.1*edfDataChunk; % 10% of no of edfBins
    partialEdfX = edfX(1:edfDataChunk); 
    partialTdtX = tdtX(1:tdtDataChunk);
        
    startIndices = nan(numel(slidingWindowSecs,1));
    tic
    for ii = 1:numel(slidingWindowSecs)
        fprintf('Aligning with time win %d secs...\n',slidingWindowSecs(ii));
        startIndices(ii,1) = tdtAlignEyeWithEdf(partialEdfX,movmean(partialTdtX,binsForTdtMovingAverage),edfFsHz,tdtFsHz,slidingWindowSecs(ii));
    end
    toc
    edfTrialStartOffset = startIndices(1);
    edfOffsetTimes = table();
    edfOffsetTimes.slidingWindowSecs = slidingWindowSecs(:);
    edfOffsetTimes.edfTrialStartOffsets = startIndices;
    edfOffsetTimes.edfDataChunkSize = repmat(edfDataChunk,numel(slidingWindowSecs),1);
    edfOffsetTimes.tdtDataChunkSize = repmat(tdtDataChunk,numel(slidingWindowSecs),1);
    
    %% Parse edf Data and tdt Data into trials
    
    trialTimeTable = table();
    trialTimeTable.trialTimeMs=round(trialStartTimes);
    trialTimeTable.trialDurationMs=[diff(trialTimeTable.trialTimeMs);NaN];
    trialTimeTable.tdtTrialTimeBins=trialTimeTable.trialTimeMs./tdtBinWidthMs;
    trialTimeTable.tdtTrialTimeBins=round(trialTimeTable.trialTimeMs./tdtBinWidthMs);
    trialTimeTable.edfTrialTimeBins=round(trialTimeTable.trialTimeMs+edfTrialStartOffset);
        
    % Parse vector to trial omit 1st and last trial
    nTrials = size(trialTimeTable,1);
    parse2Trials = @(eyeVec,timeBins)...
                  [NaN;...
                   arrayfun(@(ii) eyeVec(timeBins(ii):timeBins(ii+1)-1),(2:nTrials-1)','UniformOutput',false);...
                   NaN];
    
    trialEyes.tdtTrialsEyeX = parse2Trials(tdtX,trialTimeTable.tdtTrialTimeBins);
    trialEyes.tdtTrialsEyeY = parse2Trials(tdtY,trialTimeTable.tdtTrialTimeBins);
    trialEyes.edfTrialsEyeX = parse2Trials(edfX,trialTimeTable.edfTrialTimeBins); 
    trialEyes.edfTrialsEyeY = parse2Trials(edfY,trialTimeTable.edfTrialTimeBins); 
    
    % Fill other output fields
    trialEyes.trialTimeTable = trialTimeTable;
    trialEyes.tdtFsHz = tdtFsHz;
    trialEyes.tdtBinWidthMs = tdtBinWidthMs;
    trialEyes.edfFsHz = edfFsHz;
    trialEyes.edfBinWidthMs = edfBinWidthMs;
    trialEyes.edfOffsetTimes = edfOffsetTimes;
    trialEyes.edfOffsetTimeUsed = edfTrialStartOffset;
    trialEyes.tdtStartTime = tdtStartTime;
    trialEyes.edfHeader = edf.(edfDataField).HEADER;
    trialEyes.edfRecordings = edf.(edfDataField).RECORDINGS;
    trialEyes.edfFevent = edf.(edfDataField).FEVENT;
        
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

