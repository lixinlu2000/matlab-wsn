function out = routing_strategies(varargin)

% Written by Ying Zhang yzhang@parc.com
% Last modified: Dec. 22, 2003  by YZ

Max_Sim_Time = varargin{1};
Number_of_Runs = varargin{2};
if (length(varargin)>2)
    Time_Interval = varargin{3};
else
    Time_Interval = 1;    
end

Time = 1:Time_Interval:Max_Sim_Time;

if (length(varargin)>3)
    dir = varargin{4};
else
    dir = '.';    
end

set_layers({'mac', 'neighborhood', 'ant_routing', 'init_hello', 'app', 'stats'});
[delays1, throughput1, lossrate1, succrate1, energy1, energy_var1, sent1] = routing_test(Max_Sim_Time, Number_of_Runs, Time_Interval);
X=[Time;delays1;throughput1;lossrate1;succrate1;energy1;energy_var1;sent1];
filename = [dir, '/ant_routing.txt'];
fid = fopen(filename, 'w');
fprintf(fid, '%d %f %f %f %f %d %f %d\n', X);
fclose(fid);

set_layers({'mac', 'neighborhood', 'check_duplicate', 'mcbr_ant', 'init_backward', 'app', 'stats'});
[delays2, throughput2, lossrate2, succrate2, energy2, energy_var2, sent2] = routing_test(Max_Sim_Time, Number_of_Runs, Time_Interval);
X=[Time;delays2;throughput2;lossrate2;succrate2;energy2;energy_var2;sent2];
filename = [dir, '/mcbr_ant.txt'];
fid = fopen(filename, 'w');
fprintf(fid, '%d %f %f %f %f %d %f %d\n', X);
fclose(fid);

set_layers({'mac', 'transmit_queue', 'neighborhood', 'delay_transmit', 'mcbr_smart_ant', 'init_backward', 'app', 'stats'});
[delays3, throughput3, lossrate3, succrate3, energy3, energy_var3, sent3] = routing_test(Max_Sim_Time, Number_of_Runs, Time_Interval);
X=[Time;delays3;throughput3;lossrate3;succrate3;energy3;energy_var3;sent3];
filename = [dir, '/mcbr_smart_ant.txt'];
fid = fopen(filename, 'w');
fprintf(fid, '%d %f %f %f %f %d %f %d\n', X);
fclose(fid);

set_layers({'mac', 'neighborhood', 'delay_transmit', 'mcbr_flood_ant', 'init_backward', 'app', 'stats'});
[delays4, throughput4, lossrate4, succrate4, energy4, energy_var4, sent4] = routing_test(Max_Sim_Time, Number_of_Runs, Time_Interval);
X=[Time;delays4;throughput4;lossrate4;succrate4;energy4;energy_var4;sent4];
filename = [dir, '/mcbr_flood_ant.txt'];
fid = fopen(filename, 'w');
fprintf(fid, '%d %f %f %f %f %d %f %d\n', X);
fclose(fid);


function set_layers(names)
all_layers = all_app_layers;
for i=1:length(all_layers)
    sim_params('set_app', all_layers{i}, 0);
end

for i=1:length(names)
    sim_params('set_app', names{i}, 1);
end