function [pdSignal] = getPhotoDiodeEvents(pdVolts,pdFs, thresholdPercentile,signalWidthEven)
%GETPHOTODIODEEVENTS Summary of this function goes here
%   Detailed explanation goes here
    

    pdSignal.thresholdPercentile = thresholdPercentile;
    pdSignal.threshold = prctile(pdVolts,thresholdPercentile);
    % PDBin
    pdTbinMs = 1000.0/pdFs;
    
    % make it a column vector
    pdVolts = pdVolts(:);

    %% figureout the PD signal
    pdVolts3PtAvg = movmean(pdVolts,[2 0]);

    aboveThr=find(pdVolts>pdSignal.threshold);
    idxThr = aboveThr;
    pdSignal.idxThr = idxThr;
    % Half window for the signal
    hw = round(signalWidthEven);
    % Find index for rise time : time to rise from 10% range to 90% range
    riseEndTime = @(x) min(find(x>=min(x)+range(x)*0.90)); %#ok<MXFND>
    riseBeginTime = @(x) min(find(x>=min(x)+range(x)*0.10)); %#ok<MXFND>
    pdSignal.riseEndTime = arrayfun(@(x) riseEndTime(pdVolts3PtAvg(x-hw:x+hw)), idxThr);
    pdSignal.riseBeginTime = arrayfun(@(x) riseBeginTime(pdVolts3PtAvg(x-hw:x+hw)), idxThr);
    % shift center index to rise time
    idxOnRiseEndTime = idxThr + pdSignal.riseEndTime - hw;
    pdSignal.idxOnRiseTime = idxOnRiseEndTime;

    pdSignal.ts = cell2mat(arrayfun(@(x) (-hw:hw).*pdTbinMs, idxOnRiseEndTime,'UniformOutput', false));
    pdSignal.pdVolts = cell2mat(arrayfun(@(x) pdVolts(x-hw:x+hw)', idxOnRiseEndTime,'UniformOutput', false));
    pdSignal.x = cell2mat(arrayfun(@(x) [(-hw:hw)';NaN], idxOnRiseEndTime,'UniformOutput', false));
    pdSignal.pdVoltsOnRiseEndTime = cell2mat(arrayfun(@(x) [pdVolts3PtAvg(x-hw:x+hw);NaN], idxOnRiseEndTime,'UniformOutput', false));
    pdVolts_raw = cell2mat(arrayfun(@(x) [pdVolts(x-hw:x+hw);NaN], idxOnRiseEndTime,'UniformOutput', false));

    figure
    plot(pdSignal.x.*pdTbinMs,pdSignal.pdVoltsOnRiseEndTime)
    hold on
    plot(pdSignal.x.*pdTbinMs,pdVolts_raw,'r')
    hold off
    
    grid on
    xlabel({'Photodiode Signal centered on rise-time (reach 90% of range for each cycle)'; 'Relative Time (ms)'})
    ylabel('Phootodiode Signal Volts? or mVolts?')
    
    text(min(xlim())*0.95,max(ylim())*0.95,sprintf('#PD Events = %d',numel(pdSignal.idxOnRiseTime)));
    text(min(xlim())*0.95,max(ylim())*0.90,sprintf('#PD Thresh Percentile = %0.4f',pdSignal.thresholdPercentile));
    text(min(xlim())*0.95,max(ylim())*0.85,sprintf('#PD Thresh = %0.4f',pdSignal.threshold));


end

