%NOTE: Make sure to add oopsi to path
% predSpk = inferSpk(dFF,fps,bias,bias)
%dFF: trace
%fps: frame rate
%bias: bias value (usually between 0.1 and 1)
%verbose: set to "1" if you want to see some plots


function predSpk = inferSpk(dFF,fps,bias,verbose)

if nargin<3
    bias = 0.5;
    verbose = 0;
end

predSpk = ones(length(dFF),1);
%extract some spikes
% set simulation metadata

V.dt    = 1/fps;  % time step size
% initialize params
P.a     = 1;    % observation scale
P.b     = bias; % observation bias
tau     = 1;    % decay time constant
P.gam   = 1-V.dt/tau; % C(t) = gam*C(t-1)
P.lam   = 1/(1/fps);  % firing rate = lam/dt
P.sig   = 0.1;  % standard deviation of observation noise
[Nhat Phat] = fast_oopsi(dFF,V,P);
predSpk = Nhat;
if verbose
    figure(1)
    plot(1:length(F),F,'b',1:length(F),Nhat);
end
end