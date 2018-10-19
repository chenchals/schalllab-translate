function [ ] = plot_Pcorr_X_aspRatio_GNG( TaskInfos , SessionInfos )
%plot_Pcorr_X_aspRatio_GNG Summary of this function goes here
%   Detailed explanation goes here

NUM_TRIAL = length(TaskInfos);

TrialOutcome = init_TrialOutcome(TaskInfos, NUM_TRIAL);

aspRatio = [TaskInfos.itemSizeH1000x] ./ [TaskInfos.itemSizeV1000x];
AR_PLOT = unique(aspRatio);
NUM_AR = length(AR_PLOT);

idxProblem = ([TaskInfos.displayItemSize] > 8);
TrialOutcome(idxProblem) = [];

Pcorr_X_AR = NaN(1,NUM_AR);

for jj = 1:NUM_AR
  idx_jj = (aspRatio == AR_PLOT(jj));
  if (sum(idx_jj) < 20); continue; end
  Pcorr_X_AR(jj) = sum(idx_jj & ismember(TrialOutcome, {'go_correct'})) / sum(idx_jj & ismember(TrialOutcome, {'pro_no_saccade','go_correct'}));
end%for:aspRatio(jj)

%% Plotting

figure(); hold on
plot(AR_PLOT, Pcorr_X_AR, 'ko')
title(SessionInfos.date, 'FontSize',8)
xlabel('Stimulus aspect ratio')
ylabel('P[saccade]')
ppretty()

print(['~/Dropbox/tmp/',SessionInfos.date,'-Pcorr.tif'], '-dtiff')
% print(['C:\Users\TDT\Dropbox/tmp/',SessionInfos.date,'-Pcorr.tif'], '-dtiff')

end%fxn:plot_Pcorr_X_aspRatio_GNG()

