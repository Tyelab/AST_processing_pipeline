function track_freeze_dash_vid_generator(varargin)
% track_freeze_dash_vid_generator(varargin)
% 
%
%
%
%
% notes about this function
% 1) pose data is from the 'native' sleap labels with 14 points
%    pose data was stored in \\nadata.snl.salk.edu\snlkt_ast\Miniscope\expAnalysis\20220705_CACO3_backupCam_D1_DISC5\SLEAP_processed_backupCam_D1_Disc5_v1\
% 2) visualizer is NOT working in this verison for shock only events
%    ** have to find out what's going wrong with call to scrolling bars
% 3) this version of LK_fmat_trackDataVidGen_D1_Disc5_v3 was updated to
%    filter freezes in port (when mouse is acutally collecting reward)
%    using the nose-to-port or LED1 on data
%
% this filters freezes in port
% this vis gen is set up to 
%% SETUP

%% SEE NOTES AFTER CONTROL PANEL
%% CONTROL PANEL
if ispc
    addpath('\\nadata.snl.salk.edu\snlkt_ast\AlphaTracker\AlphaTracker code\Utils\distance_point_to_line\') % adds point_to_line_distance.m
elseif isunix
    addpath('/snlkt/ast/AlphaTracker/AlphaTracker code/Utils/distance_point_to_line/') % adds point_to_line_distance.m
end
% 0 = Don't generate, 1 = Generate, 
% todo: implement overwrite value with warning to use
c.dataGen   = 0; % Toggle 1 to generate a data file.
c.calcGen   = 1; % Toggle 1 to generate calculations from file.   Requires data, LED output.  (REQUIRES LED to filter out freezing in port!)
c.vidGen    = 0; % Toggle 1 to generate a video.                  Requires data,calc output.
c.vidCS_shocks = 1; % Toggle 1 to generate a video(CS_shock only) Requires data,calc,LED output.
c.vidCS_rew = 1; % Toggle 1 to generate a video(CS_shock only)    Requires data,calc,LED output.
c.visGen    = 0; % Toggle 1 to generate visualizer video.         Requires data,calc,vid,LED output.

% Data directories
%c.dataDir = '\\nadata.snl.salk.edu\snlkt_ast\Miniscope\expAnalysis\20220504_Sleap_shorttest\'
if ispc
    c.dataDirTop = '\\nadata.snl.salk.edu\snlkt_ast';
elseif isunix
    c.dataDirTop = '/snlkt/ast/';
end
c.dataDir = fullfile(c.dataDirTop, 'Miniscope','expAnalysis','20220902_oldEphysVids','lk_processed_oldEphysVids_v2');

c.inputVidSuffix = '.mp4';
%c.inputJsonSuffix ='_behCamAll-alphapose-results-forvis-tracked';
c.inputH5Suffix ='.predictions.analysis.h5';

% quick generate all files in folder
% d = dir(c.dataDir); {d.name}'

c.folderNameCell = {...
%         '3024ishmael_20180810_Disc4' ;... % port LED = 4
%         '3014illidan_20180926_DiscD4';... % port LED = 4
%         '3026deng_20181128_DiscD2'   ;... % port LED = 4
%         '3029iouxio_20181128_DiscD2' ;... % port LED = 4
%         '3016donkey_20180810_DiscD4' ;... % port LED = 4
%         '6429durian_20191016DISCD5'  ;... % port LED = 2
%         '6197daijobu_20190718DiscD4' ;... % port LED = 2
%         '6253daisy_20190913DISCD3'   ;... % port LED = 2
%         '7008ikari_20190718DiscD4'   ;... % port LED = 2
%         '7049ivy_20190914DISCD4'     ;... % port LED = 2
    'Disc4_NPX4'     ;...
    'Disc4_NPX5'     ;...
    'Disc4_NPX6'     ;... 
    'Disc4_NPX7'     ;... 
    'Disc5_NPX10'     ;... 
    'Disc5_NPX11'     ;...    
    'Disc4_NPX3'     ;...
    'Disc6_NPX8'     ;...
    'Disc6_NPX9'     ;...
    };


% Still to process after completing tracking:
%   NPX3, NPX8, NPX9, ishmael, durian,


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
c.freezeSettings.REMOVE_FREEZES_IN_PORT = 1; % if true, removes any freeze label when the port entry LED 2 is ON
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
% v = VideoReader('\\nadata.snl.salk.edu\snlkt_ast\Miniscope\expAnalysis\20220708_neuropix_Disc4\lk_processed_neuropix_Disc4_v3\Disc4_NPX4\Disc4_NPX4.mp4');
% c.outputVidFrameRate = v.FrameRate; 
c.labelVidLengthFrames = 9000;

c.box.plotLines = 0; % Toggle 1 to plot YOLO-derived box
c.box.colorStyle = 'yellow';

% Color settings
c.pointColors = {[1 0 0];[0 1 0];[0 0 1];[1 1 0];[0 1 1];[1 0 1];[1 1 1];[0 0 0];[1 0 0];[0 1 0];[0 0 1]};
c.pointColors = cellfun(@(x) x*255,c.pointColors,'un',0); % converts to RGB values /255
c.confColorMap = [round(linspace(255, 50, 256))', round(linspace(0, 0, 256))', round(linspace(0, 212, 256))'];
% Point settings
%c.linkPoints = {[1 2];[1 3];[1 4];[4 5];[5 6];[6 7]};  % Anno7
% c.linkPoints = {[1 3];[1 4];[2 3];[4 5];[3 6];[4 6];[6 7];[7 8];[8 9]}; % Anno9
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
%c.inputLabelledVidSuffix = '_label_v2.avi';
c.inputLabelledVidSuffix = '_CS_shock_v1.avi';

%addpath 'U:\Fergil\AlphaTracker\AlphaTracker code\Utils\distance_point_to_line'
%savepath

%% ABOUT
% This function allows analysis of json point movement, and plotting of json output on video.
% Highly likely these will be separate functions in the future.

%% WORKING NOTES
% Color of circles indicates point confidence?
% Point track smoothing
% Pixels changed per frame
% Fix confidence hack - wtf is confidence >1 from alphatracker?
% Point color schemes: A) Multicolor B) 'Color' C) 'Confidence'
%
% Option for uncompressed? R
%
% Leaving out the specific file/folder mode thing right now.
% c.folderMode = 1; % Toggle 1 to use calcium folder structure. Otherwise, will use 'Option 1' file settings below.
% % FILE MANAGEMENT SETTINGS  % OPTION 1: Specify 1 json and 1 video file. Expects these video files in the same dataDir.
% c.dataDir = 'D:\Dropbox\AlphaTracker annotation\Output_test13_(CalciumFC)\20200206_box1_FCD1_6609_octopus_behCamAll\';
% c.jsonFileName = '20200206_box1_FCD1_6609_octopus_behCamAll-alphapose-results-forvis-tracked.json';
% c.vidFileName = '20200206_box1_FCD1_6609_octopus_behCamAll.avi';
%

if c.dataGen >= 1
    %% Generating pose data cube (smoothed and unsmoothed)
    disp('Generating data...')
    
    % Loading the json file
    for folderNum = 1:length(c.folderNameCell)
        
        thisdir= fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} c.saveMouseDataNameSuffix]);
        
        if exist(thisdir,'dir')
            disp([c.saveMouseDataNameSuffix ' already exists in ' c.folderNameCell{folderNum} ', skipped.'])
        else
            disp([c.folderNameCell{folderNum} '...'])
            filePath = fullfile(c.dataDir, c.folderNameCell{folderNum} , [c.folderNameCell{folderNum} c.inputH5Suffix]);
            
            %tmp = 123;
            %cd (fullfile(c.dataDir, c.folderNameCell{folderNum}));
            t.file = fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} c.inputH5Suffix]);
            
