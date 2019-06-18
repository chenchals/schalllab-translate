classdef TDTAdapterTest < matlab.unittest.TestCase
    %TDTADAPTERTEST Test TDT data adapter
    %   
    
    properties
        adapter;
    end
    
    properties
        recordingSystem;
        datasource;
        dataMultiplier;      
    end
    
    %% SETUP: Class level 
    methods(TestClassSetup)
        function setupProps(obj)
            obj.recordingSystem = 'tdt';
            obj.datasource = '/scratch/ksData/TESTDATA/Init_SetUp-160715-150111/*_Wav1_*.sev';
            obj.dataMultiplier = 1E6;
        end
        
        
    end
    
    %% SETUP: TestCase
    methods (TestMethodSetup)
        function getTDTAdapter(obj)
            obj.adapter = interface.IDataAdapter.newDataAdapter(obj.recordingSystem,obj.datasource,'rawDataScaleFactor',obj.dataMultiplier);
        end

    end
    
   %% TEARDOWN: TestCase
    methods (TestMethodTeardown)
        function clearTDTAdapter(obj)
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
            %header = dataAdapter.header;
            obj.assertEqual(obj.dataMultiplier,dataAdapter.rawDataScaleFactor,'obj.rawDataScaleFactor');
            obj.assertEqual('Init_SetUp-160715-150111',dataAdapter.session,'obj.session');

            
        end
        
        function testReadRaw(obj)
            nChan =10;
            nSamples = 100;
            dataAdapter = obj.adapter;
            obj.assertEqual(0,dataAdapter.lastSampleRead);
            buffer = dataAdapter.readRaw(nChan,nSamples);
            obj.assertEqual([nChan nSamples],size(buffer));
            obj.assertEqual(nSamples,dataAdapter.lastSampleRead);       
        end
    
        function testReadRawParallel(obj)
            obj.assumeFail();
            nChan = 10;
            nSamples = 100;
            dataAdapter = obj.adapter;
            obj.assertEqual(0,dataAdapter.lastSampleRead,'lastSampleRead');
            gcp(); % create pool if not exist            
            buffer = dataAdapter.readRaw(nChan,nSamples);
            obj.assertEqual([nChan nSamples],size(buffer));
            obj.assertEqual(nSamples,dataAdapter.lastSampleRead);       
            delete(gcp('nocreate')); % delete current pool
        end
             
        
        function testBatchRead(obj)
            nChan = 10;
            nSamples = 100;
            nBatches =10;
            dataAdapter = obj.adapter;
            obj.assertEqual(0,dataAdapter.lastSampleRead,'lastSampleRead');
            buffer = cell(nBatches,1);
            for ii = 1:nBatches
                %readOffsetAllChan, nChannels, nSamples, dataTypeString, channelOffset
                buffer{ii} = dataAdapter.batchRead([],nChan,nSamples,[],0);
            end
            buffer = cell2mat(buffer');
            obj.assertEqual([nChan nSamples*nBatches],size(buffer));
            obj.assertEqual(nSamples*nBatches,dataAdapter.lastSampleRead);       
        end

    end
    
    
end

