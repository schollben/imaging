

function plotcyc(ce,cycn)
clf
for cc=1:length(ce)
    cyc = ce(cc).cyc;
    [~,nt,nl] = size(cyc);
    inds = [1:nt];
    for ii = cycn
        xt = (1:nl) + (10+nl)*(ii-1);

        x = (ones(length(inds),1)*xt);
        y = nanmean(squeeze(cyc(ii,:,:)),1) - 0.5*(cc-1);
        errBar = nanstd(squeeze(cyc(ii,:,:)),1)./sqrt(nt);
        shadedErrorBar(xt,y,errBar,'k')
        hold on
    end
end
