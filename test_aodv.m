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
sim_params('set_app','Xsize',10);
sim_params('set_app','Ysize',10);
sim_params('set_app', 'DestinationType', 'static');
sim_params('set_app', 'DestinationCenterType', 'fixed');
sim_params('set_app', 'DestinationCenterX', 6);
sim_params('set_app', 'DestinationCenterY', 6);
sim_params('set_app', 'SourceRate', 1);
sim_params('set_app', 'RandSpeedDestination', 0);
sim_params('set_app', 'RandSpeedSource', 0.00);

Max_Sim_Time = 35;
Number_of_Runs = 5;
Time_Interval = 5;
InitTime = 5;
dir = '';    

% AODV
% sim_params('set_app', 'TransTimeout', 35000);
set_layers({'mac', 'neighborhood', 'ant_routing', 'init_hello', 'app', 'stats'});
%set_layers({'mac', 'neighborhood','confirm_transmit','check_duplicate','aodv_routing','app', 'stats', 'log'});
run_routing(dir,'antrouting.txt',Max_Sim_Time+InitTime, Number_of_Runs, Time_Interval);
