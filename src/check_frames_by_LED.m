
%function CheckFramesByLed
% v = a video opened with videoreader
% frame = a frame in that video

%%
clear all; close all;

maindir = '\\nadata.snl.salk.edu\snlkt_ast\Miniscope\expAnalysis\20220902_oldEphysVids\lk_processed_oldEphysVids_v2';
% Disc7folder = '3014illidan_20180926_DiscD4'; %-- DONE
% Disc7folder = '3016donkey_20180810_DiscD4' ; %-- DONE
    %Disc7folder = '3024ishmael_20180810_Disc4' ;% %-- DONE
    Disc7folder = '3026deng_20181128_DiscD2'   ; %--DONE
%     Disc7folder = '3029iouxio_20181128_DiscD2' ; %-- DONE
%      Disc7folder = '6197daijobu_20190718DiscD4' ; --DONE
%     Disc7folder = '6253daisy_20190913DISCD3'   ; %-- DONE
%     Disc7folder = '6429durian_20191016DISCD5'  ; %-- DONE
%     Disc7folder = '7008ikari_20190718DiscD4'   ; %-- DONE
%     Disc7folder = '7049ivy_20190914DISCD4'     ;%-- DONE
    
d = dir(fullfile(maindir,Disc7folder,[Disc7folder,'_LEDevents.mat']))

load(fullfile(d.folder,d.name))

videopath = dir(fullfile(maindir,Disc7folder,[Disc7folder,'*.mp4']))
v = VideoReader(fullfile(videopath.folder,videopath.name));


if 0
    % if you need to add frames in:
    N = numel(LEDevents.evCellLED{1,1})
    index_to_add = 2
    frame_number = 2259
    tmp = [LEDevents.evCellLED{1,1}(1:index_to_add-1);...
        frame_number;...
        LEDevents.evCellLED{1,1}(index_to_add:N);...
        ]
    LEDevents.evCellLED{1,1} = tmp
end


if 0
    %     to validate detections for LED3 -- shock tone
    figure; plot(LEDevents.rawLEDs(:,3));
    hold on;
    plot(LEDevents.evCellLED{3,1},LEDevents.rawLEDs(LEDevents.evCellLED{3,1},3),'go','MarkerFaceColor','g')
    plot(LEDevents.evCellLED{3,2},LEDevents.rawLEDs(LEDevents.evCellLED{3,2},3),'ro','MarkerFaceColor','r')
    % plot(LEDevents.evCellLED{4,1},LEDevents.threshLEDs(LEDevents.evCellLED{4,1},3),'ko')
    legend('LED-3','LED-3 onset (Shock)', 'LED-3 offset (Shock)')%, 'LED-4 onset (Miniscope)')
    title(Disc7folder,'Interpreter','none')
    
    [LEDevents.evCellLED{3,1} LEDevents.evCellLED{3,2} LEDevents.evCellLED{3,2}-LEDevents.evCellLED{3,1}]
    %     LEDevents.evCellLED{3,1}((LEDevents.evCellLED{3,2}-LEDevents.evCellLED{3,1})<200) = 0
    LEDevents.evCellLED{3,1}(diff(LEDevents.evCellLED{3,1})<200) = 0
%     
%     LED3 = find(LEDevents.rawLEDs(:,3)>6000);
%     LED3_diff = diff(LED3);
%     LED3 = LED3(LED3_diff>1);
%     LEDevents.evCellLED{3,1} = LED3;

    
    %     to validate detections for LED1 -- rew tone
    figure; plot(LEDevents.rawLEDs(:,1));
    hold on;
    plot(LEDevents.evCellLED{1,1},LEDevents.rawLEDs(LEDevents.evCellLED{1,1},1),'go','MarkerFaceColor','g')
    plot(LEDevents.evCellLED{1,2},LEDevents.rawLEDs(LEDevents.evCellLED{1,2},1),'ro','MarkerFaceColor','r')
    plot(LEDevents.evCellLED{2,1},LEDevents.rawLEDs(LEDevents.evCellLED{2,1},1),'ko')
    legend('LED-1','LED-1 onset (Rew)','LED-1 offset (Rew)', 'LED-2 onset (Port)')
    title(Disc7folder,'Interpreter','none')
    
    % check out the difference between start times
    [LEDevents.evCellLED{1,1} LEDevents.evCellLED{1,2} LEDevents.evCellLED{1,2}-LEDevents.evCellLED{1,1}]
    disp(['number of LED1> 600 = ',   num2str( sum(diff(LEDevents.evCellLED{1,1})>600))])
    
    % set values less than some threshold to 0 and remove from the start
    % times
    LEDevents.evCellLED{1,1}(diff(LEDevents.evCellLED{1,1})<600) = 0
    tmp = LEDevents.evCellLED{1,2}(find(LEDevents.evCellLED{1,1} ~= 0))
    LEDevents.evCellLED{1,2}=tmp
    
    % find peaks:
    raw =  LEDevents.rawLEDs(:,1);
    raw(raw<1000)=0;
    LED1 = raw;%LEDevents.rawLEDs(:,1);
    LED1_diff = diff(LED1);
    tmp_on  = find(LED1_diff>1000);
    tmp_off = find(LED1_diff<-1000);
     tmp_on  = tmp_on(diff(tmp_on)>3)
     tmp_off = tmp_off(diff(tmp_off)>3)

     % remove too low detections
     tmp_off =  tmp_off(LEDevents.rawLEDs(tmp_off,1)>20000) 
     tmp_on =  tmp_on(LEDevents.rawLEDs(tmp_on,1)>20000) 
     
    LEDevents.evCellLED{1,1} = tmp_on;
    LEDevents.evCellLED{1,2} = tmp_off;
    
    
    
    
    %%
    
    for jj = 8560:8600
        frame = jj;
        v.CurrentTime = frame/v.FrameRate;
        vidFrame = readFrame(v);
        image(vidFrame);
        title(sprintf('Frame %d ',jj))
        pause;
    end
    
    
