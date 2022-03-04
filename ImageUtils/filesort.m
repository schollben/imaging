
%sort
% cd M:\2018-Jun-08
cd O:\2019-Feb-04

folderList = dir(['*_',sprintf('%.5d',1),'.tif']);
fileList = dir('*.tif');
%loop through list, move all chunks with the same basename
for j = 1:length(folderList)
    k = str2num(folderList(j).name(6:10));
    newdir = [cd,'\t',sprintf('%.5d',k)];
    mkdir(newdir)
    for n = 1:length(fileList)
        if strcmp(sprintf('%.5d',k),fileList(n).name(6:10))
            [s, mess, messid] = movefile([cd '\' fileList(n).name],....
                [newdir,'\',fileList(n).name],'f');
        end
    end
end



%%

%sort
cd C:\Users\schollb\Dropbox\projects\crebgcamp_2018\mdnew\
fileList = dir('*.flim');
%loop through list, move all chunks with the same basename
for n = 1:length(fileList)
    fname = fileList(n).name(1:8);
    newdir = [cd,'\',fname];
    mkdir(newdir)
            [s, mess, messid] = movefile([cd '\' fileList(n).name],....
                [newdir,'\',fileList(n).name],'f');
end
