
function [] = plotFreezeDashHeatmaps()
% 
% This function plots heatmaps showing the freezing or dashing binary,
% aligned to CS-rew or CS-shock.
% This plots are behavior rastors of freezing (red) or dashing
% (yellow) behavior during trials.
% It uses data generated earlier (track_freeze_dash_vid_generator.m) and
% saved as *_SL_calc.mat, where * is the nametag of the video.
%
%
% Other notes about this function
% 1) Expected pose data is from the 'native' sleap labels with 14 points
%    pose data was stored in:
%    lk_processed_backupCam_Disc5_Disc7_FFBatch_v3_1
% 2) pulls in function 'analyzePortEntries' from Fergil's port entry code
% \\nadata.snl.salk.edu\snlkt_ast\Miniscope\miniscopeCode\portEntry\fmss_MedPCData_portEntry_v3
%   (renamed here as analyzeFreeze and analyzeDash )
% 3) corrected defensive behavior so it's a sum of freeze and dash instead
% of a mean across the two (which pulled down the overall percentage)


%% SETUP
%clear ;%all
close all
addpath('\\nadata.snl.salk.edu\snlkthome\lkeyes\Projects\MATLAB\Util\') % contains saveFigEpsPng function
%% SEE NOTES AFTER CONTROL PANEL
%% CONTROL PANEL
% if ispc
% addpath('\\nadata.snl.salk.edu\snlkt_ast\AlphaTracker\AlphaTracker code\Utils\distance_point_to_line\') % adds point_to_line_distance.m
% elseif isunix
% addpath('/snlkt/ast/AlphaTracker/AlphaTracker code/Utils/distance_point_to_line/') % adds point_to_line_distance.m
% end
% 0 = Don't generate, 1 = Generate
c.calc_plot_Freeze = 1;
c.calc_plot_Dash   = 1;
c.plot_defensive   = 1; % combine freeze and dash together intelligently


%This is the behavioral raster colormap
c.colormap = colormap(...
    [.1 .1 .1;... % black = nothing
    .8 0.1 0.1;...     % red = dash
    1 1 0])  ;          % yellow = freeze
close;
c.PLOT_NAN_COLORS = 0; % whether to add in black in the plots to represent nan values (logical)

% Data directories
if ispc
    c.dataDirTop = '\\nadata.snl.salk.edu\snlkt_ast';
elseif isunix
    c.dataDirTop = '/snlkt/ast/';
end
% update this data directory to point to your data!
c.dataDir = fullfile(c.dataDirTop, 'Miniscope','expAnalysis','20230626_REV_allEphys_sleap','lk_processed_REV_allEphys_v1');
% here is a quick way to generate list of all files in folder (copy into
% c.folderNameCell
%    d = dir(c.dataDir); {d.name}'


% Note: RUN each file separately due to different fps of files -- will create an issue if run all together
c.folderNameCell = {...
    '20221222_CeANPX1_Disc4'     ;...
    '20221222_CeANPX2_Disc4'     ;...
    '20221222_CeANPX4_Disc4'     ;...
    '20221222_CeANPX5_Disc4'     ;...
    '3014illidan_20180926_DiscD4';...
    '3016donkey_20180810_DiscD4' ;...
    '3024ishmael_20180810_Disc4' ;...
    '3026deng_20181128_DiscD2'   ;...
    '3029iouxio_20181128_DiscD2' ;...
    '6197daijobu_20190718DiscD4' ;...
    '6253daisy_20190913DISCD3'   ;...
    '6429durian_20191016DISCD5'  ;...
    '7008ikari_20190718DiscD4'   ;...
    '7049ivy_20190914DISCD4'     ;...
    'Disc4_NPX3';...
    'Disc4_NPX4';...
    'Disc4_NPX5';...
    'Disc4_NPX6';...
    'Disc4_NPX7';...
    'Disc5_NPX10';...
    'Disc5_NPX11';...
    'Disc6_NPX8';...
    'Disc6_NPX9';...
    };

% if ~isempty(varargin)
%     % select specific folders using input values
%     InputFolderIndex = varargin{1};
%     c.folderNameCell = c.folderNameCell(InputFolderIndex);
% end
%

%% this section is whether to align the trials by the tone onset or tone offset
% this should be updated as needed for the specific paradigm
%
% In this example of aliging to tone onset, we want to plot 10 sec of
% baseline, include the 10 sec experimental CS tone, and show 15 sec of
% post-experimental behavior:
% c.baseWin = [-10,0]; % use this one if aligned to start of tone
% c.expWin  = [0,10];  % use this one if aligned to start of tone
% c.dispWin = [-10,25];% use this one if aligned to start of tone

% Here is another example, where we align to tone OFFSET by adjusting these
% window parameters and using end time instead of start time 
c.baseWin = [-40,-20]; % 10 seconds before tone onset to start of tone offset, but aligned to tone offset
c.expWin = [-20,0]; % aligned to tone offset!
c.dispWin = [-45,15]; % moved the disp win to account for aligning to tone offset (20 s base, 15 s post-tone)

% c.offsetFromCS = 0; % this is lefover from older code; leaving in case we need it later
c.ALIGN_HM = 'original_method';   % options are 'align_to_LED' or 'original'
% 'align_to_LED: will use LED on off to align heatmaps to tone offset,
% making sure to align tone offsets and fill in around that
% if '' then will just fill in expected number of frames (10 s tone)


%% another colormap
%c.saveFigFolderName = sprintf('heatmaps_%d_to_%d',c.dispWin(1), c.dispWin(2))
c.vidSuffix = '.mp4';
c.colormap = [...
    0.4 0.4 0.4 % darker grey
    0.6 0.6 0.7... % lighter grey
    ];
% expected filename suffixes (keep consistent with what you named them in
% track_freeze_dash_vid_generator.m
c.saveMouseDataNameSuffix = '_SL_mouseData.mat';
c.saveCalcNameSuffix = '_SL_calc.mat';
c.saveArenaNameSuffix = '_SL_arena.mat' ;
c.arenaWidth = 24.1; %indside width of the test chamber in cm

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
% c.freezeSettings.relevantPoints = 1:14; % Specifies which points to look at when evaluating freezing
% warning('Using 14 nodes to calculate freezing')


%% ABOUT
%
%% WORKING NOTES
%
%
%
%%
if c.calc_plot_Freeze >= 1
    for folderNum = 1:length(c.folderNameCell)
        
        % get the frame rate of video
        vidpath = fullfile(c.dataDir, c.folderNameCell{folderNum} ,  [c.folderNameCell{folderNum} , c.vidSuffix]);
        if exist(vidpath,'file')
            v = VideoReader(vidpath);
            c.fps = v.FrameRate;
            disp([c.folderNameCell{folderNum},': This video frame rate is ',num2str(c.fps)])
            clear v vidpath
        else
            error('could not find video to get frame rate')
        end
        
        load(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} c.saveCalcNameSuffix]), 'calc')
        load(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} '_LEDevents.mat']), 'LEDevents')
        
        % open the CS_shock timestamps (recall only onsets were corrected
        CS_cue_shock_startTimes = LEDevents.evCellLED{3,1}; % shock cue
        CS_cue_shock_endTimes = LEDevents.evCellLED{3,1}+diff(c.expWin)*c.fps; % shock cue
        
        CS_cue_rew_startTimes = LEDevents.evCellLED{1,1}; % reward cue
        CS_cue_rew_endTimes = LEDevents.evCellLED{1,1}+diff(c.expWin)*c.fps; % reward cue
        
        disp(sprintf('%s aligning freeze binary to %d CS Rew and %d Shock Tone...',c.folderNameCell{folderNum} ,numel(CS_cue_rew_startTimes) ,numel(CS_cue_shock_startTimes)))
        
        
        % because reward times turn off at first headpoke, we manually set
        % the reward end times to be 10 s after onset:
        freezes.dataRew   = analyzeBehavior(c, CS_cue_rew_endTimes, calc.smoothed.cm.freezing.logiModFG, CS_cue_rew_startTimes, CS_cue_rew_endTimes);
        freezes.dataShock = analyzeBehavior(c, CS_cue_shock_endTimes, calc.smoothed.cm.freezing.logiModFG,CS_cue_shock_startTimes, CS_cue_shock_endTimes);
        oldc = c;
        save(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} '_freezeData.mat']), 'freezes','oldc', 'CS_cue_shock_startTimes', 'CS_cue_rew_startTimes');
        
        
        %% FIGURE TIME
        fh = figure('Position',[600,65,700,900],'Visible','on');
        
        % REWARD SUBPLOT
        subplot(4,2,1);
        plotPortMatrix(c, freezes.dataRew);title('Freezing during CS-Rew')
        subplot(4,2,2);
        plotPortGraphs( freezes.dataRew);
        title(sprintf('(Cue-BL)/BL=%2.1f',freezes.dataRew.portBaseExpRelPercentChange));
        
        % SHOCK SUBPLOT
        subplot(4,2,3);
        plotPortMatrix(c, freezes.dataShock);title('Freezing during CS-Shock')
        subplot(4,2,4);
        plotPortGraphs( freezes.dataShock)
        title(sprintf('(Cue-BL)/BL=%2.1f',freezes.dataShock.portBaseExpRelPercentChange));
        
        
        %%%%% BAR GRAPHS
        subplot(4,2,[5 7]);
        xrange = freezes.dataRew.portMatrixMEAN;
        % plot trial-average CS-SHOCK
        fm_pn_errorbar(1:size(xrange,2),freezes.dataShock.portMatrixMEAN,freezes.dataShock.portMatrixSEM,[0.8 0.1 0.1]); set(gca, 'XTick', []);
        hold on;
        % plot trial-average CS-REW
        fm_pn_errorbar(1:size(xrange,2),freezes.dataRew.portMatrixMEAN,freezes.dataRew.portMatrixSEM); set(gca, 'XTick', []);
        xlabel('Time');
        ylabel('P(In Port) %');
        set(gca, 'TickDir','out')
        set(gca,'FontName','arial')
        hold on;
        xlim([1 size(freezes.dataRew.portMatrixMEAN,2)]);
        ylim([0 1]);
        
        xTemp = (c.dispWin(1)*-1+c.baseWin(1))*c.fps+1;
        x = [xTemp xTemp]; y = [0 1]; line(x,y,'Color','red','LineStyle','--');
        xTemp = (c.dispWin(1)*-1+c.baseWin(2))*c.fps-1;
        x = [xTemp xTemp]; y = [0 1]; line(x,y,'Color','red','LineStyle','--');
        
        xTemp = (c.dispWin(1)*-1+c.expWin(1))*c.fps;
        x = [xTemp xTemp]; y = [0 1]; line(x,y,'Color','green','LineStyle','--');
        xTemp = (c.dispWin(1)*-1+c.expWin(2))*c.fps;
        x = [xTemp xTemp]; y = [0 1]; line(x,y,'Color','green','LineStyle','--');
        
        hold on;
        
        legend('CS-Shock SEM','CS-Shock mean','CS-Rew SEM','CS-Rew mean')
        title(c.folderNameCell{folderNum},'Interpreter','none')
        figname = fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} '_freezeHM.png']);
        saveFigEpsPng(figname, fh)
        %close all;
        
        disp('Saving CS-aligned heatmaps of freezing...')
    end
    disp(['Done ' c.folderNameCell{folderNum} '.'])
    
