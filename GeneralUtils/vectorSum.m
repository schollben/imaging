function summedVector = vectorSum(array,harmonic,dim)
% summedVector = vectorSum(stack,harmonic,dim)
% vector sum of input array with 2nd harmonic response 
% along the last dimension of the array (unless 
% otherwise specified by user input). 

if(nargin<3), dim = length(size(array)); end
if(nargin<2), harmonic = 2;              end

stackSize = size(array);
phaseArraySize = 1+0*stackSize; phaseArraySize(dim) = stackSize(dim);
vectorArraySize = stackSize;    vectorArraySize(dim) = 1;
phaseValues = linspace(0,360,stackSize(dim)+1); 
summedVector = sum(array.*repmat(reshape(exp(2*pi*1i*harmonic*mod(phaseValues(1:(end-1)),360/harmonic)/360),phaseArraySize),vectorArraySize),3);