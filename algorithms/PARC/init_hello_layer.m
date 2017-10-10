function status = init_hello_layer(N, S)
%
% Broadcast a couple of 'hello' packets at a certain interval from each
% node.
% Define variables:
% event:            --denotes events to be handled. e.g. Init_Application',
%                     'Packet_Received','Clock_Tick'
% mote_IDs:         --denotes the id of nodes
% topology:         --represents the 2D coordinates of each node
% clock_interval:   --the time interval for sending hello packet
% hello_times:      --the times of sending hello
% msgID:            --msgID is given by application at the source node; 
%                     typically different msgIDs are for different 
%                     destinations or different types of data
% address           --address of next hop; if address is 0 it means broadcast

% Written by Ying Zhang, yzhang@parc.com
% Last modified: Nov. 22, 2003  by YZ

% DO NOT edit simulator code (lines that begin with S;)

S; %%%%%%%%%%%%%%%%%%%   housekeeping  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
S;      persistent app_data 
S;      global ID t
S;      [t, event, ID, data]=get_event(S);
S;      [topology, mote_IDs]=prowler('GetTopologyInfo');
S;      ix=find(mote_IDs==ID);
S;      if ~strcmp(event, 'Init_Application') 
S;         try memory=app_data{ix}; catch memory=[]; end, 
S;      end
S;      global ATTRIBUTES
S;      status = 1;
S;      pass = 1;
S; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                                          %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%         APPLICATION STARTS               %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%               HERE                       %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                                          %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%

persistent clock_interval
persistent hello_times

switch event
case 'Init_Application'
    
    if (ix==1)
        clock_interval = sim_params('get_app', 'InitInterval');
        if (isempty(clock_interval)) clock_interval = 20000; end    %0.5 second
        hello_times = sim_params('get_app', 'InitNofTimes');
        if (isempty(hello_times)) hello_times = 3; end      %every node send N hello messages, each in clock_inrerval 
    end
    [topology, mote_IDs] = prowler('GetTopologyInfo');
    memory.hello_times = hello_times;
    memory.clock_interval = clock_interval;
    Set_Hello_Clock(100*rand*length(mote_IDs)); %nodes start at random time to avoid collapse
    
case 'Packet_Received'
    % do not forward hello message, when receive hello message
    try msgID = data.data.msgID; catch msgID = 0; end
    if (msgID<0) pass = 0; end

case 'Clock_Tick'
    try type = data.type; catch type = 'none'; end
    
    if (strcmpi(type, 'hello_send')) % a send signal
      if (memory.clock_interval < Inf)
          memory.hello_times = memory.hello_times - 1;
          Set_Hello_Clock(t+memory.clock_interval);
          if (memory.hello_times==0) memory.clock_interval = Inf; end
      end
      
      hello.msgID = -inf;
      hello.address = 0;
      %hello.info = 'it is a test from hello layer.';
      status = init_hello_layer(N, make_event(t, 'Send_Packet', ID, hello));
      pass = 0;
    end
end

%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                                          %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%         APPLICATION ENDS                 %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%               HERE                       %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                                          %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
S; %%%%%%%%%%%%%%%%%%%%%% housekeeping %%%%%%%%%%%%%%%%%%%%%%%%%%%
S;        try app_data{ix}=memory; catch app_data{ix} = []; end
S;        if (pass) status = common_layer(N, make_event(t, event, ID, data)); end
S; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                           %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%        COMMANDS           %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                           %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function PrintMessage(msg)
global ID
prowler('TextMessage', ID, msg)

function b=Set_Hello_Clock(alarm_time);
global ID
clock.type = 'hello_send';
prowler('InsertEvents2Q', make_event(alarm_time, 'Clock_Tick', ID, clock));


