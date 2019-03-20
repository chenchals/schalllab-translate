



%% Convert to table
Task = struct2table(Task);
TaskInfos = struct2table(TaskInfos);

%% Plot Eyes
figure; 
subplot(211)
plot( tdt.EyeX, '-')
subplot(212)
plot( tdt.EyeY, '-')
%% Check negative nos in the infos
figure;
hist( TaskInfos.RandNegNumberTest, 100 )

%% Check Trial numbers
figure;
plot( TaskInfos.TrialNumber, '-')
%% Check Block numbers

figure;
plot( TaskInfos.BlockNum, '-')

%% Check IsRunning -- removed...
isRunning_0 = TaskInfos(TaskInfos.IsRunning == 0, :);
isRunning_1 = TaskInfos(TaskInfos.IsRunning == 1, :);

isRunning_0_task = Task(TaskInfos.IsRunning == 0, :);
%% Check Event: AcquireFix_

% figure;
% plot( Task.AcquireFix_, '-')
% 
%% Check Trial duration
figure;
subplot(331); plot( Task.TrialStart_ , '-')
subplot(332); plot( Task.Eot_ , '-')
subplot(333); hist( Task.Eot_ - Task.TrialStart_, 100)  

subplot(334)
hist( Task.TimeoutStart_ - Task.Eot_ , 100)

% subplot(334); plot( Task.TrialStart_ , '-')
figure;
timeoutDuration =  Task.TimeoutEnd_-Task.TimeoutStart_;
subplot(335); hist(  Task.Eot_ - Task.TrialStart_ + timeoutDuration, 100)
subplot(336); hist(  TaskInfos.UseTrialDuration , 100)
%% % This tests the trial duration for GO and STOP trials. They should be the
% same! 
figure; subplot(2,1,1); hist( TaskInfos.UseTrialDuration ( TaskInfos.TrialType == 0 ), 100)
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




