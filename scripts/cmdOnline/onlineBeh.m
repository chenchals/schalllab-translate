function [beh,Task,TaskInfos] = onlineBeh()
%ONLINEBEH Summary of this function goes here
%   Detailed explanation goes here

%% Set up session location and ProcLib Location
monitorRefreshHz = 60;
online = 0;
%% Session
session = 'Joule-190412-102057';
if online
    sessionDir = fullfile('D:/Synapse/Tanks/CMD_TSK_029-190212-102605',session);
    proclibDir = 'T:/Tempo/rigProcLibs/schalllab-rig029/ProcLib/CMD';
else
    drive = '/Volumes/schalllab'; 
    sessionDir = fullfile(drive,'/Users/Chenchal/Tempo_NewCode/Joule',session);
    proclibDir = fullfile(sessionDir,'ProcLib/CMD');
end


%% Proclib
eventCodecFile = fullfile(proclibDir,'EVENTDEF.PRO');
infosCodecFile = fullfile(proclibDir, 'INFOS.PRO');

%% Analysis from here
opts.useTaskStartEndCodes = true;
opts.dropNaNTrialStartTrials = false;
opts.dropEventAllTrialsNaN = false;
% Offset for Info Code values_
opts.infosOffsetValue = 3000;
opts.infosHasNegativeValues = true;
opts.infosNegativeValueOffset = 32768;

beh.opts = opts;
beh.session = session;
%% Extract trial variables for online behavior plots
[Task, TaskInfos] = tdtExtractEvents(sessionDir, eventCodecFile, infosCodecFile, opts);
Task = struct2table(Task);
TaskInfos = struct2table(TaskInfos);
%%%%%%%%%%%%%%%%%%%%%FIX_ME%%%%%%%%%%%FIX_ME%%%%%%%%%%%FIX_ME%%%%%%%%%%%FIX_ME%%%%%
Task = Task(TaskInfos.numberOfInfoCodeValuesLowerThanOffset == 0,:);
TaskInfos = TaskInfos(TaskInfos.numberOfInfoCodeValuesLowerThanOffset == 0,:);
beh.badTrialInfos = TaskInfos.numberOfInfoCodeValuesLowerThanOffset > 0;
%%%%%%%%%%%%%%%%%%%%%FIX_ME%%%%%%%%%%%FIX_ME%%%%%%%%%%%FIX_ME%%%%%%%%%%%FIX_ME%%%%%

beh.infosVarNames = {'TrialType','UseSsdIdx','UseSsdVrCount','SsdVrCount','StopSignalDuration',...
    'IsCancelledNoBrk','IsCancelledBrk','IsNonCancelledNoBrk','IsNonCancelledBrk','IsNogoErr',...
    'IsGoCorrect','IsGoErr', 'IsStopSignalOn'};
beh.taskOutcomes = Task.Properties.VariableNames(...
    ~cellfun(@isempty,regexp(Task.Properties.VariableNames,'^Outcome','match')));
beh.taskOutcomes(end+1:end+2) = {'AcquireFixError_','FixBreak_'}; 
beh.taskVarNames = {'Decide_','Target_'};

beh.values = [TaskInfos(:,beh.infosVarNames),...
              array2table(~cell2mat(cellfun(@isnan,table2cell(Task(:,beh.taskOutcomes)),'UniformOutput',false)),...
                          'VariableNames',beh.taskOutcomes),...
              Task(:,beh.taskVarNames)];
beh.values.reactionTime = beh.values.Decide_ - beh.values.Target_;

%% Extract Trial Proportions
 varNames = {'GoCorrect', 'GoErr','Cancel','CancelErr','NonCancel','NonCancelErr'};
 beh.trial.outcomes=table('RowNames',varNames);
 beh.trial.outcomes('GoCorrect',1:2)= {sum(beh.values.IsGoCorrect==1 & beh.values.TrialType==0),0};
 beh.trial.outcomes('GoErr',1:2)= {sum(beh.values.IsGoErr==1 & beh.values.TrialType==0),0};
 beh.trial.outcomes('Cancel',1:2)= {sum(beh.values.IsCancelledNoBrk==1 & beh.values.TrialType==1),0};
 % Nogo Cancel break will always be post SSD, since pre-ssd will be a
 % nogo-non-cancelled or nogo-error, so 
 beh.trial.outcomes('CancelErr',1:2)= {0,sum(beh.values.IsCancelledBrk==1 & beh.values.TrialType==1)};
 beh.trial.outcomes('NonCancel',1:2)= {sum(beh.values.IsNonCancelledNoBrk==1 & beh.values.TrialType==1 & beh.values.IsStopSignalOn==0),...
                           sum(beh.values.IsNonCancelledNoBrk==1 & beh.values.TrialType==1 & beh.values.IsStopSignalOn==1)};
 beh.trial.outcomes('NonCancelErr',1:2)= {sum(beh.values.IsNonCancelledBrk==1 & beh.values.TrialType==1 & beh.values.IsStopSignalOn==0),...
                             sum(beh.values.IsNonCancelledBrk==1 & beh.values.TrialType==1 & beh.values.IsStopSignalOn==1)};
 
                         
