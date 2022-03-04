data = load('M:\imagingcourse\Day4\NMDAspont\Old\Registered\Channel1\NMDASpont.mat');
Pten_spont_data = data.ce;
Pten_spont_dff = [];

figure(1)
for i = 1:length(Pten_spont_data)
    subplot(length(Pten_spont_data), 1,i)
    a = Pten_spont_data(i).dff;
    plot(Pten_spont_data(i).dff);
    hold on
    Pten_spont_dff = [Pten_spont_dff, a];
    axis off
end

figure(2)
PTEN_spont_corr = corr(Pten_spont_dff);
imagesc(PTEN_spont_corr)

%%Trying to plot 3 correlative traces and failed
subplot(1, 1,1, 'align')
    plot(Pten_spont_data(9).dff(1:1000));
    hold on

subplot(3, 1,2, 'align')
    plot(Pten_spont_data(10).dff);
    hold on
    axis off
subplot(3, 1,3, 'align')
    plot(Pten_spont_data(11).dff);
    hold on
    Pten_spont_dff = [Pten_spont_dff, a];
    axis off
    
---

data = load('M:\imagingcourse\Day2\PTEN_pop_spontaneous\Result\PTEN_pop_spontaneous');
Pten_spont_data = data.ce;
Distances = zeros(length(Pten_spont_data), length(Pten_spont_data));
for i = 1:length(Pten_spont_data)
    for j = 1:length(Pten_spont_data)
        P(1,1) = Pten_spont_data(i).xPos;
        P(1,2) = Pten_spont_data(i).yPos;
        P(2,1) = Pten_spont_data(j).xPos;
        P(2,2) = Pten_spont_data(j).yPos;
        Distances(i,j) = pdist(P);
    end
end
Pten_spont_dff = [];
for i = 1:length(Pten_spont_data)
    a = Pten_spont_data(i).dff;
    Pten_spont_dff = [Pten_spont_dff, a];
end
PTEN_spont_corr = corr(Pten_spont_dff);
PTEN_spon_corr_once = tril(PTEN_spont_corr, -1);
PTEN_spon_corr_once(PTEN_spon_corr_once == 0) = NaN;

PTEN_Distances_once = tril(Distances, -1);
PTEN_Distances_once(PTEN_Distances_once == 0) = NaN;

figure
plot(PTEN_Distances_once, PTEN_spon_corr_once, 'ok')
xlabel('Distance in pixel')
ylabel('correlation')
title('PTENKO')