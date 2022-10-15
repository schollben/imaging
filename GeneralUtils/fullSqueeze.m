
function [dat]=fullSqueeze(dat)

while length(size(dat))>1
    dat = squeeze(dat);
end