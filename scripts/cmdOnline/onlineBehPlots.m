function onlineBehPlots(beh)

figure;
h_rwrd1 = subplot(321);
h_inh = subplot(322);
h_rwrd2 = subplot(323);
h_rt = subplot(324);
h_rwrd3 = subplot(325);
h_trial = subplot(326);

%% Trial outcomes grouped-stack plot
% stack: pre-, post- SSD only valid for STOP trials
%Plot
axes(h_trial);
addPlotZoom();
data = table2array(beh.trial.outcomes);
labels = beh.trial.outcomes.Properties.RowNames';
groups = size(data,1)/2;
stacks = size(data,2);
barsInGroup = 2;

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
axes(h_inh)
addPlotZoom();
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
axes(h_rt)
addPlotZoom();
plot(beh.reactionTimes.binEdges(2:end)-1,cumsum(beh.reactionTimes.GoCorrect)./sum(beh.reactionTimes.GoCorrect),'-b','LineWidth',1.5)
hold on
plot(beh.reactionTimes.binEdges(2:end)-1,cumsum(beh.reactionTimes.NonCancelled)./sum(beh.reactionTimes.NonCancelled),'--r','LineWidth',1.5)
hold off
xlim(beh.reactionTimes.xlims)
ylim([0 1.02])
xlabel('Reaction Time (ms)')
ylabel('Normalized cumulative count')
legend('Go','NonCancelled')
title('Normalized Reaction Time CDF')


%% Reward duration by trial no/block num
axes(h_rwrd1)
addPlotZoom();
box on
blockColors = [0.7 0.7 0.7
               0.8 0.8 0.8];
blockAlpha = 0.5;
vy = beh.reward.values.rewardDuration;
vy(isnan(vy))=0;
vy = movmean(vy,10);


% add block number patches to the plot 
yLims = [0 ceil(max(vy)/50)*50];
vx = [0;beh.reward.block.endTrialNum];
vertices = arrayfun(@(x) [...
                          vx(x),yLims(1)   %(x1y1)
                          vx(x+1),yLims(1) %(x2y1)
                          vx(x+1),yLims(2)*0.9 %(x2y2)
                          vx(x),yLims(2)*0.9],... %(x1y2)
          (1:size(vx,1)-1)','UniformOutput',false);
nPatches = size(vertices,1);
%odd blocks
idx = 1:2:nPatches;
patch('Faces',reshape(1:numel(idx)*4,4,[])','Vertices',cell2mat(vertices(idx)),...
      'FaceColor',blockColors(1,:),'FaceAlpha',blockAlpha, 'EdgeColor', 'none');
%even blocks
idx = 2:2:nPatches;
patch('Faces',reshape(1:numel(idx)*4,4,[])','Vertices',cell2mat(vertices(idx)),...
      'FaceColor',blockColors(2,:),'FaceAlpha',blockAlpha, 'EdgeColor', 'none');
hold on
% plot the line as stairs plot
stairs(beh.reward.values.TrialNumber,vy,'LineWidth',1.25)
ylabel('Moving Avg. (ms)')
ylim(yLims)
xlabel('Trial number')
xlim([0 numel(vy)])
title('Reward duration during session')
hold off

%% Cumulative Reward duration (CRD) by session time by block 
% The cumulative reward duration is reset when new block starts
axes(h_rwrd2)
addPlotZoom();
box on
% add block number patches to the plot 
yLims = [0 ceil(max(beh.reward.values.cumulBlockRwrdDuration)/50)*50];
vx = [0;beh.reward.values.sessionTime(beh.reward.block.endTrialNum)];
xLims = [0 max(vx)];
vertices = arrayfun(@(x) [...
                          vx(x),yLims(1)   %(x1y1)
                          vx(x+1),yLims(1) %(x2y1)
                          vx(x+1),yLims(2)*0.9 %(x2y2)
                          vx(x),yLims(2)*0.9],... %(x1y2)
          (1:size(vx,1)-1)','UniformOutput',false);
nPatches = size(vertices,1);
%odd blocks
idx = 1:2:nPatches;
patch('Faces',reshape(1:numel(idx)*4,4,[])','Vertices',cell2mat(vertices(idx)),...
      'FaceColor',blockColors(1,:),'FaceAlpha',blockAlpha,...
      'EdgeColor', blockColors(1,:),'LineWidth', 0.5);
%even blocks
idx = 2:2:nPatches;
patch('Faces',reshape(1:numel(idx)*4,4,[])','Vertices',cell2mat(vertices(idx)),...
      'FaceColor',blockColors(2,:),'FaceAlpha',blockAlpha,...
      'EdgeColor', blockColors(1,:),'LineWidth', 0.5);
ylabel('Cumul. (ms)')
ylim(yLims)
xlabel('Session time (s)')
xlim(xLims)
hold on
% Compute vertices for all outcomes
vx = [0;beh.reward.values.sessionTime];
vy = [0;beh.reward.values.cumulBlockRwrdDuration];
vy1 = vy(1:end-1);
vy2 = vy(2:end);
% when new block starts reset to zero
vy1(beh.reward.block.startTrialNum) = 0;

vertices = arrayfun(@(x) [...
                          vx(x),vy1(x)   %(x1y1)
                          vx(x+1),vy1(x) %(x2y1)
                          vx(x+1),vy2(x) %(x2y2)
                          vx(x),vy2(x)],... %(x1y2)
          (1:size(vx,1)-1)','UniformOutput',false);
nPatches = size(vertices,1);
% draw patches for each outcome
patchLabels = {'Go';'Cancelled';'NonCancelled';'Timeout/Error'};
patchColors = {[0.0 0.0 0.0];[0.0 0.0 1.0];[1.0 0.0 0.0];[0.5 0.5 0.5]};

% go patches
h=[];
idx = find(beh.reward.values.Go==1);
h(1) = patch('Faces',reshape(1:numel(idx)*4,4,[])','Vertices',cell2mat(vertices(idx)),...
      'FaceColor',patchColors{1},'EdgeColor',patchColors{1});
% cancelled patches
idx = find(beh.reward.values.Cancelled==1);
h(2) = patch('Faces',reshape(1:numel(idx)*4,4,[])','Vertices',cell2mat(vertices(idx)),...
      'FaceColor',patchColors{2},'EdgeColor',patchColors{2});
% non-cancelled patches
idx = find(beh.reward.values.NonCancelled==1);
h(3) = patch('Faces',reshape(1:numel(idx)*4,4,[])','Vertices',cell2mat(vertices(idx)),...
      'FaceColor',patchColors{3},'EdgeColor',patchColors{3},'LineWidth',2);
% timeout-error patches
idx = find(beh.reward.values.ErrorOrTimeout==1);
h(4) = patch('Faces',reshape(1:numel(idx)*4,4,[])','Vertices',cell2mat(vertices(idx)),...
      'FaceColor',patchColors{4},'EdgeColor', patchColors{4},'LineWidth',2);

l=legend(h,patchLabels');
%set(l,'Position',[0.91 0.30 0.054 0.054])

end

%% Add plot zoom
function addPlotZoom()
    thisPlot.pos = get(gca,'Position');
    thisPlot.zoom = 0;
    set(gca,'UserData',thisPlot);
    set(gca,'ButtonDownFcn',@plotZoom);
end


