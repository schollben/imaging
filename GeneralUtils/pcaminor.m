% PCA
% RR Sokal & FJ Rohlf 3rd ed. (1995)
% give major axis vector
% ex: [m,b,L1,L2] = pca(x,y,showplot)

function [m,b,L1,L2] = pcaminor(x,y,showplot)

if nargin<3
showplot=1;
end

if showplot
close all
figure
plot(x,y,'.')  
end

%correlation
s1 = sum((y - mean(y)).^2) / (length(x) - 1);
s2 = sum((x - mean(x)).^2) / (length(x) - 1);

%covariance
s12 = sum( (x - mean(x)) .* (y - mean(y)) ) / (length(x) - 1);

%diag frommatrix
D = sqrt((s1 + s2)^2 - 4*(s1 * s2 - (s12)^2));

%eigen values
e1 = (s1 + s2 + D) / 2;
e2 = (s1 + s2 - D) / 2;

%principle slope
b1 = s12 / (e1 - s1);
%minor slope
b2 = -1 / b1; 

if showplot
%equation of these lines
hold on
plot(x,mean(y) + b1.*(x - mean(x)),'r')
plot(x,mean(y) - b2.*(x - mean(x)),'g')
end

%95% C.I. bounds on major axis slope for ellipticals
F =4.96;
H = F / ((e1/e2 + e2/e1 -2 )*(length(x) - 2));
A = sqrt(H / (1-H));
L1 = (b1 - A) / (1 + b1*A);
L2 = (b1 + A) / (1 - b1*A);

%%%%%
m = -b2;
b = mean(y) - m*mean(x);

num = ((m*x + b) - y).^2;
denom = (y-mean(y)).^2;
r2 = 1 - (sum(num)/sum(denom));


