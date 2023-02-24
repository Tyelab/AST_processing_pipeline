# AST_processing_pipeline
Compute freeze/dash behavior from videos for Fergil Mill's AST project

Running Fergil Mills’ AST Behavioral Processing Pipeline
-	Currently uses SLEAP processed data but can import Alphatracker data 
-	Assumes that behavioral videos are all together in one folder and takes this as the starting point
Initial steps
1.	The first step is to gather the backup camera videos or other behavioral videos that you want to process. You will need the directory path to your videos in a later step.
You may need to convert them into mp4 or some other type of video that SLEAP can import.
Note that h264 encoding can be read by MATLAB but h265 cannot.
Below is an example of how to convert at the command line in a terminal window 
(‘conda activate sleap’ will let you use ffmpeg, if you have not already installed it separately):

ffmpeg -i input.asf -vcodec libx264 -crf 23 -pix_fmt yuv420p -vf scale=w=1280:h=720 output.mp4

-i 		is the file you want to convert (input file)

-vcodec 	tells which codec library you want to use, stick to libx264
Codec stands for code/decode and is a program that compresses your video so it can be stored and moved around, then decodes it for viewing.  It makes the size of the file manageable. (this option is an alias for 

-codec:v, which applies to the video part of your video 

-codec:a would apply to the audio part)

-crf	constant rate factor is an option available in the libex264 encoder to set the output quality, ranges from 0 (best lossless quality, largest file size) to 51 (poorest quality, smallest file size)** 

-pix_fmt 	set the pixel format. All videos contain a value called pixel format that tells you about how colors are ordered and organized.  There are many options here but this should work for what we need.

-vf	filter the video, this allows you to rescale (can use either option "scale=1280:720"  or scale=w=1280:h=720, they mean the same thing.)

The last part of the command is the name of the output file. It does not get an option flag. 
The output.mp4 can include the full directory path if you want to put it somewhere else. 
E.g., FFBatch/output.mp4

Can set up as a batch script to run through linux shell see the matlab code:
makeScript_convert_asf_264.m  which produces the example convert_h264.sh shell script located in /scripts/.  When you run this code, this script is saved to the same folder as your videos.

2.	Get together a set of labeled data in SLEAP, ideally corresponding to your behavioral videos.  The closer the labeled data is to your videos (e.g. lighting/resolution/mouse type/cagetype/etc.) the better the automated tracking will be.  It is often useful to label even 100 frames from each video you wish to track to get better correlation.
a.	For a single animal in a MEDPC box, you can start by using Fergil’s model.  At last count there were 6645 (!) labeled frames in this model.  Sleap file is here:
\\nadata\snlkt_ast\SLEAP\Sleap_phase4\fm_MedPC_Halo+Calc_v04_greyscale_v07_Christian.slp
and the corresponding models for making top-down predictions are here:
\\nadata\snlkt_ast\SLEAP\Sleap_phase4\models\220928_225407.centered_instance.n=6645
\\nadata\snlkt_ast\SLEAP\Sleap_phase4\models\220928_201257.centroid.n=6645
3.	Create a model by running training and inference in SLEAP.
(We don’t cover how to do this here, this is step can be a significant effort.)
In this work, we used 14 points to define the skeleton as follows:
 1 - 'nose',
 2 - 'left_ear_tip',
 3 -'left_ear_base',
 4 - 'right_ear_base',
 5 - 'right_ear_tip',
 6 - 'skull_base',
 7 - 'shoulders',
 8 - 'haunch',
 9 - 'tail_base',
 10  'tail_seg',
 11  'left_arm',
 12  'right_arm',
 13  'right_leg',
 14  'left_leg',

Run SLEAP tracking on videos
4.	You can run the model on one video at a time at the command line.  Alternatively, you can create a batch script, which will create a script that cycles through all the videos you want to run with the same commands.  
Run this function in MATLAB to generate a batch script to run tracking on each video with the model you created in SLEAP:
   sleap_batch_script_generator.m
