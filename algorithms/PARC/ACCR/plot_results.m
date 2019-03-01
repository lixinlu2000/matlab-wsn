function plot_results
clear;
list={'accr_acs','accr_mcbr','accr_original','eeabr','mcbr_ant'};
resultdir = 'results/results1031';
num_node = 49;          %the number of node in networks.
node_Interval = 10;     %the point number in x-coordinate;
%simulation_time = 300;  %simulation time
%log_Interval = 10;      %log interval
metrics = {'Latency','Throughput','Success Rate','Energy Consumption','Energy Efficiency','Lifetime Prediction','Energy Standard Deviation','Control Overhead'};
% delays;throughput;lossrate;succrate;energy;energy_var;sent;control
symbols = {'bo-', 'gx-', 'r+:', 'c*-.', 'ms--', 'ys-','ks-','bs-','r*--','gd-'};

for i=1:length(list)
    res = load(strcat(resultdir,'/',list{i},'.txt'));
%     res = res(1:simulation_time/log_Interval,:);  %collect the 0-simulation_time/log_Interval records.
    n = 1:floor(size(res,1)/node_Interval):size(res,1);
    res_pre = res(n,:);
    time(:,i) = res_pre(:,1);
    latency(:, i) = res_pre(:,2);
    throughput(:, i) = res_pre(:,3);
    lossrate(:,i) = res_pre(:,4);
    succrate(:,i) = res_pre(:,5);
    energy(:,i) = res_pre(:,6);
    energy_var(:,i) = res_pre(:,7);
    sent(:,i) = res_pre(:,8);
    control(:,i) = res_pre(:,9);
    lifetime(:, i) = 2000 - (energy(:, i) ./ num_node + sqrt(energy_var(:, i)));
    received(:, i) = succrate(:, i) .* sent(:, i);
    efficiency(:, i) = received(:, i) ./ energy(:, i);
end

%% efficiency,energy_var,lifetime,control need to be
% normalized.
% energy,throughput,succrate
control = control./(control + sent);
% energy_var = normalization_plot(energy_var);
lifetime = lifetime ./20;

%% plot the latency
% h = figure;
% for i=1:length(list)
%     x = time(1:size(time,1),i);
%     y = latency(1:size(latency,1),i);
%     plot(x,y,symbols{i});
%     hold on;
% end
% title('Latency');
% xlabel('Simulation Time(s)');
% ylabel('Latency');
% 
% % legend(list{1},list{2},list{3});
% legend('accr\_acs','accr\_mcbr','accr\_original','eeabr','mcbr\_ant');
% figurename=[resultdir,'/latency.fig'];
% saveas(h,figurename);

%% plot the Throughput
h = figure;
for i=1:length(list)
    x = time(1:size(time,1),i);
    y = throughput(1:size(throughput,1),i);
    plot(x,y,symbols{i});
    hold on;
end
title('Throughput');
xlabel('Simulation Time(s)');
ylabel('Throughput');

% legend(list{1},list{2},list{3});
legend('accr\_acs','accr\_mcbr','accr\_original','eeabr','mcbr\_ant');
figurename=[resultdir,'/throughput.fig'];
%saveas(h,figurename);

%% plot the Success Rate
h = figure;
for i=1:length(list)
    x = time(1:size(time,1),i);
    y = succrate(1:size(succrate,1),i);
    plot(x,y,symbols{i});
    hold on;
end
% title('Success Rate');
xlabel('Simulation Time(s)');
ylabel('Success Rate(%)');
axis([-inf,inf,0,0.8]);
% legend(list{1},list{2},list{3});
legend('accr\_acs','accr\_mcbr','accr\_original','eeabr','mcbr\_ant');
figurename=[resultdir,'/succrate.fig'];
%saveas(h,figurename);

%% plot the Energy Consumption
h = figure;
for i=1:length(list)
    x = time(1:size(time,1),i);
    y = energy(1:size(energy,1),i);
    plot(x,y,symbols{i});
    hold on;
end
% title('Energy Consumption');
xlabel('Simulation Time(s)');
ylabel('Energy Consumption(J)');

legend('accr\_acs','accr\_mcbr','accr\_original','eeabr','mcbr\_ant');
figurename=[resultdir,'/energy.fig'];
%saveas(h,figurename);

%% plot the Energy Efficiency
h = figure;
for i=1:length(list)
    x = time(1:size(time,1),i);
    y = efficiency(1:size(efficiency,1),i);
    plot(x,y,symbols{i});
    hold on;
end
% title('Energy Efficiency');
xlabel('Simulation Time(s)');
ylabel('Energy Efficiency');
axis([-inf,inf,0,7.0]);

legend('accr\_acs','accr\_mcbr','accr\_original','eeabr','mcbr\_ant');
figurename=[resultdir,'/efficiency.fig'];
%saveas(h,figurename);

%% plot the Lifetime Prediction
h = figure;
for i=1:length(list)
    x = time(1:size(time,1),i);
    y = lifetime(1:size(lifetime,1),i);
    plot(x,y,symbols{i});
    hold on;
end
% title('Lifetime Prediction');
xlabel('Simulation Time(s)');
ylabel('Lifetime Prediction(%)');

legend('accr\_acs','accr\_mcbr','accr\_original','eeabr','mcbr\_ant');
figurename=[resultdir,'/lifetime.fig'];
saveas(h,figurename);

%% plot the Energy Standard Deviation
h = figure;
for i=1:length(list)
    x = time(1:size(time,1),i);
    y = energy_var(1:size(energy_var,1),i);
    plot(x,y,symbols{i});
    hold on;
end
% title('Energy Standard Deviation');
xlabel('Simulation Time(s)');
ylabel('Energy Standard Deviation');

legend('accr\_acs','accr\_mcbr','accr\_original','eeabr','mcbr\_ant');
figurename=[resultdir,'/energy_var.fig'];
saveas(h,figurename);

%% plot the Control Overhead
h = figure;
for i=1:length(list)
    x = time(1:size(time,1),i);
    y = control(1:size(control,1),i);
    plot(x,y,symbols{i});
    hold on;
end
% title('Control Packet Overhead');
xlabel('Simulation Time(s)');
ylabel('Control Packet Overhead');

legend('accr\_acs','accr\_mcbr','accr\_original','eeabr','mcbr\_ant');
figurename=[resultdir,'/control.fig'];
saveas(h,figurename);