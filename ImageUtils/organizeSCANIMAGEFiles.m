%
%
%
function [] = organizeSCANIMAGEFiles()
%%
cd D:\SCANIMAGE\
rawfileList = dir('*tif'); %images
%rawh5fileList = dir('*h5'); %wavesurfer
allFilesToSort = [];
if isempty(rawfileList)
    disp 'no files to organize'
else
    for k = 1:length(rawfileList)
        a = strfind(rawfileList(k).name,'_');
        aa = strfind(rawfileList(k).name,'-');
        date = rawfileList(k).name([a(1)+1 : aa(1)-1, aa(1)+1:aa(2)-1, aa(2)+1:a(2)-1]);
        filenum = rawfileList(k).name([a(2)+1 : a(3)-1]);
        allFilesToSort = [allFilesToSort; str2double([date,filenum])];
    end
end
allFilesToSort = unique(allFilesToSort);

for j = 1:length(allFilesToSort)
    d = num2str(allFilesToSort(j));
    date = d([5:8 1:4])
    fnames = str2double(d(end-4:end))
    organizeFiles(fnames,date,'SCANIMAGE');
end
