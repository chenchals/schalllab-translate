function [tblEventCount] = verifyEventCodes(sessionDir, eventCodecFile)
%VERIFYEVENTCODES Check of eventCodes for task/trial integrety
%   Detailed explanation goes here
% Example:
%    sessDir = 'data/Joule/tdtData/Countermanding/Joule-180714-093508';
%    sessDir10 = ...
%    'data/Joule/tdtData/troubleshootEventCodes/Joule-180720-121327'; %//<10
%    sessDir5 = ...
%    'data/Joule/tdtData/troubleshootEventCodes/Joule-180720-120340'; %//<5
%    sessDir2 = ...
%    'data/Joule/tdtData/troubleshootEventCodes/Joule-180720-120804'; %//<2
%    outDir = 'dataProcessed/Joule/Countermanding';
%    evDefFile = 'data/Joule/TEMPO/currentProcLib/EVENTDEF.pro';%...TEMPO_EV_SEAS_rig029.m
%    infosDefFile = 'data/Joule/TEMPO/currentProcLib/CMD/INFOS.pro';

% T=verifyEventCodes(sessDir,evDefFile);
% Output:
% read up to t=5581.44s
% 
% ********************************
% data/Joule/tdtData/Countermanding/Joule-180714-093508
% data/Joule/tdtSetup/TEMPO_EV_SEAS_rig029.m
% 
% tblEventCount =
% 
%   7×3 table
% 
%                   evName                  evCode    evCount
%     __________________________________    ______    _______
% 
%     'CmanHeader_'                         1501       1640  
%     'UNKNOWN_CODE_NOT_IN_EVENT_STREAM'     NaN          0  
%     'TrialStart_'                         1666       1614  
%     'Eot_'                                1667       1632  
%     'StartInfos_'                         2998       1626  
%     'EndInfos_'                           2999       1612  
%     'UNKNOWN_CODE_IN_EVENT_STREAM'           0      29282  
% 
% 
% ********************************


    codes2Verify =[ 2681, 1501, 2680, 1666, 1667, 2998, 2999, 0];
    
    tdtFun = @TDTbin2mat;
    if ispc
        tdtFun = @TDT2mat;
    end
    % Normalize filepaths
    normFilepath = @(x) regexprep(x,'[/\\]',filesep);

    %%  Process Rig specific event codes and event names   %
     eventCodecFile = normFilepath(eventCodecFile);
    [evCodec.code2Name, evCodec.name2Code] = ...
        getCodeDefs(eventCodecFile);

    %% Read events form TDT tank/block path %%
    % Get raw TDT events codes and event times
    sessionDir = normFilepath(sessionDir);
    tdtRaw = tdtFun(sessionDir,'TYPE',{'epocs','scalars'},'VERBOSE',0); 
    
    % Assume STRB data
    events = tdtRaw.epocs.STRB.data;
    
    tblEventCount = struct();

    for ii = 1:numel(codes2Verify)
        code = codes2Verify(ii);
        if evCodec.code2Name.isKey(code) 
            evName = evCodec.code2Name(code);
            evCode = code;
            evCount = sum(events == code);
        elseif sum(events==code)
            evName = 'UNKNOWN_CODE_IN_EVENT_STREAM';
            evCode = code;
            evCount = sum(events == code);                
        else
            evName = 'UNKNOWN_CODE_NOT_IN_EVENT_STREAM';
            evCode = code;
            evCount = 0;              
        end
        tblEventCount(ii).evName = evName;
        tblEventCount(ii).evCode = evCode;
        tblEventCount(ii).evCount = evCount;
        
        
    end
    % table of codes
    tblEventCount = struct2table(tblEventCount);
    fprintf('\n********************************\n');
    fprintf('%s\n%s\n',sessionDir,eventCodecFile);
    display(tblEventCount);
    fprintf('\n********************************\n');
  
end

