infosDefFile='~/teba/local/Tempo/rigProcLibs/FixRoom030/03_ProcLib/Search/INFOS.pro'
content = fileread(infosDefFile);
content = regexprep(content,'InfosZero\s*\+\s*','');
tokens = regexp(content,'SEND_EVT\((\w*[ +]*\w*)\)','tokens');
tokens = [tokens{:}]';
startInfosIndex = find(strcmp(tokens,'StartInfos_'));
tokens = tokens(startInfosIndex:end);

infosDefFile2='~/teba/local/Tempo/rigProcLibs/FixRoom029/ProcLib_007/CMD/INFOS.PRO'
content2 = fileread(infosDefFile2);
content2 = regexprep(content2,'InfosZero\s*\+\s*|abs\(|\(|\s*\+\s*\d*|\);','');
tokens2 = regexp(content2,'Set_event\]\s*=\s*(\w*[ +]*\w*)','tokens');
tokens2 = [tokens2{:}]';
startInfosIndex2 = find(strcmp(tokens2,'StartInfos_'));
tokens2 = tokens2(startInfosIndex2:end);
tokens2


eventDefFile='~/teba/local/Tempo/rigProcLibs/FixRoom029/ProcLib_007/EVENTDEF.PRO'
content3 = fileread(eventDefFile);
tokens3 = regexp(content3,'constant\s+([A-Z]\w*)\s*=\s*(\d{1,4});','tokens');
tokens3 = [tokens3{:}];
tokens3 = reshape(tokens3, [2, numel(tokens3)/2])';
codeNames = tokens3(:,1);
codeVals = cellfun(@str2num,tokens3(:,2));


