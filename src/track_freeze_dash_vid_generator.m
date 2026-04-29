function track_freeze_dash_vid_generator(varargin)
% track_freeze_dash_vid_generator(varargin)
% 
%
% notes about this function
% 1) pose data is from the 'native' sleap labels with 14 points
%    pose data was stored in \\nadata.snl.salk.edu\snlkt_ast\Miniscope\expAnalysis\20220705_CACO3_backupCam_D1_DISC5\SLEAP_processed_backupCam_D1_Disc5_v1\
% 2) visualizer is NOT working in this verison for shock only events
%    ** have to find out what's going wrong with call to scrolling bars
% 3) this version of LK_fmat_trackDataVidGen_D1_Disc5_v3 was updated to
%    filter freezes in port (when mouse is acutally collecting reward)
%    using the nose-to-port or LED1 on data (however, for Chris Lee data,
%    we do not track port entries in the events structure)
% 4) Chris Lee Disc data has 
%        - 46 reward trials 
%        - 14 shock trials. 
% bottom LED represents CS-R and the LED above that represents CS-S
%
% this filters freezes in port
%%  SETUP

%% SEE NOTES AFTER CONTROL PANEL
%% CONTROL PANEL
if ispc
    topdir = '\\ktdata\snlkt\';    
elseif isunix
    topdir = '/snlkt';
end
addpath(fullfile(topdir,'ast','AlphaTracker','AlphaTracker code','Utils','distance_point_to_line')) % adds point_to_line_distance.m
% 0 = Don't generate, 1 = Generate, 
% todo: implement overwrite value with warning to use
c.dataGen   = 0; % Toggle 1 to generate a data file.
c.calcGen   = 0; % Toggle 1 to generate calculations from file.   Requires data, LED output.  (REQUIRES LED to filter out freezing in port!)
c.vidGen    = 0; % Toggle 1 to generate a video.                  Requires data,calc output.
c.vidCS_shocks = 0; % Toggle 1 to generate a video(CS_shock only) Requires data,calc,LED output.
c.vidCS_rew = 0; % Toggle 1 to generate a video(CS_shock only)    Requires data,calc,LED output.
c.visGen    = 1; % Toggle 1 to generate visualizer video.         Requires data,calc,vid,LED output.

% Data directories
%c.dataDir = '\\nadata.snl.salk.edu\snlkt_ast\Miniscope\expAnalysis\20220504_Sleap_shorttest\'
c.dataDirTop = fullfile(topdir,'lonelee');
c.slpDir = fullfile(c.dataDirTop, 'SIV','02_Processed','bonsai','03_slpFiles');
c.vidDir = fullfile(topdir,'lonelee','SIV','02_Processed','bonsai','02_convertedVids');
c.h5Dir = fullfile(topdir,'lonelee','SIV','02_Processed','bonsai','04_hd5Files');
c.outputDir =  fullfile(topdir,'lonelee','SIV','02_Processed','bonsai','05_discOutputs');
c.inputVidSuffix = '.mp4';

%c.inputJsonSuffix ='_behCamAll-alphapose-results-forvis-tracked';
c.inputH5Suffix ='.analysis.h5';

% quick generate all files in folder
% d = dir(c.dataDir); {d.name}'