end


%%

% figure; plot(LEDevents.rawLEDs(:,1));
% hold on; 
% plot( LEDevents.evCellLED{1,1},LEDevents.rawLEDs(LEDevents.evCellLED{1,1}),'go')
% plot( LEDevents.evCellLED{1,2},LEDevents.rawLEDs(LEDevents.evCellLED{1,2}),'ro')

LED_ON = LEDevents.evCellLED{1}
if numel(LED_ON) ~= 90
     
    disp('More or less than 90 events -- Running check at LED 1')
    
    preFrames = 10;% this backs up video enough to see when LED first lights
    stopFrames = v.FrameRate;
    for ii = 23:numel(LED_ON)
        % set the starting frame
        frame = LED_ON(ii)
        % set the video to the frame you want, specify in seconds:
        if frame-preFrames>0
            v.CurrentTime = (frame-preFrames)/v.FrameRate;
        end
        for jj = 1:preFrames + v.FrameRate*2
            vidFrame = readFrame(v);
            image(vidFrame);
            %currAxes.Visible = 'off';
            title(sprintf('Frame %d, current %d, (loop counter:%d)',frame, frame-preFrames + jj-1, ii))
            pause(1/(5*v.FrameRate));
        end
        pause();
        
    end
    if 0
        
        tmp = LEDevents.evCellLED{1,1}(find(LEDevents.evCellLED{1,1} ~= 0))
        LEDevents.evCellLED{1,1}=tmp
        
        tmp = LEDevents.evCellLED{1,2}(find(LEDevents.evCellLED{1,1} ~= 0))
        LEDevents.evCellLED{1,2}=tmp
        
    end
end

%%
LED_ON = LEDevents.evCellLED{3}
if numel(LED_ON) ~= 30
    disp('More of less than 30 events -- Running check at LED 3')
    
    preFrames = 10;% this backs up video enough to see when LED first lights
    stopFrames = v.FrameRate;
    for ii = 10:numel(LED_ON)
        % set the starting frame
        frame = LED_ON(ii)
        % set the video to the frame you want, specify in seconds:
        v.CurrentTime = (frame-preFrames)/v.FrameRate;
        for jj = 1:preFrames+ 30%(20*v.FrameRate)
            vidFrame = readFrame(v);
            image(vidFrame);
            %currAxes.Visible = 'off';
            title(sprintf('Frame %d, current %d',frame, frame-preFrames + ii-1))
            pause(1/(5*v.FrameRate));
        end
        pause();
        
    end
    
    if 0
        tmp = LEDevents.evCellLED{3,1}(find(LEDevents.evCellLED{3,1} ~= 0))
        LEDevents.evCellLED{3,1}=tmp
        
        tmp = LEDevents.evCellLED{3,2}(find(LEDevents.evCellLED{3,1} ~= 0))
        LEDevents.evCellLED{3,2}=tmp
    end
     
end
%%
LED_ON = LEDevents.evCellLED{4}
if numel(LED_ON) ~= 30
    disp('More of less than 30 events -- Running check at LED 4')
    
    preFrames = 10;% this backs up video enough to see when LED first lights
    stopFrames = v.FrameRate;
    for ii = 1:numel(LED_ON)
        % set the starting frame
        frame = LED_ON(ii)
        % set the video to the frame you want, specify in seconds:
        v.CurrentTime = (frame-preFrames)/v.FrameRate;
        for ii = 1: preFrames + 20*v.FrameRate
            vidFrame = readFrame(v);
            image(vidFrame);
            %currAxes.Visible = 'off';
            title(sprintf('Frame %d, current %d',frame, frame-preFrames + ii-1))
            pause(1/(5*v.FrameRate));
        end
        pause();
        
    end
    
    if 0
        tmp = LEDevents.evCellLED{4,1}(find(LEDevents.evCellLED{4,1} ~= 0))
        LEDevents.evCellLED{4,1}=tmp

        tmp = LEDevents.evCellLED{4,2}(find(LEDevents.evCellLED{4,2} ~= 0))
        LEDevents.evCellLED{4,2}=tmp
end
end
%%

save(fullfile(maindir,Disc7folder,[Disc7folder,'_LEDevents.mat']), 'LEDevents')
%end