
testSession = 'Init_SetUp-160713-144841';%'Init_SetUp-161005-134520';(64 chans)
baseDataDir = '/Volumes/schalllab/data/Kaleb/dataRaw';
sessions = dir(baseDataDir);
sessions = sessions(arrayfun(@(x) isempty(regexp(x.name,'^\.','match')),sessions));
sessions = {sessions.name}';

sessions = sessions(contains(sessions,testSession));

chansPerProbe = 32;
% masterTdt(baseDataDir, baseResultDir, sessionDir, probeNum)
for repeat = 1:3
baseResultDir = fullfile('./testProcess/local',['repeat_',num2str(repeat)]);
for sessInd = 1: numel(sessions)
    session = sessions{sessInd};
    % Check if there are 64 channels?
    numProbes = floor(numel(dir(fullfile(baseDataDir, session, '/*Wav1_Ch*.sev')))/chansPerProbe);
    for probeNum = 1:numProbes
        fprintf('\nDoing session %s probeNum %d of %d\n',session,probeNum,numProbes);
        tic;
        masterTdt(baseDataDir, baseResultDir, session, probeNum);
        toc;
        fprintf('\n');
    end
    out = processKiloSortResults(fullfile(baseResultDir,session));
    fprintf('**********************\n');
end
end