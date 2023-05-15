
function RFcheckermap_dff(cc)

global ce

dff_all = [ce.dff];
% for c = 1:length(ce)
%     spike_prob(c,:) = ce(c).spikeInference;
% end
StimOnTimes = ce(1).stimOn2pFrame;
StimOnLocations =cell2mat(strfind(ce(1).stimstr,'1'));

if ismember(880, max(StimOnLocations))
    wid = 22; hei = 40;
elseif ismember(220, max(StimOnLocations))
    wid = 11; hei = 20;
elseif ismember(50, max(StimOnLocations))
    wid = 5; hei = 10;
end
simulStims = size(StimOnLocations, 2);

%cells = [39];
%cells = [1:10];


% Forward dFF
rDff = zeros(wid*hei,30); % 220,16 originally.
for n = 1:length(StimOnTimes)
    dff = dff_all(StimOnTimes(n) - 3:StimOnTimes(n) + 29, cc)';
    dff = dff - mean(dff(1:3)); % Originally just dff(1:2)
    dff = dff(4:end);
    rDff(StimOnLocations(n,:),:) = rDff(StimOnLocations(n,:),:) + ones(simulStims,1)*dff;
end

rDff = reshape(rDff,hei,wid,size(rDff,2));

figure(99); clf; hold on

for x=1:hei
    for y = 1:wid
t = 1:size(rDff,3);
t = t + 1.2*length(t)*(x - 1);
plot(t,squeeze(rDff(x,y,:)) - y*5,'k')
    end
end

% % Forward Prob
% rProb = zeros(wid*hei,30);
% rProb_shuffle = rProb;
% for n = 1:length(StimOnTimes)
%     prob = spike_prob(cc, StimOnTimes(n) - 3:StimOnTimes(n) + 29);
%     prob = prob - mean(prob(1:3));
%     prob = prob(4:end);
%     rProb(StimOnLocations(n,:),:) = rProb(StimOnLocations(n,:),:) + ones(simulStims,1)*prob;
%     %shuffle for comparison
%     rand_id = randi(size(StimOnLocations,1),1);
%     rProb_shuffle(StimOnLocations(rand_id,:),:) = rProb_shuffle(StimOnLocations(rand_id,:),:) + ones(simulStims,1)*prob;
% end
% 
% rProb = reshape(rProb,hei,wid,size(rProb,2));
% rProb_shuffle = reshape(rProb_shuffle,hei,wid,size(rProb_shuffle,2));
% figure(99); clf; hold on
% for x=1:hei
%     for y = 1:wid
% t = 1:size(rProb,3);
% t = t + 1.2*length(t)*(x - 1);
% plot(t,squeeze(rProb(x,y,:)) - y*4,'k')
% % plot(t,squeeze(rProb_shuffle(x,y,:)) - y*5,'color',[.5 .5 .5])
%     end
% end
% pause
