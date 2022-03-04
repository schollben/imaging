function [img clippingValues] = clipImage(img,ClippingRange,centerOnZero)
% [img clippingValues] = clipImage(img,ClippingRange,centerOnZero)
% This function clips an image.
% Clipping Range: # of std. deviations around mean that image will be clipped.
% Centered on Zero - Default is False. If True, Clipping will be
% +/-(Mean+ClippingRange*Std)

if(nargin<3)
    centerOnZero = false;
end

% Clips Image (If necessary)
if(centerOnZero)
    LowerClippingValue = -(abs(mean2(img))+ClippingRange*std2(img));
    UpperClippingValue =  (abs(mean2(img))+ClippingRange*std2(img));
else
    LowerClippingValue = mean2(img)-ClippingRange*std2(img);
    UpperClippingValue = mean2(img)+ClippingRange*std2(img);
end

img(img < LowerClippingValue) = LowerClippingValue;
img(img > UpperClippingValue) = UpperClippingValue;
clippingValues = [LowerClippingValue UpperClippingValue];