end

%close all

%%
if c.calc_plot_Dash >= 1
    for folderNum = 1:length(c.folderNameCell)
        
        % get the frame rate of video
        vidpath = fullfile(c.dataDir, c.folderNameCell{1} ,  [c.folderNameCell{1} , c.vidSuffix]);
        if exist(vidpath,'file')
            v = VideoReader(vidpath);
            c.fps = v.FrameRate;
            clear v vidpath
        else
            error('could not find video to get frame rate')
        end
        
        load(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} c.saveCalcNameSuffix]), 'calc')
        load(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} '_LEDevents.mat']), 'LEDevents')
        
        % open the CS_shock timestamps (recall only onsets were corrected
        CS_cue_shock_startTimes = LEDevents.evCellLED{3,1}; % shock cue
        CS_cue_shock_endTimes = LEDevents.evCellLED{3,1} + diff(c.expWin)*c.fps; % shock cue
        
        CS_cue_rew_startTimes = LEDevents.evCellLED{1,1}; % reward cue
        CS_cue_rew_endTimes = LEDevents.evCellLED{1,1} + diff(c.expWin)*c.fps; % reward cue
        
        disp(sprintf('%s aligning dash binary to %d CS Rew and %d Shock Tone...',c.folderNameCell{folderNum} ,numel(CS_cue_rew_startTimes) ,numel(CS_cue_shock_startTimes)))
        
        
        % because reward times turn off at first headpoke, we manually set
        % the reward end times to be 10 s after onset:
        dashes.dataRew   = analyzeBehavior(c, CS_cue_rew_endTimes,   calc.smoothed.cm.dashing.logiModFG, CS_cue_rew_startTimes, CS_cue_rew_endTimes);
        dashes.dataShock = analyzeBehavior(c, CS_cue_shock_endTimes, calc.smoothed.cm.dashing.logiModFG, CS_cue_shock_startTimes, CS_cue_shock_endTimes);
        oldc = c;
        save(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} '_dashData.mat']), 'dashes','oldc', 'CS_cue_shock_endTimes', 'CS_cue_rew_endTimes');
        
        
        %% FIGURE TIME
        fh = figure('Position',[600,65,700,900],'Visible','on');
        
        % REWARD SUBPLOT
        subplot(4,2,1);
        plotPortMatrix(c, dashes.dataRew); title('Dashing during CS-Rew')
        subplot(4,2,2);
        plotPortGraphs( dashes.dataRew)
        title(sprintf('(Cue-BL)/BL=%2.1f',dashes.dataRew.portBaseExpRelPercentChange));
        
        
        % SHOCK SUBPLOT
        subplot(4,2,3);
        plotPortMatrix(c, dashes.dataShock); title('Dashing during CS-Shock')
        subplot(4,2,4);
        plotPortGraphs( dashes.dataShock)
        title(sprintf('(Cue-BL)/BL=%2.1f',dashes.dataShock.portBaseExpRelPercentChange));
        
        
        %%%%% BAR GRAPHS
        subplot(4,2,[5 7]);
        xrange = dashes.dataRew.portMatrixMEAN;
        % plot trial-average CS-SHOCK
        fm_pn_errorbar(1:size(xrange,2),dashes.dataShock.portMatrixMEAN,dashes.dataShock.portMatrixSEM,[0.8 0.1 0.1]); set(gca, 'XTick', []);
        hold on;
        % plot trial-average CS-REW
        fm_pn_errorbar(1:size(xrange,2),dashes.dataRew.portMatrixMEAN,dashes.dataRew.portMatrixSEM); set(gca, 'XTick', []);
        xlabel('Time');
        ylabel('P(In Port) %');
        set(gca, 'TickDir','out')
        set(gca,'FontName','arial')
        legend('CS-Shock','CS-Rew')
        xlim([1 size(dashes.dataRew.portMatrixMEAN,2)]);
        ylim([0 1]);
        
        xTemp = (c.dispWin(1)*-1+c.baseWin(1))*c.fps+1;
        x = [xTemp xTemp]; y = [0 1]; line(x,y,'Color','red','LineStyle','--');
        xTemp = (c.dispWin(1)*-1+c.baseWin(2))*c.fps-1;
        x = [xTemp xTemp]; y = [0 1]; line(x,y,'Color','red','LineStyle','--');
        
        xTemp = (c.dispWin(1)*-1+c.expWin(1))*c.fps;
        x = [xTemp xTemp]; y = [0 1]; line(x,y,'Color','green','LineStyle','--');
        xTemp = (c.dispWin(1)*-1+c.expWin(2))*c.fps;
        x = [xTemp xTemp]; y = [0 1]; line(x,y,'Color','green','LineStyle','--');
        
        
        legend('CS-Shock SEM','CS-Shock mean','CS-Rew SEM','CS-Rew mean')
        title(c.folderNameCell{folderNum},'Interpreter','none')
        figname = fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} '_dashHM.png']);
        saveFigEpsPng(figname, fh)
        %close all;
        
        disp('Saving CS-aligned heatmaps of dashing...')
    end
    disp(['Done ' c.folderNameCell{folderNum} '.'])
    
