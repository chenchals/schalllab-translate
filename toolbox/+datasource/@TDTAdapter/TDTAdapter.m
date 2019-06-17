classdef TDTAdapter < interface.IDataAdapter
    %TDTADAPTER Adapter for TD recordings
    %   
    
    
    methods
        function obj = TDTAdapter(dataSource)
            obj.dataConfig.datasource=dataSource;
            
            
                    %         recordingSystem;  % Recording system : TDT, EMouse
        %         dataPath;         % Path to raw recording file(s)
        %         session;          % Session name
        %         dataFiles;         % raw data file(s) pattern

            try
                d = dir(dataSource);
                dataFile = fullfile(d(1).folder,d(1).name);
                obj.dataConfig.fileHeader = readHeader(obj,dataFile);
                [obj.dataConfig.dataPath,obj.dataConfig.session]=fileparts(dataFile);
                [~,chNos]=sort(cellfun(@(x) str2double(x{1}),regexp( {d.name}, '_Ch(\d+)', 'tokens' )));
                obj.dataConfig.dataFiles = strcat({d(chNos).folder},filesep,{d(chNos).name})';
                obj.nChannels = max(chNos);
                
            catch ME
                disp(ME);
            end
            

        end       
    end
    
    
    
end

