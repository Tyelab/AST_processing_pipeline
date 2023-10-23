function [c,script_path] = sleap_batch_script_generator
% [c,script_path] = sleap_batch_script_generator
%
% This function will generate a command line script to run sleap-track and
% sleap-convert using a specified SLEAP model.  (that is, this script
% assumes you have already trained a SLEAP model).
%
% This particular function is currently set up to run a top-down model that
% uses centroid model, followed by a centered-instance model to identify a
% single mouse.  It uses a flow tracker to connect tracks and will always
% output one and only one track for every frame. These parameters can be
% altered to fit your desired model.  Please view the options at
% http://sleap.ai
%
% Tyelab: to run the commands in Linux, open matlab from within a Linux
% shell so that the file paths will be set for a linux environment.
%
%
% Written by Laurel Keyes, September 30, 2022


%% SETUP

% UPDATE THE DIRECTORY STRUCTURE TO POINT TO THE RIGHT LOCATION ON THE
% SERVER
if ispc
    topdir = '\\nadata.snl.salk.edu\snlkt_ast\';
elseif isunix
    topdir = '/nadata/snlkt/ast/';
end

% UPDATE THE FOLLOWING TO POINT TO YOUR DATA
error('User must update the video, output, prediction, and models directories to point to YOUR data')
c.vidDirectory    = fullfile(topdir,'Miniscope','expAnalysis','20220902_oldEphysVids','sourceVids','FFBatch');
c.outputDirectory = fullfile(topdir,'Miniscope','expAnalysis','20220902_oldEphysVids','SLEAP_processed_oldEphysVids_v2');
c.predictionDirectory = fullfile(c.outputDirectory,'predictions');
c.training_config_centroid = fullfile(topdir,'SLEAP','Sleap_phase4','models','220919_172147.centroid.n=6277','training_config.json');
c.training_config_centered_instance = fullfile(topdir,'SLEAP','Sleap_phase4','models','220919_212713.centered_instance.n=6277','training_config.json');
c.vidSuffix = '.mp4';

% Create the prediction directory
if ~exist(c.outputDirectory,'dir')
    mkdir(c.predictionDirectory)
end

% Note, you can quickly list all files in folder by uncommenting this next
% line and then copying them into c.folderNameCell below
%    d = dir(c.vidDirectory); {d.name}'


% UPDATE HERE TO POINT TO YOUR SPECIFIC DATA FOLDERS
error('User must update the folderNameCell to point to YOUR data')
c.folderNameCell = {...
    '6197daijobu_20190718DiscD4'  ;...
    '6253daisy_20190913DISCD3'    ;...
    '7049ivy_20190914DISCD4'      ;...
    '6429durian_20191016DISCD5'   ;...
    '7008ikari_20190718DiscD4'    ;...
    '3014illidan_20180926_DiscD4' ;...
    '3016donkey_20180810_DiscD4'  ;...
    '3024ishmael_20180810_Disc4'  ;...
    '3026deng_20181128_DiscD2'    ;...
    '3029iouxio_20181128_DiscD2'  ;...
    };

Sleap_Command_script = ['Sleap_Command_script_',mfilename];
disp(['Commands will be saved to ', Sleap_Command_script])

% % % % get number of frames in each mp4 in folder
% % % nFrames = nan(length(c.folderNameCell),1);
% % % for folderNum = 1:length(c.folderNameCell)
% % %     tic
% % %     disp([c.vidDirectory c.folderNameCell{folderNum} c.vidSuffix])
% % %     v = VideoReader([c.vidDirectory c.folderNameCell{folderNum} c.vidSuffix]);
% % %     nFrames(folderNum) = v.NumFrames;
% % %     toc
% % % end


% sleap-track '/nadata/snlkt/data/Chris/TCoSI/01_Media_Files/Trial_7_conv.mp4'
% --model TCoSI_Intruder_v003_220706_161643.centered_instance.n=439
% --model TCoSI_Intruder_v003_220706_160909.centroid.n=439
% --frames 1-2000
% -o segment_vid7_0
% --gpu 3
% --tracking.tracker flow
% --tracking.target_instance_count 1
% --tracking.post_connect_single_breaks 1
% --tracking.clean_instance_count 1


commandString = cell(length(c.folderNameCell),1);

