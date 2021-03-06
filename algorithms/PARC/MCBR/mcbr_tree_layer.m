function status = mcbr_tree_layer(N, S)

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
global LTOTALS
global RNUMBERS

persistent NQValues

persistent alpha
persistent resend
persistent delta

switch event
case 'Init_Application'
        
    if (ix==1)

        sim_params('set_app', 'Promiscuous', 1);
	
        alpha = sim_params('get_app', 'LearningRate');
        if (isempty(alpha)) alpha = 1; end
        resend = sim_params('get_app', 'ReSend');
        if (isempty(resend)) resend = 0; end
        delta = sim_params('get_app', 'ForwardDelta');
        if (isempty(delta)) delta = Inf; end
        
    end
    
    %%%%%%%%%%%%%%   Memory should be initialized here  %%%%%%%%%%%%%%%%%
    memory=struct('parent', -inf, 'cost', inf);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
    ATTRIBUTES{ID}.QValue = 0;
    NQValues{ID} = [];
    
case 'Send_Packet'
    data.QValue = ATTRIBUTES{ID}.QValue;
    try msgID = data.msgID; catch msgID = 0; end
    if (msgID < 0) data.address = 0; %broadcast for tree establish
    elseif (memory.parent>=0) 
        data.address = memory.parent;
    end
    if ((msgID >= 0) && (memory.parent<0)) %no parent to pass data
          pass = 0;
    end
case 'Packet_Received'
    try duplicated = data.duplicated; catch duplicated = 0; end
    try msgID = data.data.msgID; catch msgID = 0; end
    data.data.forward = 1;
    if (resend>0) data.data.resend = resend; end
    
    if (DESTINATIONS(ID))
        memory.parent = 0;
        memory.cost = 0;
        ATTRIBUTES{ID}.QValue = 0;
    
        if (msgID >= 0) %real data received, confirm to neighbors
            PrintMessage('b');
            status = mcbr_tree_layer(N, make_event(t, 'Send_Packet', ID, data.data));
        end  
    else               
        nID = find(NEIGHBORS{ID}==data.data.from);
        oldQValue = ATTRIBUTES{ID}.QValue;
        
        if (~isempty(nID))
           rate = LTOTALS{ID}(nID)/(LTOTALS{ID}(nID)+RNUMBERS{ID}(nID));
           if (rate==0) NQValues{ID}(nID) = data.data.QValue;
           else NQValues{ID}(nID) = rate*NQValues{ID}(nID) + (1-rate)*data.data.QValue;
           end          
           minQ = min(NQValues{ID});
           ATTRIBUTES{ID}.QValue = (1-alpha)*ATTRIBUTES{ID}.QValue+alpha*(minQ+mcbr_cost);
           id = find(NQValues{ID}==minQ);
           if ((memory.parent ~= NEIGHBORS{ID}(id(1))) && ...
                   ((memory.cost == inf) ||(memory.cost - minQ > delta)))
               if (memory.parent > 0)
                   DrawLine('delete', memory.parent, ID);
               end
               memory.parent = NEIGHBORS{ID}(id(1));
               DrawLine('Arrow', memory.parent, ID, 'color', [1 0 0]);
               memory.cost = minQ;
           end                                   
         end
         if ((msgID >= 0) && (data.data.address==ID)) %real data address to me
                PrintMessage('f');
                status = mcbr_tree_layer(N, make_event(t, 'Send_Packet', ID, data.data));
         else
              if ((abs(oldQValue - ATTRIBUTES{ID}.QValue) > delta)&&(msgID ~= -inf)) %extra control packets
                  hello.msgID = -1;        
                  status = mcbr_tree_layer(N, make_event(t, 'Send_Packet', ID, hello));
              end
         end
    end
    if (duplicated || (~DESTINATIONS(ID)&(msgID>=0)))
        pass = 0; 
    end
    
case 'Collided_Packet_Received'
    % this is for debug purposes only
    
case 'Clock_Tick'
  try type = data.type; catch type = 'none'; end
  
  if (strcmp(type, 'confirm_timeout')) 
        rdata = data.data;
        address = rdata.address;
        
        nID = find(NEIGHBORS{ID}==address);       
        LTOTALS{ID}(nID) = LTOTALS{ID}(nID) + 1;       
        NQValues{ID}(nID) = NQValues{ID}(nID)+link_cost(nID);
        
        minQ = min(NQValues{ID});
        id = find(NQValues{ID}==minQ);
        if (memory.parent>0)
            DrawLine('delete', memory.parent, ID);
        end
        memory.parent = NEIGHBORS{ID}(id(1));
        DrawLine('Arrow', memory.parent, ID, 'color', [1 0 0]);
        memory.cost = minQ;
        ATTRIBUTES{ID}.QValue = (1-alpha)*ATTRIBUTES{ID}.QValue+alpha*(minQ+mcbr_cost);
        try 
            if (data.data.resend>0)
                data.data.forward = 1;
                data.data.resend = data.data.resend - 1;
                mcbr_tree_layer(N, make_event(t, 'Send_Packet', ID, data.data));
            end            
        end 
        pass = 0;
  end

case 'GuiInfoRequest'
    if ~isempty(memory)
        disp(sprintf('Memory Dump of mote ID# %d:\n',ID)); disp(memory)
    else
        disp(sprintf('No memory dump available for node %d.\n',ID)); 
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