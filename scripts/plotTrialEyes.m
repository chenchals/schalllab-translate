
edfData = trialEyes.edfEyeX;
tdtData = trialEyes.tdtEyeX;

tdtFs = trialEyes.tdt.FsHz;
edfFs = trialEyes.edf.FsHz;

tdtBinWidth = trialEyes.tdt.BinWidthMs;

nTrials = size(tdtData,1);

% From Edf2Mat.m in edf-converter
MISSING_DATA_VALUE  = -32768;
EMPTY_VALUE         = 1e08;


edfData = arrayfun(@(x) replaceValue(edfData{x},MISSING_DATA_VALUE,nan),(1:nTrials)','UniformOutput',false);
edfData = arrayfun(@(x) replaceValue(edfData{x},EMPTY_VALUE,nan),(1:nTrials)','UniformOutput',false);

% Plot some data after aligning... not yet hashed out.....
%edfStartIndex = startIndices(1);
voltRange = [-5 5];
signalRange = [-0.2 1.2];
pixelRangeX = [0 1024]; % Eye-X

volt2pixFx = @(x) tdtAnalog2Pixels(x,voltRange,signalRange,pixelRangeX);

tdtX2Pix = arrayfun(@(x) volt2pixFx(tdtData{x}), (1:nTrials)','UniformOutput',false);

skip = -ceil(nTrials/100);

for ii = nTrials:skip:1
    tX = tdtX2Pix{ii};
    eX = edfData{ii};
    plot(1:numel(eX),eX,'r');
    hold on
    plot((1:numel(tX)).*tdtBinWidth,tX,'b');
    hold off
    xlabel(num2str(ii,'Trial #%d'));
    pause(3)
end


function vec = replaceValue(vec,val,subVal)
      vec(vec==val)=subVal;
end
