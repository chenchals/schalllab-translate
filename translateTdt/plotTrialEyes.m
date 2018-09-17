
edfX = trialEyes.edfTrialsEyeX;
tdtX = trialEyes.tdtTrialsEyeX;

tdtFs = trialEyes.tdtFsHz;
edfFs = trialEyes.edfFsHz;

tdtBinWidth = trialEyes.tdtBinWidthMs;

nTrials = size(tdtX,1);

% From Edf2Mat.m in edf-converter
MISSING_DATA_VALUE  = -32768;
EMPTY_VALUE         = 1e08;


edfX = arrayfun(@(x) replaceValue(edfX{x},MISSING_DATA_VALUE,nan),(1:nTrials)','UniformOutput',false);
edfX = arrayfun(@(x) replaceValue(edfX{x},EMPTY_VALUE,nan),(1:nTrials)','UniformOutput',false);

% Plot some data after aligning... not yet hashed out.....
%edfStartIndex = startIndices(1);
voltRange = [-5 5];
signalRange = [-0.2 1.2];
pixelRangeX = [0 1024]; % Eye-X

volt2pixFx = @(x) tdtAnalog2Pixels(x,voltRange,signalRange,pixelRangeX);

tdtX2Pix = arrayfun(@(x) volt2pixFx(tdtX{x}), (1:nTrials)','UniformOutput',false);


for ii = 1300:-50:1
    tX = tdtX2Pix{ii};
    eX = edfX{ii};
    plot(1:numel(eX),eX,'r');
    hold on
    plot((1:numel(tX)).*tdtBinWidth,tX,'b');
    hold off
    xlabel(num2str(ii,'Trial #%d'));
    pause(1)
end


function vec = replaceValue(vec,val,subVal)
      vec(vec==val)=subVal;
end
