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
    
    isInfosDefFile = false;
    if contains(codesFile,'INFOS.pro')
        isInfosDefFile = true;
        matchExpr = '^\s*Event_fifo.*InfosZero\s*\+\s*\(*(\w*)\s*.*;';        
    elseif contains(codesFile,'EVENTDEF.pro') % EVENDTDEF.pro file
        matchExpr = '^declare hide constant\s+([A-Z]\w*)\s*=\s*(\d{1,4});';
    elseif ~isempty(regexp(codesFile,'rig.*\.m$','match'))
        % it is a '...._rigXXX.m' file
        matchExpr = 'EV\.([A-Z]\w*)\s*=\s*(\d{1,4});';
    else
        error('Unknown codes file %s',codesFile);
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
    code2Name = containers.Map(ev.code, ev.name);
    name2Code = containers.Map(ev.name, ev.code);
end
