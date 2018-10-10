function [code2Name, name2Code] = getCodeDefs(codesFile)
%GETCODEDEFS Parse files conatining declarations for Event or Info codes.
%
%   codesFile : File that contains declarations for (Code, Name) pairs.
%               This file can be one of the following files that contains
%               *specific* matching expressions to extract [Code-Name]
%               pairs. Ensure that there are no duplicate codes or
%               different names for same code. If there are duplicates, the
%               call will issue a warning and proceed. This should be
%               treated as an error in experiment setup files.
%               Matching expressins are different for different files:
% <html>
% <table><th><td>test1</td></th><tr><td>blah</td></tr></table>
% </html>
% ________________________________________________________________________
% |   Filename    |  Matching Expression                                 |
% ------------------------------------------------------------------------
% |INFOS.pro      |'^\s*Event_fifo.*InfosZero\s*\+\s*\(*(\w*)\s*.*;'     |
% |EVENTDEF.pro   |'^declare hide constant\s+([A-Z]\w*)\s*=\s*(\d{1,4});'|
% |....rigXXXXX.m |'EV\.([A-Z]\w*)\s*=\s*(\d{1,4});'                     |
% ------------------------------------------------------------------------
%
% Example:
% codesFile = 'data/Joule/TEMPO/currentProcLib/EVENTDEF.pro';
% [evCodec.code2Name, evCodec.name2Code] = getCodeDefs(codesFile);
%
% See also GETRELCODES, VERIFYEVENTCODES, TDTEXTRACTBEHAVIOR
    
    if contains(codesFile,'INFOS')
        [ev.code, ev.name] = parseInfosCodes(codesFile);   
    elseif contains(codesFile,'EVENTDEF') % EVENDTDEF.pro file
        [ev.code, ev.name] = parseEventCodes(codesFile);
    else
        error('Unknown codes file %s',codesFile);
    end    
    % fix duplicate names: ?
     code2Name = containers.Map(ev.code, ev.name);
     name2Code = containers.Map(ev.name, ev.code);
end

function [codes, names] = parseEventCodes(codeFile)
    content = fileread(codeFile);
    tokens = regexp(content,'constant\s+([A-Z]\w*)\s*=\s*(\d{1,4});','tokens');
    tokens = [tokens{:}];
    tokens = reshape(tokens, [2, numel(tokens)/2])';
    names = tokens(:,1);
    codes = cellfun(@str2num,tokens(:,2));
    codesGt3000 = find(codes>3000);
    if ~isempty(codesGt3000)
        warning(sprintf('There are Event codes greater than 3000.\nIf these are commented out, please *REMOVE* commented out line(s)\n')); %#ok<SPWRN>
        disp(table(names(codesGt3000),codes(codesGt3000),...
             'VariableNames',{'EventName','EventCode'}));
        warning(sprintf('EVENTCODES greater than 3000 are NOT Processed...\n')); %#ok<SPWRN>  
    end
end

function [codes, names] = parseInfosCodes(codesFile)
    content = fileread(codesFile);
    content = regexprep(content,'InfosZero\s*\+\s*|abs\(|\(|\s*\+\s*\d*|\);','');
    content = regexprep(content,'Int','');
    sendEvtRegEx = 'spawnwait SEND_EVT(\w*)';
    %setEvtRegEx = 'Set_event\]\s*=\s*(\w*[ +]*\w*)';
    setEvtRegEx = 'Set_event\]\s*=\s*(\w*)';
    % Check both patterns:
    names = regexp(content,sendEvtRegEx,'tokens');
    if isempty(names)
        names = regexp(content,setEvtRegEx,'tokens');
    end
    names = [names{:}]';    
    names = names(~ismember(names,{'StartInfos_','EndInfos_'}));
    codes = (1:numel(names))';

end


function [ev ]= old(codesFile, isInfosDefFile) %#ok<DEFNU>
    if isInfosDefFile
        matchExpr = '^\s*Event_fifo.*InfosZero\s*\+\s*[abs\(|\(]*(\w*)\s*.*';
    else
        matchExpr = '^declare hide constant\s+([A-Z]\w*)\s*=\s*(\d{1,4});';
    end

    rFid = fopen(codesFile,'r');
    count = 0;
    while ~feof(rFid)
        toks = regexp(fgetl(rFid),matchExpr,'tokens');
        if ~isempty(toks)
            count = count + 1;
            ev.name{count,1} = toks{1}{1};
            if isInfosDefFile 
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

end