%             mouseData.instance_scores = h5read(t.file, '/instance_scores');
            mouseData.instance_scores = h5read(t.file, '/instance_scores');
            mouseData.node_names = h5read(t.file, '/node_names');
            mouseData.point_scores = h5read(t.file, '/point_scores');
            mouseData.track_names = h5read(t.file, '/track_names');
            mouseData.track_occupancy = h5read(t.file, '/track_occupancy');
            mouseData.tracking_scores = h5read(t.file, '/tracking_scores');
            mouseData.tracks = h5read(t.file, '/tracks');
            mouseData.file = t.file;
            
            % smooth track data using Savitzky-Golay FIR smoothing filter
            mouseData_unsmooth = mouseData;  % keep a copy of the unsmoothed data for now
            mouseData.tracks = smoothdata(mouseData.tracks, 1, 'sgolay', 5); % mouseData now contains smoothed track data
            
            disp('H5 loaded...')
            
            oldc = c;
            save(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} c.saveMouseDataNameSuffix]), 'oldc', 'mouseData', 'mouseData_unsmooth','filePath');
            
            clear t mouse
            disp('Done. Data saved.')
            clearvars -except c folderNum
            
            %tmp = 123;
        end
    end
end

% tmp = 123;


%%

if c.calcGen >= 1
    
    % Identify arena features for all folders and save as a structure
    for folderNum = 1:length(c.folderNameCell)
        folderName = c.folderNameCell{folderNum};
        folderPath = fullfile(c.dataDir, folderName) ;
        disp(folderName)
        
        c_old = c; % save the original settings to revert to at the end
        c = check_settings_matfile(c, folderPath, folderName);
        
        %cd(folderPath) ;
        if exist (fullfile(c.dataDir ,c.folderNameCell{folderNum} ,[ c.folderNameCell{folderNum} c.saveArenaNameSuffix]),'file')
            disp([c.saveArenaNameSuffix ' already exists in ' folderName ', skipped'])
        else
            
            inputVideo = VideoReader(fullfile(folderPath,[folderName c.inputVidSuffix])) ; %#ok<TNMLP>
            firstFrameRGB = read(inputVideo, 1) ;
            firstFrame = rgb2gray(firstFrameRGB) ;
            firstFrame = double(firstFrame)/255 ;
            
            imshow(firstFrame);
            set(gcf, 'Position', get(0, 'Screensize'));
            annotation('textbox', [0.4, 0.4, 0.2, 0.2], 'String', 'Label grid floor corners with polygon!' ,'FontSize', 12, 'Interpreter', 'none', 'FitBoxtoText', 'on' );
            
            ArenaBox = drawpolygon();
            Arena.Box.position = ArenaBox.Position;
            
            annotation('textbox', [0.4, 0.3, 0.2, 0.2], 'String', 'Label port spout with a point!' ,'FontSize', 12, 'Interpreter', 'none', 'FitBoxtoText', 'on' );
            
            ArenaPort = drawpoint();
            Arena.Port.position = ArenaPort.Position;
            
            arenaDim(1) = pdist(([Arena.Box.position(1,1), Arena.Box.position(1,2); Arena.Box.position(2,1), Arena.Box.position(2,2)]), 'euclidean');
            arenaDim(2) = pdist(([Arena.Box.position(2,1), Arena.Box.position(2,2); Arena.Box.position(3,1), Arena.Box.position(3,2)]), 'euclidean');
            arenaDim(3) = pdist(([Arena.Box.position(3,1), Arena.Box.position(3,2); Arena.Box.position(4,1), Arena.Box.position(4,2)]), 'euclidean');
            arenaDim(4) = pdist(([Arena.Box.position(4,1), Arena.Box.position(4,2); Arena.Box.position(1,1), Arena.Box.position(1,2)]), 'euclidean');
            
            arenaDim = sort(arenaDim);
            
            pixel_width = mean(arenaDim(1:2));
            
            Arena.conversionFactor = c.arenaWidth / pixel_width;
            
            save_filename = fullfile(c.dataDir, c.folderNameCell{folderNum} ,[c.folderNameCell{folderNum} c.saveArenaNameSuffix]);
            save(save_filename, 'Arena')
            
        end
        
        c = c_old; % save the original settings to revert to at the end
    end
    
    
    
    %% Calculate various measures from the pose data
    for folderNum = 1:length(c.folderNameCell)
        folderName = c.folderNameCell{folderNum};
        folderPath = [c.dataDir folderName] ;
        
        c_old = c; % save the original settings to revert to at the end
        c = check_settings_matfile(c, folderPath, folderName);
        
        %cd(folderPath);
        if exist(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} c.saveCalcNameSuffix]),'file') && c.calcGen == 1
            disp([c.saveCalcNameSuffix, ' already exists in ' folderName ', skipped'])
        else
            %tmp = 123;
            %% Calculating json file analysis
            disp('Calculating...')
            
            load(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} c.saveArenaNameSuffix]), 'Arena')
            load(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} c.saveMouseDataNameSuffix]), 'mouseData','mouseData_unsmooth')
            
            %             calc.unsmoothed = fmat_poseAnalyze(c,mouseData_unsmooth, Arena);
            calc.smoothed = fmat_poseAnalyze(c,mouseData, Arena);
            
            if c.freezeSettings.REMOVE_FREEZES_IN_PORT
                %% NOTE: This section adds a filter to remove labeled freezes in port
                % when the mouse may not be moving much but is actually trying
                % to collect a reward, rather than freezing from fear
                
                %                 if ~isempty(strfind(c.folderNameCell{folderNum},'NPX'))
                %                     c.freezeSettings.LEDPortEntryNumber = 2 ; % looks like LED4 indicates port entry, not LED2
                %                 else
                %                     disp('using LED4 for port entry on older ephys data')
                %                     c.freezeSettings.LEDPortEntryNumber = 4 ; % looks like LED4 indicates port entry, not LED2
                %                 end
                
                
                load(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} '_settings.mat']), 'LEDPortEntryNumber')
                c.freezeSettings.LEDPortEntryNumber = LEDPortEntryNumber;
                % 1) Load LED info and get LED2
                load(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} '_LEDevents.mat']), 'LEDevents')
                LED2_array = zeros(size(calc.smoothed.stickerPoint,1),1);
                LED2_onset  = LEDevents.evCellLED{c.freezeSettings.LEDPortEntryNumber,1};
                LED2_offset = LEDevents.evCellLED{c.freezeSettings.LEDPortEntryNumber,2};
                
                % 2) define function to create sequence of numbers from 2 inputs:
                func = @(x,y) x:y;
                B = arrayfun( func,LED2_onset, LED2_offset, 'UniformOutput', false);
                portEntryTrue = cell2mat(B'); clear func B
                % portEntryTrue should contain the full set of frames when LED2 is ON
                
                % now update LED2_array to show when those times are on:
                LED2_array(portEntryTrue) = 1;
                
                % Remove freezes happening during port entry
                warning('Removing %d labelled freezes because mouse is actually in port',sum(LED2_array==1))
                calc.smoothed.cm.freezing.logiModFG(LED2_array==1) = 0;  % this removes the freeze indicator
            end
            
            %
            %             calc.unsmoothed.distanceFromegdge = fmat_distanceFromedge(c2,data.unsmoothed, Arena)
            %             calc.smoothed.distanceFromedge = fmat_distanceFromedge(c2,data.smoothed, Arena)
            %
            %             calc.unsmoothed.distanceFromport = fmat_distanceFromport(c2, data.unsmoothed, Arena)
            %             calc.smoothed.distanceFromport = fmat_distanceFromport(c2, data.smoothed, Arena)
            
            % figure; plot(calc.smoothed.stickerPoint(1:10000,1),calc.smoothed.stickerPoint(1:10000,2),'g')
            % hold on; plot(calc.unsmoothed.stickerPoint(1:10000,1),calc.unsmoothed.stickerPoint(1:10000,2),'r:')
            oldc = c;
            
            save(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} c.saveCalcNameSuffix]), 'oldc', 'mouseData', 'mouseData_unsmooth','calc');
            
            disp('Done. Data saved.')
        end
        
        c = c_old; % revert to original settings structure
    end
    disp('Done generating calc for all.')
