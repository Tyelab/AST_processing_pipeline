
function make_analysis_folder_copy_files
% make_analysis_folder_copy_files
%
% this function is utility script for setting up a new folder structure and
% copying in relevant files
% This script follows the folder structure used for the Mill's AST
% processing pipeline.
% Typically, there was a main cohort as the top level folder, e.g.
% oldEphysVids  
%      |
%       ----- SourceVideos
%       ----- SLEAP_processed_outputs
%       ----- matlab_processed_outputs
% 

% The various functions in this script are mean to be copy/pasted into the
% matlab command window

main_dir = '\\nadata.snl.salk.edu\snlkt_ast\Miniscope\expAnalysis\20220902_oldEphysVids';
dir_to_copy = 'lk_processed_oldEphysVids_v1';


% this is where you are copying the NEW data to:
output_folder = 'lk_processed_oldEphysVids_v2';
mkdir(fullfile(main_dir,output_folder));

% get Disc5 disc7 folders and write in new folder
folders=dir(fullfile(main_dir,dir_to_copy));
for ii = 1:numel(folders)   
    if strcmp(folders(ii).name,'.') || strcmp(folders(ii).name,'..') || ~folders(ii).isdir, continue, end
    
    % make the folder in new output area
    disp([' making ',folders(ii).name])
    mkdir(fullfile(main_dir,output_folder,folders(ii).name))
    
    % copy the asf info into that folder    
    disp(['     copying ',[folders(ii).name,'.mp4']])
    src = fullfile(main_dir,dir_to_copy,folders(ii).name,[folders(ii).name,'.mp4']);
    dst = fullfile(main_dir, output_folder,folders(ii).name,[folders(ii).name,'.mp4']);
    copyfile(src,dst)
    
