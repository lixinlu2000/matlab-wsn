function status = mcbr_smart_ant_e_layer(N, S)

%* Copyright (C) 2003 PARC Inc.  All Rights Reserved.

% Energy related FF protocol Improvement Implementation
% Written by Ying Zhang, yzhang@parc.com, modified from Lukas Kuhn's code
% Last modified: Feb. 17, 2004  by YZ
% Last modified by xinlu 2017/08/23

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

global NEIGHBORS
global DESTINATIONS
global SOURCES

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

persistent backDelayMin
persistent backDelayRand

persistent initPower

switch event
case 'Init_Application'
    if (ix==1)
        antStart = sim_params('get_app', 'AntStart');
        if (isempty(antStart)) antStart = 120000; end % 3 sec
        antRatio = sim_params('get_app', 'AntRatio');
        if (isempty(antRatio)) antRatio = 2; end % 1:2 control packets
        sourceRate = sim_params('get_app', 'SourceRate');
        if (isempty(sourceRate)) sourceRate = 0.1; end %10 sec 1 msg
        antInterval = antRatio*40000/sourceRate; 
        windowSize = sim_params('get_app', 'WindowSize');
        if (isempty(windowSize)) windowSize = 10; end
        eta = min(5/windowSize, 1);
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
        
        backDelayMin = sim_params('get_app', 'BackDelayMin');
        if (isempty(backDelayMin)) backDelayMin = 40000; end %1 sec
        backDelayRand = sim_params('get_app', 'BackDelayRand');
        if (isempty(backDelayRand)) backDelayRand = 20000; end %0.5 sec
        
    end
    probability{ID} = [];
    memory = struct('average', 0, 'variance', 0, 'window', [],  'potentials', [], 'interval', antInterval);
    Set_Start_Clock(antStart); %start forward ant 
    
