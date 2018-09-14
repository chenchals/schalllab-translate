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
    
    trialEyes = struct();
    [tdtEyeX, tdtEyeY, trialEyes.tdtEyeFsHz, trialEyes.tdtEyeZeroTime] = getTdtEyeData(blockPath);
    tdtTimes = ((0:numel(tdtEyeX))'./trialEyes.tdtEyeFsHz) + trialEyes.tdtEyeZeroTime;
    tdtTimes = tdtTimes.*1000;
    nTrials = numel(trialStartTimes);
    tic
    tdtIdx = nan(nTrials,1);
    % Do not process first trial
    parfor i=2:nTrials
        d=abs(tdtTimes-trialStartTimes(i));
        idx = find(d==min(d),1,'first');
        tdtIdx(i,1) = idx;
    end
    toc
    trialEyes.tdtDataIndex = tdtIdx;

    trialEyes.tdtEyeX = arrayfun(@(x) tdtEyeX(tdtIdx(x):tdtIdx(x+1)), (2:nTrials-1)','UniformOutput', false);
    trialEyes.tdtEyeY = arrayfun(@(x) tdtEyeY(tdtIdx(x):tdtIdx(x+1)), (2:nTrials-1)','UniformOutput', false);    
    % Set Eye data of 1st and last trials to NaN
    trialEyes.tdtEyeX = [NaN;trialEyes.tdtEyeX;NaN];
    trialEyes.tdtEyeY = [NaN;trialEyes.tdtEyeY;NaN];
    
    %% If EDF translated data is present align trial data with edf data and parse edfData
    edfMatFile = dir([sessionDir '/*_EDF.mat']);
    if isempty(edfMatFile)
        return;
    end
    edfData = 'dataEDF';
    trialEyes.edfMatFile = fullfile(edfMatFile.folder, edfMatFile.name);
    edf = load(trialEyes.edfMatFile);
    edfX = edf.(edfData).FSAMPLE.gx(1,:);
    edfY = edf.(edfData).FSAMPLE.gy(1,:);
   
    % Clean EDF eye data
    MISSING_DATA_VALUE  = -32768;
    EMPTY_VALUE         = 1e08;
    % Eye X
    edfX(edfX==MISSING_DATA_VALUE)=nan;
    edfX(edfX==EMPTY_VALUE)=nan;
    % Eye Y
    edfY(edfY==MISSING_DATA_VALUE)=nan;
    edfY(edfY==EMPTY_VALUE)=nan;
   
    trialEyes.edfEyeFsHz = 1000;  
    
    edfFs = trialEyes.edfEyeFsHz;
    tdtFs = trialEyes.tdtEyeFsHz;
    maxTdtStartDelay = 100; % in seconds
   
    edfStartIndices = nan(nTrials,1);
    tempEdfX = edfX;
    fprintf('Aligning...\n');
    
    % complete trace
    
    slidWins = [10 20 40 60 80 100 150 200];
    tic
    for ii = 1:numel(slidWins)
       startIndForFirst(ii) = tdtAlignEyeWithEdf(tempEdfX,tdtEyeX,edfFs,tdtFs,slidWins(ii))
    end
    toc
    
    edfAlignedAt = 8498;
    
    
    for ii = 2:nTrials-1
         fprintf('.');
        slidingWindow = 10;
        if ii <= 2
            slidingWindow = maxTdtStartDelay;
        end
        tdtX = trialEyes.tdtEyeX{ii};
        trialLength = floor(numel(tdtX)*1000/trialEyes.tdtEyeFsHz);
        edfStartIndices(ii) = tdtAlignEyeWithEdf(tempEdfX,tdtX,edfFs,tdtFs,slidingWindow);
        nextEdfIndex = edfStartIndices(ii) + trialLength;
        tempEdfX = tempEdfX(nextEdfIndex:end);
        if mod(ii,100)==0
            fprintf('%d\n',ii);
        end
    end

    trialEyes.edfStartIndices = edfStartIndices;
    edfDataIndex = [NaN;cumsum(edfStartIndices(2:end-1));NaN];
    trialEyes.edfDataIndex = edfDataIndex;

    trialEyes.edfEyeX = arrayfun(@(x) edfX(edfDataIndex(x):edfDataIndex(x+1)), (2:nTrials-2)','UniformOutput', false);
    trialEyes.edfEyeY = arrayfun(@(x) edfY(edfDataIndex(x):edfDataIndex(x+1)), (2:nTrials-2)','UniformOutput', false);    

    % Set Eye data of 1st and last trials to NaN
    trialEyes.edfEyeX = [NaN;trialEyes.edfEyeX;NaN];
    trialEyes.edfEyeY = [NaN;trialEyes.edfEyeY;NaN];
    
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


