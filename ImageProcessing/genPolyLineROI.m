%
% nmCoord - line coordinates from Image
% d - nStrokeWidth
function [mask2d] = genPolyLineROI(nmCoord,dWidth,sizeX,sizeY)

if nargin < 2
    dWidth = 10;
end

x = nmCoord(:,1);
y = nmCoord(:,2);

r = sqrt( (x(2:end) - x(1:end-1)).^2 + (y(2:end) - y(1:end-1)).^2 );

delta_x = ( (dWidth/2) ./ r ) .* (y(1:end-1) - y(2:end));
delta_y = ( (dWidth/2) ./ r ) .* (x(2:end) - x(1:end-1));

new_x = x + [delta_x ; delta_x(end)];
new_y = y + [delta_y ; delta_y(end)];

delta_x = ( (-dWidth/2) ./ r ) .* (y(1:end-1) - y(2:end));
delta_y = ( (-dWidth/2) ./ r ) .* (x(2:end) - x(1:end-1));

new_x = [new_x; flipud(x + [delta_x ; delta_x(end)])];
new_y = [new_y; flipud(y + [delta_y ; delta_y(end)])];

new_x = [new_x; new_x(1)];
new_y = [new_y; new_y(1)];

mask2d = poly2mask(new_x,new_y,sizeX,sizeY);