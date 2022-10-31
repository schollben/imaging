%clear, clc,

% set simulation metadata
T       = length(F); % # of time steps
V.dt    = 1/(7.5);  % time step size

% initialize params
P.a     = 1;    % observation scale
P.b     = 0.5;    % observation bias
tau     = 1;    % decay time constant
P.gam   = 1-V.dt/tau; % C(t) = gam*C(t-1)
P.lam   = 0.1;  % firing rate = lam/dt
P.sig   = 0.1;  % standard deviation of observation noise 

% fast oopsi
F(isnan(F)) = nanmean(F);
[Nhat Phat] = fast_oopsi(F,V,P);

% % smc-oopsi
% V.smc_iter_max = 1;
% [M P V] = smc_oopsi(F,V,P);

%%plot results
figure(1), clf
tvec=0:V.dt:(T-1)*V.dt;
plot(tvec,F); axis('tight'), ylabel('F (au)')
hold on, plot(tvec,Nhat,'r','linewidth',1), axis('tight'), ylabel('fast')