for folderNum = 1:length(c.folderNameCell)
    
    % I think this command is appropriate for a single animal model
    % It needs to be updated if you have a top-down model to account for
    % the two models (centroid and centered-instance)
    commandStringTemp = [...
        'sleap-track ' fullfile(c.vidDirectory, [c.folderNameCell{folderNum} c.vidSuffix]) ...%
        ' -m ', c.training_config_centroid ... %
        ' -m ', c.training_config_centered_instance ...%       ' --frames 0,-' nFrames(folderNum) ...
        ' --gpu 0 ',...
        ' --tracking.tracker flow' ...%
        ' --tracking.target_instance_count 1 ' ...
        ' --tracking.pre_cull_to_target 1' ...
        ' --tracking.pre_cull_iou_threshold 0.8' ...
        ' --tracking.similarity instance' ...
        ' --tracking.match greedy' ...
        ' --tracking.track_window 30' ...
        ' --tracking.post_connect_single_breaks 1' ...
        ' --tracking.clean_instance_count 1' ...
        ' -o ' fullfile(c.predictionDirectory, [c.folderNameCell{folderNum} '.predictions.slp']) ...
        ' --verbosity json' ...        ' --no-empty-frames' ...
        ' > runfile_',c.folderNameCell{folderNum},'.log '... % this line will pipe output to a log file instead of printing to screen
        ';' ...
        ' sleap-convert --format analysis -o "' fullfile(c.predictionDirectory, [c.folderNameCell{folderNum} '.predictions.analysis.h5']) '" "' fullfile(c.predictionDirectory, [c.folderNameCell{folderNum} '.predictions.slp']) '"' ...
        ' ; ',...
        ];
    
    
    % example top-down Command line call:
    % sleap-track /nadata/snlkt/ast/SLEAP/SLEAP_VIDS/calcvids_caco2disc57/20211007_Disc5_G3B2_C6_J588.mp4
    % --frames 70593,58439,36296,28809,45460,17368,51418,10169,62428,60574,24734,48353,29095,3752,77608,5546,8680,23917,11509,43833
    % -m models/220517_125543.single_instance.n=5890/training_config.json
    % --tracking.tracker flow --tracking.target_instance_count 1
    % --tracking.pre_cull_to_target 1 --tracking.pre_cull_iou_threshold 0.8
    % --tracking.similarity instance --tracking.match greedy --tracking.track_window 5
    % --tracking.post_connect_single_breaks 1
    % -o predictions/20211007_Disc5_G3B2_C6_J588.mp4.220517_210851.predictions.slp
    % --verbosity json --no-empty-frames
    
    
    commandString{folderNum} = commandStringTemp;
    
end

% commandStringAll = strjoin(commandString);
% Laurel added write commands to a batch script for Linux systems.
% Should be able to run the script with the command
%     $ bash Sleap_Command_script.sh
% ( this is untested for Windows systems)
if ispc
    script_path = fullfile(c.outputDirectory,[Sleap_Command_script,'.bat']);
    fid = fopen(script_path,'w');
    if fid<0,error('Could not open for writing: %s',script_path);end
    %     % write a header to the script file telling how it was generated and when
    %     fprintf(fid,'#!/bin/bash\n');
    %     fprintf(fid,sprintf('#Created automatically on %s using MATLAB function: %s\n',datestr(datetime),mfilename));
    %     fprintf(fid,'#\n');
elseif isunix
    script_path = fullfile(c.outputDirectory,[Sleap_Command_script,'.sh']);
    
    fid = fopen(script_path,'w');
    if fid<0,error('Could not open for writing: %s',script_path);end
    % write a header to the script file telling how it was generated and when
    fprintf(fid,'#!/bin/bash\n');
    fprintf(fid,sprintf('#Created automatically on %s using MATLAB function: %s\n',datestr(datetime),mfilename('fullpath')));
    fprintf(fid,'#\n');
end

% write each command line to the script
for folderNum = 1:length(c.folderNameCell)
    if ispc
        fprintf(fid,sprintf("%s\n", strrep(commandString{folderNum},'\','\\')  ));
        fprintf(fid,'#\n'); % print commented line break between function calls
    elseif isunix
        fprintf(fid,sprintf("%s\n", commandString{folderNum}  ));
        fprintf(fid,'#\n'); % print commented line break between function calls
    end
end
fclose(fid); % close the file
if isunix
    % this line attempts to make the script an executable 
    
    system(sprintf('chmod u+x %s',script_path))
end

fprintf(sprintf('Done.  Script is located in %s\n',script_path))

end