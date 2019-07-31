

ks1Phy = '/scratch/subravcr/ksDataProcessed/Joule/cmanding/ephys/TESTDATA/In-Situ/Joule-190725-111052/ks1_0';
npyFiles = dir([ks1Phy '/*.npy']);

wavFn='/scratch/subravcr/ksData/Joule/cmanding/ephys/TESTDATA/In-Situ/Joule-190725-111500/CMD_TSK_029_EphysSingle-190724-081723_Joule-190725-111500_Wav1_Ch';

wavCh1=memmapfile([wavFn '1.sev'],'Offset', 40, 'Format','single');
wavCh2=memmapfile([wavFn '2.sev'],'Offset', 40, 'Format','single');
wavCh3=memmapfile([wavFn '3.sev'],'Offset', 40, 'Format','single');
wavCh4=memmapfile([wavFn '4.sev'],'Offset', 40, 'Format','single');

wavCh1=wavCh1.Data;
wavCh2=wavCh2.Data;
wavCh3=wavCh3.Data;
wavCh4=wavCh4.Data;


figure
plot(1:10)
hold on
plot(wavCh1); drawnow
plot(wavCh2); drawnow
plot(wavCh3); drawnow
plot(wavCh4); drawnow



