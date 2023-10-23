
function makeScript_convert_asf_264
% This function will output a batch script to convert your videos to mp4.  
% 
% Usage
% -----
% Edit 'sourceVideoDir' and the file extension in vids to point to your data
% This will set up an FFMPEG batch script to convert your videos into 264
% encoding and save as mp4 files. 
%
% Open your Linux system and change the permissions like so to make the
% file an executable script: 
%     $chmod u+x convert_h264.sh
% Now you can run it at the command line.
%
% Notes below are helpful if your conversion using ffmpeg is slightly
% different from our base example.
% ----- 
% Note that h264 encoding can be read by MATLAB but h265 cannot.
% Below is an example of how to convert at the command line in a terminal
% window  
% Tyelab users note that ‘conda activate sleap’ will let you use ffmpeg, if
% you have not already installed it separately.
% 
% below is the example output of the ffmpeg command, where we have
% converted AND scaled the output video: 
% ffmpeg -i input.asf -vcodec libx264 -crf 23 -pix_fmt yuv420p -vf scale=w=1280:h=720 output.mp4
% 
%  -i 		is the file you want to convert (input file)
%  -vcodec 	tells which codec library you want to use, stick to libx264
%      Codec stands for code/decode and is a program that compresses
%      your video so it can be stored and moved around, then decodes
%      it for viewing.  It makes the size of the file manageable.
%      (this option is an alias for    
%  -codec:v, which applies to the video part of your video 
%  -codec:a would apply to the audio part)
%  -crf	constant rate factor is an option available in the libex264 encoder
%       to set the output quality, ranges from 0 (best lossless quality,
%       largest file size) to 51 (poorest quality, smallest file size)**   
%  -pix_fmt  set the pixel format. All videos contain a value called
%       pixel format that tells you about how colors are ordered and
%       organized.  There are many options here but this should work for
%       what we need.   
%  -vf	filter the video, this allows you to rescale (can use either option
%       "scale=1280:720"  or scale=w=1280:h=720, they mean the same thing.) 
%       The last part of the command is the name of the output file. It
%       does not get an option flag.  
%       The output.mp4 can include the full directory path if you want to
%       put it somewhere else.  E.g., FFBatch/output.mp4
% 
% Written by Laurel Keyes, Aug 4, 2022


%% -------------------------------
% EDIT LINE BELOW TO POINT TO YOUR DATA:
% MAKE SURE YOU HAVE SET THE CORRECT FILE TYPE FOR YOUR VIDEOS (.asf, .wmv,
% etc)

% set the path directly:
% sourceVideoDir ='\\nadata.snl.salk.edu\snlkt_ast\Miniscope\expAnalysis\20220803_D1_DiscD6_backupCam\sourceFiles\';
% or have the user navigate to their folder:


if ispc
    topdir = '\\nadata.snl.salk.edu\snlkt_ast\Miniscope\expAnalysis\20220803_D1_DiscD6_backupCam\sourceFiles\';
elseif isunix
    topdir = ('/snlkt/ast/Miniscope/expAnalysis/20220803_D1_DiscD6_backupCam/sourceFiles/');
end
sourceVideoDir = uigetdir(topdir,'Select the location of your source videos (*.asf)');
vids = dir(fullfile(sourceVideoDir,'*.asf')); 
if isempty(vids), error('Did you set the file type correctly in %s? no asf files found in %s', mfilename, sourceVideoDir);end

outfile = fullfile(sourceVideoDir, 'convert_h264_test.sh');
% check if this file exists so you don't accidentally overwrite something
if ~exist(outfile,'file')
    fid = fopen(outfile,'w');
else
    %fid = -1;
    error('File exists! (Delete the old or give it a new name.)')
end

fprintf(fid,'#! /bin/bash -p\n'); % header line for linux systems
txt = sprintf('# This file was generated automatically on %s using the matlab function: %s\n', date, mfilename);
fprintf(fid,txt);
fprintf(fid,'This is a batch script for converting video files to mp4. \n');
% loop through the videos in your folder
for ii = 1:numel(vids)
if strcmp(vids(ii).name,'.') || strcmp(vids(ii).name,'..'); continue; end

[~,baseName,~] = fileparts(vids(ii).name); % this strips off the .asf and just returns the file name
text_line = sprintf('ffmpeg -i %s.asf -vcodec libx264 -crf 23 -preset veryfast -pix_fmt yuv420p -vf "scale=1280:720" FFBatch/%s.mp4\n', baseName, baseName);
fprintf(fid, text_line);
end

fclose(fid);
fprintf('Done!\n\n')


if isunix
    % this line attempts to make the script an executable     
    system(sprintf('chmod u+x %s',script_path))
end

%fprintf('Reminder: At a linux shell command line type: chmod u+x convert_h264_test.sh\n')
fprintf('Run the script in a linux shell.\n')
