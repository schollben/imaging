% delete straightened arrays with only bar
%identify all folder names
function [] = DeleteRawImageData(datatype)

cd(['D:\',datatype])
folders = dir('*');
for ii = 1:length(folders)
    folderName = folders(ii).name;
    if contains(folderName,'TSeries')
        cd(['D:\',datatype,'\',folderName])
        tFileFolders = dir('*.tif');
        if exist([cd,'/Registered'],'dir') 
            if exist([cd,'/Registered/Channel1/000001.tiff'],'file')
                disp(['deleting files from:  ',cd])
                for ff = 1:length(tFileFolders)
                    if contains(tFileFolders(ff).name,'TSeries')
                        filename = [cd,'\',tFileFolders(ff).name];
                        delete(filename)
                    end
                end
            end
        else
            disp([cd,'----> not registered yet'])
        end
    end
end
