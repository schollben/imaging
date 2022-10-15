%
%
%
function []=SearchForUnregisteredFolders(datatype)

cd(['D:\',datatype])
allFiles = dir();
needtoreg = [];
for k = 1:length(allFiles)
    if strcmp(allFiles(k).name(1:7),'TSeries')
        cd([['D:\',datatype,'\',allFiles(k).name])
        if exist('Registered')
            needtoreg = [needtoreg; ];

        end
    end
end