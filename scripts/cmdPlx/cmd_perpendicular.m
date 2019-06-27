% Hi Chenchal,
% Here are the depths for the 16 perpendicular penetrations. The depths are
% in channel-units the certainty is +/- 0.5 channels. They can also be
% matched to supplementary figure 1a of our paper or Figure 5A of Godlove
% et al., 2014. Note that the depth alignments are slightly off from
% Godlove et al., 2014 because after discussions with Alex Maier, Jeff and
% I decided to approximate depth to the closest channel units rather than
% using the actual depth. 

% waveforms: 56 points, 25microsecs, 

%session,  file name,  relative depth of the 1st channel (in channel units) from surface
basePath = '/Volumes/schalllab';
baseBinPath = '/scratch/Chenchal/cmdBinaryRepo';
if ~exist(baseBinPath,'dir')
    mkdir(baseBinPath);
end

euPaths={'data/Euler/mat','data/Euler/plx'};
xPaths={'data/Xena/post_2011/mat','data/Xena/post_2011/plx'};

str= {...
 'Eu 1st session|eulsef20120910c-01|channels in gray matter|6:21'; % resorted halfway through, notes p.26
 'Eu 2nd session|eulsef20120911c-01|channels in gray matter|6:21'; %excellent as per notes p.27
 'Eu 3rd session|eulsef20120912c-01|channels in gray matter|8:23';
 'Eu 4th session|eulsef20120913c-01|channels in gray matter|9:24';
 'Eu 5th session|eulsef20120914c-01|channels in gray matter|12:24';
 'Eu 6th session|eulsef20120915c-01|channels in gray matter|6:21';
 'X-site1 1st session|xensef20120420a-01|channels in gray matter|13:24';
 'X-site1 2nd session|xensef20120423b-final|channels in gray matter|6:21';
 'X-site1 3rd session|xensef20120424c-final|channels in gray matter|8:23';
 'X-site1 4th session|xensef20120425c-final|channels in gray matter|12:24';
 'X-site1 5th session|xensef20120426c-01|channels in gray matter|12:24';
 'X-site1 6th session|xensef20120427c-01|channels in gray matter|10:24';
 'X-site2 1st session|xensef20120514d-final|channels in gray matter|7:22';
 'X-site2 2nd session|xensef20120515c-final|channels in gray matter|7:22';
 'X-site2 3rd session|xensef20120516c-final|channels in gray matter|8:23';
 'X-site2 4th session|xensef20120517d-final|channels in gray matter|6:21';
};
sess = struct();
for ii = 1:numel(str)
    if startsWith(str{ii},'E')
        paths = euPaths;
    else
        paths = xPaths;
    end
    t=split(str{ii},'|');
    sess(ii).session = t{1};
    sess(ii).plxPath = paths{2};
    sess(ii).matPath = paths{1};   
    sess(ii).filename = t{2};
    sess(ii).channelNos = eval(t{4});
end

sess=struct2table(sess);

for ii=1:size(sess,1)
    mfiles = dir(fullfile(basePath,sess.matPath{ii},[sess.filename{ii} '.mat']));
    if ~isempty(mfiles)
        sess.matFile(ii) = {mfiles.name}';
    end
    % Raw file
    pfiles = dir(fullfile(basePath,sess.plxPath{ii},[sess.filename{ii} '.plx']));
    if ~isempty(pfiles)
        sess.plxFile(ii) = {pfiles.name}';
    else
        % find if base file is present
        b = split(sess.filename{ii},'-');
        pfiles = dir(fullfile(basePath,sess.plxPath{ii},[ b{1} '.plx']));
        if ~isempty(pfiles)
            sess.plxFile(ii) = {pfiles.name}';
        end
    end    
