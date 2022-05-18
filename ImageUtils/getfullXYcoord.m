function [mask]=getfullXYcoord(nmCoord)

insidexy = inpolygon(1:imgInfo.sizeX, 1:imgInfo.sizeY, nmCoord(:,1), nmCoord(:,2));

[X,Y] = ind2sub([imgInfo.sizeX imgInfo.sizeY], find(insidexy));
