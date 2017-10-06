function status = iabr_layer(N, S)

% This implementation is disgned for iabr ant routing protocol according
% to the iabr algorithm (IABR) discribed in EEABR.
% 
% Written by Xinlu Li, xinlu.li@mydit.ie 22/09/2017
% Last modified: 2017/09/29  by Xinlu

% Copyright (C) 2003 PARC Inc.  All Rights Reserved.
% Define variables:
% antInterval:       --time interval of ant agent;
% antStart:          --start time, default value is 3 second;
% sourceRate:        --data generation rate in source node, default value =0.1 10 sec 1 msg
% antRatio:
% probability:
% rewardScale:       --learning rate, see equation 3.
% DESTINATIONS:      --;
% SOURCES:           --;

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
persistent pheromone
persistent initPower
persistent evaporation
 
switch event
case 'Init_Application'  % Initilize Application
    if (ix==1)
        sim_params('set_app', 'Promiscuous', 0);
        antStart = sim_params('get_app', 'AntStart');
        if (isempty(antStart)) 
            antStart = 120000; %3 sec
        end
        antRatio = sim_params('get_app', 'AntRatio');
        if (isempty(antRatio)) 
            antRatio = 2; % 1:2 control packets
        end 
        sourceRate = sim_params('get_app', 'SourceRate');
        if (isempty(sourceRate)) 
            sourceRate = 0.1; %10 sec 1 msg
        end 
        antInterval = antRatio*40000/sourceRate; 
   
    end
    probability{ID} = [];
    pheromone{ID} = [];
    initPower = sim_params('get_app','InitPower');
    evaporation = 0.3;
%     memory = struct('average', 0, 'variance', 0, 'window', [], 'interval', antInterval);
    memory = struct('interval',antInterval);
    
    Set_Start_Clock(antStart); %start forward ant 
    
case 'Send_Packet'   % Send packet
    
    try msgID = data.msgID; catch msgID = 0; end   
    try list = data.list; catch list = []; end
    
