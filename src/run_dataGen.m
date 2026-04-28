function run_dataGen(c, folderName)
% run_dataGen  Load SLEAP pose data, smooth tracks, and save mouseData .mat.
%
% Reads all relevant datasets from a SLEAP-generated HDF5 (.h5) file,
% applies Savitzky-Golay smoothing to the track coordinates along the
% frame dimension, and saves the result as a mouseData .mat file.
%
% Skips processing if the mouseData file already exists.
%
% SYNTAX:
%   run_dataGen(c, folderName)
%
% INPUTS:
%   c          - Settings structure (see track_freeze_dash_vid_generator).
%                Required fields:
%                  c.outputDir               - root output directory
%                  c.h5Dir                   - directory containing SLEAP .h5 files
%                  c.inputH5Suffix           - suffix appended to folderName for .h5 file
%                  c.saveMouseDataNameSuffix - suffix for mouseData .mat file
%   folderName - Folder/file name to process (string or char).
%
% OUTPUTS:
%   mouseData .mat file saved to:
%     <c.outputDir>/<folderName>/<folderName><c.saveMouseDataNameSuffix>
%
%   Saved variables:
%     mouseData  - struct with smoothed pose tracks and metadata (see below)
%     oldc       - copy of settings struct c used for this run
%     filePath   - path to the source .h5 file
%
% HDF5 DATASETS READ:
%   /instance_scores, /node_names, /point_scores, /track_names,
%   /track_occupancy, /tracking_scores, /tracks
%
% NOTES:
%   - mouseData.tracks is smoothed in-place with a degree-5 Savitzky-Golay
%     filter along dimension 1 (frames). The raw unsmoothed tracks are not
%     saved; re-enable the unsmoothed save block if needed.
%   - The output folder is created if it does not already exist.
%
% See also: run_arenaLabel, run_calcGen, check_settings_matfile

% =========================================================================
% --- Create output folder if needed --------------------------------------
% =========================================================================

folderPath    = fullfile(c.outputDir, folderName);
outputMatPath = fullfile(folderPath, [folderName c.saveMouseDataNameSuffix]);

if ~exist(folderPath, 'dir')
    mkdir(folderPath);
end

% --- Skip if already done ---
if exist(outputMatPath, 'file')
    fprintf('run_dataGen: mouseData already exists for %s, skipping.\n', folderName);
    return;
end

% --- Validate H5 input ---
h5FilePath = fullfile(c.h5Dir, [folderName c.inputH5Suffix]);
assert(exist(h5FilePath, 'file') == 2, ...
    'run_dataGen: H5 file not found:\n  %s', h5FilePath);

fprintf('run_dataGen: Loading H5 for %s ...\n', folderName);

% --- Read all datasets from H5 file ---
mouseData.instance_scores  = h5read(h5FilePath, '/instance_scores');
mouseData.node_names       = h5read(h5FilePath, '/node_names');
mouseData.point_scores     = h5read(h5FilePath, '/point_scores');
mouseData.track_names      = h5read(h5FilePath, '/track_names');
mouseData.track_occupancy  = h5read(h5FilePath, '/track_occupancy');
mouseData.tracking_scores  = h5read(h5FilePath, '/tracking_scores');
mouseData.tracks           = h5read(h5FilePath, '/tracks');
mouseData.file             = h5FilePath;

fprintf('run_dataGen: H5 loaded. %d frames, %d nodes.\n', ...
    size(mouseData.tracks, 1), size(mouseData.tracks, 2));

% --- Apply Savitzky-Golay smoothing along the frame dimension ---
% mouseData.tracks is smoothed in-place; unsmoothed copy is not saved
% (re-enable saving mouseData_unsmooth below if needed)
mouseData.tracks = smoothdata(mouseData.tracks, 1, 'sgolay', 5);

% --- Save ---
oldc     = c;
filePath = h5FilePath;
save(outputMatPath, 'oldc', 'mouseData', 'filePath');

fprintf('run_dataGen: Done. mouseData saved for %s. \n', folderName)
end