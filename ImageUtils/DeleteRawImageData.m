% delete straightened arrays with only bar
%identify all folder names
function [] = DeleteRawImageData(datatype)

cd(['D:\',datatype])
folders = dir('*'); 
for ii = 1:length(folders)
    folderName = folders(ii).name;
    if strcmp(folderName,'2018-Feb-23')
        cd(['M:\',folderName])
        tFileFolders = dir('*');
        for jj = 1:length(tFileFolders)
            dataLocation = ['M:\',folderName,'\',...
                tFileFolders(jj).name,'\Registered'];
            if isdir(dataLocation)
                cd(['M:\',folderName,'\',tFileFolders(jj).name])
                tFiles = dir('*tif');
                for ff = 1:length(tFiles)
                    filename = ['M:\',folderName,'\',...
                        tFileFolders(jj).name,'\',tFiles(ff).name];
                    delete(filename)
                    disp(['deleted raw file...  ',filename])
                end
            end
        end
    end
end
disp done


%%
% delete straightened arrays with only bar
%identify all folder names
cd O:\
folders = dir('*'); 
for ii = 1:length(folders)
    folderName = folders(ii).name;
%     if strcmp(folderName,'2017-Jul-31')

        cd(['O:\',folderName])
        tFileFolders = dir('*');
        for jj = 1:length(tFileFolders)
            dataLocation = ['O:\',folderName,'\',...
                tFileFolders(jj).name,'\Registered'];
            if isdir(dataLocation)
                cd(['O:\',folderName,'\',tFileFolders(jj).name])
                tFiles = dir('*tif');
                for ff = 1:length(tFiles)
                    filename = ['O:\',folderName,'\',...
                        tFileFolders(jj).name,'\',tFiles(ff).name];
                    delete(filename)
                    disp(['deleted raw file...  ',filename])
                end
            end
        end
%     end
end
disp done


%%
% delete straightened arrays with only bar
%identify all folder names
cd O:\Population\
folders = dir('*'); 
for ii = 1:length(folders)
    folderName = folders(ii).name;
    if strcmp(folderName,'2018-May-16')
        cd(['O:\Population\',folderName])
        tFileFolders = dir('*');
        for jj = 1:length(tFileFolders)-1
            dataLocation = ['O:\Population\',folderName,'\',...
                tFileFolders(jj).name,'\Registered'];
            dataLocation2 = ['O:\Population\',folderName,'\',...
                tFileFolders(jj).name,'\Result'];
            if isdir(dataLocation)||isdir(dataLocation2)
                cd(['O:\Population\',folderName,'\',tFileFolders(jj).name])
                tFiles = dir('*tif');
                for ff = 1:length(tFiles)
                    filename = ['O:\Population\',folderName,'\',...
                        tFileFolders(jj).name,'\',tFiles(ff).name];
                    delete(filename)
                    disp(['deleted raw file...  ',filename])
                end
            end
        end
    end
end
disp done