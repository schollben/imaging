function neuropilRois = generateNeuropilROIs(diskRadius)
% takes cellular imageJ ROIs and creates neuropil masks centered around each roi.
% The neuropil masks are disks projected away from each cell with a radius equal
% to the pixel size specified by diskRadius. Neuropil masks will not
% include any pixels contained in any of the cellular rois. 
%
% rois - can either be a path to the location of ROIs or are the cellular rois
%        passed into MATLAB with rm.getRoisAsArray
% diskRadius - size of the neuropil masks

% Setup ROI Manager with MIJ
rm=ij.plugin.frame.RoiManager;
rm=rm.getInstance;
cellRois=rm.getRoisAsArray;
for i =1:length(cellRois)
    cellRois(i) = ij.gui.ShapeRoi(cellRois(i));
end;

%% XOR current cell ROIs
% Step 1: Determine locations to eliminate
XOR_Locations=cellRois(1).clone;
for i=2:length(cellRois)
    XOR_Locations=XOR_Locations.xor(cellRois(i));
end

% Step 2: Create a new XORed ROI list
emptyOverlay=ij.gui.Overlay; % allows us to put an empty here
XORedCellRois=emptyOverlay.toArray;
for i=1:length(cellRois)
    XORedCellRois(i)=cellRois(i).clone;
    XORedCellRois(i)=XORedCellRois(i).and(XOR_Locations);
    XORedCellRois(i).setName(cellRois(i).getName);
end

%% Create a mask set where we project discs away from the centers of each cellular ROI
% Step 1: Create a ROI that contains regions located within our cell ROIs. All future 
% neuropil masks will exclude this region.
excludedRegions=XORedCellRois(1).clone;
for i=2:length(XORedCellRois)
    excludedRegions=excludedRegions.or(XORedCellRois(i));
end

% Step 2: Generate a neuropil mask by creating a disk roi centered around each cell. However, 
% we will exclude all regions that include our cellular ROIs.
if(nargin<1), diskRadius = 5; end
neuropilRois = emptyOverlay.toArray;
for i=1:length(XORedCellRois)
    % Create new oval roi
    x = cellRois(i).getXBase+0.5*cellRois(i).getFloatWidth;
    y = cellRois(i).getYBase+0.5*cellRois(i).getFloatHeight;
    diskDiameter = 2*diskRadius+1;
    ovalROI  = ij.gui.OvalRoi(x-diskRadius,y-diskRadius,diskDiameter,diskDiameter); % start with an oval roi
    shapeROI = ij.gui.ShapeRoi(ovalROI); % convert oval roi to a shape roi    
    
    % Save the new roi, but we will exclude pixels contained within
    % cellular ROIs
    neuropilRois(i) = shapeROI.not(excludedRegions);
    
    % Rename the neuropil ROIs
    %cellName = char(cellRois(i).getName);
    %neuropilRois(i).setName(strrep(cellName,'Cell','Neuropil'));
end    

% Step 3: Load neuropil masks into imageJ
loadRm(neuropilRois)
return

function varargout=loadRm(newRois)
% oldRois=loadRm(newRois)
%
% replaces rois in roi manager with spcified rois.
% Input can be roi array, path to IJ roi .zip file
% if empty, a open file dialog is raised.
% 
% Optionally returns the previous rois as oldRois
%
% Gordon Smith, 2014

rm=ij.plugin.frame.RoiManager;
rm=rm.getInstance;
if nargout~=0
    oldRois=rm.getRoisAsArray;
end

if nargin==0
    pd=pwd;
    try cd('analysis'); end
    [fn pth]=uigetfile('*.zip','Select ROIs:');
    cd(pd);
    if fn==0; return; end
    name=[];
    loadFromfile=true;
    fname=[pth fn];
elseif ischar(newRois)
    fname=newRois;
    loadFromfile=true;
else
    loadFromfile=false;
end

if rm.getCount~=0
    rm.runCommand('Deselect');
    rm.runCommand('Delete');
end
if loadFromfile
    rm.setTitle('ROI Manager')
    rm.runCommand('Open', strrep(fname,'\','\\'));
else    
    name=inputname(1);
    for i=1:length(newRois)
        rm.addRoi(newRois(i));
    end
    rm.setTitle(sprintf('%s RM',name))
end
return

