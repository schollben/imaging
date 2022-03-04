
function [events, noiseTotal] = extractCaEvents(ce,SDCUTTOFF,verbose)

cyc = ce.cycRes;

Spdff = filterBaseline_dFcomp(resample(ce.raw,1,4));

%calc spine F noise before subtraction for later use
%remove baseline and compute dF/F
Spdff = Spdff(1:round(length(Spdff)*.9));
Spdff(isinf(Spdff)) = 0;
Spdff_sub = Spdff(Spdff < nanmedian(Spdff)+abs(min(Spdff)));
noiseM = nanmedian(Spdff_sub); % should be near 0
noiseSD = nanstd(Spdff_sub);

noiseTotal = noiseM + noiseSD;

%identify spine 'events'
%apply for each indiv cycRes

%exponential filter param 
%decay is 400 ms time constant (roughly following Konnerth)
alpha = .4; 

events = zeros(size(cyc,1),size(cyc,2));

for jj = 1:size(cyc,2)
    for ii = 1:size(cyc,1)-1 %dont go through blank
        
        r = squeeze(cyc(ii,jj,:));
        %%%%%%%%%%%%%%%%%%%%%%%
        %exponential filter (r: dff trace)
        rf = filter(alpha, [1 alpha-1],r);
        
        [~,locs]= findpeaks(rf);
        %ignore trial beginning/end
        locs = locs(locs>1 & locs<length(rf)-3);
        amps = zeros(length(locs),1);
        %avg 2 pts (choose best from forward or backward)
        for z = 1:length(locs)
            amps(z) = max([mean(r(locs(z)-1:locs(z))) ...
                mean(r(locs(z)-1:locs(z)))]);
        end
        
        locs = locs(amps>(noiseSD*SDCUTTOFF+noiseM));
        
        events(ii,jj) = sum(locs)>0;
        
%         if isnan(amps) | amps==0
%             eventamps(ii,jj) = 0;
%         else
%             eventamps(ii,jj) = max(amps);
%         end
        
        if verbose
            
            figure(jj)
            subplot(1,size(cyc,1),ii)
            hold off
            plot(1:length(r),r,'b',1:length(rf),rf,'r')
            hold on
            plot(1:length(r),ones(1,length(r)).*(noiseSD*SDCUTTOFF +noiseM),'--k')
            ylim([-noiseSD 1])
            
            
        end
    end
end