end




%% Annotating the video file

if c.vidGen >= 1
    for folderNum = 1:length(c.folderNameCell)
        
        load(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} c.saveArenaNameSuffix]), 'Arena')
        load(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} c.saveMouseDataNameSuffix]), 'mouseData', 'mouseData_unsmooth')
        load(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} c.saveCalcNameSuffix]), 'calc')
        
        c_old = c; % save the original settings to revert to at the end
        c = check_settings_matfile(c, fullfile(c.dataDir, c.folderNameCell{folderNum}), c.folderNameCell{folderNum});
        
        
        inputVideo = VideoReader(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} c.inputVidSuffix])); %#ok<TNMLP>
        c.outputVidFrameRate = inputVideo.FrameRate;
        %         vidHeight = inputVideo.Height;
        %         vidWidth = inputVideo.Width;
        outputVideo = VideoWriter(fullfile(c.dataDir, c.folderNameCell{folderNum},[ c.folderNameCell{folderNum} c.outputLabelVidSuffix])); %#ok<TNMLP>
        outputVideo.FrameRate = c.outputVidFrameRate;
        open(outputVideo);
        disp([c.folderNameCell{folderNum} ' video being labelled...'])
        
        
        % For each frame of the video, annotate with points or lines
        % Smoothed or unsmoothed data will be plotted based on settings in c
        curFrameNum = 1;
        progBar = 0;
        dataLength = size(mouseData.tracks,1);
        totalFrameNum = size(mouseData.tracks,1); % These are the same for cases where track data and video are unequal - can likely cut one later
        f = waitbar(progBar,['Annotating ' c.folderNameCell{folderNum} c.inputVidSuffix c.outputLabelVidSuffix]);
        
        while(hasFrame(inputVideo) && curFrameNum < c.labelVidLengthFrames)
            if curFrameNum <= dataLength
                curFrame = readFrame(inputVideo);
                if c.labelArenaEdges == 1
                    curFrame = insertShape(curFrame,'line', [Arena.Box.position(1,1),Arena.Box.position(1,2),Arena.Box.position(2,1),Arena.Box.position(2,2)], 'LineWidth', 1,'Color', 'white');
                    curFrame = insertShape(curFrame,'line', [Arena.Box.position(2,1),Arena.Box.position(2,2),Arena.Box.position(3,1),Arena.Box.position(3,2)], 'LineWidth', 1,'Color', 'white');
                    curFrame = insertShape(curFrame,'line', [Arena.Box.position(3,1),Arena.Box.position(3,2),Arena.Box.position(4,1),Arena.Box.position(4,2)], 'LineWidth', 1,'Color', 'white');
                    curFrame = insertShape(curFrame,'line', [Arena.Box.position(4,1),Arena.Box.position(4,2),Arena.Box.position(1,1),Arena.Box.position(1,2)], 'LineWidth', 1,'Color', 'white');
                end
                
                if c.labelPort == 1
                    curFrame = insertShape(curFrame,'FilledCircle', [Arena.Port.position 6], 'LineWidth', 1, 'Color', 'blue', 'opacity', 0.7);
                    
                end
                
                if c.smoothed.plotLines == 1
                    curFrame = fmat_plotLines(c,mouseData,curFrameNum,curFrame,c.smoothed.lineColorStyle);
                end
                
                if c.smoothed.plotPoints == 1
                    curFrame = fmat_plotPoints(c,mouseData,curFrameNum,curFrame,c.smoothed.pointColorStyle);
                end
                
                if c.unsmoothed.plotLines == 1
                    curFrame = fmat_plotLines(c,mouseData_unsmooth,curFrameNum,curFrame,c.unsmoothed.lineColorStyle);
                end
                if c.unsmoothed.plotPoints == 1
                    curFrame = fmat_plotPoints(c,mouseData_unsmooth,curFrameNum,curFrame,c.unsmoothed.pointColorStyle);
                end
                
                if c.labelFrameNum == 1
                    curFrame = insertText(curFrame,[1 1],['Frame ' num2str(curFrameNum)],'BoxColor','black','TextColor','white');
                end
                
                if c.box.plotLines == 1
                    curFrame = insertShape(curFrame,'rectangle', data.box(curFrameNum,:), 'LineWidth', 1,'Color', colorStyle,  'Opacity', 0.3);
                end
                
                if c.sticker.plotFreeze == 1   % Plots the dot when the mouse is freezing
                    % SMOOTHED: filled red circle indicates freezing
                    if ~isnan(calc.smoothed.stickerPoint  (curFrameNum,1))
                        if calc.smoothed.cm.freezing.logiModFG(curFrameNum) == 1
                            curFrame = insertShape(curFrame,'FilledCircle', [calc.smoothed.stickerPoint(curFrameNum,1) calc.smoothed.stickerPoint(curFrameNum,2) 9], 'LineWidth', 1, 'Color', 'red', 'opacity', 0.7);
                        end
                    end
                    
                    %                     % UNsmoothed: open green circle indicates freezing
                    %                     if ~isnan(calc.smoothed.stickerPoint  (curFrameNum,1))
                    %                         if calc.smoothed.cm.freezing.logiModFG(curFrameNum) == 1
                    %                             curFrame = insertShape(curFrame,'Circle', [calc.smoothed.stickerPoint(curFrameNum,1) calc.smoothed.stickerPoint(curFrameNum,2) 9], 'LineWidth', 1, 'Color', 'green');
                    %                         end
                    %                     end
                end
                
                if c.sticker.plotDash == 1   % Plots the dot when the mouse is dashing
                    % SMOOTHED: filled yello circle indicates dashing
                    if ~isnan(calc.smoothed.stickerPoint(curFrameNum,1))
                        if calc.smoothed.cm.dashing.logiModFG(curFrameNum) == 1
                            curFrame = insertShape(curFrame,'FilledCircle', [calc.smoothed.stickerPoint(curFrameNum,1) calc.smoothed.stickerPoint(curFrameNum,2) 9], 'LineWidth', 1, 'Color', 'yellow', 'opacity', 0.7);
                        end
                    end
                    %                     % UNSMOOTHED: open cyan circle indicates dashing
                    %                     if ~isnan(calc.smoothed.stickerPoint(curFrameNum,1))
                    %                         if calc.smoothed.cm.dashing.logiModFG(curFrameNum) == 1
                    %                             curFrame = insertShape(curFrame,'Circle', [calc.smoothed.stickerPoint(curFrameNum,1) calc.smoothed.stickerPoint(curFrameNum,2) 9], 'LineWidth', 1, 'Color', 'cyan');
                    %                         end
                    %                     end
                end
                
                % figure; imshow(curFrame);
                writeVideo(outputVideo,curFrame);
                curFrameNum = curFrameNum + 1;
                progBar = curFrameNum / totalFrameNum;
                waitbar(progBar,f);
                
            else
                disp('Video frame number exceeds data cube!')
                % FM Bugged!
            end
        end
        
        close(outputVideo);
        close(f);
        disp('Closing video...')
        
        c = c_old; % revert to old settings
    end
    disp(['Done ' c.folderNameCell{folderNum} '.'])
    
