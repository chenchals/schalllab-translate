function [bestFitParams,minDiscrepancyFn,weibullY,fitOutput,exitFlag] = fitWeibull(inh_SSD, inh_pNC, inh_nTr, varargin)
%FITWEIBULL Fit a Weibull function to the given data
%
% Given data which describe points on the x and y axes, Weibull uses a
% genetic algorithm approach to find parameters which minimize sum of
% squares error based on the Weibull function:
%
%    yData = gamma - ((exp(-((xData./alpha).^beta))).*(gamma-delta))
%
% The starting parameters and the upper and lower bounds are set to provide
% good fits to inhibiton function data. 
%   see Hanes, Patterson, and Schall. JNeurophysiol. 1998.
%
% INPUT:
%   inh_SSD: x-data (SSDs for inhibion function) 
%   inh_pNC: y-data (p(noncanceled|SSD) for inhibition function) 
%   inh_nTr: weights (count(nTrials|SSD) fro inhibition function)
%
% OUTPUT:
%   bestFitParams: a vector of optimum coeffecients of fit 
%                  [alpha beta gamma delta]           
%   minDiscrepancyFn: sum of squared errors at bestFitParams  
%
%   see also GET_SSRT, GA, GAOPTIMSET
%
% Author: david.c.godlove@vanderbilt.edu 
% Date: 2010/10/23
% Last modification: 2019/05/03

% /////////////////// Modifications ////////////////////////
% Revision History:
% 2019/05/03 chenchal subraveti
%       Adapted from: SEF_beh_fitWeibull.m
%       Removed option for 'pops' as it is not used.
% 2019/05/07 chenchal subraveti
%      If optimization toobox is not present: use fminsearchbnd
%      If optimization toobox is present: Use fmincon

%% options for display
   displayProgress = [0 0];
   if numel(varargin)>0
      displayProgress = contains({'printProgress','plotProgress'},varargin,'IgnoreCase',true);
   end
%% Search options
    searchOptions = struct(...
        'Display','none',...
        'MaxIter',100000,...
        'MaxFunEvals',100000,...
        'TolX',1e-6,...
        'TolFun',1e-6, ...
        'FunValCheck','off',...
        'UseParallel','always');
     if displayProgress(1)
         searchOptions.Display = 'iter';
     end
     if displayProgress(2)
         searchOptions.PlotFcns = @plotProgress;
     end
        
%% Check inputs
    logicalStr = {'FALSE','TRUE'};
    % check and convert to column vector
    assert(isvector(inh_SSD) && isvector(inh_pNC),'fitWeibull:InputNonVector',...
        sprintf('Inputs must be vectors. Is a vector: inh_SSD [%s], inh_pNC [%s]',...
        logicalStr{isvector(inh_SSD)+1},logicalStr{isvector(inh_pNC)+1}));
    % check number of elements
    assert(numel(inh_SSD)==numel(inh_pNC),'fitWeibull:InputSizeMismatch',...
        sprintf('Number of elements in inh_SSD [%d] must match number of elements in inh_pNC [%d]',numel(inh_SSD),numel(inh_pNC)))
    nGroups = numel(inh_SSD);
    % Check weights
    if nargin == 3
        assert(numel(inh_SSD)==numel(inh_pNC),'fitWeibull:InputWeightsMismatch',...
            sprintf('Number of elements in inh_nTr [%d] must match number of elements in inh_SSD [%d]',numel(inh_nTr),numel(inh_SSD)))
        inh_nTr = inh_nTr(:);
    else
        inh_nTr = ones(nGroups,1);
    end
    
%% Clean inputs and sort
    ssd = inh_SSD(:);
    pNC = inh_pNC(:);
    weights = inh_nTr(:);
    nanIdx = isnan(ssd) | isnan(pNC);
    ssd(nanIdx) = [];
    pNC(nanIdx) = [];
    % sort data
    [ssd, idx] = sort(ssd);
    pNC = pNC(idx);
    
%% Specify model parameters and bounds
    % alpha: time at which inhition function reaches 67% probability
    alpha = 200;
    % beta: slope
    beta  = 1;
    % gamma: maximum probability value
    gamma = 1; 
    % delta: minimum probability value
    delta = 0.5;   
    % must be in this format for ge.m
    param = [alpha beta gamma delta];
    % bounds for parameter optimization by position
    loBound = [1       1       0.5      0.0];  
    upBound = [1000    25      1.0      0.5];
    % force bounds max to 1 and/or min to 0
    if pNC(end) > .9 
        loBound(3) = 0.9;
    elseif pNC(end) == 1
        loBound(3) = 1;
    end
    if pNC(1) == 0
        upBound(4) = 0;
    end

