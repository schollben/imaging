[sROI] = ReadImageJROI('D:/RoiSet.zip');

for j = 1:4
%%
nmCoord = sROI{1}.mnCoordinates;
[x,y] = meshgrid(nmCoord(:,1),nmCoord(:,2));
insidexy = inpolygon(x,y,nmCoord(:,1),nmCoord(:,2));
x(~insidexy) = NaN;
y(~insidexy) = NaN;
removeIndicies = isnan(x) & isnan(y);
x(removeIndicies) = [];
y(removeIndicies) = [];
%%
end

tic; 
imData = tsStack(:,:,1:1000); 

toc;