end%% Annotating the video file

%%
if c.vidCS_shocks >= 1
    for folderNum = 1:length(c.folderNameCell)
        
        load(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} c.saveArenaNameSuffix]), 'Arena')
        load(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} c.saveMouseDataNameSuffix]), 'mouseData', 'mouseData_unsmooth')
        load(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} c.saveCalcNameSuffix]), 'calc')
        load(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} '_LEDevents.mat']), 'LEDevents')
        
        c_old = c; % save the original settings to revert to at the end
        c = check_settings_matfile(c, fullfile(c.dataDir, c.folderNameCell{folderNum}), c.folderNameCell{folderNum});
        
        % open the CS_shock timestamps
        CS_shocks = LEDevents.evCellLED{3,1};% LEDevents.evCellLED{3,2}];
        
        inputVideo = VideoReader(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} c.inputVidSuffix])); %#ok<TNMLP>
        
        outputVideo = VideoWriter(fullfile(c.dataDir, c.folderNameCell{folderNum},[ c.folderNameCell{folderNum} c.outputCS_shockVidSuffix])); %#ok<TNMLP>
        outputVideo.FrameRate = inputVideo.FrameRate;
        disp(['frame rate for videos is : ', num2str(outputVideo.FrameRate)])
        %         outputVideo.FrameRate = c.outputVidFrameRate;
        open(outputVideo);
        disp([c.folderNameCell{folderNum} ' video being labelled for CS_shock periods...'])
        
        
        % For each frame of the video, annotate with points or lines
        % Smoothed or unsmoothed data will be plotted best on settings in c
        
        baseline_window = diff(c.baseWin)*inputVideo.FrameRate; % 20 sec for npx
        exp_window = diff(c.expWin)*inputVideo.FrameRate; % 20 sec for npx
        curCS_shock = 1;
        curFrameNum = CS_shocks(curCS_shock,1)- baseline_window; if curFrameNum<1, curFrameNum=1;end
        progBar = 0;
        dataLength = size(mouseData.tracks,1);
        totalFrameNum = size(mouseData.tracks,1); % These are the same for cases where track data and video are unequal - can likely cut one later
        f = waitbar(progBar,['Annotating ' c.folderNameCell{folderNum} c.inputVidSuffix c.outputLabelVidSuffix]);
        
        while(hasFrame(inputVideo) ) % && curFrameNum < c.labelVidLengthFrames)
            if curFrameNum <= dataLength && any(curFrameNum >= (CS_shocks(:,1)-baseline_window) & curFrameNum <= CS_shocks(:,1)+exp_window)
                %                 if mod(curFrameNum,100)==0
                %                     % display every 100 steps
                %                     disp(curFrameNum),
                %                 end
                inputVideo.CurrentTime = curFrameNum/inputVideo.FrameRate; % update to the right frame in the video
                curFrame = readFrame(inputVideo);
                
                if c.labelArenaEdges == 1
                    curFrame = insertShape(curFrame,'line', [Arena.Box.position(1,1),Arena.Box.position(1,2),Arena.Box.position(2,1),Arena.Box.position(2,2)], 'LineWidth', 1,'Color', 'white');
                    curFrame = insertShape(curFrame,'line', [Arena.Box.position(2,1),Arena.Box.position(2,2),Arena.Box.position(3,1),Arena.Box.position(3,2)], 'LineWidth', 1,'Color', 'white');
                    curFrame = insertShape(curFrame,'line', [Arena.Box.position(3,1),Arena.Box.position(3,2),Arena.Box.position(4,1),Arena.Box.position(4,2)], 'LineWidth', 1,'Color', 'white');
                    curFrame = insertShape(curFrame,'line', [Arena.Box.position(4,1),Arena.Box.position(4,2),Arena.Box.position(1,1),Arena.Box.position(1,2)], 'LineWidth', 1,'Color', 'white');
                end
                
                if c.labelPort == 1
                    curFrame = insertShape(curFrame,'FilledCircle', [Arena.Port.position 6], 'LineWidth', 1, 'Color', 'blue', 'opacity', 0.7);
                    
                end
                
                if c.smoothed.plotLines == 1
                    curFrame = fmat_plotLines(c,mouseData,curFrameNum,curFrame,c.smoothed.lineColorStyle);
                end
                
                if c.smoothed.plotPoints == 1
                    curFrame = fmat_plotPoints(c,mouseData,curFrameNum,curFrame,c.smoothed.pointColorStyle);
                end
                
                if c.unsmoothed.plotLines == 1
                    curFrame = fmat_plotLines(c,mouseData_unsmooth,curFrameNum,curFrame,c.unsmoothed.lineColorStyle);
                end
                if c.unsmoothed.plotPoints == 1
                    curFrame = fmat_plotPoints(c,mouseData_unsmooth,curFrameNum,curFrame,c.unsmoothed.pointColorStyle);
                end
                
                if c.labelFrameNum == 1
                    curFrame = insertText(curFrame,[1 1],['Frame ' num2str(curFrameNum)],'BoxColor','black','TextColor','white');
                end
                
                if c.box.plotLines == 1
                    curFrame = insertShape(curFrame,'rectangle', data.box(curFrameNum,:), 'LineWidth', 1,'Color', colorStyle,  'Opacity', 0.3);
                end
                
                
                if c.sticker.plotFreeze == 1   % Plots the dot when the mouse is freezing
                    % SMOOTHED: filled red circle indicates freezing
                    if ~isnan(calc.smoothed.stickerPoint  (curFrameNum,1))
                        if calc.smoothed.cm.freezing.logiModFG(curFrameNum) == 1
                            curFrame = insertShape(curFrame,'FilledCircle', [calc.smoothed.stickerPoint(curFrameNum,1) calc.smoothed.stickerPoint(curFrameNum,2) 9], 'LineWidth', 1, 'Color', 'red', 'opacity', 0.7);
                        end
                    end
                    
                    %                     % UNsmoothed: open green circle indicates freezing
                    %                     if ~isnan(calc.smoothed.stickerPoint  (curFrameNum,1))
                    %                         if calc.smoothed.cm.freezing.logiModFG(curFrameNum) == 1
                    %                             curFrame = insertShape(curFrame,'Circle', [calc.smoothed.stickerPoint(curFrameNum,1) calc.smoothed.stickerPoint(curFrameNum,2) 9], 'LineWidth', 1, 'Color', 'green');
                    %                         end
                    %                     end
                end
                
                if c.sticker.plotDash == 1   % Plots the dot when the mouse is dashing
                    % SMOOTHED: filled yello circle indicates dashing
                    if ~isnan(calc.smoothed.stickerPoint(curFrameNum,1))
                        if calc.smoothed.cm.dashing.logiModFG(curFrameNum) == 1
                            curFrame = insertShape(curFrame,'FilledCircle', [calc.smoothed.stickerPoint(curFrameNum,1) calc.smoothed.stickerPoint(curFrameNum,2) 9], 'LineWidth', 1, 'Color', 'yellow', 'opacity', 0.7);
                        end
                    end
                    %                     % unSMOOTHED: open cyan circle indicates dashing
                    %                     if ~isnan(calc.smoothed.stickerPoint(curFrameNum,1))
                    %                         if calc.smoothed.cm.dashing.logiModFG(curFrameNum) == 1
                    %                             curFrame = insertShape(curFrame,'Circle', [calc.smoothed.stickerPoint(curFrameNum,1) calc.smoothed.stickerPoint(curFrameNum,2) 9], 'LineWidth', 1, 'Color', 'cyan');
                    %                         end
                    %                     end
                end
                
                
                % figure; imshow(curFrame);
                writeVideo(outputVideo,curFrame);
                curFrameNum = curFrameNum + 1;
                progBar = curFrameNum / totalFrameNum;
                waitbar(progBar,f);
                
            else
                curCS_shock = curCS_shock+ 1;
                if curCS_shock<=size(CS_shocks,1)
                    curFrameNum = CS_shocks(curCS_shock,1) - baseline_window;
                    disp(['Updated to next CS_shock time: ',num2str(curFrameNum)])
                else
                    break
                end
            end
        end
        
        close(outputVideo);
        close(f);
        disp('Closing video...')
        
        % revert to old settings
        c = c_old;
    end
    disp(['Done ' c.folderNameCell{folderNum} '.'])
    
