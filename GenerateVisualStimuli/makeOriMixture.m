function [] = makeOriMixture
% makeOriMixture illustrates the construction of orientation mixtures

% Begin with clean slate
clear all
close all
clc

% Set constants
nComp     = 9;                                 % Number of stimulus components (set to 9)
stimCont  = 1;                                 % Stimulus contrast
dirCent   = 0;                                % Center direction of Gaussian contrast profile, in degrees
spreadVec = [5 12.5 20 30 55];                 % Standard deviation of Gaussian contrast profile, in degrees
dirComp   = dirCent + linspace(-80, 80, nComp) % The direction of motion for every stimulus component

% Loop through the different mixtures
for iW = 1:numel(spreadVec)
    
    % Compute Gaussian contrast profile
    profTemp      = normpdf(dirComp, dirCent, spreadVec(iW));
    profile       = stimCont * profTemp/sum(profTemp);    
    conProf(iW,:) = profile;
    
    % Plot the contrast profile in the orientation domain
    figure(1)
    subplot(2, numel(spreadVec), iW)
    plot(dirComp, profile, 'o-', 'color', rand(1,3), 'linewidth', 2)
    hold on, box off, axis square
    axis([dirCent-180 dirCent+180 0 stimCont])
    
    % Illustrate one movie-frame in the spatial domain
    for iC = 1:nComp
        sComp(:,:,iC) = genGabor(256, 100, 100, .025, 360*rand, .5, dirComp(iC), profile(iC));
    end
    subplot(2, numel(spreadVec), numel(spreadVec)+iW)
    imshow(sum(sComp - .5, 3) + .5);    
end
conProf
% Compute the opacicity for every stimulus component for programming
% environments in wich the contrast is always set to one, and the opacity
% determines the effective stimulus contrast. This system requires a
% different ordering of the stimulus components because the contrast has to
% decrease systematically. Now, the center orientation is the first
% component. The second component is the first component counterclockwise
% to the center, the third is the first clockwise to the center, the fourth
% is the second component counterclockwise to the center, etc.
conSort = fliplr(sort(conProf, 2));

O = zeros(numel(spreadVec), nComp);

for W = 1:numel(spreadVec)
    O(W,9) = conSort(W,9);
    O(W,8) = conSort(W,8)./((1 - O(W,9)));
    O(W,7) = conSort(W,7)./((1 - O(W,9)).*(1 - O(W,8)));
    O(W,6) = conSort(W,6)./((1 - O(W,9)).*(1 - O(W,8)).*(1 - O(W,7)));
    O(W,5) = conSort(W,5)./((1 - O(W,9)).*(1 - O(W,8)).*(1 - O(W,7)).*(1 - O(W,6)));
    O(W,4) = conSort(W,4)./((1 - O(W,9)).*(1 - O(W,8)).*(1 - O(W,7)).*(1 - O(W,6)).*(1 - O(W,5)));
    O(W,3) = conSort(W,3)./((1 - O(W,9)).*(1 - O(W,8)).*(1 - O(W,7)).*(1 - O(W,6)).*(1 - O(W,5)).*(1 - O(W,4)));
    O(W,2) = conSort(W,2)./((1 - O(W,9)).*(1 - O(W,8)).*(1 - O(W,7)).*(1 - O(W,6)).*(1 - O(W,5)).*(1 - O(W,4)).*(1 - O(W,3)));
    O(W,1) = conSort(W,1)./((1 - O(W,9)).*(1 - O(W,8)).*(1 - O(W,7)).*(1 - O(W,6)).*(1 - O(W,5)).*(1 - O(W,4)).*(1 - O(W,3)).*(1 - O(W,2)));
end
% disp(O)
end


function [IM] = genGabor(imsize, W_x, W_y, freq, phase, Back_lum, orientation, contrast)

IM       = zeros(imsize);
theta    = -orientation/180*pi;
X_vector = linspace(-imsize/2, imsize/2, imsize);

for r = 1:imsize;
    
    y_1 = r - (imsize + 1)/2;
    x_1 = X_vector;
    
    x = cos(-theta) * x_1 + sin(-theta) * y_1;
    y = -sin(-theta) * x_1 + cos(-theta) * y_1;
    
    deel_x = exp(-2.77/W_x^2 *(x - 0).^2);
    deel_y = exp(-2.77/W_y^2 *(y - 0).^2);
    deel_f = cos(2*pi*freq* (x - 0) + phase);
    
    temp = contrast*(deel_x.*deel_y.*deel_f);
    temp_2 = 1+temp;
    temp_3 = Back_lum * temp_2;
    
    IM(r, :) = temp_3;
end
end