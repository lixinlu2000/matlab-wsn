%get the max energy node in the path
%written by xinlu 
function [maxValue,minValue,avgValue] = max_min_avg_in_path(list)
global ATTRIBUTES
N = length(ATTRIBUTES);
for i=1:N
    power(i) = ATTRIBUTES{i}.power;
end

M = length(list);
for i=1:M
    list_energy(i) = power(list(i));
end
maxValue = max(list_energy);
minValue = min(list_energy);
avgValue = mean(list_energy);