end



%%
if c.vidCS_rew >= 1
    for folderNum = 1:length(c.folderNameCell)
        
        load(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} c.saveArenaNameSuffix]), 'Arena')
        load(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} c.saveMouseDataNameSuffix]), 'mouseData', 'mouseData_unsmooth')
        load(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} c.saveCalcNameSuffix]), 'calc')
        load(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} '_LEDevents.mat']), 'LEDevents')
        
        c_old = c; % save the original settings to revert to at the end
        c = check_settings_matfile(c, fullfile(c.dataDir, c.folderNameCell{folderNum}), c.folderNameCell{folderNum});
        
        % open the CS_shock timestamps
        CS_rew = LEDevents.evCellLED{1,1};% LED1 is reward
        
        inputVideo = VideoReader(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} c.inputVidSuffix])); %#ok<TNMLP>
        
        outputVideo = VideoWriter(fullfile(c.dataDir, c.folderNameCell{folderNum},[ c.folderNameCell{folderNum} c.outputCS_rewVidSuffix])); %#ok<TNMLP>
        outputVideo.FrameRate = inputVideo.FrameRate;
        disp(['frame rate for videos is : ', num2str(outputVideo.FrameRate)])
        %         outputVideo.FrameRate = c.outputVidFrameRate;
        open(outputVideo);
        disp([c.folderNameCell{folderNum} ' video being labelled for CS_shock periods...'])
        
        
        % For each frame of the video, annotate with points or lines
        % Smoothed or unsmoothed data will be plotted best on settings in c
        
        baseline_window = diff(c.baseWin)*inputVideo.FrameRate; % 20 sec for npx
        exp_window = diff(c.expWin)*inputVideo.FrameRate; % 20 sec for npx
        curCS_rew = 1;
        curFrameNum = CS_rew(curCS_rew,1);
        progBar = 0;
        dataLength = size(mouseData.tracks,1);
        totalFrameNum = size(mouseData.tracks,1); % These are the same for cases where track data and video are unequal - can likely cut one later
        f = waitbar(progBar,['Annotating ' c.folderNameCell{folderNum} c.inputVidSuffix c.outputLabelVidSuffix]);
        
        while(hasFrame(inputVideo) ) % && curFrameNum < c.labelVidLengthFrames)
            if curFrameNum <= dataLength && ...
                any(curFrameNum >= CS_rew(:,1) & curFrameNum <= CS_rew(:,1)+exp_window) 
                %                 if mod(curFrameNum,100)==0
                %                     % display every 100 steps
                %                     disp(curFrameNum),
                %                 end
                inputVideo.CurrentTime = curFrameNum/inputVideo.FrameRate; % update to the right frame in the video
                curFrame = readFrame(inputVideo);
                
                if c.labelArenaEdges == 1
                    curFrame = insertShape(curFrame,'line', [Arena.Box.position(1,1),Arena.Box.position(1,2),Arena.Box.position(2,1),Arena.Box.position(2,2)], 'LineWidth', 1,'Color', 'white');
                    curFrame = insertShape(curFrame,'line', [Arena.Box.position(2,1),Arena.Box.position(2,2),Arena.Box.position(3,1),Arena.Box.position(3,2)], 'LineWidth', 1,'Color', 'white');
                    curFrame = insertShape(curFrame,'line', [Arena.Box.position(3,1),Arena.Box.position(3,2),Arena.Box.position(4,1),Arena.Box.position(4,2)], 'LineWidth', 1,'Color', 'white');
                    curFrame = insertShape(curFrame,'line', [Arena.Box.position(4,1),Arena.Box.position(4,2),Arena.Box.position(1,1),Arena.Box.position(1,2)], 'LineWidth', 1,'Color', 'white');
                end
                
                if c.labelPort == 1
                    curFrame = insertShape(curFrame,'FilledCircle', [Arena.Port.position 6], 'LineWidth', 1, 'Color', 'blue', 'opacity', 0.7);
                    
                end
                
                if c.smoothed.plotLines == 1
                    curFrame = fmat_plotLines(c,mouseData,curFrameNum,curFrame,c.smoothed.lineColorStyle);
                end
                
                if c.smoothed.plotPoints == 1
                    curFrame = fmat_plotPoints(c,mouseData,curFrameNum,curFrame,c.smoothed.pointColorStyle);
                end
                
                if c.unsmoothed.plotLines == 1
                    curFrame = fmat_plotLines(c,mouseData_unsmooth,curFrameNum,curFrame,c.unsmoothed.lineColorStyle);
                end
                if c.unsmoothed.plotPoints == 1
                    curFrame = fmat_plotPoints(c,mouseData_unsmooth,curFrameNum,curFrame,c.unsmoothed.pointColorStyle);
                end
                
                if c.labelFrameNum == 1
                    curFrame = insertText(curFrame,[1 1],['Frame ' num2str(curFrameNum)],'BoxColor','black','TextColor','white');
                end
                
                if c.box.plotLines == 1
                    curFrame = insertShape(curFrame,'rectangle', data.box(curFrameNum,:), 'LineWidth', 1,'Color', colorStyle,  'Opacity', 0.3);
                end
                
                
                if c.sticker.plotFreeze == 1   % Plots the dot when the mouse is freezing
                    % SMOOTHED: filled red circle indicates freezing
                    if ~isnan(calc.smoothed.stickerPoint  (curFrameNum,1))
                        if calc.smoothed.cm.freezing.logiModFG(curFrameNum) == 1
                            curFrame = insertShape(curFrame,'FilledCircle', [calc.smoothed.stickerPoint(curFrameNum,1) calc.smoothed.stickerPoint(curFrameNum,2) 9], 'LineWidth', 1, 'Color', 'red', 'opacity', 0.7);
                        end
                    end
                    
                    %                     % UNsmoothed: open green circle indicates freezing
                    %                     if ~isnan(calc.smoothed.stickerPoint  (curFrameNum,1))
                    %                         if calc.smoothed.cm.freezing.logiModFG(curFrameNum) == 1
                    %                             curFrame = insertShape(curFrame,'Circle', [calc.smoothed.stickerPoint(curFrameNum,1) calc.smoothed.stickerPoint(curFrameNum,2) 9], 'LineWidth', 1, 'Color', 'green');
                    %                         end
                    %                     end
                end
                
                if c.sticker.plotDash == 1   % Plots the dot when the mouse is dashing
                    % SMOOTHED: filled yello circle indicates dashing
                    if ~isnan(calc.smoothed.stickerPoint(curFrameNum,1))
                        if calc.smoothed.cm.dashing.logiModFG(curFrameNum) == 1
                            curFrame = insertShape(curFrame,'FilledCircle', [calc.smoothed.stickerPoint(curFrameNum,1) calc.smoothed.stickerPoint(curFrameNum,2) 9], 'LineWidth', 1, 'Color', 'yellow', 'opacity', 0.7);
                        end
                    end
                    %                     % unSMOOTHED: open cyan circle indicates dashing
                    %                     if ~isnan(calc.smoothed.stickerPoint(curFrameNum,1))
                    %                         if calc.smoothed.cm.dashing.logiModFG(curFrameNum) == 1
                    %                             curFrame = insertShape(curFrame,'Circle', [calc.smoothed.stickerPoint(curFrameNum,1) calc.smoothed.stickerPoint(curFrameNum,2) 9], 'LineWidth', 1, 'Color', 'cyan');
                    %                         end
                    %                     end
                end
                
                
                % figure; imshow(curFrame);
                writeVideo(outputVideo,curFrame);
                curFrameNum = curFrameNum + 1;
                progBar = curFrameNum / totalFrameNum;
                waitbar(progBar,f);
                
            else
                curCS_rew = curCS_rew+ 1;
                if curCS_rew<=size(CS_rew,1)
                    curFrameNum = CS_rew(curCS_rew,1);
                    disp(['Updated to next CS_rew time: ',num2str(curFrameNum)])
                else
                    break
                end
            end
        end
        
        close(outputVideo);
        close(f);
        disp('Closing video...')
        
        % revert to old settings
        c = c_old;
    end
    disp(['Done ' c.folderNameCell{folderNum} '.'])
    
