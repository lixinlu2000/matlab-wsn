function status = init_backward_layer(N, S)

%* Copyright (C) 2003 PARC Inc.  All Rights Reserved.
% Control Layer: flood from the destination to set up hop counts or to 
% build an initial spanning tree, which are used by many routing algorithms

% Written by Ying Zhang, yzhang@parc.com
% Last modified: Jan. 22, 2004  by YZ

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

global DESTINATIONS
global ATTRIBUTES

persistent clock_interval
persistent hello_times

switch event
case 'Init_Application'
    if (ix==1)
        %initilize the time interval = 0.5 second and back hello times = 3
        clock_interval = sim_params('get_app', 'InitInterval');
        if (isempty(clock_interval)) clock_interval = 20000; end %0.5 second
        hello_times = sim_params('get_app', 'InitNofTimes');
        if (isempty(hello_times)) hello_times = 3; end %every node send N hello messages, each in clock_inrerval 
    end
    Set_Dest_Clock(1000); %destination broadcast
    
case 'Packet_Received'
    try msgID = data.data.msgID; catch msgID = 0; end
    try duplicated = data.duplicated; catch duplicated = 0; end
    if ((msgID == -inf) && (~duplicated)) %continue propagate for initial stage
           PrintMessage('f');
           status = init_backward_layer(N, make_event(t, 'Send_Packet', ID, data.data)); 
    end
        
    if (~DESTINATIONS(ID) || msgID < 0)
        pass = 0;
    end
    
case 'Clock_Tick'
    try type = data.type; catch type = 'none'; end
    
    if (strcmpi(type, 'backward_dest')) % a send signal
      if (DESTINATIONS(ID))
            dest.msgID = -inf;
            dest.address = 0; %broadcast
            maxhops = sim_params('get_app', 'MaxHops');
            if (~isempty(maxhops))
                dest.maxhops = maxhops;
            end
            %dest.info = 'it is a test from backward layer.';
            status = init_backward_layer(N, make_event(t, 'Send_Packet', ID, dest));
            hello_times = hello_times - 1;
            if (hello_times>0) Set_Dest_Clock(t+clock_interval);end
      end
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

function b=Set_Dest_Clock(alarm_time);
global ID
clock.type = 'backward_dest';
prowler('InsertEvents2Q', make_event(alarm_time, 'Clock_Tick', ID, clock));

function DrawLine(command, varargin)
switch lower(command)
case 'line'
    prowler('DrawLine', varargin{:})
case 'arrow'
    prowler('DrawArrow', varargin{:})
case 'delete'
    prowler('DrawDelete', varargin{:})
otherwise
    error('Bad command for DrawLine.')
end
