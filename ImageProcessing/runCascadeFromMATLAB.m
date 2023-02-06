%% Invoking HelmchenLab's Cascade from MATLAB
% This script appends spike deconvolution data to calcium DFF ce structs
% from getTracesDFF :

% Expected outputs - ce struct with the following fields :
%     spike_prob - not a true probability, but the expected number of spikes
%     within this frame. (32 prior, 32 following + current timepoint)
%       - spike_prob * frame_rate = instantaneous spike rate
%       - single-spike resolution is unattainable due to noise.
%       - See the git issue or the paper for more info on interpretation:
%       https://github.com/HelmchenLabSoftware/Cascade/issues/22
%       https://www.nature.com/articles/s41593-021-00895-5
%       - NaNs populate the timepoints at the sliding window boundaries
%   
%     noise - noise level estimate for this neuron. 
%       - 1-2 is good. 3,4 is decent for multi-neuron recordings. Noise
%       above 5 becomes troublesome and may be candidates for removal.
%     discrete_approximation - approximated spike_prob function composed of
%       the inferred discrete spikes. See paper for details.
%     spike_time_estimates - indices of an inferred spike event. Multiple
%       spikes may be inferred within the same timepoint.

% To Use : 
%   Make sure that framerate, desired model, and spike inf are correct.
%   Make sure that pyFile points to runCascade.py
%   Make sure that pyExec and workDir are the correct paths.
%       - pyExec should point to the python executable that corresponds to the
%         [Ana/Mini]conda environment (rarely changed)
%       - workDir should point to the directory containing .mat files w/ ce
%         structure contained. 
%  Using discrete spikes isn't recommended by the authors unless DFF traces
%  come from exceptionally high quality recordings.

% Needed changes :
% - Change the save location of the data. Include a check against overwrite
% - Redirect stdout to logfiles. Save these per input data location.

%%initalize params ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
do_inference = false; % computationally expensive, brute-force. LONG compute time.
frame_rate = 30;
model_name = 'Global_EXC_7.5Hz_smoothing200ms'; % Most recommended model for our work.

%%folder locations ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% pyExec = 'C:\Users\scholab\miniconda3\envs\Cascade\python.exe';
pyExec = 'C:\Users\scholab\anaconda3\envs\Cascade\python.exe';
workDir = 'D:\NR1KO_2022\';
%workDir = 'C:\Users\scholab\Documents\mappingRFs';
pyFile = 'C:\Users\scholab\Documents\MATLAB\Cascade-Master\runCascade.py';
cd C:\Users\scholab\Documents\MATLAB\Cascade-master

%%Setting up MATLAB to use the right python environment ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
pyRoot = fileparts(pyExec);
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

%% Running for multiple files/sessions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Workdir will contain a mat file for each electrode trace.' - mat is [nElectrodes, nSamples] matrix.

filePattern = fullfile(workDir, '*.mat');
fileSet = dir(filePattern);
for f = 1:length(fileSet)
    baseFileName = fileSet(f).name;
    fullFileName = fullfile(fileSet(f).folder, baseFileName);
    load(fullFileName)
    fprintf(1, 'File is %s\n', baseFileName)
    dff = ce(1).dff;
    dff = zeros(size(ce, 2), size(dff, 1));
    % initialize
    for i = 1:size(ce,2)
        dff(i,:) = ce(i).dff;
        dff(i,dff(i,:)<0) = 0; %%%%
    end
    % conversion to feed into Cascade
    dff_python = py.numpy.array(dff);

    % Running Cascade on the data
    results = pyrunfile(pyFile, "results", ...
        traces = dff_python, do_inference = do_inference, frame_rate = frame_rate, model_name = model_name);

    % Extracting information out of python environment and into MATLAB
    spike_prob = double(pyrun("spike_prob = results['prob']","spike_prob",results = results));
    noise_levels = double(pyrun("noise_levels = results['noise']","noise_levels",results = results));
    discrete_approximation = double(pyrun("discrete_approx = results['discrete_approx']","discrete_approx",results = results));
    spike_time_estimates = double(pyrun("spike_est = results['spike_times']","spike_est",results = results));
    % Populating ce fields
    for i=1:size(ce,2)
        ce(i).spikeInference = spike_prob(i,:);
        ce(i).inferenceNoiseEstimate = noise_levels(i);
        if discrete_approximation ~= 0
            ce(i).discreteApproximation = discrete_approximation(i,:);
            ce(i).spikeTimeEstimates = spike_time_estimates(i,:);
        end
    end
    % Save to disk
    save(baseFileName, "ce")
end


