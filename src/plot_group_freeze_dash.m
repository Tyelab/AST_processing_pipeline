function [] = plot_group_freeze_dash
%
% notes about this function
% 1) pose data is from the 'native' sleap labels with 14 points
%    pose data was stored in:
%    lk_processed_backupCam_Disc5_Disc7_FFBatch_v3_1
% 2) load the calcuated freeze and dash data saved to disk and run with
%    LK_plotFreezeDashHeatmaps_v01.m
% 3) this function analyzes group trends within PAIRED and UNPAIR groups
% 4) also looks at comparison of reward vs shock during cue period
% 5) for computing stats on bar plots:
% --- Use a paired test if the study paired subjects in some way, or if the study compares two measurements on each subject.
% ----Use a two-sample test if the data were produced from two independent groups.
% close all
addpath('\\nadata.snl.salk.edu\snlkthome\lkeyes\Projects\MATLAB\Util\')

close all

%% CONTROL PANEL
%SAVMAT = 1;
SAVFIG = 1;
c.PlotFreeze = 0;
c.PlotDash   = 0;
c.PlotDefensive = 0;

% Data directories
if ispc
    c.dataDirTop = '\\nadata.snl.salk.edu\snlkt_ast';
elseif isunix
    c.dataDirTop = '/snlkt/ast/';
end
c.dataDir = fullfile(c.dataDirTop, 'Miniscope','expAnalysis','20220902_oldEphysVids','lk_processed_oldEphysVids_v2');

% quick generate all files in folder
%    d = dir(c.dataDir); {d.name}'

% subjects with tone and stimulus paired:
c.folderNameCell_PR = {...
    'Disc4_NPX3';...
    'Disc4_NPX4';...
    'Disc4_NPX5';...
    'Disc6_NPX8';...
    'Disc6_NPX9';...
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
    };

% unpaired subjects (tone/stim not paired)
c.folderNameCell_UNP = {...
    'Disc4_NPX6';...
    'Disc4_NPX7';...
    'Disc5_NPX10';...
    'Disc5_NPX11';...
    };

% we align to tone offset by adjusting these window parameters and using
% end time instead of start time
c.baseWin = [-40,-20]; % 20 seconds before tone onset to start of tone offset, but aligned to tone offset
c.expWin = [-20,0]; % aligned to tone offset!  20 s tone duration for ephys subjects
c.dispWin = [-40,20]; % moved the disp win to account for aligning to tone offset (5 iti, 20 s base, 20 s tone, 15 s post-tone)
c.offsetFromCS = 0; % this is lefover from older code; leaving in case we need it later
c.fps = 30; % frames per second
c.colormap = [0.4 0.4 0.4
    .6 .6 .7];
c.nTrials = 90;  % need this to keep the matricies same number of trials

%% ABOUT
% This function plots grouped infomation showing the freezing or dashing binary,
% aligned to CS-rew or CS-shock in Disc5 CACO2 data
%
%% WORKING NOTES
%
%
%
%%

if c.PlotFreeze == 1
    % load paired datasets
    for folderNum = 1:length(c.folderNameCell_PR)
        load(fullfile(c.dataDir, c.folderNameCell_PR{folderNum}, [c.folderNameCell_PR{folderNum} '_freezeData.mat']),'freezes');
        disp(folderNum)
        
        % check the number of trials and pad with nan if needed
        [numtrials, nt] = size(freezes.dataRew.portMatrix);
        if numtrials ~= c.nTrials
            missing_trials = abs(c.nTrials-numtrials);
            pm = [nan(missing_trials, nt); freezes.dataRew.portMatrix];
            freezes.dataRew.portMatrix=pm;
        end
        metaPR(folderNum).freeze=freezes; %#ok<*AGROW>
        
        % check the video frame rate
        v = VideoReader(fullfile(c.dataDir, c.folderNameCell_PR{folderNum}, [c.folderNameCell_PR{folderNum} '.mp4']));
        fps = v.FrameRate;
        if fps==15
            disp('Upsampling relevant variables from 15 fps to 30')
            
            % Method 1
            tmp = metaPR(folderNum).freeze.dataRew.portMatrix;
            newPM = zeros(size(tmp,1),2*size(tmp,2)-1);
            for ii =1:size(tmp,1)
                tmp2 = [tmp(ii,:);tmp(ii,:)];
                tmp2= tmp2(:);
                newPM(ii,:) = tmp2(1:end-1);
            end
            metaPR(folderNum).freeze.dataRew.portMatrix = newPM;
            clear tmp tmp2 newPM
            
            tmp = metaPR(folderNum).freeze.dataShock.portMatrix;
            newPM = zeros(size(tmp,1),2*size(tmp,2)-1);
            for ii =1:size(tmp,1)
                tmp2 = [tmp(ii,:);tmp(ii,:)];
                tmp2= tmp2(:);
                newPM(ii,:) = tmp2(1:end-1);
            end
            metaPR(folderNum).freeze.dataShock.portMatrix = newPM;
            clear tmp tmp2 newPM
        end
        % collect the individual heatmaps for cs-rew and cs-shock for paired animals
        P_CS_rew_portMatrix(:,:,folderNum) = metaPR(folderNum).freeze.dataRew.portMatrix;
        P_CS_shk_portMatrix(:,:,folderNum) = metaPR(folderNum).freeze.dataShock.portMatrix;
        
        % collect the difference scores between cue and baseline windows for cs-rew and cs-shock for paired animals
        P_CS_rew.portBaseExpDiffPercent(folderNum) = metaPR(folderNum).freeze.dataRew.portBaseExpDiffPercentMEAN(3); % only need the last entry, which is diff = cue - base
        P_CS_shk.portBaseExpDiffPercent(folderNum) = metaPR(folderNum).freeze.dataShock.portBaseExpDiffPercentMEAN(3); % only need the last entry, which is diff = cue - base
        
        % collect the difference scores between cue and baseline windows for cs-rew and cs-shock for paired animals
        P_CS_rew.portBaseExpDiffPercent_all(folderNum,:) = metaPR(folderNum).freeze.dataRew.portBaseExpDiffPercentMEAN; % only need the last entry, which is diff = cue - base
        P_CS_shk.portBaseExpDiffPercent_all(folderNum,:) = metaPR(folderNum).freeze.dataShock.portBaseExpDiffPercentMEAN; % only need the last entry, which is diff = cue - base
        
        P_CS_rew.ID(folderNum) = c.folderNameCell_PR(folderNum);
        P_CS_shk.ID(folderNum) = c.folderNameCell_PR(folderNum);
    end
    
    % load unpaired datasets
    for folderNum = 1:length(c.folderNameCell_UNP)
        load(fullfile(c.dataDir, c.folderNameCell_UNP{folderNum}, [c.folderNameCell_UNP{folderNum} '_freezeData.mat']),'freezes');
        % check the number of trials and pad with nan if needed
        [numtrials, nt] = size(freezes.dataRew.portMatrix);
        if numtrials ~= c.nTrials
            missing_trials = abs(c.nTrials-numtrials);
            pm = [nan(missing_trials, nt); freezes.dataRew.portMatrix];
            freezes.dataRew.portMatrix=pm;
        end
        
        metaUNP(folderNum).freeze=freezes;
        
        % convert nan to 0 here
        if any(any(isnan(metaUNP(folderNum).freeze.dataRew.portMatrix)))
            warning('Converting nan entries in Freeze Reward to 0 here... (%s)',c.folderNameCell_UNP{folderNum})
            metaUNP(folderNum).freeze.dataRew.portMatrix(isnan(metaUNP(folderNum).freeze.dataRew.portMatrix)) = 0;
        end
        if any(any(isnan(metaUNP(folderNum).freeze.dataShock.portMatrix)))
            warning('Converting nan entries in Freeze Reward to 0 here... (%s)',c.folderNameCell_UNP{folderNum})
            metaUNP(folderNum).freeze.dataShock.portMatrix(isnan(metaUNP(folderNum).freeze.dataShock.portMatrix)) = 0;
        end
        
        % check the video frame rate
        v = VideoReader(fullfile(c.dataDir, c.folderNameCell_PR{folderNum}, [c.folderNameCell_PR{folderNum} '.mp4']));
        fps = v.FrameRate;
        
        if fps==15
            disp('Upsampling relevant variables from 15 fps to 30')
            
            % Method 1
            tmp = metaUNP(folderNum).freeze.dataRew.portMatrix;
            newPM = zeros(size(tmp,1),2*size(tmp,2)-1);
            for ii =1:size(tmp,1)
                tmp2 = [tmp(ii,:);tmp(ii,:)];
                tmp2= tmp2(:);
                newPM(ii,:) = tmp2(1:end-1);
            end
            metaUNP(folderNum).freeze.dataRew.portMatrix = newPM;
            clear tmp tmp2 newPM
            
            tmp = metaUNP(folderNum).freeze.dataShock.portMatrix;
            newPM = zeros(size(tmp,1),2*size(tmp,2)-1);
            for ii =1:size(tmp,1)
                tmp2 = [tmp(ii,:);tmp(ii,:)];
                tmp2= tmp2(:);
                newPM(ii,:) = tmp2(1:end-1);
            end
            metaUNP(folderNum).freeze.dataShock.portMatrix = newPM;
            clear tmp tmp2 newPM
        end
        
        % collect the individual heatmaps for cs-rew and cs-shock for UNPaired animals
        UNP_CS_rew_portMatrix(:,:,folderNum) = metaUNP(folderNum).freeze.dataRew.portMatrix;
        UNP_CS_shk_portMatrix(:,:,folderNum) = metaUNP(folderNum).freeze.dataShock.portMatrix;
        
        % collect the difference scores between cue and baseline windows for cs-rew and cs-shock for paired animals
        UNP_CS_rew.portBaseExpDiffPercent(folderNum) = metaUNP(folderNum).freeze.dataRew.portBaseExpDiffPercentMEAN(3); % only need the last entry, which is diff = cue - base
        UNP_CS_shk.portBaseExpDiffPercent(folderNum) = metaUNP(folderNum).freeze.dataShock.portBaseExpDiffPercentMEAN(3); % only need the last entry, which is diff = cue - base
        
        UNP_CS_rew.portBaseExpDiffPercent_all(folderNum,:) = metaUNP(folderNum).freeze.dataRew.portBaseExpDiffPercentMEAN;
        UNP_CS_shk.portBaseExpDiffPercent_all(folderNum,:) = metaUNP(folderNum).freeze.dataShock.portBaseExpDiffPercentMEAN;
        
        UNP_CS_rew.ID(folderNum) = c.folderNameCell_UNP(folderNum);
        UNP_CS_shk.ID(folderNum) = c.folderNameCell_UNP(folderNum);
    end
    
    
    
    % % average each across indiviuals, and across trials to get the mean and SEM
    P_CS_rew = analyzeGroupBehavior(P_CS_rew_portMatrix,P_CS_rew);
    P_CS_shk = analyzeGroupBehavior(P_CS_shk_portMatrix,P_CS_shk);
    UNP_CS_rew = analyzeGroupBehavior(UNP_CS_rew_portMatrix,UNP_CS_rew);
    UNP_CS_shk = analyzeGroupBehavior(UNP_CS_shk_portMatrix,UNP_CS_shk);
    
    oldc = c;
    save(fullfile(c.dataDir,  'Group_freezeData.mat'), ...
        'P_CS_rew','P_CS_shk','UNP_CS_rew','UNP_CS_shk',...
        'oldc','metaPR','metaUNP');
    
    %% FIGURE TIME
    fh_rew = figure('Position',[1039,86,700,900],'Name','Reward freeze','Visible','on');
    xrange = P_CS_rew.portMatrixMEAN;
    
    % PAIRED REWARD SUBPLOT
    subplot(3,2,1);
    plotPortMatrix(c, P_CS_rew);
    title({sprintf('Paired Group (N=%d)',numel(P_CS_rew.ID)),'CS-Rew Freeze'})
    % plotPortGraphs(P_CS_rew)
    
    % UNPAIRED REWARD SUBPLOT
    subplot(3,2,3);
    plotPortMatrix(c, UNP_CS_rew);
    title({sprintf('UNP Group (N=%d)',numel(UNP_CS_rew.ID)),'CS-Rew Freeze'})
    
    subplot(3,2,5);
    fm_pn_errorbar(1:size(xrange,2),P_CS_rew.portMatrixMEAN,P_CS_rew.portMatrixSEM,[0.8 0.1 0.1]);
    hold on;
    fm_pn_errorbar(1:size(xrange,2),UNP_CS_rew.portMatrixMEAN,UNP_CS_rew.portMatrixSEM,[0.1 0.1 0.8]);
    set(gca, 'XTick', []);
    title('Trial-averaged freeze')
    ylabel('% animals freezing')
    ylim([0 .5])
    if 1
        % plot baseline window
        nTrials = size(P_CS_rew.portMatrix,1);
        xTemp1 = ((c.dispWin(1)*-1+c.baseWin(1))*c.fps);
        xTemp1 = xTemp1+1; % wiggle for visibility
        x = [xTemp1 xTemp1]; y = [0 nTrials+0.5]; line(x,y,'Color','red','LineStyle','--');
        xTemp2 = ((c.dispWin(1)*-1+c.baseWin(2))*c.fps);
        xTemp2 = xTemp2*0.99; % wiggle for visibility
        x = [xTemp2 xTemp2]; y = [0 nTrials+0.5]; line(x,y,'Color','red','LineStyle','--');
        line([xTemp1 xTemp2],[0.5 0.5],'Color','red','LineWidth',2);
        
        % plot experimental window
        nTrials = size(P_CS_rew.portMatrix,1);
        xTemp1 = ((c.dispWin(1)*-1+c.expWin(1))*c.fps);
        xTemp1 = xTemp1+1; % wiggle for visibility
        x = [xTemp1 xTemp1]; y = [0 nTrials+0.5]; line(x,y,'Color','green','LineStyle','--');
        xTemp2 = ((c.dispWin(1)*-1+c.expWin(2))*c.fps);
        xTemp2 = xTemp2*0.99; % wiggle for visibility
        x = [xTemp2 xTemp2]; y = [0 nTrials+0.5]; line(x,y,'Color','green','LineStyle','--');
        line([xTemp1 xTemp2],[0.5 0.5],'Color','green','LineWidth',2);
        
    end
    leg_text={'Paired error','Paired mean','Unpaired error','Unpaired mean'};
    leg = legend(leg_text,'Position',[0.4916    0.2398    0.1843    0.0728]);
    
    
    %%%%% BAR GRAPHS
    [h,p_rew] = ttest2(P_CS_rew.portBaseExpDiffPercent', UNP_CS_rew.portBaseExpDiffPercent');
    disp([h, p_rew])
    
    subplot(3,2,2);
    % plot the dots
    plot(1,P_CS_rew.portBaseExpDiffPercent,'o');hold on
    plot(2,UNP_CS_rew.portBaseExpDiffPercent,'d')
    % plot the bars
    x= 1:2; % 2 bars
    meanDiffScore = [P_CS_rew.portBaseExpDiffPercentMEAN UNP_CS_rew.portBaseExpDiffPercentMEAN];
    bb = bar(x,meanDiffScore);
    bb.FaceColor = 'none';
    hold on;
    % plot the error
    Y_err = [P_CS_rew.portBaseExpDiffPercentMEAN UNP_CS_rew.portBaseExpDiffPercentMEAN];
    SEM_err = [P_CS_rew.portBaseExpDiffPercentSEM,UNP_CS_rew.portBaseExpDiffPercentSEM];
    er = errorbar(x,Y_err,SEM_err);
    er.Color = [0 0 0];
    er.LineStyle = 'none';
    ylabel('Percent');
    title({'CS-Rew Freeze','Difference Score (Cue-BL)',sprintf('Student T-test p=%1.4f',p_rew)})
    set(gca,'Xtick',x)
    set(gca,'xticklabel',{'PR','UNP'})
    % ylim([-1 1]);
    
    % add the legend
    leg = legend('Location','bestoutside','Interpreter','none','Position',[ 0.5220    0.3365    0.4557    0.3311]);
    leg.String = [P_CS_rew.ID';UNP_CS_rew.ID'];
    
    figname = fullfile(c.dataDir,  'Compare_Pair_Unpair_freezes_CS-reward.png');
    saveFigEpsPng(figname,fh_rew)
    
    
    %%
    fh_shock = figure('Position',[1039,86,700,900],'Name','Shock freeze','Visible','on');
    
    % PAIRED SHOCK SUBPLOT
    subplot(3,2,1);
    plotPortMatrix(c, P_CS_shk);
    title({sprintf('Paired Group (N=%d)',numel(P_CS_shk.ID)),'CS-Shock Freeze'})
        
    % UNPAIRED SHOCK SUBPLOT
    subplot(3,2,3);
    plotPortMatrix(c, UNP_CS_shk);
    title({sprintf('UNP Group (N=%d)',numel(UNP_CS_shk.ID)),'CS-Shock Freeze'})
    
    subplot(3,2,5);
    fm_pn_errorbar(1:size(xrange,2),P_CS_shk.portMatrixMEAN,P_CS_shk.portMatrixSEM,[0.8 0.1 0.1]);
    hold on;
    fm_pn_errorbar(1:size(xrange,2),UNP_CS_shk.portMatrixMEAN,UNP_CS_shk.portMatrixSEM,[0.1 0.1 0.8]);
    set(gca, 'XTick', []);
    title('Trial-averaged freeze')
    ylabel('% animals freezing')
    ylim([0 .5])
    
    if 1
        % plot baseline window
        nTrials = size(P_CS_rew.portMatrix,1);
        xTemp1 = ((c.dispWin(1)*-1+c.baseWin(1))*c.fps);
        xTemp1 = xTemp1+1; % wiggle for visibility
        x = [xTemp1 xTemp1]; y = [0 nTrials+0.5]; line(x,y,'Color','red','LineStyle','--');
        xTemp2 = ((c.dispWin(1)*-1+c.baseWin(2))*c.fps);
        xTemp2 = xTemp2*0.99; % wiggle for visibility
        x = [xTemp2 xTemp2]; y = [0 nTrials+0.5]; line(x,y,'Color','red','LineStyle','--');
        line([xTemp1 xTemp2],[0.5 0.5],'Color','red','LineWidth',2);
        
        % plot experimental window
        nTrials = size(P_CS_rew.portMatrix,1);
        xTemp1 = ((c.dispWin(1)*-1+c.expWin(1))*c.fps);
        xTemp1 = xTemp1+1; % wiggle for visibility
        x = [xTemp1 xTemp1]; y = [0 nTrials+0.5]; line(x,y,'Color','green','LineStyle','--');
        xTemp2 = ((c.dispWin(1)*-1+c.expWin(2))*c.fps);
        xTemp2 = xTemp2*0.99; % wiggle for visibility
        x = [xTemp2 xTemp2]; y = [0 nTrials+0.5]; line(x,y,'Color','green','LineStyle','--');
        line([xTemp1 xTemp2],[0.5 0.5],'Color','green','LineWidth',2);
        
    end
    leg_text={'Paired error','Paired mean','Unpaired error','Unpaired mean'};
    leg = legend(leg_text,'Position',[0.4916    0.2398    0.1843    0.0728]);
    
    %%%%% BAR GRAPHS
    [h,p_shk] = ttest2(P_CS_shk.portBaseExpDiffPercent', UNP_CS_shk.portBaseExpDiffPercent');
    disp([h, p_shk])
    
    subplot(3,2,2);
    % plot the dots
        plot(1,P_CS_shk.portBaseExpDiffPercent,'o');hold on
        plot(2,UNP_CS_shk.portBaseExpDiffPercent,'d')
    % plot the bars
    x= 1:2; % 2 bars
    meanDiffScore = [P_CS_shk.portBaseExpDiffPercentMEAN UNP_CS_shk.portBaseExpDiffPercentMEAN];
    bb = bar(x,meanDiffScore);
    bb.FaceColor = 'none';
    hold on;
    % plot the error
    Y_err = [P_CS_shk.portBaseExpDiffPercentMEAN UNP_CS_shk.portBaseExpDiffPercentMEAN];
    SEM_err = [P_CS_shk.portBaseExpDiffPercentSEM,UNP_CS_shk.portBaseExpDiffPercentSEM];
    er = errorbar(x,Y_err,SEM_err);
    er.Color = [0 0 0];
    er.LineStyle = 'none';
    ylabel('Percent');
    title({'CS-Shock Freeze','Difference Score (Cue-BL)',sprintf('Student T-test p=%1.4f',p_shk)})
    set(gca,'Xtick',x)
    set(gca,'xticklabel',{'PR','UNP'})
    % ylim([-1 1]);
    
    % add the legend
    leg = legend('Location','bestoutside','Interpreter','none','Position',[ 0.5220    0.3365    0.4557    0.3311]);
    leg.String = [P_CS_shk.ID';UNP_CS_shk.ID'];
    
    
    figname = fullfile(c.dataDir,  'Compare_Pair_Unpair_freezes_CS-shock.png');
    if SAVFIG, saveFigEpsPng(figname,fh_shock); end
    
    
    
    %%     % look at within trial comparison of reward and shock
    
    % 1. make the figure of shock vs reward for paired group
    fh_shock_rew = figure('Position',[1039,86,700,900],'Name','Paired Freeze','Visible','on');
    xrange = P_CS_rew.portMatrixMEAN;
    ymax = .75;
    
    subplot(2,2,1)
    fm_pn_errorbar(1:size(xrange,2),P_CS_shk.portMatrixMEAN,P_CS_shk.portMatrixSEM,[0.8 0.1 0.1]);
    hold on;
    fm_pn_errorbar(1:size(xrange,2),P_CS_rew.portMatrixMEAN,P_CS_rew.portMatrixSEM,[0.1 0.1 0.8]);
%     set(gca, 'XTick', []);
    title('Trial-averaged freezing for PAIRED subjects')
    ylabel('% animals freezing behavior')
    ylim([0 ymax])
    
    if 1
        % plot baseline window
        nTrials = size(P_CS_rew.portMatrix,1);
        xTemp1 = ((c.dispWin(1)*-1+c.baseWin(1))*c.fps);
        xTemp1 = xTemp1+1; % wiggle for visibility
        x = [xTemp1 xTemp1]; y = [0 nTrials+0.5]; line(x,y,'Color','red','LineStyle','--');
        xTemp2 = ((c.dispWin(1)*-1+c.baseWin(2))*c.fps);
        xTemp2 = xTemp2*0.99; % wiggle for visibility
        x = [xTemp2 xTemp2]; y = [0 nTrials+0.5]; line(x,y,'Color','red','LineStyle','--');
        line([xTemp1 xTemp2],[ymax ymax],'Color','red','LineWidth',2);
        
        % plot experimental window
        nTrials = size(P_CS_rew.portMatrix,1);
        xTemp1 = ((c.dispWin(1)*-1+c.expWin(1))*c.fps);
        xTemp1 = xTemp1+1; % wiggle for visibility
        x = [xTemp1 xTemp1]; y = [0 nTrials+0.5]; line(x,y,'Color','green','LineStyle','--');
        xTemp2 = ((c.dispWin(1)*-1+c.expWin(2))*c.fps);
        xTemp2 = xTemp2*0.99; % wiggle for visibility
        x = [xTemp2 xTemp2]; y = [0 nTrials+0.5]; line(x,y,'Color','green','LineStyle','--');
        line([xTemp1 xTemp2],[ymax ymax],'Color','green','LineWidth',2);
        
    end
    leg_text={'Paired shock error','Paired shock mean','Paired reward error','Paired reward mean'};
    leg = legend(leg_text,'Position',[0.5445    0.7898    0.2200    0.0728]);
    
    %     cue_shk_P = P_CS_shk.portMatrixMEAN(xTemp1:xTemp2);
    %     cue_rew_P = P_CS_rew.portMatrixMEAN(xTemp1:xTemp2);
    
    
    % figure;    plot(cue_shk_P,'Color',[0.8 0.1 0.1]);hold on; plot(cue_rew_P,'Color',[0.1 0.1 0.8])
    
    % 2. gather all individual dots and make the bar plot for rew vs shk
    % NOTE: because this is a within trial  case, we need to use the
    % matched pairs t-test, where we match entries to same subject.
    [h,p_shk_rew,ci,stats] = ttest(P_CS_shk.portBaseExpDiffPercent', P_CS_rew.portBaseExpDiffPercent');
    disp([h, p_shk_rew])
    subplot(2,2,3);
    % plot the dots
    plot(1,P_CS_rew.portBaseExpDiffPercent,'o'); hold on    ;
    plot(2,P_CS_shk.portBaseExpDiffPercent,'d');
    % plot lines between dots
    for jj = 1:numel(P_CS_rew.portBaseExpDiffPercent)
        plot([1 2],  [P_CS_rew.portBaseExpDiffPercent(jj) P_CS_shk.portBaseExpDiffPercent(jj)],'Color',[.7 .7 .7])
    end
    % plot the bars
    x = 1:2; % 2 bars
    meanDiffScore = [P_CS_rew.portBaseExpDiffPercentMEAN P_CS_shk.portBaseExpDiffPercentMEAN];
    bb = bar(x,meanDiffScore);
    bb.FaceColor = 'none';
    hold on;
    % plot the error
    Y_err   = [P_CS_rew.portBaseExpDiffPercentMEAN P_CS_shk.portBaseExpDiffPercentMEAN];
    SEM_err = [P_CS_rew.portBaseExpDiffPercentSEM,P_CS_shk.portBaseExpDiffPercentSEM];
    er = errorbar(x,Y_err,SEM_err);
    er.Color = [0 0 0];
    er.LineStyle = 'none';
    ylabel('Percent');
    title({'CS-Rew vs CS-Shk Freeze (PAIRED) ','Difference Score (cue-bl)',...
        sprintf('Student T-test p=%1.4f, tstat=%1.2f,df=%d',p_shk_rew,stats.tstat, stats.df)})
    set(gca,'Xtick',x)
    set(gca,'xticklabel',{'CS-Rew','CS-Shock'})
    % ylim([-1 1]);
    
    % add the legend
    leg = legend('Location','best','Interpreter','none','Position',[0.5002    0.2600    0.4229    0.1417]);
    leg.String = [P_CS_rew.ID';P_CS_shk.ID'];
    % 3. use a t-test or non-param version
    % 4. RM anova?
    
    figname = fullfile(c.dataDir,  'Compare_cs-rew_cs-shk_freeze_paired.png');
    saveFigEpsPng(figname, fh_shock_rew)
    
    
    
    % 1. make the figure of shock vs reward for unpaired group
    fh_shock_rew_UNP = figure('Position',[1039,86,700,900],'Name','Unpaired Freeze','Visible','on');
    xrange = UNP_CS_rew.portMatrixMEAN;
    ymax = .75;
    
    subplot(2,2,1)
    fm_pn_errorbar(1:size(xrange,2),UNP_CS_shk.portMatrixMEAN, UNP_CS_shk.portMatrixSEM,[0.8 0.1 0.1]);
    hold on;
    fm_pn_errorbar(1:size(xrange,2), UNP_CS_rew.portMatrixMEAN, UNP_CS_rew.portMatrixSEM,[0.1 0.1 0.8]);
    set(gca, 'XTick', []);
    title('Trial-averaged freezing for UNPAIRED subjects')
    ylabel('% animals freezing behavior')
    ylim([0 ymax])
    if 1
        % plot baseline window
        nTrials = size(UNP_CS_rew.portMatrix,1);
        xTemp1 = ((c.dispWin(1)*-1+c.baseWin(1))*c.fps);
        xTemp1 = xTemp1+1; % wiggle for visibility
        x = [xTemp1 xTemp1]; y = [0 nTrials+0.5]; line(x,y,'Color','red','LineStyle','--');
        xTemp2 = ((c.dispWin(1)*-1+c.baseWin(2))*c.fps);
        xTemp2 = xTemp2*0.99; % wiggle for visibility
        x = [xTemp2 xTemp2]; y = [0 nTrials+0.5]; line(x,y,'Color','red','LineStyle','--');
        line([xTemp1 xTemp2],[ymax ymax],'Color','red','LineWidth',2);
        
        % plot experimental window
        nTrials = size(UNP_CS_rew.portMatrix,1);
        xTemp1 = ((c.dispWin(1)*-1+c.expWin(1))*c.fps);
        xTemp1 = xTemp1+1; % wiggle for visibility
        x = [xTemp1 xTemp1]; y = [0 nTrials+0.5]; line(x,y,'Color','green','LineStyle','--');
        xTemp2 = ((c.dispWin(1)*-1+c.expWin(2))*c.fps);
        xTemp2 = xTemp2*0.99; % wiggle for visibility
        x = [xTemp2 xTemp2]; y = [0 nTrials+0.5]; line(x,y,'Color','green','LineStyle','--');
        line([xTemp1 xTemp2],[ymax ymax],'Color','green','LineWidth',2);
        
    end
    leg_text={'Unpaired shock error','Unpaired shock mean','Unpaired reward error','Unpaired reward mean'};
    leg = legend(leg_text,'Position',[0.5445    0.7898    0.2200    0.0728]);
    
    % 2. gather all individual dots and make the bar plot for rew vs shk
    [h,unp_shk_rew,ci,stats] = ttest(UNP_CS_shk.portBaseExpDiffPercent', UNP_CS_rew.portBaseExpDiffPercent');
    disp([h, unp_shk_rew])
    subplot(2,2,3);
    % plot the dots
    plot(1,UNP_CS_rew.portBaseExpDiffPercent,'o');hold on    
    plot(2,UNP_CS_shk.portBaseExpDiffPercent,'d')
    for jj = 1:numel(UNP_CS_rew.portBaseExpDiffPercent)
        plot([1 2], [UNP_CS_rew.portBaseExpDiffPercent(jj) UNP_CS_shk.portBaseExpDiffPercent(jj)],'Color',[.7 .7 .7])
    end
    
    % plot the bars
    x = 1:2; % 2 bars
    meanDiffScore = [UNP_CS_rew.portBaseExpDiffPercentMEAN UNP_CS_shk.portBaseExpDiffPercentMEAN];
    bb = bar(x,meanDiffScore);
    bb.FaceColor = 'none';
    hold on;
    % plot the error
    Y_err = [UNP_CS_rew.portBaseExpDiffPercentMEAN UNP_CS_shk.portBaseExpDiffPercentMEAN];
    SEM_err = [UNP_CS_rew.portBaseExpDiffPercentSEM,UNP_CS_shk.portBaseExpDiffPercentSEM];
    er = errorbar(x,Y_err,SEM_err);
    er.Color = [0 0 0];
    er.LineStyle = 'none';
    ylabel('Percent');
    title({'CS-Rew vs CS-Shk Freeze (UNPAIRED) ','Difference Score (cue-bl)',...
                sprintf('Student T-test p=%1.4f, tstat=%1.2f,df=%d',p_shk_rew,stats.tstat, stats.df)})

    set(gca,'Xtick',x)
    set(gca,'xticklabel',{'CS-Rew','CS-Shock'})
    % ylim([-1 1]);
    
    % add the legend
    leg = legend('Location','best','Interpreter','none','Position',[0.5002    0.2600    0.4229    0.1417]);
    leg.String = [UNP_CS_rew.ID';UNP_CS_shk.ID'];
    
    figname = fullfile(c.dataDir,  'Compare_cs-rew_cs-shk_freeze_UNP.png');
    saveFigEpsPng(figname, fh_shock_rew_UNP)
    
    
    disp('Done Freeze.')
    
end


%%

if c.PlotDash ==1
    % load paired datasets
    for folderNum = 1:length(c.folderNameCell_PR)
        load(fullfile(c.dataDir, c.folderNameCell_PR{folderNum}, [c.folderNameCell_PR{folderNum} '_dashData.mat']),'dashes');
        
        % check the number of trials and pad with nan if needed
        [numtrials, nt] = size(dashes.dataRew.portMatrix);
        if numtrials ~= c.nTrials
            missing_trials = abs(c.nTrials-numtrials);
            pm = [nan(missing_trials, nt); dashes.dataRew.portMatrix];
            dashes.dataRew.portMatrix=pm;
        end
        metaPR(folderNum).dash=dashes;
        
        % check the video frame rate
        v = VideoReader(fullfile(c.dataDir, c.folderNameCell_PR{folderNum}, [c.folderNameCell_PR{folderNum} '.mp4']));
        fps = v.FrameRate;
        
        if fps==15
            disp('Upsampling relevant variables from 15 fps to 30')
            
            % Method 1
            tmp = metaPR(folderNum).dash.dataRew.portMatrix;
            newPM = zeros(size(tmp,1),2*size(tmp,2)-1);
            for ii =1:size(tmp,1)
                tmp2 = [tmp(ii,:);tmp(ii,:)];
                tmp2= tmp2(:);
                newPM(ii,:) = tmp2(1:end-1);
            end
            metaPR(folderNum).dash.dataRew.portMatrix = newPM;
            clear tmp tmp2 newPM
            
            tmp = metaPR(folderNum).dash.dataShock.portMatrix;
            newPM = zeros(size(tmp,1),2*size(tmp,2)-1);
            for ii =1:size(tmp,1)
                tmp2 = [tmp(ii,:);tmp(ii,:)];
                tmp2= tmp2(:);
                newPM(ii,:) = tmp2(1:end-1);
            end
            metaPR(folderNum).dash.dataShock.portMatrix = newPM;
            clear tmp tmp2 newPM
        end
        % collect the individual heatmaps for cs-rew and cs-shock for paired animals
        P_CS_rew_portMatrix(:,:,folderNum) = metaPR(folderNum).dash.dataRew.portMatrix;
        P_CS_shk_portMatrix(:,:,folderNum) = metaPR(folderNum).dash.dataShock.portMatrix;
        
        % collect the difference scores between cue and baseline windows for cs-rew and cs-shock for paired animals
        P_CS_rew.portBaseExpDiffPercent(folderNum) = metaPR(folderNum).dash.dataRew.portBaseExpDiffPercentMEAN(3); % only need the last entry, which is diff = cue - base
        P_CS_shk.portBaseExpDiffPercent(folderNum) = metaPR(folderNum).dash.dataShock.portBaseExpDiffPercentMEAN(3); % only need the last entry, which is diff = cue - base
        
        P_CS_rew.ID(folderNum) = c.folderNameCell_PR(folderNum);
        P_CS_shk.ID(folderNum) = c.folderNameCell_PR(folderNum);
    end
    
    % load unpaired datasets
    for folderNum = 1:length(c.folderNameCell_UNP)
        load(fullfile(c.dataDir, c.folderNameCell_UNP{folderNum}, [c.folderNameCell_UNP{folderNum} '_dashData.mat']),'dashes');
        
        % check the number of trials and pad with nan if needed
        [numtrials, nt] = size(dashes.dataRew.portMatrix);
        if numtrials ~= c.nTrials
            missing_trials = abs(c.nTrials-numtrials);
            pm = [nan(missing_trials, nt); dashes.dataRew.portMatrix];
            dashes.dataRew.portMatrix=pm;
        end
        metaUNP(folderNum).dash=dashes;
        
        % convert nan to 0 here
        if any(any(isnan(metaUNP(folderNum).dash.dataRew.portMatrix)))
            warning('Converting nan entries in dash Reward to 0 here... (%s)',c.folderNameCell_UNP{folderNum})
            metaUNP(folderNum).dash.dataRew.portMatrix(isnan(metaUNP(folderNum).dash.dataRew.portMatrix)) = 0;
        end
        if any(any(isnan(metaUNP(folderNum).dash.dataShock.portMatrix)))
            warning('Converting nan entries in dash Shock to 0 here... (%s)',c.folderNameCell_UNP{folderNum})
            metaUNP(folderNum).dash.dataShock.portMatrix(isnan(metaUNP(folderNum).dash.dataShock.portMatrix)) = 0;
        end
        
        
        % check the video frame rate
        v = VideoReader(fullfile(c.dataDir, c.folderNameCell_PR{folderNum}, [c.folderNameCell_PR{folderNum} '.mp4']));
        fps = v.FrameRate;
        
        if fps==15
            disp('Upsampling relevant variables from 15 fps to 30')
            
            % Method 1
            tmp = metaUNP(folderNum).dash.dataRew.portMatrix;
            newPM = zeros(size(tmp,1),2*size(tmp,2)-1);
            for ii =1:size(tmp,1)
                tmp2 = [tmp(ii,:);tmp(ii,:)];
                tmp2= tmp2(:);
                newPM(ii,:) = tmp2(1:end-1);
            end
            metaUNP(folderNum).dash.dataRew.portMatrix = newPM;
            clear tmp tmp2 newPM
            
            tmp = metaUNP(folderNum).dash.dataShock.portMatrix;
            newPM = zeros(size(tmp,1),2*size(tmp,2)-1);
            for ii =1:size(tmp,1)
                tmp2 = [tmp(ii,:);tmp(ii,:)];
                tmp2= tmp2(:);
                newPM(ii,:) = tmp2(1:end-1);
            end
            metaUNP(folderNum).dash.dataShock.portMatrix = newPM;
            clear tmp tmp2 newPM
        end
        % collect the individual heatmaps for cs-rew and cs-shock for UNPaired animals
        UNP_CS_rew_portMatrix(:,:,folderNum) = metaUNP(folderNum).dash.dataRew.portMatrix;
        UNP_CS_shk_portMatrix(:,:,folderNum) = metaUNP(folderNum).dash.dataShock.portMatrix;
        
        % collect the difference scores between cue and baseline windows for cs-rew and cs-shock for paired animals
        UNP_CS_rew.portBaseExpDiffPercent(folderNum) = metaUNP(folderNum).dash.dataRew.portBaseExpDiffPercentMEAN(3); % only need the last entry, which is diff = cue - base
        UNP_CS_shk.portBaseExpDiffPercent(folderNum) = metaUNP(folderNum).dash.dataShock.portBaseExpDiffPercentMEAN(3); % only need the last entry, which is diff = cue - base
    
        UNP_CS_rew.ID(folderNum) = c.folderNameCell_UNP(folderNum);
        UNP_CS_shk.ID(folderNum) = c.folderNameCell_UNP(folderNum);
    end
    
    % % average each across indiviuals, and across trials to get the mean and SEM
    P_CS_rew = analyzeGroupBehavior(P_CS_rew_portMatrix,P_CS_rew);
    P_CS_shk = analyzeGroupBehavior(P_CS_shk_portMatrix,P_CS_shk);
    UNP_CS_rew = analyzeGroupBehavior(UNP_CS_rew_portMatrix,UNP_CS_rew);
    UNP_CS_shk = analyzeGroupBehavior(UNP_CS_shk_portMatrix,UNP_CS_shk);
    
    oldc = c;
    save(fullfile(c.dataDir,  'Group_dashData.mat'), ...
        'P_CS_rew','P_CS_shk','UNP_CS_rew','UNP_CS_shk',...
        'oldc','metaPR','metaUNP');
    
    %% FIGURE TIME
    fh_rew = figure('Position',[1039,86,700,900],'Name','Reward Dash','Visible','on');
    xrange = P_CS_rew.portMatrixMEAN;
    
    % PAIRED REWARD SUBPLOT
    subplot(3,2,1);
    plotPortMatrix(c, P_CS_rew);
    title({sprintf('Paired Group (N=%d)',numel(P_CS_rew.ID)),'CS-Rew Dash'})
    
    % UNPAIRED REWARD SUBPLOT
    subplot(3,2,3);
    plotPortMatrix(c, UNP_CS_rew);
    title({sprintf('UNP Group (N=%d)',numel(UNP_CS_rew.ID)),'CS-Rew Dash'})
    
    subplot(3,2,5);
    fm_pn_errorbar(1:size(xrange,2),P_CS_rew.portMatrixMEAN,P_CS_rew.portMatrixSEM,[0.8 0.1 0.1]);
    hold on;
    fm_pn_errorbar(1:size(xrange,2),UNP_CS_rew.portMatrixMEAN,UNP_CS_rew.portMatrixSEM,[0.1 0.1 0.8]);
    set(gca, 'XTick', []);
    title('Trial-averaged dash')
    ylabel('% animals Dashing')
    ylim([0 .5])
    
    if 1
        % plot baseline window
        nTrials = size(P_CS_rew.portMatrix,1);
        xTemp1 = ((c.dispWin(1)*-1+c.baseWin(1))*c.fps);
        xTemp1 = xTemp1+1; % wiggle for visibility
        x = [xTemp1 xTemp1]; y = [0 nTrials+0.5]; line(x,y,'Color','red','LineStyle','--');
        xTemp2 = ((c.dispWin(1)*-1+c.baseWin(2))*c.fps);
        xTemp2 = xTemp2*0.99; % wiggle for visibility
        x = [xTemp2 xTemp2]; y = [0 nTrials+0.5]; line(x,y,'Color','red','LineStyle','--');
        line([xTemp1 xTemp2],[0.5 0.5],'Color','red','LineWidth',2);
        
        % plot experimental window
        nTrials = size(P_CS_rew.portMatrix,1);
        xTemp1 = ((c.dispWin(1)*-1+c.expWin(1))*c.fps);
        xTemp1 = xTemp1+1; % wiggle for visibility
        x = [xTemp1 xTemp1]; y = [0 nTrials+0.5]; line(x,y,'Color','green','LineStyle','--');
        xTemp2 = ((c.dispWin(1)*-1+c.expWin(2))*c.fps);
        xTemp2 = xTemp2*0.99; % wiggle for visibility
        x = [xTemp2 xTemp2]; y = [0 nTrials+0.5]; line(x,y,'Color','green','LineStyle','--');
        line([xTemp1 xTemp2],[0.5 0.5],'Color','green','LineWidth',2);
        
    end
    leg_text={'Paired error','Paired mean','Unpaired error','Unpaired mean'};
    leg = legend(leg_text,'Position',[0.4916    0.2398    0.1843    0.0728]);
    
    %%%%% BAR GRAPHS
    [h,p_rew] = ttest2(P_CS_rew.portBaseExpDiffPercent', UNP_CS_rew.portBaseExpDiffPercent');
    disp([h, p_rew])
    
    
    subplot(3,2,2);
    % plot the dots
    plot(1,P_CS_rew.portBaseExpDiffPercent,'o');hold on
    plot(2,UNP_CS_rew.portBaseExpDiffPercent,'d')
    
    
    % plot the bars
    x= 1:2; % 2 bars
    meanDiffScore = [P_CS_rew.portBaseExpDiffPercentMEAN UNP_CS_rew.portBaseExpDiffPercentMEAN];
    bb = bar(x,meanDiffScore);
    bb.FaceColor = 'none';
    hold on;
    % plot the error
    Y_err = [P_CS_rew.portBaseExpDiffPercentMEAN UNP_CS_rew.portBaseExpDiffPercentMEAN];
    SEM_err = [P_CS_rew.portBaseExpDiffPercentSEM,UNP_CS_rew.portBaseExpDiffPercentSEM];
    er = errorbar(x,Y_err,SEM_err);
    er.Color = [0 0 0];
    er.LineStyle = 'none';
    ylabel('Percent');
    title({'CS-Rew Dash','Difference Score (Cue-BL)',sprintf('Student T-test p=%1.4f',p_rew)})
    set(gca,'Xtick',x)
    set(gca,'xticklabel',{'PR','UNP'})
    % ylim([-1 1]);
    
    % add the legend
    leg = legend('Location','bestoutside','Interpreter','none','Position',[ 0.5245    0.3453    0.4229    0.3311]);
    leg.String = [P_CS_rew.ID';UNP_CS_rew.ID'];
    
    
    figname = fullfile(c.dataDir,  'Compare_Pair_Unpair_dashes_CS-reward.png');
    if SAVFIG, saveFigEpsPng(figname,fh_rew); end
    
    
    %%
    fh_shock = figure('Position',[1039,86,700,900],'Name','Shock dash','Visible','on');
    
    % PAIRED SHOCK SUBPLOT
    subplot(3,2,1);
    plotPortMatrix(c, P_CS_shk);
    title({sprintf('Paired Group (N=%d)',numel(P_CS_shk.ID)),'CS-Shock Dash'})
    
    % UNPAIRED SHOCK SUBPLOT
    subplot(3,2,3);
    plotPortMatrix(c, UNP_CS_shk);
    title({sprintf('UNP Group (N=%d)',numel(UNP_CS_shk.ID)),'CS-Shock Dash'})
    
    subplot(3,2,5);
    fm_pn_errorbar(1:size(xrange,2),P_CS_shk.portMatrixMEAN,P_CS_shk.portMatrixSEM,[0.8 0.1 0.1]);
    hold on;
    fm_pn_errorbar(1:size(xrange,2),UNP_CS_shk.portMatrixMEAN,UNP_CS_shk.portMatrixSEM,[0.1 0.1 0.8]);
    set(gca, 'XTick', []);
    title('Trial-averaged Dash')
    ylabel('% animals Dashing')
    ylim([0 .5])
    if 1
        % plot baseline window
        nTrials = size(P_CS_rew.portMatrix,1);
        xTemp1 = ((c.dispWin(1)*-1+c.baseWin(1))*c.fps);
        xTemp1 = xTemp1+1; % wiggle for visibility
        x = [xTemp1 xTemp1]; y = [0 nTrials+0.5]; line(x,y,'Color','red','LineStyle','--');
        xTemp2 = ((c.dispWin(1)*-1+c.baseWin(2))*c.fps);
        xTemp2 = xTemp2*0.99; % wiggle for visibility
        x = [xTemp2 xTemp2]; y = [0 nTrials+0.5]; line(x,y,'Color','red','LineStyle','--');
        line([xTemp1 xTemp2],[0.5 0.5],'Color','red','LineWidth',2);
        
        % plot experimental window
        nTrials = size(P_CS_rew.portMatrix,1);
        xTemp1 = ((c.dispWin(1)*-1+c.expWin(1))*c.fps);
        xTemp1 = xTemp1+1; % wiggle for visibility
        x = [xTemp1 xTemp1]; y = [0 nTrials+0.5]; line(x,y,'Color','green','LineStyle','--');
        xTemp2 = ((c.dispWin(1)*-1+c.expWin(2))*c.fps);
        xTemp2 = xTemp2*0.99; % wiggle for visibility
        x = [xTemp2 xTemp2]; y = [0 nTrials+0.5]; line(x,y,'Color','green','LineStyle','--');
        line([xTemp1 xTemp2],[0.5 0.5],'Color','green','LineWidth',2);
        
    end
    leg_text={'Paired error','Paired mean','Unpaired error','Unpaired mean'};
    leg = legend(leg_text,'Position',[0.4916    0.2398    0.1843    0.0728]);
    
    %%%%% BAR GRAPHS
    [h,p_shk] = ttest2(P_CS_shk.portBaseExpDiffPercent', UNP_CS_shk.portBaseExpDiffPercent');
    disp([h, p_shk])
    
    subplot(3,2,2);
    % plot the dots
    plot(1,P_CS_shk.portBaseExpDiffPercent,'o');hold on
    plot(2,UNP_CS_shk.portBaseExpDiffPercent,'d')
    % plot the bars
    x= 1:2; % 2 bars
    meanDiffScore = [P_CS_shk.portBaseExpDiffPercentMEAN UNP_CS_shk.portBaseExpDiffPercentMEAN];
    bb = bar(x,meanDiffScore);
    bb.FaceColor = 'none';
    hold on;
    % plot the error
    Y_err = [P_CS_shk.portBaseExpDiffPercentMEAN UNP_CS_shk.portBaseExpDiffPercentMEAN];
    SEM_err = [P_CS_shk.portBaseExpDiffPercentSEM,UNP_CS_shk.portBaseExpDiffPercentSEM];
    er = errorbar(x,Y_err,SEM_err);
    er.Color = [0 0 0];
    er.LineStyle = 'none';
    ylabel('Percent');
    title({'CS-Shock Dash','Difference Score (Cue-BL)',sprintf('Student T-test p=%1.4f',p_shk)})
    set(gca,'Xtick',x)
    set(gca,'xticklabel',{'PR','UNP'})
    % ylim([-1 1]);
    
    % add the legend
    leg = legend('Location','bestoutside','Interpreter','none','Position',[ 0.5206    0.3520    0.4557    0.3311]);
    leg.String = [P_CS_shk.ID';UNP_CS_shk.ID'];
    
    figname = fullfile(c.dataDir,  'Compare_Pair_Unpair_dashes_CS-shock.png');
    saveFigEpsPng(figname,fh_shock)
        
    disp('Done Dash.')
    
end

%%

if c.PlotDefensive ==1
    % load paired datasets
    for folderNum = 1:length(c.folderNameCell_PR)
        load(fullfile(c.dataDir, c.folderNameCell_PR{folderNum}, [c.folderNameCell_PR{folderNum} '_defensiveData.mat']),'defensive');
        
        % check the number of trials and pad with nan if needed
        [numtrials, nt] = size(defensive.dataRew.portMatrix);
        if numtrials ~= c.nTrials
            missing_trials = abs(c.nTrials-numtrials);
            pm = [nan(missing_trials, nt); defensive.dataRew.portMatrix];
            defensive.dataRew.portMatrix=pm;
        end
        metaPR(folderNum).defensive=defensive;
        
        % check the video frame rate
        v = VideoReader(fullfile(c.dataDir, c.folderNameCell_PR{folderNum}, [c.folderNameCell_PR{folderNum} '.mp4']));
        fps = v.FrameRate;
        
        if fps==15
            disp('Upsampling relevant variables from 15 fps to 30')
            
            % Method 1
            tmp = metaPR(folderNum).defensive.dataRew.portMatrix;
            newPM = zeros(size(tmp,1),2*size(tmp,2)-1);
            for ii =1:size(tmp,1)
                tmp2 = [tmp(ii,:);tmp(ii,:)];
                tmp2= tmp2(:);
                newPM(ii,:) = tmp2(1:end-1);
            end
            metaPR(folderNum).defensive.dataRew.portMatrix = newPM;
            clear tmp tmp2 newPM
            
            tmp = metaPR(folderNum).defensive.dataShock.portMatrix;
            newPM = zeros(size(tmp,1),2*size(tmp,2)-1);
            for ii =1:size(tmp,1)
                tmp2 = [tmp(ii,:);tmp(ii,:)];
                tmp2= tmp2(:);
                newPM(ii,:) = tmp2(1:end-1);
            end
            metaPR(folderNum).defensive.dataShock.portMatrix = newPM;
            clear tmp tmp2 newPM
        end
        
        % collect the individual heatmaps for cs-rew and cs-shock for paired animals
        P_CS_rew_portMatrix(:,:,folderNum) = metaPR(folderNum).defensive.dataRew.portMatrix;
        P_CS_shk_portMatrix(:,:,folderNum) = metaPR(folderNum).defensive.dataShock.portMatrix;
        
        % collect the difference scores between cue and baseline windows for cs-rew and cs-shock for paired animals
        P_CS_rew.portBaseExpDiffPercent(folderNum) = metaPR(folderNum).defensive.dataRew.portBaseExpDiffPercentMEAN(3); % only need the last entry, which is diff = cue - base
        P_CS_shk.portBaseExpDiffPercent(folderNum) = metaPR(folderNum).defensive.dataShock.portBaseExpDiffPercentMEAN(3); % only need the last entry, which is diff = cue - base
        P_CS_rew.portBaseExpDiffPercent_all(folderNum,:) = metaPR(folderNum).defensive.dataRew.portBaseExpDiffPercentMEAN;
        P_CS_shk.portBaseExpDiffPercent_all(folderNum,:) = metaPR(folderNum).defensive.dataShock.portBaseExpDiffPercentMEAN;
        
        P_CS_rew.ID(folderNum) = c.folderNameCell_PR(folderNum);
        P_CS_shk.ID(folderNum) = c.folderNameCell_PR(folderNum);
    end
    
    % load unpaired datasets
    for folderNum = 1:length(c.folderNameCell_UNP)
        load(fullfile(c.dataDir, c.folderNameCell_UNP{folderNum}, [c.folderNameCell_UNP{folderNum} '_defensiveData.mat']),'defensive');
        
        % check the number of trials and pad with nan if needed
        [numtrials, nt] = size(defensive.dataRew.portMatrix);
        if numtrials ~= c.nTrials
            missing_trials = abs(c.nTrials-numtrials);
            pm = [nan(missing_trials, nt); defensive.dataRew.portMatrix];
            defensive.dataRew.portMatrix=pm;
        end
        metaUNP(folderNum).defensive = defensive;
        
        % convert nan to 0 here
        if any(any(isnan(metaUNP(folderNum).defensive.dataRew.portMatrix)))
            warning('Converting nan entries in defensive Reward to 0 here... (%s)',c.folderNameCell_UNP{folderNum})
            metaUNP(folderNum).defensive.dataRew.portMatrix(isnan(metaUNP(folderNum).defensive.dataRew.portMatrix)) = 0;
        end
        if any(any(isnan(metaUNP(folderNum).defensive.dataShock.portMatrix)))
            warning('Converting nan entries in defensive Reward to 0 here... (%s)',c.folderNameCell_UNP{folderNum})
            metaUNP(folderNum).defensive.dataShock.portMatrix(isnan(metaUNP(folderNum).defensive.dataShock.portMatrix)) = 0;
        end
        
        % check the video frame rate
        v = VideoReader(fullfile(c.dataDir, c.folderNameCell_PR{folderNum}, [c.folderNameCell_PR{folderNum} '.mp4']));
        fps = v.FrameRate;
        
        if fps==15
            disp('Upsampling relevant variables from 15 fps to 30')
            
            % Method 1
            tmp = metaUNP(folderNum).defensive.dataRew.portMatrix;
            newPM = zeros(size(tmp,1),2*size(tmp,2)-1);
            for ii =1:size(tmp,1)
                tmp2 = [tmp(ii,:);tmp(ii,:)];
                tmp2= tmp2(:);
                newPM(ii,:) = tmp2(1:end-1);
            end
            metaUNP(folderNum).defensive.dataRew.portMatrix = newPM;
            clear tmp tmp2 newPM
            
            tmp = metaUNP(folderNum).defensive.dataShock.portMatrix;
            newPM = zeros(size(tmp,1),2*size(tmp,2)-1);
            for ii =1:size(tmp,1)
                tmp2 = [tmp(ii,:);tmp(ii,:)];
                tmp2= tmp2(:);
                newPM(ii,:) = tmp2(1:end-1);
            end
            metaUNP(folderNum).defensive.dataShock.portMatrix = newPM;
            clear tmp tmp2 newPM
        end
        
        % collect the individual heatmaps for cs-rew and cs-shock for UNPaired animals
        UNP_CS_rew_portMatrix(:,:,folderNum) = metaUNP(folderNum).defensive.dataRew.portMatrix;
        UNP_CS_shk_portMatrix(:,:,folderNum) = metaUNP(folderNum).defensive.dataShock.portMatrix;
        
        % collect the difference scores between cue and baseline windows for cs-rew and cs-shock for paired animals
        UNP_CS_rew.portBaseExpDiffPercent(folderNum) = metaUNP(folderNum).defensive.dataRew.portBaseExpDiffPercentMEAN(3); % only need the last entry, which is diff = cue - base
        UNP_CS_shk.portBaseExpDiffPercent(folderNum) = metaUNP(folderNum).defensive.dataShock.portBaseExpDiffPercentMEAN(3); % only need the last entry, which is diff = cue - base
        UNP_CS_rew.portBaseExpDiffPercent_all(folderNum,:) = metaUNP(folderNum).defensive.dataRew.portBaseExpDiffPercentMEAN;
        UNP_CS_shk.portBaseExpDiffPercent_all(folderNum,:) = metaUNP(folderNum).defensive.dataShock.portBaseExpDiffPercentMEAN;
        
        if folderNum <= numel(c.folderNameCell_UNP)
            UNP_CS_rew.ID(folderNum) = c.folderNameCell_UNP(folderNum);
        end
        if folderNum <= numel(c.folderNameCell_UNP)
            UNP_CS_shk.ID(folderNum) = c.folderNameCell_UNP(folderNum);
        end
    end
        
    % % average each across indiviuals, and across trials to get the mean and SEM
    P_CS_rew   = analyzeGroupBehavior(  P_CS_rew_portMatrix,  P_CS_rew);
    P_CS_shk   = analyzeGroupBehavior(  P_CS_shk_portMatrix,  P_CS_shk);
    UNP_CS_rew = analyzeGroupBehavior(UNP_CS_rew_portMatrix,UNP_CS_rew);
    UNP_CS_shk = analyzeGroupBehavior(UNP_CS_shk_portMatrix,UNP_CS_shk);
    
    oldc = c;
    
    save(fullfile(c.dataDir,  'Group_defensiveData.mat'), ...
        'P_CS_rew','P_CS_shk','UNP_CS_rew','UNP_CS_shk',...
        'oldc','metaPR','metaUNP');
    %% FIGURE TIME
    fh_rew = figure('Position',[1039,86,700,900],'Name','Reward Defensive','Visible','on');
    xrange = P_CS_rew.portMatrixMEAN;
    
    % PAIRED REWARD SUBPLOT
    subplot(3,2,1);
    plotPortMatrix(c, P_CS_rew);
    title({sprintf('Paired Group (N=%d)',numel(P_CS_rew)),'CS-Rew Defensive'})
    % plotPortGraphs(P_CS_rew)
    
    % UNPAIRED REWARD SUBPLOT
    subplot(3,2,3);
    plotPortMatrix(c, UNP_CS_rew);
    title({sprintf('UNP Group (N=%d)',numel(UNP_CS_rew)), 'CS-Rew Defensive'})
    
    subplot(3,2,5);
    fm_pn_errorbar(1:size(xrange,2),  P_CS_rew.portMatrixMEAN,  P_CS_rew.portMatrixSEM,[0.8 0.1 0.1]);
    hold on;
    fm_pn_errorbar(1:size(xrange,2),UNP_CS_rew.portMatrixMEAN,UNP_CS_rew.portMatrixSEM,[0.1 0.1 0.8]);
    set(gca, 'XTick', []);
    title('Trial-averaged defensive')
    ylabel('% animals freezing')
    ylim([0 .5])
    if 1
        % plot baseline window
        nTrials = size(P_CS_rew.portMatrix,1);
        xTemp1 = ((c.dispWin(1)*-1+c.baseWin(1))*c.fps);
        xTemp1 = xTemp1+1; % wiggle for visibility
        x = [xTemp1 xTemp1]; y = [0 nTrials+0.5]; line(x,y,'Color','red','LineStyle','--');
        xTemp2 = ((c.dispWin(1)*-1+c.baseWin(2))*c.fps);
        xTemp2 = xTemp2*0.99; % wiggle for visibility
        x = [xTemp2 xTemp2]; y = [0 nTrials+0.5]; line(x,y,'Color','red','LineStyle','--');
        line([xTemp1 xTemp2],[0.5 0.5],'Color','red','LineWidth',2);
        
        % plot experimental window
        nTrials = size(P_CS_rew.portMatrix,1);
        xTemp1 = ((c.dispWin(1)*-1+c.expWin(1))*c.fps);
        xTemp1 = xTemp1+1; % wiggle for visibility
        x = [xTemp1 xTemp1]; y = [0 nTrials+0.5]; line(x,y,'Color','green','LineStyle','--');
        xTemp2 = ((c.dispWin(1)*-1+c.expWin(2))*c.fps);
        xTemp2 = xTemp2*0.99; % wiggle for visibility
        x = [xTemp2 xTemp2]; y = [0 nTrials+0.5]; line(x,y,'Color','green','LineStyle','--');
        line([xTemp1 xTemp2],[0.5 0.5],'Color','green','LineWidth',2);
        
    end
    leg_text={'Paired error','Paired mean','Unpaired error','Unpaired mean'};
    leg = legend(leg_text,'Position',[0.4916    0.2398    0.1843    0.0728]);
    
    
    %%%%% BAR GRAPHS
    [h,p_rew] = ttest2(P_CS_rew.portBaseExpDiffPercent', UNP_CS_rew.portBaseExpDiffPercent');
    disp([h, p_rew])
    
    
    subplot(3,2,2);
    % plot the dots
    for ii =1:numel(P_CS_rew)
        plot(1,P_CS_rew(ii).portBaseExpDiffPercent,'o');hold on
    end
    for ii = 1:numel(UNP_CS_rew)
        plot(2,UNP_CS_rew(ii).portBaseExpDiffPercent,'d')
    end
    % plot the bars
    x= 1:2; % 2 bars
    meanDiffScore = [P_CS_rew.portBaseExpDiffPercentMEAN UNP_CS_rew.portBaseExpDiffPercentMEAN];
    bb = bar(x,meanDiffScore);
    bb.FaceColor = 'none';
    hold on;
    % plot the error
    Y_err = [P_CS_rew.portBaseExpDiffPercentMEAN UNP_CS_rew.portBaseExpDiffPercentMEAN];
    SEM_err = [P_CS_rew.portBaseExpDiffPercentSEM,UNP_CS_rew.portBaseExpDiffPercentSEM];
    er = errorbar(x,Y_err,SEM_err);
    er.Color = [0 0 0];
    er.LineStyle = 'none';
    ylabel('Percent');
    title({'CS-Rew Defensive','Difference Score (Cue-BL)',sprintf('Student T-test p=%1.4f',p_rew)})
    set(gca,'Xtick',x)
    set(gca,'xticklabel',{'PR','UNP'})
    % ylim([-1 1]);
    
    % add the legend
    leg = legend('Location','bestoutside','Interpreter','none','Position',[0.5306    0.4184    0.4557    0.2450]);
    leg.String = [P_CS_rew.ID';UNP_CS_rew.ID'];
    
    figname = fullfile(c.dataDir,  'Compare_Pair_Unpair_defensives_CS-reward.png');
    
    saveFigEpsPng(figname, fh_rew)
    
    
    %%
    fh_shock = figure('Position',[1039,86,700,900],'Name','Shock defensive','Visible','on');
    
    % PAIRED SHOCK SUBPLOT
    subplot(3,2,1);
    plotPortMatrix(c, P_CS_shk);
    title({sprintf('Paired Group (N=%d)',numel(P_CS_shk)),'CS-Shock Defensive'})
    
    % UNPAIRED SHOCK SUBPLOT
    subplot(3,2,3);
    plotPortMatrix(c, UNP_CS_shk);
    title({sprintf('UNP Group (N=%d)',numel(UNP_CS_shk)), 'CS-Shock Defensive'})
    
    subplot(3,2,5);
    fm_pn_errorbar(1:size(xrange,2),P_CS_shk.portMatrixMEAN,P_CS_shk.portMatrixSEM,[0.8 0.1 0.1]);
    hold on;
    fm_pn_errorbar(1:size(xrange,2),UNP_CS_shk.portMatrixMEAN,UNP_CS_shk.portMatrixSEM,[0.1 0.1 0.8]);
    set(gca, 'XTick', []);
    title('Trial-averaged defensive')
    ylabel('% animals freezing')
    ymax = 0.6;
    ylim([0 ymax])
    if 1
        % plot baseline window
        nTrials = size(P_CS_rew.portMatrix,1);
        xTemp1 = ((c.dispWin(1)*-1+c.baseWin(1))*c.fps);
        xTemp1 = xTemp1+1; % wiggle for visibility
        x = [xTemp1 xTemp1]; y = [0 nTrials+ymax]; line(x,y,'Color','red','LineStyle','--');
        xTemp2 = ((c.dispWin(1)*-1+c.baseWin(2))*c.fps);
        xTemp2 = xTemp2*0.99; % wiggle for visibility
        x = [xTemp2 xTemp2]; y = [0 nTrials+0.5]; line(x,y,'Color','red','LineStyle','--');
        line([xTemp1 xTemp2],[ymax ymax],'Color','red','LineWidth',2);
        
        % plot experimental window
        nTrials = size(P_CS_rew.portMatrix,1);
        xTemp1 = ((c.dispWin(1)*-1+c.expWin(1))*c.fps);
        xTemp1 = xTemp1+1; % wiggle for visibility
        x = [xTemp1 xTemp1]; y = [0 nTrials+ymax]; line(x,y,'Color','green','LineStyle','--');
        xTemp2 = ((c.dispWin(1)*-1+c.expWin(2))*c.fps);
        xTemp2 = xTemp2*0.99; % wiggle for visibility
        x = [xTemp2 xTemp2]; y = [0 nTrials+0.5]; line(x,y,'Color','green','LineStyle','--');
        line([xTemp1 xTemp2],[ymax ymax],'Color','green','LineWidth',2);
        
    end
    leg_text={'Paired error','Paired mean','Unpaired error','Unpaired mean'};
    leg = legend(leg_text,'Position',[0.4916    0.2398    0.1843    0.0728]);
    
    %%%%% BAR GRAPHS
    [h,p_shk] = ttest2(P_CS_shk.portBaseExpDiffPercent', UNP_CS_shk.portBaseExpDiffPercent');
    disp([h, p_shk])
        
    subplot(3,2,2);
    % plot the dots
    for ii =1:numel(P_CS_shk)
        plot(1,P_CS_shk(ii).portBaseExpDiffPercent,'o');hold on
    end
    for ii = 1:numel(UNP_CS_shk)
        plot(2,UNP_CS_shk(ii).portBaseExpDiffPercent,'d')
    end
    % plot the bars
    x= 1:2; % 2 bars
    meanDiffScore = [P_CS_shk.portBaseExpDiffPercentMEAN UNP_CS_shk.portBaseExpDiffPercentMEAN];
    bb = bar(x,meanDiffScore);
    bb.FaceColor = 'none';
    hold on;
    % plot the error
    Y_err = [P_CS_shk.portBaseExpDiffPercentMEAN UNP_CS_shk.portBaseExpDiffPercentMEAN];
    SEM_err = [P_CS_shk.portBaseExpDiffPercentSEM,UNP_CS_shk.portBaseExpDiffPercentSEM];
    er = errorbar(x,Y_err,SEM_err);
    er.Color = [0 0 0];
    er.LineStyle = 'none';
    ylabel('Percent');
    title({'CS-Shock Defensive','Difference Score (Cue-BL)',sprintf('Student T-test p=%1.4f',p_shk)})
    set(gca,'Xtick',x)
    set(gca,'xticklabel',{'PR','UNP'})
    % ylim([-1 1]);
    
    % add the legend
    leg = legend('Location','bestoutside','Interpreter','none','Position',[ 0.5206    0.3487    0.4557    0.3311]);
    leg.String = [P_CS_shk.ID';UNP_CS_shk.ID'];
    
    figname = fullfile(c.dataDir,  'Compare_Pair_Unpair_defensives_CS-shock.png');
    saveFigEpsPng(figname, fh_shock)
    
    
    
    
    %%     % look at within trial comparison of reward and shock
    
    % 1. make the figure of shock vs reward for paired group
    fh_shock_rew = figure('Position',[1039,86,700,900],'Name','Paired defensive','Visible','on');
    xrange = P_CS_rew.portMatrixMEAN;
    ymax = .75;
    
    subplot(2,2,1)
    fm_pn_errorbar(1:size(xrange,2),P_CS_shk.portMatrixMEAN,P_CS_shk.portMatrixSEM,[0.8 0.1 0.1]);
    hold on;
    fm_pn_errorbar(1:size(xrange,2),P_CS_rew.portMatrixMEAN,P_CS_rew.portMatrixSEM,[0.1 0.1 0.8]);
    set(gca, 'XTick', []);
    title('Trial-averaged defensive for PAIRED subjects')
    ylabel('% animals defensive behavior')
    ylim([0 ymax])
    if 1
        % plot baseline window
        nTrials = size(P_CS_rew.portMatrix,1);
        xTemp1 = ((c.dispWin(1)*-1+c.baseWin(1))*c.fps);
        xTemp1 = xTemp1+1; % wiggle for visibility
        x = [xTemp1 xTemp1]; y = [0 nTrials+0.5]; line(x,y,'Color','red','LineStyle','--');
        xTemp2 = ((c.dispWin(1)*-1+c.baseWin(2))*c.fps);
        xTemp2 = xTemp2*0.99; % wiggle for visibility
        x = [xTemp2 xTemp2]; y = [0 nTrials+0.5]; line(x,y,'Color','red','LineStyle','--');
        line([xTemp1 xTemp2],[ymax ymax],'Color','red','LineWidth',2);
        
        % plot experimental window
        nTrials = size(P_CS_rew.portMatrix,1);
        xTemp1 = ((c.dispWin(1)*-1+c.expWin(1))*c.fps);
        xTemp1 = xTemp1+1; % wiggle for visibility
        x = [xTemp1 xTemp1]; y = [0 nTrials+0.5]; line(x,y,'Color','green','LineStyle','--');
        xTemp2 = ((c.dispWin(1)*-1+c.expWin(2))*c.fps);
        xTemp2 = xTemp2*0.99; % wiggle for visibility
        x = [xTemp2 xTemp2]; y = [0 nTrials+0.5]; line(x,y,'Color','green','LineStyle','--');
        line([xTemp1 xTemp2],[ymax ymax],'Color','green','LineWidth',2);
        
    end
    leg_text={'Paired shock error','Paired shock mean','Paired reward error','Paired reward mean'};
    leg = legend(leg_text,'Position',[0.5445 0.7898 0.2200 0.0728]);
    
    %     cue_shk_P = P_CS_shk.portMatrixMEAN(xTemp1:xTemp2);
    %     cue_rew_P = P_CS_rew.portMatrixMEAN(xTemp1:xTemp2);
    
    
    % figure;    plot(cue_shk_P,'Color',[0.8 0.1 0.1]);hold on; plot(cue_rew_P,'Color',[0.1 0.1 0.8])
    
    % 2. gather all individual dots and make the bar plot for rew vs shk
    [h,p_shk_rew,ci,stats_p_shk_rew] = ttest(P_CS_shk.portBaseExpDiffPercent', P_CS_rew.portBaseExpDiffPercent');
    disp([h, p_shk_rew])
    subplot(2,2,3);
    % plot the dots
    plot(1,P_CS_rew(ii).portBaseExpDiffPercent,'o'); hold on    ;
    plot(2,P_CS_shk(ii).portBaseExpDiffPercent,'d');
    %
    for jj = 1:numel(P_CS_rew(ii).portBaseExpDiffPercent)
        plot([1 2],  [P_CS_rew(ii).portBaseExpDiffPercent(jj) P_CS_shk(ii).portBaseExpDiffPercent(jj)],'Color',[.7 .7 .7])
    end
    
    % plot the bars
    x = 1:2; % 2 bars
    meanDiffScore = [P_CS_rew.portBaseExpDiffPercentMEAN P_CS_shk.portBaseExpDiffPercentMEAN];
    bb = bar(x,meanDiffScore);
    bb.FaceColor = 'none';
    hold on;
    % plot the error
    Y_err   = [P_CS_rew.portBaseExpDiffPercentMEAN P_CS_shk.portBaseExpDiffPercentMEAN];
    SEM_err = [P_CS_rew.portBaseExpDiffPercentSEM,P_CS_shk.portBaseExpDiffPercentSEM];
    er = errorbar(x,Y_err,SEM_err);
    er.Color = [0 0 0];
    er.LineStyle = 'none';
    ylabel('Percent');
    title({'CS-Rew vs CS-Shk Defensive (PAIRED) ','Difference Score (cue-bl)',...
        sprintf('Student T-test p=%1.4f, tstat=%1.3f, df=%d',p_shk_rew,stats_p_shk_rew.tstat, stats_p_shk_rew.df)})
    set(gca,'Xtick',x)
    set(gca,'xticklabel',{'CS-Rew','CS-Shock'})
    % ylim([-1 1]);
    
    % add the legend
    leg = legend('Location','best','Interpreter','none','Position',[0.5002    0.2600    0.4229    0.1417]);
    leg.String = [P_CS_rew.ID';P_CS_shk.ID'];
    % 3. use a t-test or non-param version
    % 4. RM anova?
    
    figname = fullfile(c.dataDir,  'Compare_cs-rew_cs-shk_defensive_paired.png');
    saveFigEpsPng(figname, fh_shock_rew)
    
    
    
    % 1. make the figure of shock vs reward for unpaired group
    fh_shock_rew_UNP = figure('Position',[1039,86,700,900],'Name','Unpaired defensive','Visible','on');
    xrange = UNP_CS_rew.portMatrixMEAN;
    ymax = .75;
    
    subplot(2,2,1)
    fm_pn_errorbar(1:size(xrange,2),UNP_CS_shk.portMatrixMEAN, UNP_CS_shk.portMatrixSEM,[0.8 0.1 0.1]);
    hold on;
    fm_pn_errorbar(1:size(xrange,2), UNP_CS_rew.portMatrixMEAN, UNP_CS_rew.portMatrixSEM,[0.1 0.1 0.8]);
    set(gca, 'XTick', []);
    title('Trial-averaged defensive for UNPAIRED subjects')
    ylabel('% animals defensive behavior')
    ylim([0 ymax])
    if 1
        % plot baseline window
        nTrials = size(UNP_CS_rew.portMatrix,1);
        xTemp1 = ((c.dispWin(1)*-1+c.baseWin(1))*c.fps);
        xTemp1 = xTemp1+1; % wiggle for visibility
        x = [xTemp1 xTemp1]; y = [0 nTrials+0.5]; line(x,y,'Color','red','LineStyle','--');
        xTemp2 = ((c.dispWin(1)*-1+c.baseWin(2))*c.fps);
        xTemp2 = xTemp2*0.99; % wiggle for visibility
        x = [xTemp2 xTemp2]; y = [0 nTrials+0.5]; line(x,y,'Color','red','LineStyle','--');
        line([xTemp1 xTemp2],[ymax ymax],'Color','red','LineWidth',2);
        
        % plot experimental window
        nTrials = size(UNP_CS_rew.portMatrix,1);
        xTemp1 = ((c.dispWin(1)*-1+c.expWin(1))*c.fps);
        xTemp1 = xTemp1+1; % wiggle for visibility
        x = [xTemp1 xTemp1]; y = [0 nTrials+0.5]; line(x,y,'Color','green','LineStyle','--');
        xTemp2 = ((c.dispWin(1)*-1+c.expWin(2))*c.fps);
        xTemp2 = xTemp2*0.99; % wiggle for visibility
        x = [xTemp2 xTemp2]; y = [0 nTrials+0.5]; line(x,y,'Color','green','LineStyle','--');
        line([xTemp1 xTemp2],[ymax ymax],'Color','green','LineWidth',2);
        
    end
    leg_text={'Unpaired shock error','Unpaired shock mean','Unpaired reward error','Unpaired reward mean'};
    leg = legend(leg_text,'Position',[0.5445    0.7898    0.2200    0.0728]);
    
    % 2. gather all individual dots and make the bar plot for rew vs shk
    [h,unp_shk_rew,ci, stat_unp_shk_rew] = ttest(UNP_CS_shk.portBaseExpDiffPercent', UNP_CS_rew.portBaseExpDiffPercent');
    disp([h, unp_shk_rew])
    subplot(2,2,3);
    % plot the dots
    for ii =1:numel(UNP_CS_rew)
        plot(1,UNP_CS_rew(ii).portBaseExpDiffPercent,'o');hold on
    end
    for ii = 1:numel(UNP_CS_shk)
        plot(2,UNP_CS_shk(ii).portBaseExpDiffPercent,'d')
    end
    
    for jj = 1:numel(UNP_CS_rew(ii).portBaseExpDiffPercent)
        plot([1 2],  [UNP_CS_rew(ii).portBaseExpDiffPercent(jj) UNP_CS_shk(ii).portBaseExpDiffPercent(jj)],'Color',[.7 .7 .7])
    end
    % plot the bars
    x = 1:2; % 2 bars
    meanDiffScore = [UNP_CS_rew.portBaseExpDiffPercentMEAN UNP_CS_shk.portBaseExpDiffPercentMEAN];
    bb = bar(x,meanDiffScore);
    bb.FaceColor = 'none';
    hold on;
    % plot the error
    Y_err = [UNP_CS_rew.portBaseExpDiffPercentMEAN UNP_CS_shk.portBaseExpDiffPercentMEAN];
    SEM_err = [UNP_CS_rew.portBaseExpDiffPercentSEM,UNP_CS_shk.portBaseExpDiffPercentSEM];
    er = errorbar(x,Y_err,SEM_err);
    er.Color = [0 0 0];
    er.LineStyle = 'none';
    ylabel('Percent');
    title({'CS-Rew vs CS-Shk Freeze (UNPAIRED)','Difference Score (cue-bl)',...
        sprintf('Student T-test p=%1.4f, tstat=%1.3f, df=%d',unp_shk_rew, stat_unp_shk_rew.tstat, stat_unp_shk_rew.df)})
    set(gca,'Xtick',x)
    set(gca,'xticklabel',{'CS-Rew','CS-Shock'})
    % ylim([-1 1]);
    
    % add the legend
    leg = legend('Location','best','Interpreter','none','Position',[0.5002    0.2600    0.4229    0.1417]);
    leg.String = [UNP_CS_rew.ID';UNP_CS_shk.ID'];
    
    figname = fullfile(c.dataDir,  'Compare_cs-rew_cs-shk_defensive_UNP.png');
    saveFigEpsPng(figname, fh_shock_rew_UNP)
    
    disp('Done Defensive.')
    % 3. use a t-test or non-param version
    % 4. RM anova?
    
    
    
    
end



disp('All done!')



end

function [output] = analyzeGroupBehavior(portMatrix,output)
%

% check that port matrix is a stack of individual mats
if numel(size(portMatrix)) ~= 3, error('input variable is not a stack of port matrices'); end

% take average across individuals to get the group portMatrix data
output.portMatrix = mean(portMatrix,3);

% take average of portMatrix data across trials, assumed to be first dimension
output.portMatrixMEAN = mean(output.portMatrix,1,'omitnan');
output.portMatrixSEM = fm_semCols(output.portMatrix);


output.portBaseExpDiffPercentMEAN = mean(output.portBaseExpDiffPercent,2,'omitnan');
output.portBaseExpDiffPercentSEM = fm_semCols(output.portBaseExpDiffPercent');


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


% colormap(c.colormap)
colormap(gray(4))
imagesc(data.portMatrix, [0 1]); set(gca, 'XTick', []);
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

if 0
    % Adding latency data
    for rowNum = 1:nTrials %#ok<UNRCH>
        y = [rowNum-0.5 rowNum+0.5];
        x = (c.dispWin(1)*-1+c.baseWin(2))*c.fps+data.latencyInportZero(rowNum)*c.fps;
        x = [x x];
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
end


function [] = plotPortGraphs(data) %#ok<DEFNU>
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
ylim([-1 1]);
%text(0,-0.8,['""Success"" trials = ' num2str(data.successMEAN)]);
%title(['"Success" trials = ' num2str(data.successMEAN)]);


end
