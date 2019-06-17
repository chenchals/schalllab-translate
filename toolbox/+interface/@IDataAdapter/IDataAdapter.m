classdef (Abstract=true) IDataAdapter < handle
    %IDATAADAPTER Interface for raw data files
    %
    
    properties (SetAccess=protected,SetObservable=true)
        dataConfig; % is set in the constructor
        %         recordingSystem;  % Recording system : TDT, EMouse
        %         dataPath;         % Path to raw recording file(s)
        %         session;          % Session name
        %         dataFiles;         % raw data file(s) pattern
        
        
    end
    
    properties (SetAccess=protected, SetObservable=true, Transient=true, Dependent=true)
        isOpen = 0;           % Flag if dataset is ready for reading
        nChannels;            % total number of channels
        nSamplesPerChannel;   % No of data points for each channel
        nHeaderBytes;         % Number of header bytes before the first sample
        
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
                    adapter.dataConfig.rawDataMultiplier = 1.0;
                case 'tdt'
                    if numel(varargin)>0
                        rawDataMultiplier = varargin{1};
                    else
                        rawDataMultiplier = 1.0;
                    end
                    
                    adapter = datasource.TDTAdapter(source);
                    adapter.dataConfig.rawDataMultiplier = rawDataMultiplier;
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
        % isOpen
        function set.isOpen(obj, trueFalse)
            obj.isOpen = trueFalse;
        end
        function [val] = get.isOpen(obj)
            val = obj.isOpen;
        end
        
        % nChannels
        function set.nChannels(obj, val)
            obj.nChannels = val;
        end
        function [val] = get.nChannels(obj)
            val = obj.nChannels;
        end
        
        % nSamplesPerChannel
        function set.nSamplesPerChannel(obj, val)
            obj.nSamplesPerChannel = val;
        end
        function [val] = get.nSamplesPerChannel(obj)
            val = obj.nSamplesPerChannel;
        end
        
        % nHeaderBytes
        function set.nHeaderBytes(obj, val)
            obj.nHeaderBytes = val;
        end
        function [val] = get.nHeaderBytes(obj)
            val = obj.nHeaderBytes;
        end
        
    end
    
end

