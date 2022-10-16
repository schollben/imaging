%
%
%
function [] = organizeFiles(fnames,date,datatype)

cd(['D:\',datatype])

rawfileList = dir('*tif'); %images

rawh5fileList = dir('*h5'); %wavesurfer

for k = fnames
    sortedDir = ['D:\',datatype,'\TSeries-',date,'-',sprintf('%04i',k),'-',sprintf('%03i',k)];
    mkdir(sortedDir)
end
%%
for k = 1:length(rawfileList)

    filedate = rawfileList(k).name(9:18);
    a = strfind(filedate,'-');
    filedate = filedate([a(1)+1:a(2)-1, a(2)+1:end, 1:a(1)-1]);

    rawfilefname = str2double(rawfileList(k).name(end-14:end-10));

    if ismember(rawfilefname,fnames) && strcmp(date,filedate)
        sortedDir = ['D:\',datatype,'\TSeries-',date,'-',sprintf('%04i',rawfilefname),'-',sprintf('%03i',rawfilefname)];
        movefile(rawfileList(k).name,sortedDir)
    end

end

for k = 1:length(rawh5fileList)

    filedate = rawh5fileList(k).name(9:18);
    a = strfind(filedate,'-');
    filedate = filedate([a(1)+1:a(2)-1, a(2)+1:end, 1:a(1)-1]);

    rawfilefname = str2double(rawh5fileList(k).name(end-6:end-3));
       
    if ismember(rawfilefname,fnames) && strcmp(date,filedate)
       sortedDir = ['D:\',datatype,'\TSeries-',date,'-',sprintf('%04i',rawfilefname),'-',sprintf('%03i',rawfilefname)];
       movefile(rawh5fileList(k).name,sortedDir)
    end

end

disp 'organized SCANIMAGE files'
