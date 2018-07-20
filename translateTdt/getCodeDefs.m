function [code2Name, name2Code] = getCodeDefs(codesFile, isProcFile)
%GETCODEDEFS Parse files conatining event or infos definitions into
%code-name pairs

    % Matching expressins are different for 
    %   1. INFOS.pro file 
    %   2. TEMPO_EV_...rigXXX.m file
    if isProcFile
        matchExpr = 'InfosZero\s*\+\s*\(*(\w*)\s*.*;';
    else
        matchExpr = 'EV\.([A-Z]\w*)\s*=\s*(\d{1,4});';
    end
    rFid = fopen(codesFile,'r');
    count = 0;
    while ~feof(rFid)
        toks = regexp(fgetl(rFid),matchExpr,'tokens');
        if ~isempty(toks)
            count = count + 1;
            ev.name{count,1} = toks{1}{1};
            if isProcFile 
                % only 1 token use count as code
                % code will be count = index into Info Vector
                % codeValue = tdtEventCode - InfosZero (3000)
                ev.code{count,1} = count;
            else
                ev.code{count,1} = str2double(toks{1}{2});
            end
        end
    end
    fclose(rFid);
    code2Name = containers.Map(ev.code, ev.name);
    name2Code = containers.Map(ev.name, ev.code);
end