end
sigChannels = 1:24;
for ii = 1:size(sess,1)
    ifile = fullfile(basePath,sess.plxPath{ii},sess.plxFile{ii});
    fprintf('Reading plx file %s ...',ifile)    
    data = readPLXFileC(ifile,'all');
    fprintf('done\n')
    % 
    % SpikeChannels 24 channels
    ADFrequency = data.ADFrequency;
    NumPointsWave = data.NumPointsWave;
    NumPointsPreThr = data.NumPointsPreThr;
    LastTimestamp = data.LastTimestamp;
    sanityCheck = sum(data.SpikeWaveformCounts(:)) == sum(arrayfun(@(x) size(data.SpikeChannels(x).Waves,2),sigChannels));
    maxSpikeTimestamp = max(vertcat(data.SpikeChannels.Timestamps))+ NumPointsWave - NumPointsPreThr;
    sanityCheck = sanityCheck && maxSpikeTimestamp <= LastTimestamp;
    
    % Write temp files of channel data
    nChans = numel(sigChannels);
    tempDir = fullfile(baseBinPath,'temp');
    for chNo = 1:nChans
        chData = gpuArray(uint16(zeros(LastTimestamp,1)));
        wavData = gpuArray(uint16(data.SpikeChannels(chNo).Waves));
        spkTs = gpuArray(unit32(data.SpikeChannels(chNo).Timestamps));
        tic
        for ts = spkTs
            chData(ts-NumPointsPreThr:ts+NumPointsWave-NumPointsPreThr,1) = wavData(:,ts);
        end
        toc
        tFile{chNo,1} = fullfile(tempDir,num2str(chNo,'ch%03i.bin'));
        tFidw = fopen(tFile{chNo},'w');
        fwrite(tFidw,gather(chData)','int16');
        fprintf('Wrote temp file for channel %i of %i to %s in %.4f\n',chNo,nChans, tFile{chNo});
    end
    
    

%     ofile = fullfile(baseBinPath,[sess.filename{ii} '.bin']);
%     fidw = fopen(ofile,'w');
%     fprintf('Writing file %s ...',ofile)  
%     
%     nBatches = numel(sigChannels);
%     
%     for bNo = 1:nBatches
%         
%         
%         if ~isempty(data)
%            fwrite(fidw,bData(:)','int16');
%            nSampTOT = nSampTOT + numel(nData);
%            fprintf('Wrote batch %i of %i\n',bNo,nBatches);
%        end           
%     end
%     
%     
%     
%     
%     
%     
%     
%     fclose(fidw);
    fprintf('done\n')
end


%% readPLCFileC output for 'all'
% data = 
%   struct with fields:
% 
%                  Version: 106
%                  Comment: ''
%                     Date: 735123.642581019
%         NumSpikeChannels: 32
%         NumEventChannels: 28
%          NumContChannels: 64
%              ADFrequency: 40000
%            NumPointsWave: 56
%          NumPointsPreThr: 8
%                 FastRead: 0
%             WaveformFreq: 0
%            LastTimestamp: 400562777
%               Trodalness: 1
%           DataTrodalness: 1
%       BitsPerSpikeSample: 12
%        BitsPerContSample: 12
%      SpikeMaxMagnitudeMV: 3000
%       ContMaxMagnitudeMV: 5000
%          SpikePreAmpGain: 1000
%        AcquiringSoftware: ''
%       ProcessingSoftware: 'OFS 2.8.8'
%     SpikeTimestampCounts: [27×32 double]
%      SpikeWaveformCounts: [27×32 double]
%              EventCounts: [1×259 double]
%         ContSampleCounts: [1×64 double]
%      ContSampleFragments: [1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
%            SpikeChannels: [32×1 struct]
%            EventChannels: [28×1 struct]
%       ContinuousChannels: [64×1 struct]
%                 FullRead: 1
%        DataStartLocation: 67376

%% data.SpikeChannels
% struct2table(data.SpikeChannels)
% ans =
%   32×22 table
%       Name      Channel    SIGName     SIG    SourceID    ChannelID    Comment    NUnits    Ref    Filter    Gain    Threshold    WFRate    SortMethod    SortBeg    SortWidth      Template           Boxes             Fit            Timestamps             Units                Waves      
%     ________    _______    ________    ___    ________    _________    _______    ______    ___    ______    ____    _________    ______    __________    _______    _________    _____________    ______________    ____________    _________________    ________________    _________________
%     'sig001'       1       'sig001'     1        0            0          ''         0        0       1        32       -266         10          1            0          56        [5×64 double]    [5×2×4 double]    [5×1 double]    [368519×1 uint32]    [368519×1 uint8]    [56×368519 int16]
%     'sig002'       2       'sig002'     2        0            0          ''         0        0       1        32       -286         10          1            0          56        [5×64 double]    [5×2×4 double]    [5×1 double]    [297538×1 uint32]    [297538×1 uint8]    [56×297538 int16]
%     'sig003'       3       'sig003'     3        0            0          ''         0        0       1        32       -286         10          1            0          56        [5×64 double]    [5×2×4 double]    [5×1 double]    [359901×1 uint32]    [359901×1 uint8]    [56×359901 int16]
%     'sig004'       4       'sig004'     4        0            0          ''         0        0       1        32       -327         10          1            0          56        [5×64 double]    [5×2×4 double]    [5×1 double]    [331798×1 uint32]    [331798×1 uint8]    [56×331798 int16]
%     'sig005'       5       'sig005'     5        0            0          ''         0        0       1        32       -347         10          1            0          56        [5×64 double]    [5×2×4 double]    [5×1 double]    [287255×1 uint32]    [287255×1 uint8]    [56×287255 int16]
%     'sig006'       6       'sig006'     6        0            0          ''         1        0       1        32       -450         10          1            0          56        [5×64 double]    [5×2×4 double]    [5×1 double]    [137641×1 uint32]    [137641×1 uint8]    [56×137641 int16]
%     'sig007'       7       'sig007'     7        0            0          ''         2        0       1        32       -530         10          1            0          56        [5×64 double]    [5×2×4 double]    [5×1 double]    [171219×1 uint32]    [171219×1 uint8]    [56×171219 int16]
%     'sig008'       8       'sig008'     8        0            0          ''         1        0       1        32       -499         10          1            0          56        [5×64 double]    [5×2×4 double]    [5×1 double]    [258521×1 uint32]    [258521×1 uint8]    [56×258521 int16]
%     'sig009'       9       'sig009'     9        0            0          ''         1        0       1        32       -554         10          1            0          56        [5×64 double]    [5×2×4 double]    [5×1 double]    [220488×1 uint32]    [220488×1 uint8]    [56×220488 int16]
%     'sig010'      10       'sig010'    10        0            0          ''         2        0       1        32       -639         10          1            0          56        [5×64 double]    [5×2×4 double]    [5×1 double]    [222711×1 uint32]    [222711×1 uint8]    [56×222711 int16]
%     'sig011'      11       'sig011'    11        0            0          ''         1        0       1        32       -655         10          1            0          56        [5×64 double]    [5×2×4 double]    [5×1 double]    [331954×1 uint32]    [331954×1 uint8]    [56×331954 int16]
%     'sig012'      12       'sig012'    12        0            0          ''         1        0       1        32       -634         10          1            0          56        [5×64 double]    [5×2×4 double]    [5×1 double]    [448123×1 uint32]    [448123×1 uint8]    [56×448123 int16]
%     'sig013'      13       'sig013'    13        0            0          ''         1        0       1        32       -593         10          1            0          56        [5×64 double]    [5×2×4 double]    [5×1 double]    [593888×1 uint32]    [593888×1 uint8]    [56×593888 int16]
%     'sig014'      14       'sig014'    14        0            0          ''         2        0       1        32       -864         10          1            0          56        [5×64 double]    [5×2×4 double]    [5×1 double]    [323607×1 uint32]    [323607×1 uint8]    [56×323607 int16]
%     'sig015'      15       'sig015'    15        0            0          ''         3        0       1        16       -204         10          1            0          56        [5×64 double]    [5×2×4 double]    [5×1 double]    [827336×1 uint32]    [827336×1 uint8]    [56×827336 int16]
%     'sig016'      16       'sig016'    16        0            0          ''         2        0       1        32       -513         10          1            0          56        [5×64 double]    [5×2×4 double]    [5×1 double]    [303494×1 uint32]    [303494×1 uint8]    [56×303494 int16]
%     'sig017'      17       'sig017'    17        0            0          ''         1        0       1        32       -520         10          1            0          56        [5×64 double]    [5×2×4 double]    [5×1 double]    [232685×1 uint32]    [232685×1 uint8]    [56×232685 int16]
%     'sig018'      18       'sig018'    18        0            0          ''         0        0       1        32       -528         10          1            0          56        [5×64 double]    [5×2×4 double]    [5×1 double]    [192412×1 uint32]    [192412×1 uint8]    [56×192412 int16]
%     'sig019'      19       'sig019'    19        0            0          ''         0        0       1        32       -463         10          1            0          56        [5×64 double]    [5×2×4 double]    [5×1 double]    [262508×1 uint32]    [262508×1 uint8]    [56×262508 int16]
%     'sig020'      20       'sig020'    20        0            0          ''         1        0       1        32       -486         10          1            0          56        [5×64 double]    [5×2×4 double]    [5×1 double]    [305250×1 uint32]    [305250×1 uint8]    [56×305250 int16]
%     'sig021'      21       'sig021'    21        0            0          ''         0        0       1        32       -486         10          1            0          56        [5×64 double]    [5×2×4 double]    [5×1 double]    [159604×1 uint32]    [159604×1 uint8]    [56×159604 int16]
%     'sig022'      22       'sig022'    22        0            0          ''         0        0       1        32       -455         10          1            0          56        [5×64 double]    [5×2×4 double]    [5×1 double]    [453436×1 uint32]    [453436×1 uint8]    [56×453436 int16]
%     'sig023'      23       'sig023'    23        0            0          ''         0        0       1        32       -492         10          1            0          56        [5×64 double]    [5×2×4 double]    [5×1 double]    [318557×1 uint32]    [318557×1 uint8]    [56×318557 int16]
%     'sig024'      24       'sig024'    24        0            0          ''         0        0       1        32       -456         10          1            0          56        [5×64 double]    [5×2×4 double]    [5×1 double]    [270719×1 uint32]    [270719×1 uint8]    [56×270719 int16]
%     'sig025'      25       'sig025'    25        0            0          ''         0        0       0        32       -245         10          1            0          56        [5×64 double]    [5×2×4 double]    [5×1 double]    [     0×1 uint32]    [     0×1 uint8]    []               
%     'sig026'      26       'sig026'    26        0            0          ''         0        0       0        32       -245         10          1            0          56        [5×64 double]    [5×2×4 double]    [5×1 double]    [     0×1 uint32]    [     0×1 uint8]    []               
%     'sig027'      27       'sig027'    27        0            0          ''         0        0       0        32       -245         10          1            0          56        [5×64 double]    [5×2×4 double]    [5×1 double]    [     0×1 uint32]    [     0×1 uint8]    []               
%     'sig028'      28       'sig028'    28        0            0          ''         0        0       0        32       -245         10          1            0          56        [5×64 double]    [5×2×4 double]    [5×1 double]    [     0×1 uint32]    [     0×1 uint8]    []               
%     'sig029'      29       'sig029'    29        0            0          ''         0        0       0        32       -245         10          1            0          56        [5×64 double]    [5×2×4 double]    [5×1 double]    [     0×1 uint32]    [     0×1 uint8]    []               
%     'sig030'      30       'sig030'    30        0            0          ''         0        0       0        32       -245         10          1            0          56        [5×64 double]    [5×2×4 double]    [5×1 double]    [     0×1 uint32]    [     0×1 uint8]    []               
%     'sig031'      31       'sig031'    31        0            0          ''         0        0       0        32       -245         10          1            0          56        [5×64 double]    [5×2×4 double]    [5×1 double]    [     0×1 uint32]    [     0×1 uint8]    []               
%     'sig032'      32       'sig032'    32        0            0          ''         0        0       0        32       -245         10          1            0          56        [5×64 double]    [5×2×4 double]    [5×1 double]    [     0×1 uint32]    [     0×1 uint8]    []               
%
%% data.EventChannels
% struct2table(data.EventChannels)
% ans =
%   28×7 table
%        Name        Channel    SourceID    ChannelID    Comment       Timestamps             Values     
%     ___________    _______    ________    _________    _______    _________________    ________________
%     'Event001'         1         0            0          ''       [     0×1 uint32]    [     0×1 int16]
%     'Event002'         2         1            0          ''       [  3656×1 uint32]    [  3656×1 int16]
%     'Event003'         3         0            0          ''       [     0×1 uint32]    [     0×1 int16]
%     'Event004'         4         0            0          ''       [     0×1 uint32]    [     0×1 int16]
%     'Event005'         5         0            0          ''       [     0×1 uint32]    [     0×1 int16]
%     'Event006'         6         0            0          ''       [     0×1 uint32]    [     0×1 int16]
%     'Event007'         7         0            0          ''       [     0×1 uint32]    [     0×1 int16]
%     'Event008'         8         0            0          ''       [     0×1 uint32]    [     0×1 int16]
%     'Event009'         9         0            0          ''       [     0×1 uint32]    [     0×1 int16]
%     'Event010'        10         0            0          ''       [     0×1 uint32]    [     0×1 int16]
%     'Event011'        11         0            0          ''       [     0×1 uint32]    [     0×1 int16]
%     'Event012'        12         0            0          ''       [     0×1 uint32]    [     0×1 int16]
%     'Event013'        13         0            0          ''       [     0×1 uint32]    [     0×1 int16]
%     'Event014'        14         0            0          ''       [     0×1 uint32]    [     0×1 int16]
%     'Event015'        15         0            0          ''       [     0×1 uint32]    [     0×1 int16]
%     'Event016'        16         0            0          ''       [     0×1 uint32]    [     0×1 int16]
%     'Strobed'        257         1            0          ''       [124161×1 uint32]    [124161×1 int16]
%     'Start'          258         0            0          ''       [              0]    [             0]
%     'Stop'           259         0            0          ''       [      400562777]    [             0]
%     'Keyboard1'      101         0            0          ''       [     0×1 uint32]    [     0×1 int16]
%     'Keyboard2'      102         0            0          ''       [     0×1 uint32]    [     0×1 int16]
%     'Keyboard3'      103         0            0          ''       [     0×1 uint32]    [     0×1 int16]
%     'Keyboard4'      104         0            0          ''       [     0×1 uint32]    [     0×1 int16]
%     'Keyboard5'      105         0            0          ''       [     0×1 uint32]    [     0×1 int16]
%     'Keyboard6'      106         0            0          ''       [     0×1 uint32]    [     0×1 int16]
%     'Keyboard7'      107         0            0          ''       [     0×1 uint32]    [     0×1 int16]
%     'Keyboard8'      108         0            0          ''       [     0×1 uint32]    [     0×1 int16]
%     'Keyboard9'      109         0            0          ''       [     0×1 uint32]    [     0×1 int16]
%
%% data.ContinuousChannels
% struct2table(data.ContinuousChannels)
% ans =
%   64×13 table
%      Name     Channel    SpikeChannel    SourceID    ChannelID    Comment    Enabled    ADFrequency    ADGain    PreAmpGain     Timestamps      Fragments            Values      
%     ______    _______    ____________    ________    _________    _______    _______    ___________    ______    __________    ____________    ____________    __________________
%     'AD01'       0            0             0            0          ''          1          1000           5         1000       [       553]    [  10013519]    [10013519×1 int16]
%     'AD02'       1            0             0            0          ''          1          1000           5         1000       [       553]    [  10013519]    [10013519×1 int16]
%     'AD03'       2            0             0            0          ''          1          1000           5         1000       [       553]    [  10013519]    [10013519×1 int16]
%     'AD04'       3            0             0            0          ''          1          1000           5         1000       [       553]    [  10013519]    [10013519×1 int16]
%     'AD05'       4            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD06'       5            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD07'       6            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD08'       7            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD09'       8            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD10'       9            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD11'      10            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD12'      11            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD13'      12            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD14'      13            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD15'      14            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD16'      15            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD17'      16            0             0            0          ''          1          1000          10         1000       [       553]    [  10013519]    [10013519×1 int16]
%     'AD18'      17            0             0            0          ''          1          1000          10         1000       [       553]    [  10013519]    [10013519×1 int16]
%     'AD19'      18            0             0            0          ''          1          1000          10         1000       [       553]    [  10013519]    [10013519×1 int16]
%     'AD20'      19            0             0            0          ''          1          1000          10         1000       [       553]    [  10013519]    [10013519×1 int16]
%     'AD21'      20            0             0            0          ''          1          1000          10         1000       [       553]    [  10013519]    [10013519×1 int16]
%     'AD22'      21            0             0            0          ''          1          1000          10         1000       [       553]    [  10013519]    [10013519×1 int16]
%     'AD23'      22            0             0            0          ''          1          1000          10         1000       [       553]    [  10013519]    [10013519×1 int16]
%     'AD24'      23            0             0            0          ''          1          1000          10         1000       [       553]    [  10013519]    [10013519×1 int16]
%     'AD25'      24            0             0            0          ''          1          1000          10         1000       [       553]    [  10013519]    [10013519×1 int16]
%     'AD26'      25            0             0            0          ''          1          1000          10         1000       [       553]    [  10013519]    [10013519×1 int16]
%     'AD27'      26            0             0            0          ''          1          1000          10         1000       [       553]    [  10013519]    [10013519×1 int16]
%     'AD28'      27            0             0            0          ''          1          1000          10         1000       [       553]    [  10013519]    [10013519×1 int16]
%     'AD29'      28            0             0            0          ''          1          1000          10         1000       [       553]    [  10013519]    [10013519×1 int16]
%     'AD30'      29            0             0            0          ''          1          1000          10         1000       [       553]    [  10013519]    [10013519×1 int16]
%     'AD31'      30            0             0            0          ''          1          1000          10         1000       [       553]    [  10013519]    [10013519×1 int16]
%     'AD32'      31            0             0            0          ''          1          1000          10         1000       [       553]    [  10013519]    [10013519×1 int16]
%     'AD33'      32            0             0            0          ''          1          1000          10         1000       [       553]    [  10013519]    [10013519×1 int16]
%     'AD34'      33            0             0            0          ''          1          1000          10         1000       [       553]    [  10013519]    [10013519×1 int16]
%     'AD35'      34            0             0            0          ''          1          1000          10         1000       [       553]    [  10013519]    [10013519×1 int16]
%     'AD36'      35            0             0            0          ''          1          1000          10         1000       [       553]    [  10013519]    [10013519×1 int16]
%     'AD37'      36            0             0            0          ''          1          1000          10         1000       [       553]    [  10013519]    [10013519×1 int16]
%     'AD38'      37            0             0            0          ''          1          1000          10         1000       [       553]    [  10013519]    [10013519×1 int16]
%     'AD39'      38            0             0            0          ''          1          1000          10         1000       [       553]    [  10013519]    [10013519×1 int16]
%     'AD40'      39            0             0            0          ''          1          1000          10         1000       [       553]    [  10013519]    [10013519×1 int16]
%     'AD41'      40            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD42'      41            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD43'      42            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD44'      43            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD45'      44            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD46'      45            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD47'      46            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD48'      47            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD49'      48            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD50'      49            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD51'      50            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD52'      51            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD53'      52            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD54'      53            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD55'      54            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD56'      55            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD57'      56            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD58'      57            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD59'      58            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD60'      59            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD61'      60            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD62'      61            0             0            0          ''          0          1000           1         1000       [0×1 uint32]    [0×1 uint32]    [       0×1 int16]
%     'AD63'      62            0             0            0          ''          1          1000           1         1000       [       553]    [  10013519]    [10013519×1 int16]
%     'AD64'      63            0             0            0          ''          1          1000           1         1000       [       553]    [  10013519]    [10013519×1 int16]
% 
    
    