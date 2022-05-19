%
%
%
%
%%%%%%%%%%%%%%%%%%%%%%

%%initialize params
datatype = 'BRUKER'; %BRUKER or SI - (SI uses bigtiffreader and file names are different)
date = '02232022';
filenum = 1;
doNeuropil = 0;
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
                locatedDendriteROI = ~locatedDendriteROI;
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
        for cc = 1:numCells

            nmCoord = sROI{cc}.mnCoordinates;
            [x,y]=meshgrid(1:imgInfo.sizeX,1:imgInfo.sizeY);
            mask2d = inpolygon( x, y, nmCoord(:,1), nmCoord(:,2));
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
            if ff == 1 && (ce(cc).soma==1 || ce(cc).dendrite)
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
        DendriteSubtraction

        %neuropil subtraction - TO ADD
        
    end
end
disp finished

%%%%%%%%%%%%%%%%%%%%%%















%%
%init ce struct
global ce
ce = [];

%get MIJ, get ROI manager
import ij.*;
import ij.IJ.*;
RM = ij.plugin.frame.RoiManager();
RC = RM.getInstance(); % get open instance of ROI manager in imagej
%save ROI set
RC.runCommand('Save',saveROIset)
%load ROI set to get relevant info
[sROI] = ReadImageJROI(saveROIset);
numROIs = size(sROI,2); %total number of ROIs
ROISegNum = zeros(numROIs,1); %keep track of dendritic segment number
isDendrite = zeros(numROIs,1); %keep track of dendritic ROIs
currentDendrite = 1;
for n = 1:numROIs
    ROISegNum(n) = currentDendrite;
    if strcmp(sROI{n}.strType,'PolyLine') %strType for straightening
        isDendrite(n) = 1;
        %assumes last ROI in each segment is the dendrite
        currentDendrite = currentDendrite + 1;
    end
end

% %grab standard deviation structure and close image
% struct = MIJ.getCurrentTitle;
% selectWindow(struct);
% img = MIJ.getCurrentImage;
% run('Close')

disp('going through ROIs')
for i = 1:numROIs
    
    %save ROI and associated information
    ce(i).yPos =  median(sROI{i}.mnCoordinates(:,2));
    ce(i).xPos =  median(sROI{i}.mnCoordinates(:,1));
    ce(i).depth = depth;
    ce(i).mask = sROI{i}.mnCoordinates;
    ce(i).date = date;
    ce(i).file = filenum;
    
    if numROIs==1
        ce(i).soma = 1;
        ce(i).dendrite = 0;
        ce(i).spine = 0;
        ce(i).segment = 0;
        ce(i).img = img;
    else
        ce(i).dendrite = isDendrite(i);
        ce(i).spine = ~isDendrite(i);
        ce(i).segment = ROISegNum(i);
        
        ce(i).pathlength = pathlength;
        ce(i).denType = denType;
        ce(i).scale = scale;
    end
    
    if isDendrite(i)
        ce(i).img = img;
    end
    
    RC.select(i-1);
    currentROI = MIJ.getRoi(i-1);
    MIJ.run('Plot Z-axis Profile');
    MIJ.run('Close','');
    raw = MIJ.getResultsTable;
    %need this flag for line segments: [mean, length]
    if size(raw,2)>1
        raw = raw(:,1);
    end
    MIJ.run('Clear Results');
    
    ce(i).raw = raw;

    clear CurrentROI
end
   %%     

%downsample 4x and get df/f cycles
if doresamp==1
    stimOn2pFrame = floor(stimOn2pFrame./4);
    stimDur2 = round(stimDur2/4);
    postPeriod2 = round(postPeriod2/4);
    prePeriod2 = round(prePeriod2/4);
end

disp 'Cutting up data based off stimIDs'
for cc = 1:length(ce)
    
    ce(cc).cyc = zeros(length(uniqStims),ntrials,stimDur2+prePeriod2+postPeriod2);
    ce(cc).stimOn2pFrame = stimOn2pFrame;
    
    raw = ce(cc).raw;
    if doresamp==1
        dff = filterBaseline_dFcomp2(resample(raw,1,4));
    else
        dff = filterBaseline_dFcomp2(raw);
    end
    ce(cc).dff = dff;
    
    trialList = zeros(1,length(uniqStims));
    for ii = 1:numStims
        stimTime2 = stimOn2pFrame(ii)-prePeriod2+1:stimOn2pFrame(ii)+stimDur2+postPeriod2;
        ind = find(uniqStims==stimID(ii));
        trialList(ind) = trialList(ind)+1;
        if stimTime2(end) < length(dff)
            f = dff(stimTime2);
        else
            f = NaN(length(stimTime2),1);
        end
        ce(cc).cyc(ind,trialList(ind),:) = f;
    end
    fprintf(num2str(cc))
end




%save ce struct to processed data stream for later
saveMijiData(savefilename)
clc
disp done

% % for spine imaging
% depth = 0; 
% pathlength = 0; %distance from soma
% denType = 'basal'; 
% scale = 0; %pixel per microns

