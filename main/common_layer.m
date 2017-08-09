function status = common_layer(N, S)

%* Copyright (C) 2003 PARC Inc.  All Rights Reserved.
%*/

% Written by Ying Zhang, yzhang@parc.com
% Last modified: Nov. 22, 2003  by YZ

% DO NOT edit simulator code (lines that begin with S;)

S; %%%%%%%%%%%%%%%%%%%   housekeeping  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
S;      global ID t
S;      [t, event, ID, data]=get_event(S);
S;      status = 1;
S; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

persistent strength
global ATTRIBUTES

[layers, Nlayers] = app_layers;

switch event
case 'Init_Application'
    strength=sim_params('get_app', 'Strength'); 
    if (isempty(strength)) strength = 1; end
    if (Nlayers>N)
	    status = feval([layers{N+1}, '_layer'], N+1, S);
    end 
case 'Packet_Sent'
    if (Nlayers>N) 
        status = feval([layers{N+1}, '_layer'], N+1, S);
    end
case 'Packet_Received'
    if (Nlayers>N) 
        status = feval([layers{N+1}, '_layer'], N+1, S);
    end
case 'Collided_Packet_Received'
    if (Nlayers>N) 
        status = feval([layers{N+1}, '_layer'], N+1, S);
    end 
case 'Send_Packet'
    if (N>1) 
	  status = feval([layers{N-1}, '_layer'], N-1, S);
    else
      %each packet can have its strength set by the upper layer
      try s = data.strength; catch
          %each node can have its own strength set by the upper layer
		  try s = ATTRIBUTES{ID}.strength; catch s = strength; end
      end
      status = Send_Packet(radiostream(data, s)); 
    end
case 'Clock_Tick'
    if (Nlayers>N) 
       status = feval([layers{N+1}, '_layer'], N+1, S);
    end 
case 'GuiInfoRequest'
   if (Nlayers>N) 
       status = feval([layers{N+1}, '_layer'], N+1, S);
   end
case 'Application_Finished'
   if (Nlayers>N) 
       status = feval([layers{N+1}, '_layer'], N+1, S);
   end
case 'Application_Stopped'
   if (Nlayers>N) 
       status = feval([layers{N+1}, '_layer'], N+1, S);
   end
otherwise
    error(['Bad event name for application: ' event])
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                           %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%        COMMANDS           %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                           %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function b=Send_Packet(data);
global ID t
radio=prowler('GetRadioName');
b=feval(radio, 'Send_Packet', ID, data, t);
