classdef TdtDataAdapter < DataAdapter
    %EMOUSEDATAADAPTER Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        % CTOR
        function obj = TdtDataAdapter(source)
            obj.dataSource = source;
            updateFileHandles(obj);
        end
        
        % Samples to read per channel
        function [ sampsToRead ] = getSampsToRead(obj,nChannels)
            % assume dForm = single = 4 bytes
            nBytesPerSample = 4;
            checkChannelCount(obj, nChannels);
            totalBytes = 0;
            for ch = 1:nChannels
                fStruct = obj.dirStruct(ch);
                totalBytes = totalBytes + fStruct.bytes - 40;
            end
            sampsToRead = floor(totalBytes/nChannels/nBytesPerSample);
        end
        
        % Batch read datapoints
        function [ buffer ] = batchRead(obj, readOffsetAllChan, nChannels, nSamples, dataTypeString, chOffset)
            checkChannelCount(obj, nChannels);
            buffer = zeros(nChannels, nSamples);
            headerBytes = 40;
            readOffset = (readOffsetAllChan/nChannels) + headerBytes;
            myChannels = (1:nChannels)+chOffset;
            for ch = myChannels
                fid = obj.fidArray(ch);
                fseek(fid,readOffset,'bof');
                %fprintf('pointer before read %d ...',ftell(fid));
                temp = fread(fid, nSamples,['*' dataTypeString]);
                %fprintf('after read %d\n',ftell(fid));
                if isempty(temp)
                    buffer = [];
                else
                   buffer(ch-chOffset,1:length(temp)) = temp;
                end
                clearvars temp
            end
            % close all filehandles if buff=[], as we have read past the
            % file for every channel
            if isempty(buffer)
                 obj.closeAll();
            end
        end
        
        function [ chData ] = getChannelData(obj, nChannels, channelNo, dataTypeString)
            readOffset = 40; % Header
            chStr = num2str(channelNo,'_Ch%d.sev');
            fprintf('reading channel %d of %d\n',channelNo, nChannels)
            fid = obj.fidArray(contains({obj.dirStruct.name}',chStr));
            fseek(fid,readOffset,'bof');
            chData = fread(fid, obj.getSampsToRead(nChannels),['*' dataTypeString]);
            
        end
        
        
        % Read sample data for range of [sampleWin] centered on samples
        function [ waveforms ] = getWaveforms(obj, sampleWin, samples, channelNos, chOffset)
           wtemp = cell(length(channelNos),1);
           dataType = 'single';
           header = 40;
           nSamples = size(samples,1);
           sampWinLength = length(sampleWin);
           nChannels = length(channelNos);
           wavIndices = arrayfun(@(x) sampleWin+x,samples(:,1),'UniformOutput', false);
           wavIndices = cell2mat(wavIndices);
           minLoc = (min(wavIndices(:))-1)*4;
           nSampsToRead = max(wavIndices(:)) - min(wavIndices(:)) + 1;
           wavIndicesRel = wavIndices - min(wavIndices(:)) +1;
           for ii = 1:nChannels
               ch = channelNos(ii);
               fprintf('Doing channel %d\n',ch);
               fid = obj.fidArray(ch);
               fseek(fid,minLoc+header,'bof');
               temp = fread(fid, nSampsToRead, ['*' dataType]);
               wtemp{ch-chOffset} = temp(wavIndicesRel);
           end
           waveforms=reshape(cell2mat(wtemp'),nSamples,sampWinLength,nChannels);
           % verify diff should be zero for channel 1
           %DD=WF(:,:,1)-cell2mat(WW39(1));
        end
    end
    
    methods (Access=private)
        
        function [] = updateFileHandles(obj)
            if exist(obj.dataSource,'dir')==7
                obj.dirStruct = dir([obj.dataSource '/*_Wav1_Ch*.sev']);
                for ch = 1:numel(obj.dirStruct)
                    chStr = ['_Ch' num2str(ch) '.sev'];
                    index = find(contains({obj.dirStruct.name},chStr));
                    obj.dirStruct(index).index = ch;
                    fStruct = obj.dirStruct(index);
                    obj.fidArray(ch) = fopen(fullfile(fStruct.folder,fStruct.name),'rb');
                end
                %sort dirStruct to correspond to ch number
                [~,sortOrder] = sortrows({obj.dirStruct.index}');
                obj.dirStruct = obj.dirStruct(sortOrder);
            else
                error('DirNotFound: TDT data dir %s does not exist',obj.dataSource);
            end
        end
        
        function [] = checkChannelCount(obj, nChannels)
            if ~(nChannels <= numel(obj.dirStruct))
                error('NChannels [%d] specified are more than number of .sev files [%d].', ...
                    nChannels, numel(obj.dirStruct));
            end
        end
        
    end
    
end

