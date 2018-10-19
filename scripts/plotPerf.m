
outcomeMap = containers.Map;
outcomeMap('no_fixation') = 1;
outcomeMap('broke_fixation') = 2;
outcomeMap('pro_no_saccade') = 3;
outcomeMap('nogo_correct') = 4;
outcomeMap('sacc_incorrect') = 5;
outcomeMap('broke_tgt_fixation') = 6;
outcomeMap('go_correct') = 7;
outcomeMap('nogo_incorrect') = 8;

taskInfos = struct2table(TaskInfos);
% gather vars
taskInfos = taskInfos(:,{'Trl_Outcome','itemSizeH1000x','itemSizeV1000x','displayItemSize'});
% do not use trials where values are empty
validTrials=~any(ismember(cellfun(@num2str,table2cell(taskInfos),'UniformOutput',false),''),2);

taskInfos = taskInfos(validTrials,:);
taskInfos.aspectRatio=cell2mat(taskInfos.itemSizeH1000x)./cell2mat(taskInfos.itemSizeV1000x);

uniqAspectRatios = unique(taskInfos.aspectRatio);

results = table();
results.aspectRatio = uniqAspectRatios;
for ii = 1:numel(uniqAspectRatios)
    results.goCorrect(ii,1) = sum(taskInfos.aspectRatio==uniqAspectRatios(ii) & taskInfos.Trl_Outcome==outcomeMap('go_correct'));
    results.proNoSaccade(ii,1) = sum(taskInfos.aspectRatio==uniqAspectRatios(ii) & taskInfos.Trl_Outcome==outcomeMap('pro_no_saccade'));
    results.prob(ii,1) = results.goCorrect(ii,1)/(results.goCorrect(ii,1) + results.proNoSaccade(ii,1));
end

plot(results.aspectRatio,results.prob,'o-')