%     % check if an mp4 exists and if so, copy it in 
%     src = fullfile(mdir,dir_to_copy,folders(ii).name,[folders(ii).name,'.mp4']);
%     
%     mp4_dir = dir(src);
%     if ~isempty(    mp4_dir )     
%         disp(['     copying ',[folders(ii).name,'.mp4']])
%         dst = fullfile(mdir, output_folder,folders(ii).name,[folders(ii).name,'.mp4']);
%         copyfile(src,dst)
%     end
    
    
    % copy the LED into into that folder
    disp(['     copying ',[folders(ii).name,'_LEDfigure.png']])
    src = fullfile(main_dir,dir_to_copy,folders(ii).name,[folders(ii).name,'_LEDfigure.png']);
    dst = fullfile(main_dir, output_folder,folders(ii).name,[folders(ii).name,'_LEDfigure.png']);
    copyfile(src,dst)
    
    % copy LED events into folder
    disp(['     copying ',[folders(ii).name,'_LEDevents.mat']])
    src = fullfile(main_dir,dir_to_copy,folders(ii).name,[folders(ii).name,'_LEDevents.mat']);
    dst = fullfile(main_dir, output_folder,folders(ii).name,[folders(ii).name,'_LEDevents.mat']);
    copyfile(src,dst)
    
    % copy any settings files
    src = fullfile(main_dir,dir_to_copy,folders(ii).name,[folders(ii).name,'_settings.mat']);
    setting_dir = dir(src);
    if ~isempty(    setting_dir ) 
        disp(['     copying ',[folders(ii).name,'_settings.mat']])
        dst = fullfile(main_dir, output_folder,folders(ii).name,[folders(ii).name,'_settings.mat']);
        copyfile(src,dst)
    end
    
    disp(['     copying ',[folders(ii).name,'_LEDROIs.mat']])
    src = fullfile(main_dir,dir_to_copy,folders(ii).name,[folders(ii).name,'_LEDROIs.mat']);
    dst = fullfile(main_dir, output_folder,folders(ii).name,[folders(ii).name,'_LEDROIs.mat']);
    copyfile(src,dst)
    
    % copy the SLEAP arena and calc into that folder
    % this should be the same even if you update the 
    disp(['     copying ',[folders(ii).name,'_SL_arena.mat']])
    src = fullfile(main_dir,dir_to_copy,folders(ii).name,[folders(ii).name,'_SL_arena.mat']);
    dst = fullfile(main_dir, output_folder,folders(ii).name,[folders(ii).name,'_SL_arena.mat']);
    copyfile(src,dst)
    
   % copy any text files into new area (usually notes about LED onsets or
   % experimental details that might be useful
    src = fullfile(main_dir,dir_to_copy,folders(ii).name,'*.txt');
    txt_dir = dir(src);
    if ~isempty(    txt_dir )     
        disp(['     copying ',txt_dir(1).name])
        for tt = 1:numel(txt_dir)            
            src = fullfile(main_dir,dir_to_copy,folders(ii).name,txt_dir(tt).name);
            dst = fullfile(main_dir, output_folder,folders(ii).name,txt_dir(tt).name);        
            copyfile(src,dst)
        end
    end
    
end

disp('Done!\n')

end

function copyPredictions(main_dir, dir_to_copy, output_folder)
% copyPredictions(mdir, dir_to_copy, output_folder)
% 
% this will specifically copy the predictions from a given folder to a new
% folder

% folder containing predictions:

main_dir = '\\nadata.snl.salk.edu\snlkt_ast\Miniscope\expAnalysis\20220902_oldEphysVids\';
dir_to_copy = '\\nadata.snl.salk.edu\snlkt_ast\Miniscope\expAnalysis\20220902_oldEphysVids\SLEAP_processed_oldEphysVids_v2\predictions\';

% this is where you are copying the NEW data to:
output_folder = '\\nadata.snl.salk.edu\snlkt_ast\Miniscope\expAnalysis\20220902_oldEphysVids\lk_processed_oldEphysVids_v2\';

% get data folders and write in new folder
folders=dir(dir_to_copy);
for ii = 1:numel(folders)   
    if strcmp(folders(ii).name,'.') || strcmp(folders(ii).name,'..') || ~folders(ii).isdir, continue, end
    %1 make the folder in new output area
    disp([' making ',folders(ii).name])
    mkdir(fullfile(main_dir,output_folder,folders(ii).name))
    
    % copy the h5 info into that folder    
    disp(['     copying ',[folders(ii).name,'.h5']])
    src = fullfile(main_dir,dir_to_copy,folders(ii).name,[folders(ii).name,'.predictions.analysis.h5']);
    dst = fullfile(main_dir, output_folder,folders(ii).name,[folders(ii).name,'.predictions.analysis.h5']);
    copyfile(src,dst)
    
    if 0
    % copy the sleap info into that folder    
    disp(['     copying ',[folders(ii).name,'.slp']])
    src = fullfile(main_dir,dir_to_copy,folders(ii).name,[folders(ii).name,'.predictions.slp']);
    dst = fullfile(main_dir, output_folder,folders(ii).name,[folders(ii).name,'.predictions.slp']);
    copyfile(src,dst)
    
    end
end
fprintf('Done!\n')

end




function copyNewPredictions(main_dir, dir_to_copy, output_folder)
% copyPredictions(main_dir, dir_to_copy, output_folder)
% 
% this will specifically copy the predictions from a given folder to a new
% folder

% folder containing predictions:

main_dir = '\\nadata.snl.salk.edu\snlkt_ast\Miniscope\expAnalysis\20220902_oldEphysVids\';
dir_to_copy = 'SLEAP_processed_oldEphysVids_v2\predictions';

% this is where you are copying the NEW data to:
output_folder = 'lk_processed_oldEphysVids_v2';

% get Disc5 disc7 folders and write in new folder
folders=dir(fullfile(main_dir,output_folder));
for ii = 1:numel(folders)   
    if strcmp(folders(ii).name,'.') || strcmp(folders(ii).name,'..') || ~folders(ii).isdir, continue, end
    %1 make the folder in new output area
    disp([' Working ',folders(ii).name])
    % mkdir(fullfile(main_dir,output_folder,folders(ii).name))
    
    % copy the h5 info into that folder    
    disp(['     copying ',[folders(ii).name,'.h5']])
    src = fullfile(main_dir,dir_to_copy,[folders(ii).name,'.predictions.analysis.h5']);
    dst = fullfile(main_dir, output_folder,folders(ii).name,[folders(ii).name,'.predictions.analysis.h5']);
    copyfile(src,dst)
    
    % copy the sleap info into that folder    
    disp(['     copying ',[folders(ii).name,'.slp']])
    src = fullfile(main_dir,dir_to_copy,[folders(ii).name,'.predictions.slp']);
    dst = fullfile(main_dir, output_folder,folders(ii).name,[folders(ii).name,'.predictions.slp']);
    copyfile(src,dst)
    
end
fprintf('Done!\n')

end





function createProcessingFolder_copyVideos
% When you are setting up a new output area, this function will 
%  1. make the output directory
%  2. make the individual folders in the output directory using video names
%  3. copy video into correct folder


% set the name of your base directory for output 
main_dir = '\\nadata.snl.salk.edu\snlkt_ast\Miniscope\expAnalysis\20220902_oldEphysVids\';
% set the name of your NEW directory to create
output_folder = 'lk_processed_oldEphysVids_v2';
mkdir(fullfile(main_dir,output_folder));

% location of videos you want to copy to new directory
dir_to_copy = '\\nadata.snl.salk.edu\snlkt_ast\Miniscope\expAnalysis\20220902_oldEphysVids\sourceVids\FFBatch\';

% 1. make all the subfolders in output dir based on names these files
vids = dir(fullfile(dir_to_copy,'*.mp4')); % make sure to match type of video extension!
for ii = 1:numel(vids)   
    [~,folder,~] = fileparts(vids(ii).name);
    mkdir(fullfile(main_dir,output_folder, folder))
    disp(['Made ',folder])    
    
    % copy in the original video
    copyfile(fullfile(vids(ii).folder, vids(ii).name), fullfile(main_dir,output_folder, folder, vids(ii).name))
end


disp('Done!\n')

end