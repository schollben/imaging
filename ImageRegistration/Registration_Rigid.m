 %
% 2022-03-01

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% initialize params
downsampleRates = [1/16 1/8 1/4 1/2 1];
maxMovement = 1/8;
ChunkProcess = 0; %flag to apply shifts across batches of images
doimagSpatSamp = 0; %flag to use 0.5x downsampling
useCh2template = 0; %use Ch2 for registering (red/structural)
datatype = 'BRUKER'; %BRUKER or SI - (SI uses bigtiffreader and file names are different)

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%data location and folder(s)
%BRUKER files are MarkPoints or SingleImage or TSeries
%SI files are user-defined names
date = '02232022';
fnames = [1 3]; %MAKE MORE FLEXIBLE-> NEED TO BATCH PROCESS EVENTUALLY

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%find images and
cd(['D:\BRUKER\',date])
folderList = dir(['*TSeries*']); % EVENTUALLY WILL NEED TO EXAMINE MARKPOINTS AS WELL
for k = 1:length(folderList)
    folderListNames(k) = str2double(folderList(k).name(end-2:end));
end
[~,targetFolders]=ismember(fnames,folderListNames);

%%%%%%%%%%%%%%%%%%%%%%%%%%%
for k = targetFolders

    cd(['D:\BRUKER\',date,'\',folderList(k).name]);
    fileList = dir('*.tif');
    mkdir('Registered\Channel1');
    mkdir('Registered\Channel2');
    outputDirCh1 = [cd,'\Registered\Channel1'];
    outputDirCh2 = [cd,'\Registered\Channel2'];

    if strcmp(datatype,'BRUKER')
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %read in some metadata
        %NEED TO ADD HERE -> CHANNELS, Fs, ZOOM, ROIs
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %load some images for generating template
        %CURRENT SAVING SINGLE IMAGES NOT BATCHES
        imgStack = [];
        for frmn = 1:500
            imgStack(:,:,frmn) = ScanImageTiffReader(fileList(frmn+100).name).data;
        end
        %if useCh2template??
    elseif strcmp(datatype,'SI')
        % NOTE- HAVE NOT EDITED THIS CODE YET
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %read metadata
        metadata=ScanImageTiffReader([fileName,'/',files(1).name]).metadata;
        meta = regexp(metadata,'[\w\.]+','match');
        desc = [];
        %check if there 2 channels saved
        loc = find(ismember(meta, 'SI.hChannels.channelSave'));
        if str2double(meta{loc+2})==2
            disp 'found red channel (2)'
            useCh2template = 1;
        else
            useCh2template = 0;
            disp 'no red channel'
        end
        %check how many ROIs there (and if mROI imaging)
        loc = find(ismember(meta, 'scanimage.mroi.Roi'));
        numROIs = length(loc);
        desc.numROIs = numROIs;
        if numROIs>1
            disp 'mROI imaging detected'
        end
        %framerate
        loc = find(ismember(meta, 'SI.hRoiManager.scanFrameRate'));
        desc.framerate = str2double(meta(loc+1));
        %Zoom angle
        loc = find(ismember(meta, 'SI.hRoiManager.scanZoomFactor'));
        desc.zoom = str2double(meta(loc+1));
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %load an image stack to grab a template
        imgStack = ScanImageTiffReader(files(2).name).data;
        if useCh2template
            imgStack = imgStack(:,:,2:2:end);
        end
    else
        disp 'no type'
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    % generate a template using brightest images
    imgStack = squeeze(imgStack);
    dat = squeeze(squeeze(sum(sum(imgStack,1),2)));
    [~,id] = sort(dat);
    template = mean(imgStack(:,:,id(end-30:end)),3);
    if doimagSpatSamp==1
        template = imresize(template,.5,'bilinear');
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    %begin working files
    %batch load because BRUKER is single files and SI is ~1000 frame chunks
    %FIX THIS TO WORK WITH SI DATA TOO
    BatchSize = 50;
    batches={};
    for j = 1:ceil(length(fileList)/BatchSize)
        if j~=ceil(length(fileList)/BatchSize)
            batches{j} = BatchSize*(j-1)+1:BatchSize*j;
        else
            batches{j} = BatchSize*(j-1)+1:length(fileList);
        end
    end

    for j = 1:length(batches) 
        %build stack
        imgStack = [];
        for frmn = batches{j}
            imgStack = cat(3,imgStack,ScanImageTiffReader(fileList(frmn).name).data);
        end
        imgStack = squeeze(imgStack);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %2x spatial downsampling
        if doimagSpatSamp>0
            for frnum = 1:size(imgStack,3)
                im = squeeze(imgStack(:,:,frnum));
                if doimagSpatSamp==1
                    im = imresize(im,0.5);
                elseif doimagSpatSamp==0.5
                    im = imresize(im,[512 250]);
                end
                im(im<0) = 0;
                imgStack(1:size(imgStack,1)/2,1:size(imgStack,2)/2,frnum) = im;
            end
            imgStack = imgStack(1:size(imgStack,1)/2,1:size(imgStack,2)/2,:);
            disp(['spat resamp and thresh done'])
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %if using Ch2 for template
        if useCh2template
            ch1Stack = imgStack(:,:,1:2:end);
            imgStack = imgStack(:,:,2:2:end);
        end
        [height,width,depth] = size(imgStack);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%begin working files
        [imgStack,ch1Stack]=rigidReg(imgStack,template,ChunkProcess,useCh2template,downsampleRates,maxMovement);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %save some metadata
        %         save([fileName '\Registered\desc'],'desc') %FIX/UPDATE
        %save images outputDir - saving individual for virtual load in Fiji
        for frmn = 1:size(imgStack,3)

            filenameCh1 = [outputDirCh1 '\' sprintf('%06i', batches{j}(frmn) ) '.tif'];
            filenameCh2 = [outputDirCh2 '\' sprintf('%06i', batches{j}(frmn) ) '.tif'];

            if useCh2template

                imwrite(uint16(ch1Stack(:,:,frmn))',filenameCh1,'tif');
                imwrite(uint16(imgStack(:,:,frmn))',filenameCh2,'tif');

            else

                imwrite(uint16(imgStack(:,:,frmn))',filenameCh1,'tif');

            end
        end
        disp(['Saved Images: ',outputDirCh1]);
    end
end












