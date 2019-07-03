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
%             totalBytes = 0;
            minBytes = inf;
            for i = 1:length(obj.dirStruct)
                for ch = 1:nChannels
                    fStruct = obj.dirStruct(i).subName(ch);
                    minBytes = min([minBytes,(fStruct.bytes-40)]);
    %                 totalBytes = totalBytes + fStruct.bytes - 40;
                end
            end
            sampsToRead = minBytes/nBytesPerSample;%floor(totalBytes/nChannels/nBytesPerSample);
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
                    break
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
        
        % Read sample data for range of [sampleWin] centered on samples
        function [ waveforms ] = getWaveforms(obj, sampleWin, samples, channelNos, chOffset, maxSamples)
           wtemp = cell(length(channelNos),1);
           dataType = 'single';
           header = 40;
           nSamples = size(samples,1);
           % Cut out bad samples. Read first channel to get number of
           goodSpikes = logical(samples(:,1) > (-1*sampleWin(1)) & samples < (maxSamples-sampleWin(end)));
           samples = samples(goodSpikes,:);
           sampWinLength = length(sampleWin);
           nChannels = length(channelNos);
           wavIndices = arrayfun(@(x) sampleWin+x,samples(:,1),'UniformOutput', false);
           wavIndices = cell2mat(wavIndices);
           minLoc = (min(wavIndices(:))-1)*4;
           nSampsToRead = max(wavIndices(:)) - min(wavIndices(:)) + 1;
           wavIndicesRel = wavIndices - min(wavIndices(:)) +1;
           clear wavIndices;
           myChannels = (1:nChannels)+chOffset;
           waveforms = zeros(nSamples,sampWinLength,nChannels,'single');
           for ch = fliplr(myChannels)
               fprintf('Doing channel %d\n',ch);
               fid = obj.fidArray(ch);
               fseek(fid,minLoc+header,'bof');
               temp = fread(fid, nSampsToRead, ['*' dataType]);
               waveforms(goodSpikes,1:sampWinLength,ch-chOffset) = reshape(temp(wavIndicesRel),sum(goodSpikes),sampWinLength);%wtemp{ch-chOffset} = temp(wavIndicesRel);
           end
%            waveforms=reshape(cell2mat(wtemp'),nSamples,sampWinLength,nChannels);
           % verify diff should be zero for channel 1
           %DD=WF(:,:,1)-cell2mat(WW39(1));
        end
    end
    
    methods (Access=private)
        
        function [] = updateFileHandles(obj)
            for i = 1:length(obj.dataSource)
                if exist(obj.dataSource{i},'dir')==7
                    raw = 0;
                    obj.dirStruct(i).subName = dir([obj.dataSource{i} '/*_Wav1_Ch*.sev']);
                    if length(obj.dirStruct(i).subName) == 0
                        obj.dirStruct(i).subName = dir([obj.dataSource{i} '/*_RSn1_ch*.sev']);
                        raw = 1;
                    end
                    for ch = 1:numel(obj.dirStruct(i).subName)
                        if raw
                            chStr = ['_ch' num2str(ch) '.sev'];
                        else
                            chStr = ['_Ch' num2str(ch) '.sev'];
                        end
                        index = find(contains({obj.dirStruct(i).subName.name},chStr));
                        obj.dirStruct(i).subName(index).index = ch;
                        fStruct = obj.dirStruct(i).subName(index);
                        obj.fidArray(ch) = fopen(fullfile(fStruct.folder,fStruct.name),'rb');
                    end
                    %sort dirStruct to correspond to ch number
                    [~,sortOrder] = sortrows({obj.dirStruct(i).subName.index}');
                    obj.dirStruct(i).subName = obj.dirStruct(i).subName(sortOrder);
                else
                    error('DirNotFound: TDT data dir %s does not exist',obj.dataSource);
                end
            end
        end
        
        function [] = checkChannelCount(obj, nChannels)
            for i = 1:length(obj.dirStruct)
                if ~(nChannels <= numel(obj.dirStruct(i).subName))
                    error('NChannels [%d] specified are more than number of .sev files [%d].', ...
                        nChannels, numel(obj.dirStruct(i).subName));
                end
            end
        end
        
    end
    
end

