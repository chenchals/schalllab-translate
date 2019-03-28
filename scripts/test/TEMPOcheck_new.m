% Process raw eye values
baseDir = '/Volumes/schalllab';
baseSaveDir = fullfile(baseDir,'Users/Chenchal/Tempo_NewCode/dataProcessed');
sessName = 'Amir-190328-102128';

load(fullfile(baseSaveDir,sessName, 'Events.mat'));
load(fullfile(baseSaveDir,sessName, 'Eyes.mat'));

set(0, 'DefaultTextInterpreter', 'none')

%% Convert to table
Task = struct2table(Task);
TaskInfos = struct2table(TaskInfos);

%% Plot Eyes
figure; 
subplot(411)
plot( tdt.EyeX, '-')
subplot(412)
plot( tdt.EyeY, '-')
subplot(413)
plot( tempEyes(:,1),tempEyes(:,2), '-')
subplot(414)
plot( tempEyes(:,1),tempEyes(:,3), '-')

figure;
plot( tempEyes(:,1),tempEyes(:,2), '-b')
hold on
plot( tempEyes(:,1),tempEyes(:,3), ':r')
hold off

figure;
plot( tdt.EyeX, '-b')
hold on
plot( tdt.EyeY, ':r')
hold off

figure;
plot( sess2Eyes.tdt.EyeX, '-b')
hold on
plot( sess2Eyes.tdt.EyeY, ':r')
hold off



% X and Y-direction:
Y_passLimit = find( tempEyes(:,3) < -1.6*10000 );
Y_passLimit_diff = diff( Y_passLimit );
Y_passLimit_diff ( Y_passLimit_diff <2 ) = [];
figure; subplot(211); hist( Y_passLimit_diff ,1:2:5000 );
X_passLimit = find( tempEyes(:,2) < -1.6*10000 );
X_passLimit_diff = diff( X_passLimit );
X_passLimit_diff ( X_passLimit_diff <2 ) = [];
        subplot(212); hist( X_passLimit_diff ,1:2:5000 );


%% Check negative nos in the infos
figure;
hist( TaskInfos.RandNegNumberTest, 100 )

%% Check Trial numbers
figure;
plot( TaskInfos.TrialNumber, '-')
%% Check Block numbers

figure;
plot( TaskInfos.BlockNum, '-')

%% Check IsRunning -- removed...from TaskInfos
%% Check Event: AcquireFix_

% figure;
% plot( Task.AcquireFix_, '-')
% 
%% Check Trial duration
figure;
subplot(331); plot( Task.TrialStart_ , '-')
title('TrialStart_');
subplot(332); plot( Task.Eot_ , '-')
title('Eot_');
subplot(333); hist( Task.Eot_ - Task.TrialStart_, 100)  
title('Eot_ - TrialStart_');
subplot(334)
hist( Task.TimeoutStart_ - Task.Eot_ , 100)
title('TimeoutStart_ - Eot_');

% subplot(334); plot( Task.TrialStart_ , '-')
timeoutDuration =  Task.TimeoutEnd_-Task.TimeoutStart_;
subplot(335); hist( Task.Eot_ - Task.TrialStart_ + timeoutDuration, 100)
title('Task.Eot_ - Task.TrialStart_ + timeoutDuration')
subplot(336); hist(  TaskInfos.UseTrialDuration , 100)
title('UseTrialDuration')
%% % This tests the trial duration for GO and STOP trials. They should be the
% same! 
figure; 
subplot(2,1,1); hist( TaskInfos.UseTrialDuration ( TaskInfos.TrialType == 0 ), 100)
subplot(2,1,2); hist( TaskInfos.UseTrialDuration ( TaskInfos.TrialType == 1 ), 100)
        % we tested and found that they are off by 660ms.
%% Check RT time to look at fix point      
figure;
plot(  Task.TrialStart_  - Task.FixSpotOn_, '-')  % RT time to look at fix point

figure;
plot( Task.TrialStart_ - Task.AcquireFix_, '-')  % up to 1ms delay between the two.

%% Check fix hold duration 
figure;
subplot(411); plot( Task.Fixate_ - Task.TrialStart_ , '-')
subplot(412); hist( Task.Fixate_ - Task.TrialStart_ , 100)  % here is a jitter...
subplot(413); hist( (Task.Fixate_ - Task.TrialStart_) - TaskInfos.UseFixHoldDuration , 100)  % this should be 0 -- we get it within 1ms.

%% Check fix hold duration -- This should be zero (0) but is not! Why?
figure;
subplot(411); hist(  (TaskInfos.FixHoldDuration - TaskInfos.UseFixHoldDuration)  , 100)  % this should be 0 -- 
% plotting it for STOP-only:
subplot(412); hist(  TaskInfos.FixHoldDuration(TaskInfos.TrialType==1) - TaskInfos.UseFixHoldDuration(TaskInfos.TrialType==1)  , 100)  % non-zero for many trials
% plotting it for GO-only:
subplot(413); hist(    TaskInfos.FixHoldDuration(TaskInfos.TrialType==0) - TaskInfos.UseFixHoldDuration(TaskInfos.TrialType==0)  , 100)  % non-zero for two trials
        % what is unique about these two GO trials?
