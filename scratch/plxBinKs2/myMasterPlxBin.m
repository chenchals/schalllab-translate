function [rez] = myMasterPlxBin(ops)
sortData = 1;

ops.fbinary = ops.dataSessionFile;
%% Channel Map file
copyChanMap = fullfile(ops.rootZ,ops.chanMap);
copyfile(which(ops.chanMap), copyChanMap,'f');
ops.chanMapUsed = copyChanMap;

%% Data adapter for reading data
ops.dataAdapter = interface.IDataAdapter.newDataAdapter(ops.recordingSystem,...
    ops.fbinary,'nChannels',ops.NchanTOT,'fs',ops.fs);
%ops.dataAdapter = DataAdapter.newDataAdapter(ops.recordingSystem,ops.fbinary,ops.rawDataMultiplier);
ops.dataTypeBytes       = 2; % datatpe for the sample point -int16=2 4=single
ops.dataTypeString      = 'int16'; % datatype of sample point - 'int16' or 'single'
ops.headerBytes         = 0;

%% Run kilosort2 on the simulated data
if( sortData )
    
    % common options for every probe
    gpuDevice(1);   %re-initialize GPU
    
    % preprocess data to create temp_wh.dat
    rez = clusterWithKilosort(ops);
    
    % pre-clustering to re-order batches by depth
    rez = clusterSingleBatches(rez);
    
    % main optimization
    % learnAndSolve8;
    rez = learnAndSolve8b(rez);
    
    % final splits
    rez = find_merges(rez, 1);
    
    % final splits by SVD
    rez    = splitAllClusters(rez, 1);
    
    % final splits by amplitudes
    rez = splitAllClusters(rez, 0);
    
    % decide on cutoff
    rez = set_cutoff(rez);
    
    % this saves to Phy
    rezToPhy(rez, ops.rootZ);
    
    % discard features in final rez file (too slow to save)
    rez.cProj = [];
    rez.cProjPC = [];
    
    fname = fullfile(ops.rootZ, 'rezFinal.mat');
    save(fname, 'rez', '-v7.3');
    
    sum(rez.good>0)
    fileID = fopen(fullfile(ops.rootZ, 'cluster_group.tsv'),'w');
    fprintf(fileID, 'cluster_id%sgroup', char(9));
    fprintf(fileID, char([13 10]));
    for k = 1:length(rez.good)
        if rez.good(k)
            fprintf(fileID, '%d%sgood', k-1, char(9));
            fprintf(fileID, char([13 10]));
        end
    end
    fclose(fileID);
    
    % remove temporary file
    delete(ops.fproc);
end
end

