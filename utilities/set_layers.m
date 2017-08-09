function set_layers(names)

%
% Function set_layers set the layer in application parameter according to
% the arguments
% Steps1: set all layers to be 0;
% Steps2: set specified layers to be 1;
%

% Written by Ying Zhang yzhang@parc.com

all_layers = all_app_layers;
for i=1:length(all_layers)
    sim_params('set_app', all_layers{i}, 0);
end

for i=1:length(names)
    sim_params('set_app', names{i}, 1);
end