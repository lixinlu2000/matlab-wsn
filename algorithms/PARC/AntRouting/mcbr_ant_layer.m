function status = mcbr_ant_layer(N, S)

%* Copyright (C) 2003 PARC Inc.  All Rights Reserved.
% Define variables:
% antInterval:       --time interval of ant agent;
% antStart:          --start time, default value is 3 second;
% sourceRate:        --Դ�ڵ����ݷ����ʣ�Ĭ��ֵ=0.1����10 sec 1 msg��
% antRatio:
% c1,c2,z:           --����reward(r)��ϵ�����ο���ʽ3.
% dataGain:          --the data ants are prevented from choosing links with very low
%                      probability by remapping p to p^dataGain, dataGain>1, default value = 1.2
% probGain:          --default value = 1.2
% eta:               --ϵ�����ο���ʽ1
% probability:
% rewardScale:       --learning rate�� see equation 3.
% DESTINATIONS:       --Ŀ�Ľڵ�������ֵΪ1����ʾĿ�Ľڵ�;
% SOURCES��           --Դ�ڵ�������ֵΪ1����ʾĿ�Ľڵ�;

% Written by Ying Zhang, yzhang@parc.com
% Last modified: Feb. 17, 2004  by YZ

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

%this implementation is based on AntNet by G. D. Caro and M. Dorigo
%with added mcbr functionality

global NEIGHBORS
global DESTINATIONS
global SOURCES
global Control_Sent_Count
global TIME

persistent antInterval
persistent antStart
persistent probability
persistent windowSize
persistent eta
persistent c1 c2
persistent z
persistent rewardScale
persistent dataGain
persistent probGain

switch event
case 'Init_Application'  % Initilize Application
    if (ix==1)
        sim_params('set_app', 'Promiscuous', 0);
        antStart = sim_params('get_app', 'AntStart');
        if (isempty(antStart)) antStart = 120000; end % 3 sec
        antRatio = sim_params('get_app', 'AntRatio');
        if (isempty(antRatio)) antRatio = 2; end % 1:2 control packets
        sourceRate = sim_params('get_app', 'SourceRate');
        if (isempty(sourceRate)) sourceRate = 0.1; end %10 sec 1 msg
        antInterval = antRatio*40000/sourceRate; 
        windowSize = sim_params('get_app', 'WindowSize');
        if (isempty(windowSize)) windowSize = 10; end
        eta = min(5/windowSize, 1);  % see equation 1 in paper.
        c1 = sim_params('get_app', 'C1');
        if (isempty(c1)) c1 = 0.7; end
        c2 = 1-c1;
        z = sim_params('get_app', 'Z');
        if (isempty(z)) z = 1; end
        rewardScale = sim_params('get_app', 'RewardScale');
        if (isempty(rewardScale)) rewardScale = 0.3; end
        dataGain = sim_params('get_app', 'DataGain');
        if (isempty(dataGain)) dataGain = 1.2; end
        probGain = sim_params('get_app', 'ProbGain');
        if (isempty(probGain)) probGain = 1.2; end
        
        Control_Sent_Count = 0;
    end
    probability{ID} = [];
    memory = struct('average', 0, 'variance', 0, 'window', [], 'potentials', [], 'interval', antInterval);
    
    Set_Start_Clock(antStart); %start forward ant 
    
