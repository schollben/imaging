

function [stat] = jregress(x, y, m1, slopefit)
% myregress.m
%
% purpose: regression statistics
%   usage: [m b r2 pm pb] = jregress(x, y, m1)
%          x = column vector of independent variable
%          y = column vector of dependent variable
%          m1 = slope to check difference of
%          m = slope of regression line
%          b = y-intercept
%          r2 = coefficient of determination
%          pm = p-value for slope
%          pb = p-value for y-intercept
%      by:  justin gardner
%    date:  9/3/98

if (nargin <2)
  help jregress, return,
elseif (nargin <3)
  m1 = 0;
end

n = length(x);

% precalculate sum terms
sumx = sum(x);
sumy = sum(y);
sumx2 = sum(x.^2);
sumy2 = sum(y.^2);
sumxy = sum(x.*y);

% use formulas to calculate slope and y-intercept
m = (n*sumxy-sumx*sumy)/(n*sumx2-sumx^2);
b = (sumy*sumx2 - sumx*sumxy)/(n*sumx2 - sumx^2);


% find least squares fit for a line of the form y = m*x + b
%A = x;
%A(:,2) = 1;
%coef = ((A'*A)^-1)*A'*y;
%m = coef(1);
%b = coef(2);

% calculate r^2
num = ((m*x + b) - y).^2;
denom = (y-mean(y)).^2;
r2 = 1 - (sum(num)/sum(denom));

if exist('slopefit')
m=slopefit;
b=0;
yfit= x.*m+b;
a=corr([y',yfit']).^2;
disp('Comparing data with slope was 1')
r2=a(1,2)
end

sum(num)
sum(denom)
% calculate standard error of the estimate
Sx = std(x);
Sy = std(y);
%Syx = sqrt(((n-1)/(n-2))*(Sy^2-(m^2)*Sx^2));
Syx = sqrt(((n-1)/(n-2))*(1-r2)*(Sy^2));

% calculate standard error of the slope
Sm = (1/sqrt(n-1))*(Syx/Sx);

% calculate standard error of the y-intercept
Sb = Syx * sqrt((1/n) + (mean(x)^2)/((n-1)*Sx^2));

if (n <= 2), pm = -1;, pb = -1;, return;, end;

% calculate t-statistic and p-value for slope
% note, use incomplete beta function because
% matlab's tpdf function gives strange results.
Tm = (m-m1)/Sm;
pm = betainc((n-2)/((n-2)+Tm^2),(n-2)/2,.5);

% calculate t-statistic and p-value for y-intercept
Tb = b/Sb;
pb = betainc((n-2)/((n-2)+Tb^2),(n-2)/2,.5);

stat.m=m;
stat.b=b;
stat.r2=r2;
stat.pm=pm;
stat.pb=pb;