You will need :
a.	the path to your videos, 
b.	the path to your output area 
c.	the SLEAP model for running tracking.
NOTE: You should run this matlab function through a linux shell if you plan to run the sleap tracking on a linux machine, otherwise the paths will not be convertible!  If you want to run on a Windows machine, you can open matlab in windows.  The paths will be created based on whatever machine matlab was running on.
% example top-down Command line call (should normally be all on one line if running in the terminal):
% sleap-track /nadata/snlkt/ast/SLEAP/SLEAP_VIDS/path-to-video.mp4 
% --frames 70593,58439,36296,28809,45460,43833 
% -m models/220517_125543.single_instance.n=5890/training_config.json 
% --tracking.tracker flow --tracking.target_instance_count 1 
% --tracking.pre_cull_to_target 1 --tracking.pre_cull_iou_threshold 0.8 
% --tracking.similarity instance --tracking.match greedy --tracking.track_window 5 
% --tracking.post_connect_single_breaks 1 
% -o predictions/20211007_Disc5_G3B2_C6_J588.mp4.220517_210851.predictions.slp 
% --verbosity json --no-empty-frames

5.	The matlab function will create a directory and folder to 
a.	hold the predictions (.h5 and .slp) files
b.	put the bash Command script 
6.	The script can be run on a single node on the cluster by just typing
> ./nameofscrip.sh
where nameofscript is the name of your shell script.   Alternatively, copy and paste individual lines (commands) into terminals at different nodes if you are in a hurry to run tracking and get SLEAP predictions.

Note, the matlab script will automatically make your nameofscrip.sh “executable” by using this command at the terminal window
> chmod u+x nameofscrip.sh

7.	After those copy, you can use the MATLAB function “copyNewPredictions” in
      make_analysis_folder_copy_files.m
to copy from the predictions folder into your folder structure.
Setting up folders and adding data
8.	While the SLEAP script is tracking the poses, you can set up the rest of your folders. See 
function “createProcessingFolder_copyVideos” in the matlab function make_analysis_folder_copy_files.m

(This function is set up to be copy-pasted into the command window in MATLAB. Adjust the paths then copy it in to create folders.)
It is helpful to name the folders based on the names of the original videos. 
In this project, we have basically assumed that all your files will have the same ‘root’ filename. For example, if your video is called 20210927_FCD1_G3B2_C6_J588.asf, then everything that follows will be stored in a folder called (20210927_FCD1_G3B2_C6_J588/) and contain the same base in every file name (20210927_FCD1_G3B2_C6_J588_SL_calc.mat).

Identify LED on/off times from videos
9.	This step can be done prior to SLEAP tracking completion.  If your video is already time synchronized to your other experimental data, you do not need to do this step.  The purpose of identifying when LED turns on or off is so that you know when a given event occurred, e.g. stimulus tone played.  In your experimental paradigm, each LED should be associated with a given event.  For example, in AST:
a.	LED 1 = reward tone
b.	LED 2 = port entry detected
c.	LED 3 = shock tone 
d.	LED 4 = miniscope camera is recording neural data (we did not record every trial)
e.	LED 5 = session is running (video might be started before/ended after the session begins, so this lets you know when the experiment began and ended)

10.	You need to identify when each LED is on/off in each video.  Example code to do this is here:
   msb_detectEventsLED.m
a.	Update the location of your data (c.dataDir), e.g., using the folder created in step 8 above.
b.	Update the c.folderNameCell to the correct folders in your data directory.
c.	This script will open the first frame of a video and allow you label the LED location by clicking on the image to define a region of interest (ROI). Each region of interest is expected to be a square (4 connected points).  After you create the square, hover over the area and your cursor will change from a circle to a double arrow.  Double click on the square to save the ROI and move onto the next LED.
d.	In AST paradigm, LED1 is the light closest to the port, LED 5 is farthest from port.  This orientation helps because sometimes the video camera is upside down, so the port is on the other side of the video.
11.	After you create the ROIs, the program will attempt to identify when the led is on using a change to the pixel values and output a png showing the number of times each light was on. In clean data, this works quite well.  However, if illumination changes or something (tether/mouse/experimenter’s hands) blocks the LED, you will not get the expected number of trials for each stimulus type.  
a.	You will need to manually check that these times line up with expectations by playing back the video at those times.  The matlab code to help do this is the function check_frames_by_LED.m
b.	If you got no LED detections or something looks horribly wrong, here is a quick matlab hack to try and detect using just the raw pixel values.  (Taken from checkFrames_by_LED.m) 
i.	Load the LEDevents.mat file in matlab
ii.	figure; plot(LEDevents.rawLEDs(:,1))hold on;    plot(LEDevents.evCellLED{1,1},LEDevents.rawLEDs(LEDevents.evCellLED{1,1},1),'go','MarkerFaceColor','g')    plot(LEDevents.evCellLED{1,2},LEDevents.rawLEDs(LEDevents.evCellLED{1,2},1),'ro','MarkerFaceColor','r')    plot(LEDevents.evCellLED{2,1},LEDevents.rawLEDs(LEDevents.evCellLED{2,1},1),'ko')    legend('LED-1','LED-1 onset (Rew)','LED-1 offset (Rew)', 'LED-2 onset (Port)')
title(Disc7folder,'Interpreter','none')
xlabel(‘Frame Number’); ylabel(‘brightness’)
 whole session
 (zoom view)
