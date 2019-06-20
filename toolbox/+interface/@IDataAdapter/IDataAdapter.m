classdef (Abstract=true) IDataAdapter < handle
    %IDATAADAPTER Interface for raw data files
    %
    
    properties (SetAccess=protected, SetObservable)
        recordingSystem;   % Recording system : TDT, EMouse
        rawDataScaleFactor % Multiplication factor for raw data to convert sample-units to uV       
        dataPath;          % Path to raw recording file(s)
        session;           % Session name
        dataFiles;         % raw data file(s), full path
        header;            % file header, if any
        headerOffset;      % Number of header bytes before the first sample
        fileSizeBytes;     % Size of each dataFile in dataFiles, including header
        dataForm;          %'int16','single'...
        dataWidthBytes;    % number of bytes for each sample data point
        dataSize;          % [nChannels x nSamples]
        dataFs;            % data sampling frequency
        nShanks;           % no of vector probes for multi-probe recordings
    end
    
    properties (SetAccess=protected, SetObservable, Transient, Dependent)
        nChannels;            % total number of channels
        nSamplesPerChannel;   % No of data points for each channel      
    end
    
    properties (Hidden, SetAccess=protected, SetObservable, Transient)
        isOpen = 0;           % Flag if dataset is ready for reading
    end
    
    
    %% Static factory method to get correct dataAdapter
    methods (Static)
        function adapter = newDataAdapter(recordingSystem, source, varargin)
            switch lower(recordingSystem)
                case 'emouse'
                    nChannels = 34; % default for KS1
                    if numel(varargin)>0
                        nChannels = varargin{1};
                    end
                    adapter = datasource.BinaryAdapter(source,nChannels);
                    adapter.rawDataScaleFactor = 1.0;
                case 'tdt'
                    adapter = datasource.TDTAdapter(source,varargin);
                otherwise
                    error('Type must be either emouse or tdt');
            end
        end
    end
    
    %% Abstract Methods for reading from raw file(s)
    methods (Abstract=true)
        data = readRaw(obj, nChannels, nSamples);
    end
    
    %% Getter/Setter methods
    methods
        % nChannels
        function [val] = get.nChannels(obj)
            val = obj.dataSize(1);
        end
        
        % nSamplesPerChannel
        function [val] = get.nSamplesPerChannel(obj)
            val = obj.dataSize(2);
        end
        
        
    end
    
end

