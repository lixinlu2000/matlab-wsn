function testplots

lists={'ant_routing','accr_original'};
%lists={'ant-basic','mcbr_ant','mcbr_flood_ant','mcbr_smart_ant'};


num_node(1) = 49;
testlists{1} = lists;

metricsY = {'delays','throughput','succrate','energy','efficiency','lifetime','energy_var','overhead'};
testsTime = {10};

% resultdir=  'results/results_original';
resultdir = 'results/results1005';

for i=1:1
    for j=1:size(metricsY,2)
        getplots_ant('time', metricsY{j}, testsTime{i}, resultdir, testlists{i},resultdir,strcat(resultdir,'/',metricsY{j}),num_node(i));
    end
end