c.folderNameCell = {...
    '250424_SIV_1-0_Disc7_conv.mp4';...
    % '250424_SIV_1-1_Disc7_conv.mp4';...
    % '250424_SIV_1-3_Disc7_conv.mp4';...
    % '250424_SIV_2-0_Disc7_conv.mp4';...
    % '250424_SIV_2-2_Disc7_conv.mp4';...
    % '250424_SIV_2-3_Disc7_conv.mp4';...
    % '250424_SIV_3-0_Disc7_conv.mp4';...
    % '250424_SIV_3-1_Disc7_conv.mp4';...
    % '250424_SIV_3-2_Disc7_conv.mp4';...
    % '250424_SIV_4-0_Disc7_conv.mp4';...
    % '250424_SIV_4-1_Disc7_conv.mp4';...
    % '250424_SIV_4-2_Disc7_conv.mp4';...
    % '250425_SIV_1-0_Disc8_conv.mp4';...
    % '250425_SIV_1-1_Disc8_conv.mp4';...
    % '250425_SIV_1-3_Disc8_conv.mp4';...
    % '250425_SIV_2-0_Disc8_conv.mp4';...
    % '250425_SIV_2-2_Disc8_conv.mp4';...
    % '250425_SIV_2-3_Disc8_conv.mp4';...
    % '250425_SIV_3-0_Disc8_conv.mp4';...
    % '250425_SIV_3-1_Disc8_conv.mp4';...
    % '250425_SIV_3-2_Disc8_conv.mp4';...
    % '250425_SIV_4-0_Disc8_conv.mp4';...
    % '250425_SIV_4-1_Disc8_conv.mp4';...
    % '250425_SIV_4-2_Disc8_conv.mp4';...
    % '250430_SIV_1-0_Disc_24hr_conv.mp4';...
    % '250430_SIV_1-1_Disc_24hr_conv.mp4';...
    % '250430_SIV_1-3_Disc_24hr_conv.mp4';...
    % '250430_SIV_2-0_Disc_24hr_conv.mp4';...
    % '250430_SIV_2-2_Disc_24hr_conv.mp4';...
    % '250430_SIV_2-3_Disc_24hr_conv.mp4';...
    % '250430_SIV_3-0_Disc_24hr_conv.mp4';...
    % '250430_SIV_3-1_Disc_24hr_conv.mp4';...
    % '250430_SIV_3-2_Disc_24hr_conv.mp4';...
    % '250430_SIV_4-0_Disc_24hr_conv.mp4';...
    % '250430_SIV_4-1_Disc_24hr_conv.mp4';...
    % '250430_SIV_4-2_Disc_24hr_conv.mp4';...
    % '250506_SIV_1-0_Disc_7d_conv.mp4';...
    % '250506_SIV_1-1_Disc_7d_conv.mp4';...
    % '250506_SIV_1-3_Disc_7d_conv.mp4';...
    % '250506_SIV_2-0_Disc_7d_conv.mp4';...
    % '250506_SIV_2-2_Disc_7d_conv.mp4';...
    % '250506_SIV_2-3_Disc_7d_conv.mp4';...
    % '250506_SIV_3-0_Disc_7d_conv.mp4';...
    % '250506_SIV_3-1_Disc_7d_conv.mp4';...
    % '250506_SIV_3-2_Disc_7d_conv.mp4';...
    % '250506_SIV_4-0_Disc_7d_conv.mp4';...
    % '250506_SIV_4-1_Disc_7d_conv.mp4';...
    % '250506_SIV_4-2_Disc_7d_conv.mp4';...
    % '250513_SIV_1-0_Disc_14d_conv.mp4';...
    % '250513_SIV_1-1_Disc_14d_conv.mp4';...
    % '250513_SIV_1-3_Disc_14d_conv.mp4';...
    % '250513_SIV_2-0_Disc_14d_conv.mp4';...
    % '250513_SIV_2-2_Disc_14d_conv.mp4';...
    % '250513_SIV_2-3_Disc_14d_conv.mp4';...
    % '250513_SIV_3-0_Disc_14d_conv.mp4';...
    % '250513_SIV_3-1_Disc_14d_conv.mp4';...
    % '250513_SIV_3-2_Disc_14d_conv.mp4';...
    % '250513_SIV_4-0_Disc_14d_conv.mp4';...
    % '250513_SIV_4-1_Disc_14d_conv.mp4';...
    % '250513_SIV_4-2_Disc_14d_conv.mp4';...
    % '250520_SIV_1-0_Disc_21d_conv.mp4';...
    % '250520_SIV_1-1_Disc_21d_conv.mp4';...
    % '250520_SIV_1-3_Disc_21d_conv.mp4';...
    % '250520_SIV_2-0_Disc_21d_conv.mp4';...
    % '250520_SIV_2-2_Disc_21d_conv.mp4';...
    % '250520_SIV_2-3_Disc_21d_conv.mp4';...
    % '250520_SIV_3-0_Disc_21d_conv.mp4';...
    % '250520_SIV_3-1_Disc_21d_conv.mp4';...
    % '250520_SIV_3-2_Disc_21d_conv.mp4';...
    % '250520_SIV_4-0_Disc_21d_conv.mp4';...
    % '250520_SIV_4-1_Disc_21d_conv.mp4';...
    % '250520_SIV_4-2_Disc_21d_conv.mp4';...
    % '250527_SIV_1-0_Disc_28d_conv.mp4';...
    % '250527_SIV_1-1_Disc_28d_conv.mp4';...
    % '250527_SIV_1-3_Disc_28d_conv.mp4';...
    % '250527_SIV_2-0_Disc_28d_conv.mp4';...
    % '250527_SIV_2-2_Disc_28d_conv.mp4';...
    % '250527_SIV_2-3_Disc_28d_conv.mp4';...
    % '250527_SIV_3-0_Disc_28d_conv.mp4';...
    % '250527_SIV_3-1_Disc_28d_conv.mp4';...
    % '250527_SIV_3-2_Disc_28d_conv.mp4';...
    % '250527_SIV_4-0_Disc_28d_conv.mp4';...
    % '250527_SIV_4-1_Disc_28d_conv.mp4';...
    % '250527_SIV_4-2_Disc_28d_conv.mp4';...
    };

