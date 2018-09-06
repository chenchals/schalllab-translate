function [alignedEdfVec, alignStartIndex] = eyeAlignEdfWithTdt(edfEyeVec, tdtEyeVec, edfSamplingFreqHz, tdtSamplingFreqHz, alignWindowSecs)
%EYEALIGNEDFWITHTDT Align EDF eye data with TDT eye data
%
%   edfEyeVec : Vector of Eye (X or Y) data from EDF file collected on Eyelink
%   tdtEyeVec : Vector of Eye (X or Y) data from TDT file collected on TDT
%   edfSamplingFreqHz : Sampling frequency of EDF
%   tdtSamplingFreqHz : Sampling frequency of TDT for Eye channels
%   alignWindowSecs : In Seconds. Converted to number of edf bins to slide the data for computing alignment.
%
%   OUTPUT:
%     alignedEdfVec : Truncated edfEyeVec. Data from the first data point
%                     of edfVec which whenaligned with first datapoint of
%                     tdtEyeVec will show minimal mean squared distance
%                     between tdtEyeVec and edfEyeVec. 
%     alignStartIndex : The index of edfEyeVec that when aligned with the
%                       first index of tdtEyeVec will show minimal mean
%                       squared distance between tdtEyeVec and edfEyeVec. 
%
% Example:
%   [alignedEdfX, startIndices] = eyeAlignEdfWithTdt(edfX, tdtX, 1000, 1017, 100);
%
% See also RESAMPLE, MEAN

    edfFs = round(edfSamplingFreqHz);
    tdtFs = round(tdtSamplingFreqHz);
    edfBinWidth = 1/edfFs;

    tdtEyeVecResampled = single(resample(double(tdtEyeVec),edfFs,tdtFs));
    tdtNBins = numel(tdtEyeVecResampled); % use 10 of the data
    % In edf bin time 1ms if colledted at 1000Hz
    slidingWinBins = alignWindowSecs/edfBinWidth; 
    
    normEdfX = (edfEyeVec - min(edfEyeVec))./range(edfEyeVec);
    normTdtX = (tdtEyeVecResampled - min(tdtEyeVecResampled))./range(tdtEyeVecResampled);
    meanSquaredDiff = nan(slidingWinBins,1);
    parfor ii = 1:slidingWinBins  
        meanSquaredDiff(ii,1) =  mean((normTdtX(1:tdtNBins) - normEdfX(ii:tdtNBins+ii-1)).^2); %#ok<PFBNS>
    end
    alignStartIndex = find(meanSquaredDiff==max(meanSquaredDiff));
    alignedEdfVec = edfEyeVec(alignStartIndex:end);
end

