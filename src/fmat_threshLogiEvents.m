
function [output] = fmat_threshLogiEvents(rawData,operator,thresh,minFrames,gapTol)
% fmat_threshLogiEvents  Threshold a continuous signal into bout events.
%
% Applies a threshold to a frame-wise continuous signal to produce a
% logical vector of "event active" frames, then refines it by discarding
% bouts shorter than a minimum duration and filling short gaps between
% bouts. Returns both the refined logical vector and the onset/offset
% timestamps of each surviving bout.
%
% Typical use cases are detecting freezing (signal LESS than a movement
% threshold) and dashing (signal GREATER than a velocity threshold).
%
% SYNTAX
%   output = fmat_threshLogiEvents(rawData, operator, thresh, minFrames, gapTol)
%
% INPUTS
%   rawData    - Nx1 numeric vector of per-frame signal values
%                (e.g. mean point displacement in cm, haunch velocity)
%   operator   - string, thresholding direction:
%                  'less'    : event active when rawData < thresh
%                  'greater' : event active when rawData > thresh
%   thresh     - scalar, threshold value in the same units as rawData
%   minFrames  - integer, minimum number of consecutive frames required
%                for a bout to be retained. Bouts shorter than this are
%                discarded. (e.g. 5 frames at 30fps = ~167ms minimum)
%   gapTol     - integer, maximum gap in frames between two bouts that
%                will be bridged (filled in) to merge them into one bout.
%                (e.g. 4 frames at 30fps = ~133ms gap tolerance)
%
% OUTPUTS
%   output     - struct with fields:
%     .rawData    - original input signal (Nx1)
%     .logiRaw    - Nx1 logical, raw threshold applied to rawData
%     .logiModF   - Nx1 logical, after discarding sub-minimum bouts
%     .logiModFG  - Nx1 logical, after gap-filling between bouts
%     .timestamps - 1x2 cell:
%                     {1,1} column vector of bout onset  frame indices
%                     {1,2} column vector of bout offset frame indices
%                   Each row i defines one bout: onset(i) to offset(i)
%
% ALGORITHM
%   1. Apply threshold to produce logiRaw
%   2. Scan logiRaw with a sliding window of width minFrames; mark a
%      frame as active only if all minFrames consecutive frames are active
%      (logiModF)
%   3. Fill gaps <= gapTol frames between active bouts (logiModFG)
%   4. Extract bout onsets/offsets from the diff of logiModFG
%
% KNOWN LIMITATIONS
%   - Gap filling only bridges gaps of exactly gapTol frames; gaps of
%     1:(gapTol-1) frames are not reliably filled. See gapTol note above.
%   - Timestamp parity correction (onset/offset count mismatch) is a
%     heuristic fallback; inspect output.timestamps if bout counts appear
%     incorrect for edge cases where the signal starts or ends mid-bout.
%
% EXAMPLE
%   % Detect freezing: movement below 0.05 cm/frame for at least 5 frames
%   output = fmat_threshLogiEvents(pointDistRelevantAvg, 'less', 0.05, 5, 4);
%   freezeOnsets  = output.timestamps{1,1};
%   freezeOffsets = output.timestamps{1,2};
%
%   % Detect dashing: haunch velocity above 0.85 cm/frame for 2+ frames
%   output = fmat_threshLogiEvents(pointDistHaunch, 'greater', 0.85, 2, 2);
%
% SEE ALSO
%   fmat_poseAnalyze, smoothdata, findpeaks

% Calculating freezing logical and bout timestamps

if strcmp(operator,"greater")
    logiRaw = (rawData > thresh);
else
    if strcmp(operator,"less")
        logiRaw = (rawData < thresh);
    else
        disp('ERROR: Logical operator not recognized for fmat_threshLogiEvents.')
        % 
    end
end

% 


% Discarding freezing bouts below the minimum number of frames
logiModF(1:length(logiRaw),1) = false; % Make a new logical of zeros
for frameNum = 1:length(logiRaw)
    if frameNum == 6796
        % 
    end
    if frameNum+(minFrames-1) <= length(logiRaw) % Avoiding out-of-array errors
        if logiRaw(frameNum:frameNum+(minFrames-1)) == true
            logiModF(frameNum:frameNum+(minFrames-1)) = true;
        end
        
    end
end

% Filling any gaps between large freezing bouts
%logiModFG(1:length(logiModF),1) = false; % Make a new logical of zeros

logiModFG = logiModF; % make a copy of your logical
for frameNum = 1:length(logiModF)
    if frameNum+(gapTol+1) <= length(logiModF) % Avoiding out-of-array errors
        if logiModF(frameNum) == true && logiModF(frameNum+gapTol+1) == true
            logiModFG(frameNum:(frameNum+gapTol+1)) = true;
        end
    end
end






logiModFGDiff = diff(logiModFG);
logiModFGDiff = [0; logiModFGDiff];

if logiModFG(1) == 1
    logiModFGDiff(1) = 1;
end

[~, peakIndexes] = findpeaks(logiModFGDiff);

if logiModFG(1) == 1
    peakIndexes(2:end+1) = peakIndexes;
    peakIndexes(1) = 1 ;
end

timestamps{1,1} = peakIndexes;
invDiff = logiModFGDiff*-1;
[~, valIndexes] = findpeaks(invDiff);
timestamps{1,2} = valIndexes;

if size(timestamps{1,1},1) ~= size(timestamps{1,2},1)
    if size(timestamps{1,1},1) < size(timestamps{1,2},1)
        peakIndexes2 = [1; peakIndexes];
        timestamps{1,1} = peakIndexes2;
    end
    if size(timestamps{1,1},1) > size(timestamps{1,2},1)
        valIndexes2 = [valIndexes; length(logiModFG)] ;
        timestamps{1,2} = valIndexes2;
    end
end

output.rawData = rawData;
output.logiRaw = logiRaw;
output.logiModF = logiModF;
output.logiModFG = logiModFG;
output.timestamps = timestamps;

% 
end


