function status = accr_acs_layer(N, S)

% This implementation is disigned for variant of original ACCR protocol
% The main improvement of this variant include:
% 1. use ACS algorithm instead of AS in route discovery;
% 2. improve the global pheromone value update;
% 3. adopt the expected energy cost as heuristic vlaue.
% 

% Written by Xinlu, xinlu.li@mydit.ie 09/10/2017
% Last modified: 31/10/2017 by xinlu 

%* Copyright (C) 2003 PARC Inc.  All Rights Reserved.
% Define variables:
% antInterval:       --time interval of ant agent;
% antStart:          --start time, default value is 3 second;
% sourceRate:        --data generation rate in source node, default value =0.1 10 sec 1 msg
% antRatio:
% dataGain:          --the data ants are prevented from choosing links with very low
% probability:
% DESTINATIONS: 
% SOURCES:


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
global Control_Sent_Count

persistent antInterval
persistent antStart
persistent probability
persistent probGain
persistent initPower
persistent pheromone
persistent evaporation
persistent heuristic
persistent s_index
persistent statistics
persistent alpha
persistent beta
persistent exploitation

switch event
case 'Init_Application'  % Initilize Application Event
    if (ix==1)
        sim_params('set_app', 'Promiscuous', 0);
        antStart = sim_params('get_app', 'AntStart');
        if (isempty(antStart)) 
            antStart = 120000;  %120000/40000 = 3 sec
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
        Control_Sent_Count = 0;
        probGain = sim_params('get_app', 'ProbGain');
        if (isempty(probGain)) probGain = 1.2; end
        exploitation = 0.5;
        evaporation = 0.5;
        alpha = 1;
        beta = 2;
    end
    probability{ID} = [];
    pheromone{ID} = [];
    heuristic{ID} = [];
    
    s_index{ID} = struct('ant_id',1,'sdx_id',1);
    statistics{ID} = struct('generate',ID,'destination',0,'ant_id',0,'hops',0,'avgValue',0,'minValue',0,'maxValue',0,'ph_increment',0); %store the statistics information for each node

    initPower = sim_params('get_app','InitPower');
%     evaporation = 0.5;
%     alpha = 1;
%     beta = 2;
    
%     memory = struct('average', 0, 'variance', 0, 'window', [], 'potentials', [], 'interval', antInterval); 
    memory = struct('potentials', [], 'interval', antInterval);
    %memory.potentials(nID) denote the the minimum cost to destination
    %through de node nID.
   
    Set_Start_Clock(antStart); %start forward ant 
    
