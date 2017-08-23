function status = eeabr_layer(N, S)

% Copyright (C) 2003 PARC Inc.  All Rights Reserved.
% Define variables:
% antInterval:       --time interval of ant agent;
% antStart:          --start time, default value is 3 second;
% sourceRate:        --data generation rate in source node, default value =0.1 10 sec 1 msg
% antRatio:
% c1,c2,z:           --coefficient in reward(r), see equation 3.
% dataGain:          --the data ants are prevented from choosing links with very low
%                      probability by remapping p to p^dataGain, dataGain>1, default value = 1.2
% eta:               --coefficient, see equation 1.
% probability:
% rewardScale:       --learning rate, see equation 3.
% DESTINATIONS:      --;
% SOURCES:           --;

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
persistent initPower
persistent path_length

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
    end
    probability{ID} = [];
    memory = struct('average', 0, 'variance', 0, 'window', [], 'interval', antInterval);
    Set_Start_Clock(antStart); %start forward ant 
    
case 'Send_Packet'   % Send packet
    
    try msgID = data.msgID; catch msgID = 0; end   
    try list = data.list; catch list = [];  end
    
    if (msgID == -2) %if backward ant, select the next hop according to list.
        try 
            data.address = list(1); %address of next hop
            data.list = list(2:length(list));
            PrintMessage(['<-', num2str(data.address')]);
        catch
            pass = 0;
        end
    elseif (msgID == -1)  %if send forward ant 
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
                      data.address = NEIGHBORS{ID}(ndx); %select next hop
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
        %display the residual energy for debug
        %disp(['energy_ant_layer, current node: ' num2str(ID) ' residual energy:' num2str(get_energy(ID))])
        %display the neighbor list and the residual energy for neighbors
        %ngh_energy = get_ngh_energy(ID)
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
    nID = find(NEIGHBORS{ID}==rdata.from); %nID denotes the index last node in neighbor list.
    
    data.data.forward = 1;
    
    pass=0;
    
    if (msgID ~= -inf)
        try prob = probability{ID}(nID);
        catch probability{ID}(nID) = 0;
        end
    end
    
    if (msgID == -1) %forward ant
        if(DESTINATIONS(ID)) %arriving destination
            antBackward.msgID = -2; %change to backward ant
            antBackward.list = rdata.list;
            
            %calculate the pheromone increment according to equation 5 in
            %eeabr. obtain the min energy and average enengy in this list,
            %the length of the list, initial energy of node.
            %added by xinlu 2017/08/19
            initPower = sim_params('get_app', 'InitPower'); 
            path_length = length(antBackward.list);
            [maxValue,minValue,avgValue] = max_min_avg_in_path(antBackward.list);
            ph_increment = 1/(initPower - (minValue - path_length)/(maxValue - path_length));
            ph_increment = exp(ph_increment); %avoid pheromone increment too low
            
            %antBackward.cost = 0; %the original ant routing consider only
            %consider the path length as the cost.
            antBackward.cost = ph_increment;
            antBackward.ph_increment = ph_increment;
            
            status = eeabr_layer(N, make_event(t, 'Send_Packet', ID, antBackward));
        else
            status = eeabr_layer(N, make_event(t, 'Send_Packet', ID, data.data));
        end
    end
           
    if (msgID == -2) %if receive backward ant
        %update average cost and variance according to equation 1 in paper.
        %cost be the current cost of the path from the destination to the
        %current node.
        
        %calculate the travelled distance by backward ant
        backward_length = path_length - length(data.data.list);
        
        %data.data.cost = rdata.cost + 1;
        data.data.cost = rdata.ph_increment / backward_length;
        
        if (isempty(memory.window))
            memory.average = data.data.cost;
            %An observation window W of size M is kept for storing the cost
            %of path M pahts, so that the minimum cost within the window W
            %can be obtained.
            memory.window = [data.data.cost];
        else
            memory.average = memory.average + eta*(data.data.cost - memory.average);
            memory.variance = memory.variance +eta*((data.data.cost - memory.average)^2-memory.variance);
            memory.window = [data.data.cost, memory.window];
            memory.window = memory.window(1:min(windowSize, length(memory.window)));
        end
        %update probability, see equation 3 in paper.
        Iinf = min(memory.window); 
        Isup = memory.average + z*sqrt(memory.variance/windowSize);
        %Given a reward r, calculated followed by equation 3.
        r = c1*Iinf/data.data.cost;
        tmp = (Isup-Iinf) + (data.data.cost-Iinf);
        if (tmp>0)
            r = r + c2*(Isup-Iinf)/tmp;
        end
        probability{ID} = Set_New_Prob_Eeabr(probability{ID}, nID, data.data.cost);
        if (~SOURCES(ID))  %do not arrive source node ,continue to forward backward ant        
            status = eeabr_layer(N, make_event(t, 'Send_Packet', ID, data.data));
        else %reach source node, calculate interval
            memory.interval = memory.interval*exp(r-0.5); %adaptively set the interval
        end
    end
    
    if (msgID >= 0) %data packet
        if(~DESTINATIONS(ID)) %forward
            status = eeabr_layer(N, make_event(t, 'Send_Packet', ID, data.data));
        end
    end
    
    if ((DESTINATIONS(ID) && msgID >= 0) || (msgID == -inf))
        pass =1;
    end
    
case 'Clock_Tick'
    try type = data.type; catch type = 'none'; end
    if (strcmp(type, 'ant_start'))
        if (isempty(probability{ID}))
            %probability initialization
            probability{ID} = ones(1, length(NEIGHBORS{ID}))/length(NEIGHBORS{ID});
        end
        if(SOURCES(ID))
            antForward.msgID = -1;
            status = eeabr_layer(N, make_event(t+4000, 'Send_Packet', ID, antForward));            
        end
        Set_Start_Clock(t+memory.interval);
        pass =0;
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

% update transfer probability, see equation 2,3
% Define variables:
% old:    --probability vector of neigbor list 
% idx:    --probability need to update, denote the index in list.
% r:      --reward
function new = Set_New_Prob(old, idx, r)

for i=1:length(old)
    if (i==idx)
        new(i) = old(i) + r*(1-old(i));
    else
        new(i) = old(i) - r*old(i);
    end
end

function new = Set_New_Prob_Eeabr(old,idx,ph)
for i =1:length(old)
    if(i==idx)
        new(i) = old(i) + ph;
    else
        %0.1 is a coefficient, such that (1-0.1) represents the
        %evaportation of trail, according to the equation 3 in eeabr.
        new(i) = old(i) - 0.1 * old(i); 
    end
end


% get the residual energy for specific node
% added by xinlu 2017/8/2
function out=get_energy(ID)
global ATTRIBUTES
out = ATTRIBUTES{ID}.power;
    
% get the residual energy array for specific node neighbor list
% added by xinlu 2017/8/2
function out=get_ngh_energy(ID)
global NEIGHBORS
global ATTRIBUTES
if (~isempty(NEIGHBORS{ID})) %if there is neighbor
    N = length(ATTRIBUTES);
    for i=1:N
        power(i) = ATTRIBUTES{i}.power;
    end

    M = length(NEIGHBORS{ID});
    for i=1:M
        ngh_energy{i}.id = NEIGHBORS{ID}(i);
        ngh_energy{i}.energy=power(ngh_energy{i}.id); 
    end
end
out=ngh_energy;

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
