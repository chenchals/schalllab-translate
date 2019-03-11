% Test for translateTdt/tdtExtractEvents
% See TDTEXTRACTEVENTS, GETCODEDEFS

%function [trialEvents, trialInfos, evCodec, infosCodec, tdtInfos ] = tdtExtractEvents(sessionDir, eventCodecFile, infosCodecFile)

codesDir = 'T:/Users/Chenchal/Tempo_NewCode/Joule-190311-095924/ProcLib/CMD';
sessionDir = 'T:/Users/Chenchal/Tempo_NewCode/Joule-190311-123405';
eventCodecFile = fullfile(codesDir,'EVENTDEF.PRO');
infosCodecFile = fullfile(codesDir, 'INFOS.PRO');

[trialEvents, trialInfos, evCodec, infosCodec, tdtInfos ] = tdtExtractEvents(sessionDir, eventCodecFile, infosCodecFile);



