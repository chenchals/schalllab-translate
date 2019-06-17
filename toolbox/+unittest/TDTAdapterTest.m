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
    
    %% SETUP
    methods(TestClassSetup=true)
        function setupProps(obj)
            obj.recordingSystem = 'tdt';
            obj.datasource = '/scratch/ksData/TESTDATA/Init_SetUp-160715-150111/*_Wav1_*.sev';
            obj.dataMultiplier = 1E6;
        end
        
        function getTDTAdapter(obj)
            obj.adapter = interface.IDataAdapter.newDataAdapter(obj.recordingSystem,obj.datasource,obj.dataMultiplier);
        end
        
    end
    
    %% TEARDOWN
    methods (TestClassTeardown=true)
        function clearVars(obj)
            fprintf('In teardown..\n');     
        end
   
    end
   
    %% Test methods
    methods (Test=true)
        function testUserConfig(obj)
            adapter = obj.adapter;
            dataConfig = adapter.dataConfig;
            
        end
        
    
    
    end
    
    
end

