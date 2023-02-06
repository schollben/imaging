% code to use NormCorre nonrigid registration
% usually used to register dendrite/spine imaging data
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% initialize parallel
clear 
parpool
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% initialize params
niter = 1; %number of iterations (can increase to help improve registration)
gridWidth = 64; %decrease for better registration (in pixel)
gridHeight = 64; %decrease for better registration (in pixel)
op = 16; %grid overlap (in pixel)
%see more NormCorre parameters below
doimagSpatSamp = 0; %flag to use 0.5x downsampling
useCh2template = 0; %use Ch2 for registering (red/structural)
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%find image location and setup

date = '11302022'; %date of the recording

dataLocation = 'D:\TestData\'; %where is each set of folders to register

datatype = 'BRUKER'; %microscope type (used to handle images and read XML metadata)

folderList = gettargetFolders2(dataLocation,date);

%where to save the data
cd(dataLocation)
mkdir('Registered\Channel1');
mkdir('Registered\Channel2');
outputDir = [cd,'\Registered'];
outputDirCh1 = [cd,'\Registered\Channel1'];
outputDirCh2 = [cd,'\Registered\Channel2'];
filenameCh1 = [outputDirCh1, '\Ch1Stack.tif'];
filenameCh2 = [outputDirCh2, '\Ch2Stack.tif'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% generate master template

template = [];
tic;
for k = 1:length(folderList)
        cd( [dataLocation, folderList(k).name] );
    fileList = dir('*.tif');
    for frmn = 1:length(fileList)
        img = ScanImageTiffReader(fileList(frmn).name).data;
        template = cat(3,template,img);
    end
end
template = squeeze(mean(template,3));
toc;
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
masterStackCh1 = [];
masterStackCh2 = [];
for k = 1:length(folderList)

    cd( [dataLocation, folderList(k).name] );
    fileList = dir('*.tif');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    %read in some metadata
    [imgInfo,fileList] = getmetadata(datatype,folderList(k).name,fileList);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    %begin working files
    tic;
    %build stack
    imgStack = [];
    for frmn = 1:length(fileList)
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
    options_rigid.use_parallel = 1; % set to '0' or false if dont have toolbox
    %Run
    disp('running NoRMCorre')
    [imgStack,shifts,~] = normcorre(imgStack,options_rigid,template);
    %apply Ch2 shifts to Ch1
    if useCh2template
        ch1Stack = apply_shifts(ch1Stack,shifts,options_rigid);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    if useCh2template
        masterStackCh1(:,:,k) = squeeze(mean(imgStack,3));
        masterStackCh2(:,:,k) = squeeze(mean(ch1Stack,3));
    else
        masterStackCh2(:,:,k) = squeeze(mean(imgStack,3));
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    %save images outputDir
    if k == 1
        if useCh2template
            imwrite(uint16(masterStackCh1(:,:,k))',filenameCh1,'tif','write','overwrite','compression','none')
            imwrite(uint16(masterStackCh2(:,:,k))',filenameCh2,'tif','write','overwrite','compression','none')
        else
            imwrite(uint16(masterStackCh2(:,:,k))',filenameCh2,'tif','write','overwrite','compression','none')
        end
    else
        if useCh2template
            imwrite(uint16(masterStackCh1(:,:,k))',filenameCh1,'tif','write','append','compression','none')
            imwrite(uint16(masterStackCh2(:,:,k))',filenameCh2,'tif','write','append','compression','none')
        else
            imwrite(uint16(masterStackCh2(:,:,k))',filenameCh2,'tif','write','append','compression','none')
        end
    end
end

disp(['Saved Images: ',outputDirCh1]);
save([outputDir,'\imgInfo'],'imgInfo')
toc;
