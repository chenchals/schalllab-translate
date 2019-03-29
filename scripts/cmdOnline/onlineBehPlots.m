
%% Inhibition fx plot
figure; 
yyaxis('left');
plot(beh.inhibition.ssdStatsAll.mean_UseSsdIdx+1, beh.inhFx.values.pNC,'o-b','LineWidth',2,'MarkerSize',14);
hold on
plot(beh.inhibition.ssdStatsCancelled.mean_UseSsdIdx+1, beh.inhFx.values.pNC(1:3),'d','MarkerSize', 8, 'MarkerFaceColor','k','MarkerEdgeColor','y');
hold on
ylim([0 1.1])
ylabel('pNC')
xlabel('SSD (# vertical refresh)')
grid on
title('Inhibition function')
yyaxis('right');
bb = bar(beh.inhibition.ssdStatsAll.mean_UseSsdIdx+1,beh.inhFx.values.nTrials,...
    'BarWidth',0.95,'FaceAlpha',0.6);
ylim([0 max(beh.inhFx.values.nTrials)*1.1])
xticklabels([0; beh.inhibition.ssdStatsAll.mean_UseSsdVrCount])
set(gca, 'SortMethod', 'depth')
ylabel('# STOP trials')

%%