end




%% visualizer
if c.visGen >= 1
    
    
    for folderNum = 1:length(c.folderNameCell)
        
        % load the data files
        %         load(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} c.saveArenaNameSuffix]), 'Arena')
        load(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} c.saveMouseDataNameSuffix]), 'mouseData')
        load(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} c.saveCalcNameSuffix]), 'calc')
        load(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} '_LEDevents.mat']), 'LEDevents')
        
        c_old = c; % save the original settings to revert to at the end
        c = check_settings_matfile(c, fullfile(c.dataDir, c.folderNameCell{folderNum}), c.folderNameCell{folderNum});
        
        %TODO: add error checks here
        
        % open the CS_shock timestamps
        CS_shocks = [LEDevents.evCellLED{3,1} LEDevents.evCellLED{3,2}];
        CS_rew = [LEDevents.evCellLED{1,1} LEDevents.evCellLED{1,2}];
        
        % open the labelled video and output file
        inputLabelledVideo = VideoReader(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} c.inputLabelledVidSuffix])); %#ok<*NASGU,TNMLP>
        
        outputVideo = VideoWriter(fullfile(c.dataDir, c.folderNameCell{folderNum},[ c.folderNameCell{folderNum} c.outputVisualizerVidFileSuffix])); %#ok<TNMLP>
        outputVideo.FrameRate = c.outputVidFrameRate;
        open(outputVideo);
        disp([c.folderNameCell{folderNum} ' Visualizer video running ...'])
        
        % NOTE: if your inputLab3elledVideSuffix is "CS_shock_1", then you
        % will want to read the video from frame 1 (time=00:00:00) to end
        % However, you will have to update the scrolling window so that you
        % pull the pt_distance_ave_all from the correct frame from the full
        % set of all frames.  In this case, you should update the scrolling
        % window using the CS_shocks timestamps.  So you need 2 counters to
        % run this correctly.
        % If instead you are using the regularly labeled video
        % ("_label_v1"), then your two counters can be the same and should
        % start from 0.
        
        % set the current time in label video to 0
        curCS_shock = 1;
        curFrameNum = 1;%CS_shocks(curCS_shock,1); % counter for video
        progBar = 0;
        dataLength = size(mouseData.tracks,1);
        totalFrameNum = size(mouseData.tracks,1); % These are the same for cases where track data and video are unequal - can likely cut one later
        f = waitbar(progBar,['Annotating ' c.folderNameCell{folderNum} c.inputVidSuffix c.outputLabelVidSuffix]);
        
        % Select the data to be plotted
        %dataSet = calc.smoothed.cm.freezing.rawData;  %  y-values of black line, should be X frames
        dataSet = calc.smoothed.cm.pointDistAllAvg;
        highlights1 = calc.smoothed.cm.freezing;  %
        highlights2 = calc.smoothed.cm.dashing;
        
        % Set up output video layout
        figure('Position',[1 49, 1920, 955], 'Visible','off')
        ax1 = subplot(3,5,[1:3 6:8]); % For mouse labeled video
        ax2 = subplot(3,5, 11:15); % For full time freeze/dash/dist plot
        ax3 = subplot(3,5,[4:5 9:10]); % for scrolling plot
        
        % Display the first frame in the top subplot
        vidFrame = readFrame(inputLabelledVideo);
        image(vidFrame, 'Parent', ax1);
        ax1.Visible = 'off';
        ax2.NextPlot = 'add';
        ax3.NextPlot = 'add';
        
        % Load the data
        t = 1:totalFrameNum; % Cooked up for this example, use your actual data
        y = dataSet(t);
        %         nDataPoints = length(t); % Number of data points
        index = 1:totalFrameNum;
        i = CS_shocks(curCS_shock,1); %1;  % counter for scrolling windows
        
        % Add highlights 1
        if exist('highlights1','var')
            highlights = highlights1;
            bout.y = 0;
            bout.h = max(calc.smoothed.cm.pointDistAllAvg);
            
            for boutNum=1:length(highlights.timestamps{1, 1})
                bout.x = highlights.timestamps{1, 1}(boutNum);
                bout.w = (highlights.timestamps{1, 2}(boutNum) - highlights.timestamps{1, 1}(boutNum));
                
                r1 = rectangle(ax2,'Position',[bout.x bout.y bout.w bout.h],'FaceColor',[1 .8 .8],'EdgeColor',[1 .8 .8],'LineWidth',0.1);
                hold on
                r1_scroll = rectangle(ax3, 'Position',[bout.x bout.y bout.w bout.h],'FaceColor',[1 .8 .8],'EdgeColor',[1 .8 .8],'LineWidth',0.1);
            end
        end
        
        
        % Add highlights 2
        if exist('highlights2','var')
            highlights = highlights2;
            bout.y = 0;
            bout.h = max(calc.smoothed.cm.pointDistAllAvg);
            
            for boutNum=1:length(highlights.timestamps{1, 1})
                bout.x = highlights.timestamps{1, 1}(boutNum);
                bout.w = (highlights.timestamps{1, 2}(boutNum) - highlights.timestamps{1, 1}(boutNum));
                
                r2 = rectangle(ax2,'Position',[bout.x bout.y bout.w bout.h],'FaceColor',[1 .95 .7],'EdgeColor',[1 .95 .7],'LineWidth',0.1);
                hold on
                r2_scroll = rectangle(ax3,'Position',[bout.x bout.y bout.w bout.h],'FaceColor',[1 .95 .7],'EdgeColor',[1 .95 .7],'LineWidth',0.1);
            end
        end
        
        
        % set the plot for the whole duration axis
        j = plot(ax2,t,y,'Color',[0.5 0.5 0.5]);
        hold on;
        k = plot(ax2,t(1:index(i)),y(1:index(i)),'-k');
        yline(ax2, c.freezeSettings.thresh, 'Color', 'red', 'LineStyle', '--'); %FreezeThresh
        yline(ax2, c.dashSettings.thresh, 'Color', [0.8500 0.3250 0.0980], 'LineStyle', '--'); %DashThresh
        
        % set the plot for the short-duration scroll
        j_scroll = plot(ax3,t,y,'Color',[0.5 0.5 0.5]);
        hold on
        k_scroll = plot(ax3,t(1:index(i)),y(1:index(i)),'-k');
        yline(ax3, c.freezeSettings.thresh, 'Color', 'red', 'LineStyle', '--'); % Freeze thresh
        yline(ax3, c.dashSettings.thresh, 'Color', [0.8500 0.3250 0.0980], 'LineStyle', '--');%DashThresh
        
        % Fix the axes
        ax2.XLim = [t(1) t(end)];
        ax2.YLim = [0 100*c.freezeSettings.thresh_cm];%[0 max(calc.smoothed.cm.pointDistAllAvg)];
        ax3.YLim = [0 10*c.freezeSettings.thresh_cm];%[0 max(calc.smoothed.cm.pointDistAllAvg)];
        
        line_scroll = plot(ax3, [i i], ax3.YLim, 'Color', [0.4660 0.6740 0.1880], 'LineWidth', 1.0);
        ax1.Visible = 'off';
        ax3.Visible = 'on' ;
        
        
        %% Animate
        %         tic
        while (hasFrame(inputLabelledVideo) && curFrameNum < c.labelVidLengthFrames)
            
            %         curCS_shock = 1;
            %         curFrameNum = CS_shocks(curCS_shock,1);
            %         progBar = 0;
            %         dataLength = size(mouseData.tracks,1);
            %         totalFrameNum = size(mouseData.tracks,1); % These are the same for cases where track data and video are unequal - can likely cut one later
            %         f = waitbar(progBar,['Annotating ' c.folderNameCell{folderNum} c.inputVidSuffix c.outputLabelVidSuffix]);
            
            % while(hasFrame(inputLabelledVideo) ) % && curFrameNum < c.labelVidLengthFrames)
            
            line_scroll.Visible = 'off';
            
            % update the video to point to curFrameNum
            %inputLabelledVideo.CurrentTime = curFrameNum/inputLabelledVideo.FrameRate; % update to the right frame in the video
            
            % update scrolling window pointer
            %i = curFrameNum;
            
            % read frame and plot
            curFrame = readFrame(inputLabelledVideo);
            image(curFrame, 'Parent', ax1);
            
            % update the scrolling video
            set(k,'YData',y(1:index(i)), 'XData', t(1:index(i)));
            set(k_scroll,'YData',y(1:index(i)), 'XData', t(1:index(i)));
            % line_scroll = plot(ax3, [i i], [0 10], 'Color', [0.4660 0.6740 0.1880]);
            line_scroll = plot(ax3, [i i], ax3.YLim, 'Color', [0.4660 0.6740 0.1880]);
            line_scroll.Visible = 'on';
            %             Xlimrolling = i - 100 ;
            %             Xlimrollingupper = i + 100 ;
            %             ax3.XLim = [Xlimrolling Xlimrollingupper];
            ax3.XLim = [i-100 i+100];
            %i = i + 1 ;
            
            % save to output video
            F = getframe(gcf);
            writeVideo(outputVideo,F);
            
            % update the progress bar
            curFrameNum = curFrameNum + 1;
            progBar = curFrameNum / totalFrameNum;
            waitbar(progBar,f);
            
            i = i+1;
            if i <= dataLength && any(i >= CS_shocks(:,1) & i <= CS_shocks(:,1)+10*inputLabelledVideo.FrameRate)
                % do nothing
            else
                % move counter to the next shock tone period
                curCS_shock = curCS_shock+ 1;
                
                if curCS_shock<=size(CS_shocks,1)
                    i = CS_shocks(curCS_shock,1);
                    disp(['Updated scrolling counter to next CS_shock time: ',num2str(i)])
                else
                    % this should only happen at the very end of the video
                    break
                end
            end
            
        end
        %toc
        % fprintf(sprintf('Processed %d frames in %f seconds\n',i,toc))
        close(outputVideo);
        disp(['Completed visualization for ',c.folderNameCell{folderNum}])
        
        c = c_old; % save the original settings to revert to at the end
    end % loop over folders
    
    disp('Done all visualizations.')
