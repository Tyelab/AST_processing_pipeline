function [] = msb_detectEventsLED
% msb_detectEventsLED
%
% This function's purpose is to identify when different LED are active in a
% behavioral video.  This is useful if your behavioral video is not time
% synched with your neural data or trial structure.  The LEDs are used to
% indicate different events and are sometimes the only indicators of when
% a tone or stimulus occurred in the behavioral video.
%
% This script was created with the Mill's AST project in mind.
% If your video is already time synchronized to your other experimental
% data, you do not need to do this step.  The purpose of identifying when
% LED turns on or off is so that you know when a given event occurred, e.g.
% stimulus occurred or tone played.  In your experimental paradigm, each
% LED should be associated with a given event.  For example, in AST:
% a.	LED 1 = reward tone
% b.	LED 2 = port entry detected
% c.	LED 3 = shock tone
% d.	LED 4 = miniscope camera is recording neural data
%              (Note, this was tracked b/c not every trial was recorded)
% e.	LED 5 = session is running (video might be started before/ended
%               after the session begins, so this lets you know when the
%               experiment began and ended)
%
%
% Usage
% -----
%
% a. Update the location of your data (c.dataDir)
% b. Update the c.folderNameCell to the correct folders in your data
%    directory
% c. This script will open the first frame of a video and allow you label
%    the LED location by clicking on the image to define a region of
%    interest (ROI). Each region of interest is expected to be a square (4
%    connected points).  After you create the square, hover over the area
%    and your cursor will change from a circle to a double arrow.  Double
%    click on the square to save the ROI and move onto the next LED.
% d. In AST paradigm, LED1 is the light closest to the port, LED 5 is
%    farthest from port.  This orientation helps because sometimes the
%    video camera is upside down, so the port is on the other side of the
%    video. IMPORTANT: LABEL THE LED IN ORDER FROM 1 TO 5
%
% e. After you create the ROIs, the program will attempt to identify when
%    the led is on using a change to the pixel values and output a png
%    showing the number of times each light was on. In clean data, this
%    works quite well.  However, if illumination changes or something
%    (tether/mouse/experimenter’s hands) blocks the LED, you will not get
%    the expected number of trials for each stimulus type.
%    If this happens, you will need to manually check that these times line
%    up with expectations by playing back the video at those times.
%    Code to help do this is here:  check_frames_by_LED.m
%    b. If you got no LED detections or something looks horribly wrong,
%       here is a quick matlab hack to try and detect using just the raw
%       pixel values.  Code is taken from check_frames_by_LED.m
%
%       (Load the LEDevents.mat file in matlab)
%
%       figure; plot(LEDevents.rawLEDs(:,1));hold on;
%       plot(LEDevents.evCellLED{1,1},LEDevents.rawLEDs(LEDevents.evCellLED{1,1},1),'go','MarkerFaceColor','g')
%       plot(LEDevents.evCellLED{1,2},LEDevents.rawLEDs(LEDevents.evCellLED{1,2},1),'ro','MarkerFaceColor','r')
%       plot(LEDevents.evCellLED{2,1},LEDevents.rawLEDs(LEDevents.evCellLED{2,1},1),'ko')
%       legend('LED-1','LED-1 onset (Rew)','LED-1 offset (Rew)', 'LED-2 onset (Port)')
%       title(Disc7folder,'Interpreter','none')
%       xlabel(‘Frame Number’); ylabel(‘brightness’)
%
% In this resulting figure, Blue spikes show change in LED1 illumination
% over time, green dot = detected onset, red = detected offset.  If you
% don’t get the expected red/green placement, you can zoom into the figure
% and use datatips to manually identify onset and offset. While this sucks,
% it generally works.
%
%
% Based on code written by Fergil Mills and adapted by Laurel Keyes
% April 2, 2022
% See also check_frames_by_LED,


%% CONTROL PANEL
% behCam settings  % Specifies the name of the video file in each folder that will be analyzed.

c.nROI = 5; % Specifies the number of ROIs the script will prompt for. Label closest LED to port '1'.
c.threshold = .5 ;% Specified the threshold above which the brightness will indicate the LED is ON.  This can also be set as an array of thresholds, corresponding to each LED (e.g. [0.85 0.85 0.9 0.6  0.85] ;)


