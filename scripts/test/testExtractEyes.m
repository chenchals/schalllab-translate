%function [trialEyes] = tdtExtractEyes(sessionDir, trialStartTimes, varargin)

codesDir = '/Volumes/schalllab/Users/Chenchal/Tempo_NewCode/Joule/Joule-190312-162436/ProcLib/CMD';
sessionDir = '/Volumes/schalllab/Users/Chenchal/Tempo_NewCode/Joule/Joule-190312-162436';
eventCodecFile = fullfile(codesDir,'EVENTDEF.PRO');
infosCodecFile = fullfile(codesDir, 'INFOS.PRO');

[trialEvents, trialInfos, evCodec, infosCodec, tdtInfos ] = tdtExtractEvents(sessionDir, eventCodecFile, infosCodecFile);

trialStartTimes = trialEvents.TrialStart_;
trialEndTimes = trialEvents.Eot_;

[trialEyes] = tdtExtractEyes(sessionDir, trialStartTimes, trialEndTimes);


