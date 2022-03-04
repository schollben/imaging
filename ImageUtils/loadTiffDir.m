% turned Dan's original code into function with filename as input

function imgStack = loadTiffDir(filename)
% tifList = dir('*.tif');
count  = 0;
% for i = 1:length(tifList)
    nImages=length(imfinfo(filename));
%     t = Tiff(tifList(i).name,'r');
    t = Tiff(filename,'r');
    for k = 1:nImages
        count = count+1;
        t.setDirectory(k);
        imgStack(:,:,count) = t.read();
    end;
%       disp([num2str(i/length(tifList)), 'percent done']);
% end;
    