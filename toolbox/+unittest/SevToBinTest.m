classdef SevToBinTest < matlab.unittest.TestCase
    %SEVTOBINTEST Test conversion form sev file to bin file
    %     The timestamops for all channels must be interleaved
    
    %%
    properties
        tdtAdapter;
        binAdapter;
        
        tdtProps;
        binProps;
    end
    
    %% SETUP: Class level
    methods(TestClassSetup)
        function setupProps(obj)
            obj.tdtProps.recordingSystem = 'sev';
            obj.tdtProps.datasource = '/scratch/ksData/TESTDATA/Init_SetUp-160715-150111/*_Wav1_*.sev';
            obj.tdtProps.dataMultiplier = 1E6;%multiplier used during write to binary
            obj.binProps.recordingSystem = 'bin';
            obj.binProps.datasource = '/scratch/ksData/TESTDATA/Init_SetUp-160715-150111/Init_SetUp-160715-150111.bin';
            obj.binProps.dataMultiplier = 1;
        end
        
        
    end
    
    %% SETUP: TestCase
    methods (TestMethodSetup)
        function getAdapters(obj)
            obj.tdtAdapter = interface.IDataAdapter.newDataAdapter(obj.tdtProps.recordingSystem,obj.tdtProps.datasource,'rawDataScaleFactor',obj.tdtProps.dataMultiplier);
            obj.binAdapter = interface.IDataAdapter.newDataAdapter(obj.binProps.recordingSystem,obj.binProps.datasource,'nChannels',64);
        end
        
    end
    
    %% TEARDOWN: TestCase
    methods (TestMethodTeardown)
        function clearTDTAdapter(obj)
            obj.tdtAdapter = [];
            obj.binAdapter = [];
        end
    end
    
    
    %% TEARDOWN
    methods (TestClassTeardown=true)
        function clearVars(obj)
            fprintf('In teardown..\n');
            clearvars 'obj';
        end
    end
    
    %% Test Methods
    methods (Test)
        function testVerifyReadAllChannels(obj)
            %obj.assumeFail();
            nChan = 64;
            nSamples = 100;
            
            tdtBuffer = int16(obj.tdtAdapter.readRaw(nChan,nSamples));
            binBuffer = obj.binAdapter.readRaw(nChan,nSamples);
            
            obj.assertEqual(tdtBuffer,binBuffer,'Fail... buffers are not same');
        end
        function testVerifyReadLessThanAllChannels(obj)
            %obj.assumeFail();
            nChan = 10;
            nSamples = 100;
            
            tdtBuffer = int16(obj.tdtAdapter.readRaw(nChan,nSamples));
            binBuffer = obj.binAdapter.readRaw(nChan,nSamples);
            
            obj.assertEqual(tdtBuffer,binBuffer,'Fail... buffers are not same');
        end
        
        function testVerifyReadAllChannelsBatch(obj)
            %obj.assumeFail();
            nChan = 64;
            nSamples = 100;
            nBatches =10;
            tdtBuffer = cell(nBatches,1);            
            binBuffer = cell(nBatches,1);
            for ii = 1:nBatches
                %readOffsetAllChan, nChannels, nSamples, dataTypeString, channelOffset
                tdtReadOffsetAllChan = max(0, (ii-1)*nSamples*obj.tdtAdapter.dataWidthBytes*obj.tdtAdapter.nChannelsTotal);
                tdtBuffer{ii} = obj.tdtAdapter.batchRead(tdtReadOffsetAllChan,nChan,nSamples,[],0);
                binReadOffsetAllChan = max(0, (ii-1)*nSamples*obj.binAdapter.dataWidthBytes*obj.binAdapter.nChannelsTotal);
                binBuffer{ii} = obj.binAdapter.batchRead(binReadOffsetAllChan,nChan,nSamples,[],0);
            end
            tdtBuffer = cell2mat(tdtBuffer');
            tdtBuffer = int16(tdtBuffer);
            binBuffer = cell2mat(binBuffer');
            
            obj.assertEqual(tdtBuffer,binBuffer,'Fail... buffers are not same');
        end        
        
        
        function testVerifyReadLessThanAllChannelsBatch(obj)
            %obj.assumeFail();
            nChan = 20;
            nSamples = 100;
            nBatches =10;
            tdtBuffer = cell(nBatches,1);            
            binBuffer = cell(nBatches,1);
            for ii = 1:nBatches
                %readOffsetAllChan, nChannels, nSamples, dataTypeString, channelOffset
                tdtReadOffsetAllChan = max(0, (ii-1)*nSamples*obj.tdtAdapter.dataWidthBytes*obj.tdtAdapter.nChannelsTotal);
                tdtBuffer{ii} = obj.tdtAdapter.batchRead(tdtReadOffsetAllChan,nChan,nSamples,[],0);
                binReadOffsetAllChan = max(0, (ii-1)*nSamples*obj.binAdapter.dataWidthBytes*obj.binAdapter.nChannelsTotal);
                binBuffer{ii} = obj.binAdapter.batchRead(binReadOffsetAllChan,nChan,nSamples,[],0);
            end
            tdtBuffer = cell2mat(tdtBuffer');
            tdtBuffer = int16(tdtBuffer);
            binBuffer = cell2mat(binBuffer');
            
            obj.assertEqual(tdtBuffer,binBuffer,'Fail... buffers are not same');
        end         
        
        
    end
    
    %%
end