end

% close all

%%
if c.plot_defensive >= 1
    
    
    for folderNum = 1:length(c.folderNameCell)
        
        disp([c.folderNameCell{folderNum} ' Creating defensive mode from Freeze/Dash data...'])
        load(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} '_dashData.mat']), 'dashes', 'CS_cue_shock_endTimes', 'CS_cue_rew_endTimes');
        load(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} '_freezeData.mat']), 'freezes');
        
        % get the frame rate of video
        vidpath = fullfile(c.dataDir, c.folderNameCell{1} ,  [c.folderNameCell{1} , c.vidSuffix]);
        if exist(vidpath,'file')
            v = VideoReader(vidpath);
            c.fps = v.FrameRate;
            clear v vidpath
        else
            error('could not find video to get frame rate')
        end
        
        defensive.dataRew.portMatrix = freezes.dataRew.portMatrix + 2* dashes.dataRew.portMatrix;
        defensive.dataShock.portMatrix = freezes.dataShock.portMatrix + 2* dashes.dataShock.portMatrix;
        
        
        % calculations using portMatrix
        defensive.dataRew.portMatrixMEAN = mean(defensive.dataRew.portMatrix,1,'omitnan');
        defensive.dataRew.portMatrixSEM = fm_semCols(defensive.dataRew.portMatrix);
        defensive.dataShock.portMatrixMEAN = mean(defensive.dataShock.portMatrix,1,'omitnan');
        defensive.dataShock.portMatrixSEM = fm_semCols(defensive.dataShock.portMatrix);
        
        % get averages of the summed behaviors
        defensive.dataRew.portMatrixMEAN_sum = freezes.dataRew.portMatrixMEAN + dashes.dataRew.portMatrixMEAN;
        defensive.dataShock.portMatrixMEAN_sum = freezes.dataShock.portMatrixMEAN + dashes.dataShock.portMatrixMEAN;
        
        %
        % I will combine the freeze and dash values for 'portBaseExpDiffPercent'
        % together for a total of 30 values for shock trial (or 90 values rew trial),
        % then take the average to get defensive portBaseExpDiffPercentMEAN.
        
        defensive.dataShock.portBaseExpDiffPercent=[freezes.dataShock.portBaseExpDiffPercent;dashes.dataShock.portBaseExpDiffPercent];
        defensive.dataShock.portBaseExpDiffPercentMEAN  = freezes.dataShock.portBaseExpDiffPercentMEAN + dashes.dataShock.portBaseExpDiffPercentMEAN;
        defensive.dataShock.portBaseExpDiffPercentSEM = fm_semCols(defensive.dataShock.portBaseExpDiffPercentMEAN);
        
        
        bl = defensive.dataShock.portBaseExpDiffPercentMEAN(1);
        cue = defensive.dataShock.portBaseExpDiffPercentMEAN(2);
        defensive.dataShock.portBaseExpRelPercentChange = (cue-bl)/bl;
        defensive.dataShock.portBaseExpRelPercentIncrease = cue/bl;
        
        defensive.dataRew.portBaseExpDiffPercent =  [freezes.dataRew.portBaseExpDiffPercent;dashes.dataRew.portBaseExpDiffPercent];
        defensive.dataRew.portBaseExpDiffPercentMEAN  = freezes.dataRew.portBaseExpDiffPercentMEAN + dashes.dataRew.portBaseExpDiffPercentMEAN;
        defensive.dataRew.portBaseExpDiffPercentSEM = fm_semCols(defensive.dataRew.portBaseExpDiffPercentMEAN);
        
        bl = defensive.dataRew.portBaseExpDiffPercentMEAN(1);
        cue = defensive.dataRew.portBaseExpDiffPercentMEAN(2);
        defensive.dataRew.portBaseExpRelPercentChange = (cue-bl)/bl;
        defensive.dataRew.portBaseExpRelPercentIncrease = cue/bl;
        
        oldc = c;
        save(fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} '_defensiveData.mat']), 'defensive','oldc', 'CS_cue_shock_endTimes', 'CS_cue_rew_endTimes');
        
        
        
        %% FIGURE TIME
        fh = figure('Position',[600,65,870,900],'Visible','on');
        % REWARD SUBPLOT
        subplot(5,6,[1 3]);%         plotPortMatrix(c, defensive.dataRew);
        plotIndividualHeatmap(defensive.dataRew,c)
        title({c.folderNameCell{folderNum},'Defensive Behaviors during CS-Rew'}, 'interpreter','none')
        subplot(5,6,4)
        plotPortGraphs( freezes.dataRew);
        title({'Freezes', 'CS-Rew',sprintf('(Cue-BL)/BL = %2.1f',freezes.dataRew.portBaseExpRelPercentChange)});
        
        subplot(5,6,5)
        plotPortGraphs( dashes.dataRew);
        title({'Freezes', 'CS-Rew',sprintf('(Cue-BL)/BL=%2.1f',dashes.dataRew.portBaseExpRelPercentChange)});
        
        subplot(5,6,6)
        plotPortGraphs( defensive.dataRew);
        title({'Defensive', 'CS-Rew',sprintf('(Cue-BL)/BL=%2.1f',defensive.dataRew.portBaseExpRelPercentChange)});
        
        % SHOCK SUBPLOT
        subplot(5,6,[7 9]);
        plotIndividualHeatmap(defensive.dataShock,c);
        title('Defensive Behaviors during CS-Shock')
        subplot(5,6,10)
        plotPortGraphs( freezes.dataShock);
        title({'Freezes', 'CS-Shock',sprintf('(Cue-BL)/BL = %2.1f',freezes.dataShock.portBaseExpRelPercentChange)});
        subplot(5,6,11)
        plotPortGraphs( dashes.dataShock);
        title({'Dashes', 'CS-Shock',sprintf('(Cue-BL)/BL = %f2.1',dashes.dataShock.portBaseExpRelPercentChange)});
        subplot(5,6,12)
        plotPortGraphs( defensive.dataShock);
        title({'Defensive', 'CS-Shock',sprintf('(Cue-BL)/BL = %2.1f',defensive.dataShock.portBaseExpRelPercentChange)});
        
        
        
        %%%%% average GRAPHS
        subplot(5,6,[13 15] );
        xrange = defensive.dataRew.portMatrixMEAN;
        % plot trial-average CS-SHOCK
        fm_pn_errorbar(1:size(xrange,2),freezes.dataShock.portMatrixMEAN,freezes.dataShock.portMatrixSEM,[0.8 0.1 0.1]); set(gca, 'XTick', []);
        hold on;
        % plot trial-average CS-REW
        fm_pn_errorbar(1:size(xrange,2),freezes.dataRew.portMatrixMEAN,freezes.dataRew.portMatrixSEM); set(gca, 'XTick', []);
        xlabel('Time');
        ylabel('Freeze %');
        set(gca, 'TickDir','out')
        set(gca,'FontName','arial')
        hold on;
        xlim([1 size(freezes.dataRew.portMatrixMEAN,2)]);
        ylim([0 1]);
        title('Trial-averaged Freezing')
        if 1
            % Draw some lines for base and exp windows
            xTemp = (c.dispWin(1)*-1+c.baseWin(1))*c.fps+1;
            x = [xTemp xTemp]; y = [0 1]; line(x,y,'Color','red','LineStyle','--');
            xTemp = (c.dispWin(1)*-1+c.baseWin(2))*c.fps-1;
            x = [xTemp xTemp]; y = [0 1]; line(x,y,'Color','red','LineStyle','--');
            
            xTemp = (c.dispWin(1)*-1+c.expWin(1))*c.fps;
            x = [xTemp xTemp]; y = [0 1]; line(x,y,'Color','green','LineStyle','--');
            xTemp = (c.dispWin(1)*-1+c.expWin(2))*c.fps;
            x = [xTemp xTemp]; y = [0 1]; line(x,y,'Color','green','LineStyle','--');
        end
        leg_text={'Shock SEM','Shock mean','Rew SEM','Rew mean'};
        legend(leg_text,'Location','Best');
        
        subplot(5,6,[19 21] );
        % plot trial-average CS-SHOCK
        fm_pn_errorbar(1:size(xrange,2),dashes.dataShock.portMatrixMEAN,dashes.dataShock.portMatrixSEM,[0.8 0.1 0.1]); set(gca, 'XTick', []);
        hold on;
        % plot trial-average CS-REW
        fm_pn_errorbar(1:size(xrange,2),dashes.dataRew.portMatrixMEAN,dashes.dataRew.portMatrixSEM); set(gca, 'XTick', []);
        xlabel('Time');
        ylabel('Freeze %');
        set(gca, 'TickDir','out')
        set(gca,'FontName','arial')
        hold on;
        xlim([1 size(dashes.dataRew.portMatrixMEAN,2)]);
        ylim([0 1]);
        title('Trial-averaged Dashing')
        if 1
            xTemp = (c.dispWin(1)*-1+c.baseWin(1))*c.fps+1;
            x = [xTemp xTemp]; y = [0 1]; line(x,y,'Color','red','LineStyle','--');
            xTemp = (c.dispWin(1)*-1+c.baseWin(2))*c.fps-1;
            x = [xTemp xTemp]; y = [0 1]; line(x,y,'Color','red','LineStyle','--');
            
            xTemp = (c.dispWin(1)*-1+c.expWin(1))*c.fps;
            x = [xTemp xTemp]; y = [0 1]; line(x,y,'Color','green','LineStyle','--');
            xTemp = (c.dispWin(1)*-1+c.expWin(2))*c.fps;
            x = [xTemp xTemp]; y = [0 1]; line(x,y,'Color','green','LineStyle','--');
            
        end
        leg_text={'Shock error','Shock mean','Reward error','Reward mean'};
        leg = legend(leg_text,'Location','Best');
        
        
        
        
        subplot(5,6,[25 27]);
        % plot trial-average CS-SHOCK
        fm_pn_errorbar(1:size(xrange,2),defensive.dataShock.portMatrixMEAN,defensive.dataShock.portMatrixSEM,[0.8 0.1 0.1]); set(gca, 'XTick', []);
        hold on;
        % plot trial-average CS-REW
        fm_pn_errorbar(1:size(xrange,2),defensive.dataRew.portMatrixMEAN,defensive.dataRew.portMatrixSEM); set(gca, 'XTick', []);
        xlabel('Time');
        ylabel('Defensive %');
        set(gca, 'TickDir','out')
        set(gca,'FontName','arial')
        hold on;
        xlim([1 size(defensive.dataRew.portMatrixMEAN,2)]);
        ylim([0 1]);
        title('Trial-averaged Defensive')
        if 1
            xTemp = (c.dispWin(1)*-1+c.baseWin(1))*c.fps+1;
            x = [xTemp xTemp]; y = [0 1]; line(x,y,'Color','red','LineStyle','--');
            xTemp = (c.dispWin(1)*-1+c.baseWin(2))*c.fps-1;
            x = [xTemp xTemp]; y = [0 1]; line(x,y,'Color','red','LineStyle','--');
            
            xTemp = (c.dispWin(1)*-1+c.expWin(1))*c.fps;
            x = [xTemp xTemp]; y = [0 1]; line(x,y,'Color','green','LineStyle','--');
            xTemp = (c.dispWin(1)*-1+c.expWin(2))*c.fps;
            x = [xTemp xTemp]; y = [0 1]; line(x,y,'Color','green','LineStyle','--');
        end
        leg_text={'Shock error','Shock mean','Reward error','Reward mean'};
        legend(leg_text,'Location','Best');
        
        
        
        figname = fullfile(c.dataDir, c.folderNameCell{folderNum}, [c.folderNameCell{folderNum} '_defensiveHM.png']);
        saveFigEpsPng(figname, fh)
        
        
        
        
        
        
    end
    
    
    
    
