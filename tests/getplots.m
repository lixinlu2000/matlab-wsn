function getplots(nameX, nameY, num_points, dir, list, tag, figurename, num)

%* Copyright (C) 2003 PARC Inc.  All Rights Reserved.

% Written by Ying Zhang, yzhang@parc.com
% Last modified: Nov. 22, 2003  by YZ

symbols = {'bo-', 'gx-', 'r+:', 'c*-.', 'ms--', 'ys-','ks-','bs-','r*--','gd-'};
total = 1000;

for i=1:length(list)
    res = load([dir, '/', list{i}, '.txt']);
    time(:, i) = res(size(res,1)-num_points+1:size(res,1), 1);
    delays(:, i) = res(size(res,1)-num_points+1:size(res,1), 2);
    throughput(:, i) = res(size(res,1)-num_points+1:size(res,1), 3);
    lossrate(:, i) = res(size(res,1)-num_points+1:size(res,1), 4);
    succrate(:, i) = res(size(res,1)-num_points+1:size(res,1), 5);
    energy(:, i) = res(size(res,1)-num_points+1:size(res,1), 6);
    energy_var(:, i) = res(size(res,1)-num_points+1:size(res,1), 7);
    sent(:, i) = res(size(res,1)-num_points+1:size(res,1), 8);
    received(:, i) = succrate(:, i) .* sent(:, i);
    efficiency(:, i) = received(:, i) ./ energy(:, i);
    lifetime(:, i) = 2000 - (energy(:, i) ./ num + sqrt(energy_var(:, i)));    
end

if strcmp(nameX,'time')
    time = time-time(1,1);
end

plotstring = [];
%xrange = strcat(num2str(size(res,1)-num_points+1),':',num2str(size(res,1)));
xrange = strcat('1:',num2str(num_points));
for i=1:length(list)
    plotstring = [plotstring, nameX, '(', xrange, ',', '1', '), '];
    plotstring = [plotstring, nameY, '(', xrange, ',', num2str(i), '), ', '''', symbols{i}, ''''];
    %plotstring = [plotstring, nameY, '(', xrange, ',', num2str(i), ')'];
    if (i<length(list)) plotstring = [plotstring, ', '];
    end    
end
h=figure;
disp(['plot(', plotstring, ')'])
eval(['plot(', plotstring, ')']);
title([tag,': ',nameX, ' vs. ', nameY]), 
xlabel(nameX)
ylabel(nameY)
legendstring = [];
for i=1:length(list)
    legendstring = [legendstring, '''', list{i}, ''''];
    if (i<length(list)) 
        legendstring = [legendstring, ', '];
    end
end
eval(['legend(', legendstring, ')']);
figurename=[figurename '.fig'];
saveas(h,figurename);