% to explore:
 A = TaskInfos((abs(TaskInfos.FixHoldDuration - TaskInfos.UseFixHoldDuration) > 5) , :);
 B = Task((abs(TaskInfos.FixHoldDuration - TaskInfos.UseFixHoldDuration) > 5) , :);

%% Check min target hold time duration 
figure; 
% we are using a Gaussian distribution
subplot(2,1,1); hist( TaskInfos.UseMinThtDuration, 100)
subplot(2,1,2); hist( TaskInfos.MinThtDuration , 100)
% we see many trials at 0, some with >0 but <50, and many with >150. Are
% these different?
%% Check Tone timings: 
% Tone_OFF - Tone_ON =  tone delay + tone duration
% AudioEnd_ - AudioStart_ =  tone duration
% tone delay = AudioStart_ - Tone_on
Task_toneDelay = Task.AudioStart_ - Task.ToneOn_;
figure; hist( Task_toneDelay, 100) 
figure; hist( Task.ToneOn_ - Task.ToneOff_, 100) 
% so it seems like tone on and audio start are equivalent (with some noise added over 0).

TaskInfos_toneDelay = TaskInfos.UseToneDelay;
figure; hist( TaskInfos.UseToneDelay, 100) % this should be a Gaussian because user set a mean +/- a non-zero jitter value with Gaussian flag on.
% there is ONE trial that has tone delay = 0! 

figure; hist( TaskInfos_toneDelay - Task_toneDelay, 100)

figure; hist( Task.AudioStart_ - Task.XtraHoldStart_, 100) 
figure; hist(  (Task.AudioStart_ - Task.XtraHoldStart_) - TaskInfos.UseToneDelay, 100)
% they should be 0 -- why didn't we get 0? Need to find a good explanation.

%% Check Reward timings: 

Task_rewardDelay = Task.RewardOff_ - Task.RewardOn_; 
figure; hist( Task_rewardDelay, 100); % INCORRECT!! The distribution looks shorter than what it should be.

Task_rewardDuration = Task.JuiceEnd_ - Task.JuiceStart_; 
figure; hist( Task_rewardDuration, 100); % INCORRECT!! The distribution looks shorter than what it should be.
% this seems alright, with a Gaussian distribution around the high and low-
% reward duration values.
%% Check outcome flags 
%     - GO Trials
go_summary = [sum(TaskInfos.TrialType == 0), ... % all GO trials
    sum(Task.OutcomeGoCorrect_>0), ...  % all GO correct
    sum(Task.OutcomeGoError_ > 0), ...  % all Go error
    sum(Task.OutcomeFixError_(TaskInfos.TrialType==0) > 0), ... % all Fix error (GO trials only)
    sum(Task.OutcomeFixBreak_(TaskInfos.TrialType==0) > 0)];  % all fix break (GO trials only)
go = categorical({'All GO','GO-Correct','GO-Error','GO-FixError','GO-FixBreak'});

figure;

subplot(221)
bar(go,go_summary)
title('GO-Outcomes')
subplot(222)
bar([[go_summary(1),nan(1,numel(go_summary)-2)];go_summary(2:end)],'stacked')
%    - NOGO Trials
nogo_summary = [sum(TaskInfos.TrialType == 1), ... % all NOGO trials
    sum(Task.OutcomeNogoCancelled_>0), ...  % all NOGO cancelled
    sum(Task.OutcomeNogoNonCancelled_ > 0), ...  % all NOGo non-cancelled
    sum(Task.OutcomeNogoError_ > 0), ...  % all NOGo error
    sum(Task.OutcomeFixError_(TaskInfos.TrialType==1) > 0), ... % all Fix error (NOGO trials only)
    sum(Task.OutcomeFixBreak_(TaskInfos.TrialType==1) > 0)];  % all fix break (NOGO trials only)
nogo = categorical({'All NOGO','NOGO-Cancelled','NOGO-Non-Cancelled','NOGO-Error','NOGO-FixError','NOGO-FixBreak'});

subplot(223)
bar(nogo,nogo_summary)
title('NOGO-Outcomes')
subplot(224)
bar([[nogo_summary(1),nan(1,numel(nogo_summary)-2)];nogo_summary(2:end)],'stacked')
%% Check Stop signal delays
ssdTable = TaskInfos(:,{'TrialNumber','TrialType', 'UseSsdIdx', 'UseSsdVrCount','SsdVrCount', 'StopSignalDuration',...
    'IsCancelled', 'IsNonCancelled'});
ssdTable =[ssdTable Task(:,{'StopSignal_', 'Target_','OutcomeFixError_','OutcomeFixBreak_','OutcomeGoCorrect_','OutcomeGoError_',...
    'OutcomeNogoCancelled_', 'OutcomeNogoNonCancelled_','OutcomeNogoError_'})];
ssdTable.StopSignal_Minus_Target_ = ssdTable.StopSignal_ - ssdTable.Target_;
ssdTable = sortrows(ssdTable,{'TrialType','UseSsdIdx'});

ss_on_idx = ssdTable.StopSignal_>0;

