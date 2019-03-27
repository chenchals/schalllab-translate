% Process raw eye values
baseDir = '/Volumes/schalllab';

baseSaveDir = fullfile(baseDir,'Users/Chenchal/Tempo_NewCode/dataProcessed');
sessName = 'Joule-190326-154110-Blinks';
sessionDir = fullfile(baseDir,'Users/Chenchal/Tempo_NewCode/Joule',sessName);


load(fullfile(baseSaveDir,sessName, 'Events.mat'));
load(fullfile(baseSaveDir,sessName, 'Eyes.mat'));
if (exist(fullfile(sessionDir,'ProcLib/rawIVals_1.csv'),'file'))
    tempoEyes = csvread(fullfile(sessionDir,'ProcLib/rawIVals_1.csv'));
end

set(0, 'DefaultTextInterpreter', 'none')

%% Convert to table
Task = struct2table(Task);
TaskInfos = struct2table(TaskInfos);
if (exist('tempoEyes','var'))
    %relTimeMs, EYE_X_VOLTS, EYE_Y_VOLTS, I_INVALID, I_INVALID_DURATION,pupil)
        tempoEyes = array2table(tempoEyes,'VariableNames',{'timeMs','eyeX','eyeY','iInvalid','iInvalidDuration','pupil'});
        rowIds = tempoEyes.eyeX < -16000 & tempoEyes.eyeY < -16000;
        tempoEyes.noEyes(rowIds) = 1;
end


%% Plot eyes and pupil for whole data set

x=tempoEyes.eyeX; x(x>-16000)=NaN;
y=tempoEyes.eyeY; y(y>-16000)=NaN;
p=tempoEyes.pupil; p(p>-10000)=NaN;
noI=tempoEyes.noEyes; noI(noI==0)=NaN;
dur=tempoEyes.iInvalidDuration; dur(dur==0)=NaN;
invalid=tempoEyes.iInvalid; invalid(invalid==0)=NaN;

loT=133460/2;
hiT=133520/2;
figure
plot(tempoEyes.timeMs(loT:hiT),tempoEyes.eyeX(loT:hiT),'-b*');
hold on
plot(tempoEyes.timeMs(loT:hiT),tempoEyes.eyeY(loT:hiT),'-r*');
hold on
plot(tempoEyes.timeMs(loT:hiT),tempoEyes.pupil(loT:hiT),'-g*');
hold on
plot(tempoEyes.timeMs(loT:hiT),tempoEyes.iInvalid(loT:hiT)*-16000,'-k*');
hold on
%plot(tempoEyes.timeMs,dur,'-m');
hold off
grid on

x=tempoEyes.eyeX; x(x>-16000)=NaN;
y=tempoEyes.eyeY; y(y>-16000)=NaN;
p=tempoEyes.pupil; p(p>-10000)=NaN;
noI=tempoEyes.noEyes; noI(noI==0)=NaN;
dur=tempoEyes.iInvalidDuration; dur(dur==0)=NaN;
invalid=tempoEyes.iInvalid; invalid(invalid==0)=NaN;

figure
plot(tempoEyes.timeMs,x,'-b');
hold on
plot(tempoEyes.timeMs,y,'-r');
hold on
plot(tempoEyes.timeMs,p,'-g');
hold on
plot(tempoEyes.timeMs,noI,'-k');
hold on
plot(tempoEyes.timeMs,dur,'-m');
hold off



d=diff(tempoEyes.iInvalidDuration);


idxNaN = tempoEyes.eyeX<12000 & tempoEyes.eyeX>-12000;
x=tempoEyes.eyeX; x(~idxNaN)=NaN;
y=tempoEyes.eyeY; y(~idxNaN)=NaN;
p=tempoEyes.pupil; p(~idxNaN)=NaN;
noI=tempoEyes.noEyes; noI(~idxNaN)=NaN;
dur=tempoEyes.iInvalidDuration; dur(~idxNaN)=NaN;
invalid=tempoEyes.iInvalid; invalid(~idxNaN)=NaN;


figure
plot(tempoEyes.timeMs,x,'-b');
hold on
plot(tempoEyes.timeMs,y,'-r');
hold on
plot(tempoEyes.timeMs,p,'-g');
hold on
plot(tempoEyes.timeMs,invalid*-16000,'-k');
hold on




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