end

disp('Done all.')
end

function [output] = analyzeBehavior(c,startTimes, behBinary, LEDon, LEDoff)
% takes in the structure c, the start times of specific trial onsets and a
% binary vector of a given behavrior
%
% inputs
%   c  - structure with settings of adjustable parameters in this function
%   startTimes - trial start times;  usually given as frame number of associated
%       video to convert to units of seconds framerate*startTimes; times are
%       aligned to behBinary
%   behBinary - logical vector; true when behavior occurs
%   LEDevents  - the actual frames where a given LED is on
%
% output
%   output.portMatrix - logical matrix, size time by trial num, where
%     time = baseline window + experiment window + ITI
%

% original:
switch c.ALIGN_HM
    case 'align_to_LED'
        
        % this is supposed to account for having dropped frames in video, e.g.
        % if the LED shuts off before the expected number of frames is
        % reached then this will fill in NAN values
        
        % generate portMatrix from behBinary and startTimesTemp
        for rowNum = 1:length(startTimes)
            try
                %         output.portMatrix(rowNum,:) = behBinary((startTimes(rowNum)*c.fps+c.dispWin(1)*c.fps+c.offsetFromCS*c.fps):(startTimes(rowNum)*c.fps+c.dispWin(2)*c.fps-1)+c.offsetFromCS*c.fps);
                iStart = startTimes(rowNum) + c.dispWin(1)*c.fps;  % note that startTimes for our cue is in terms of video frame number (not seconds)
                iEnd   = startTimes(rowNum) + c.dispWin(2)*c.fps;
                nEpochs = iEnd-iStart;
                % initialize this trial
                temp_behBinary = nan(nEpochs,1);
                
                counterStart = 1;
                % fill in the base behavior
                iStartBase = LEDon(rowNum) + c.baseWin(1)*c.fps;
                iEndBase   = LEDon(rowNum) + c.baseWin(2)*c.fps;
                nBaseEpochs = iEndBase-iStartBase;
                temp_behBinary(counterStart:nBaseEpochs+counterStart) = behBinary(iStartBase:iEndBase);
                
                counterStart = 1 + diff(c.baseWin)*c.fps;
                counterEnd = (diff(c.expWin) + diff(c.baseWin))*c.fps;
                % fill in the exp response behavior
                iStartExp= LEDon(rowNum);
                iEndExp   = LEDoff(rowNum);
                nExpEpochs = iEndExp-iStartExp;
                %        temp_behBinary(counterStart : nExpEpochs+counterStart) = behBinary(iStartExp:iEndExp);
                temp_behBinary(counterEnd- nExpEpochs: counterEnd) = behBinary(iStartExp:iEndExp);
                
                counterStart = 1 + (diff(c.expWin) + diff(c.baseWin))*c.fps;
                
                % fill in the end disp behavior
                iStartAfter= LEDoff(rowNum) + c.expWin(2)*c.fps;
                iEndAfter   = LEDoff(rowNum) + c.dispWin(2)*c.fps;
                nAfterEpochs = iEndAfter-iStartAfter;
                temp_behBinary(counterStart:nAfterEpochs + counterStart) = behBinary(iStartAfter:iEndAfter);
                
                
                output.portMatrix(rowNum,:) = temp_behBinary;
            catch
                disp(['Something went wrong in ', mfilename])
            end
        end
        
        
    otherwise
        
        % this is the original way we computed the portMatrix entries
        % generate portMatrix from behBinary and startTimesTemp
        for rowNum = 1:length(startTimes)
            try
                %         output.portMatrix(rowNum,:) = behBinary((startTimes(rowNum)*c.fps+c.dispWin(1)*c.fps+c.offsetFromCS*c.fps):(startTimes(rowNum)*c.fps+c.dispWin(2)*c.fps-1)+c.offsetFromCS*c.fps);
                iStart = startTimes(rowNum) + c.dispWin(1)*c.fps;  % note that startTimes for our cue is in terms of video frame number (not seconds)
                iEnd   = startTimes(rowNum) + c.dispWin(2)*c.fps;
                
                if iStart<1
                    % iExpectedNum = diff(c.dispWin)*c.fps;
                    temp_start = abs( iStart)+1;
                    iStart=1;
                    nEpochs = diff(c.dispWin)*c.fps +1;
                    % initialize this trial
                    temp_behBinary = nan(1,nEpochs);
                    temp_behBinary(1, temp_start+1:nEpochs) = behBinary(iStart:iEnd);
                    output.portMatrix(rowNum,:) = temp_behBinary;
                else
                    nEpochs = iEnd-iStart;
                    output.portMatrix(rowNum,:) = behBinary(iStart:iEnd);
                end
            catch
                disp(sprintf('Something went wrong in row %d, %s',rowNum, mfilename))
            end
        end
        
