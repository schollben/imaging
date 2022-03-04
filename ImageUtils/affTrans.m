% affTrans
%
% Takes array of old x and y positions, cp2tform result as arguments
% Applies affine transform and outputs in coordinates of fixed image
%
% ex: [ newX, newY ] = affTrans( oldX, oldY, T )

function [newX,newY] = affTrans(oldX, oldY, T)

if ~isempty(oldX)
    for i = 1:length(oldX)
        newX(i) = oldX(i)*T.tdata.T(1,1) + oldY(i)*T.tdata.T(1,2)+ T.tdata.T(3,1);
        newY(i) = oldX(i)*T.tdata.T(2,1) + oldY(i)*T.tdata.T(2,2)+ T.tdata.T(3,2);
    end
else
    newX = [];
    newY = [];
end


