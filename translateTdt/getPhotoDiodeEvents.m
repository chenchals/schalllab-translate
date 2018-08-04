function [pdSignal] = getPhotodiodeEvents(pdVolts, samplingFreq, thresholdPercentile, signalWidthInTicks)
%GETPHOTODIODEEVENTS Photodiode signal processing
%   Computes threshold value for PD signal, extracts pd-on vectors around
%   the threshold values, computes signal-rise-end-time for each
%   3-point-moving-average of pd-on vector, centers pd-on (and 3-pt avg)
%   vectors on the signal-rise-end-time for each pd-on vectors, and finally
%   plots these signals
%   Definition : Time to rise is time tyaken for signal to rise from 10%
%   range to 90% range for each signal-vector
%   
%   Inputs:
%     pdVolts : Raw TDT data for photodiode stream. Usually
%         (tdtRaw.streams.PD__.data or tdtRaw.streams.PhoL.data,...)
%     samplingFreq : Sampling frequency for the Photodiode channel. Usually 
%         (tdtRaw.streams.PD__.fs or tdtRaw.streams.PhoL.fs,...)
%     thresholdPercentile : Percentile to use for thresholding the
%         Photodiode raw signal. Use: 99.9.  Lower thresholds will yeald
%         too many PD event chunks
%     signalWidthInTicks : Width of photodiode signal to extract centered on the
%         threshold for each pd-on vector. For low frequency sampling uise
%         6, for high frequency sampling use 40
%    
%     ***Note the timestamps need to offset by the startTime,  ut we omit this
%     as this is usually very low, on the order of 10e-7 secs.***
%   Output:
%     pdSignal : A struct with the following fields:
%          thresholdPercentile: 
%                    threshold: 
%                       idxThr: 
%                  riseEndTime: 
%                riseBeginTime: 
%                idxOnRiseTime: 
%                           ts: 
%                      pdVolts: 
%                            x: 
%         pdVoltsOnRiseEndTime: 
% 
%   Example1: Low sampling frequency
%       [pdSignal] = getPhotoDiodeEvents(tdtRaw.streams.PD__.data,tdtRaw.streams.PD__.fs,99.9,6);
%
%   Example2: High sampling frequency 2.4414E+4
%       [pdSignal] = getPhotoDiodeEvents(tdtRaw.streams.PhoL.data,tdtRaw.streams.PhoL.fs,99.9,40);
%
% See also PRCTILE, MOVMEAN
    tic
    timeToRise = [0.10 0.90]; % 0 - 1
    % Number of ticks for which the PD voltage will be above threshold.
    % This value is used to 'jump' to next pd-on vector. This value must be
    % small for lo sampling rate (2?) and around 5 for 24414 Hz sampling
    % rate.
    if samplingFreq > 20000
        runLength = 5;
    else
        runLength = 2;
    end
    overplotRaw = false;
    
    pdSignal.thresholdPercentile = thresholdPercentile;
    pdSignal.threshold = prctile(pdVolts,thresholdPercentile);
    
    %pdSignal.threshold = 0.1;
    % PDBin
    pdTbinMs = 1000.0/samplingFreq;
    
    % make it a column vector
    pdVolts = pdVolts(:);

    %% figureout the PD signal
    pdVolts3PtAvg = movmean(pdVolts,[2 0]);

    aboveThrIdxAll=find(pdVolts>pdSignal.threshold);
    pdSignal.aboveThrIdxAll = aboveThrIdxAll;
    
    % Since there will more than 1 value that is above 99.9 percentile for
    % each pd-on vector, there will 'runs' of valuse > 99.9th percentile,
    % since we want to junp to the next signal-rise-time we will consider
    % adjacent indices to belong to the same pd-on vector
    aboveThrIdx=aboveThrIdxAll(diff(aboveThrIdxAll)>runLength);
       
    % Half window for the signal
    hw = round(signalWidthInTicks);
    % Find index for rise time : time to rise from 10% range to 90% range
    riseEndTime = @(x) min(find(x>=min(x)+range(x)*timeToRise(2))); %#ok<MXFND>
    riseBeginTime = @(x) min(find(x>=min(x)+range(x)*timeToRise(1))); %#ok<MXFND>
    pdSignal.riseEndTime = arrayfun(@(x) riseEndTime(pdVolts3PtAvg(x-hw:x+hw)), aboveThrIdx);
    pdSignal.riseBeginTime = arrayfun(@(x) riseBeginTime(pdVolts3PtAvg(x-hw:x+hw)), aboveThrIdx);
    % shift center index to rise time
    idxOnRiseEndTime = aboveThrIdx + pdSignal.riseEndTime - hw;
    pdSignal.idxOnRiseEndTime = idxOnRiseEndTime;

    pdSignal.ts = cell2mat(arrayfun(@(x) (-hw:hw).*pdTbinMs, idxOnRiseEndTime,'UniformOutput', false));
    pdSignal.pdVolts = cell2mat(arrayfun(@(x) pdVolts(x-hw:x+hw)', idxOnRiseEndTime,'UniformOutput', false));
    pdSignal.x = cell2mat(arrayfun(@(x) [(-hw:hw)';NaN], idxOnRiseEndTime,'UniformOutput', false));
    pdSignal.pdVoltsOnRiseEndTime = cell2mat(arrayfun(@(x) [pdVolts3PtAvg(x-hw:x+hw);NaN], idxOnRiseEndTime,'UniformOutput', false));
    toc
    fprintf('Plotting....\n')
    figure
    plot(pdSignal.x.*pdTbinMs,pdSignal.pdVoltsOnRiseEndTime)
    hold on
    if overplotRaw
        pdVolts_raw = cell2mat(arrayfun(@(x) [pdVolts(x-hw:x+hw);NaN], idxOnRiseEndTime,'UniformOutput', false)); %#ok<UNRCH>
        plot(pdSignal.x.*pdTbinMs,pdVolts_raw,'r')
    end
    hold off
    grid on
    xlabel({num2str(timeToRise(2)*100,'Photodiode Signal centered on rise-end-time (reach %02.1f%% of range for each cycle)'); 'Relative Time (ms)'})
    ylabel('Phootodiode Signal Volts? or mVolts?')
    
    text(min(xlim())*0.95,max(ylim())*0.95,sprintf('#PD Events = %d',numel(pdSignal.idxOnRiseEndTime)));
    text(min(xlim())*0.95,max(ylim())*0.90,sprintf('#PD Thresh Percentile = %0.4f',pdSignal.thresholdPercentile));
    text(min(xlim())*0.95,max(ylim())*0.85,sprintf('#PD Thresh = %0.4f',pdSignal.threshold));

end

