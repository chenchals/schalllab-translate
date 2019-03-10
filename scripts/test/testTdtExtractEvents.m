% Test for translateTdt/tdtExtractEvents
% See TDTEXTRACTEVENTS, GETCODEDEFS

%function [trialEvents, trialInfos, evCodec, infosCodec, tdtInfos ] = tdtExtractEvents(sessionDir, eventCodecFile, infosCodecFile)

codesDir = 'local-data/Users/Chenchal/Tempo_NewCode/Joule-190308-161547/ProcLib/CMD';
sessionDir = 'local-data/Users/Chenchal/Tempo_NewCode/Joule-190308-161547';
eventCodecFile = fullfile(codesDir,'EVENTDEF.PRO');
infosCodecFile = fullfile(codesDir, 'INFOS.PRO');

[trialEvents, trialInfos, evCodec, infosCodec, tdtInfos ] = tdtExtractEvents(sessionDir, eventCodecFile, infosCodecFile);



