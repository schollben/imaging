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

end

%%
tic; 
for frnum = 1:1000
    im = squeeze(imgstack(:,:,frnum));
    for cc = 1
    m1(frnum) = mean(im(ss));
    end
end
toc;

%%

tic;
for cc = 1:100
m2 = mean( reshape(imgstack(S), 128, 1000), 1);
end
toc;




