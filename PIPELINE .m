% PIPELINE
%
% Registation (motion correction)
% 
%   - subcellularRegisttration_normcorre: 
%
%   - Registration_Rigid_ParPool: 
%
%   - Registration_Rigid: Same as above without parallel processing
%
%   - Images are saved as 10,000 frame stacks
%
% Draw ROIs
%   - Open Fiji (ImageJ)
%   - Located the files and import all (note: a virtual stack can be used for large sets of files
%   - Use 'cell magic wand' to draw cell and spine ROIs
%   - Use 'sgemented line' to draw dendrite ROIs
%   - Save the ROI set to the data file folder
%   
%   Alternatively: 
%       - Use Suite2p for loading data, automatic ROI detection, and signal
%       extraction. This pipeline will work well for population-level
%       imaging (i.e. cells, as compared to dendritic spines). This can
%       generate processed data for subsqeuent analysis.
%
% Extract Signals for Analysis
%   - 
%   -
%
%
%