end

% calculations using portMatrix
output.portMatrixMEAN = mean(output.portMatrix,1,'omitnan');
output.portMatrixSEM = fm_semCols(output.portMatrix);

for rowNum = 1:length(startTimes)
    
    % compute baseline window percent freezing
    ibaseStart = startTimes(rowNum) + c.baseWin(1)*c.fps; if ibaseStart<1, ibaseStart=1;end
    ibaseEnd   = startTimes(rowNum) + c.baseWin(2)*c.fps;
    baseSnip = behBinary(ibaseStart:ibaseEnd);
    output.portBaseExpDiffPercent(rowNum,1) = sum(baseSnip) / length(baseSnip);
    
    % compute experimental window percent freezing
    iExpStart = startTimes(rowNum) + c.expWin(1)*c.fps; if iExpStart<1, iExpStart=1; end
    iExpEnd   = startTimes(rowNum) + c.expWin(2)*c.fps;
    expSnip = behBinary(iExpStart:iExpEnd);
    output.portBaseExpDiffPercent(rowNum,2) = sum(expSnip) / length(expSnip);
    
    % compute experimental window percent freezing
    iExpStart = LEDon(rowNum);
    iExpEnd   = LEDoff(rowNum);
    expSnip = behBinary(iExpStart:iExpEnd);
    output.portBaseExpDiffPercent_LED(rowNum,1) = sum(baseSnip) / length(baseSnip);
    output.portBaseExpDiffPercent_LED(rowNum,2) = sum(expSnip) / length(expSnip);
    
    % compute difference between BL and Exp
    output.portBaseExpDiffPercent(rowNum,3) = output.portBaseExpDiffPercent(rowNum,2) - output.portBaseExpDiffPercent(rowNum,1);
    output.portBaseExpDiffPercent(rowNum,3) = output.portBaseExpDiffPercent_LED(rowNum,2) - output.portBaseExpDiffPercent_LED(rowNum,1);
    
