classdef RawBinAdapterTest < matlab.unittest.TestCase
    %RAWBINADAPTERTEST Test Raw Binary file data adapter
    %     similar to eMouse data
    
    properties
        adapter;
    end
    
    properties
        recordingSystem;
        datasource;
        dataMultiplier;  
        nChannels; % need to be specified for a binary file for 
    end
    
    %% SETUP: Class level 
    methods(TestClassSetup)
        function setupProps(obj)
            obj.recordingSystem = 'emouse';
            obj.datasource = '/scratch/ksData/SIMULDATA/eMouseSimData/sim_binary.imec.ap.bin';
            obj.dataMultiplier = 1.0;
            obj.nChannels = 64;
        end
        
        
    end
    
    %% SETUP: TestCase
    methods (TestMethodSetup)
        function getRawBinAdapter(obj)
            obj.adapter = interface.IDataAdapter.newDataAdapter(obj.recordingSystem,obj.datasource,...
                                                               'nChannels',obj.nChannels,...           
                                                               'rawDataScaleFactor',obj.dataMultiplier...
                                                               );
        end

    end
    
   %% TEARDOWN: TestCase
    methods (TestMethodTeardown)
        function clearRawBinAdapter(obj)
            obj.adapter = [];
        end
    end

    
    %% TEARDOWN
    methods (TestClassTeardown=true)
        function clearVars(obj)
            fprintf('In teardown..\n'); 
            clearvars 'obj';
        end
   
    end
   
    %% Test methods
    methods (Test=true)
        function testConstructor(obj)
            dataAdapter = obj.adapter;
            obj.assertEqual(obj.dataMultiplier,dataAdapter.rawDataScaleFactor,'obj.rawDataScaleFactor');
            obj.assertEqual('eMouseSimData',dataAdapter.session,'obj.session');            
        end
        
        function testReadRaw(obj)
            nChan = 10;
            nSamples = 100;
            dataAdapter = obj.adapter;
            obj.assertEqual(0,dataAdapter.lastSampleRead);
            buffer = dataAdapter.readRaw(nChan,nSamples);
            obj.assertEqual([nChan nSamples],size(buffer));
            obj.assertEqual(nSamples*dataAdapter.nChannelsTotal,dataAdapter.lastSampleRead);       
        end

        function testBatchRead(obj)
            nChan = 10; % not reading all channels
            nSamples = 100;
            nBatches =10;
            dataAdapter = obj.adapter;
            obj.assertEqual(0,dataAdapter.lastSampleRead,'lastSampleRead');
            buffer = cell(nBatches,1);
            for ii = 1:nBatches
                %readOffsetAllChan, nChannels, nSamples, dataTypeString, channelOffset
                readOffsetAllChan = max(0, (ii-1)*nSamples*dataAdapter.dataWidthBytes*dataAdapter.nChannelsTotal);
                buffer{ii} = dataAdapter.batchRead(readOffsetAllChan,nChan,nSamples,[],0);
            end
            buffer = cell2mat(buffer');
            obj.assertEqual([nChan nSamples*nBatches],size(buffer));
            obj.assertEqual(nSamples*nBatches*dataAdapter.nChannelsTotal,dataAdapter.lastSampleRead);       
        end

    end
    
    
end

