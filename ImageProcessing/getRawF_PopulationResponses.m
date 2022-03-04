%%loads stimulus and two photon timing data with Miji
%%POPULATION VER
file2p  = 12
fileSpk = 14
date = '2019-02-04';
date2 = '2019-02-04'; 

useLessTrials = 0;    
neuropilflag = 0; 
prestimPeriod = 0;    
stimDur = 2;  
postPeriod = 1;   
resamp = 0;

date2p = monthChange(date);
% temp = ['open=O:\\', date2p,'\\t',sprintf('%.5d',file2p),'\\Result\\000001.tif sort'];
temp = ['open=O:\\', date2p,'\\t',sprintf('%.5d',file2p),'\\Registered\\Channel1\\000001.tif sort'];
MIJ.run('Image Sequence...', temp);
MIJ.run('Z Project...', 'projection=[Standard Deviation]');
%% initialize, draw ROI, then run

%set up file/folder names
Spk2dir = ['C:\Spike2Data\',date2,'\'];
folderDir = 'O:\Population\processed\';

name = ['t',sprintf('%.5d',file2p)];
savedir = [folderDir,date2p,'\'];
savefilename = [savedir,name];
saveROIset = [savedir,'ROIs\',name,'.zip'];

%check if directories exist
if ~exist(savedir,'dir')
    mkdir(savedir)
end
if ~exist([folderDir,date2p,'\ROIs'],'dir')
    mkdir([folderDir,date2p,'\ROIs'])
end

%load header file
%%%%%%%%%%%%%%%load(['M:\',date2,'\',name,'\header.mat'])
%get spike2 info
cd([Spk2dir,'t',sprintf('%.5d',fileSpk)])
twophotontimes = load('frametrigger.txt');
S = load('stimontimes.txt');
stimOn = S(2:2:length(S));
stimID = S(1:2:length(S)-1);

% Check to see if the first StimID is 0.  if it is, then delete it
% (initialization error with serial port in psychopy)
if stimID(1)==0
    stimOn(1) = [];
    stimID(1) = [];
end

if sum(stimID==0)>1 %if you make a mistake and 0 is a stim code
    stimID = stimID+1;
end

% f1 = fopen('stimtimes.txt', 'r');
% ST = fscanf(f1, '%f');
uniqStims = unique(stimID);
disp(['Loaded ', num2str(length(uniqStims)), ' unique stimCodes.'])
disp(['Loaded ', num2str(length(stimOn)), ' stim on times'])
preVisStim = find( twophotontimes < stimOn(1));
% twophotontimes = twophotontimes(1:4:end); %comment this out for single
% plane imaging
global ce
ce = [];
ce(1).twophotontimes = twophotontimes;
ce(1).copyStimID = stimID;
ce(1).copyStimOn = stimOn;
ce(1).uniqStims = uniqStims;


%%Get MIJ, get ROI manager
import ij.*;
import ij.IJ.*;
RM = ij.plugin.frame.RoiManager();
RC = RM.getInstance(); % get open instance of ROI manager in imagej
%save ROI set 
RC.runCommand('Save',saveROIset)
%load ROI set to get relevant info
[sROI] = ReadImageJROI(saveROIset);
numROIs = size(sROI,2); %total number of ROIs

%grab standard deviation structure and close image
struct = MIJ.getCurrentTitle;
selectWindow(struct);
img = MIJ.getCurrentImage;
run('Close')

disp('going through ROIs')
for i = 1:numROIs
    
    %save ROI and associated information
    ce(i).yPos =  median(sROI{i}.mnCoordinates(:,2));
    ce(i).xPos =  median(sROI{i}.mnCoordinates(:,1));
    ce(i).mask = sROI{i}.mnCoordinates;
    ce(i).date = date2p;
    ce(i).file = name;

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
    
    %filter and downsample and compute dF/F
    ce(i).raw = raw;
    
    if i==1
        % take the avg of first 10 frames to give actual img rate
        ce(1).scanPeriod = mean(diff(ce(1).twophotontimes(1:10)));
        ce(1).rate = 1/ce(1).scanPeriod;
        ce(i).img = img;
    end
    clear CurrentROI
   
end

if neuropilflag
neuropilRois = generateNeuropilROIs(25);
disp('going through ROI neuropils')
for i = 1:numROIs
    
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
    
    %filter and downsample and compute dF/F
    ce(i).neuropilraw = raw;

    clear CurrentROI

end
end

scanPeriod = 0.0341;
ce(1).scanPeriod = scanPeriod;
prestimPeriod2 = ceil(prestimPeriod./scanPeriod);
stimDur2 = ceil(stimDur./scanPeriod);
postPeriod2 = ceil(postPeriod./scanPeriod);

stimID = ce(1).copyStimID;
stimOn = ce(1).copyStimOn;
uniqStims = ce(1).uniqStims;
twophotontimes = ce(1).twophotontimes;

if sum(uniqStims==0)==1
    uniqStims = uniqStims(2:end);
end

ntrials = floor(length(stimOn)/length(uniqStims));
ntrials = ntrials-useLessTrials;

numStims = ntrials*length(uniqStims);
stimOn2pFrame = zeros(1,numStims);


%convert stim times into frame times
for ii = 1:numStims
    id1 = stimOn(ii)<twophotontimes;
    id2 = stimOn(ii)>twophotontimes;
    ind = id1.*id2;
    ind = find(ind==1);
    if ~isempty(ind)
        stimOn2pFrame(ii) = ind;
    else
        stimOn2pFrame(ii) = find(diff(id1)==1);
    end
end

if resamp
    %downsample 4x
    stimOn2pFrame = floor(stimOn2pFrame./4);
    prestimPeriod2 = round(prestimPeriod2./4);
    stimDur2 = round(stimDur2./4);
    postPeriod2 = round(postPeriod2./4);
end

disp 'Cutting up data based off stimIDs...'
for cc = 1:length(ce) 
    %downsample and filter raw trace
    if resamp
        raw = filterBaseline_dFcomp(resample(ce(cc).raw,1,4));
    else
        raw = filterBaseline_dFcomp(ce(cc).raw,99*4);
    end
    ce(cc).df_f_resamp_raw = raw;
    ce(cc).cyc = zeros(length(uniqStims),ntrials,(stimDur2+postPeriod2));
    if neuropilflag
        neuropilraw = filterBaseline_dFcomp(resample(ce(cc).neuropilraw,1,4));
        ce(cc).df_f_resamp_neuropilraw = neuropilraw;
        ce(cc).cycneuropil = zeros(length(uniqStims),ntrials,(stimDur2+postPeriod2));
    end
    ce(cc).stimOn2pFrame = stimOn2pFrame;
    %go through stims
    trialList = zeros(1,length(uniqStims));
    for ii = 1:numStims     
        prestimTime2 = stimOn2pFrame(ii)-prestimPeriod2:stimOn2pFrame(ii);
        stimTime2 = stimOn2pFrame(ii)+1:stimOn2pFrame(ii)+stimDur2+postPeriod2;
        
        ind = stimID(ii); 
        trialList(ind) = trialList(ind)+1;                 
        ce(cc).cyc(ind,trialList(ind),:) = raw(stimTime2)' - mean(raw(stimTime2(1:2)));
        
        if neuropilflag
            ce(cc).cycneuropil(ind,trialList(ind),:) = neuropilraw(stimTime2)';
        end
    end   
    fprintf(num2str(cc))
end
%save ce struct to processed data stream for later
saveMijiData(savefilename)
clc
disp done







