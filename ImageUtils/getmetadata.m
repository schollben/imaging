% function getmetadata
% example:
%  [imgInfo] = getmetadata(datatype,fileList,folderList(k).name)
% note: Bruker and SI save channel 2 images differently. SI interleaves in
% image stack. Bruker saves individual images and they are ordered by name
% (starting with Ch1 i.e. red).

function [imgInfo,fileList] = getmetadata(datatype,foldername,fileList)

if strcmp(datatype,'BRUKER')

    imgInfo = readXmlFile_v2([foldername,'.XML']);
    if  imgInfo.PMTgain_ch01 > 0
        disp 'found red channel (channel 1 on bruker system)'
        imgInfo.isCh2 = true;
        %rearrange fileList to interleave Ch2 and Ch1
        %also reversing order of channels
        numFiles = length(fileList);
        vec = [numFiles/2+1:numFiles ; 1:numFiles/2];
        newvec = reshape(vec,1,numFiles);
        fileList = fileList(newvec);
    else
        imgInfo.isCh2 = false;
        disp 'no red channel'
    end

elseif strcmp(datatype,'SI')

    % NOTE- HAVE NOT EDITED THIS CODE YET

    metadata=ScanImageTiffReader(fileList(1).name).metadata;
    meta = regexp(metadata,'[\w\.]+','match');
    %check if there 2 channels saved
    loc = find(ismember(meta, 'SI.hChannels.channelSave'));
    if str2double(meta{loc+2})==2
        disp 'found red channel (2)'
        imgInfo.isCh2 = true;
    else
        imgInfo.isCh2 = false;
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
else
    disp 'no type'
end