%% Weight data by number of observations for each (x,y) pair
    [ssd, pNC] = arrayfun(@(x,y,t) deal(repmat(x,t,1),repmat(y,t,1)),ssd,pNC,weights,'UniformOutput',false);
    ssd = cell2mat(ssd);
    pNC = cell2mat(pNC);

%% Use fmincon or fminsearchbnd depending on presence of optimization toolbox - GA is too slow
   if license('test','Optimization_Toolbox')
       fprintf('Using FMINCON...\n')
       [bestFitParams,minDiscrepancyFn,exitFlag,fitOutput] = fmincon(@(param) weibullErr(param,ssd,pNC),param,[],[],[],[],loBound,upBound,[],searchOptions);
   else
       fprintf('Using FMINSEARCHBND...\n')
       [bestFitParams,minDiscrepancyFn,exitFlag,fitOutput] = fminsearchbnd(@(param) weibullErr(param,ssd,pNC),param,loBound,upBound,searchOptions);
   end
   weibullY = weibullFx(bestFitParams,(0:max(inh_SSD)+10));
%%

end

function [sse, yPred] = weibullErr(coeffs, x, y)
    % This is the objective function to minimize
    % Sum of squared errors method (SSE):
    %generate predictions
    %yPred = coeffs(3) - ((exp(-((x./coeffs(1)).^coeffs(2)))).*(coeffs(3)-coeffs(4)));
    yPred = weibullFx(coeffs,x);
    % % If we need a decreasing Weibull, do that here
    % if mean(diff(yData)) < 0
    %     ypred = 1-ypred;
    % end

    % Sum of squared errors method (SSE):
    %compute SSE
    sse=sum((yPred-y).^2);
end

function [yVals] = weibullFx(coeffs,x)
    yVals = coeffs(3) - ((exp(-((x./coeffs(1)).^coeffs(2)))).*(coeffs(3)-coeffs(4)));
    yVals = yVals(:);
end



function stop = plotProgress(xOutputfcn, optimValues, state, varargin)
    % create an print function for the fMinSearch
    %
    % NOTE: The plot functions do their own management of the plot and axes - if you want to
    % plot on your own figure or axes, just do the plotting in the output function, and leave
    % the plot function blank.  
    %
    % One thing the plot function DOES have it that it installs STOP and PAUSE buttons on the
    % plot that allow you to interrupt the optimization to go in and see what's going on, and 
    % then resume, or stop the iteration and still have it exit normally (and report output 
    % values, etc).  
    %
    % inputs:
    % 1) xOutputfcn = the current x values
    % 2) optimValues - structure having:
    %         optimValues.iteration = iter;  % iteration number
    %         optimValues.funccount = numf;  % number of function eval's so far
    %         optimValues.fval = f;          % value of the function at current iter.
    %         optimValues.procedure = how;   % how is fminsearch current method (expand, contract, etc)
    % 3) State = 'iter','init' or 'done'     % where we are in the fminsearch algorithm.
    % 4) varargin is passed thru fminsearch to the user function and can be anything.
    %

    symb={'\alpha','\beta ','\gamma','\delta'}';
    xOutputfcn = xOutputfcn(:);
    titleTxt = '';
    if numel(varargin)==0
        titleTxt = join(strcat(symb(1:numel(xOutputfcn)),{' : '},num2str(xOutputfcn,'%4.4f')),'; ');
    end
    titleTxt = [titleTxt;strcat(['State: ' state],{'    SSE : '}, num2str(optimValues.fval,'%4.4f'))];

    stop = false;

    hold on; 
    % this is fun - it simply plots the optimization variable (inverse figure of merit) as it 
    % goes along, so you can see it improving, or stop the iterations if it stagnates.
    rectangle('Position', ...
        [(optimValues.iteration - 0.45) optimValues.fval, 0.9, 0.5*optimValues.fval]);
    set(gca, 'YScale', 'log');

    title(titleTxt,'Interpreter','tex');
    xlabel('Iteration #')
    ylabel('log(SSE)')

    % when you run this, try pressing the 'stop' or 'pause' buttons on the plot.

    % you can add any code here that you desire.

end
