
function [calc] = fmat_poseAnalyze(c, data, Arena)
% fmat_poseAnalyze  Compute frame-wise pose metrics from tracked keypoint data.
%
% Calculates per-frame movement, velocity, and position metrics from SLEAP
% tracked keypoint coordinates, converts all distance metrics from pixels
% to centimeters, identifies the sticker point position for visualisation,
% and detects freeze and dash bouts using threshold-based event detection.
%
% SYNTAX
%   calc = fmat_poseAnalyze(c, data, Arena)
%
% INPUTS
%   c       - settings structure with fields:
%               .haunchPointID    - integer, 1-based index of the haunch
%                                   keypoint in data.tracks; used for
%                                   velocity (dashing) calculation and
%                                   distance-from-edge calculation
%               .nosePointID      - integer, 1-based index of the nose
%                                   keypoint; used for distance-to-port
%               .stickerPointID   - 1xN integer vector of keypoint indices
%                                   whose mean XY position defines the
%                                   sticker overlay location (e.g. [7 8]
%                                   for shoulders and haunch)
%               .freezeSettings   - struct with fields:
%                   .relevantPoints - vector of keypoint indices included
%                                     in the mean displacement calculation
%                                     used for freeze detection
%                   .operator       - 'less' (freeze when movement < thresh)
%                   .thresh_cm      - freeze threshold in cm/frame
%                   .minFrames      - minimum bout duration in frames
%                   .gapTol         - gap fill tolerance in frames
%               .dashSettings     - struct with fields:
%                   .operator       - 'greater' (dash when velocity > thresh)
%                   .thresh_cm      - dash threshold in cm/frame
%                   .minFrames      - minimum bout duration in frames
%                   .gapTol         - gap fill tolerance in frames
%   data    - struct with fields:
%               .tracks           - [frames x points x 2] numeric array of
%                                   (x,y) keypoint coordinates in pixels
%   Arena   - struct with fields:
%               .Box.position     - Nx2 matrix of arena corner (x,y) pixel
%                                   coordinates, used for edge distance
%               .Port.position    - 1x2 vector of port spout (x,y) pixel
%                                   coordinates, used for nose-to-port
%                                   distance
%               .conversionFactor - scalar, cm per pixel conversion factor
%                                   computed by run_arenaLabel
%
% OUTPUT
%   calc    - struct with fields:
%     .pixel.pointDistAll         - [frames x points] euclidean distance
%                                   each point moved between consecutive
%                                   frames, in pixels; frame 1 = 0
%     .pixel.pointDistAllAvg      - [frames x 1] mean of pointDistAll
%                                   across all points per frame
%     .pixel.pointDistRelevantAvg - [frames x 1] mean displacement across
%                                   c.freezeSettings.relevantPoints only
%     .pixel.pointDistHaunch      - [frames x 1] displacement of haunch
%                                   point between frames (pixel velocity)
%     .pixel.distanceFromEdge     - [frames x 1] minimum distance from
%                                   haunch point to any arena wall, pixels
%     .pixel.distanceFromPort     - [frames x 1] distance from nose point
%                                   to port spout, pixels
%     .cm.*                       - all of the above converted to cm via
%                                   Arena.conversionFactor
%     .stickerPoint               - [frames x 2] mean (x,y) position of
%                                   c.stickerPointID keypoints; used to
%                                   place freeze/dash overlay markers
%     .cm.freezing                - output struct from fmat_threshLogiEvents
%                                   applied to pointDistRelevantAvg;
%                                   contains logiModFG, timestamps, etc.
%     .cm.dashing                 - output struct from fmat_threshLogiEvents
%                                   applied to pointDistHaunch
%
% NOTES
%   - Frame 1 displacement is set to 0 for all points (no prior frame)
%   - distanceFromEdge uses the haunch point and point_to_line_distance;
%     requires the AlphaTracker Utils path to be on the MATLAB path
%   - All pixel metrics are retained alongside cm metrics to allow
%     post-hoc threshold adjustment without re-running
%
% KNOWN ISSUES
%   1. The entire function runs in a frame-by-frame for loop which is
%      fully vectorizable — see SUGGESTED IMPROVEMENTS below
%   2. distanceFromEdge assumes exactly 4 arena corners; will silently
%      produce incorrect results for non-rectangular arenas
%   3. pointDistAllAvg includes ALL points equally regardless of
%      tracking quality; NaN points are omitted via 'omitnan' but low-
%      confidence points are not downweighted
%
% SUGGESTED IMPROVEMENTS
%   See inline comments below. Summary:
%     - Vectorize inter-frame distance calculation (major speedup)
%     - Vectorize sticker point extraction
%     - Guard against mismatched data/Arena corner count
%     - Consider confidence-weighted average displacement
%
% EXAMPLE
%   calc = fmat_poseAnalyze(c, mouseData, Arena);
%   figure; plot(calc.cm.pointDistRelevantAvg);
%   yline(c.freezeSettings.thresh_cm, 'r--');
%
% SEE ALSO
%   fmat_threshLogiEvents, run_calcGen, point_to_line_distance


