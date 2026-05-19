function curFrame = annotate_frame(c, curFrame, curFrameNum, Arena, mouseData, calc)
% annotate_frame(c, curFrame, curFrameNum, Arena, mouseData, calc)
%
% Applies all configured annotations to a single video frame.
% Returns the annotated frame.
%
% Annotations applied (each gated by its toggle in c):
%   - Arena edge lines
%   - Port location marker
%   - Skeleton lines (smoothed / unsmoothed)
%   - Skeleton points (smoothed / unsmoothed)
%   - Frame number label
%   - Freeze sticker (red filled circle)
%   - Dash sticker (yellow filled circle)

STICKER_RADIUS    = 9;
PORT_RADIUS       = 6;
STICKER_OPACITY   = 0.7;
PORT_OPACITY      = 0.7;
ARENA_LINE_WIDTH  = 1;

% Arena edges
if c.labelArenaEdges
    corners = Arena.Box.position;
    nCorners = size(corners, 1);
    for edgeNum = 1:nCorners
        nextCorner = mod(edgeNum, nCorners) + 1;
        curFrame = insertShape(curFrame, 'line', ...
            [corners(edgeNum,1), corners(edgeNum,2), corners(nextCorner,1), corners(nextCorner,2)], ...
            'LineWidth', ARENA_LINE_WIDTH, 'Color', 'white');
    end
end

% Port marker
if c.labelPort
    curFrame = insertShape(curFrame, 'FilledCircle', ...
        [Arena.Port.position, PORT_RADIUS], ...
        'LineWidth', 1, 'Color', 'blue', 'Opacity', PORT_OPACITY);
end

% Skeleton lines
if c.smoothed.plotLines
    curFrame = fmat_plotLines(c, mouseData, curFrameNum, curFrame, c.smoothed.lineColorStyle);
end

% Skeleton points
if c.smoothed.plotPoints
    curFrame = fmat_plotPoints(c, mouseData, curFrameNum, curFrame, c.smoothed.pointColorStyle);
end

% Frame number label
if c.labelFrameNum
    curFrame = insertText(curFrame, [1 1], ['Frame ' num2str(curFrameNum)], ...
        'BoxColor', 'black', 'TextColor', 'white');
end

% Freeze sticker (red)
if c.sticker.plotFreeze
    stickerX = calc.smoothed.stickerPoint(curFrameNum, 1);
    stickerY = calc.smoothed.stickerPoint(curFrameNum, 2);
    if ~isnan(stickerX) && calc.smoothed.cm.freezing.logiModFG(curFrameNum)
        curFrame = insertShape(curFrame, 'FilledCircle', ...
            [stickerX, stickerY, STICKER_RADIUS], ...
            'LineWidth', 1, 'Color', 'red', 'Opacity', STICKER_OPACITY);
    end
end

% Dash sticker (yellow)
if c.sticker.plotDash
    stickerX = calc.smoothed.stickerPoint(curFrameNum, 1);
    stickerY = calc.smoothed.stickerPoint(curFrameNum, 2);
    if ~isnan(stickerX) && calc.smoothed.cm.dashing.logiModFG(curFrameNum)
        curFrame = insertShape(curFrame, 'FilledCircle', ...
            [stickerX, stickerY, STICKER_RADIUS], ...
            'LineWidth', 1, 'Color', 'yellow', 'Opacity', STICKER_OPACITY);
    end
end

end