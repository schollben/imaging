%% loads stimulus and two photon timing data with Miji 

%%%%%%%%%%%%%%%%%%%%%%
datatype = 'BRUKER'; %BRUKER or SI - (SI uses bigtiffreader and file names are different)
date = '02232022';
filenum = 1;

depth = 0; 
pathlength = 0; 
denType = 'basal'; 
scale = 0; %pixel per microns
%%%%%%%%%%%%%%%%%%%%%%

date2p = monthChange(date);
temp = ['open=M:\\',date2p,'\\t',sprintf('%.5d',file2p),'\\Registered\\Channel1\\000001.tif sort'];
MIJ.run('Image Sequence...', temp);
MIJ.run('Z Project...', 'projection=[Standard Deviation]');

%% Run this cell after labeled ROIs

%init folder locations
folderDir = ['D:\processed\',datatype,'\'];
name = ['file',sprintf('%.5d',filenum)];
savedir = [folderDir,date,'\'];
savefilename = [savedir,name];
saveROIset = [savedir,'ROIs\',name,'.zip'];
mkdir(savedir)
mkdir([folderDir,date,'\ROIs'])

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


%dendritic subtraction
for cc = 1:length(ce)
    if ce(cc).spine
        %find dendrite
        dendPoint = cc;
        while ~ce(dendPoint).dendrite
            dendPoint = dendPoint+1;
        end
        Spdff = ce(cc).dff;
        Spdff = Spdff(1:round(length(Spdff)*.9));
        Spdff(isinf(Spdff)) = 0;
        Spdff_sub = Spdff(Spdff < nanmedian(Spdff)+abs(min(Spdff)));
        noiseM = nanmedian(Spdff_sub); % should be near 0
        noiseSD = nanstd(Spdff_sub);
        spcyc = ce(cc).cyc(:);
        spcyc(isnan(spcyc)) = 0;
        slope = robustfit(ce(dendPoint).cyc(:),spcyc);
        %dendritic scalar applied (from robust fit) to cyc and subtraction
        ce(cc).slope = slope(2);
        
        ce(cc).cycRes = ce(cc).cyc - slope(2).*ce(dendPoint).cyc;
        ce(cc).cycRes(ce(cc).cycRes < 0) = 0;

        r = ce(cc).dff - slope(2).*ce(dendPoint).dff;

        ce(cc).dffRes = r;
        
        rSp =  ce(cc).dff;
        rDn =  ce(dendPoint).dff;
        rSp = rSp - slope(2).*rDn;
        rSp(rSp < -noiseSD) = -noiseSD;
        rSp(isinf(rSp)) = 0;
        rDn(isinf(rDn)) = 0;
        ce(cc).rawRes = rSp;
        rSp(rSp <= 0) = nan;
        rDn(rDn <= 0) = nan;
        r = corrcoef(rSp,rDn,'rows','pairwise');
        ce(cc).corr = r(2);
    else
        ce(cc).cycRes = [];
        ce(cc).slope = [];
        ce(cc).corr = -1;
    end
end


%save ce struct to processed data stream for later
saveMijiData(savefilename)
clc
disp done

