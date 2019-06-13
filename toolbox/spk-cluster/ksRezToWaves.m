%rezFinalPath = '/scratch/ksDataProcessed/SIMULDATA/eMouseSimData';
rezFinalPath = '/scratch/ksDataProcessed/TESTDATA/Init_SetUp-160811-145107-SD-6';
rez = load(fullfile(rezFinalPath,'rezFinal.mat'));
rez = rez.rez;
ops = rez.ops;
resultsMatPath = rezFinalPath;
resultsPhyPath = fullfile(rezFinalPath,'phy');
Fs = ops.fs;
load(fullfile(resultsMatPath, ops.chanMapName));
yc = ycoords(connected); xc = xcoords(connected);
% clu is a length nSpikes vector with the cluster identities of every
% spike
clu = readNPY(fullfile(resultsPhyPath,  'spike_clusters.npy'));
spikeTemplates = readNPY(fullfile(resultsPhyPath,  'spike_templates.npy')); % note: zero-indexed
% ss is a length nSpikes vector with the spike time of every spike (in
% samples)
ss = readNPY(fullfile(resultsPhyPath,  'spike_times.npy'));

% convert to times in seconds
st = double(ss)/Fs;


