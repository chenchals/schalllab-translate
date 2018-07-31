function [pdLP] = getPhotoDiodeEvents(pdL,pdFs)
%GETPHOTODIODEEVENTS Summary of this function goes here
%   Detailed explanation goes here

    % PDBin
    pdTbinMs = 1000.0/pdFs;

    %% figureout the PD signal
    pdL5Avg = movmean(pdL,[4 0]);

    above_0_2L=find(pdL>0.15);
    idxThr = above_0_2L;
    pdLP.above_0_2.idxThr = idxThr;
    % Half window for the signal
    hw = 40;
    % Find index for rise time : time to rise from 10% range to 90% range
    riseTime = @(x) min(find(x>=range(x)*0.90)); %#ok<MXFND>
    pdLP.above_0_2.riseTime = arrayfun(@(x) riseTime(pdL5Avg(x-40:x+40)), idxThr);
    % shift center index to rise time
    idxOnRiseTime = idxThr + pdLP.above_0_2.riseTime - hw;
    pdLP.above_0_2.idxOnRiseTime = idxOnRiseTime;

    pdLP.above_0_2.x = cell2mat(arrayfun(@(x) [(-hw:hw)';NaN], idxThr,'UniformOutput', false));
    pdLP.above_0_2.y = cell2mat(arrayfun(@(x) [pdL5Avg(x-hw:x+hw);NaN], idxThr,'UniformOutput', false));
    pdLP.above_0_2.yOnRiseTime = cell2mat(arrayfun(@(x) [pdL5Avg(x-hw:x+hw);NaN], idxOnRiseTime,'UniformOutput', false));

    figure
    plot(pdLP.above_0_2.x.*pdTbinMs,pdLP.above_0_2.yOnRiseTime)
    grid on
    xlabel({'Photodiode Signal centered on rise-time (reach 90% of range for each cycle)'; 'Relative Time (ms)'})
    ylabel('Phootodiode Signal Volts? or mVolts?')



end

