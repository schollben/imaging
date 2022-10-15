


function [barsxl,respfit,params] = fitSpatialRF(nbars,resp,pref)

opt = optimset;
opt.Display = 'off';
startvals = [.5    5     .25    0];
ub =        [ 1  nbars    5     .5];
lb =        [ 0    1      0  -.5];


if nargin==3
    startvals(2) = pref;
    ub(2) = pref+3;
    lb(2) = pref-3;
end
[params,~,~,~,~,~,~] = lsqcurvefit('fitguassSINGLE',startvals,1:nbars,resp',lb,ub,opt);

barsxl = 1:.01:nbars;
respfit = fitguassSINGLE(params, barsxl);

