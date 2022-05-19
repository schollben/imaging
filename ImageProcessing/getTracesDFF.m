% Script for extracting signals from ROIs defined by ImageJ from image
% stacks collected by Scanimge or Bruker Software
%
%
% to add later (for spine imaging):
% depth = 0; 
% pathlength = 0; %distance from soma
% denType = 'basal'; 
% scale = 0; %pixel per microns
%%%%%%%%%%%%%%%%%%%%%%

%%initialize params
date = '02232022';
filenum = 1;
datatype = 'BRUKER';            %BRUKER or SI 
saveLocation = 'D:\processed\'; %might change depending on machine
doNeuropil = 0;                 %extract neuropil signal for subtraction?
tic;

%%%%%%%%%%%%%%%%%%%%%%
%%get data locations
folderList = gettargetFolders(['D:\',datatype,'\',date],filenum);

for k = 1:length(folderList)

    %reg folder location
    cd(['D:\',datatype,'\',date,'\',folderList(k).name,'\Registered'])

    %%%%%%%%%%%
    %load RoiSet.zip
    if exist('RoiSet.zip','file')
        [sROI] = ReadImageJROI('RoiSet.zip');
        numCells = length(sROI);

        % locate any dendrite ROIs
        locatedDendriteROI = 0;
        for cc = 1:numCells
            if strcmp(sROI{cc}.strType,'PolyLine')
                locatedDendriteROI = 1;
            end
        end
    end
        
    %%%%%%%%%%%
    %load imgInfo
    if exist('imgInfo.mat','file')
        load imgInfo
        if ~isfield(imgInfo,'sizeX')
            imgInfo.sizeX = 512;
            imgInfo.sizeY = 512;
        end
    end

    %%%%%%%%%%%
    if exist('sROI','var') && exist('imgInfo','var')

        disp 'build ce struct and generate sparse masks'
        global ce
        ce = [];
        maskstruct = [];
        neuropilmask = zeros(imgInfo.sizeX,imgInfo.sizeY);
        [x,y]=meshgrid(1:imgInfo.sizeX,1:imgInfo.sizeY);
        for cc = 1:numCells

            nmCoord = sROI{cc}.mnCoordinates;

            if ~strcmp(sROI{cc}.strType,'PolyLine')
                %dendrite ROI
                mask2d = genPolyLineROI(nmCoord,sROI{cc}.nStrokeWidth);
            else
                mask2d = inpolygon( x, y, nmCoord(:,1), nmCoord(:,2));
            end
            neuropilmask = neuropilmask + mask2d;
            sparse3dmask = ndSparse( repmat( mask2d , 1, 1, 1000)); %expect 1000-frame stacks
            maskstruct(cc).mask = sparse3dmask;

            ce(cc).yPos =  median(nmCoord(:,2));
            ce(cc).xPos =  median(nmCoord(:,1));
            ce(cc).celloutline = nmCoord;
            ce(cc).mask2d = sparse(mask2d);
            ce(cc).date = date;
            ce(cc).file = filenum;
            ce(cc).framePeriod = imgInfo.framePeriod;
            ce(cc).opticalZoom = imgInfo.opticalZoom;

            ce(cc).soma = (strcmp(sROI{cc}.strType,'Freehand') | strcmp(sROI{cc}.strType,'Oval')) ...
                & ~locatedDendriteROI;                          %magicwand or circle/oval ROI label
            ce(cc).dendrite = strcmp(sROI{cc}.strType,'PolyLine') ...
                & locatedDendriteROI;                           %segmented line ROI label
            ce(cc).spine = strcmp(sROI{cc}.strType,'Freehand') & ...
                locatedDendriteROI;  %magicwand ROI label

            ce(cc).dendriteSegment = [];                        %keep track of multiple segments
            ce(cc).denType = [];                                %defined by user from looking at cell
            ce(cc).pathlength = [];                             %distance from soma (measured with Fiji and z stack)
            ce(cc).depth = [];                                  %imgInfo.Zdepth; %distance from surface
            ce(cc).img = [];

            ce(cc).scale = 1 / imgInfo.micronsPerPixel(1);      % pixels per micron -> need to add for SI
            ce(cc).raw = [];
            ce(cc).raw_neuropil = [];
            
            fprintf('.')
        end
        toc

        if doNeuropil
            %transform neuropilmask
            neuropilmask = ~logical(neuropilmask);
            neuropil3dmask = ndSparse( repmat( neuropilmask , 1, 1, 1000));
        end

        %reg data folder location
        cd([cd,'\Channel1'])
        fileList = dir('*.tiff');
        
        %%%%%%%%%%%
        %go through tiff stacks
        disp 'load stacks amd extract traces...'
        for ff = 1:length(fileList)
            
            imgstack = ScanImageTiffReader(fileList(ff).name).data; fprintf('.') % < 1 sec per 1000 frame stack

            for cc = 1:numCells
                ftrace = mean( reshape (imgstack(  maskstruct(cc).mask(:,:,1:size(imgstack,3)) ), length(find(ce(cc).mask2d)) , size(imgstack,3) , 1));
                ce(cc).raw = cat(1, ce(cc).raw, ftrace');
            end
            
            if doNeuropil
                %neuropil trace
                %only added to ce(1)
                ftrace = mean( reshape (imgstack( neuropil3dmask(:,:,1:size(imgstack,3)) ), length(find(neuropilmask)) , size(imgstack,3), 1));
                ce(1).raw_neuropil = cat(1, ce(1).raw_neuropil, ftrace');
            end

            %save sample image
            %only added to ce(1)
            if ff == 1
                ce(cc).img = squeeze(mean(imgstack,3));
            end
            fprintf('.')
        end
        toc

        %%%%%%%%%%%
        disp 'calculate df/f for all ROIs - downsampled 4x'
        for cc = 1:length(ce)
            dff = filterBaseline_dFcomp2(resample( ce(cc).raw , 1 , 4));
            ce(cc).dff = dff;
        end

        if doNeuropil
            %calculate df/f for neuropil trace
            dff = filterBaseline_dFcomp2 (resample( ce(cc).raw_neuropil , 1 , 4));
            ce(cc).dff_neuropil = dff;
        end
        toc

        %%%%%%%%%%%
        %dendritic substraction
        %argin = 1 - use full trace for subtraction
        %argin = 2 - use stimuli ('cyc' periods)
        DendriteSubtraction(1)

        %neuropil subtraction - TO ADD
        
        %save
        save([saveLocation,folderList(k).name,'.mat'],'ce','-mat','-v7.3')
    end
    disp 'no ROI.zip file or imgInfo mat file'
end
disp finished



