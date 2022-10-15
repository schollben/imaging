function [p_CA,stats]=cochran_arm(x,w)
%COCHRAN_ARM Cochran-Armitage chi-square test for trend in proportions
%   [p_CA,stats]=cochran_arm(x,w)
%   x - n-by-2 counts matrix
%   w - n-by-1 matrix of weights (optional, 1:n by deafult)
%   p_CA - p-value for the main hypothesis
%   stats - structure with overall and Cochran-Armitage chi^2 values, and p
%       values for the test itself (same as p_CA) and for the deviation
%       forom linear trend
%
% The formulas were taken from the books mentioned below and tested on the
% examples from these books, also shown below.
%
% Agresti, Categorical Data Analysis, 2nd ed, pp. 179-182
% x=[ 48  17066;  38  14464;  5  788;  1  126;  1  37 ];
% w=[0 0.5 1.5 4 7];
% 
% Armitage, Berry, Matthews, Statistical Methods in Medical Research, 
% 4th ed, pp. 504-506 
% x=[ 59 97; 10 31; 12 36; 5 28]; w=[0 1 2 3];

%% deal with inputs
% check sizes ond orientation of x and w
if nargin<1, error('cochran_arm: Not enough arguments'), end

if size(x,2)~=2, x=x'; end;
if size(x,2)~=2 || size(x,1)<2
    error('cochran_arm: Data must be n x 2')
end

% default: linear weights
if nargin<2, w=1:size(x,1); end

if ~isvector(w)
    error('cochran_arm: Weights matrix must be a vector')
end
if size(w,2)~=1, w=w'; end;
if length(w)~=size(x,1)
    error('cochran_arm: Sizes of weight matrix and data matrix are incompatible')
end

%% computation
n=sum(x,2); N=sum(n);
p=x(:,1)./n;
pp=sum(x(:,1))/N;
R=sum(x(:,1));

%overall chi^2
x2=1/(pp*(1-pp)) * sum(n.*(p-pp).^2);

%Cochran_armitage chi^2 (aka z^2)
x2_1_numer=N*(N*sum(x(:,1).*w)-R*sum(n.*w))^2;
x2_1_denom=R*(N-R)*(N*sum(n.*w.*w)-(sum(n.*w))^2);
x2_1=x2_1_numer/x2_1_denom;

p_CA=1-chi2cdf(x2_1,1);
p_fit=1-chi2cdf(x2-x2_1,size(x,1)-2);

%% output
stats.overall_chi2=x2;
stats.cochran_arm_chi2=x2_1;
stats.cochran_arm_p=p_CA;
stats.deviation_from_linear_p=p_fit;