classdef EMouseDataAdapter < DataAdapter
    %EMOUSEDATAADAPTER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=protected)
     totalNumberOfChannels = 34; %synthetoc data has 34 channels
    end
    
    methods
        % CTOR
        function obj = EMouseDataAdapter(source)
            obj.dataSource = source;
            updateFileHandles(obj);
        end
        
        % Samples to read per channel
        function [ sampsToRead ] = getSampsToRead(obj,nChannels)
            sampsToRead = floor(obj.dirStruct.bytes/nChannels/2);
        end
        
        % Batch read datapoints
        function [ buffer ] = batchRead(obj, readOffset, nChannels, nSamples, dataTypeString)
            fid = obj.fidArray(1);
            fseek(fid,readOffset,'bof');
            buffer = fread(fid, [nChannels nSamples], ['*' dataTypeString]);
        end
        
        % Read sample data for range of [sampleWin] centered on samples
        function [ waveforms ] = getWaveforms(obj, sampleWin, samples, channelNos)
            wtemp = cell(length(channelNos),1);
            dataType = 'int16';
            nBytesPerSamples = 2;
            samplesPerChannel = getSampsToRead(obj,obj.totalNumberOfChannels);
            nSamples = size(samples,1);
            sampWinLength = length(sampleWin);
            nChannels = length(channelNos);
            wavIndices = arrayfun(@(x) sampleWin+x,samples(:,1),'UniformOutput', false);
            wavIndices = cell2mat(wavIndices);
            minLoc = (min(wavIndices(:))-1)*nBytesPerSamples;
            nSampsToRead = max(wavIndices(:)) - min(wavIndices(:)) + 1;
            wavIndicesRel = wavIndices - min(wavIndices(:)) +1;
            fid = obj.fidArray(1);
            for ch = 1:length(channelNos)
                chOffest = samplesPerChannel*(ch-1)*nBytesPerSamples;
                fprintf('Reading channel %d channel offset (bytes from bof) %d\n',ch,chOffest);
                fseek(fid,minLoc+chOffest,'bof');
                temp = fread(fid, nSampsToRead, ['*' dataType]);
                wtemp{ch} = temp(wavIndicesRel);
            end
            waveforms=reshape(cell2mat(wtemp'),nSamples,sampWinLength,nChannels);
            % verify diff should be zero for channel 1
            %DD=WF(:,:,1)-cell2mat(WW39(1));
        end
        
    end
    
    methods (Access=private)
        
        function [] = updateFileHandles(obj)
            if exist(obj.dataSource,'file')==2
                obj.dirStruct = dir(obj.dataSource);
                obj.fidArray(1) = fopen(obj.dataSource,'rb');
            else
                error('FileNotFound: Binary data file %s does not exist',source);
            end
        end
    end
    
end

