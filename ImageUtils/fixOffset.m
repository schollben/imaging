function [ img2 ] = fixOffset( img,offSet)
% fixes phase offset for resonance scanned images;
img2 = img;
for i = 1:2:size(img,1)-1
    for j = 10:size(img,2)-11
        img2(i,j) = img(i,j+offSet);
    end;
end;

end

