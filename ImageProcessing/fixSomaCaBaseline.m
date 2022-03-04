               
function cyc_new = fixSomaCaBaseline(cyc)
%stupid soma weird responses
cyc_new = cyc;
for nStim = 1:size(cyc,1)
    cycFo = mean(squeeze(cyc(nStim,:,1:3)),2);
    cyc_new(nStim,:,:) = squeeze(cyc(nStim,:,:)) - cycFo*ones(1,size(cyc,3));
end