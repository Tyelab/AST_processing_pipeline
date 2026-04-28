function calc = remove_port_entry_freezes(c, folderName, calc)
% remove_port_entry_freezes  Zero out freeze labels that overlap port entry.
%
% Loads the session's LED events and masks any freeze frames that coincide
% with an active port-entry LED (i.e. the animal is collecting a reward,
% not freezing from fear). The modified calc struct is returned.
%
% SYNTAX:
%   calc = remove_port_entry_freezes(c, folderName, calc)
%
% INPUTS:
%   c          - Settings structure (see track_freeze_dash_vid_generator).
%                Required fields:
%                  c.dataDir                          - root data directory
%                  c.freezeSettings.LEDPortEntryNumber- LED channel index for
%                                                       port entry (loaded from
%                                                       per-session settings if
%                                                       not already set)
%   folderName - Folder/file name to process (string or char).
%   calc       - Calc struct from fmat_poseAnalyze. Must contain:
%                  calc.smoothed.cm.freezing.logiModFG - frame-wise freeze logical
%                  calc.smoothed.stickerPoint           - used to determine nFrames
%
% OUTPUTS:
%   calc       - Same struct with port-entry freeze frames zeroed out in
%                  calc.smoothed.cm.freezing.logiModFG
%
% NOTES:
%   - Logs the number of removed freeze frames via fprintf (not warning),
%     since removal is expected behaviour when this function is called.
%   - LED offset frames are clamped to nFrames to guard against events that
%     extend beyond the tracked data.
%
% See also: run_calcGen, fmat_poseAnalyze

% =========================================================================
% --- Load per-session LED port entry number ------------------------------
% =========================================================================
settingsPath = fullfile(c.dataDir, folderName, [folderName '_settings.mat']);
assert(exist(settingsPath, 'file') == 2, ...
    'remove_port_entry_freezes: Settings file not found:\n  %s', settingsPath);

loaded = load(settingsPath, 'LEDPortEntryNumber');
c.freezeSettings.LEDPortEntryNumber = loaded.LEDPortEntryNumber;

% =========================================================================
% --- Load LED events ---
% =========================================================================
ledPath = fullfile(c.dataDir, folderName, [folderName '_LEDevents.mat']);
assert(exist(ledPath, 'file') == 2, ...
    'remove_port_entry_freezes: LED events file not found:\n  %s', ledPath);

loaded    = load(ledPath, 'LEDevents');
LEDevents = loaded.LEDevents;

ledChannel = c.freezeSettings.LEDPortEntryNumber;
LED_onset  = LEDevents.evCellLED{ledChannel, 1};
LED_offset = LEDevents.evCellLED{ledChannel, 2};

assert(numel(LED_onset) == numel(LED_offset), ...
    'remove_port_entry_freezes: Mismatched onset/offset counts for LED channel %d.', ...
    ledChannel);

% =========================================================================
% --- Build frame-wise port entry logical array ---
% =========================================================================
nFrames        = size(calc.smoothed.stickerPoint, 1);
portEntry_logi = false(nFrames, 1);

for k = 1:numel(LED_onset)
    onsetFrame  = LED_onset(k);
    offsetFrame = min(LED_offset(k), nFrames); % guard against out-of-bounds
    if onsetFrame <= nFrames
        portEntry_logi(onsetFrame:offsetFrame) = true;
    end
end

% =========================================================================
% --- Remove freeze labels during port entry ---
% =========================================================================
nRemoved = sum(portEntry_logi & calc.smoothed.cm.freezing.logiModFG);
fprintf('remove_port_entry_freezes: Removed %d freeze frames during port entry for %s\n', ...
    nRemoved, folderName);
calc.smoothed.cm.freezing.logiModFG(portEntry_logi) = false;
end