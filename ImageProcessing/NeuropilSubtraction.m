%
%
%
function [] = NeuropilSubtraction()

global ce

for cc = 1:length(ce)

    if ce(cc).soma
    
        slope = robustfit(ce(cc).dff, ce(1).dff_neuropil);

        ce(cc).slope = slope(2);

        r = ce(cc).dff - slope(2).*ce(1).dff_neuropil;

        ce(cc).dff = r;

    else
        
        ce(cc).slope = [];
    
    end
end