%     if (msgID == -inf)
%         % verify the data from init_hello_layer, just for debug.
%         disp('just for debug.');
%     end
    
    if (msgID == -2) %send backward ant, select the next hop according to list.
        try 
            data.address = list(1); %address of next hop
            data.list = list(2:length(list));
            PrintMessage(['<-', num2str(data.address')]);
        catch
            pass = 0;
        end
    elseif (msgID == -1)  %send forward ant 
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
           prob = rand * total;
           for n = RestNEIGHBORS
               ndx = find(NEIGHBORS{ID}==n);
               if (prob>0)
                   prob = prob - probability{ID}(ndx);
                   if(prob <=0)
                      data.address = NEIGHBORS{ID}(ndx); %select next hop
                      PrintMessage(['->', num2str(data.address')]);
                      %data.width = 5*probability{ID}(ndx);
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
%                total = total + probability{ID}(ndx)^dataGain;
                total = total + probability{ID}(ndx);
           end
           %total can be < 1 since power is applied
           prob = rand*total;
           for ndx = 1:length(NEIGHBORS{ID})
               if (prob>0)
%                    prob = prob - probability{ID}(ndx)^dataGain;
                   prob = prob - probability{ID}(ndx);
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
        try 
            prob = probability{ID}(nID);
            ph = pheromone{ID}(nID);
        catch
            probability{ID}(nID) = 0;
            pheromone{ID}(nID) = 1;
        end
    end
    
    if (msgID == -1) % receive forward ant
        if(DESTINATIONS(ID)) %arriving destination
            antBackward.msgID = -2; %change to backward ant
            antBackward.list = rdata.list;
                        
            %antBackward.cost = 0;
            [maxValue,minValue,avgValue] = max_min_avg_in_path(antBackward.list);
            phermone_increment = 1/(initPower - (avgValue - 1/minValue));
            %phermone_increment = exp(phermone_increment); %avoid pheromone increment too low
            antBackward.ph_increment = phermone_increment;
            
            status = iabr_layer(N, make_event(t, 'Send_Packet', ID, antBackward));
        else
            status = iabr_layer(N, make_event(t, 'Send_Packet', ID, data.data));
        end
    end
           
    if (msgID == -2) %backward ant
        pheromone{ID} =  Set_New_PH(pheromone{ID},nID,rdata.ph_increment,evaporation);
        ngh_used_energy = get_ngh_used_energy(ID);
        probability{ID} = Set_New_Prob1(pheromone{ID},ngh_used_energy);
        
%         probability{ID} = Set_New_Prob(probability{ID}, nID, rewardScale*r); %rewardScale:learning rate
        if (~SOURCES(ID))  %do not arrive source node ,continue to forward backward ant            
            status = iabr_layer(N, make_event(t, 'Send_Packet', ID, data.data));
        else %reach source node, calculate interval
%             memory.interval = memory.interval*exp(r-0.5); %adaptively set the interval
            memory.interval = memory.interval*exp(0.5); %adaptively set the interval
        end
    end
    
    if (msgID >= 0) %data packet
        if(~DESTINATIONS(ID)) %forward
            status = iabr_layer(N, make_event(t, 'Send_Packet', ID, data.data));
        end
    end
    
    if ((DESTINATIONS(ID) && msgID >= 0) || (msgID == -inf))
        %msgID == -Inf, data.type = hello_send
        pass =1;
    end
    
case 'Clock_Tick'
    try type = data.type; catch type = 'none'; end
    if (strcmp(type, 'ant_start'))
        if(isempty(pheromone{ID}))
            % pheromone initialization
            pheromone{ID} = ones(1, length(NEIGHBORS{ID}));
        end
        if (isempty(probability{ID}))
            %probability initialization
            probability{ID} = ones(1, length(NEIGHBORS{ID}))/length(NEIGHBORS{ID});
        end
        if(SOURCES(ID))
            antForward.msgID = -1;
            status = iabr_layer(N, make_event(t+4000, 'Send_Packet', ID, antForward));            
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

% writen by xinlu
% update the pheromone trail according to equation 3 in EEABR.
function new = Set_New_PH(old,idx,ph,evaporation)
if(sum(old)==0)
    old = ones(1,length(old))/length(old);
end
for i =1:length(old)
    if(i==idx)
        new(i) = evaporation * old(i) + ph;
    else
        new(i) = old(i);
    end
end

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
        ngh_energy(i) = power(NEIGHBORS{ID}(i));
%         ngh_energy{i}.id = NEIGHBORS{ID}(i);
%         ngh_energy{i}.energy=power(ngh_energy{i}.id); 
    end
    
end
out=ngh_energy;

%get the used power for neighbor list
%added by xinlu 2017/9/28
function out=get_ngh_used_energy(ID)
global NEIGHBORS
global ATTRIBUTES
if (~isempty(NEIGHBORS{ID}))
    N = length(ATTRIBUTES);
    for i=1:N
        used_power(i) = ATTRIBUTES{i}.usedPower;
    end
    
    M = length(NEIGHBORS{ID}); 
    for i=1:M
        ngh_used_energy(i) = used_power(NEIGHBORS{ID}(i));
    end
end
out = ngh_used_energy;

% get the residual energy for specific node
% added by xinlu 2017/8/2
function out=get_energy(ID)
global ATTRIBUTES
out = ATTRIBUTES{ID}.power;

% update the probability according to the ACO metaheuristic in EEABR.
% ph:----pheromone trail
% idx:----the index of node(data from)
% ngh_used_en: ----used power of neighbor
function new = Set_New_Prob1(ph,ngh_used_en)
global NEIGHBORS
global ID
alpha = 0.7;
beta = 1.0 - alpha;
for i=1:length(NEIGHBORS{ID})
    ph_trail = ph(i).^alpha;
    %visibility = 1/(initPower - current_energy) = 1/used_power
    visibility = (1/ngh_used_en(i)).^beta;
%     visibility = ngh_en(i).^bata_coefficient;
%     tmp = ph(idx).^alfa_coefficient * get_energy(NEIGHBORS{ID}(idx)).^bata_coefficient;
    tmp = ph_trail * visibility;
    tmp_2 = dot(ph.^alpha,(1./ngh_used_en).^beta);
    new(i) = tmp / tmp_2;   
end

