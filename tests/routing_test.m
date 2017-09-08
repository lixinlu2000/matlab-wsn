function [latency, throughput, lossrate, succrate, energy, energy_var, packet_sent,control_packet] = routing_test(varargin)

% 输入参数：
%   Max_Sim_Time     --最大的模拟时间，默认单位为second
%   Number_of_Runs   --运行的次数
%   Time_Interval    --时间间隔
% 输出结果：
%   用于性能统计的metrics:latency, throughput, lossrate, succrate, energy,
%   energy_var, packet_sent.

% Copyright (C) 2003 PARC Inc.  All Rights Reserved.

% Written by Lukas D. Kuhn, lukas.kuhn@parc.com
% Last modified: Dec. 22, 2003  by YZ

global LATENCY THROUGHPUT LOSSRATE SUCCRATE ENERGY ENERGY_VAR PACKET_SENT CONTROL_PACKET

Max_Sim_Time = varargin{1};
Number_of_Runs = varargin{2};
if (length(varargin)>2)
    Time_Interval = varargin{3};
else
    Time_Interval = 1;
end

sim_params('set_app', 'LogInterval', Time_Interval);
sim_params('set', 'STOP_SIM_TIME', Max_Sim_Time*40000);     %40000 = 1 second

for (inum=1:Number_of_Runs)
    prowler('Init');
    disp(['In routing_test:Current Run: ' num2str(inum)])
    prowler('StartSimulation');
    
    if (inum==1)
        latency = LATENCY;
        throughput = THROUGHPUT;
        lossrate = LOSSRATE;
        energy = ENERGY;
        energy_var = ENERGY_VAR;
        packet_sent = PACKET_SENT;
        control_packet = CONTROL_PACKET;
        succrate = SUCCRATE;
    else
        latency = (latency*(inum-1)+LATENCY)/inum;
        throughput = (throughput*(inum-1)+THROUGHPUT)/inum;
        lossrate = (lossrate*(inum-1)+LOSSRATE)/inum;
        energy = (energy*(inum-1)+ENERGY)/inum;
        energy_var = (energy_var*(inum-1)+ENERGY_VAR)/inum;
        packet_sent = (packet_sent*(inum-1)+PACKET_SENT)/inum;
        control_packet = (control_packet*(inum-1)+CONTROL_PACKET)/inum;
        succrate = (succrate*(inum-1)+SUCCRATE)/inum;
    end    
end


