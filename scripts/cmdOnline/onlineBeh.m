function [beh] = onlineBeh()
%ONLINEBEH Summary of this function goes here
%   Detailed explanation goes here

%% Set up session location and ProcLib Location
monitorRefreshHz = 60;
sessionBaseDir = '/Volumes/schalllab/Users/Chenchal/Tempo_NewCode/Joule';
proclibBaseDir = '/Volumes/schalllab/Tempo/rigProcLibs/schalllab-rig029';

session = 'Amir-190328-102128';
sessionDir = fullfile(sessionBaseDir,session);
codesDir = fullfile(proclibBaseDir,'ProcLib','CMD');
eventCodecFile = fullfile(codesDir,'EVENTDEF.PRO');
infosCodecFile = fullfile(codesDir, 'INFOS.PRO');

opts.useTaskStartEndCodes = true;
opts.dropNaNTrialStartTrials = false;
opts.dropEventAllTrialsNaN = false;
% Offset for Info Code values_
opts.infosOffsetValue = 3000;
opts.infosHasNegativeValues = true;
opts.infosNegativeValueOffset = 32768;


%% Extract trial variables for online behavior plots
[Task, TaskInfos] = tdtExtractEvents(sessionDir, eventCodecFile, infosCodecFile, opts);
Task = struct2table(Task);
TaskInfos = struct2table(TaskInfos);
beh.infosVarNames = {'TrialType','UseSsdIdx','UseSsdVrCount','SsdVrCount','StopSignalDuration',...
    'IsCancelledNoBrk','IsCancelledBrk','IsNonCancelledNoBrkNoBrk','IsNonCancelledBrk','IsNogoErr',...
    'IsGoCorrect','IsGoErr'};
beh.taskVarNames = {'Decide_','Target_'};
beh.values = [TaskInfos(:,beh.infosVarNames) Task(:,beh.taskVarNames)];
beh.values.reactionTime = beh.values.Decide_ - beh.values.Target_;

%% Extract Trial Proportions
beh.trialTypes.values = grpstats(beh.values,{'TrialType'},{'sum'},...
    'DataVars', {'IsCancelledNoBrk','IsCancelledBrk','IsNonCancelledNoBrkNoBrk',...
    'IsNonCancelledBrk','IsNogoErr','IsGoCorrect','IsGoErr'});

%% Extract all Trial outcomes


%% Extract Inhibition function values
beh.inhFx.values=grpstats(beh.values, {'UseSsdIdx'},{'sum'},'DataVars',...
    {'IsCancelledNoBrk','IsCancelledBrk','IsNonCancelledNoBrkNoBrk','IsNonCancelledBrk','IsNogoErr'});
beh.inhFx.values.NC = beh.inhFx.values.sum_IsNonCancelledBrk + beh.inhFx.values.sum_IsNonCancelledNoBrkNoBrk;
beh.inhFx.values.C = beh.inhFx.values.sum_IsCancelledBrk + beh.inhFx.values.sum_IsCancelledNoBrk;
beh.inhFx.values.pNC = beh.inhFx.values.NC./(beh.inhFx.values.C + beh.inhFx.values.NC);
beh.inhFx.values.nTrials = beh.inhFx.values.C + beh.inhFx.values.NC;

% Correctly cancelled trial SSD durations men
beh.inhibition.ssdStatsCancelled = grpstats(beh.values(beh.values.IsCancelledNoBrk==1,:),...
                      {'UseSsdIdx'},{'mean'},'DataVars',{'UseSsdIdx', 'UseSsdVrCount','SsdVrCount','StopSignalDuration'});
% All trial SSD durations mean
beh.inhibition.ssdStatsAll = grpstats(beh.values,...
                      {'UseSsdIdx'},{'mean'},'DataVars',{'UseSsdIdx', 'UseSsdVrCount','SsdVrCount','StopSignalDuration'});
beh.inhFx.values.refreshRate(:) = 1000.0/monitorRefreshHz;
beh.inhFx.values.vrCounts = beh.inhibition.ssdStatsAll.mean_UseSsdVrCount;
beh.inhFx.values.vrDuration = beh.inhFx.values.vrCounts.* beh.inhFx.values.refreshRate;


%% Extract Reactions times




end