ssOn_ssdStats = grpstats(ssdTable(ss_on_idx,:),{'TrialType','UseSsdIdx'},{'min','mean','max','std'},...
                              'DataVars',{'UseSsdVrCount', 'SsdVrCount','StopSignalDuration','StopSignal_Minus_Target_'});

    
figure
subplot(331)
hist(ssdTable.UseSsdVrCount(ssdTable.TrialType==1),unique(ssdTable.UseSsdVrCount(ssdTable.TrialType==1)))
xlabel('SSD - # refreshes')
ylabel('# Stop trials')
title('SSD config (#refreshes)')
subplot(332)
bar(unique(ssdTable.UseSsdVrCount(ss_on_idx)),...
    [histc(ssdTable.UseSsdVrCount(ss_on_idx),unique(ssdTable.UseSsdVrCount(ss_on_idx))),...
     histc(ssdTable.SsdVrCount(ss_on_idx),unique(ssdTable.UseSsdVrCount(ss_on_idx)))]...
    )
legend({'config.','PD-count'})
xlabel('SSD - # screen refreshes')
ylabel('# Stop trials')
title('SSD (#refreshes) - stop signal ON')

subplot(333)

%% Inhibition function:
Inh_table.SSDlist = TaskInfos.UseSsdIdx;
Inh_table.NC1 = ~isnan(Task.OutcomeNogoNonCancelBrk_) ;
Inh_table.NC2 = ~isnan(Task.OutcomeNogoNonCancelNoBrk_) ;
Inh_table.C1 = ~isnan(Task.OutcomeNogoCancelBrk_) ;
Inh_table.C2 = ~isnan(Task.OutcomeNogoCancelNoBrk_) ;

Inh_table.NC = zeros( size(Inh_table.NC1 ));
Inh_table.C = zeros( size(Inh_table.C1 ));

Inh_table.NC( Inh_table.NC1 == 1 ) = 1;
Inh_table.NC( Inh_table.NC2 == 1 ) = 1;
Inh_table.C( Inh_table.C1 == 1 ) = 1;
Inh_table.C( Inh_table.C2 == 1 ) = 1;

InhPlot = table;
InhPlot.SSD = Inh_table.SSDlist;
InhPlot.SSD = Inh_table.SSDlist+1;
InhPlot.NC = Inh_table.NC;
InhPlot.C = Inh_table.C;

for currSSD = 1:10  % 10 SSDs);
    SSDind = find( InhPlot.SSD == currSSD );
    inh.nTr(currSSD) = length(SSDind);
    inh.NC(currSSD) = sum(InhPlot.NC(SSDind));
    inh.C(currSSD) = sum(InhPlot.C(SSDind));
end

numerator = inh.NC;
denominator = inh.NC + inh.C;
figure;
plot( numerator./denominator, '-*r' )
%% RT calculation:
figure; 
subplot(211); hist( Task.Decide_(TaskInfos.TrialType == 0) - Task.Target_(TaskInfos.TrialType == 0), 1:10:700 );
subplot(212); hist( Task.Decide_(TaskInfos.TrialType == 1) - Task.Target_(TaskInfos.TrialType == 1), 1:10:700 );
 
%% Trial types
sum(TaskInfos.TrialType)/length(TaskInfos.TrialType); %#ok<VUNUS>
figure; plot(TaskInfos.TrialType, '-');

%% Inhibition Fx
inhibition.varNames = {'UseSsdIdx','UseSsdVrCount','SsdVrCount','StopSignalDuration','IsCancelledNoBrk','IsCancelledBrk',...
    'IsNonCancelledNoBrkNoBrk','IsNonCancelledBrk'};
inhibition.varTable =TaskInfos(:,inhibition.varNames);
inhibition.values=grpstats(inhibition.varTable, {'UseSsdIdx'},{'sum'});
inhibition.values.NC = inhibition.values.sum_IsNonCancelledBrk + inhibition.values.sum_IsNonCancelledNoBrkNoBrk;
inhibition.values.C = inhibition.values.sum_IsCancelledBrk + inhibition.values.sum_IsCancelledNoBrk;
inhibition.values.prob = inhibition.values.NC./(inhibition.values.C + inhibition.values.NC);
% Correctly cancelled trial SSD durations men
inhibition.ssdStatsCancelled = grpstats(inhibition.varTable(inhibition.varTable.IsCancelledNoBrk==1,:),...
                      {'UseSsdIdx'},{'mean'},'DataVars',{'UseSsdIdx', 'UseSsdVrCount','SsdVrCount','StopSignalDuration'});
% All trial SSD durations mean
inhibition.ssdStatsAll = grpstats(inhibition.varTable,...
                      {'UseSsdIdx'},{'mean'},'DataVars',{'UseSsdIdx', 'UseSsdVrCount','SsdVrCount','StopSignalDuration'});

figure; 
plot(inhibition.ssdStatsAll.mean_UseSsdIdx+1, inhibition.values.prob,'o-b');
hold on
plot(inhibition.ssdStatsCancelled.mean_UseSsdIdx+1, inhibition.values.prob(1:3),'*r');
hold off
