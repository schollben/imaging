% Script for extracting signals from ROIs defined by ImageJ from image
% stacks collected by Scanimge or Bruker Software

%%%%%%%%%%%%%%%%%%%%%%
clear
%%initialize params
saveLocation =  'D:\processed\';    %might change depending on machine
datatype =      'SCANIMAGE';           %BRUKER or SCANIMAGE
date =          '05152023';
filenum = 1;
stimulusfile = 7;                   %set to -1 if there is no stimulus presented (not needed for SCANIMAGE save data?)
durResp = 2;                        %window to look for responses

doNeuropil = 0;                     %extract neuropil signal for subtraction? most important for mouse
doCascade = 0;                      %spike inference?
is2pOpto = 0;                       %if using 2P optogenetic stimulation
isvoltage = 0;                                                          %if recording Post-ASAP

framePeriod = 0.033;                %recording 1/framerate (need to eventually read from metadata
opticalZoom = 2;                    %zoom from recording to get scale-->  SI: 1 =  1.9531 pixels/micron   BRUKER: 1 = 2.44 pixels/micron (check)
% scale = 0; %pixel per microns
% depth = 0; 
% pathlength = 0; %distance from soma
% denType = 'basal'; 

chnk = 1e3;                         %how much data to load for signal extraction

%%%%%%%%%%%%%%%%%%%%%%
% For Casacde
pyExec = 'C:\Users\scholab\anaconda3\envs\Cascade\';
pyFile = 'C:\Users\scholab\Documents\Python Scripts\runCascade.py';
cascade2p_dir = 'C:\Users\scholab\Documents\MATLAB\Cascade-master';

%%%%%%%%%%%%%%%%%%%%%%
%%get data locations
folderList = gettargetFolders2(['D:\',datatype,'\'],date,filenum,'TSeries');

%reg folder location
cd(['D:\',datatype,'\',folderList(1).name,'\'])
% cd(['D:\',datatype,'\',folderList(1).name,'\Registered\Channel1\'])
%get hdf5 filen
fileList = dir('*.h5');
fileList = fileList([fileList.bytes]==max([fileList.bytes]));

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
else
    disp 'no ROIs'
end

%%%%%%%%%%%
%read h5 file and get image dimensions
h = h5info(fileList.name);
datName = h.Datasets.Name;
sizeX = h.Datasets.Dataspace.Size(1);
sizeY = h.Datasets.Dataspace.Size(2);
totalFrames = h.Datasets.Dataspace.Size(3);

%%%%%%%%%%%
tic; disp 'build ce struct and generate sparse masks'
global ce
ce = [];
maskstruct = [];
neuropilmask = zeros(sizeX,sizeY);
[x,y]=meshgrid(1:sizeX,1:sizeY);

for cc = 1:numCells

    nmCoord = [sROI{cc}.mnCoordinates(:,2) sROI{cc}.mnCoordinates(:,1)];

    if strcmp(sROI{cc}.strType,'PolyLine') %DENDRITE ROI
        mask2d = genPolyLineROI(nmCoord,sROI{cc}.nStrokeWidth,sizeX,sizeY);
    else
        mask2d = inpolygon( x, y, nmCoord(:,1), nmCoord(:,2));
    end
    neuropilmask = neuropilmask + mask2d;
    sparse3dmask = ndSparse( repmat( mask2d , 1, 1, chnk)); %expect chnk-frame stacks
    maskstruct(cc).mask = sparse3dmask;

    ce(cc).yPos =  median(nmCoord(:,2));
    ce(cc).xPos =  median(nmCoord(:,1));
    ce(cc).celloutline = nmCoord;
    ce(cc).mask2d = sparse(mask2d);
    ce(cc).date = date;
    ce(cc).file = filenum;
    ce(cc).framePeriod = framePeriod;
    ce(cc).frameRate = 1/framePeriod;
    ce(cc).opticalZoom = opticalZoom;

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
toc

if doNeuropil
    %transform neuropilmask
    neuropilmask = ~logical(neuropilmask);
    neuropil3dmask = ndSparse( repmat( neuropilmask , 1, 1, chnk));
end

%%%%%%%%%%%
tic; disp 'load stacks and extract traces'
for f_i = 1:ceil(totalFrames/chnk)

    start = ((f_i-1)*chnk + 1);
    stop = (f_i*chnk);

    imgstack = h5read(fileList.name,['/',h.Datasets.Name],[1 1 start],[sizeX sizeY min(chnk, totalFrames - start)]);

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
    if f_i==1
        ce(1).img = squeeze(mean(imgstack,3))';
        % COLLECT RED CHANNEL IMAGE IF IT EXISTS - NEED FOR PTEN KO DATA FOR EXAMPLE
    end
    fprintf('.')
end
toc

%%%%%%%%%%%
tic; disp 'calculate df/f for all ROIs'
for cc = 1:length(ce)
    if isvoltage
        ce(cc).raw = -ce(cc).raw;
        ce(cc).raw = ce(cc).raw - min(ce(cc).raw);
    end
    dff = filterBaseline_dFcomp2( ce(cc).raw ,99*4);
    ce(cc).dff = dff;
end

if doNeuropil
    %calculate df/f for neuropil trace
    dff = filterBaseline_dFcomp2(ce(1).raw_neuropil);
    ce(1).dff_neuropil = dff;
end
toc

%%%%%%
if stimulusfile>-1

    tic; disp 'grabbing two-photon frametimes'

    cd(['D:\',datatype,'\',folderList(1).name,'\'])

    if strcmp(datatype,'BRUKER')
        
        PYSCHOPYLOC = [datatype,'_PSYCHOPY'];

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

        PYSCHOPYLOC = [datatype,'_PSYCHOPY'];

        voltageFiles = dir('*.h5');
        foundWavesurfer = 0;
        cnt = 0;
        while ~foundWavesurfer
            cnt = cnt+1;
            VoltageRecording_filename = voltageFiles(cnt).name;
            if strcmp(VoltageRecording_filename(1:7),'TSeries')
                foundWavesurfer = 1;
            end
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


    disp('stimulus times and sync with two-photon')
    stimulusTriggers = medfilt1(Vrec(:,2),101);
    stimulusTriggers(stimulusTriggers<0) = 0;
    stimulusTriggers = diff(stimulusTriggers);
    [~,stimOn]=findpeaks(stimulusTriggers,'MinPeakDistance',1e3,'MinPeakHeight',max(stimulusTriggers) - max(stimulusTriggers)*.9);
    ce(1).stimOn = stimOn;
    [~,stimOff]=findpeaks(stimulusTriggers,'MinPeakDistance',1e3,'MinPeakHeight',max(stimulusTriggers) - max(stimulusTriggers)*.9);
    ce(1).stimOff = stimOff;

    if is2pOpto
        disp('2pOpto triggers')
        stimulusTriggers = medfilt1(Vrec(:,3),51);
        stimulusTriggers(stimulusTriggers<0) = 0;
        [~,photostimTrig]=findpeaks(stimulusTriggers,'MinPeakDistance',1e4,'MinPeakHeight',max(stimulusTriggers) - max(stimulusTriggers)*.9);
        ce(1).photostimTrig = photostimTrig;
    end

    cd(['D:\',PYSCHOPYLOC,'\',date(5:end),'-',date(1:2),'-',date(3:4)])
    pyschopyFile = readmatrix(['T',sprintf('%03d',stimulusfile),'.txt']);

    fidi = fopen(['T',sprintf('%03d',stimulusfile),'.txt'], 'rt');
    stimstr = textscan(fidi, '%s%s', 'CollectOutput',1);
    fclose(fidi);

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

    if is2pOpto
        ce(1).TargetStim2pFrame = floor( ce(1).TargetStim2pFrame);
    end
else
    disp 'no stimulus triggers recorded'
end
toc

%%%%%%%%%%%
%neuropil subtraction
if doNeuropil
    NeuropilSubtraction();
end

%%%%%%
if doCascade
% If requested, running CASCADE
% Installation requirements :
%{
    1. Have a version of MATLAB that supports either Python 3.7-3.8.
    Cascade works with these versions, and MathWorks supports running only
    a limited number of Python versions with each MATLAB release. 
    See compatibility chart here : (https://www.mathworks.com/support/requirements/python-compatibility.html)

    2. Have miniconda/anaconda/miniforge environment installed.

    3. Download the latest stable release of Cascade from Helmchen Lab's
    github page. Extract the collection where you intend to keep those
    scripts.

    4. Create a new Python environment in the tool above^ with command:
    conda create -n Cascade python=3.7 tensorflow==2.3 keras==2.3.1 h5py numpy scipy matplotlib seaborn ruamel.yaml spyder
    We're not going to bother with training our own network, so we can use
    the simplest and most straightforward installation method.

    5. Set the following variables
    pyExec - the python executable generated by creating the cascade
    virutal environment. This is the executable the python interpreter will
    use when we invoke cascade from MATLAB.

    pyFile - the path to the Python file that will actually run cascade.

    cascade2p_dir - parent directory of the Cascade distribution you
    downloaded from GitHub.

    The script should be able to run now.
    The ~18 lines of code below make sure that everything MATLAB needs to
    run Cascade is on path/in the environment. It also loads so NumPy and
    MATLAB data can be passed back and forth between the two programs.

%}

tic; pyRoot = fileparts(pyExec);
p = getenv('PATH');
p = strsplit(p, ';');
addToPath = {
    pyRoot
    fullfile(pyRoot, 'Library', 'mingw-w64', 'bin')
    fullfile(pyRoot, 'Library', 'usr', 'bin')
    fullfile(pyRoot, 'Library', 'bin')
    fullfile(pyRoot, 'Scripts')
    fullfile(pyRoot, 'bin')
    };
p = [addToPath(:); p(:)];
p = unique(p, 'stable');
p = strjoin(p, ';');
setenv('PATH', p);

myMod = py.importlib.import_module('numpy');
py.importlib.reload(myMod);

dff = ce(1).dff;
dff = zeros(size(ce, 2), size(dff, 1));
for i = 1:size(ce,2)
    dff(i,:) = ce(i).dff;
    dff(i, dff(i,:)<0) = 0; % Remove negatives
end

dff_python = py.numpy.array(dff);

cd(cascade2p_dir)
results = pyrunfile(pyFile, "results", ...
    traces = dff_python, do_inference = false, ...
    frame_rate = 1/framePeriod, model_name = 'Global_EXC_30Hz_smoothing50ms_causalkernel'); %'Global_EXC_7.5Hz_smoothing200ms');
cd(['D:\',datatype,'\',folderList(1).name])

spike_prob = double(pyrun("spike_prob = results['prob']","spike_prob",results = results));
noise_levels = double(pyrun("noise_levels = results['noise']","noise_levels",results = results));
discrete_approximation = double(pyrun("discrete_approx = results['discrete_approx']","discrete_approx",results = results));
spike_time_estimates = double(pyrun("spike_est = results['spike_times']","spike_est",results = results));

% Moving everything into ce struct
for i = 1:size(ce,2)
    ce(i).spikeInference = spike_prob(i,:);
    ce(i).inferenceNoiseEstimate = noise_levels(i);
    if discrete_approximation ~= 0
        ce(i).discreteApproximation = discrete_approximation(i,:);
        ce(i).spikeTimeEstimates = spike_time_estimates(i,:);
    end
end
toc
end
%%%%%%

%stimulus cyc generation - add peak SPIKE response?
genstimcyc([durResp 0 1]);

%dendritic substraction
DendriteSubtraction(1)        %argin = 1 - use full trace for subtraction, argin = 2 - use stimuli ('stimulus duration' periods)

%extract some basic responses from cyc or cycRes
if stimulusfile>-1 && floor(length(stimID)/length(unique(stimID)))>2
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
disp saving; save([saveLocation,folderList(1).name,'.mat'],'ce','-mat','-v7.3'); disp finished