end % visualizer




disp('Done all.')
end



%% jsonAnalyze
function [calc] = fmat_poseAnalyze(c,data, Arena)
%tmp = 123;

for curFrameNum = 1:size(data.tracks,1)
    for pointNum = 1:size(data.tracks,2)
        
        if curFrameNum == 1
            calc.pixel.pointDistAll(curFrameNum,pointNum) = 0;
        else
            x1 = data.tracks(curFrameNum,pointNum,1);
            y1 = data.tracks(curFrameNum,pointNum,2);
            x2 = data.tracks(curFrameNum-1,pointNum,1);
            y2 = data.tracks(curFrameNum-1,pointNum,2);
            
            % calculate the distance between  xy1 and xy2
            calc.pixel.pointDistAll(curFrameNum,pointNum) = pdist(([x1,y1;x2,y2]),'euclidean');
            
        end
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
    % % %     % letting use know which nodes are used in calculation
    % % %     nodes   = data.node_names(c.freezeSettings.relevantPoints);
    % % %     txt =('Using these points in average distance:');
    % % %     for ii =1:numel(nodes), txt = [txt deblank(nodes{ii}) ', '] ;end
    % % %     warning(txt)
    
    
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

% tmp = 123;


% fmat_threshLogiEvents(rawData,operator,thresh,minFrames,gapTol)

% CALC FREEZING
[calc.cm.freezing] = fmat_threshLogiEvents(calc.cm.pointDistRelevantAvg,c.freezeSettings.operator,c.freezeSettings.thresh_cm,c.freezeSettings.minFrames,c.freezeSettings.gapTol);


% CALC DASHING
[calc.cm.dashing] = fmat_threshLogiEvents(calc.cm.pointDistHaunch,c.dashSettings.operator,c.dashSettings.thresh_cm,c.dashSettings.minFrames,c.dashSettings.gapTol);


% FM: Add window over which velocity is considered?
% tmp = 123;



end


function [curFrame] = fmat_plotLines(c,data,curFrameNum,curFrame,colorStyle)
for linkNum = 1:length(c.linkPoints)
    pointNumA = c.linkPoints{linkNum, 1}(1);
    pointNumB = c.linkPoints{linkNum, 1}(2);
    
    x1 = data.tracks(curFrameNum,pointNumA,1);
    y1 = data.tracks(curFrameNum,pointNumA,2);
    x2 = data.tracks(curFrameNum,pointNumB,1);
    y2 = data.tracks(curFrameNum,pointNumB,2);
    
    if ~isnan(x1) && ~isnan(x2)
        
        % tmp = 123;
        if isequal(colorStyle,'multicolor')
            curFrame = insertShape(curFrame,'line', [x1,y1,x2,y2], 'LineWidth', 1,'Color', c.pointColors{pointNum});
        end
        if isequal(colorStyle,'confidence')
            curFrame = insertShape(curFrame,'line', [x1,y1,x2,y2], 'LineWidth', 1,'Color', c.pointColors{pointNum});
        end
        if ~isequal(colorStyle,'confidence') && ~isequal(colorStyle,'multicolor')
            try
                curFrame = insertShape(curFrame,'line', [x1,y1,x2,y2], 'LineWidth', 1,'Color', colorStyle);
            catch
                % tmp = 123;
            end
            
        end
    end
    % tmp = 123;
