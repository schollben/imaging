% dendritic subtraction
%

function [] = DendriteSubtraction()

global ce

for cc = 1:length(ce)

    if ce(cc).spine

        %find dendrite
        dendPoint = cc;
        while ~ce(dendPoint).dendrite
            dendPoint = dendPoint+1;
        end
        Spdff = ce(cc).dff;
        Spdff = Spdff(1:round(length(Spdff)*.9));
        Spdff(isinf(Spdff)) = 0;
        Spdff_sub = Spdff(Spdff < nanmedian(Spdff)+abs(min(Spdff)));
        noiseM = nanmedian(Spdff_sub); % should be near 0
        noiseSD = nanstd(Spdff_sub);
        spcyc = ce(cc).cyc(:);
        spcyc(isnan(spcyc)) = 0;
        slope = robustfit(ce(dendPoint).cyc(:),spcyc);
        %dendritic scalar applied (from robust fit) to cyc and subtraction
        ce(cc).slope = slope(2);
        
        ce(cc).cycRes = ce(cc).cyc - slope(2).*ce(dendPoint).cyc;
        ce(cc).cycRes(ce(cc).cycRes < 0) = 0;

        r = ce(cc).dff - slope(2).*ce(dendPoint).dff;

        ce(cc).dffRes = r;
        
        rSp =  ce(cc).dff;
        rDn =  ce(dendPoint).dff;
        rSp = rSp - slope(2).*rDn;
        rSp(rSp < -noiseSD) = -noiseSD;
        rSp(isinf(rSp)) = 0;
        rDn(isinf(rDn)) = 0;
        ce(cc).rawRes = rSp;
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

