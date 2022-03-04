%
% computePeakResp Ca+ data

function [resp,resps,resperr] = computePeakResp(data)

resp = zeros(size(data,1),1);
resps = zeros(size(data,1),size(data,2));
resperr = zeros(size(data,1),1);

for ii = 1:size(data,1)
    
    data2 = squeeze(data(ii,:,:)); 
    
    [temp_f1, temp_f1s, temp_dc, temp_dcs,~,~] = compf1wdev(data2);
    
    resp(ii) = temp_dc + temp_f1;
    resps(ii,:) = temp_f1s + temp_dcs;
    resperr(ii) = nanstd(temp_dcs + temp_f1s)./sqrt(size(data,2));
    
end
