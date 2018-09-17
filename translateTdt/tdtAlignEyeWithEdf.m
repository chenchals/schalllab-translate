function [alignStartIndex, alignedEdfVec] = tdtAlignEyeWithEdf(edfEyeVec, tdtEyeVec, edfSamplingFreqHz, tdtSamplingFreqHz, alignWindowSecs)
%TDTALIGNEYEWITHEDF Align EDF eye data with TDT eye data
%Note:
% Replace values in EDF eye data that is missed/defaulted
% Seems to be 1E8 is the value.  Also MISSING_DATA = -32768
%
%   edfEyeVec : Vector of Eye (X or Y) data from EDF file collected on Eyelink
%   tdtEyeVec : Vector of Eye (X or Y) data from TDT file collected on TDT
%   edfSamplingFreqHz : Sampling frequency of EDF
%   tdtSamplingFreqHz : Sampling frequency of TDT for Eye channels
%   alignWindowSecs : In Seconds. Converted to number of edf bins to slide the data for computing alignment.
%
%   OUTPUT:
%     alignStartIndex : The index of edfEyeVec that when aligned with the
%                       first index of tdtEyeVec will show minimal mean
%                       squared distance between tdtEyeVec and edfEyeVec. 
%     alignedEdfVec : Truncated edfEyeVec. Data from the first data point
%                     of edfVec which whenaligned with first datapoint of
%                     tdtEyeVec will show minimal mean squared distance
%                     between tdtEyeVec and edfEyeVec. 
%
% Example:
%   [alignStartIndex, alignedEdfVec] = eyeAlignEdfWithTdt(edfX, tdtX, 1000, 1017, 100);
%
% See also RESAMPLE, MEAN, EDFANALOG2PIXELS
% See EDF2MAT in edf-converter https://github.com/uzh/edf-converter for
%   MISSING_DATA_VALUE 
%   EMPTY_VALUE 
%   
    % From Edf2Mat.m in edf-converter
    MISSING_DATA_VALUE  = -32768;
    EMPTY_VALUE         = 1e08;

    edfEyeVec(edfEyeVec==MISSING_DATA_VALUE)=nan;
    edfEyeVec(edfEyeVec==EMPTY_VALUE)=nan;

    edfFs = round(edfSamplingFreqHz);
    tdtFs = round(tdtSamplingFreqHz);
    tdtEyeVecResampled = single(resample(double(tdtEyeVec),edfFs,tdtFs));
    alignStartIndex = alignVectors(edfEyeVec,tdtEyeVecResampled,alignWindowSecs * edfFs);
    alignedEdfVec = edfEyeVec(alignStartIndex:end);
end

function [lag] = alignVectors(edfVec, tdtVec, slidingWinBins)
    % for conversion to gaze in pixels
    voltRange = [-5 5];
    signalRange = [-0.2 1.2];
    pixelRange = [0 1024]; % X-only
    % In edf bin time 1ms if colledted at 1000Hz
    %Restrict tdt eye data to double the slidingWinBins
%     tdtNBins = numel(tdtVec);
%     if tdtNBins > 2*slidingWinBins
%         tdtNBins = 2*slidingWinBins;
%         tdtVec = tdtVec(1:tdtNBins);
%     end
%     if numel(edfVec) > 2*slidingWinBins
%         edfVec = edfVec(1:2*slidingWinBins);
%     end
    tdtNBins = numel(tdtVec);
    nGazeEdf = (edfVec - min(edfVec))./range(edfVec);
    nGazeTdt = tdtAnalog2Pixels(tdtVec,voltRange,signalRange,pixelRange);
    nGazeTdt = (nGazeTdt - min(nGazeTdt))./range(nGazeTdt);
    meanSquaredDiff = nan(slidingWinBins,1);
    parfor ii = 1:slidingWinBins
        if ii+tdtNBins-1 <= numel(nGazeEdf)
            edfForAlign = nGazeEdf(ii:ii+tdtNBins-1);
            meanSquaredDiff(ii,1) =  nanmean(((nGazeTdt - edfForAlign).^2));
        end
    end
    lag = find(meanSquaredDiff==nanmin(meanSquaredDiff),1,'first');

end



