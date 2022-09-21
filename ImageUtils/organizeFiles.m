%
%
%
function [] = organizeFiles(fnames,datatype,date)

if strcmp(datatype,'SCANIMAGE')

    cd(['D:\',datatype])

    rawfileList = dir('*tif'); %images

    rawh5fileList = dir('*h5'); %wavesurfer

    for k = fnames
        sortedDir = ['D:\',datatype,'\TSeries-',date,'-',sprintf('%04i',k),'-',sprintf('%03i',k)];
        mkdir(sortedDir)
    end

    for k = 1:length(rawfileList)
        
        rawfilefname = str2double(rawfileList(k).name(end-14:end-10));
        
        if ismember(rawfilefname,fnames)
            sortedDir = ['D:\',datatype,'\TSeries-',date,'-',sprintf('%04i',rawfilefname),'-',sprintf('%03i',rawfilefname)];
            movefile(rawfileList(k).name,sortedDir)
        end

    end

    for k = 1:length(rawh5fileList)

        rawfilefname = str2double(rawh5fileList(k).name(end-6:end-3));
        sortedDir = ['D:\',datatype,'\TSeries-',date,'-',sprintf('%04i',rawfilefname),'-',sprintf('%03i',rawfilefname)];
        if ismember(rawfilefname,fnames)
            movefile(rawh5fileList(k).name,sortedDir)
        end

    end

    disp 'organized SCANIMAGE files'
else

    disp(datatype)

end
