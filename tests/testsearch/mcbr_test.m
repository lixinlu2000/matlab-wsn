function out=generator_test

%* Copyright (C) 2003 PARC Inc.  All Rights Reserved.
%*
%* Use, reproduction, preparation of derivative works, and distribution 
%* of this software is permitted, but only for non-commercial research 
%* or educational purposes. Any copy of this software or of any derivative 
%* work must include both the above copyright notice of PARC Incorporated 
%* and this paragraph. Any distribution of this software or derivative 
%* works must comply with all applicable United States export control laws. 
%* This software is made available AS IS, and PARC INCORPORATED DISCLAIMS 
%* ALL WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE 
%* IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
%* PURPOSE, AND NOTWITHSTANDING ANY OTHER PROVISION CONTAINED HEREIN, ANY 
%* LIABILITY FOR DAMAGES RESULTING FROM THE SOFTWARE OR ITS USE IS EXPRESSLY 
%* DISCLAIMED, WHETHER ARISING IN CONTRACT, TORT (INCLUDING NEGLIGENCE) 
%* OR STRICT LIABILITY, EVEN IF PARC INCORPORATED IS ADVISED OF THE 
%* POSSIBILITY OF SUCH DAMAGES. This notice applies to all files in this 
%* release (sources, executables, libraries, demos, and documentation).
%*/

% Written by Ying Zhang, yzhang@parc.com
% Last modified: Nov. 22, 2003  by YZ

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
sim_params('set_default')

sim_params('set', 'APP_NAME', 'Rmase');  % set the application name for the simulator
sim_params('set_app_default');

% sim_params('set_app', 'Xoffset', 0.1);
% sim_params('set_app', 'Yoffset', 0.1);

sim_params('set_app', 'SourceCenterType', 'fixed');
sim_params('set_app', 'SourceCenterX', 6);
sim_params('set_app', 'SourceCenterY', 6);
sim_params('set_app', 'SourceRadius', 0.5);

sim_params('set_app', 'DestinationCenterType', 'fixed');
sim_params('set_app', 'DestinationCenterX', 0);
sim_params('set_app', 'DestinationCenterY', 0);
sim_params('set_app', 'DestinationRadius', 0.5);

sim_params('set_app', 'HPosX', 3);
sim_params('set_app', 'HPosY', 3);
sim_params('set_app', 'HLengthX', 3);
sim_params('set_app', 'HHeigthY', 3);

sim_params('set_app', 'InitTime', 3);
sim_params('set_app', 'SourceRate', 1);

mcbr_routing_strategies(20, 10, 1, 'tests/testsearch');
