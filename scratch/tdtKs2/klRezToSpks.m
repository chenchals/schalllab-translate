%% Pull waveforms and spike times for each cluster... but also figure out the channel

function out = klRezToSpks(rez,varargin)

% Set defaults
sampWin = -25:25;
nChannels = 1:rez.ops.NchanTOT;
percThresh = .05;
chanOff = 0;
sampleRate = 24414;
resultPath = './dataProcessed';

% Decode varargin
varStrInd = find(cellfun(@ischar,varargin));
for iv = 1:2:length(varStrInd)
    switch varargin{varStrInd(iv)}
        case {'-r'}
            resultPath = varargin{varStrInd(iv)+1};
    end
end

% Get what we need from rez before clearing
[~,sessStr] = fileparts(rez.ops.resultPath(1:(end-1)));
resultPath = [resultPath,filesep,sessStr];

resultPath = 'testProcess/Init_SetUp-160713-144841_probe1/klrez2spks';

isPos = rez.ops.spkTh > 0;
allWaves = rez.waves;
clear rez;

% Get clusters and times
clusts = readNPY([resultPath, '/spike_clusters.npy']);% rez.st3(:,5);
tms = double(readNPY([resultPath,'/spike_times.npy']));

% Get unique clusters
uClusts = unique(clusts);

% Get a list of times for later
tmVect = (1:max(tms)).*(1000/sampleRate);

% Make a vector of number of units identified per channel
chanNoUnits = zeros(1,max(nChannels));

% Start cluster loop
for ic = 1:length(uClusts)
    clustNo = uClusts(ic);
    fprintf('Pulling waves for cluster %d (%d of %d)...',clustNo,ic,length(uClusts));
    % Get this cluster waveforms and times
    clusterWaves = allWaves(clusts==clustNo,:,:);
    clusterTimes = tms(clusts==clustNo);
    if isPos
        [~,maxAbs] = max(clusterWaves(:,sampWin==0,:),[],3);
    else
        [~,maxAbs] = min(clusterWaves(:,sampWin==0,:),[],3);
    end
    [nChanClustA,cChanClustA] = hist(maxAbs,1:32);
    
    % Which channels have at least 5% of this cluster's spikes?
    chansMeetCrit = cChanClustA(nChanClustA > (percThresh*sum(nChanClustA)));
    
    % Loop through the channels that do have at leeast 5%...
    uMaxChan = unique(chansMeetCrit);
    for iu = 1:length(uMaxChan)
        waves = clusterWaves(maxAbs==uMaxChan(iu),:,uMaxChan(iu));
        spkTimes = tmVect(clusterTimes(maxAbs==uMaxChan(iu)));
        % Unit id
        chanNoUnits(uMaxChan(iu)) = chanNoUnits(uMaxChan(iu)) + 1;
        unitStr = sprintf('chan%02d%s',uMaxChan(iu)+chanOff,num2abc(chanNoUnits(uMaxChan(iu))));
        
        save([resultPath,filesep,unitStr,'.mat'],'spkTimes','waves','clustNo');
        out.(unitStr).spkTimes = spkTimes;
        out.(unitStr).waves = waves;
        out.(unitStr).clustNo = clustNo;
        clear spkTimes waves

    end
    fprintf('\n');
    
end