for curFrameNum = 1:size(data.tracks,1)
    % fergil's original double loop 
    % for pointNum = 1:size(data.tracks,2)
    %     Fergil original double loop code to compute:
    % 
    %     if curFrameNum == 1
    %         calc.pixel.pointDistAll(curFrameNum,pointNum) = 0;
    %     else
    %         x1 = data.tracks(curFrameNum,pointNum,1);
    %         y1 = data.tracks(curFrameNum,pointNum,2);
    %         x2 = data.tracks(curFrameNum-1,pointNum,1);
    %         y2 = data.tracks(curFrameNum-1,pointNum,2);
    % 
    %         % calculate the distance between  xy1 and xy2
    %         calc.pixel.pointDistAll(curFrameNum,pointNum) = pdist(([x1,y1;x2,y2]),'euclidean');
    %     end
    % end

    % --- Vectorized point-to-point distances across all points ---
    if curFrameNum == 1
        calc.pixel.pointDistAll(curFrameNum, :) = 0;
    else
        % Extract XY coords for current and previous frame: [nPoints x 2]
        xy_curr = squeeze(data.tracks(curFrameNum,   :, 1:2));  % [nPoints x 2]
        xy_prev = squeeze(data.tracks(curFrameNum-1, :, 1:2));  % [nPoints x 2]

        % Euclidean distance for each point in one shot
        calc.pixel.pointDistAll(curFrameNum, :) = sqrt(sum((xy_curr - xy_prev).^2, 2));
    end

    %calculate distance to edges (using haunch as pt)
    pt = [data.tracks(curFrameNum, c.haunchPointID, 1),data.tracks(curFrameNum, c.haunchPointID, 2)] ;
    edgeDistance(1) = point_to_line_distance(pt, [Arena.Box.position(1,1) Arena.Box.position(1,2)], [Arena.Box.position(2,1) Arena.Box.position(1,2)]);
    edgeDistance(2) = point_to_line_distance(pt, [Arena.Box.position(2,1) Arena.Box.position(2,2)], [Arena.Box.position(3,1) Arena.Box.position(3,2)]);
    edgeDistance(3) = point_to_line_distance(pt, [Arena.Box.position(3,1) Arena.Box.position(3,2)], [Arena.Box.position(4,1) Arena.Box.position(4,2)]);
    edgeDistance(4) = point_to_line_distance(pt, [Arena.Box.position(4,1) Arena.Box.position(4,2)], [Arena.Box.position(1,1) Arena.Box.position(1,2)]);
    calc.pixel.distanceFromEdge(curFrameNum, 1) = min(edgeDistance);

    %calculate distance to port (using nose as pt)
    calc.pixel.distanceFromPort(curFrameNum, 1) = pdist(([Arena.Port.position(1),Arena.Port.position(2); data.tracks(curFrameNum, c.nosePointID, 1),data.tracks(curFrameNum, c.nosePointID, 2)]),'euclidean');

    % Average distance of all points between frames:
    calc.pixel.pointDistAllAvg(curFrameNum) = mean(calc.pixel.pointDistAll(curFrameNum,:),'omitnan');

    % Average distance of all points between frames, minus tail point:
    calc.pixel.pointDistRelevantAvg(curFrameNum) = mean(calc.pixel.pointDistAll(curFrameNum,c.freezeSettings.relevantPoints),'omitnan');
    %     % letting us know which nodes are used in calculation:
    %     nodes   = data.node_names(c.freezeSettings.relevantPoints);
    %     txt =('Using these points in average distance:');
    %     for ii =1:numel(nodes), txt = [txt deblank(nodes{ii}) ', '] ;end
    %     warning(txt)


end

calc.pixel.pointDistAllAvg = calc.pixel.pointDistAllAvg';
calc.pixel.pointDistRelevantAvg =  calc.pixel.pointDistRelevantAvg';
calc.pixel.pointDistHaunch = calc.pixel.pointDistAll(:,c.haunchPointID);

%CONVERTING TO CM
calc.cm.pointDistAll = calc.pixel.pointDistAll * Arena.conversionFactor ;
calc.cm.pointDistAllAvg = calc.pixel.pointDistAllAvg  * Arena.conversionFactor ;
calc.cm.pointDistRelevantAvg = calc.pixel.pointDistRelevantAvg  * Arena.conversionFactor;
calc.cm.pointDistHaunch  = calc.pixel.pointDistHaunch  * Arena.conversionFactor ;

%calc.cm.pointVectAll = calc.pixel.pointDistAll * Arena.conversionFactor ;
%calc.cm.pointVectAllAvg = calc.pixel.pointVectAllAvg  * Arena.conversionFactor;
%calc.cm.pointVectAllAvgAbs = calc.pixel.pointVectAllAvgAbs  * Arena.conversionFactor;


% STICKER POINT COORDINATES
stickerPointTemp = nan( size(data.tracks,1),size(c.stickerPointID,2), 2);
for stickerPointNum = 1:size(c.stickerPointID,2)
    stickerPointTemp(:,stickerPointNum,:) = data.tracks(:,c.stickerPointID(stickerPointNum),(1:2));
end
calc.stickerPoint(:,1) = mean(stickerPointTemp(:,:,1),2,'omitnan');
calc.stickerPoint(:,2) = mean(stickerPointTemp(:,:,2),2,'omitnan');

% this is the format for following function calls
% fmat_threshLogiEvents(rawData,operator,thresh,minFrames,gapTol)

% CALC FREEZING
[calc.cm.freezing] = fmat_threshLogiEvents(calc.cm.pointDistRelevantAvg,c.freezeSettings.operator,c.freezeSettings.thresh_cm,c.freezeSettings.minFrames,c.freezeSettings.gapTol);


% CALC DASHING
[calc.cm.dashing] = fmat_threshLogiEvents(calc.cm.pointDistHaunch,c.dashSettings.operator,c.dashSettings.thresh_cm,c.dashSettings.minFrames,c.dashSettings.gapTol);

end
