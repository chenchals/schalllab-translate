%function [trialEyes] = tdtExtractEyes(sessionDir, trialStartTimes, varargin)

codesDir = 'T:/Users/Chenchal/Tempo_NewCode/Joule/Joule-190313-133648/ProcLib/CMD';
sessionDir = 'T:/Users/Chenchal/Tempo_NewCode/Joule/Joule-190313-133648';
eventCodecFile = fullfile(codesDir,'EVENTDEF.PRO');
infosCodecFile = fullfile(codesDir, 'INFOS.PRO');

[trialEvents, trialInfos, evCodec, infosCodec, tdtInfos ] = tdtExtractEvents(sessionDir, eventCodecFile, infosCodecFile);

trialStartTimes = trialEvents.TrialStart_;
trialEndTimes = trialEvents.Eot_;

[trialEyes] = tdtExtractEyes(sessionDir,[],[]);

[trialEyes2] = tdtExtractEyes(sessionDir, trialStartTimes, trialEndTimes);


