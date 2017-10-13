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
sim_params('set_app','SourcePercentage',0.4);
sim_params('set_app','SourceUnique',0);

sim_params('set_app', 'DestinationType', 'static');
sim_params('set_app', 'DestinationCenterType', 'fixed');
sim_params('set_app', 'DestinationCenterX', N_num);
sim_params('set_app', 'DestinationCenterY', N_num-1);

% sim_params('set_app', 'SourceRate', 1); %1 sec 1 msg, 0.1 = 10 sec 1 msg
sim_params('set_app', 'SourceRate', 0.2);
sim_params('set_app', 'RandSpeedDestination', 0);
sim_params('set_app', 'RandSpeedSource', 0.00);

initTime = 50;
sim_params('set_app', 'InitTime',initTime); %init time, app layer will hold on

Max_Sim_Time = 300;
Number_of_Runs = 1;
Time_Interval = 10;
dir=  'results/results1012';
% TIME = 1:Time_Interval:(Max_Sim_Time + InitTime); 
%TIME = 1:Time_Interval:(Max_Sim_Time); 

% sim_params('set_app', 'DestFunc', 'geo_dest'); 
% sim_params('set_app', 'CostFunc', 'energy_cost'); 
global TIME;
set_layers({'mac', 'neighborhood', 'accr_original', 'init_hello', 'app', 'stats'}); % for basic ant routing
[delays1, throughput1, lossrate1, succrate1, energy1, energy_var1, sent1, control1] = routing_test(Max_Sim_Time + initTime, Number_of_Runs, Time_Interval);
X=[TIME;delays1;throughput1;lossrate1;succrate1;energy1;energy_var1;sent1;control1];
filename = [dir, '/accr_original2.txt'];
fid = fopen(filename, 'w');
fprintf(fid, '%d %f %f %f %f %d %f %d %d\n', X);
fclose(fid);

% set_layers({'mac', 'neighborhood', 'check_duplicate', 'mcbr_ant', 'init_backward', 'app', 'stats'});
% [delays2, throughput2, lossrate2, succrate2, energy2, energy_var2, sent2,control2] = routing_test(Max_Sim_Time, Number_of_Runs, Time_Interval);
% X=[TIME;delays2;throughput2;lossrate2;succrate2;energy2;energy_var2;sent2;control2];
% filename = [dir, '/mcbr_ant2.txt'];
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

