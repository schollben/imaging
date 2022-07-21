
function []=genstimcyc(stimDur,prestim,poststim)

if nargin

global ce



stimulus information 
prestimPeriod = 0;    
stimDur = 2; % 4SEC for annulus!
postPeriod = 1;  
useLessTrials = 0;    
doresamp = 1;

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





