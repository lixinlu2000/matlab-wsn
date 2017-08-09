%load('attribute.mat');
ATTRIBUTES{1} = struct('x', 0, 'y', 0, 'power', 1000);
ATTRIBUTES{2} = struct('x', 0, 'y', 0, 'power', 900);
ATTRIBUTES{3} = struct('x', 0, 'y', 0, 'power', 800);
ATTRIBUTES{4} = struct('x', 0, 'y', 0, 'power', 800);
ATTRIBUTES{5} = struct('x', 0, 'y', 0, 'power', 890);
ATTRIBUTES{6} = struct('x', 0, 'y', 0, 'power', 680);
ATTRIBUTES{7} = struct('x', 0, 'y', 0, 'power', 888);
ATTRIBUTES{8} = struct('x', 0, 'y', 0, 'power', 999);
ATTRIBUTES{9} = struct('x', 0, 'y', 0, 'power', 777);
ATTRIBUTES{10} = struct('x', 0, 'y', 0, 'power', 677);
NEIGBHORS = [3,5,9,10];

% if NEIGBHORS in ATTRIBUTES
%     disp('energy_ant_layer:Current Energy: ');
% end

N = length(ATTRIBUTES);
for i=1:N
    power(i) = ATTRIBUTES{i}.power;
end

M = length(NEIGBHORS);
for i=1:M
    ngh_energy{i}.id = NEIGBHORS(i);
    ngh_energy{i}.power=power(NEIGBHORS(i));
end