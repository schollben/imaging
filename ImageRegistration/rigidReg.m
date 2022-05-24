% Adapted from original code by Theo Walker circa 2015
%
% 03-02-2022

function [newstack,newch1stack]=rigidReg(imgStack,ch1Stack,template,ChunkProcess,useCh2template,downsampleRates,maxMovement)

%init
[height, width, depth] = size(imgStack);
regOffsetsX = zeros(depth,1);
regOffsetsY = zeros(depth,2);
%%%%%%%%%%%%%%%%%%%%%%%
%begin
% tic;
%get best correlation
if ChunkProcess

    for r=1:length(downsampleRates)
        sampRate = downsampleRates(r);
        if r>1
            prevsampRate = downsampleRates(r-1);
        end
        disp(['registering images, iteration ' num2str(r)]);
        downHeight = height*sampRate;
        downWidth = width*sampRate;

        templateImg = imresize(template, [downHeight,downWidth]);

        regImg = imresize( squeeze( nanmean(imgStack,3) ) , [downHeight,downWidth]);

        if r==1
            %initial offset
            minOffsetY = -round(maxMovement*downHeight/2);
            maxOffsetY = round(maxMovement*downHeight/2);

            minOffsetX = -round(maxMovement*downWidth/2);
            maxOffsetX = round(maxMovement*downWidth/2);

        else
            %we are refining an earlier offset
            minOffsetY = regOffsetsY*sampRate - sampRate/prevsampRate/2;
            maxOffsetY = regOffsetsY*sampRate + sampRate/prevsampRate/2;

            minOffsetX = regOffsetsX*sampRate - sampRate/prevsampRate/2;
            maxOffsetX = regOffsetsX*sampRate + sampRate/prevsampRate/2;
        end
        bestCorrValue = -1;
        bestCorrX = 0;
        bestCorrY = 0;
        for y=minOffsetY:maxOffsetY
            for x=minOffsetX:maxOffsetX
                %determine the offsets in X and Y for which the overlap
                %between the images correlates best
                subTemplateY1 = 1+max(y,0);
                subTemplateY2 = downHeight+min(y,0);
                subTemplateX1 = 1+max(x,0);
                subTemplateX2 = downWidth+min(x,0);

                subRegY1 = 1+max(-y,0);
                subRegY2 = downHeight+min(-y,0);
                subRegX1 = 1+max(-x,0);
                subRegX2 = downHeight+min(-x,0);

                subTemplateImg = templateImg(subTemplateY1:subTemplateY2,...
                    subTemplateX1:subTemplateX2);
                subRegImg = regImg(subRegY1:subRegY2,subRegX1:subRegX2);

                corrValue = corr2(subRegImg, subTemplateImg);
                if corrValue > bestCorrValue
                    bestCorrX = x;
                    bestCorrY = y;
                    bestCorrValue = corrValue;
                end
            end
        end
        regOffsetsY = bestCorrY*1/sampRate;
        regOffsetsX = bestCorrX*1/sampRate;
    end

    regOffsetsY = repmat(regOffsetsY,depth,1);
    regOffsetsX = repmat(regOffsetsX,depth,1);

elseif ~ChunkProcess

    for r=1:length(downsampleRates)
        sampRate = downsampleRates(r);
        if r>1
            prevsampRate = downsampleRates(r-1);
        end
        disp(['registering images, iteration ' num2str(r)]);
        downHeight = height*sampRate;
        downWidth = width*sampRate;

        templateImg = imresize(template, [downHeight,downWidth]);
        for d=1:depth

            regImg = imresize(imgStack(:,:,d), [downHeight,downWidth]);

            if r==1
                %initial offset
                minOffsetY = -round(maxMovement*downHeight/2);
                maxOffsetY = round(maxMovement*downHeight/2);

                minOffsetX = -round(maxMovement*downWidth/2);
                maxOffsetX = round(maxMovement*downWidth/2);

            else
                %we are refining an earlier offset
                minOffsetY = regOffsetsY(d)*sampRate - sampRate/prevsampRate/2;
                maxOffsetY = regOffsetsY(d)*sampRate + sampRate/prevsampRate/2;

                minOffsetX = regOffsetsX(d)*sampRate - sampRate/prevsampRate/2;
                maxOffsetX = regOffsetsX(d)*sampRate + sampRate/prevsampRate/2;
            end
            bestCorrValue = -1;
            bestCorrX = 0;
            bestCorrY = 0;
            for y=minOffsetY:maxOffsetY
                for x=minOffsetX:maxOffsetX
                    %determine the offsets in X and Y for which the overlap
                    %between the images correlates best
                    subTemplateY1 = 1+max(y,0);
                    subTemplateY2 = downHeight+min(y,0);
                    subTemplateX1 = 1+max(x,0);
                    subTemplateX2 = downWidth+min(x,0);

                    subRegY1 = 1+max(-y,0);
                    subRegY2 = downHeight+min(-y,0);
                    subRegX1 = 1+max(-x,0);
                    subRegX2 = downHeight+min(-x,0);

                    subTemplateImg = templateImg(subTemplateY1:subTemplateY2,...
                        subTemplateX1:subTemplateX2);
                    subRegImg = regImg(subRegY1:subRegY2,subRegX1:subRegX2);

                    corrValue = corr2(subRegImg, subTemplateImg);
                    if corrValue > bestCorrValue
                        bestCorrX = x;
                        bestCorrY = y;
                        bestCorrValue = corrValue;
                    end
                end
            end
            regOffsetsY(d) = bestCorrY*1/sampRate;
            regOffsetsX(d) = bestCorrX*1/sampRate;
        end
    end

end
%%%%%%%%%%%%%%%%%%%%%%%

newch1stack = [];
newstack = [];

for d=1:depth
    
    img = imgStack(:,:,d);
    shiftedY1 = 1+max(regOffsetsY(d),0);
    shiftedY2 = height+min(regOffsetsY(d),0);
    shiftedX1 = 1+max(regOffsetsX(d),0);
    shiftedX2 = width+min(regOffsetsX(d),0);

    subRegY1 = 1+max(-regOffsetsY(d),0);
    subRegY2 = height+min(-regOffsetsY(d),0);
    subRegX1 = 1+max(-regOffsetsX(d),0);
    subRegX2 = width+min(-regOffsetsX(d),0);

    shiftedImg = ones(height,width)*double(min(min(img)));
    shiftedImg(shiftedY1:shiftedY2,shiftedX1:shiftedX2) = img(subRegY1:subRegY2,...
        subRegX1:subRegX2);
    newstack(:,:,d) = shiftedImg;

    if useCh2template
        img = ch1Stack(:,:,d);
        shiftedImg = ones(height,width)*double(min(min(img)));
        shiftedImg(shiftedY1:shiftedY2,shiftedX1:shiftedX2) = img(subRegY1:subRegY2,...
            subRegX1:subRegX2);
        newch1stack(:,:,d) = shiftedImg;
    end

end
% toc;