case 'Send_Packet'  % send packet
    
    try msgID = data.msgID; catch msgID = 0; end   
    try list = data.list; catch list = [];  end
    
    if (msgID == -inf) %send init backward packet
        if (isempty(memory.potentials)|| DESTINATIONS(ID))
            data.cost = mcbr_dest;
        else
            data.cost = mcbr_cost + min(memory.potentials);
        end
    end
           
    if (msgID == -2) %send backward ant
        try
            data.address = list(1); %address of next hop
            data.list = list(2:length(list));
            PrintMessage(['<-', num2str(data.address')]);
        catch
            pass = 0;
        end
    elseif (msgID == -1)  %send forward ant
        %send the forward ant exploit the broadcast channel of wireless
        %sensor networks. 
        %TODO:
        %introduce the Opportunistic Broadcast in our paper.
        data.list = [ID, list];
        data.address = 0; %broadcast       
    elseif (msgID >= 0) % data packet
       try
           total = 0;
           for ndx = 1:length(NEIGHBORS{ID})
               total = total + probability{ID}(ndx)^dataGain;
           end
           %total can be < 1 since power is applied
           if (total==0)
               probability{ID} = ones(1, length(probability{ID}))/length(probability{ID});
               total = 1;
           end
           prob = rand*total;
           for ndx = 1:length(NEIGHBORS{ID})
               if (prob>0)
                   prob = prob - probability{ID}(ndx)^dataGain;
                   if(prob <=0)
                      data.address = NEIGHBORS{ID}(ndx);
                      data.width = 5*probability{ID}(ndx);
                      PrintMessage(['f', num2str(data.address')]);
                   end
               end
           end
       catch
           pass = 0;
       end
    end
        
case 'Packet_Received'
    rdata = data.data;
    try duplicated = data.duplicated; catch duplicated = 0; end
    try msgID = rdata.msgID; catch msgID = 0; end
    try list = rdata.list; catch list = []; end
    nID = find(NEIGHBORS{ID}==rdata.from);
    
    data.data.forward = 1;
    
    pass=0;
        
    if (msgID ~= -inf)
        try prob = probability{ID}(nID);
        catch probability{ID}(nID) = 0;
        end
    else %init backward message from sink
        %msgID == -inf, obtain the estimation of the cost to the
        %destination from each of its neighbors according the init backward
        %message from sink node. rdata.cost come from the send init
        %backward function in line 100.
        memory.potentials(nID) = rdata.cost;
    end   
    
    if (msgID == -1) %receive forward ant
        if( DESTINATIONS(ID)) %arriving destination
            antBackward.msgID = -2; %change to backward ant
            antBackward.list = rdata.list;
            
            %calculate the pheromone increment according to the equation in
            %eeabr. should be modified later.
            %added by xinlu 2017/08/23
            initPower = sim_params('get_app', 'InitPower');
            antBackward.path_length = length(antBackward.list);
            %path_length = length(antBackward.list);
            [maxValue,minValue,avgValue] = max_min_avg_in_path(antBackward.list);
            ph_increment = 1/(initPower - (minValue - antBackward.path_length)/(maxValue - antBackward.path_length));
            ph_increment = exp(ph_increment); %avoid pheromone increment too low
            
            %antBackward.cost = memory.average;
            antBackward.cost = ph_increment;
            antBackward.ph_increment = ph_increment;
            
            %delay for some time to avoid collison at the destination
            status = mcbr_smart_ant_e_layer(N, make_event(t+backDelayMin+backDelayRand*rand, 'Send_Packet', ID, antBackward));
        elseif (~duplicated && (probability{ID}(nID) < 1/length(probability{ID}))) %forward only if ant from weak link
            status = mcbr_smart_ant_e_layer(N, make_event(t, 'Send_Packet', ID, data.data));
        end
    end
           
    if ((msgID == -2) && (~duplicated)) %receive backward ant
        %calcualte the travelled distance by backward ant
        %the phromenone increment need to be divided evenly in the list
        %according to the distance to the destination.
        tmp_list = 1:data.data.path_length;
        tmp_sum = sum(tmp_list);
        data.data.cost = rdata.ph_increment*(length(data.data.list)+1)/tmp_sum;
        
        %data.data.cost = rdata.cost + mcbr_cost;
        
        if (isempty(memory.window))
            memory.average = data.data.cost;
            memory.window = [data.data.cost];
        else
            memory.average = memory.average + eta*(data.data.cost - memory.average);
            memory.variance = memory.variance +eta*((data.data.cost - memory.average)^2-memory.variance);
            memory.window = [data.data.cost, memory.window];
            memory.window = memory.window(1:min(windowSize, length(memory.window)));
        end
        
        %Iinf = min(memory.window);
        Iinf = max(memory.window);
        Isup = memory.average + z*sqrt(memory.variance/windowSize);
        r = c1*Iinf/data.data.cost;
        tmp = (Isup-Iinf) + (data.data.cost-Iinf);
        if (tmp>0)
            r = r + c2*(Isup-Iinf)/tmp;
        end
        if (data.data.address==ID) %I am in the path, reinforce it
            probability{ID} = Set_New_Prob(probability{ID}, nID, rewardScale*r);
            %probability{ID} = Set_New_Prob2(probability{ID}, nID, data.data.cost);
            if (~SOURCES(ID))          
                status = mcbr_smart_ant_e_layer(N, make_event(t, 'Send_Packet', ID, data.data));
            else
                memory.interval = memory.interval*exp(r-0.5);
            end
        else %I am not in path, but maybe good to go through that node too
            probability{ID} = Set_New_Prob(probability{ID}, nID, rewardScale*r/2);
        end
    end
    
    if (msgID >= 0) %receive data packet
%         if (DESTINATIONS(ID))
%             antBackward.msgID = -2;     
%             antBackward.cost = 0;
%             
%             status = mcbr_smart_ant_e_layer(N, make_event(t, 'Send_Packet', ID, antBackward));
%         end
            
        if(~DESTINATIONS(ID) && (data.data.address == ID)) %forward if is for me
            status = mcbr_smart_ant_e_layer(N, make_event(t, 'Send_Packet', ID, data.data));
        end
    end
    
    if ((DESTINATIONS(ID) && msgID >= 0 && (~duplicated)) || (msgID == -inf))
        pass =1;
    end
    
case 'Clock_Tick'
    try type = data.type; catch type = 'none'; end
    if (strcmp(type, 'ant_start'))
        if (isempty(probability{ID}))
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
            status = mcbr_smart_ant_e_layer(N, make_event(t+4000, 'Send_Packet', ID, antForward));
        else
            memory.interval = memory.interval*probGain;
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

if (sum(old)==0)
    old = ones(1,length(old))/length(old);
end

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

%another function to try, added by xinlu 2017/08/24
function new = Set_New_Prob2(old,idx,ph)
if (sum(old)==0)
    old = ones(1,length(old))/length(old);
end
for i = 1:length(old)
    if(i==idx)
        new(i) = old(i) + ph;
    else
        new(i) = old(i) - 0.1 * old(i);
    end
end

%another function to try
function new = Set_New_Prob1(old, idx, r)

if (sum(old)==0)
    old = ones(1,length(old))/length(old);
end

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

%get the max energy node in the path
function [maxValue,minValue,avgValue] = max_min_avg_in_path(list)
global ATTRIBUTES
N = length(ATTRIBUTES);
for i=1:N
    power(i) = ATTRIBUTES{i}.power;
end

M = length(list);
for i=1:M
    list_energy(i) = power(list(i));
end
maxValue = max(list_energy);
minValue = min(list_energy);
avgValue = mean(list_energy);