case 'Send_Packet' % Send packet Command, that means the data will flow down to the support layer, if pass = 1;
    
    try msgID = data.msgID; catch 
        msgID = 0; end   
    try list = data.list; catch
        list = [];  end
    
    if(msgID < 0 )  %count the number of control packet, including hello message, init_backward message, forward and backward ant agents.
        Control_Sent_Count = Control_Sent_Count + 1;
    end
    
    if (msgID == -inf) % send packet, which come from conrol layer(i.e. init_backward layer or init_hello layer)
        if (isempty(memory.potentials) || DESTINATIONS(ID))
            data.cost = mcbr_dest; %mcbr_dest is function, default value is zero.
        else
            data.cost = mcbr_cost + min(memory.potentials); %mcbr_cost is function, default value is one.
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
    end
    if (msgID == -1)  % send forward ant 
        data.list = [ID, list]; %add the node ID into the visited list.
        dest_ID = find(DESTINATIONS);  
        % if the destination is the direct node, enforce the destination as
        % next hop according to intuition.
        if((ismember(dest_ID,NEIGHBORS{ID}))||(ismember(ID,NEIGHBORS{dest_ID})))
            data.address = find(DESTINATIONS);
        else
           RestNEIGHBORS = setdiff(NEIGHBORS{ID}, data.list);
           if (isempty(RestNEIGHBORS)) RestNEIGHBORS = NEIGHBORS{ID}; end
           total = 0;
           for n = RestNEIGHBORS
               ndx = find(NEIGHBORS{ID}==n);
               total = total + probability{ID}(ndx);
           end
           %total can be < 1 since only a fraction of the neighbors
           prob = rand*total;
           if (prob <= exploitation) %exploitation
               % exploit route according to the acs route discovery rule.
               max_prob = 0;
               max_index = 0;
               for n = RestNEIGHBORS
                   ndx = find(NEIGHBORS{ID}==n);
                   if max_prob < probability{ID}(ndx)
                       max_prob = probability{ID}(ndx);
                       max_index = ndx;
                   end
               end
               data.address = NEIGHBORS{ID}(max_index);
           else %exploration
                for n = RestNEIGHBORS
                    ndx = find(NEIGHBORS{ID}==n);
                    if (prob>0)
                       prob = prob - probability{ID}(ndx);
                       if(prob <=0)
                          data.address = NEIGHBORS{ID}(ndx);
                          PrintMessage(['->', num2str(data.address')]);
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
                end %end for
           end

        end
    end
    if (msgID >= 0) % send data packet      
       try
           %select the next hop accoding to probability
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
        
case 'Packet_Received' % Packet_Received Event, that means the data flow up to control layer until the app layer, if pass = 1; 
    rdata = data.data;
    try msgID = rdata.msgID; catch msgID = 0; end
    try list = rdata.list; catch list = []; end
    nID = find(NEIGHBORS{ID}==rdata.from);
    
    data.data.forward = 1;
    
    pass=0;
    
    if (msgID ~= -inf) %FANT, BANT, data packet
        try 
            prob = probability{ID}(nID);
            ph = pheromone{ID}(nID);
            he = heuristic{ID}(nID);
        catch
            probability{ID}(nID) = 1./length(NEIGHBORS{ID});
            pheromone{ID}(nID) = 1./length(NEIGHBORS{ID});
            heuristic{ID}(nID) = 1./length(NEIGHBORS{ID});
        end
    else  % receive init backward packet
        memory.potentials(nID) = rdata.cost; 
        % update local heuristic value 
        tem_heuristic = 1./(1 + memory.potentials);
        heuristic{ID}(:,1:length(tem_heuristic)) = tem_heuristic;
        heuristic{ID}=normalization(heuristic{ID});
    end
    
    if (msgID == -1) %receive forward ant
        if(DESTINATIONS(ID)) %arriving destination
            antBackward.msgID = -2; %change to backward ant
            antBackward.list = rdata.list;
            antBackward.generate = rdata.generate;
            [maxValue,minValue,avgValue] = max_min_avg_in_path(antBackward.list);
            fant_length = length(antBackward.list);
            phermone_increment = (minValue * avgValue)/(initPower * initPower * fant_length);
            antBackward.ant_id = rdata.ant_id;
            
            %when FANT reach the destination, update the statistics for ant generated node
            sdx = s_index{rdata.generate}.sdx_id;
            statistics{rdata.generate}(sdx).ant_id = rdata.ant_id;
            statistics{rdata.generate}(sdx).generate = rdata.generate;
            statistics{rdata.generate}(sdx).destination = ID;
            statistics{rdata.generate}(sdx).hops = length(rdata.list);
            statistics{rdata.generate}(sdx).maxValue = maxValue;
            statistics{rdata.generate}(sdx).minValue = minValue;
            statistics{rdata.generate}(sdx).avgValue = avgValue;
            statistics{rdata.generate}(sdx).ph_increment = phermone_increment;
            
            s_index{rdata.generate}.sdx_id = s_index{rdata.generate}.sdx_id + 1;
            
%             antBackward.cost = 0;
            status = accr_acs_layer(N, make_event(t, 'Send_Packet', ID, antBackward));
        else
            status = accr_acs_layer(N, make_event(t, 'Send_Packet', ID, data.data));
        end
    end
           
    if (msgID == -2) %receive backward ant
        
        tmp_ant_id = rdata.ant_id;
        tmp_statistics = statistics{rdata.generate};
       
        path_length = tmp_statistics([tmp_statistics.ant_id] == tmp_ant_id).hops;
        tmp_list = 1:path_length;
        tmp_sum = sum(tmp_list);
        
        tmp_pheromone = tmp_statistics([tmp_statistics.ant_id] == tmp_ant_id).ph_increment;
        
        ph_pheromone = tmp_pheromone * (length(rdata.list) + 1) / tmp_sum;
        
        pheromone{ID} =  Set_New_PH(pheromone{ID},nID,ph_pheromone,evaporation);

        %updata heuristic value
        %TODO:
        %heuristic value update depend on the estimation from destination.
        %we simply use the reciprocal of the potentials.
%         tem_heuristic = 1./(1 + memory.potentials);
%         heuristic{ID}(:,1:length(tem_heuristic)) = tem_heuristic;
%         heuristic{ID} = 1./(1 + memory.potentials);
%         avg_Value = tmp_statistics([tmp_statistics.ant_id] == tmp_ant_id).avgValue;
%         heuristic{ID} = Set_New_HE(initPower,avg_Value);
        %  normalized heruistic value to (0,1)
%         heuristic{ID}=normalization(heuristic{ID});
        
        probability{ID} = Set_New_Prob2(pheromone{ID},heuristic{ID},alpha,beta);

%         
%         data.data.cost = rdata.cost + mcbr_cost;
%         if (isempty(memory.window))
%             memory.average = data.data.cost;
%             memory.window = [data.data.cost];
%         else
%             memory.average = memory.average + eta*(data.data.cost - memory.average);
%             memory.variance = memory.variance +eta*((data.data.cost - memory.average)^2-memory.variance);
%             memory.window = [data.data.cost, memory.window];
%             memory.window = memory.window(1:min(windowSize, length(memory.window)));
%         end
%         
%         Iinf = min(memory.window);
%         Isup = memory.average + z*sqrt(memory.variance/windowSize);
%         r = c1*Iinf/data.data.cost;
%         tmp = (Isup-Iinf) + (data.data.cost-Iinf);
%         if (tmp>0)
%             r = r + c2*(Isup-Iinf)/tmp;
%         end
%         probability{ID} = Set_New_Prob(probability{ID}, nID, rewardScale*r);
%         if (~SOURCES(ID))  
        if(rdata.generate ~= ID)
            status = accr_acs_layer(N, make_event(t, 'Send_Packet', ID, data.data));
        else
%             memory.interval = memory.interval*exp(r-0.5); %adaptively set the interval
            memory.interval = memory.interval*exp(0.5);
        end
    end
    
%     if ((msgID >= 0) && (data.data.address == ID)) % receive data packet
%         if(~DESTINATIONS(ID))
%             status = accr_acs_layer(N, make_event(t, 'Send_Packet', ID, data.data));
%         else % use for confirmation only
%             data.data.address = 0;
%             status = common_layer(N, make_event(t, 'Send_Packet', ID, data.data));
%         end
%     end
    
    if (msgID >= 0) %data packet
        if(~DESTINATIONS(ID)) %forward
            status = accr_acs_layer(N, make_event(t, 'Send_Packet', ID, data.data));
        end
        
    end
    
    if ((DESTINATIONS(ID) && msgID >= 0) || (msgID == -inf))
        pass =1;
    end
    
case 'Clock_Tick' % Clock Tick Event
    try type = data.type; catch type = 'none'; end
    if (strcmp(type, 'ant_start'))
        if(isempty(pheromone{ID}))
            % pheromone initialization
            pheromone{ID} = ones(1, length(NEIGHBORS{ID}))/length(NEIGHBORS{ID});
        end
        if(isempty(heuristic{ID}))
            % heuristic initialization
            heuristic{ID} = ones(1, length(NEIGHBORS{ID}))/length(NEIGHBORS{ID});
        end
        if (isempty(probability{ID})) 
            % Initialize the probability distribution according to both
            % local cost(mcbcr_cost) and estiamting
            % cost(memory.potentials), whcich is different with other
            % algorithms.
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
            antForward.generate = ID;
            antForward.ant_id = s_index{ID}.ant_id;
            s_index{ID}.ant_id = s_index{ID}.ant_id + 1;
            status = accr_acs_layer(N, make_event(t+4000, 'Send_Packet', ID, antForward));             
        end
        Set_Start_Clock(t+memory.interval);
        pass =0;
    end
    if (strcmp(type, 'confirm_timeout')) %if confirm_transmit_layer is included
        rdata = data.data;
        address = rdata.address;
        nID = find(NEIGHBORS{ID}==address);
        %reduce probablity of that link at least
%         probability{ID} = Set_New_Prob(probability{ID}, nID, -rewardScale/2);
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

function b=Set_Start_Clock(alarm_time)
global ID
clock.type = 'ant_start';
prowler('InsertEvents2Q', make_event(alarm_time, 'Clock_Tick', ID, clock));

% writen by xinlu 
% update pheromone trail
% last modified by xinlu 11/10/2017
function new = Set_New_PH(old,idx,ph,evaporation)
% if(sum(old)==0)
%     old = ones(1,length(old))/length(old);
% end
for i =1:length(old)
    if(i==idx)
        new(i) = (1-evaporation) * old(i) + evaporation * ph; %positive reinforcement + evaporation
    else
        new(i) = (1-evaporation) * old(i); %decrease by evaporation
    end
end

% wirten by xinlu 2017/10/02
% update the heuristic value
function new = Set_New_HE(initPower,avg_Value)
global NEIGHBORS
global ID
M = length(NEIGHBORS{ID});
for i=1:M
    new(i) = (initPower - avg_Value)/(initPower - get_energy(NEIGHBORS{ID}(i)));
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

function new = Set_New_Prob2(ph,he,alpha,beta)
global NEIGHBORS
global ID
% alpha = 5;
% beta = 1;
for i=1:length(NEIGHBORS{ID})
    ph_trail = ph(i).^alpha;
    visibility = he(i).^beta;
    tmp = ph_trail * visibility;
    tmp2 = dot(ph.^alpha,he.^beta);
    new(i) = tmp / tmp2;
end
