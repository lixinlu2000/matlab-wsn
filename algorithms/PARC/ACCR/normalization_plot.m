function normal = normalization_plot(x)
[m,n] = size(x);
normal = zeros(m,n);
%normalize the data x to [0,1]
for i=1:m
    ma = max(x(i,:));
    mi = min(x(i,:));
    normal(i,:) = (x(i,:) - mi)./(ma-mi);
end