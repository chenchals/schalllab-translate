% Process raw eye values
baseDir = '/Volumes/schalllab';

baseSaveDir = fullfile(baseDir,'Users/Chenchal/Tempo_NewCode/dataProcessed');
sessName = 'Joule-190322-151707-Blinks';
sessionDir = fullfile(baseDir,'Users/Chenchal/Tempo_NewCode/Joule',sessName);


load(fullfile(baseSaveDir,sessName, 'Events.mat'));
load(fullfile(baseSaveDir,sessName, 'Eyes.mat'));
if (exist(fullfile(sessionDir,'ProcLib/rawIVals.csv'),'file'))
    tempoEyes = csvread(fullfile(sessionDir,'ProcLib/rawIVals.csv'));
end

set(0, 'DefaultTextInterpreter', 'none')

%% Convert to table
Task = struct2table(Task);
TaskInfos = struct2table(TaskInfos);
if (exist('tempoEyes','var'))
        tempoEyes = array2table(tempoEyes,'VariableNames',{'timeMs','eyeX','eyeY'});
        rowIds = tempoEyes.eyeX < -16000 & tempoEyes.eyeY < -16000;
        tempoEyes.noEyes(rowIds) = 1;
end

% count ones in diff and group: see accumarray
A = tempoEyes.noEyes;
%add extra not element at the beginning
temp = double(diff([~A(1);A(:)]) == 1);
deltaT = accumarray(cumsum(temp).*A(:)+1,1);
% remove the extra diff you got
temp = temp(2:end);
deltaT = deltaT(2:end);
temp(temp == 1) = deltaT(2:end);
hist(deltaT(deltaT>10 & deltaT<500),0:2:400)

% Easiest and Fastest method for counting
temp2 = zeros(numel(A),1);
% find pattern [0 1]
start_pattern_0_1 = strfind([0,A(:)'],[0 1]);
% find pattern [1 0]
end_pattern_1_0 = strfind([A(:)',0],[1 0]);
deltaT2 =  pattern_1_0  - pattern_0_1 + 1;
deltaT2 = deltaT2(:);
temp2(pattern_0_1) = deltaT2;

