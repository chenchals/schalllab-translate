%% Pull waveforms and spike times for each cluster... but also figure out the channel

function out = clusterRez2Spikes_XX(sessionDir)
    out = [];
    % Set defaults
    sampWin = -25:25;
    %nChannels = 1:rez.ops.NchanTOT;
    nChannels = 32;
    percThresh = .05;
    sampleRate = 24414;
    sample2TimeFactor = (1000/sampleRate);
    % For each session
        probeDir = sessionDir;
        fprintf('Loading %s/rezFinal.mat...',probeDir);
        load(fullfile(probeDir,'rezFinal.mat'));
        fprintf('done\n');
        size(rez.waves)
        allWaves = rez.waves;
        spikeThreshold = rez.ops.spkTh;
        clear rez

        % Get clusters
        clusterNums = readNPY(fullfile(probeDir, 'phy/spike_clusters.npy'));% rez.st3(:,5);
        clusterIds = unique(clusterNums);
        % Get timeSamples
        timeSamples = double(readNPY(fullfile(probeDir,'phy/spike_times.npy')));

        unitsPerChannel = zeros(1,nChannels);

        for clusterIdIndex = 1:length(clusterIds)
            clusterId = clusterIds(clusterIdIndex);
            fprintf('Pulling waves for cluster %d (%d of %d)...\n',clusterId,clusterIdIndex,length(clusterIds));
            % Get this cluster waveforms and times
            clusterWaves = allWaves(clusterNums==clusterId,:,:);
            clusterTimes = timeSamples(clusterNums==clusterId);
            if spikeThreshold < 0
                [~,maxAbs] = min(clusterWaves(:,sampWin==0,:),[],3);
            else
                [~,maxAbs] = max(clusterWaves(:,sampWin==0,:),[],3);
            end
            [nChanClustA,cChanClustA] = hist(maxAbs,1:32);

            % Which channels have at least 5% of this cluster's spikes?
            chansMeetCrit = cChanClustA(nChanClustA > (percThresh*sum(nChanClustA)));

            % Loop through the channels that do have at leeast 5%...
            uMaxChan = unique(chansMeetCrit);
            for iu = 1:length(uMaxChan)
                waves = clusterWaves(maxAbs==uMaxChan(iu),:,uMaxChan(iu));
                spkTimes = clusterTimes(maxAbs==uMaxChan(iu)).*sample2TimeFactor;
                % Unit id
                unitsPerChannel(uMaxChan(iu)) = unitsPerChannel(uMaxChan(iu)) + 1;
                channelLetter = int2letter(unitsPerChannel(uMaxChan(iu)));
                unitStr = sprintf('chan%02d%s',uMaxChan(iu)+channelNoOffset,channelLetter);
                oFile = fullfile(sessionDir,[unitStr,'.mat']);
                fprintf('\tSaving to file %s\n',oFile);
                save(oFile,'spkTimes','waves','clusterId');
                out.(unitStr).spkTimes = spkTimes;
                out.(unitStr).waves = waves;
                out.(unitStr).clustNo = clusterId;
                clear spkTimes waves

            end
            fprintf('\n');
        end
 
end

function [ out ] = getSubDirs(dirStruct)
   out = dirStruct(arrayfun(@(x) isempty(regexp(x.name,'^\.','match')) && x.isdir==1,dirStruct));
end
