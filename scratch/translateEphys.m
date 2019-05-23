
dataDir = '/Users/subravcr/teba/data/Joule/cmanding/ephys/TESTDATA';
session = 'Joule-190510-111052'; % No RAW data

blockPath=fullfile(dataDir,session);

H=TDTbin2mat(blockPath,'headers',1)
