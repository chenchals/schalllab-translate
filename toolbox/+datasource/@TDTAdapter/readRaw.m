    function [data] = readRaw(obj, nChannels, nSamples)
    %READRAW Summary of this function goes here
    data = zeros(nChannels, nSamples);
    channels = (1:nChannels) + obj.channelOffset;
    if ~obj.isOpen
        initMemMapFiles(obj, channels);
        obj.isOpen = 1;
    end
    p = gcp('nocreate');
    sampleStart = obj.lastSampleRead + 1;
    sampleEnd = obj.lastSampleRead + nSamples;
    memFiles = obj.memmapDataFiles;
    if isempty(p)
        for ii = 1:nChannels
            ch = channels(ii);
            data(ii,1:nSamples) = memFiles{ch}.Data(sampleStart:sampleEnd);
        end
    else
        parfor ii = 1:nChannels
            ch = channels(ii);
            temp{ii} = memFiles{ch}.Data(sampleStart:sampleEnd); %#ok<PFBNS>
        end
        data = cell2mat(temp)';
    end
    data = data.*obj.rawDataScaleFactor;

    obj.lastSampleRead = obj.lastSampleRead + nSamples;
    end

    function initMemMapFiles(obj, channels)
    for ii = channels
        obj.memmapDataFiles{ii,1} = memmapfile(obj.dataFiles{ii},...
            'Offset',obj.headerOffset,'Format',obj.dataForm);
    end

    end
