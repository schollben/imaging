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

%% how to read bruker metadata
xml = xml2struct(fileList(1).name);

%%
cd D:\BRUKER\02232022\TSeries-02232022-1150-001\Registered\Channel1
obj = Tiff('test2','w');
%%
setTag(obj,'Photometric',Tiff.Photometric.RGB);
setTag(obj,'Compression',Tiff.Compression.None);
setTag(obj,'BitsPerSample',16);
setTag(obj,'SamplesPerPixel',1);
setTag(obj,'ImageLength',512);
setTag(obj,'ImageWidth',512);
setTag(obj,'PlanarConfiguration',Tiff.PlanarConfiguration.Chunky);
%%
for frnm = 1:1000
write(obj,uint16(imgstack(:,:,frnm)));
end
close(obj);

%%



