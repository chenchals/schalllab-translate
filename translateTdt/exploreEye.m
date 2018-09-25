    edfData = 'dataEDF';
    trialEyes.edfEyeFsHz = 1000;  
    edf = load(trialEyes.edfMatFile);
    edfX = edf.(edfData).FSAMPLE.gx(1,:);
    tempEdfX = edfX;
 
    edfFs = trialEyes.edfEyeFsHz;
    tdtFs = trialEyes.tdtEyeFsHz;
    maxTdtStartDelay = 100; % in seconds
    nTrials = 1000;
    edfStartIndices = nan(nTrials,1);
    tempEdfX = edfX;
    fprintf('Aligning...\n');
    for ii = 2:100
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
    edfDataIndex = [NaN;cumsum(edfStartIndices(2:end-1));NaN];

    trialEyes.edfStartIndices = edfStartIndices;
    trialEyes.edfDataIndex = edfDataIndex;
    trialEyes.edfEyeX2 = arrayfun(@(x) edfX(edfDataIndex(x):edfDataIndex(x+1)), (2:100-2)','UniformOutput', false);
    trialEyes.edfEyeY2 = arrayfun(@(x) edfY(edfDataIndex(x):edfDataIndex(x+1)), (2:100-2)','UniformOutput', false);    
    % Set Eye data of 1st and last trials to NaN
    trialEyes.edfEyeX = [NaN;trialEyes.edfEyeX;NaN];
    trialEyes.edfEyeY = [NaN;trialEyes.edfEyeY;NaN];
    
    
    
    
   %% plot it
       % for conversion to gaze in pixels
    voltRange = [-5 5];
    signalRange = [-0.2 1.2];
    pixelRange = [0 1024]; % X-only

   
   for ii = 2:40
       tdtX = trialEyes.tdtEyeX{ii};
       tdtX = tdtAnalog2Pixels(tdtX, voltRange, signalRange, pixelRange);
       edfX = trialEyes.edfEyeX{ii};
       tdtBinSize = 1000/trialEyes.tdtEyeFsHz;
       tdtTime = (1:numel(tdtX))'.*tdtBinSize;

       edfTime = (1:numel(edfX))';
       plot(tdtTime,tdtX,'b');
       hold on
       plot(edfTime,edfX,'r');
       hold off
       pause
       
   end
