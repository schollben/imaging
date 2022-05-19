%
% example:
%  [imgInfo,fileList] = getmetadata(datatype,fileList,folderList(k).name)

function [imgInfo,fileList] = getmetadata(datatype,fileList,foldername,useCh2template)

if strcmp(datatype,'BRUKER')

    imgInfo = readXmlFile_v2([foldername,'.XML']);
    if  imgInfo.PMTgain_ch01 > 0 && useCh2template
        disp 'found red channel (channel 1 on bruker system)'
        useCh2template = 1;
    else
        useCh2template = 0;
        disp 'no red channel'
    end

    %edit fileList to focus on channel 2 (green) images
    % (dont care about red channel right now)
    ch1_inds = [];
    for j = 1:length(fileList)
        if ~~strfind(fileList(j).name,'Ch2')
            ch1_inds = [ch1_inds j];
        end
    end
    %update fileList
    fileList = fileList(ch1_inds);

elseif strcmp(datatype,'SI')

    % NOTE- HAVE NOT EDITED THIS CODE YET

    metadata=ScanImageTiffReader(fileList(1).name).metadata;
    meta = regexp(metadata,'[\w\.]+','match');
    %check if there 2 channels saved
    loc = find(ismember(meta, 'SI.hChannels.channelSave'));
    if str2double(meta{loc+2})==2 && useCh2template
        disp 'found red channel (2)'
        useCh2template = 1;
    else
        useCh2template = 0;
        disp 'no red channel'
    end
    %check how many ROIs there (and if mROI imaging)
    loc = find(ismember(meta, 'scanimage.mroi.Roi'));
    numROIs = length(loc);
    imgInfo.numROIs = numROIs;
    if numROIs>1
        disp 'mROI imaging detected'
    end
    %framerate
    loc = find(ismember(meta, 'SI.hRoiManager.scanFrameRate'));
    imgInfo.framerate = str2double(meta(loc+1));
    %Zoom angle
    loc = find(ismember(meta, 'SI.hRoiManager.scanZoomFactor'));
    imgInfo.opticalZoom = str2double(meta(loc+1));
    %is there a Ch2?
    if useCh2template
        imgStack = imgStack(:,:,2:2:end);
    end
else
    disp 'no type'
end