end

output.portBaseExpDiffPercentMEAN = mean(output.portBaseExpDiffPercent,1, 'omitnan');
output.portBaseExpDiffPercentSEM = fm_semCols(output.portBaseExpDiffPercent);

bl = output.portBaseExpDiffPercentMEAN(1);
cue = output.portBaseExpDiffPercentMEAN(2);
output.portBaseExpRelPercentChange = (cue-bl)/bl;
output.portBaseExpRelPercentIncrease = cue/bl;

output.portPercentBase = output.portBaseExpDiffPercent(:,1);
output.portPercentExp = output.portBaseExpDiffPercent(:,2);
output.portPercentDiff = output.portBaseExpDiffPercent(:,3);

output.successTrials = output.portBaseExpDiffPercent(:,2) ~= 0;
output.successMEAN = sum(output.portBaseExpDiffPercent(:,2) ~= 0) / length(output.portBaseExpDiffPercent(:,2));

% compute percentChange from BL to Exp
output.portBaseExpPercentChange(rowNum,3) = output.portBaseExpDiffPercentMEAN(2)./ output.portBaseExpDiffPercentMEAN(1);

output.portBaseExpPercentChangeMEAN = mean(output.portBaseExpPercentChange,1,'omitnan');
output.portBaseExpPercentChangeSEM = fm_semCols(output.portBaseExpPercentChange);


