
function run_calcGen(c, folderName)
% run_calcGen  Compute freeze/dash metrics and save calc .mat for one folder.
%
% Loads smoothed pose data and arena geometry, runs pose analysis via
% fmat_poseAnalyze, optionally removes freezes that overlap with port
% entry events, and saves the result as a calc .mat file.
%
% Skips processing if the calc file already exists.
%
% SYNTAX:
%   run_calcGen(c, folderName)
%
% INPUTS:
%   c          - Settings structure (see track_freeze_dash_vid_generator).
%                Required fields:
%                  c.outputDir                    - root output directory
%                  c.saveArenaNameSuffix           - suffix for Arena .mat file
%                  c.saveMouseDataNameSuffix       - suffix for mouseData .mat file
%                  c.saveCalcNameSuffix            - suffix for calc .mat file
%                  c.freezeSettings.REMOVE_FREEZES_IN_PORT
%                                                 - logical; if true, removes
%                                                   freezes during port entry
%   folderName - Folder/file name to process (string or char).
%
% OUTPUTS:
%   calc .mat file saved to:
%     <c.outputDir>/<folderName>/<folderName><c.saveCalcNameSuffix>
%
%   Saved variables:
%     calc      - struct with smoothed pose metrics (freeze, dash, distances)
%     mouseData - pose data (re-saved for convenience)
%     oldc      - copy of settings struct c used for this run
%
% NOTES:
%   - Requires Arena and mouseData .mat files to exist. Run run_arenaLabel
%     and the data preprocessing step first.
%   - oldc is saved alongside calc so the settings that produced the result
%     are always recoverable from the output file.
%
% See also: run_arenaLabel, fmat_poseAnalyze, remove_port_entry_freezes,
%           check_settings_matfile

% =========================================================================
% --- Skip if already done ------------------------------------------------
% =========================================================================

folderPath   = fullfile(c.outputDir, folderName);
calcFilePath = fullfile(folderPath, [folderName c.saveCalcNameSuffix]);

if exist(calcFilePath, 'file')
    disp(['run_calcGen: Calc file already exists for ' folderName ', skipped.'])
    return;
end

% --- Override settings if per-folder settings file exists ---
c = check_settings_matfile(c, folderPath, folderName);

% =========================================================================
% --- Load required files -------------------------------------------------
% =========================================================================
arenaPath     = fullfile(folderPath, [folderName c.saveArenaNameSuffix]);
mouseDataPath = fullfile(folderPath, [folderName c.saveMouseDataNameSuffix]);

assert(exist(arenaPath, 'file') == 2, ...
    'run_calcGen: Arena file not found:\n  %s\nRun run_arenaLabel first.', arenaPath);
assert(exist(mouseDataPath, 'file') == 2, ...
    'run_calcGen: mouseData file not found:\n  %s\nRun dataGen first.', mouseDataPath);

load(arenaPath,     'Arena');
load(mouseDataPath, 'mouseData');

fprintf('run_calcGen: Calculating pose metrics for %s ...\n', folderName);

% =========================================================================
% --- Run pose analysis ---
% =========================================================================
calc.smoothed = fmat_poseAnalyze(c, mouseData, Arena);

% =========================================================================
% --- Optionally remove freezes that occur during port entry ---
% =========================================================================
if c.freezeSettings.REMOVE_FREEZES_IN_PORT
    calc = remove_port_entry_freezes(c, folderName, calc);
end

% =========================================================================
% --- Save ---
% =========================================================================
oldc = c;
save(calcFilePath, 'oldc', 'mouseData', 'calc');
fprintf('run_calcGen: Calc saved for %s\n', folderName);
end
