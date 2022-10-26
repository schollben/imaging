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
date = '10082022';
filenum = 5;
stimulusfile = 6;                   %set to -1 if there is no stimulus presented (not needed for SCANIMAGE save data?)
stimInfo = [1.5 0 0];               %[duration prestim *slag*]
datatype = 'SCANIMAGE';                %BRUKER or SCANIMAGE 
saveLocation = 'D:\processed\';     %might change depending on machine
doNeuropil = 0;                     %extract neuropil signal for subtraction?
doResample = 1;                     %downsample dff?
is2pOpto = 0;                       %2pOpto

%%%%%%%%%%%%%%%%%%%%%%
%%get data locations
tic; folderList = gettargetFolders2(['D:\',datatype,'\'],date,filenum,'TSeries');

for k = 1:length(folderList)

    %reg folder location
    cd(['D:\',datatype,'\',folderList(k).name,'\Registered'])

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

            if strcmp(sROI{cc}.strType,'PolyLine') %DENDRITE ROI
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
            if ischar(imgInfo.framePeriod)
                ce(cc).framePeriod = str2double(imgInfo.framePeriod);
            else
                ce(cc).framePeriod = (imgInfo.framePeriod);
            end
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

            ce(cc).scale = 1 / 1;% imgInfo.micronsPerPixel(1);      % pixels per micron -> NEED TO ADD FOR SCANIMAGE DATA
            ce(cc).raw = [];
            ce(cc).raw_neuropil = [];
            
            fprintf('.')
        end
        ce(1).framePeriod = mean([ce.framePeriod]);
        toc

        if doNeuropil
            %transform neuropilmask
            neuropilmask = ~logical(neuropilmask);
            neuropil3dmask = ndSparse( repmat( neuropilmask , 1, 1, 1000));
        end

        %reg data folder location
        cd([cd,'\Channel1'])
        fileList = dir('*.tif');
        
        %%%%%%%%%%%
        %go through TIFF stacks
        disp 'load stacks and extract traces'
        for ff = 1:length(fileList)
            
            imgstack = ScanImageTiffReader(fileList(ff).name).data; fprintf('.') % <1 sec per 1000 frame stack

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
            if ff==1
                ce(1).img = squeeze(mean(imgstack,3))';
            end
            fprintf('.')
        end
        toc

        %%%%%%%%%%%
        disp 'calculate df/f for all ROIs'
        downsampvalue = 4;
        for cc = 1:length(ce)
            ce(cc).raw(1:30) = nan; %Bruker scope initial images are messed up
            if doResample
                dff = filterBaseline_dFcomp2(resample(ce(cc).raw,1,downsampvalue));
            else
                dff = filterBaseline_dFcomp2(ce(cc).raw,99*4);
            end
            ce(cc).dff = dff;
        end

        if doNeuropil
            %calculate df/f for neuropil trace
            if doResample
                dff = filterBaseline_dFcomp2(resample( ce(1).raw_neuropil , 1 , downsampvalue));
            else
                dff = filterBaseline_dFcomp2(ce(1).raw_neuropil);
            end
            ce(1).dff_neuropil = dff;
        end
        toc

        %%%%%%%
        if stimulusfile>-1

            disp 'grabbing two-photon frametimes'

            cd(['D:\',datatype,'\',folderList(k).name,'\'])

            if strcmp(datatype,'BRUKER')

                %get voltage recording (10kHz sampling)
                voltageFiles = dir('*.csv');
                if length(voltageFiles)>1
                    disp 'why is there multiple voltage files??'
                else
                    VoltageRecording_filename = voltageFiles(1).name;
                end
                Vrec = csvread(VoltageRecording_filename,2,1); %first row frame times, second row stimulus triggers

                frameTriggers = find( diff( Vrec(:,1) ) < -4); %first frame starts at 0?

                if frameTriggers(1) > 340 %(in 0.1 ms)
                    disp 'first 2p frame was dropped!'
                end
                [frameTriggers] = replaceMissingFrameTriggers(frameTriggers);

            elseif strcmp(datatype,'SCANIMAGE') %.h5 files from wavesurfer

                voltageFiles = dir('*.h5');
                if length(voltageFiles)>1
                    disp 'why is there multiple voltage files??'
                else
                    VoltageRecording_filename = voltageFiles(1).name;
                end
                Vrec = h5read(VoltageRecording_filename,['/sweep_',VoltageRecording_filename(end-6:end-3),'/analogScans']);
                Vrec = double(Vrec);

                temp = double( diff( Vrec(:,1)./abs(max(Vrec(:,1) ) ) ) );
                temp(temp>0) = 0;
                temp = abs(temp);
                [~,frameTriggers] = findpeaks(temp,'MinPeakDistance',200,'MinPeakHeight',0.1);
                temp = [];

            end

            disp(['number of frametriggers detected: ',num2str(length(frameTriggers))])
            ce(1).frameTriggers = frameTriggers;


            disp 'stimulus times and sync with two-photon'
            stimulusTriggers = medfilt1(Vrec(:,2),101);
            stimulusTriggers(stimulusTriggers<0) = 0;
            stimulusTriggers = diff(stimulusTriggers);
            [~,stimOn]=findpeaks(stimulusTriggers,'MinPeakDistance',1e3,'MinPeakHeight',max(stimulusTriggers) - max(stimulusTriggers)*.9);
            ce(1).stimOn = stimOn;
            [~,stimOff]=findpeaks(stimulusTriggers,'MinPeakDistance',1e3,'MinPeakHeight',max(stimulusTriggers) - max(stimulusTriggers)*.9);
            ce(1).stimOff = stimOff;

            if is2pOpto
                disp '2pOpto triggers'
                stimulusTriggers = medfilt1(Vrec(:,3),51);
                stimulusTriggers(stimulusTriggers<0) = 0;
                [~,photostimTrig]=findpeaks(stimulusTriggers,'MinPeakDistance',1e4,'MinPeakHeight',max(stimulusTriggers) - max(stimulusTriggers)*.9);
                ce(1).photostimTrig = photostimTrig;
            end

            cd(['D:\Pyschopy\',date(5:end),'-',date(1:2),'-',date(3:4)])
            pyschopyFile = readmatrix(['T',sprintf('%03d',stimulusfile),'.txt']);

            fidi = fopen(['T',sprintf('%03d',stimulusfile),'.txt'], 'rt');
            stimstr = textscan(fidi, '%s%s', 'CollectOutput',1);
            fclose(fidi)

            if ~is2pOpto

                stimID = pyschopyFile(:,1);
                ce(1).stimID = stimID;
                ce(1).stimstr = stimstr{1};
                uniqStims = unique(stimID);
                ce(1).uniqStims = uniqStims;

                ce(1).stimProperties = pyschopyFile(:,2:end);

            elseif is2pOpto

                stimID = pyschopyFile(:,3);
                ce(1).stimID = stimID;
                ce(1).stimstr = stimstr{1};
                uniqStims = unique(stimID);
                ce(1).uniqStims = uniqStims;

                ce(1).stimProperties = pyschopyFile(:,4:end);

                ce(1).targetNumber = pyschopyFile(:,1);

                ce(1).targetTrial = pyschopyFile(:,2);

            end

            if length(stimOn)~=length(stimID)
                disp 'mismatch between number of stimulus triggers and stimuli IDs'
            end

            %get stimOn2pFrame (frame where stimulus occured)
            stimOn2pFrame = [];
            for ss = 1:length(stimOn)
                [~,frameloc] = min(abs(stimOn(ss)-frameTriggers));
                stimOn2pFrame(ss) = frameloc;
            end
            ce(1).stimOn2pFrame = stimOn2pFrame;

            if is2pOpto
                TargetStim2pFrame = [];
                for ss = 1:length(photostimTrig)
                    [~,frameloc] = min(abs(photostimTrig(ss)-frameTriggers));
                    TargetStim2pFrame(ss) = frameloc;
                end
                ce(1).TargetStim2pFrame = TargetStim2pFrame;
            end

            %%%%%%%%%%%%%%%%%
            if doResample
                %need to modify effective framerate and stimOn2pFrame
                ce(1).framePeriod =  ce(1).framePeriod * downsampvalue;
                ce(1).stimOn2pFrame = floor( ce(1).stimOn2pFrame / downsampvalue);
                
                if is2pOpto
                    ce(1).TargetStim2pFrame = floor( ce(1).TargetStim2pFrame / downsampvalue);
                end

            end
        else
            disp 'no stimulus triggers recorded'
        end


        %%%%%%%%%%%
        %neuropil subtraction
        if doNeuropil
            NeuropilSubtraction();
        end

        %stimulus cyc generation - add peak response?
        genstimcyc(stimInfo); %SCANIMAGE rig slagged by 0.5 sec?

        %dendritic substraction
        DendriteSubtraction(1)        %argin = 1 - use full trace for subtraction, argin = 2 - use stimuli ('stimulus duration' periods)


        %extract some basic responses from cyc or cycRes
        if stimulusfile>-1
            for cc = 1:length(ce)
                if ~ce(cc).spine
                    [resp,resps,resperr] = computePeakResp(ce(cc).cyc);
                else
                    [resp,resps,resperr] = computePeakResp(ce(cc).cycRes);
                end
                ce(cc).resp = resp;
                ce(cc).resps = resps;
                ce(cc).resperr = resperr;
            end
        end

        %%%%%%%%%%%
        disp saving
        save([saveLocation,folderList(k).name,'.mat'],'ce','-mat','-v7.3')
    else
        disp 'no ROI.zip file or imgInfo mat file'
    end
end
disp finished



