sessName = 'Leonardo-180928-170509_singletonPlusDistractors';

sessName = 'Leonardo-180928-150814'; % not working... choice of correct INFOS.pro

on10_03_session = 'Leonardo-181003-142453';
on10_03 ='/Users/subravcr/teba/local/Tempo/rigProcLibs/FixRoom030/ProcLib-LEO-18-10-03';
sessName = on10_03_session;
procLib = on10_03;

opts.sessionDir = fullfile('data/Leonardo/Eyelink-EDF',sessName);
opts.baseSaveDir = 'dataProcessed/Leonardo';
opts.eventDefFile = fullfile(procLib,'EVENTDEF.pro');
opts.infosDefFile = fullfile(procLib,'search/INFOS.pro'); 
opts.hasEdfDataFile = 0;
opts.edf.useEye = 'X';
opts.edf.voltRange = [-5 5];
opts.edf.signalRange = [-0.2 1.2];
opts.edf.pixelRange = [0 1024];


ZZ = TDTTranslator(opts);


[Task, TaskInfos, TrialEyes, EventCodec, InfosCodec, SessionInfo] = ZZ.translate(0);



