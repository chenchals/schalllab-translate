figure;
%% Trial outcomes grouped-stack plot
% stack: pre-, post- SSD only valid for STOP trials
data = table2array(beh.trial.outcomes);
labels = beh.trial.outcomes.Properties.RowNames';
groups = size(data,1)/2;
stacks = size(data,2);
barsInGroup = 2;
%Plot
subplot(221)
hold on;
for i=1:groups*barsInGroup
    h(i,1:stacks)=bar([data(i,:);nan(1,stacks)],'stacked'); %#ok<SAGROW>
end
%Group and set xdata
x1=1:groups;
barWidth = 0.4;
x0=x1-barWidth;
pos=[x0;x1];
xpos=pos(:)';
ticks = [];
for ii = 0:groups-1
     ticks = [ticks [0.6 1.0]+ii]; %#ok<AGROW>
end
for i=1:groups*barsInGroup
    set(h(i,:),'xdata',xpos(i))
end
set(h,'barwidth',0.4)
grid on
xticks(ticks)
xlim([0.2 3.4])
xticklabels(labels)
xtickangle(45)
ylabel('Number of Trials');
title('Trial outcomes - Stacked [pre-SSD, post-SSD]')

%% Inhibition fx plot - Using taskInfos.Is.... vars
subplot(222)
yyaxis('left');
plot(beh.inhFx.ssdStatsAll.mean_UseSsdIdx+1, beh.inhFx.values.pNC,'o-b','LineWidth',2,'MarkerSize',14);
hold on
plot(beh.inhFx.ssdStatsCancelled.mean_UseSsdIdx+1, beh.inhFx.values.pNC(1:3),'d','MarkerSize', 8, 'MarkerFaceColor','k','MarkerEdgeColor','y');
hold on
ylim([0 1.1])
ylabel('pNC')
xlabel('SSD (# vertical refresh)')
grid on
title('Inhibition function')
yyaxis('right');
bb = bar(beh.inhFx.ssdStatsAll.mean_UseSsdIdx+1,beh.inhFx.values.nTrials,...
    'BarWidth',0.95,'FaceAlpha',0.6);
ylim([0 max(beh.inhFx.values.nTrials)*1.1])
xticklabels([0; beh.inhFx.ssdStatsAll.mean_UseSsdVrCount])
set(gca, 'SortMethod', 'depth')
ylabel('# STOP trials')


%% Inhibition fx plot - Using outcomeEvents
% subplot(223)
% yyaxis('left');
% plot(beh.inhFx.ssdStatsAll.mean_UseSsdIdx+1, beh.inhFx.values.pNC_,'o-b','LineWidth',2,'MarkerSize',14);
% hold on
% plot(beh.inhFx.ssdStatsCancelled.mean_UseSsdIdx+1, beh.inhFx.values.pNC_(1:3),'d','MarkerSize', 8, 'MarkerFaceColor','k','MarkerEdgeColor','y');
% hold on
% ylim([0 1.1])
% ylabel('pNC')
% xlabel('SSD (# vertical refresh)')
% grid on
% title('Inhibition function')
% yyaxis('right');
% bb = bar(beh.inhFx.ssdStatsAll.mean_UseSsdIdx+1,beh.inhFx.values.nTrials,...
%     'BarWidth',0.95,'FaceAlpha',0.6);
% ylim([0 max(beh.inhFx.values.nTrials)*1.1])
% xticklabels([0; beh.inhFx.ssdStatsAll.mean_UseSsdVrCount])
% set(gca, 'SortMethod', 'depth')
% ylabel('# STOP trials')

%% Reaction times
subplot(223)
plot(beh.reactionTimes.binEdges(2:end)-1,cumsum(beh.reactionTimes.GoCorrect)./sum(beh.reactionTimes.GoCorrect),'-b','LineWidth',1.5)
hold on
plot(beh.reactionTimes.binEdges(2:end)-1,cumsum(beh.reactionTimes.NonCancelled)./sum(beh.reactionTimes.NonCancelled),'--r','LineWidth',1.5)
hold off
xlim(beh.reactionTimes.xlims)
ylim([0 1.02])
xlabel('Reaction Time (ms)')
ylabel('Normalized cumulative count')
legend('Go','NonCancelled')


