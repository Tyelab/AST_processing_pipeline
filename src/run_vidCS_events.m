function run_vidCS_events(c, folderName, CS_events, outputVidSuffix)
% run_vidCS_events  Write an annotated video clipped to CS-event windows.
%
% For each event onset in CS_events, a clip is written covering a baseline
% window before the onset and an experiment window after it. Clips are
% concatenated into a single output video.
%
% SYNTAX:
%   run_vidCS_events(c, folderName, CS_events, outputVidSuffix)
%
% INPUTS:
%   c               - Settings structure (see track_freeze_dash_vid_generator).
%                     Required fields:
%                       c.outputDir              - root output directory
%                       c.vidDir                 - directory of raw input videos
%                       c.inputVidSuffix         - suffix appended to folderName for input video
%                       c.saveArenaNameSuffix    - suffix for Arena .mat file
%                       c.saveMouseDataNameSuffix- suffix for mouseData .mat file
%                       c.saveCalcNameSuffix     - suffix for calc .mat file
%                       c.baseWin                - [start, end] of baseline window (seconds)
%                       c.expWin                 - [start, end] of experiment window (seconds)
%   folderName      - Folder/file name to process (string or char).
%   CS_events       - N×1 vector of event onset frame indices.
%   outputVidSuffix - Output filename suffix (e.g. c.outputCS_shockVidSuffix).
%
% OUTPUTS:
%   Video written to: <c.outputDir>/<folderName>/<folderName><outputVidSuffix>
%
% See also: run_visualizer, annotate_frame, check_settings_matfile

folderPath = fullfile(c.outputDir, folderName);

% --- Validate and load required files ---
requiredFiles = struct( ...
    'Arena',     fullfile(folderPath, [folderName c.saveArenaNameSuffix]),     ...
    'mouseData', fullfile(folderPath, [folderName c.saveMouseDataNameSuffix]), ...
    'calc',      fullfile(folderPath, [folderName c.saveCalcNameSuffix])       ...
);

fields = fieldnames(requiredFiles);
for k = 1:numel(fields)
    if ~exist(requiredFiles.(fields{k}), 'file')
        error('run_vidCS_events: Required file not found: %s', requiredFiles.(fields{k}));
    end
end

load(requiredFiles.Arena,     'Arena');
load(requiredFiles.mouseData, 'mouseData');
load(requiredFiles.calc,      'calc');

% --- Validate events ---
if isempty(CS_events)
    warning('run_vidCS_events: No events provided for %s. Skipping.', folderName);
    return;
end

% --- Override settings if per-folder settings file exists ---
c = check_settings_matfile(c, folderPath, folderName);

% --- Open input video ---
inputVideoPath = fullfile(c.vidDir, folderName, [folderName c.inputVidSuffix]);
if ~exist(inputVideoPath, 'file')
    error('run_vidCS_events: Input video not found: %s', inputVideoPath);
end
inputVideo = VideoReader(inputVideoPath); %#ok<TNMLP>

fprintf('run_vidCS_events: Frame rate = %.2f fps\n', inputVideo.FrameRate);

% --- Compute window sizes in frames ---
baseline_frames = round(diff(c.baseWin) * inputVideo.FrameRate);
exp_frames      = round(diff(c.expWin)  * inputVideo.FrameRate);

% --- Open output video ---
outputVideoPath = fullfile(folderPath, [folderName outputVidSuffix]);
outputVideo = VideoWriter(outputVideoPath); %#ok<TNMLP>
outputVideo.FrameRate = inputVideo.FrameRate;
open(outputVideo);
fprintf('run_vidCS_events: Annotating %d events for %s ...\n', size(CS_events,1), folderName);

% --- Initialize counters ---
curEvent    = 1;
curFrameNum = max(1, CS_events(curEvent, 1) - baseline_frames);
dataLength  = size(mouseData.tracks, 1);

f = waitbar(0, ['CS events: ' folderName]);

try
    while hasFrame(inputVideo)

        inWindow = curFrameNum <= dataLength && ...
            any(curFrameNum >= (CS_events(:,1) - baseline_frames) & ...
                curFrameNum <= (CS_events(:,1) + exp_frames));

        if inWindow
            inputVideo.CurrentTime = curFrameNum / inputVideo.FrameRate;
            curFrame = readFrame(inputVideo);

            curFrame = annotate_frame(c, curFrame, curFrameNum, Arena, mouseData, calc);

            writeVideo(outputVideo, curFrame);
            curFrameNum = curFrameNum + 1;
            waitbar(curFrameNum / dataLength, f);

        else
            curEvent = curEvent + 1;
            if curEvent <= size(CS_events, 1)
                curFrameNum = max(1, CS_events(curEvent, 1) - baseline_frames);
                fprintf('run_vidCS_events: Advanced to event %d (frame %d)\n', curEvent, curFrameNum);
            else
                break;
            end
        end

    end

catch ME
    warning('run_vidCS_events: Error during annotation for %s: %s', folderName, ME.message);
end

% --- Cleanup (always runs) ---
close(outputVideo);
close(f);
fprintf(sprintf('run_vidCS_events: Completed %s\n', folderName));
end