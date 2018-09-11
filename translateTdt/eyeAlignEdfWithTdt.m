function [alignedEdfVec, alignStartIndex] = eyeAlignEdfWithTdt(edfEyeVec, tdtEyeVec, edfSamplingFreqHz, tdtSamplingFreqHz, varargin)
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
% See also RESAMPLE, MEAN, EDFANALOG2PIXELS
%
    doClassic = 0;
    if numel(varargin) == 1
        doClassic = 1;
        alignWindowSecs = varargin{1};
    end
    
    edfFs = round(edfSamplingFreqHz);
    tdtFs = round(tdtSamplingFreqHz);
    tdtEyeVecResampled = single(resample(double(tdtEyeVec),edfFs,tdtFs));
    if doClassic
        alignStartIndex = alignVectors(edfEyeVec,tdtEyeVecResampled,alignWindowSecs * edfFs);
    else
        [xc,lags] = xcorr(edfEyeVec,tdtEyeVecResampled);
        alignStartIndex = lags(xc==max(xc));
    end
    alignedEdfVec = edfEyeVec(alignStartIndex:end);
end

function [lag] = alignVectors(edfVec, tdtVec, slidingWinBins)
    % for conversion to gaze in pixels
    voltRange = [-5 5];
    signalRange = [-0.2 1.2];
    pixelRange = [0 1024]; % X-only
    % In edf bin time 1ms if colledted at 1000Hz
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
    lag = find(meanSquaredDiff==nanmin(meanSquaredDiff),1,'last');

end



