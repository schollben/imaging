%remove slow baselin in raw F traces
%(1) cut off large events 
%(2) 99 pt medfilt for low-pass trace
%(3) calc initial F value (median)
%(4) subtract and add back
function [raw_new]=filterBaseline_dFcomp2(raw,pts)
if nargin<2
    pts = 99;
end
%pad F trace
F_temp = raw;
F_temp = cat(1,repmat(mean(F_temp(2:4)),pts,1),F_temp);
F_temp = cat(1,F_temp,repmat(mean(F_temp(end-4:end-1)),pts,1));
%25th percentile medfilt
F_temp = prctfilt1(F_temp,pts);
%remove padding
raw_new = F_temp(pts+1:end-pts);

raw_new = (raw - raw_new)./raw_new;

raw_newlpf = prctfilt1(raw_new,90);

raw_new = raw_new - raw_newlpf;



