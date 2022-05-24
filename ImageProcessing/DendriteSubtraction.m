% dendritic subtraction
%
% flag = 1 - use the dff traces for robust fit
% flag = 2 - use the stimulus driven activity periods ('cyc')
function [] = DendriteSubtraction(flag)

global ce

isDendrite = [ce.dendrite];

%is dendrite ROI before or after spine ROIs?
if isDendrite(1)==1
    dendcnt = 0;
else
    dendcnt = 1;
end

for cc = 1:length(ce)

    if ce(cc).dendrite
    
        dendcnt = dendcnt +1;
    
    elseif ce(cc).spine

        Spdff = ce(cc).dff;
        Spdff = Spdff(1:round(length(Spdff)*.9));
        Spdff(isinf(Spdff)) = 0;
        Spdff_sub = Spdff(Spdff < nanmedian(Spdff)+abs(min(Spdff)));
        noiseM = nanmedian(Spdff_sub); % should be near 0
        noiseSD = nanstd(Spdff_sub);

        if flag==1
            slope = robustfit(ce( isDendrite(dendcnt) ).dff, ce(cc).dff);
        elseif flag==2 && isfield(ce,'cyc')
            spcyc = ce(cc).cyc(:);
            spcyc(isnan(spcyc)) = 0;
            slope = robustfit(ce( isDendrite(dendcnt) ).cyc(:),spcyc);
        else
            slope = robustfit(ce( isDendrite(dendcnt) ).dff, ce(cc).dff);
        end
        
        ce(cc).slope = slope(2);

        if isfield(ce,'cyc')
            ce(cc).cycRes = ce(cc).cyc - slope(2).*ce( isDendrite(dendcnt) ).cyc;
            ce(cc).cycRes(ce(cc).cycRes < 0) = 0;
        end

        r = ce(cc).dff - slope(2).*ce( isDendrite(dendcnt) ).dff;

        ce(cc).dffRes = r;

        rSp =  ce(cc).dff;
        rDn =  ce( isDendrite(dendcnt) ).dff;
        rSp = rSp - slope(2).*rDn;
        rSp(rSp < -noiseSD) = -noiseSD;
        rSp(isinf(rSp)) = 0;
        rDn(isinf(rDn)) = 0;
        ce(cc).dffRes = rSp;
        rSp(rSp <= 0) = nan;
        rDn(rDn <= 0) = nan;
        r = corrcoef(rSp,rDn,'rows','pairwise');
        ce(cc).corr = r(2);
    else
        ce(cc).cycRes = [];
        ce(cc).slope = [];
        ce(cc).corr = -1;
    end
end