% UPDATE THE DIRECTORY PATHS TO POINT TO YOUR DATA
if ispc
    c.dataDirTop = '\\nadata.snl.salk.edu\snlkt_ast';
elseif isunix
    c.dataDirTop = '/snlkt/ast/';
end
c.dataDir = fullfile(c.dataDirTop, 'Miniscope','expAnalysis','20220902_oldEphysVids','lk_processed_oldEphysVids_v1');

c.behVidSuffix = '.mp4';

c.folderNameCell = {...
    '6197daijobu_20190718DiscD4' ;...
    '6253daisy_20190913DISCD3'   ;...
    '6429durian_20191016DISCD5'  ;...
    '7008ikari_20190718DiscD4'   ;...
    '7049ivy_20190914DISCD4'     ;...
    };

% this sets the colors for each of the LEDs in the output figure
Colors = {[0 0.4470 0.7410]
    [0.8500 0.3250 0.0980]
    [0.9290 0.6940 0.1250]
    [0.4940 0.1840 0.5560]
    [0.4660 0.6740 0.1880]
    [0.3010 0.7450 0.9330]
    [0.6350 0.0780 0.1840]	};

%% ABOUT
% This function serves to quantify changes in signal LEDs in a video, and
% extract timestamps of when the LEDs turn on/off.

%% NOTES.
% This just needs to draw LEDs for the lights, but be queued in batch for
% all the files being looked at.
% Add an 'ifexist' for the output of the script, so it will throw a red
% warning saying the file exists and skip it. No overwrites. Can add
% c.overwrite variable later to toggle this?

%% Set up Folder loop
disp('Generate ROIs')
for folderNum = 1:size(c.folderNameCell,1)
    
    if exist( fullfile(c.dataDir, c.folderNameCell{folderNum},[c.folderNameCell{folderNum},  '_LEDROIs.mat']),'file')
        disp([c.folderNameCell{folderNum}, ': LED file exists, skipping'])
        continue;
    end
    
    c.folderName = c.folderNameCell{folderNum};
    c.folderPath = fullfile(c.dataDir, c.folderName);
    
    disp([c.folderName])
    fullpath_to_video = fullfile(c.folderPath, [c.folderNameCell{folderNum},c.behVidSuffix]);
    c.fullpath_to_video{folderNum} = fullpath_to_video;
    
    %     if 0
    %         %% another way to define ROIs
    %         videoLabeler(fullpath_to_video)    % opens video labeler
    %         % find leds
    %         for roiNum =1:5
    %             tmp = gTruth.LabelData{:,roiNum};
    %             locs = cellfun(@(x) ~isempty(x), tmp,'UniformOutput',true);
    %             % if polygon use this:
    %             %                led1_locs = gTruth.LabelData{locs==1, roiNum}{1}{:};
    %             %                ROIs.xy{roiNum} = [led1_locs(:,1) led1_locs(:,2)];
    %             % if rectangle use this:
    %             %             led1_locs = gTruth.LabelData{locs==1, roiNum}{1};
    %             %             x = led1_locs(1);
    %             %             y = led1_locs(2);
    %             %             w = led1_locs(3);
    %             %             h = led1_locs(4);
    %             %             ROIs.xy{roiNum} = [x y;...
    %             %                 x+w y;...
    %             %                 x y+h;...
    %             %                 x+w y+h  ];
    %             %
    %         end
    %
    %         inputVideo = VideoReader(fullpath_to_video);
    %         frame_rate = inputVideo.FrameRate;
    %         inputVideo.CurrentTime = 0; % should be first frame
    %
    %         firstFrameRGB = readFrame(inputVideo);
    %         firstFrame = rgb2gray(firstFrameRGB);
    %         firstFrame = double(firstFrame)/255; % This needed to be in 0-1 format for roipoly to work -FM
    %
    %         fullpathmat = fullfile( c.dataDir, c.folderName, [char(c.folderNameCell{folderNum}) '_LEDROIs.mat']);
    %         c.fullpath_to_LEDROIsmat{folderNum} = fullpathmat
    %         % plot a figure showing
    %         fh = figure; imagesc(firstFrame),colormap(gray); hold on;
    %         % if polygon use this:
    %         for ii = 1:5
    %             plot(ROIs.xy{ii}(:,1),ROIs.xy{ii}(:,2),'r')
    %         end
    %
    %         %if rectangle use this:
    %         for ii = 1:5
    %             plot(ROIs.xy{ii}(:,1),ROIs.xy{ii}(:,2),'r.')
    %         end
    %
    %         print(fh,[char(c.folderNameCell{folderNum}) '_LEDROIs.png'])
    %     end
    
    inputVideo = VideoReader(fullpath_to_video); %#ok<TNMLP>
    %frame_rate = inputVideo.FrameRate;
    inputVideo.CurrentTime = 0; % should be first frame
    
    firstFrameRGB = readFrame(inputVideo);
    firstFrame = rgb2gray(firstFrameRGB);
    firstFrame = double(firstFrame)/255; % This needed to be in 0-1 format for roipoly to work -FM
    
    fullpathmat = fullfile( c.dataDir, c.folderName, [char(c.folderNameCell{folderNum}) '_LEDROIs.mat']);
    c.fullpath_to_LEDROIsmat{folderNum} = fullpathmat;
    
    if exist (fullpathmat,'file')
        disp([fullpathmat ' already exists, using these.'])
        load(fullpathmat,'ROIs')
    else
        % Generating rois with roi poly. Best to maximize figure, can also draw large rois and adjust down.
        % Double click to center of roi to finalize.
        ROIs.BW=cell(c.nROI,1);
        xi=cell(c.nROI,1);
        yi=cell(c.nROI,1);
        BWt=zeros(size(firstFrame,1),size(firstFrame,2));
        ROIs.xy = cell(c.nROI, 1);
        for roiNum=1:c.nROI
            %             figure(1);clf;
            %             imagesc(firstFrame);colormap(gray)
            %             set(gcf, 'Position',get(0,'ScreenSize'))
            %             [ROIs.BW{roiNum},xi{roiNum},yi{roiNum}]=roipoly();
            if roiNum==1
                [ROIs.BW{roiNum},xi{roiNum},yi{roiNum}]=roipoly(firstFrame);
            else
                [ROIs.BW{roiNum},xi{roiNum},yi{roiNum}]=roipoly(firstFrame);
            end
            BWt=BWt+ROIs.BW{roiNum};
            
            xcoordinates = xi{roiNum, 1};
            ycoordinates = yi{roiNum, 1};
            position = [xcoordinates ycoordinates];
            ROIs.xy{roiNum} = position ;
            firstFrame=firstFrame+BWt;
            
        end
        
        ROIs.All = BWt;
    end
    save(fullfile(c.dataDir, c.folderName, [char(c.folderNameCell{folderNum}) '_LEDROIs.mat']),'ROIs','c');
    disp([c.folderName])
    