if ~isempty(varargin)
    % select specific folders using input values
    InputFolderIndex = varargin{1};
    c.folderNameCell = c.folderNameCell(InputFolderIndex);
end

c.saveMouseDataNameSuffix = '_SL_mouseData.mat';
c.saveCalcNameSuffix = '_SL_calc.mat';
c.saveArenaNameSuffix = '_SL_arena.mat' ;
c.arenaWidth = 24.1; %indside width of the test chamber in cm

% DATA GENERATION SETTINGS
% Smoothing settings - calc data
c.smoothing.settings.type = 123;

% ANALYSIS SETTINGS
% Freezing
c.freezeSettings.thresh = 0.05; % Threshold for freezing (total change in pixel distance for all points)
c.freezeSettings.thresh_cm = 0.05; % Threshold for freezing (total change in pixel distance for all points) %was 0.02
c.freezeSettings.operator = 'less'; % Condition will return true when data LESS than threshold
c.freezeSettings.minFrames = 5; % Minimum frames a freezing bout must last to not be discarded
c.freezeSettings.gapTol = 4; % Gap filling tolerance for frames of freezing
c.freezeSettings.REMOVE_FREEZES_IN_PORT = 0; % if true, removes any freeze label when the port entry LED 2 is ON
c.freezeSettings.LEDPortEntryNumber = 2;

% for 14 points:
% 1 - 'nose',
% 2 - 'left_ear_tip',
% 3 -'left_ear_base',
% 4 - 'right_ear_base',
% 5 - 'right_ear_tip',
% 6 - 'skull_base',
% 7 - 'shoulders',
% 8 - 'haunch',
% 9 - 'tail_base',
% 10  'tail_seg',
% 11  'left_arm',
% 12  'right_arm',
% 13  'right_leg',
% 14  'left_leg',
c.freezeSettings.relevantPoints = 1:14; % Specifies which points to look at when evaluating freezing
warning('Using %d nodes to calculate freezing', numel(c.freezeSettings.relevantPoints))


% Movement (From haunch point)
c.haunchPointID = 8; % specifies which point is the haunch
c.nosePointID = 1;
c.dashSettings.thresh = 0.85; % Velocity of haunch point above which scored as dashing.
c.dashSettings.thresh_cm = 0.85 ;% Velocity of haunch point above which scored as dashing.
c.dashSettings.operator = 'greater'; % Condition will return true when data GREATER than threshold
c.dashSettings.minFrames = 2; % Minimum frames a freezing bout must last to not be discarded
c.dashSettings.gapTol = 2; % Gap filling tolerance for frames of freezing

% VIDEO OUTPUT SETTINGS
c.smoothed.plotPoints = 1; % Toggle 1 to plot smoothed points
c.smoothed.plotLines = 1;
c.smoothed.pointColorStyle = 'confidence'; % Can be 'multicolor', 'confidence' of specific a color ('red', 'green')
c.smoothed.lineColorStyle = 'white'; % Can be 'multicolor', 'confidence' of specific a color ('red', 'green')

c.unsmoothed.plotPoints = 0; % Toggle 1 to plot unsmoothed points
c.unsmoothed.plotLines = 0;
c.unsmoothed.pointColorStyle = 'confidence'; % Can be 'multicolor', 'confidence' of specific a color ('red', 'green')
c.unsmoothed.lineColorStyle = 'white'; % Can be 'multicolor', 'confidence' of specific a color ('red', 'green')

% take a sample video and get the correct frame rate
c.outputVidFrameRate = 30;  % this is an assumed outputVid rate but should be based on the input video so they match
c.labelVidLengthFrames = 9000;

