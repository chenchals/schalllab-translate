function Task = mergeTasks(subTask,taskHeads)

taskStr = {'CMD','MG','Search','Pro-Anti'};
taskCode = [1501, 1502, 1508, 1509];

uTasks = nunique(taskHeads);
Task.TaskType = cell(length(taskHeads),1);
for it = 1:length(uTasks)
    taskInds = taskHeads == uTasks(it);
    [Task.TaskType{taskInds}]=deal(taskStr{taskCode == uTasks(it)});
    taskFields = fieldnames(subTask{it});
    for iField = 1:length(taskFields)
        if ~isfield(Task,taskFields{iField})
            if isnumeric(subTask{it}.(taskFields{iField}))
                Task.(taskFields{iField}) = nan(length(taskHeads),size(subTask{it}.(taskFields{iField}),2));
            elseif iscell(subTask{it}.(taskFields{iField}))
                Task.(taskFields{iField}) = cell(length(taskHeads),size(subTask{it}.(taskFields{iField}),2));
            end
        end
        Task.(taskFields{iField})(taskInds,1:size(subTask{it}.(taskFields{iField}),2)) = subTask{it}.(taskFields{iField});
    end
end
