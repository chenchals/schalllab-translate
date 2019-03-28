

figure; 
plot(beh.inhibition.ssdStatsAll.mean_UseSsdIdx+1, beh.inhibition.values.pNC,'o-b');
hold on
plot(beh.inhibition.ssdStatsCancelled.mean_UseSsdIdx+1, beh.inhibition.values.pNC(1:3),'*r');
hold off