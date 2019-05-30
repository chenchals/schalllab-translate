function [] = addKilosort2NpyPaths(kilosort2Path,npyMatlabPath)
%ADDKILOSORT2NPYPATHS Add to kilosort2 and npy-matlab dirs to matlabpath
%   Removes existing paths for kilosort and npy-matlab from matlabpath and
%   adds specifc folders from Kilosort2 and npy-matlab to matlabpath

%% Add npy-matlab and Kilosort2 to matlab path
    rmpathsIfExists('/npy-matlab');
    addpath(npyMatlabPath);
    rmpathsIfExists('/Kilosort2/');
    dList = dir(kilosort2Path);
    dList = strcat({dList.folder}', filesep, {dList.name}');
    % do not add paths containing the pattern below
    dListIdx2Add = cellfun(@isempty,...
                   regexpi(dList,'\.|configFiles|eMouse|temp|Docs','once'));
    addpath(dList{dListIdx2Add});
%%
end

function [] = rmpathsIfExists(partialString)
% Remove all paths that contain the spefied partial string
  checkStr = regexprep(partialString,'\\|/',filesep);
  currPaths = matlabpath;
  currPaths = split(currPaths,pathsep);
  paths2removeIdx = contains(currPaths,checkStr,'IgnoreCase', false);
  if sum(paths2removeIdx) > 0
    rmpath(currPaths{paths2removeIdx});
  end
end

