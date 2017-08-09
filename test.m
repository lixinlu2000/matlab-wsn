
% Written by Xinlu, xinlu.li@mydit.ie

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

%peg_model;

sim_params('set_default')       % set simulator default parameter
sim_params('set', 'APP_NAME', 'Rmase');  % set the application name for the simulator

sim_params('set_app_default');  % set application default parameter

% 设置相应的ApplicationParameters，如Xoffset, SourceType etc.
sim_params('set_app', 'Xoffset', 0);
sim_params('set_app', 'Yoffset', 0);

sim_params('set_app', 'SourceType', 'static');
sim_params('set_app', 'SourceCenterType', 'fixed');
sim_params('set_app', 'SourceCenterX', 3);
sim_params('set_app', 'SourceCenterY', 3);

sim_params('set_app', 'DestinationType', 'static');
sim_params('set_app', 'DestinationCenterType', 'fixed');
sim_params('set_app', 'DestinationCenterX', 6);
sim_params('set_app', 'DestinationCenterY', 6);
sim_params('set_app', 'SourceRate', 1);

%stop at 25 sec. for a short demo with init at 5 sec.
sim_params('set_app', 'InitTime', 5);
sim_params('set', 'STOP_SIM_TIME', 25*40000);

sim_params('set_app', 'RandSpeedDestination', 0);
sim_params('set_app', 'RandSpeedSource', 0.00);

peg_aodv(75,10,5);