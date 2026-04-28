function run_vidGen(c, folderName)
% run_vidGen  Write a fully annotated full-session video for one folder.
%
% Reads every frame sequentially (no seeking) up to c.labelVidLengthFrames
% or the end of available pose data, whichever comes first. Each frame
% receives a skeleton overlay, arena edges, port marker, freeze/dash
% stickers, and a frame-number label via annotate_frame.
%
% SYNTAX:
%   run_vidGen(c, folderName)
%
% INPUTS:
%   c          - Settings structure (see track_freeze_dash_vid_generator).
%                Required fields:
%                  c.outputDir               - root output directory
%                  c.vidDir                  - directory containing input video
%                                             (video lives directly here, not in a subfolder)
%                  c.saveArenaNameSuffix     - suffix for Arena .mat file
%                  c.saveMouseDataNameSuffix - suffix for mouseData .mat file
%                  c.saveCalcNameSuffix      - suffix for calc .mat file
%                  c.labelVidLengthFrames    - maximum frames to annotate
%                  c.outputLabelVidSuffix    - suffix for output video file
%   folderName - Folder/file name to process (string or char).
%
% OUTPUTS:
%   Annotated video written to:
%     <c.outputDir>/<folderName>/<folderName><c.outputLabelVidSuffix>
%
% NOTES:
%   - Unlike run_vidCS_events, input video is read sequentially with no
%     seeking, so CurrentTime is never set manually.
%   - Annotation stops at min(c.labelVidLengthFrames, size(mouseData.tracks,1)).
%
% See also: run_vidCS_events, run_visualizer, annotate_frame, check_settings_matfile

% =========================================================================
% --- Load required files -------------------------------------------------
% =========================================================================

folderPath = fullfile(c.outputDir, folderName);
requiredFiles = struct( ...
    'Arena',     fullfile(folderPath, [folderName c.saveArenaNameSuffix]),     ...
    'mouseData', fullfile(folderPath, [folderName c.saveMouseDataNameSuffix]), ...
    'calc',      fullfile(folderPath, [folderName c.saveCalcNameSuffix])       ...
    );

for field = fieldnames(requiredFiles)'
    fpath = requiredFiles.(field{1});
    assert(exist(fpath, 'file') == 2, ...
        'run_vidGen: Required file not found:\n  %s', fpath);
end

load(requiredFiles.Arena,     'Arena');
load(requiredFiles.mouseData, 'mouseData');
load(requiredFiles.calc,      'calc');

% =========================================================================
% --- Per-folder settings override ----------------------------------------
% =========================================================================
c = check_settings_matfile(c, folderPath, folderName);

% =========================================================================
% --- Open input / output videos ------------------------------------------
% =========================================================================
% Note: vidDir contains the file directly (no subfolder), unlike CS event stages
inputVideoPath = fullfile(c.vidDir, folderName);
assert(exist(inputVideoPath, 'file') == 2, ...
    'run_vidGen: Input video not found:\n  %s', inputVideoPath);

inputVideo            = VideoReader(inputVideoPath); %#ok<TNMLP>
outputVideoPath       = fullfile(folderPath, [folderName c.outputLabelVidSuffix]);
outputVideo           = VideoWriter(outputVideoPath); %#ok<TNMLP>
outputVideo.FrameRate = inputVideo.FrameRate;
open(outputVideo);

% =========================================================================
% --- Annotate frames -----------------------------------------------------
% =========================================================================

dataLength    = size(mouseData.tracks, 1);
frameLimit = min(c.labelVidLengthFrames, dataLength);

fprintf('run_vidGen: Annotating full session for %s (%d frames) ...\n', ...
    folderName, frameLimit);

curFrameNum   = 1;
f = waitbar(0, ['Full session: ' folderName]);

try
    while hasFrame(inputVideo) && curFrameNum <= frameLimit
        % Sequential read — no seeking needed since we process every frame
        curFrame = readFrame(inputVideo);
        curFrame = annotate_frame(c, curFrame, curFrameNum, Arena, mouseData, calc);
        writeVideo(outputVideo, curFrame);
        curFrameNum = curFrameNum + 1;
        waitbar(curFrameNum / frameLimit, f);

    end

catch ME
    warning('run_vidGen: Error at frame %d for %s: %s', curFrameNum, folderName, ME.message);
end

% =========================================================================
% --- Cleanup (always runs) -----------------------------------------------
% =========================================================================
close(outputVideo);
close(f);
disp(['run_vidGen: Completed ' folderName])
end