c.box.plotLines = 0; % Toggle 1 to plot YOLO-derived box
c.box.colorStyle = 'yellow';

% Color settings
c.pointColors = {[1 0 0];[0 1 0];[0 0 1];[1 1 0];[0 1 1];[1 0 1];[1 1 1];[0 0 0];[1 0 0];[0 1 0];[0 0 1]}; % define normalized colors
c.pointColors = cellfun(@(x) x*255,c.pointColors,'UniformOutput',0); % converts normalized [0,1] colors to 8-bit RGB [0,255]
c.confColorMap = [round(linspace(255, 50, 256))', round(linspace(0, 0, 256))', round(linspace(0, 212, 256))'];

% Point settings
c.linkPoints = {[1 3];[1 4];[2 3];[4 5];[3 6];[4 6];[6 7];[7 8];[8 9];[9 10];[7 11];[7 12];[8 13];[8 14]}; % Anno14

% Stickers
c.stickerPointID = [7 8]; % Which points to use to place the freezing dot in the XY average. Can be 1 point or multiple points.
c.sticker.plotFreeze = 1; % Toggle 1 to plot freezing dot on 'sticker point' mouse back during freeze bouts.
c.sticker.plotDash = 1; % Toggle 1 to plot freezing dot on 'sticker point' mouse back during freeze bouts.

% MISCELLANEOUS
c.labelFrameNum = 1;  % Print frame number
c.labelArenaEdges = 1; % Toggle 1 to generate video with arena bounds labeled
c.labelPort = 1; % Toggle 1 to generate video with port labeled

% output video labels
c.outputLabelVidSuffix = '_label_v2.avi';
c.outputCS_shockVidSuffix = '_CS_shock_v1.avi';
c.outputCS_rewVidSuffix = '_CS_rew.avi';

c.baseWin = [-20,0]; % 20 seconds before tone onset 
c.expWin = [0,20]; % response window aligned to tone onset

% VISUALIZER SETTINGS
c.outputVisualizerVidFileSuffix = sprintf('_visualizer_%d.avi',c.labelVidLengthFrames);




%% Generate Data

if c.dataGen >= 1
    disp('Generating data...')
    for folderNum = 1:length(c.folderNameCell)
        run_dataGen(c, c.folderNameCell{folderNum});
    end
    disp('Done generating data for all.')
end


%%
if c.calcGen >= 1
    for folderNum = 1:length(c.folderNameCell)
        run_arenaLabel(c, c.folderNameCell{folderNum});
    end
    disp('Done labeling all arenas.')

    for folderNum = 1:length(c.folderNameCell)
        run_calcGen(c, c.folderNameCell{folderNum});
    end
    disp('Done generating calc for all.')
end

%% Annotating the video file
if c.vidGen >= 1
    for folderNum = 1:length(c.folderNameCell)
        run_vidGen(c, c.folderNameCell{folderNum});
    end
    disp('Done all full-session videos.')
end
%%
if c.vidCS_shocks >= 1
    for folderNum = 1:length(c.folderNameCell)
        folderName   = c.folderNameCell{folderNum};
        ledPath      = fullfile(c.outputDir, folderName, [folderName '_LEDevents.mat']);
        LEDevents    = load(ledPath, 'LEDevents').LEDevents;
        CS_shocks    = LEDevents.evCellLED{3, 1};  % LED3 = shock CS
        run_vidCS_events(c, folderName, CS_shocks, c.outputCS_shockVidSuffix);
    end
    disp('Done all CS_shock videos.')
end
%%
if c.vidCS_rew >= 1
    for folderNum = 1:length(c.folderNameCell)
        folderName = c.folderNameCell{folderNum};
        ledPath    = fullfile(c.outputDir, folderName, [folderName '_LEDevents.mat']);
        LEDevents  = load(ledPath, 'LEDevents').LEDevents;
        CS_rew     = LEDevents.evCellLED{1, 1};    % LED1 = reward CS
        run_vidCS_events(c, folderName, CS_rew, c.outputCS_rewVidSuffix);
    end
    disp('Done all CS_rew videos.')
end

%%
if c.visGen >= 1
    for folderNum = 1:length(c.folderNameCell)
        run_visualizer(c, c.folderNameCell{folderNum});
    end
    disp('Done all visualizations.')
end


disp('Done all.')
end







