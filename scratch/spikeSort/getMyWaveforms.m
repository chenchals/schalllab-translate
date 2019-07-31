function [out] = getMyWaveforms(spkTimes,spkTempl, spkAmps,spkClusts,int16DataFile, nChan)
%GETMYWAVEFORMS Summary of this function goes here

% st3:
% col1: spkTimes
% col2: templates --> 1-based
% col3: amplitudes
% col4:
% col5: clusters --> 0-based, if st3 has only 4 cols, then (clusters = templates-1)

% 
dfStruct=dir(int16DataFile);
dataType = 'int16';
dataShape = [nChan,dfStruct.bytes/nChan/2];
memDataFile=memmapfile(int16DataFile,'Offset', 0, 'Format',{dataType,dataShape,'Data'});
wfWin = [-30:30];
fx_rawWf = @(x) memDataFile.Data.Data(:,wfWin+x);

allWf = arrayfun(fx_rawWf,double(spkTimes),'UniformOutput',false);

%fx=max(O1.allWf{1},[],2)==max(max(O1.allWf{1},[],2))
fx_maxChIdx = @(x) find(max(x,[],2) == max(max(x)));


out = table();
out.spkTimes = spkTimes;
if isempty(spkTempl)
    out.spkTempl = nan(numel(spkTimes),1);
else
    out.spkTempl = spkTempl;
end
out.spkClusts = spkClusts;
out.amps = spkAmps;
out.allWf = allWf;
out.maxIdx = cellfun(@(x) fx_maxChIdx(x),allWf,'UniformOutput',false);


end