%% Extract Inhibition function values
beh.inhFx.values=grpstats(beh.values, {'UseSsdIdx'},{'sum'},'DataVars',...
    [{'IsCancelledNoBrk','IsCancelledBrk','IsNonCancelledNoBrk','IsNonCancelledBrk','IsNogoErr'},...
    beh.taskOutcomes]);
beh.inhFx.values.NC = beh.inhFx.values.sum_IsNonCancelledBrk + beh.inhFx.values.sum_IsNonCancelledNoBrk;
beh.inhFx.values.C = beh.inhFx.values.sum_IsCancelledBrk + beh.inhFx.values.sum_IsCancelledNoBrk;
beh.inhFx.values.pNC = beh.inhFx.values.NC./(beh.inhFx.values.C + beh.inhFx.values.NC);
beh.inhFx.values.nTrials = beh.inhFx.values.C + beh.inhFx.values.NC;
% Using Task.Outcome*
beh.inhFx.values.NC_ = beh.inhFx.values.sum_OutcomeNogoNonCancelBrk_ + beh.inhFx.values.sum_OutcomeNogoNonCancelNoBrk_;
beh.inhFx.values.C_ = beh.inhFx.values.sum_OutcomeNogoCancelBrk_ + beh.inhFx.values.sum_OutcomeNogoCancelNoBrk_;
beh.inhFx.values.pNC_ = beh.inhFx.values.NC_./(beh.inhFx.values.C_ + beh.inhFx.values.NC_);
beh.inhFx.values.nTrials_ = beh.inhFx.values.C_ + beh.inhFx.values.NC_;
% Correctly cancelled trial SSD durations men
beh.inhFx.ssdStatsCancelled = grpstats(beh.values(beh.values.IsCancelledNoBrk==1,:),...
                      {'UseSsdIdx'},{'mean'},'DataVars',{'UseSsdIdx', 'UseSsdVrCount','SsdVrCount','StopSignalDuration'});
% All trial SSD durations mean
beh.inhFx.ssdStatsAll = grpstats(beh.values,...
                      {'UseSsdIdx'},{'mean'},'DataVars',{'UseSsdIdx', 'UseSsdVrCount','SsdVrCount','StopSignalDuration'});
beh.inhFx.values.refreshRate(:) = 1000.0/monitorRefreshHz;
beh.inhFx.values.vrCounts = beh.inhFx.ssdStatsAll.mean_UseSsdVrCount;
beh.inhFx.values.vrDuration = beh.inhFx.values.vrCounts.* beh.inhFx.values.refreshRate;


%% Extract Reactions times
rtBins = (0:550);
beh.reactionTimes.xlims = [150 550];
[beh.reactionTimes.GoCorrect, beh.reactionTimes.binEdges]=histcounts(beh.values.reactionTime(beh.values.TrialType == 0), rtBins);
[beh.reactionTimes.NonCancelled, ~]=histcounts(beh.values.reactionTime(beh.values.TrialType == 1), rtBins);


%% Extract reward durations/amount(?)
beh.reward.varNames = {'TrialType','TrialNumber','BlockNum', 'IsLoRwrd','JuiceStart_','JuiceEnd_','rewardDuration'};
beh.reward.values = array2table(...
     [TaskInfos.TrialType TaskInfos.TrialNumber TaskInfos.BlockNum TaskInfos.IsLoRwrd ...
     Task.JuiceStart_ Task.JuiceEnd_ Task.JuiceEnd_-Task.JuiceStart_],...
     'VariableNames', beh.reward.varNames);
 temp =[Task.TaskStart_;Task.TaskEnd_(end)]-Task.TaskStart_(1); 
 beh.reward.values.sessionTime=temp(2:end)./1000;
 % Tag with outcomes
 beh.reward.values.Go = beh.values.IsGoCorrect==1;
 beh.reward.values.Cancelled = beh.values.IsCancelledNoBrk==1;
 beh.reward.values.NonCancelled = beh.values.IsNonCancelledNoBrk==1;
 beh.reward.values.ErrorOrTimeout = (beh.values.IsGoErr==1 | beh.values.IsNogoErr==1 | ...
                            beh.values.IsCancelledBrk==1 | beh.values.IsNonCancelledBrk==1 | ...
                            beh.values.AcquireFixError_==1 | beh.values.FixBreak_==1);
 % Add block start and block end trial numbers
 beh.reward.values.BlockStart = diff([0;beh.reward.values.BlockNum]);
 beh.reward.values.BlockEnd = diff([beh.reward.values.BlockNum;0]);
 % Cumulative reward duration by block
 blkStartEndVals = [find(beh.reward.values.BlockStart) find(beh.reward.values.BlockEnd)];
  % add trial nos for block start and end 
 beh.reward.block=array2table([(1:size(blkStartEndVals,1))' blkStartEndVals],'VariableNames',{'blkNum','startTrialNum','endTrialNum'});
 % cumul reward duration by block
 temp = beh.reward.values.rewardDuration;
 temp(isnan(temp))=0;
 beh.reward.values.cumulRwrdDuration = cumsum(temp);
 beh.reward.values.cumulBlockRwrdDuration = cell2mat(arrayfun(@(x,y) cumsum(temp(x:y)),blkStartEndVals(:,1),blkStartEndVals(:,2),'UniformOutput',false));

end


