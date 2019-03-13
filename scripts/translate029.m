%codesDir = '/Volumes/schalllab/Users/Chenchal/Tempo_NewCode/Joule-190312-162436/ProcLib/CMD';


sessionBaseDir = 'T:/Users/Chenchal/Tempo_NewCode/Joule';
baseSaveDir = 'T:/Users/Chenchal/Tempo_NewCode/dataProcessed';
sessName = 'Joule-190313-133648';
procLibDir =fullfile(sessionBaseDir, sessName, 'ProcLib');
eventDefFile = fullfile(procLibDir,'CMD/EVENTDEF.PRO');
infosDefFile = fullfile(procLibDir,'CMD/INFOS.PRO');

% set it up in TranslateTDT
%     opts.useTaskEndCode = true;
%     opts.dropNaNTrialStartTrials = false;
%     opts.useNegativeValsInInfos = true;
%     opts.infosNegativeOffset = 32768;


opts.sessionDir = fullfile(sessionBaseDir,sessName);
opts.baseSaveDir = baseSaveDir;
opts.eventDefFile = eventDefFile;
opts.infosDefFile = infosDefFile; 
opts.splitEyeIntoTrials = false;
opts.hasEdfDataFile = 0;
% opts.edf.useEye = 'X';
% opts.edf.voltRange = [-5 5];
% opts.edf.signalRange = [-0.2 1.2];
% opts.edf.pixelRange = [0 1024];


ZZ = TDTTranslator(opts);


[Task, TaskInfos, TrialEyes, EventCodec, InfosCodec, SessionInfo] = ZZ.translate(0);



