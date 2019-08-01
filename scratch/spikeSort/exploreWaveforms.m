

%ks1Phy = '/scratch/subravcr/ksDataProcessed/Joule/cmanding/ephys/TESTDATA/In-Situ/Joule-190725-111052/ks1_0';
%npyFiles = dir([ks1Phy '/*.npy']);
baseDataLoc = 'data/Joule/cmanding/ephys/TESTDATA/In-Situ';
tank = 'Joule-190731-121704';
wavBase = fullfile(baseDataLoc, tank);
% see if you can get waveforms from the Box thresholds
% tdtAllsData = TDTbin2mat(fullfile(baseDataLoc,tank));
% get only BOx1 data that is stored: store name : eBo1
tdtEbo1 = TDTbin2mat(fullfile(baseDataLoc,tank),'STORE',{'eBo1'});
tdtInfo = tdtEbo1.info;
tdtEbo1 = tdtEbo1.snips.eBo1;

% for each channel get indexof channel & sortcode
uniqSortcodes = unique(tdtEbo1.sortcode);
uniqChanNums = unique(tdtEbo1.chan);
for c = 1:numel(uniqChanNums)
    chans.sortIdx{c} = arrayfun(@(x) ...
           find(tdtEbo1.chan == uniqChanNums(c) & tdtEbo1.sortcode == x),...
           uniqSortcodes,'UniformOutput',false);
    % chanTimestamps
    chans.ts{c} = arrayfun(@(x) ...
           tdtEbo1.ts(tdtEbo1.chan == uniqChanNums(c) & tdtEbo1.sortcode == x),...
           uniqSortcodes,'UniformOutput',false);
     % chanWavforms
    chans.wf{c} = arrayfun(@(x) ...
           tdtEbo1.data(tdtEbo1.chan == uniqChanNums(c) & tdtEbo1.sortcode == x, :),...
           uniqSortcodes,'UniformOutput',false);
end

plot(chans.wf{1}{2}(1:10,:))




% Check the recording quality
wavFns = dir([wavBase '/*Wav1_Ch*.sev']);
sampleType = 'single';
sampleWidth = 4;
dataShape = [size(wavFns,1), (wavFns(1).bytes-40)/sampleWidth];
wavFns = strcat({wavFns.folder},filesep,{wavFns.name})';


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



