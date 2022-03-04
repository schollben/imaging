%uses robustfit function in matlab
function [dFFres] = compute_dFFres(dFF,dendrite)

slope = robustfit(dendrite(:),dFF(:));
slope = slope(2);
dFFres = dFF - slope.*dendrite;