end
% tmp = 123;
end

function [curFrame] = fmat_plotPoints(c,data,curFrameNum,curFrame,colorStyle)
for pointNum = 1:size(data.tracks,2)
    pointX = data.tracks(curFrameNum,pointNum,1);
    pointY = data.tracks(curFrameNum,pointNum,2);
    confidence = data.point_scores(curFrameNum,pointNum);
    if ~isnan(pointX)
        
        if confidence > 1
            confidence = 1;
        end
        if confidence == 0
            confidence = 1/256;
        end
        
        
        if isequal(colorStyle,'multicolor')
            curFrame = insertShape(curFrame,'FilledCircle', [pointX pointY 3], 'LineWidth', 1, 'Color', c.pointColors{pointNum},'opacity', 1);
        end
        if isequal(colorStyle,'confidence')
            
            confColorIndex = round(confidence*256);
            if confColorIndex == 0
                confColorIndex = 1;
            end
            try
                confColor = [c.confColorMap(confColorIndex,1) c.confColorMap(confColorIndex,2) c.confColorMap(confColorIndex,3)];
            catch
                tmp = 123;
                confColor = [0 0 0]; % black indicates no confidence information
            end
            
            curFrame = insertShape(curFrame,'FilledCircle', [pointX pointY 3], 'LineWidth', 1, 'Color', confColor, 'opacity', 1);
        end
        
        if ~isequal(colorStyle,'confidence') && ~isequal(colorStyle,'multicolor')
            curFrame = insertShape(curFrame,'FilledCircle', [pointX pointY 3], 'LineWidth', 1, 'Color', colorStyle, 'opacity', 1);
        end
        % tmp = 123;
        
    end
end
% tmp = 123;
end

function [output] = fmat_threshLogiEvents(rawData,operator,thresh,minFrames,gapTol)


% Calculating freezing logical and bout timestamps

if strcmp(operator,"greater")
    logiRaw = (rawData > thresh);
else
    if strcmp(operator,"less")
        logiRaw = (rawData < thresh);
    else
        disp('ERROR: Logical operator not recognized for fmat_threshLogiEvents.')
        % tmp = 123;
    end
end

% tmp = 123;


% Discarding freezing bouts below the minimum number of frames
logiModF(1:length(logiRaw),1) = false; % Make a new logical of zeros
for frameNum = 1:length(logiRaw)
    if frameNum == 6796
        % tmp = 123;
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

% tmp = 123;
end



function c = check_settings_matfile(c, folderPath, folderName)


% look for a settings file in the folder and path
% if it exists, overwrite c with these entries but be careful not to
% obliterate nested fields containing other settings that might not
% be in c_settings
% NOTE: c.first.second is a unique subfield that will be removed if
% your c_settings.first structure does not contain the field
% 'second' !!!

settings_mat_path = fullfile(folderPath, [folderName, '_settings.mat']);
if exist(settings_mat_path,'file')
    
    disp(['Found setting file for ',folderName,' ... updating structure c'])
    load(settings_mat_path,'c_settings');
    
    % get the top level fields in the structure (usually 'freezeSettings')
    c_fields_1 = fieldnames(c_settings);
    for ii = 1:numel(c_fields_1)
        
        if isstruct(c.(c_fields_1{ii}))
            % if the top level field is a structure, find the subfields and
            % only over write those in the saved structure but preserve all
            % the others.
            c_fields_2 = fieldnames(c_settings.(c_fields_1{ii}));
            
            for jj = 1:numel(c_fields_2)
                if isstruct(c.(c_fields_1{ii}).(c_fields_2{jj}))
                    error('%s: structure contains additional subfields -- need to update code to account for this')
                else
                    c.(c_fields_1{ii}).(c_fields_2{jj}) = c_settings.(c_fields_1{ii}).(c_fields_2{jj});
                end
            end
        else
            c.(c_fields_1{ii}) = c_settings.(c_fields_1{ii});
        end
    end
else
    % do nothing to structure c
end


end











% function [dataSmoothed] = smoothJsonPoints(dataUnsmoothed,c) %#ok<DEFNU>
%
% for pointNum = 1:size(dataUnsmoothed,2)
%     for coordType = 1:2
%         dataPoint = dataUnsmoothed(:,pointNum,coordType);
%
%         nanList = find(isnan(dataPoint));
%
%         % Generating segment list (NOTE: Edges cases not accounted for when first or last frame is NaN)
%         if isempty(nanList)
%             segmentList(1,:) = [1 length(dataPoint)];
%         else
%             segmentList(1,:) = [1 nanList(1)-1];
%             for nanNum = 2:length(nanList)
%                 if nanList(nanNum-1) ~= (nanList(nanNum)-1)
%                     newSeg = [(nanList(nanNum-1)+1) (nanList(nanNum)-1)];
%                     segmentList = cat(1,segmentList,newSeg);
%                 end
%             end
%             newSeg = [(nanList(end)+1) length(dataPoint)];
%             segmentList = cat(1,segmentList,newSeg);
%         end
%         segmentListAll{pointNum, coordType} = segmentList; %#ok<AGROW>
%         clear('segmentList');
%         nanListAll{pointNum, coordType} = nanList; %#ok<NASGU,AGROW>
%         clear('nanList');
%     end
% end
%
% % Error-checking for segmentList
% for pointNum = 1:size(dataUnsmoothed,2)
%     for coordType = 1:2
%         for pointNum2 = 1:size(dataUnsmoothed,2)
%             for coordType2 = 1:2
%                 if ~isequal(segmentListAll{pointNum, coordType}, segmentListAll{pointNum2, coordType2})
%                     % tmp = 123;
%                     error('ERROR: Inconsistent Segment list between points or coords.')
%
%                 end
%             end
%         end
%     end
% end
%
% dataSmoothed = dataUnsmoothed;
% for pointNum = 1:size(dataUnsmoothed,2)
%     for coordType = 1:2
%         dataPoint = dataUnsmoothed(:,pointNum,coordType);
%         dataPointNew  = dataPoint;
%         segmentList = segmentListAll{pointNum, coordType};
%         for segNum = 1:size(segmentList,1)
%             dataPointNew(segmentList(segNum,1):segmentList(segNum,2)) = smooth(dataPoint(segmentList(segNum,1):segmentList(segNum,2)));
%         end
%         dataSmoothed(:,pointNum,coordType)=dataPointNew;
%
%         % tmp = 123;
%
%     end
% end
% % Error-checking for post-smoothing nanList
% for pointNum = 1:size(dataUnsmoothed,2)
%     for coordType = 1:2
%         dataPoint = dataUnsmoothed(:,pointNum,coordType);
%         dataPointNew = dataSmoothed(:,pointNum,coordType);
%         nanList = find(isnan(dataPoint));
%         nanList2 = find(isnan(dataPointNew));
%         if ~isequal(nanList, nanList2)
%             % tmp = 123;
%             error('ERROR: Inconsistent NaN list between points or coords after smoothing.')
%
%         end
%     end
%     % tmp = 123;
% end
% % tmp = 123;
%
% end


