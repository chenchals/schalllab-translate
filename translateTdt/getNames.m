function [output] = getNames(inArg, varargin)
%GETNAMES Summary of this function goes here
%   Detailed explanation goes here
    pre = [];
    if nargin == 1
        output = {};
    else
        output = varargin{1};
        if nargin == 3
            pre = varargin{2};
        end
    end
    try
    if istable(inArg)
        fns = inArg.Properties.VariableNames';
        if ~isempty(pre)
            fns = strcat(pre,'.',fns);
         end
        output = [output ; fns ];
    elseif isstruct(inArg)
        fns = fieldnames(inArg);
        for ii = 1:numel(fns)
            fn = fns{ii};
            temp = inArg.(fn);
            if ~isempty(pre)
                fn = strcat(pre,'.',fn);
            end
            if isstruct(temp) || istable(temp)
                output = getNames(temp, output, fn);
            else
                output = [output ; fn]; %#ok<AGROW>
            end
        end
    end
    catch me
        disp(me)
    end
end

