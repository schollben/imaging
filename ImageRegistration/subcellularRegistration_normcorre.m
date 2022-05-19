% code to use NormCorre nonrigid registration
% usually used to register dendrite/spine imaging data
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%initialize parallel
clear 
delete(gcp)
parpool
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%initialize params
niter = 1; %number of iterations
gridWidth = 256; %decrease for better registration (in px)
gridHeight = 256; %decrease for better registration (in px)
op = 32; %grid overlap
%see more NormCorre parameters below
doimagSpatSamp = 0; %flag to use 0.5x downsampling
useCh2template = 0; %use Ch2 for registering (red/structural)
datatype = 'BRUKER'; %BRUKER or SI
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%data location and folder(s)
%BRUKER files are MarkPoints or SingleImage or TSeries
%SI files are user-defined names
date = '02232022';
fnames = [1]; 
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%find image location
folderList = gettargetFolders(['D:\',datatype,'\',date],fnames);
%%%%%%%%%%%%%%%%%%%%%%%%%%%
for k = 1:length(folderList)

    cd(['D:\',datatype,'\',date,'\',folderList(k).name]);
    fileList = dir('*.tif');
    mkdir('Registered\Channel1');
    mkdir('Registered\Channel2');
    outputDir = [cd,'\Registered'];
    outputDirCh1 = [cd,'\Registered\Channel1'];
    outputDirCh2 = [cd,'\Registered\Channel2'];

    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    %read in some metadata
    [imgInfo,fileList] = getmetadata(datatype,fileList,folderList(k).name);

    %check to see if single images saved or stacks of images. assuming that
    %there would never be 100 stacks. (e.g. SI set to save stacks of 100 images)
    if length(fileList)>1000
        singleimages = 1;
    else
        singleimages = 0;
    end

    %load some images for generating template
    imgStack = [];
    if singleimages==1
        for frmn = 1:1000
            imgStack(:,:,frmn) = ScanImageTiffReader(fileList(frmn+100).name).data;
        end
    else
        imgStack = ScanImageTiffReader(fileList(1).name).data;
    end

    [sizeX,sizeY,~] = size(imgStack);
    imgInfo.sizeX = sizeX;
    imgInfo.sizeY = sizeY;
    
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

    if singleimages==1
        BatchSize = 1000;
        batches={};
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

    for j = 1:length(batches)
        tic;
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
        %NoRMCorreSetParms
        options_rigid = NoRMCorreSetParms('d1',size(imgStack,1),'d2',size(imgStack,2),'grid_size',[gridWidth,gridHeight],'overlap_pre',op,'bin_width',50,'max_shift',100,'us_fac',50,'iter',niter);
        options_rigid.use_parallel = 1;
        %Run
        disp('running NoRMCorre')
        [imgStack,shifts,~] = normcorre(imgStack,options_rigid,template);
        %apply Ch2 shifts to Ch1
        if useCh2template
            ch1Stack = apply_shifts(ch1Stack,shifts,options_rigid);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %save some metadata
        %FIX/UPDATE/ADD
        %save([fileName '\Registered\desc'],'desc') %FIX/UPDATE

        %save images outputDir
        for frmn = 1:size(imgStack,3)

            filenameCh1 = [outputDirCh1 '\' sprintf('%06i',j) '.tif'];
            filenameCh2 = [outputDirCh2 '\' sprintf('%06i',j) '.tif'];

            if frmn == 1
                if useCh2template
                    imwrite(uint16(ch1Stack(:,:,frmn))',filenameCh1,'tif','write','overwrite','compression','none')
                    imwrite(uint16(imgStack(:,:,frmn))',filenameCh2,'tif','write','overwrite','compression','none')
                else
                    imwrite(uint16(imgStack(:,:,frmn))',filenameCh1,'tif','write','overwrite','compression','none')
                end
            else
                if useCh2template
                    imwrite(uint16(ch1Stack(:,:,frmn))',filenameCh1,'tif','write','append','compression','none')
                    imwrite(uint16(imgStack(:,:,frmn))',filenameCh2,'tif','write','append','compression','none')
                else
                    imwrite(uint16(imgStack(:,:,frmn))',filenameCh1,'tif','write','append','compression','none')
                end
            end
        end

        disp(['Saved Images: ',outputDirCh1]);
        toc;
    end
    save([outputDir,'\imgInfo'],'imgInfo')
end
clear 
delete(gcp)
