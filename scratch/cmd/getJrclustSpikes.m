sessionBaseDir = 'data/Joule/cmanding/ephys/TESTDATA/In-Situ';
baseSaveDir = 'dataProcessed/Joule/cmanding/ephys/TESTDATA/In-Situ';
sessName = 'Joule-190731-121704';
spikesMatFile = fullfile(baseSaveDir,sessName,'Spikes.mat');
lowerAlpha = 96;% 97='a' 98 ='b' etc
% jrclust output
jrcResFile = fullfile(baseSaveDir,sessName,'jrclust','master_jrclust_res.mat');
res = load(jrcResFile);
allSpikes = struct();
channels = unique(res.spikeSites);
fs = 24414.0625; % sampling frequency Hz
for ch = 1:numel(channels)   
    chan = channels(ch);
    unitString = num2str(chan,'DSP%02i');
    wavString = num2str(chan,'WAV%02i');
    spkIdsByCh = res.spikesBySite{ch};
    spkClustNos = res.spikeClusters(spkIdsByCh);
    spkTimeSamples = res.spikeTimes(spkIdsByCh);
    uniqClustNos = unique(spkClustNos);
    uniqClustNos(uniqClustNos<0)=[];
    for cl = 1:numel(uniqClustNos)
        clustNo = uniqClustNos(cl);
        clustLetter = char(cl+lowerAlpha);
        clustTimeSamples = spkTimeSamples(spkClustNos==clustNo);
        allSpikes.([unitString clustLetter]) = double(clustTimeSamples)*(1000.0/fs);
        % all waves not yet
        allSpikes.([wavString clustLetter]) = NaN;
    end
end
% save Spike times and waveforms
save(spikesMatFile,'-struct', 'allSpikes')



