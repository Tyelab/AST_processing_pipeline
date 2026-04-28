
function [curFrame] = fmat_plotLines(c, data, curFrameNum, curFrame, colorStyle)
% fmat_plotLines  Overlay pose skeleton lines onto a video frame.
%
% Draws a line between each pair of linked keypoints for a single video
% frame, forming the skeleton overlay. Which points are connected is
% defined by c.linkPoints. Lines are only drawn when both endpoint
% coordinates are valid (non-NaN).
%
% SYNTAX
%   curFrame = fmat_plotLines(c, data, curFrameNum, curFrame, colorStyle)
%
% INPUTS
%   c           - settings structure with fields:
%                   .linkPoints   - Nx1 cell array where each entry is a
%                                   1x2 vector [pointNumA pointNumB]
%                                   defining a connected pair of keypoints
%                                   by their 1-based index in data.tracks
%                   .pointColors  - Nx1 cell array of [R G B] color vectors
%                                   (0-255); one entry per keypoint, used
%                                   in 'multicolor' mode
%   data        - struct with fields:
%                   .tracks       - [frames x points x 2] numeric array of
%                                   (x,y) keypoint coordinates in pixels
%   curFrameNum - integer, 1-based index of the frame to annotate;
%                 used to index into data.tracks
%   curFrame    - H x W x 3 uint8 RGB image to annotate
%   colorStyle  - string controlling line color:
%                   'multicolor'  : each line uses c.pointColors{pointNumA}
%                                   (the color of the first endpoint)
%                   'confidence'  : currently identical to 'multicolor';
%                                   per-link confidence coloring is not yet
%                                   implemented (see KNOWN ISSUES)
%                   any other string (e.g. 'white', 'red', [R G B]):
%                                   all lines drawn in that color
%
% OUTPUT
%   curFrame    - H x W x 3 uint8 RGB image with skeleton lines drawn
%
% NOTES
%   - Links where either endpoint has NaN coordinates are silently skipped
%   - Line width is hardcoded to 1 pixel; parameterize via c if needed
%
% KNOWN ISSUES
% 1. 'multicolor' and 'confidence' modes reference c.pointColors{pointNum}
%      but pointNum is undefined in this scope — the loop defines pointNumA
%      and pointNumB. This will throw an "Undefined variable 'pointNum'"
%      error at runtime. The fix is c.pointColors{pointNumA}.
%   2. 'confidence' mode is not implemented — it is identical to
%      'multicolor'. Either implement confidence-based line coloring
%      (e.g. average confidence of the two endpoints) or remove the
%      branch and document that confidence coloring is unsupported for lines.
%   3. The catch block references ME but the try does not declare it,
%      causing a secondary error inside the catch itself.
%
% EXAMPLE
%   % Draw skeleton in white
%   curFrame = fmat_plotLines(c, mouseData, 150, curFrame, 'white');
%
%   % Draw skeleton with per-point colors
%   curFrame = fmat_plotLines(c, mouseData, 150, curFrame, 'multicolor');
%
% SEE ALSO
%   fmat_plotPoints, insertShape, annotate_frame


for linkNum = 1:length(c.linkPoints)
    pointNumA = c.linkPoints{linkNum, 1}(1);
    pointNumB = c.linkPoints{linkNum, 1}(2);
    
    x1 = data.tracks(curFrameNum,pointNumA,1);
    y1 = data.tracks(curFrameNum,pointNumA,2);
    x2 = data.tracks(curFrameNum,pointNumB,1);
    y2 = data.tracks(curFrameNum,pointNumB,2);
    
    if ~isnan(x1) && ~isnan(y1) && ~isnan(x2) && ~isnan(y2)
        
        % 
        if isequal(colorStyle,'multicolor') || isequal(colorStyle,'confidence')
            curFrame = insertShape(curFrame,'line', [x1,y1,x2,y2], 'LineWidth', 1,'Color', c.pointColors{pointNumA});
        else  
            try
                curFrame = insertShape(curFrame,'line', [x1,y1,x2,y2], 'LineWidth', 1,'Color', colorStyle);
            catch ME
                 warning('fmat_plotLines: insertShape failed on frame %d, link %d: %s', ...
                     curFrameNum, linkNum, ME.message);
            end
            
        end
    end %  end nan check
end % end loop over linkNum
end % end function