function [photodiodeEvents, pdFirstSignal, pdLastSignal] = processPhotodiode(pdFirst, pdLast, samplingFreq)
%PROCESSPHOTODIODE Summary of this function goes here
%   Detailed explanation goes here
%
% See also GETPHOTODIODEEVENTS

    thresholdPercentile = 99.9;
    if samplingFreq > 20000
        signalWidthInTicks = 50;% ~ 2-2.5 ms
    else % 1.2kHz
        signalWidthInTicks = 6;% ~ 5 ms? for 1.2kHz
    end
    tickWidthMs = 1000.0/samplingFreq;
    
    fprintf('Processing first photodiode...\n');
    [pdFirstSignal] = getPhotodiodeEvents(pdFirst,samplingFreq,thresholdPercentile,signalWidthInTicks);
    pdFirstUniqIdx = unique(pdFirstSignal.idxOnRiseEndTime);
    pdFirstUniqMs = pdFirstUniqIdx.*tickWidthMs;
        
    fprintf('Processing last photodiode...\n');
    [pdLastSignal] = getPhotodiodeEvents(pdLast,samplingFreq,thresholdPercentile,signalWidthInTicks);
    pdLastUniqIdx = unique(pdLastSignal.idxOnRiseEndTime);

    nRows = max([numel(pdLastUniqIdx),numel(pdFirstUniqIdx)]);
    photodiodeEvents = array2table(nan(nRows,2));
    photodiodeEvents(1:numel(pdFirstUniqIdx),1)=array2table(pdFirstUniqIdx);
    photodiodeEvents(1:numel(pdLastUniqIdx),2)=array2table(pdLastUniqIdx);
    photodiodeEvents.Properties.VariableNames={'PD_First_In_Ticks','PD_Last_In_Ticks'};
    photodiodeEvents.PD_First_In_Ms = photodiodeEvents.PD_First_In_Ticks.*tickWidthMs;
    photodiodeEvents.PD_Last_In_Ms = photodiodeEvents.PD_Last_In_Ticks.*tickWidthMs;
    
    % Pair the PD_First event tick with corresponding *next* PD_Last event tick for
    % all PD_First event ticks
    
    pairedLast = arrayfun(@(x) min([find(pdLastUniqIdx > x, 1), NaN]), pdFirstUniqIdx);
    % Avoid NaN index
    pdLastUniqIdx(end+1) = NaN;
    pairedLast(isnan(pairedLast)) = numel(pdLastUniqIdx);
    
    photodiodeEvents.PD_Last_In_Ticks_Paired = [pdLastUniqIdx(pairedLast);nan(nRows-numel(pairedLast),1)];
    photodiodeEvents.PD_Last_In_Ms_Paired = photodiodeEvents.PD_Last_In_Ticks_Paired.*tickWidthMs;
    photodiodeEvents.PD_Last_Minus_First_In_Ticks_Paired = ...
        photodiodeEvents.PD_Last_In_Ticks_Paired - photodiodeEvents.PD_First_In_Ticks;
    photodiodeEvents.PD_Last_Minus_First_In_Ms_Paired = ...
        photodiodeEvents.PD_Last_Minus_First_In_Ticks_Paired.*tickWidthMs;
    
    photodiodeEvents.PD_Ms = ...
        (photodiodeEvents.PD_Last_In_Ticks_Paired + photodiodeEvents.PD_First_In_Ticks).*(tickWidthMs/2);
    
end

