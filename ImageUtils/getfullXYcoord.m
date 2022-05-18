function [X,Y]=getfullXYcoord(nmCoord)

[xx,yy] = meshgrid(nmCoord(:,1),nmCoord(:,2));
insidexy = inpolygon(xx,yy,nmCoord(:,1),nmCoord(:,2));
xx(~insidexy) = NaN;
yy(~insidexy) = NaN;
removeIndicies = isnan(xx) & isnan(yy);
xx(removeIndicies) = [];
yy(removeIndicies) = [];

X = xx;
Y = yy;