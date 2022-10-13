

function plotcyc(ce,cycn)

for cc=1:length(ce)
    cyc = ce(cc).cyc;
    [~,nt,nl] = size(cyc);
    inds = [1:nt];
    for ii = cycn
        xt = (1:nl) + (5+nl)*(ii-1);
        if ii==1
            hold off
        end
        x = (ones(length(inds),1)*xt);
        y = nanmean(squeeze(cyc(ii,:,:)),1);
        errBar = nanstd(squeeze(cyc(ii,:,:)),1)./sqrt(nt);
        shadedErrorBar(xt,y,errBar,'k')
        hold on
    end
    
%     ylim([-.1 1])
end