end
% end
disp('Generating LED traces and events...')






%% Loop through folders and batch process the LED detections using the ROIs just defined
for folderNum = 1:size(c.folderNameCell,1)
    tic % Begin timer for processing the entire folder.
    disp([c.folderNameCell{folderNum} '...'])
    
    c.folderName = c.folderNameCell{folderNum};
    c.folderPath = fullfile(c.dataDir, c.folderName);
    disp([c.folderName])
    
    fullpath_to_video = fullfile(c.folderPath, [c.folderName, c.behVidSuffix]);
    inputVideo = VideoReader(fullpath_to_video); %#ok<TNMLP>
    
    fullpath_to_eventsmat = fullfile(c.dataDir, c.folderName,[char(c.folderNameCell{folderNum}) '_LEDevents.mat']);
    if exist(fullpath_to_eventsmat,'file')==2
        disp([char(c.folderNameCell{folderNum}) '_LEDevents.mat' ' already exists, using these.'])
        load(fullpath_to_eventsmat)
        normLED = LEDevents.normLEDs;
        rawLED = LEDevents.rawLEDs;
        totalFrameNum = length(rawLED);
        
        load(fullfile(c.dataDir, c.folderName,[char(c.folderNameCell{folderNum}) '_LEDROIs.mat']),'ROIs')
    else
        tic % this tracks how long this step takes
        % extracting raw LED pixel brightness data
        load(fullfile(c.dataDir, c.folderName,[char(c.folderNameCell{folderNum}) '_LEDROIs.mat']),'ROIs')
        totalFrameNum = 1;
        
        while hasFrame(inputVideo)
            curFrame = rgb2gray(readFrame(inputVideo));
            for roiNum = 1:size(ROIs.BW,1)
                roiInt = curFrame(ROIs.BW{roiNum});
                rawLED(totalFrameNum,roiNum) = sum(roiInt);
            end
            totalFrameNum = totalFrameNum + 1;
            
            if mod(totalFrameNum,5000)==0, disp([c.folderName,': ', num2str(totalFrameNum)]),toc, end
        end
        
        LEDevents.rawLEDs = rawLED;
        % generating normalized LED data from raw LED data
        for roiNum = 1:size(rawLED,2)
            normLED(:,roiNum) = rawLED(:,roiNum) - min(rawLED(:,roiNum));
            normLED(:,roiNum) = normLED(:,roiNum) ./ max(normLED(:,roiNum));
            
        end
        toc % prints how long this step took
        
    end
    
    threshLED = normLED > c.threshold; % apply the threshold
    diffLED = diff(threshLED); % compute the differnce in thresholded values
    
    % quick plot to check
    % the cell array corresponds to what the LEDs indicate.  In this case,
    % LED 1 was reward, 2 was port entry, etc.
    % UPDATE THESE VALUES TO REFLECT YOUR LED STRUCTURE
    led_title = {'CS-Reward','Port Entry','CS-Shock','TTL','Session Active'};
    
    if 0
        % alternative to find peak tiems
        diffPeakThresh = 0.3; %#ok<UNRCH>
        for roiNum = 1:size(ROIs.BW,1)
            ROIs.LED_onset{roiNum} = find(diff(normLED(:,roiNum)) > diffPeakThresh);
            ROIs.LED_offset{roiNum} = find(diff(normLED(:,roiNum)) < -1*diffPeakThresh);
            
        end
        figure('Visible','off');
        for ii = 1:numel(led_title)
            subplot(5,1,ii); plot(normLED(:,ii));
            title(sprintf('%s (%d)',led_title{ii}, numel(ROIs.LED_onset{ii})));
        end
    end
    
    figure('Visible','on');
    for ii = 1:numel(led_title)
        %subplot(5,1,ii); plot(diff(normLED(:,ii)));
        subplot(5,1,ii); plot(normLED(:,ii));
        title([led_title{ii}]);
    end
    
    
    % extracting the on and off times of each LED from the diffLED data
    timestampsLED = cell{numel(ROIs), 2};
    for roiNum=1:size(ROIs.BW,1)
        [peakValues, peakIndexes] = findpeaks(diffLED(:,roiNum)); %#ok<ASGLU>
        timestampsLED{roiNum,1} = peakIndexes ;
        invLED = diffLED*-1;
        [valValues, valIndexes] = findpeaks(invLED(:,roiNum)); %#ok<ASGLU>
        timestampsLED{roiNum,2} = valIndexes ;
        if size(timestampsLED{roiNum, 1}, 1) == size(timestampsLED{roiNum,2},1)
            continue
        else
            if size(timestampsLED{roiNum, 1}, 1) < size(timestampsLED{roiNum,2},1)
                peakIndexes2 = [1 ;peakIndexes];
                timestampsLED{roiNum, 1} = peakIndexes2;
            end
            if  size(timestampsLED{roiNum, 1}, 1) > size(timestampsLED{roiNum,2},1)
                valIndexes2 = [valIndexes; totalFrameNum] ;
                timestampsLED{roiNum, 2} = valIndexes2;
                
            end
        end
    end
    
    diff_thresh = 50;
    for roiNum=1:size(ROIs.BW,1)
        time_diff = timestampsLED{roiNum,2}-timestampsLED{roiNum,1};
        timestampsLED{roiNum,1}(time_diff<diff_thresh) = 0;
        timestampsLED{roiNum,2}(time_diff<diff_thresh) = 0;
        if 1
            tmp = timestampsLED{roiNum,1}(find(timestampsLED{roiNum,1} ~= 0))
            timestampsLED{roiNum,1}=tmp
            
            tmp = timestampsLED{roiNum,2}(find(timestampsLED{roiNum,2} ~= 0))
            timestampsLED{roiNum,2}=tmp
        end
        
    end
    
    
    LEDevents.normLEDs = normLED;
    LEDevents.threshLEDs = threshLED;
    LEDevents.evCellLED = timestampsLED;
    % FIGURE GENERATION
    inputVideo = VideoReader(fullpath_to_video);  %[c.dataDir,c.folderNameCell{folderNum} '\' behCamVidList.name]);
    firstFrameRGB = read(inputVideo,1);
    firstFrameROIs = rgb2gray(firstFrameRGB);
    firstFrameROIs = double(firstFrameROIs)/255; % This needed to be in 0-1 format for roipoly to work -FM;
    % loop to draw the ROIs in color onto the first frame
    figure;
    set(gcf, 'Position', [10 10 639 479]);
    imshow(firstFrameROIs, 'Border', 'Tight')
    for roiNum = 1:size(ROIs.BW)
        position = ROIs.xy{roiNum} ;
        drawpolyline('Position', position,'InteractionsAllowed', 'none', 'color', Colors{roiNum,1}) ;
    end
    
    % convert figure to image text can be placed over
    F = getframe(gcf) ;
    RGBrois = frame2im(F) ;
    %imshow(RGBrois) ;
    
    %inserts text onto image labeling each ROI
    for roiNum = 1:size(ROIs.BW)
        yposition = mean(ROIs.xy{roiNum, 1}(:, 2)) ;
        xposition = mean(ROIs.xy{roiNum, 1}(:, 1)) + 25 ;
        textstring = ['LED ' num2str(roiNum)];
        position = [xposition yposition];
        textColor = Colors{roiNum,1} ;
        RGBrois = insertText(RGBrois, position, textstring, 'AnchorPoint', 'LeftCenter', 'BoxOpacity', 1, 'BoxColor', 'white','TextColor', textColor) ;
    end
    
    % opening figure window for all the plots and specifying where the window
    % will open and how big it will be
    figure;
    set(gcf, 'Position', [10 10 1750 1000])
    
    %plotting Raw LED trace
    subplot(6, 1, 4)
    plot(rawLED)
    title('Raw LED')
    xlim([0 totalFrameNum]);
    
    %plotting normalized LED trace
    subplot(6, 1, 5)
    plot(normLED)
    title('Normalized LED')
    y = c.threshold(1) ;
    line([0, totalFrameNum],[y,y],'LineStyle','--' )
    xlim([0 totalFrameNum])
    
    %creating plot for the LED events
    subplot(6, 1, 6)
    for roiNum = 1:size(ROIs.BW,1)
        
        lineColor = Colors{roiNum,1};
        yvalue = roiNum * (1 / (c.nROI + 1));
        
        for lineNum = 1:size(timestampsLED{roiNum,1},1)
            
            plot([timestampsLED{roiNum,1}(lineNum) timestampsLED{roiNum,2}(lineNum)], [yvalue yvalue], 'color', lineColor,'LineWidth', 3)
            ylim([0 1])
            xlim([0 totalFrameNum])
            hold on
        end
        hold on
    end
    title('LED ON/OFF Events');
    
    % adds the labeled image of the box to the figure
    subplot(6, 1, [1 3]) ;
    imshow(RGBrois);
    
    % adds a legend to the figure with color key for each ROI
    position = [0.75, 0.5, 0.1, 0.1];
    
    for roiNum = 1:size(ROIs.BW,1)
        textColor = Colors{roiNum,1};
        textstring = ['-- LED ' num2str(roiNum), ' Number of events: ' num2str(size(timestampsLED{roiNum, 1},1))];
        annotation('textbox', position, 'String', textstring, 'LineStyle', 'none','FontSize', 16, 'Color', textColor );
        position = position + [0, 0.05, 0, 0];
        hold on
    end
    
    % adds labels to figure with the file name and date of analysis
    position = [0.1, 0.8, 0.1, 0.1];
    txtstring = cell (1,1) ;
    txtstring{1,1} = c.folderNameCell{folderNum} ;
    txtstring{2,1} = ['LED script run on: ' char(datetime('now'))] ;
    annotation('textbox', position, 'String', txtstring ,'FontSize', 17, 'Interpreter', 'none', 'FitBoxtoText', 'on' );
    
    %saving the figure as a .png in the same folder
    saveas(gcf, fullfile(c.dataDir, c.folderNameCell{folderNum},[char(c.folderNameCell{folderNum}) '_LEDfigure.png']) , 'png')
    
    %saving timestamps of LED events in same folder
    save( fullfile(c.dataDir, c.folderNameCell{folderNum}, [char(c.folderNameCell{folderNum}) '_LEDevents.mat']), 'LEDevents')
    clear normLED threshLED rawLED LEDevents
    % No clear invLED.... actually seems ok?
    
    close all
    
end




