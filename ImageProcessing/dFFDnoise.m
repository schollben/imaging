%alpha = 0.05; %use for 7.5Hz sampled data
% alpha = 0.20; %use for 30Hz sampled data

function [d2FF] = dFFDnoise(dFF,alpha)
if nargin==1
    alpha = 0.1;
end
d2FF = zeros(size(dFF));
n_rois = size(dFF,2);
for i = 1:n_rois
    d2FF(:,i) = filter(alpha, [1 alpha-1],dFF(:,i));
end