function img = alignImage(img,input_points,base_points,type,imgSize)
% function img = alignImage(img,input_points,base_points,type)
% Aligns an image using the same spatial landmarks across a reference and
% target image (as defined by input_points and base_points). The alignment
% method is 'affine'.
%
% input_points - same as movingPoints
% base_points  - same as fixedPoints
%
% type ==> alignment method (default is affine)
%         TRANSFORMTYPE         MINIMUM NUMBER OF PAIRS
%         -------------         -----------------------
%         'nonreflective similarity'       2 
%         'similarity'                     3 
%         'affine'                         3 
%         'projective'                     4 
%         'polynomial' (ORDER=2)           6
%         'polynomial' (ORDER=3)          10
%         'polynomial' (ORDER=4)          15
%         'piecewise linear'               4
%         'lwm'                            6
% imgSize ==> final image size

if(nargin<4), type = 'affine';      end
if(nargin<5), imgSize = size(img);  end

isSamePoints = min(input_points(:) == base_points(:)); % checks if alignment points are the same
if(~isSamePoints)
            mytform = fitgeotrans(input_points,base_points,type);
            img     = imwarp(img,mytform,'OutputView',imref2d(imgSize));
end
end

