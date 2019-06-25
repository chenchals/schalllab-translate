function [maxVal, minVal] = openDataset(obj,varargin)
%OPENDATASET create memmapfile object array for accessing data
    channels = 1:numel(obj.dataFiles);
    if ~isempty(varargin)
        channels = varargin{1};
    end
    maxVal = nan(numel(channels),1);
    minVal = nan(numel(channels),1);
    for ii = channels
        obj.memmapDataFiles{ii,1} = memmapfile(obj.dataFiles{ii},...
            'Offset',obj.headerOffset,'Format',obj.dataForm);
        %maxVal(ii,1) = max(obj.memmapDataFiles{ii,1}.Data);
        %minVal(ii,1) = min(obj.memmapDataFiles{ii,1}.Data);
    end
    %obj.minDataVal = min(minVal);
    %obj.maxDataVal = max(maxVal);
    
end
