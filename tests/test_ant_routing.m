% Written by Xinlu, xinlu.li@mydit.ie
% 2017/6/24

disp('With the GUI window open, you can see the simulations running,')
disp('but it may take a while.')
disp('Without the GUI it''s much faster.')
disp(' ')

is_gui=input('Do you want to continue with (1) or without (0) the GUI? ');
if is_gui
    prowler('OpenGUI')
    prowler('show_animation', 1)
    prowler('show_events', 1)
else
    prowler('CloseGUI')
end 

% set the default simualtion parameter
sim_params('set_default') 
sim_params('set','APP_NAME','Rmase') % set the APP_NAME

%  set application default parameter
sim_params('set_app_default');

sim_params('set_app','Xsize',7);
sim_params('set_app','Ysize',7);

sim_params('set_app', 'SourceCenterType', 'fixed');
sim_params('set_app', 'SourceCenterX', 3);
sim_params('set_app', 'SourceCenterY', 3);

sim_params('set_app', 'DestinationType', 'static');
sim_params('set_app', 'DestinationCenterType', 'fixed');
sim_params('set_app', 'DestinationCenterX', 6);
sim_params('set_app', 'DestinationCenterY', 6);
sim_params('set_app', 'SourceRate', 1);
sim_params('set_app', 'RandSpeedDestination', 0);
sim_params('set_app', 'RandSpeedSource', 0.00);

Max_Sim_Time = 200;
Number_of_Runs = 5;
Time_Interval = 10;
dir=  'testant/results0807';
TIME = 1:Time_Interval:Max_Sim_Time;

% 设置layers，不同的routing protocol对应不同的layer.
% Basic Ant
%set_layers({'mac', 'neighborhood', 'ant_routing', 'init_hello', 'app', 'stats'}); % for basic ant routing
% Sensor-driven Cost-aware Ant Routing (SC) 
set_layers({'mac', 'neighborhood', 'check_duplicate', 'mcbr_ant', 'init_backward', 'app', 'stats'});
% Energy ant routing
%set_layers({'mac', 'neighborhood', 'check_duplicate', 'energy_ant', 'init_backward', 'app', 'stats'});
% Flooded Forward Ant Routing (FF)
%set_layers({'mac', 'neighborhood','transmit_queue','delay_transmit', 'mcbr_smart_ant', 'init_backward', 'app', 'stats'});
% Flooded Piggybacked Ant Routing (FP)
%set_layers({'mac', 'neighborhood', 'delay_transmit', 'mcbr_flood_ant', 'init_backward', 'app', 'stats'});
[delays, throughput, lossrate, succrate, energy, energy_var, sent] = routing_test(Max_Sim_Time, Number_of_Runs, Time_Interval);
X=[TIME;delays;throughput;lossrate;succrate;energy;energy_var;sent];

filename = [dir, '/ant_routing.txt'];
fid = fopen(filename, 'w');
fprintf(fid, '%d %f %f %f %f %d %f %d\n', X);
fclose(fid);