case 'Send_Packet' % Send packet 
    
    try msgID = data.msgID; catch msgID = 0; end   
    try list = data.list; catch list = [];  end
    
    if(msgID < 0 )  %count the number of control packet, including hello message, init_backward message, forward and backward ant agents.
        Control_Sent_Count = Control_Sent_Count + 1;
    end
    
    if (msgID == -inf) %init packet
        if (isempty(memory.potentials) || DESTINATIONS(ID))
            data.cost = mcbr_dest; %mcbr_dest is function
        else
            data.cost = mcbr_cost + min(memory.potentials); %mcbr_cost is function
        end
    end
           
    if (msgID == -2) %backward ant
        try 
            data.address = list(1);
            data.list = list(2:length(list));
            PrintMessage(['<-', num2str(data.address')]);
        catch
            pass = 0;
        end
    elseif (msgID == -1)  %forward ant 
        data.list = [ID, list];
        if (~isempty(NEIGHBORS{ID})) %if there is neighbor
           RestNEIGHBORS = setdiff(NEIGHBORS{ID}, data.list);
           if (isempty(RestNEIGHBORS)) RestNEIGHBORS = NEIGHBORS{ID}; end
           total = 0;
           for n = RestNEIGHBORS
               ndx = find(NEIGHBORS{ID}==n);
               total = total + probability{ID}(ndx);
           end
           %total can be < 1 since only a fraction of the neighbors
           prob = rand*total;
           for n = RestNEIGHBORS
               ndx = find(NEIGHBORS{ID}==n);
               if (prob>0)
                   prob = prob - probability{ID}(ndx);
                   if(prob <=0)
                      data.address = NEIGHBORS{ID}(ndx);
                      PrintMessage(['->', num2str(data.address')]);
                      data.width = 5*probability{ID}(ndx);
                      inlist = find(data.list==data.address);
                      if (~isempty(inlist)) %there is loop
                          listsize = length(data.list);
                          if (listsize < 2*inlist) %loop is long
                              pass = 0;
                          else %cut loop
                              data.list = data.list(inlist+1:listsize);
                          end
                      end
                   end
               end
           end
       else %no neighbor
           pass = 0;
       end
   elseif (msgID >= 0) % data packet      
       try
           total = 0;
           for ndx = 1:length(NEIGHBORS{ID})
               total = total + probability{ID}(ndx)^dataGain;
           end
           %total can be < 1 since power is applied
           prob = rand*total;
           for ndx = 1:length(NEIGHBORS{ID})
               if (prob>0)
                   prob = prob - probability{ID}(ndx)^dataGain;
                   if(prob <=0)
                      data.address = NEIGHBORS{ID}(ndx); %select next hop 
                      PrintMessage(['f', num2str(data.address')]);
                      data.width = 5*probability{ID}(ndx);
                   end
               end
           end
       catch
           pass = 0;
       end
    end
        
case 'Packet_Received'
    rdata = data.data;
    try msgID = rdata.msgID; catch msgID = 0; end
    try list = rdata.list; catch list = []; end
    nID = find(NEIGHBORS{ID}==rdata.from);
    
    data.data.forward = 1;
    
    pass=0;
    
    if (msgID ~= -inf)
        try prob = probability{ID}(nID);
        catch probability{ID}(nID) = 0;
        end
    else
        memory.potentials(nID) = rdata.cost;
    end
    
    if (msgID == -1) %forward ant
        if(DESTINATIONS(ID)) %arriving destination
            antBackward.msgID = -2;
            antBackward.list = rdata.list;
            antBackward.cost = 0;
            status = mcbr_ant_layer(N, make_event(t, 'Send_Packet', ID, antBackward));
        else
            status = mcbr_ant_layer(N, make_event(t, 'Send_Packet', ID, data.data));
        end
    end
           
    if (msgID == -2) %backward ant
        data.data.cost = rdata.cost + mcbr_cost;
        if (isempty(memory.window))
            memory.average = data.data.cost;
            memory.window = [data.data.cost];
        else
            memory.average = memory.average + eta*(data.data.cost - memory.average);
            memory.variance = memory.variance +eta*((data.data.cost - memory.average)^2-memory.variance);
            memory.window = [data.data.cost, memory.window];
            memory.window = memory.window(1:min(windowSize, length(memory.window)));
        end
        
        Iinf = min(memory.window);
        Isup = memory.average + z*sqrt(memory.variance/windowSize);
        r = c1*Iinf/data.data.cost;
        tmp = (Isup-Iinf) + (data.data.cost-Iinf);
        if (tmp>0)
            r = r + c2*(Isup-Iinf)/tmp;
        end
        probability{ID} = Set_New_Prob(probability{ID}, nID, rewardScale*r);
        if (~SOURCES(ID))          
            status = mcbr_ant_layer(N, make_event(t, 'Send_Packet', ID, data.data));
        else
            memory.interval = memory.interval*exp(r-0.5); %adaptively set the interval
        end
    end
    
    if ((msgID >= 0) && (data.data.address == ID)) %data packet
        if(~DESTINATIONS(ID))
            status = mcbr_ant_layer(N, make_event(t, 'Send_Packet', ID, data.data));
        else % use for confirmation only
            data.data.address = 0;
            status = common_layer(N, make_event(t, 'Send_Packet', ID, data.data));
        end
    end
    
    if ((DESTINATIONS(ID) && msgID >= 0) || (msgID == -inf))
        pass =1;
        
        if((DESTINATIONS(ID) && msgID >= 0))
            disp(['I got a data packet: ' num2str(TIME)])
        end
    end
    
case 'Clock_Tick'
    try type = data.type; catch type = 'none'; end
    if (strcmp(type, 'ant_start'))
        if (isempty(probability{ID}))  %see equation 4 in paper
            if (DESTINATIONS(ID))
                cost = 0;
            else
                cost = mcbr_cost + min(memory.potentials);
            end
            values = exp((cost - memory.potentials)*probGain);       
            probability{ID} = values/sum(values);
        end
        if(SOURCES(ID))
            antForward.msgID = -1;
            status = mcbr_ant_layer(N, make_event(t+4000, 'Send_Packet', ID, antForward));             
        end
        Set_Start_Clock(t+memory.interval);
        pass =0;
    end
    if (strcmp(type, 'confirm_timeout')) %if confirm_transmit_layer is included
        rdata = data.data;
        address = rdata.address;
        nID = find(NEIGHBORS{ID}==address);
        %reduce probablity of that link at least
        probability{ID} = Set_New_Prob(probability{ID}, nID, -rewardScale/2);
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

function b=Set_Start_Clock(alarm_time);
global ID
clock.type = 'ant_start';
prowler('InsertEvents2Q', make_event(alarm_time, 'Clock_Tick', ID, clock));

function new = Set_New_Prob(old, idx, r)

if (r>0)
	for i=1:length(old)
        if (i==idx)
            new(i) = old(i) + r*(1-old(i));
        else
            new(i) = old(i) - r*old(i);
        end
	end
else
    for i=1:length(old)
        if (i==idx)
            new(i) = old(i) + r*old(i);
        else
            new(i) = old(i) - r*(1-old(i));
        end
	end
end

%another function to try
function new = Set_New_Prob1(old, idx, r)

if (r>0)
	for i=1:length(old)
        if (i==idx)
            new(i) = (old(i) + r)/(1+r);
        else
            new(i) = old(i)/(1+r);
        end
	end
else
    for i=1:length(old)
        if (i==idx)
            new(i) = old(i)/(1-r);
        else
            new(i) = (old(i) - r)/(1-r);
        end
	end
end


