function plot_sleap_vid

% input files
sleap_path_file_1 = '\\nadata.snl.salk.edu\snlkt_ast\Miniscope\expAnalysis\20220408_CACO2_backupCam_discClustering\SLEAP_processed_backupCam_Disc5_7_v4\predictions\20211007_Disc5_G1B1_C1_J640R.predictions.analysis.h5';
sleap_vid_1 = '\\nadata.snl.salk.edu\snlkt_ast\Miniscope\expAnalysis\20220408_CACO2_backupCam_discClustering\backupCam_Disc5_Disc7\FFBatch\20211007_Disc5_G1B1_C1_J640R.mp4';


% set up output video paths
outputVideo = VideoWriter('tracked.avi'); 


%% load sleap data
slp.instance_scores = h5read(sleap_path_file_1, '/instance_scores');
slp.node_names = h5read(sleap_path_file_1, '/node_names');
slp.point_scores = h5read(sleap_path_file_1, '/point_scores');
slp.track_names = h5read(sleap_path_file_1, '/track_names');
slp.track_occupancy = h5read(sleap_path_file_1, '/track_occupancy');
slp.tracking_scores = h5read(sleap_path_file_1, '/tracking_scores');
slp.tracks = h5read(sleap_path_file_1, '/tracks');
slp.file = sleap_path_file_1;

% smooth track data using Savitzky-Golay FIR smoothing filter
slp_unsmooth = slp;  % keep a copy of the unsmoothed data for now
slp.tracks = smoothdata(slp.tracks, 1, 'sgolay', 5); % slp now contains smoothed track data

disp('H5 loaded...')


%% load mp4
v = VideoReader(sleap_vid_1);



%% plot video
    
outputVideo.FrameRate = v.FrameRate;
open(outputVideo);
outFrame = 1; % differnt counter needed for sleap video and output video


fh = figure;

for frame = 1:10
    
    % set the time to correspond with the frame
    v.CurrentTime = frame/v.FrameRate;
    vidFrame = readFrame(v); % read that frame
    image(vidFrame); % plot the image
    hold on;
    
    % plot the keypoints
    nKeypoints = size(slp.tracks,2);
    keypoint_colormap = colormap(hsv(nKeypoints));  % set nodes as multicolor
    %keypoint_colormap = repmat([1 1 0],nKeypoints,1);  % set nodes as yellow
    for ii = 1:nKeypoints
        plot(slp.tracks(frame,ii,1),slp.tracks(frame,ii,2), 'o',...
            'MarkerFaceColor', keypoint_colormap(ii,:),...
            'markerEdgeColor', keypoint_colormap(ii,:)...
            )
    end
    legend(slp.node_names,'interpreter','none')
    
    % plot the edges
    plot_line_node1_node2(1, 3, frame, slp)
    plot_line_node1_node2(1, 4, frame, slp)
    plot_line_node1_node2(3, 6, frame, slp)
    plot_line_node1_node2(4, 6, frame, slp)
    
    writeVideo(outputVideo, outFrame);
    outFrame = outFrame + 1;
    clf
end


end


function plot_line_node1_node2(n1, n2,frame, slp)
% this function plots a line connecting two nodes from a SLEAP file
% the position data is in slp.tracks for a given frame and node number (n1
% or n2)
% 
hold on;
x = [slp.tracks(frame, n1,1);slp.tracks(frame,n2,1)];
y = [slp.tracks(frame, n1,2);slp.tracks(frame,n2,2)];
line(x,y,'color',[1 1 0]);
end
