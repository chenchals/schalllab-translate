% Test for translateTdt/tdtExtractEvents
% See TDTEXTRACTEVENTS, GETCODEDEFS

%function [trialEvents, trialInfos, evCodec, infosCodec, tdtInfos ] = tdtExtractEvents(sessionDir, eventCodecFile, infosCodecFile)

codesDir = '/Volumes/schalllab/Users/Chenchal/Tempo_NewCode/Joule-190312-162436/ProcLib/CMD';
sessionDir = '/Volumes/schalllab/Users/Chenchal/Tempo_NewCode/Joule-190312-162436';
eventCodecFile = fullfile(codesDir,'EVENTDEF.PRO');
infosCodecFile = fullfile(codesDir, 'INFOS.PRO');

[trialEvents, trialInfos, evCodec, infosCodec, tdtInfos ] = tdtExtractEvents(sessionDir, eventCodecFile, infosCodecFile);