Blue spikes show change in LED1 illumination over time, green dot = detected onset, red = detected offset.  If you don’t get the expected red/green placement, you can zoom into the figure and use datatips to manually identify onset and offset. This sucks but it generally works. 
12.	This LED data is used to align video data to trials; you need time information about what tones/stimuli were played to know when a trial started in the video unless the video is synched to the medPC data. 

Process the pose estimates to get freeze/dash heatmaps
13.	Each folder should contain the prediction h5 from SLEAP and a copy of either the original movie (.asf) or its altered form used for SLEAP tracking (.mp4).
a.	Generally, it’s better to avoid copying files into folders.  A better approach here would be modify the code below and incorporate the full path to a folder containing your videos or LED results.  That way you don’t need to take up server space with copies of identical data!
14.	You are ready to calculate features from the pose estimates. We specifically calculated freeze and dash behavior.  
Freeze is defined as the sum over distances being less than freeze threshold, where the distances are defined as change in location of a given body part across current and previous frames (14 distances calculated).  
Dash is defined as the velocity of the haunch point being above the dash threshold.  Thresholds were tuned manually for each data cohort, and if needed for each session.
(Side note that “AlphaTracker code” folder has a blank space between “Alphatracker” and “code”.  Spaces in files or folder names should generally be avoided in the future!)  
a.	See \\nadata.snl.salk.edu\snlkt_ast\AlphaTracker\AlphaTracker code\LK_fmat_trackDataVidGen_Sleap_v16.m  (basic)
b.	\\nadata.snl.salk.edu\snlkt_ast\AlphaTracker\AlphaTracker code\LK_fmat_trackDataVidGen_oldEphys_v02b.m (in this version, we remove freeze labels on animals that freeze in port.  Freeze is typically considered a fear behavior and we did not have resolution in the pose estimates to identify motion due to licking at port. Instead, we just don’t label a freeze when the LED that indicates port entry is ON.)

15.	The matlab functions listed above allows you to 
a.	Convert the h5 file into a matlab structure and extract the necessary information (dataGen)
b.	Identify landmarks in the arena, currently finds the 4 corners of the cage floor and the location of the reward spout.  (calcGen)
This data is then used to compute certain meta features, such as 
i.	the speed the animal is moving, 
ii.	whether that speed corresponds to freezing or dashing behavior, 
iii.	animal’s distance from various locations (e.g. port).
c.	Generate videos to verify behavior labeling 
i.	(vidGen) Full video with pose estimates and frame number, along with indicator of freezing/dashing markers
ii.	(vidCS_shocks) Same video but for CS-Shock only portions only
iii.	(visGen) Visualizer video showing the labeled video in upper left subplot and two views of the scrolling visual of the average mouse motion compared to threshold settings used to determining freezing/dashing behaviors. (this is generally working in later versions but not consistently working in earlier versions.) Screenshot of resulting video:
 
16.	Each of the above will generate a file and save it to the appropriate folder (subject-based naming convention).
17.	Next generate trial-aligned heatmaps of the freezing/dashing behavior for each subject: \\nadata.snl.salk.edu\snlkt_ast\AlphaTracker\AlphaTracker code\ LK_plotFreezeDashHeatmaps_NPX_Disc4_v02.m 
18.	Finally, there is another matlab function that will let you make group plots. \\nadata.snl.salk.edu\snlkt_ast\AlphaTracker\AlphaTracker code\ LK_CalcGroupMetricsFreeze_ephysNPX_v02.m 
a.	Assumption is that there are 2 groups (paired/unpaired) so data is loaded in 2 parts, then plots are made from the resulting combined data.
b.	The data that is loaded comes from the freeze/dash in the previous step (17). The baseline or experimental or display windows should be consistent across the two functions (currently defined in each separately but they need to be the same). 
c.	These plots are saved to the main processing folder rather than to given subject folders.  


