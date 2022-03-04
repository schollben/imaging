%
% computePeakResp
% compute on/off responses for spine Ca+ data

function [resp,resps,resperr,onResp,onResps,onRespdcs,onResperr,offResp,offResps,offRespdcs,offResperr] = computePeakRespOnOff(data)

resp = zeros(size(data,1),1);
resps = zeros(size(data,1),size(data,2));
resperr = zeros(size(data,1),1);
onResp = zeros(size(data,1),1);
onResps = resps;
onRespdcs = resps;
onResperr = zeros(size(data,1),1);
offResp = zeros(size(data,1),1);
offResps = resps;
offRespdcs = resps;
offResperr = zeros(size(data,1),1);

for ii = 1:size(data,1)
    
    data2 = squeeze(data(ii,:,:)); 
    
    [temp_f1, temp_f1s, temp_dc, temp_dcs,~,~] = compf1wdev(data2);
    
    resp(ii) = temp_dc + temp_f1;
    resps(ii,:) = temp_f1s + temp_dcs;
    resperr(ii) = nanstd(temp_dcs + temp_f1s)./sqrt(size(data,2));
    
    L = size(data,3);
    
    dataOn = data2(:,1:round(L/2));
    
    [temp_f1, temp_f1s,temp_dc,temp_dcs,~,~] = compf1wdev((dataOn));
    onResp(ii) = temp_f1 + temp_dc;
    onResps(ii,:) = temp_f1s + temp_dcs;
    onRespdcs(ii,:) = temp_dcs;
    onResperr(ii) = nanstd(temp_dcs + temp_f1s)./sqrt(size(data,2));
    
    dataOff = data2(:,round(L/2):L);
    %%%%%%%%%%%%%
    dataOff = dataOff - mean(dataOff(:,1:2),2)*ones(1,size(dataOff,2));
    %%%%%%%%%%%%%
    
    [temp_f1, temp_f1s,temp_dc,temp_dcs,~,~] = compf1wdev((dataOff));
    offResp(ii) = temp_dc + temp_f1;
    offResps(ii,:) = temp_f1s + temp_dcs;
    offRespdcs(ii,:) = temp_dcs ;
    offResperr(ii) = nanstd(temp_dcs + temp_f1s)./sqrt(size(data,2));
end
