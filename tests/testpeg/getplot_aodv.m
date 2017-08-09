function getplot_aodv
succrate = load('./result_aodv-75s/result.txt');
speeds = 0:0.02:0.2;
h=figure;
plot(speeds,succrate,'-rs','LineWidth',2);
title('PEG Test:  Success Rate vs. Taget Speed'), 
xlabel('Speed (GridWidth/s)')
ylabel('Success Rate (%)');
saveas(h,'./result_aodv-75s/aodv.fig');
