% function [newFrameTrigs] = replaceMissingFrameTriggers(frameTrigs)
%
function [newFrameTrigs] = replaceMissingFrameTriggers(frameTrigs)

newFrameTrigs = frameTrigs(1);
mperiod = median(diff(frameTrigs));
for k = 2:length(frameTrigs)
    
    if frameTrigs(k)-frameTrigs(k-1) > (mperiod+5)
        newFrameTrigs = [newFrameTrigs; frameTrigs(k-1) + mperiod];
    end
        
    newFrameTrigs = [newFrameTrigs; frameTrigs(k) + 0];
    
end



