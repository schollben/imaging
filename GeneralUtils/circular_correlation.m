% circular_correlation
% Batschelet, E. (1981). Circular Statistics in Biology (Academic Press).
%
% for matched (paired) measurements
% includes boot-strapped standard error
%
% args: ang1, ang2 (in degrees)

function [r,err] = circular_correlation(ang1,ang2)

ang1 = ang1.*(pi/180);
ang2 = ang2.*(pi/180);
theta = ang1 - ang2;

c = sum(cos(theta)).^2;
s = sum(sin(theta)).^2;
r = (1/length(theta))*sqrt(c + s);

iter = 1e3;
corrs = zeros(iter,1);
for ii = 1:iter
    ind = randi(length(theta),length(theta),1);
    c = sum(cos(theta(ind))).^2;
    s = sum(sin(theta(ind))).^2;
    corrs(ii) = (1/length(theta))*sqrt(c + s);
end
err = std(corrs);