% regenerate port entry onsets from portMatrix



% analysis of latency to port entry
for rowNum = 1:length(startTimes)
    
    % Determine if the mouse is in port or not at onset of CS
    iStart = floor(startTimes(rowNum) + c.expWin(1)*c.fps);
    output.inPort(rowNum) =  behBinary(iStart);
    if output.inPort(rowNum) == 1
        output.latencyInportZero(rowNum) = 0;
        output.latencyInportNan(rowNum) = NaN;
    end
    
    % If mouse not in port, determine latency
    if output.inPort(rowNum) == 0
        
        i1 = floor(startTimes(rowNum) + c.expWin(1)*c.fps);
        i2 = size(behBinary,1);
        framesUntilPokeTemp = find( behBinary(i1:i2) ,1);
        
        if isempty(framesUntilPokeTemp)
            output.latencyInportZero(rowNum) = NaN;
            output.latencyInportNan(rowNum) = NaN;
        else
            
            latency = framesUntilPokeTemp/c.fps;
            try
                output.latencyInportZero(rowNum) = latency;
                output.latencyInportNan(rowNum) = latency;
            catch
                disp('Whoops!')
            end
        end
        
    end
end

output.latencyInportZeroMEAN = mean(output.latencyInportZero,2,'omitnan');
output.latencyInportZeroSEM = fm_semCols(output.latencyInportZero');

output.latencyInportNanMEAN = mean(output.latencyInportNan,2,'omitnan');
output.latencyInportNanSEM = fm_semCols(output.latencyInportNan');



portBinaryFlip = flip(behBinary);
portLatencyIndexFlip = zeros(length(portBinaryFlip),1);
ii=0;
for frameNum = 1:length(portBinaryFlip)
    if portBinaryFlip(frameNum) == 0
        ii = ii+1;
        portLatencyIndexFlip(frameNum) = ii;
    else
        ii=0;
    end
end


portLatencyIndexFlip(1:(find(portLatencyIndexFlip==0, 1, 'first')-1)) = NaN;
latencyGlobalInportZero = flip(portLatencyIndexFlip);

latencyGlobalInportNan = latencyGlobalInportZero;
latencyGlobalInportNan(latencyGlobalInportZero == 0) = NaN;

output.latencyGlobalInportZeroMEAN = (mean(latencyGlobalInportZero,'omitnan'))/c.fps;
output.latencyGlobalInportZeroSEM = (fm_semCols(latencyGlobalInportZero'))/c.fps;

output.latencyGlobalInportNanMEAN = (mean(latencyGlobalInportNan,'omitnan'))/c.fps;
output.latencyGlobalInportNanSEM = (fm_semCols(latencyGlobalInportNan'))/c.fps;

output.latencyDeltaToneZeroMEAN = output.latencyInportZeroMEAN-output.latencyGlobalInportZeroMEAN;
output.latencyDeltaToneNanMEAN = output.latencyInportNanMEAN-output.latencyGlobalInportNanMEAN;




end




function [sem] = fm_semCols(data)
% Fergil's function to find the standard error of the mean given a vector
% of data

n = sum(~isnan(data),1);
sqrtn = sqrt(n);
stdCols = std(data,0,1,'omitnan');
sem = stdCols./sqrtn;

end



function [hl, he] = fm_pn_errorbar(x, y, er, c, alpha)
% x - x axis values, such as time points
% y - y axis values, this is the mean
% er - size of the error bars
% color for the whole thing, as a triplet
% alpha - transparency (optional, default: 0.4)
if ~exist('alpha', 'var')
    alpha = 0.4;
end
if ~exist('c', 'var')
    c = getappdata(gca,'PlotColorIndex');
    if isempty(c)
        c = 1;
    end
end

if x == 0
    x = 0:1:(length(y)-1);
end

if isrow(x)
    x = x';
end
if isrow(y)
    y = y';
end
if isrow(er)
    er = er';
end

if numel(c) == 1
    ColOrd = get(gca,'ColorOrder');
    clrIdx = mod(c, size(ColOrd, 1));
    clrIdx = clrIdx + double(clrIdx == 0)*size(ColOrd, 1);
    c = ColOrd(clrIdx, :);
end
xPlot = x;
yPlot = y;
x = [x; flipud(x)];
y2 = [y+er; flipud(y-er)];
he = fill(x, y2, c, 'FaceAlpha', alpha, 'LineStyle', 'none');
hold on;
hl = plot(xPlot, yPlot, 'Color', c);
hold off;
return;
end



function [] = plotPortMatrix(c,data)

if c.PLOT_NAN_COLORS
    % add in the nan entries and account for them in colormap
    tmp = data.portMatrix;
    tmp(isnan(tmp)) = 2;
    cmap = [c.colormap; 0 0 0]; % nan should show up as black
    colormap(cmap)
    imagesc(tmp, [0 2]); set(gca, 'XTick', []);
else
    colormap(c.colormap)
    imagesc(data.portMatrix, [0 1]); set(gca, 'XTick', []);
end
xlabel('Time');
ylabel('Trial #');
hold on;
nTrials = size(data.portMatrix,1);
xTemp1 = ((c.dispWin(1)*-1+c.baseWin(1))*c.fps);
xTemp1 = xTemp1+1; % wiggle for visibility
x = [xTemp1 xTemp1]; y = [0 nTrials+0.5]; line(x,y,'Color','red','LineStyle','--');
xTemp2 = ((c.dispWin(1)*-1+c.baseWin(2))*c.fps);
xTemp2 = xTemp2*0.99; % wiggle for visibility
x = [xTemp2 xTemp2]; y = [0 nTrials+0.5]; line(x,y,'Color','red','LineStyle','--');
line([xTemp1 xTemp2],[0.5 0.5],'Color','red','LineWidth',2);

%annotation('rectangle'


nTrials = size(data.portMatrix,1);
xTemp1 = ((c.dispWin(1)*-1+c.expWin(1))*c.fps);
xTemp1 = xTemp1+1; % wiggle for visibility
x = [xTemp1 xTemp1]; y = [0 nTrials+0.5]; line(x,y,'Color','green','LineStyle','--');
xTemp2 = ((c.dispWin(1)*-1+c.expWin(2))*c.fps);
xTemp2 = xTemp2*0.99; % wiggle for visibility
x = [xTemp2 xTemp2]; y = [0 nTrials+0.5]; line(x,y,'Color','green','LineStyle','--');
line([xTemp1 xTemp2],[0.5 0.5],'Color','green','LineWidth',2);


% Adding latency data
for rowNum = 1:nTrials
    y = [rowNum-0.5 rowNum+0.5];
    x = (c.dispWin(1)*-1+c.baseWin(2))*c.fps+data.latencyInportZero(rowNum)*c.fps;
    x = [x x]; %#ok<AGROW>
    if data.latencyInportZero(rowNum) == 0
        line(x,y,'Color','blue','LineWidth',3);
    else
        line(x,y,'Color','cyan','LineWidth',3);
    end
end

y = [0 nTrials+0.5];
x = (c.dispWin(1)*-1+c.baseWin(2))*c.fps+data.latencyInportZeroMEAN*c.fps;
x = [x x];
line(x,y,'Color','blue','LineStyle','--');
y = [0 nTrials+0.5];
x = (c.dispWin(1)*-1+c.baseWin(2))*c.fps+data.latencyInportNanMEAN*c.fps;
x = [x x];
line(x,y,'Color','cyan','LineStyle','--');

end


function [] = plotPortGraphs(data)
% assumptions:
%  1 there are 3 bars to plot, pre-cue, cue and difference between pre-cue
%  and cue

x= 1:3; % 3 bars
bar(x,data.portBaseExpDiffPercentMEAN);
hold on;
er = errorbar(x,data.portBaseExpDiffPercentMEAN,data.portBaseExpDiffPercentSEM,data.portBaseExpDiffPercentSEM);
er.Color = [0 0 0];
er.LineStyle = 'none';
ylabel('Percent');

labels={'Pre'; 'Cue'; 'Diff' };
set(gca,'xticklabel',labels)
set(gca,'TickDir','out')
% ylim([-1 1]);
ylim([-0.11 0.41]);
%text(0,-0.8,['""Success"" trials = ' num2str(data.successMEAN)]);
% title(['"Success" trials = ' num2str(data.)]);


end

function [] = plotPortPercentChangeGraphs(data)
% assumptions:
%  1 there are 3 bars to plot, pre-cue, cue and difference between pre-cue
%  and cue

x= 1:3; % 3 bars
bar(x,data.portBaseExpPercentChangeMEAN);
hold on;
er = errorbar(x,data.portBaseExpPercentChangeMEAN,data.portBaseExpPercentChangeSEM,data.portBaseExpPercentChangeSEM);
er.Color = [0 0 0];
er.LineStyle = 'none';
ylabel('Percent Change');

labels={'Pre'; 'Cue'; 'Diff' };
set(gca,'xticklabel',labels)
set(gca,'TickDir','out')
% ylim([-1 1]);
ylim([-0.11 0.41]);
%text(0,-0.8,['""Success"" trials = ' num2str(data.successMEAN)]);
% title(['"Success" trials = ' num2str(data.)]);



end



function   plotIndividualHeatmap(data,c)

% plot heatmap
imagesc(data.portMatrix, [0 2]); set(gca, 'XTick', []);
xlabel('Time');
ylabel('Trial #');
hold on;

% plot baseline window
nTrials = size(data.portMatrix,1);
xTemp1 = ((c.dispWin(1)*-1+c.baseWin(1))*c.fps);
xTemp1 = xTemp1+1; % wiggle for visibility
x = [xTemp1 xTemp1]; y = [0 nTrials+0.5]; line(x,y,'Color','red','LineStyle','--');
xTemp2 = ((c.dispWin(1)*-1+c.baseWin(2))*c.fps);
xTemp2 = xTemp2*0.99; % wiggle for visibility
x = [xTemp2 xTemp2]; y = [0 nTrials+0.5]; line(x,y,'Color','red','LineStyle','--');
line([xTemp1 xTemp2],[0.5 0.5],'Color','red','LineWidth',2);

% plot experimental window
nTrials = size(data.portMatrix,1);
xTemp1 = ((c.dispWin(1)*-1+c.expWin(1))*c.fps);
xTemp1 = xTemp1+1; % wiggle for visibility
x = [xTemp1 xTemp1]; y = [0 nTrials+0.5]; line(x,y,'Color','green','LineStyle','--');
xTemp2 = ((c.dispWin(1)*-1+c.expWin(2))*c.fps);
xTemp2 = xTemp2*0.99; % wiggle for visibility
x = [xTemp2 xTemp2]; y = [0 nTrials+0.5]; line(x,y,'Color','green','LineStyle','--');
line([xTemp1 xTemp2],[0.5 0.5],'Color','green','LineWidth',2);


colormap([...
    0.1 0.1 0.1;...   % black = nothing
    0.8 0.1 0.1;... % red = dash
    1.0 1.0 0.0])        % yellow = freeze
if 0
    cb = colorbar;
    cb.Ticks = [0 1 2];
    cb.TickLabels = {'other', 'freeze','dash'};
    cb.Visible = 'off';
    
end
end
