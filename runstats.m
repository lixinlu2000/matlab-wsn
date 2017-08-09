function [ave,std] = runstats(x)
% RUNSTATS Generate running ave/std deviation
% The values x must be passed to this function one at a time. A call
% to RUNSTATS with the argument 'reset' will reset the running sums.
% Define variables:
% ave      --Running average
% msg      --Error message
% n        --Number of data values
% std      --Running standard deviation
% sum_x    --Running sum of data values
% sum_x2    --Running sum of data values squared
% x         --Input value

persistent n   % Number of input values
persistent sum_x  % Running sum of values
persistent sum_x2  % Running sum of values squared

msg = nargchk(1,1,nargin);
error(msg);
if x == 'reset'
    n = 0;
    sum_x = 0;
    sum_x2 = 0;
else
    n = n+1;
    sum_x = sum_x + x;
    sum_x2 = sum_x2 + x^2;
end

% Calculate ave and std
if n == 0
    ave = 0;
    std = 0;
elseif n == 1
    ave = sum_x;
    std = 0;
else
    ave = sum_x / n;
    std = sqrt((n*sum_x2 - sum_x^2) / (n*(n-1)));
end
