% function genplot
% args: [gens,spk,bins]


function [newvs] = genplot(gens,spk,bins)

vv = zeros(length(gens),2);
vv(:,2) = spk;
vv(:,1) = gens;
minv = min(vv(:,1));

maxv = max(vv(:,1));
vvs = vv;
newvs = [];  

for j = bins
    
 inds = find(vvs(:,1)<=j); 

 if length(inds)<2
     mspk = nan;
     vspk = nan;
 else
     mspk = nanmean(vvs(inds,2));
     vspk = nanstd(vvs(inds,2))./sqrt(length(inds));%standard error
 end
 
 newvs = [newvs; j mspk vspk]; %mspk is mean spike rate, vpsk is standard error
 vvs(inds,:) = [];
 
end
