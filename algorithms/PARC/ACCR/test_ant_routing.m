% Written by Xinlu, xinlu.li@mydit.ie
% 2017/6/24

disp('With the GUI window open, you can see the simulations running,')
disp('but it may take a while.')
disp('Without the GUI it''s much faster.')
disp(' ')

%is_gui=input('Do you want to continue with (1) or without (0) the GUI? ');
is_gui = 0;
if is_gui
    prowler('OpenGUI')
    prowler('show_animation', 1)
    prowler('show_events', 1)
else
    prowler('CloseGUI')
end 

N_num = 7;
% set the default simualtion parameter
sim_params('set_default') 
sim_params('set','APP_NAME','Rmase') % set the APP_NAME

%  set application default parameter
sim_params('set_app_default');

sim_params('set_app','Xsize',N_num); 
sim_params('set_app','Ysize',N_num);

% sim_params('set_app','SourceType','static');
% sim_params('set_app', 'SourceCenterType', 'fixed');
% sim_params('set_app', 'SourceCenterX', 0);
% sim_params('set_app', 'SourceCenterY', 1);
% sim_params('set_app','SourceUnique',1);

sim_params('set_app','SourceType','static'); 
sim_params('set_app', 'SourceCenterType', 'fixed');
sim_params('set_app', 'SourceCenterX', N_num/2 - 1);
sim_params('set_app', 'SourceCenterY', N_num/2 - 1);
% sim_params('set_app', 'SourceRadius', N_num/2 + 1);
sim_params('set_app', 'SourceRadius', N_num);
% sim_params('set_app','SourcePercentage',1);
sim_params('set_app','SourcePercentage',0.10);
sim_params('set_app','SourceUnique',0);
sim_params('set_app', 'SourceRate', 0.1);

sim_params('set_app', 'DestinationType', 'static');
sim_params('set_app', 'DestinationCenterType', 'fixed');
sim_params('set_app', 'DestinationCenterX', N_num);
sim_params('set_app', 'DestinationCenterY', N_num-1);

sim_params('set_app', 'AntStart', 240000);
sim_params('set_app', 'AntRatio', 2);
sim_params('set_app', 'InitPower', 30);

% 
% sim_params('set_app', 'SourceRate', 1);
% sim_params('set_app', 'RandSpeedDestination', 0);
% sim_params('set_app', 'RandSpeedSource', 0.00);

%the parameters in Energy Efficiency Performance Improvements for Ant-based
%Routing Algorithm in Wireless Sensor Networks.

% sim_params('set_app','Xdist',1);
% sim_params('set_app','Ydist',1);
% sim_params('set_app','Xsize',N_num);
% sim_params('set_app','Ysize',N_num);
% 
% sim_params('set_app','SourceType','static'); 
% sim_params('set_app', 'SourceCenterType', 'random');
% sim_params('set_app', 'SourceRadius', 1);
% sim_params('set_app', 'SourceRate', 4);
% sim_params('set_app', 'RandSourceRate', 0);
% 
% sim_params('set_app', 'DestinationType', 'static');
% sim_params('set_app', 'DestinationCenterType', 'random');
% sim_params('set_app', 'DestinationRadius', 1);
% sim_params('set_app', 'DestinationRate', 0.5);
% sim_params('set_app', 'RandDestinationRate', 0);
% 
% % sim_params('set_app', 'MaxHops', 'Inf'); %defualt value
% sim_params('set_app', 'AntStart', 240000);
% sim_params('set_app', 'AntRatio', 2);
% sim_params('set_app', 'InitPower', 30);

Max_Sim_Time = 200;
Number_of_Runs = 10;
Time_Interval = 10;
dir=  'results/results1003';
TIME = 1:Time_Interval:Max_Sim_Time;

% ant_routig test
set_layers({'mac', 'neighborhood', 'ant_routing', 'init_hello', 'app', 'stats'});
[delays1, throughput1, lossrate1, succrate1, energy1, energy_var1, sent1,control1] = routing_test(Max_Sim_Time, Number_of_Runs, Time_Interval);
X=[Time;delays1;throughput1;lossrate1;succrate1;energy1;energy_var1;sent1;control1];
filename = [dir, '/ant_routing.txt'];
fid = fopen(filename, 'w');
fprintf(fid, '%d %f %f %f %f %d %f %d %d\n', X);
fclose(fid);

% set_layers({'mac', 'neighborhood', 'accr_original', 'init_hello', 'app', 'stats'}); % for basic ant routing
% [delays1, throughput1, lossrate1, succrate1, energy1, energy_var1, sent1,control1] = routing_test(Max_Sim_Time, Number_of_Runs, Time_Interval);
% X=[TIME;delays1;throughput1;lossrate1;succrate1;energy1;energy_var1;sent1;control1];
% 
% filename = [dir, '/accr_original.txt'];
% fid = fopen(filename, 'w');
% fprintf(fid, '%d %f %f %f %f %d %f %d %d\n', X);
% fclose(fid);

% set_layers({'mac', 'neighborhood', 'check_duplicate', 'mcbr_ant', 'init_backward', 'app', 'stats'});
% [delays1, throughput1, lossrate1, succrate1, energy1, energy_var1, sent1,control1] = routing_test(Max_Sim_Time, Number_of_Runs, Time_Interval);
% X=[TIME;delays1;throughput1;lossrate1;succrate1;energy1;energy_var1;sent1;control1];
% 
% filename = [dir, '/SC.txt'];
% fid = fopen(filename, 'w');
% fprintf(fid, '%d %f %f %f %f %d %f %d %d\n', X);
% fclose(fid);
% 
% set_layers({'mac', 'transmit_queue', 'neighborhood', 'delay_transmit', 'mcbr_smart_ant', 'init_backward', 'app', 'stats'});
% [delays3, throughput3, lossrate3, succrate3, energy3, energy_var3, sent3] = routing_test(Max_Sim_Time, Number_of_Runs, Time_Interval);
% X=[TIME;delays3;throughput3;lossrate3;succrate3;energy3;energy_var3;sent3];
% filename = [dir, '/mcbr_smart_ant.txt'];
% fid = fopen(filename, 'w');
% fprintf(fid, '%d %f %f %f %f %d %f %d\n', X);
% fclose(fid);
% 
% set_layers({'mac', 'neighborhood', 'delay_transmit', 'mcbr_flood_ant', 'init_backward', 'app', 'stats'});
% [delays4, throughput4, lossrate4, succrate4, energy4, energy_var4, sent4] = routing_test(Max_Sim_Time, Number_of_Runs, Time_Interval);
% X=[TIME;delays4;throughput4;lossrate4;succrate4;energy4;energy_var4;sent4];
% filename = [dir, '/mcbr_flood_ant.txt'];
% fid = fopen(filename, 'w');
% fprintf(fid, '%d %f %f %f %f %d %f %d\n', X);
% fclose(fid);

