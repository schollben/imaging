% PIPELINE README
%
% Registation (motion correction)
% 
%   - subcellularRegisttration_normcorre: typically for spines and complex motion artifact
%
%   - Registration_Rigid_ParPool: for simple registration of movement 
% (best to use with population data without too much motion problems)
%
%   - Registration_Rigid: Same as above without parallel processing
%
%   - Images are saved as 500 or 1000 stacks
%
% Draw ROIs
%   - Open Fiji (ImageJ)
%   - Located the files and import all (note: a virtual stack can be used for large sets of files
%   - use *** File-> Import-> TIFF Virtual Stack ***
%   - Use 'cell magic wand' to draw cell and spine ROIs
%   - Use 'sgemented line' to draw dendrite ROIs
%   - Save the ROI set to the data file folder ('/Registered')
%   
%   Alternatively: 
%       - Use Suite2p for loading data, automatic ROI detection, and signal
%       extraction. This pipeline will work well for population-level
%       imaging (i.e. cells, as compared to dendritic spines). This can
%       generate processed data for subsqeuent analysis.
%
% Extract Signals for Analysis 
%   - use 'getTracesDFF' script
%
%
