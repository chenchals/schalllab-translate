

%ks1Phy = '/scratch/subravcr/ksDataProcessed/Joule/cmanding/ephys/TESTDATA/In-Situ/Joule-190725-111052/ks1_0';
%npyFiles = dir([ks1Phy '/*.npy']);
baseDataLoc = 'data/Joule/cmanding/ephys/TESTDATA/In-Situ';
tank = 'Joule-190731-121704';
wavBase = fullfile(baseDataLoc, tank);
%% Wav1_Ch*.sev files and their properties
wavFiles=dir(fullfile(wavBase,'*Wav1_Ch*.sev'));
wavFileSize=wavFiles(1).bytes;
wavFileOffset = 40;
dataWidth = 4;
dataType = 'single';
nTimeSamples = (wavFileSize-40)/dataWidth;
Fs = 24414.0625;

%% Explore signal quality
ch = 1;
wavKaleb = '/Volumes/schalllab/data/Darwin/proNoElongationColor_physio/Darwin-190726-101405/SchallLab1-160315-114049_Darwin-190726-101405_Wav1_Ch17.sev';
memWavKaleb = memmapfile(wavKaleb,'Offset',40,'Format','single','writable',false);
memWavFile = memmapfile(fullfile(wavFiles(ch).folder,wavFiles(1).name),'Offset', 40,'Format', 'single','Writable', false);

% https://www.mathworks.com/help/signal/ref/snr.html
x = memWavFile.Data;
xk = memWavKaleb.Data;
[snr_x,noisePow_x] = snr(x(1:100000),Fs);
[snr_xk,noisePow_xk] = snr(xk(1:100000),Fs);

snr(double(x),Fs);

snr(double(xk),Fs);

% plot power and phase for diff. freqs
xFft = fft(x,length(x));
xF = ((0:1/length(x):1-1/length(x))*Fs)';
xkFft = fft(xk,length(xk));
xkF = ((0:1/length(xk):1-1/length(xk))*Fs)';

magX = abs(xFft);
phaseX = unwrap(angle(xFft));

magXk = abs(xkFft);
phaseXk = unwrap(angle(xkFft));

% plot
figure
subplot(2,1,1)
plot(xF(1:length(xF)/2),20*log10(magX(1:length(xF)/2)))
title('magnitude response')
xlabel('Frequency in kHz')
ylabel('dB')
axis tight
subplot(2,1,2)
plot(xF(1:length(xF)/2),phaseX(1:length(xF)/2))
title('phase response')
xlabel('Frequency in kHz')
ylabel('radians')
grid on;
axis tight


figure
subplot(2,1,1)
plot(xkF(1:length(xkF)/2),20*log10(magXk(1:length(xkF)/2)))
title('magnitude response - Kaleb')
xlabel('Frequency in kHz')
ylabel('dB')
axis tight
subplot(2,1,2)
plot(xkF(1:length(xkF)/2),phaseX(1:length(xkF)/2))
title('phase response - Kaleb')
xlabel('Frequency in kHz')
ylabel('radians')
grid on;
axis tight


% Use only 300 to 500 Hz powers and plot
loPass = 5000; hiPass =300;
xFft_bp = xFft(1:length(xkF)/2);
xFft_bp(xF>=loPass | xF<=hiPass)=0;



%%
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
     % chanWavforms (each column is a waveform)
    chans.wf{c} = arrayfun(@(x) ...
           tdtEbo1.data(tdtEbo1.chan == uniqChanNums(c) & tdtEbo1.sortcode == x, :)',...
           uniqSortcodes,'UniformOutput',false);
end


% vectorize each sorted waveform and plot
% reject waveforms where and abs value is > 0.001 (above 1 mV)
rejectThreshold = 0.0003;
for c = 1:numel(uniqChanNums)
    chan = uniqChanNums(c);
    wfs = chans.wf{c};
    wfs = wfs(~cellfun(@isempty,wfs));
    figure
    for w = 1:numel(wfs)
        subplot(1,numel(uniqSortcodes),w)
        wf = wfs{w};
        maxVals = max(abs(wf),[],1);
        % reject waveforms above threshold
        wf(:,maxVals>rejectThreshold)=[];        
        wf(end+1,:) = nan(1,size(wf,2));
        xx = repmat([1:size(wf,1)-1 NaN], 1, size(wf,2));
        plot(xx,wf(:))
        drawnow
    end
end



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



