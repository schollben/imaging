% code to use rigid registration with parallel toolbox
% usually used to register cellular imaging data
% usually used for large datasets
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
parpool
%% initialize params
downsampleRates = [1/16 1/8 1/4 1/2 1];
maxMovement = 1/8;
ChunkProcess =   0; %flag to apply shifts across batches of images
doimagSpatSamp = 0; %flag to use 0.5x downsampling
useCh2template = 1; %use Ch2 for registering (red/structural)
datatype = 'BRUKER'; %BRUKER or SCANIMAGE - (SCANIMAGE uses bigtiffreader and file names are different)
%%%%%%%
ImageVol = 71; %number of slices NEED TO AUTOMATE
%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%data location and folder(s)
%BRUKER files are MarkPoints or SingleImage or TSeries
%SCANIMAGE files are user-defined names - but aiming to label as 'TSeries-date-xxx'
DATES{1} = '10262022'; FNAMES{1} = [10 1:4 6:9];
for sesh = 1:length(DATES)
date = DATES{sesh};
fnames = FNAMES{sesh};
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%find image location
organizeSCANIMAGEFiles();
folderList = gettargetFolders2(['D:\',datatype],date,fnames,'TSeries');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for k = 1:length(folderList)
    tic;
    cd(['D:\',datatype,'\',folderList(k).name]);
    fileList = dir('*.tif');
    mkdir('Registered\Channel1');
    mkdir('Registered\Channel2');
    outputDir = [cd,'\Registered'];
    outputDirCh1 = [cd,'\Registered\Channel1'];
    outputDirCh2 = [cd,'\Registered\Channel2'];

    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    %read in some metadata
    [imgInfo,fileList] = getmetadata(datatype,folderList(k).name,fileList);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    %load file to generate template
    imgStack = ScanImageTiffReader(fileList(1).name).data;
    
    [sizeX,sizeY,depth] = size(imgStack);
    imgInfo.sizeX = sizeX;
    imgInfo.sizeY = sizeY;

    singleimages = 0;
    if depth==1
        
        singleimages = 1; %flag used later

        if length(fileList)<1000
            mFrames = length(fileList);
        else
            mFrames = 1000;
        end
        
        for frmn = 1:mFrames
            imgStack(:,:,frmn) = ScanImageTiffReader(fileList(frmn).name).data;
        end   
    end

    if useCh2template && imgInfo.isCh2
%         imgStack = imgStack(:,:,ImageVol+1:ImageVol*2);
%     elseif ~useCh2template && imgInfo.isCh2
        imgStack = imgStack(:,:,1:ImageVol);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    % generate a template using brightest images
    imgStack = squeeze(imgStack);
    template = mean(imgStack,3);
    if doimagSpatSamp==1
        template = imresize(template,.5,'bilinear');
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    %generate batches to process

    batches={};
    if singleimages==1

        BatchSize = ImageVol*2;

        for j = 1:ceil(length(fileList)/BatchSize)
            if j~=ceil(length(fileList)/BatchSize)
                batches{j} = BatchSize*(j-1)+1:BatchSize*j;
            else
                batches{j} = BatchSize*(j-1)+1:length(fileList);
            end
        end
    
    else
    
        for j = 1:length(fileList)
            batches{j} = j;
        end
    
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%begin working files
    if (strcmp(datatype,'SCANIMAGE') && (depth>=500)) || (strcmp(datatype,'BRUKER'))
        parfor j = 1:length(batches)

            %build stack
            imgStack = [];
            ch1Stack = [];
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
%                 ch1Stack = imgStack(:,:,1:2:end);
%                 imgStack = imgStack(:,:,2:2:end);
%             else
                ch1Stack = imgStack(:,:,ImageVol+1:ImageVol*2);
                imgStack = imgStack(:,:,1:ImageVol);
            end
            [height,width,depth] = size(imgStack);

            %%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%begin working files
            [imgStack,ch1Stack]=rigidReg(imgStack,ch1Stack,template,ChunkProcess,useCh2template,downsampleRates,maxMovement);

            %%%%%%%%%%%%%%%%%%%%%%%%%%%
            %save images outputDir
            filenameCh1 = [outputDirCh1 '\' sprintf('%06i', j ) '.tif'];
            filenameCh2 = [outputDirCh2 '\' sprintf('%06i', j ) '.tif'];
            for frmn = 1:size(imgStack,3)

                if frmn == 1
                    if useCh2template
%                         imwrite(uint16(ch1Stack(:,:,frmn))',filenameCh1,'tif','write','overwrite','compression','none')
%                         imwrite(uint16(imgStack(:,:,frmn))',filenameCh2,'tif','write','overwrite','compression','none')
%                     else
                        imwrite(uint16(imgStack(:,:,frmn))',filenameCh1,'tif','write','overwrite','compression','none')
                        imwrite(uint16(ch1Stack(:,:,frmn))',filenameCh2,'tif','write','overwrite','compression','none')
                    end
                else
                    if useCh2template
%                         imwrite(uint16(ch1Stack(:,:,frmn))',filenameCh1,'tif','write','append','compression','none')
%                         imwrite(uint16(imgStack(:,:,frmn))',filenameCh2,'tif','write','append','compression','none')
%                     else
                        imwrite(uint16(imgStack(:,:,frmn))',filenameCh1,'tif','write','append','compression','none')
                        imwrite(uint16(ch1Stack(:,:,frmn))',filenameCh2,'tif','write','overwrite','compression','none')
                    end
                end
            end
        end
        save([outputDir,'\imgInfo'],'imgInfo')
        toc
    end
end
end
delete(gcp)











