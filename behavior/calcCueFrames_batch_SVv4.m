%% calcCueFrames_batch_SVv4.m - convert rig cue times to video frame numbers
%
% Pick a dataset root; every session folder below it is listed. For each
% ticked session, the rig .mat's cue timestamps (ts.csp_*, ts.csm_*,
% ts.us_*, ts.laser_*) are converted to video frames,
%   frame = (cue time - ts.camera_on) x video frame rate,
% and written as N x 2 [onset offset] tables with no header:
%   <session folder>_csp_cue_frames.csv   (+ _csm_, _us_, _laser_ if present)
% The same frames are appended to the .mat as cueframes (plus NumFrames).
%
% Needs exactly one .mat and one video (.avi, else .mp4) per session folder.
% Run after organizing folders, before BehaviorDEPOT (which imports the
% csp file as the "CSp" event).

% Params
doCSV = 1;  % 0 or 1, save to csv
% fps = 49.965; % load fps, leave blank to autoload

% SV / Claude, August 28, 2026: I added - v3 differs from SVv2 in one way only:
% cue windows that fall outside the video are DROPPED instead of being written
% into the csv as real frame numbers. See dropOutOfRangeCues() at the bottom for
% the full rationale. Motivating case: PVFP_29_tms_HabD3_SV_Aug24, where the
% camera stopped ~554 s before the behavior program did, so CS+ tone 9 landed at
% frame 85733 in a 63542-frame video. Dropping it makes that session a "fewer
% tones than usual" session, which every downstream stage already handles - and
% pma_extractor's pad_to_len() fills the missing tone with NaN rather than 0.
%
% SV / Claude, September 1, 2026: I added - v4 differs from v3 in one way
% only: the single uigetdir() below is replaced with the same two-window
% flow preprocess_pma_videos_SVv3.m uses (a settings window to pick the
% folder, then a checklist of every session found in it), so you can see
% what was found and tick/untick before anything runs, instead of it
% silently reprocessing - and overwriting - every session under the chosen
% root every time. Sessions that already have a *_cue_frames.csv start
% unticked; tick one to redo it. Nothing below "Batch Setup" changed - same
% dropOutOfRangeCues, same per-session loop, same everything.
%

%% Batch Setup
% Collect 'video_folder_list' from 'P.video_directory'
% SV, September 1, 2026: I changed
% disp('Select directory containing other directories for analysis'); % point to folder for analysis
% P.video_directory = uigetdir('','Select the directory containing folders for analysis'); %Directory with list of folders containing videos + tracking to analyze
% P.video_folder_list = prepBatch(string(P.video_directory)); %Generate list of videos to analyze
% to this:
P.script_dir = pwd; % directory with script files (avoids requiring changes to path)

settingsDefaults.startingFolder = '';
[settingsCfg, settingsOk] = folderSettingsDialog(settingsDefaults);
if ~settingsOk
    disp('calcCueFrames: cancelled at settings window - nothing run.');
    return
end
P.video_directory = settingsCfg.folder;

allFolders = cellstr(prepBatch(string(P.video_directory)));
alreadyDone = cellfun(@folderHasCueOutput, allFolders);
defaultPick = ~alreadyDone;   % already-done folders start unticked - tick to redo

[chosenMask, checklistOk] = selectFoldersDialog(allFolders, alreadyDone, defaultPick, P.video_directory);
if ~checklistOk
    disp('calcCueFrames: cancelled at the session checklist - nothing run.');
    return
end
P.video_folder_list = allFolders(chosenMask);
if isempty(P.video_folder_list)
    disp('calcCueFrames: no folders ticked - nothing run.');
    return
end
%

for j = 1:length(P.video_folder_list)
    % Initialize
    video_folder = P.video_folder_list{j};
    cd(video_folder) % Folder with data files

    %%
    clearvars -except P doCSV j video_folder

    % SV / Claude, September 1, 2026: I added - every output csv this script
    % writes gets the session folder's own name as a prefix (e.g.
    % PVFP_30_HabD1_SV_Aug20_csp_cue_frames.csv), so a file is identifiable on
    % its own once copied/emailed/opened elsewhere, without needing its parent
    % folder for context. See folderHasCueOutput() at the bottom - it globs for
    % *_cue_frames.csv, so it doesn't care what the prefix actually is.
    [~, folderPrefix] = fileparts(video_folder);
    %

    % assume save to CSV unless indicated otherwise
    if ~exist('doCSV','var')
        doCSV = 1;
    end

    % load experiment data
    data = dir('*.mat');
    if isempty(data)
        disp(['SKIPPING (no .mat found): ' video_folder]);
        continue
    end
    load(fullfile(data(1).folder, data(1).name));

    % get name of vid file
    vid = dir('*.avi');
    if isempty(vid)
        vid = dir('*.mp4');
    end
    if isempty(vid)
        disp(['SKIPPING (no video found): ' video_folder]);
        continue
    end

    % SV / Claude, August 28, 2026: I added - vid(1) is taken blind by this
    % script, and a session folder holding both "..._preprocessed.mp4" and the
    % DLC preview "..._preprocessedDLC..._p1_labeled.mp4" has two matches. The
    % sort order happens to put the right one first, but that is luck rather
    % than a check, so say out loud which video is being used and warn when
    % there is more than one to choose from.
    if numel(vid) > 1
        warning('calcCueFrames: %d videos in %s - using "%s". Move the others into quality_control\\.', ...
            numel(vid), video_folder, vid(1).name);
    end
    %

    % load vid file and get frame rate if not inputted
    thisvid = VideoReader(fullfile(vid(1).folder, vid(1).name));
    % SV, August 27, 2026: I changed - fps was hardcoded to 49.965, but the
    % PVcre Aug-2026 videos are exactly 50.0 fps (ffprobe: r_frame_rate=50/1).
    % Over a ~70,000-frame session that 0.07% error accumulates to ~49 frames
    % (~1 s) of drift by session end, landing on the last tones - which is
    % where a habituation learning curve is most informative. Now read from
    % the video itself, falling back to the old constant only if unreadable.
    % fps = 49.965; % 59.97;
    %
    fps = thisvid.FrameRate;
    if isempty(fps) || ~isfinite(fps) || fps <= 0
        fps = 49.965;
        warning('calcCueFrames: could not read FrameRate from %s, falling back to %.3f fps', vid(1).name, fps);
    end
    NumFrames = thisvid.NumFrames;

    % SV / Claude, August 28, 2026: I added - camera dropout pre-flight check.
    % ts.camera_on -> ts.camera_off is how long the behavior program thought the
    % session ran; thisvid.Duration is how much video actually exists. They
    % normally agree to within ~1 s. A large positive gap means the recording
    % stopped early while the program kept delivering tones, which is exactly
    % the condition that puts cue windows past the end of the video below.
    if isfield(ts,'camera_off') && ~isempty(ts.camera_off) && ~isempty(ts.camera_on)
        rig_dur = seconds(datetime(ts.camera_off) - datetime(ts.camera_on));
        if abs(rig_dur - thisvid.Duration) > 30
            warning(['calcCueFrames: %s - behavior program ran %.1f s but the video is ' ...
                     '%.1f s (%.1f s short). Camera likely dropped out mid-session.'], ...
                     video_folder, rig_dur, thisvid.Duration, rig_dur - thisvid.Duration);
        end
    end
    %

    % % get start time from vid title if not inputted
    % if ~exist('dt','var')
    %     dt = regexp(vid.name,'....-..-..-......-....');
    %     dt = vid.name(dt:dt+16);
    % else
    %     dt = char(dt);
    % end
    %
    % % format start time
    % d1 = string(dt(1:4));
    % d2 = string(dt(6:7));
    % d3 = string(dt(9:10));
    % d4 = string(dt(12:13));
    % d5 = string(dt(14:15));
    % d6 = string(dt(16:17));
    % vid0 = [d1, d2, d3, d4, d5, d6];
    % if exist(ts.camera_on)
    vid0 = ts.camera_on;
    % end

    %% convert timestamps to video frames
    % four possible timestamps:  csp, csm, us, laser

    % do csp
    if ~isempty(ts.csp_on)
        csp_frames = zeros(size(ts.csp_on,1),2);
        for i = 1:size(ts.csp_on,1)
            csp_frames(i,1) = calcDifSeconds(vid0,ts.csp_on(i,:));
            csp_frames(i,2) = calcDifSeconds(vid0,ts.csp_off(i,:));
        end

        csp_frames = csp_frames * fps;
        csp_frames = round(csp_frames);
        % SV / Claude, August 28, 2026: I added - drop cues outside the video
        % BEFORE meandif is computed, so the mean tone duration is taken from
        % real tones only.
        [csp_frames, csp_dropped] = dropOutOfRangeCues(csp_frames, NumFrames, 'CS+', video_folder);
        cueframes.CSp_dropped = csp_dropped;
        %
        if isempty(csp_frames)
            warning('calcCueFrames: every CS+ cue in %s falls outside the video - no csp_cue_frames.csv written', video_folder);
        else
            meandif = round(mean(csp_frames(:,2) - csp_frames(:,1)));
            csp_frames = [csp_frames(:,1), csp_frames(:,1)+meandif];
            if doCSV
                % SV, September 1, 2026: I changed
                % writematrix(csp_frames, 'csp_cue_frames.csv');
                % to this:
                writematrix(csp_frames, [folderPrefix '_csp_cue_frames.csv']);
                %
            end
            disp('converted CS+ times to video frames and saved as csv');
            cueframes.CSp = csp_frames;
        end
    end

    % do csm
    if ~isempty(ts.csm_on)
        csm_frames = zeros(size(ts.csm_on,1),2);
        for i = 1:size(ts.csm_on,1)
            csm_frames(i,1) = calcDifSeconds(vid0,ts.csm_on(i,:));
            csm_frames(i,2) = calcDifSeconds(vid0,ts.csm_off(i,:));
        end

        csm_frames = csm_frames * fps;
        csm_frames = round(csm_frames);
        % SV / Claude, August 28, 2026: I added
        [csm_frames, csm_dropped] = dropOutOfRangeCues(csm_frames, NumFrames, 'CS-', video_folder);
        cueframes.CSm_dropped = csm_dropped;
        %
        if ~isempty(csm_frames)
            meandif = round(mean(csm_frames(:,2) - csm_frames(:,1)));
            csm_frames = [csm_frames(:,1), csm_frames(:,1)+meandif];
            if doCSV
                % SV, September 1, 2026: I changed
                % writematrix(csm_frames, 'csm_cue_frames.csv');
                % to this:
                writematrix(csm_frames, [folderPrefix '_csm_cue_frames.csv']);
                %
            end
            disp('converted CS- times to video frames and saved as csv');
            cueframes.CSm = csm_frames;
        end
    end

    % do us
    if ~isempty(ts.us_on)
        us_frames = zeros(size(ts.us_on,1),2);
        for i = 1:size(ts.us_on,1)
            us_frames(i,1) = calcDifSeconds(vid0,ts.us_on(i,:));
            us_frames(i,2) = calcDifSeconds(vid0,ts.us_off(i,:));
        end

        us_frames = us_frames * fps;
        us_frames = round(us_frames);
        % SV / Claude, August 28, 2026: I added
        [us_frames, us_dropped] = dropOutOfRangeCues(us_frames, NumFrames, 'US', video_folder);
        cueframes.US_dropped = us_dropped;
        %
        if ~isempty(us_frames)
            meandif = round(mean(us_frames(:,2) - us_frames(:,1)));
            us_frames = [us_frames(:,1), us_frames(:,1)+meandif];
            if doCSV
                % SV, September 1, 2026: I changed
                % writematrix(us_frames, 'us_cue_frames.csv');
                % to this:
                writematrix(us_frames, [folderPrefix '_us_cue_frames.csv']);
                %
            end
            disp('converted US times to video frames and saved as csv');
            cueframes.US = us_frames;
        end
    end

    % do laser
    if ~isempty(ts.laser_on)
        laser_frames = zeros(size(ts.laser_on,1),2);
        for i = 1:size(ts.laser_on,1)
            laser_frames(i,1) = calcDifSeconds(vid0,ts.laser_on(i,:));
            laser_frames(i,2) = calcDifSeconds(vid0,ts.laser_off(i,:));
        end

        laser_frames = laser_frames * fps;
        laser_frames = round(laser_frames);
        % SV / Claude, August 28, 2026: I added
        [laser_frames, laser_dropped] = dropOutOfRangeCues(laser_frames, NumFrames, 'laser', video_folder);
        cueframes.laser_dropped = laser_dropped;
        %
        if ~isempty(laser_frames)
            meandif = round(mean(laser_frames(:,2) - laser_frames(:,1)));
            laser_frames = [laser_frames(:,1), laser_frames(:,1)+meandif];
            if doCSV
                % SV, September 1, 2026: I changed
                % writematrix(laser_frames, 'laser_cue_frames.csv');
                % to this:
                writematrix(laser_frames, [folderPrefix '_laser_cue_frames.csv']);
                %
            end
            disp('converted laser times to video frames and saved as csv');
            cueframes.laser = laser_frames;
        end
    end

    save(fullfile(data(1).folder, data(1).name),'cueframes', '-append');
    save(fullfile(data(1).folder, data(1).name),'NumFrames', '-append');
    disp('appended cueframes into "cueframes" struct in .mat file');
    disp(['for ' pwd]);

end

function video_folder_list = prepBatch(video_directory)
    mat_files = dir(fullfile(video_directory, '**', '*.mat'));
    folder_paths = string({mat_files.folder});
    video_folder_list = unique(folder_paths, 'stable');

    for i = 1:length(video_folder_list)
        disp([num2str(i) ' directory loaded: ' char(video_folder_list(i))])
    end

    video_folder_list = cellstr(video_folder_list);
end

%% supporting fxn

function [kept, dropped] = dropOutOfRangeCues(frames, NumFrames, label, video_folder)
% SV / Claude, August 28, 2026: I added.
%
% Removes cue windows that do not fit inside the video, and returns how many
% were removed.
%
% WHY: when the camera stops before the behavior program does, the trailing
% cues get frame numbers past the end of the video. Nothing downstream catches
% this on its own:
%   - BehaviorDEPOT's genBehStruct.m does "Vector(start:stop) = 1" on a vector
%     preallocated to numFrames. MATLAB silently GROWS the array instead of
%     erroring, so Behavior.Temporal.CSp.Vector comes out longer than every
%     other behavior vector in the file.
%   - BehDEPOT_Analysis then computes "CSp_on .* on_plat.'" with two row
%     vectors of different lengths, which errors out mid-batch - or, where the
%     shapes happen to line up, reports 0 s on platform for a tone that simply
%     has no video, which is indistinguishable from a real 0.
% Neither outcome is what we want: the tone should read as MISSING, not as
% zero avoidance.
%
% HOW THE NaN ACTUALLY APPEARS: dropping the cue here makes the session a
% "fewer tones than usual" session, which the rest of the pipeline already
% handles. pma_extractor's pad_to_len() pads every per-tone metric out to
% max_tones with NaN, so the dropped tone lands in the workbook as an empty
% NaN cell rather than a 0. That path is already exercised by the DCSP
% sessions that ran 4 or 5 tones instead of 6.
%
% A window is dropped if it starts before frame 1 or ends after the last
% frame. Partly-covered tones are dropped rather than clamped on purpose: a
% tone truncated halfway through would produce a real-looking average computed
% over only part of the tone, which is the same false-data problem in a subtler
% form.

n = size(frames, 1);
in_range = frames(:,1) >= 1 & frames(:,2) <= NumFrames;
kept = frames(in_range, :);
bad = find(~in_range);
dropped = numel(bad);

if dropped == 0
    return
end

% Only a contiguous TRAILING block may be dropped. A camera dropout always
% loses the LAST tones, so that is the only pattern we can safely renumber. If
% a gap appears in the middle, silently removing it would shift every later
% tone down one index and misalign this animal's "tone 5" with everyone else's
% in the workbook - so stop and make it a human decision instead.
if ~isequal(bad(:)', (n-dropped+1):n)
    error(['calcCueFrames: %s cue(s) %s in %s fall outside the video, but they are not a ' ...
           'contiguous trailing block (video is %d frames). Dropping them would misalign ' ...
           'tone numbering against the other animals - inspect this session by hand.'], ...
           label, mat2str(bad(:)'), video_folder, NumFrames);
end

warning(['calcCueFrames: %s - dropped %d trailing %s cue(s) (%s of %d) that fall past the end ' ...
         'of the %d-frame video. They will read as NaN downstream, not 0.'], ...
         video_folder, dropped, label, mat2str(bad(:)'), n, NumFrames);
end

function dif = calcDifSeconds(start, fin)
% calcDifSeconds:  calculates difference in seconds between two vector date
% inputs.
% INPUT: t1 - start time; t2 - end time. Both input as [YYYY MM DD HH MM
% SS]. t2 can be vector or vector array
% OUTPUT: dif - difference between two timepoints in seconds
    start = double(start);
    fin = double(fin);
    d2s = 24*3600;    % convert from days to seconds
    d1 = datenum(start); % convert from datetime format to serial date time
    d1  = d2s*datenum(d1);  % convert to seconds

    dif = zeros(size(fin,1),1);
    for i = 1:size(fin,1)
        d2 = datenum(fin(i,:));
        d2  = d2s*datenum(d2);

        dif(i) = (d2-d1);
    end
end

% SV / Claude, September 1, 2026: I added - the three functions below (down
% to the end of the file). They give calcCueFrames the same two-window
% "pick a folder, then tick which sessions to run" flow that
% preprocess_pma_videos_SVv4.m uses, built the same way (plain uicontrol
% figures, not App Designer) so it needs nothing this script didn't already
% depend on.

% ========================================================================
% Settings window - pick the folder to search
% ========================================================================
function [cfg, ok] = folderSettingsDialog(defaults)
%FOLDERSETTINGSDIALOG Small settings window shown on Run.
%   Asks for the root folder to search (prepBatch below still does the
%   actual recursive search for session folders inside it). Returns a
%   struct with field .folder, and ok=false if the window was cancelled
%   (Quit, or the close box).

cfg = struct('folder', defaults.startingFolder);
ok = false;

W = 640; H = 190;
scr = get(0, 'ScreenSize');
f = figure( ...
    'Name', 'calcCueFrames - choose a folder', ...
    'NumberTitle', 'off', 'MenuBar', 'none', 'ToolBar', 'none', ...
    'Units', 'pixels', ...
    'Position', [scr(3)/2 - W/2, scr(4)/2 - H/2, W, H], ...
    'Color', [0.94 0.94 0.94], ...
    'WindowStyle', 'modal', ...
    'CloseRequestFcn', @onQuit);

uicontrol(f, 'Style', 'text', 'Units', 'pixels', ...
    'Position', [20 H-50 W-40 34], ...
    'String', ['Select the directory containing the session folders to search (it is searched ' ...
               'recursively, so this can be the dataset root).'], ...
    'HorizontalAlignment', 'left', 'FontSize', 9, ...
    'BackgroundColor', [0.94 0.94 0.94]);

hFolder = uicontrol(f, 'Style', 'edit', 'Units', 'pixels', ...
    'Position', [20 H-100 W-40-110 26], ...
    'String', defaults.startingFolder, 'HorizontalAlignment', 'left', ...
    'BackgroundColor', [1 1 1]);

uicontrol(f, 'Style', 'pushbutton', 'Units', 'pixels', ...
    'Position', [W-130 H-100 100 26], ...
    'String', 'Browse...', 'FontSize', 9, 'Callback', @onBrowse);

uicontrol(f, 'Style', 'pushbutton', ...
    'Units', 'pixels', 'Position', [W-330 20 140 38], ...
    'String', 'Quit', 'FontSize', 10, ...
    'Callback', @onQuit);

uicontrol(f, 'Style', 'pushbutton', ...
    'Units', 'pixels', 'Position', [W-170 20 150 38], ...
    'String', 'Next: choose sessions', 'FontSize', 10, 'FontWeight', 'bold', ...
    'Callback', @onNext);

uiwait(f);

    function onBrowse(~, ~)
        start = get(hFolder, 'String');
        if isempty(start) || ~isfolder(start)
            start = pwd;
        end
        picked = uigetdir(start, 'Select the directory containing folders for analysis');
        if ~isequal(picked, 0)
            set(hFolder, 'String', picked);
        end
    end

    function onNext(~, ~)
        folder = strtrim(get(hFolder, 'String'));
        if isempty(folder) || ~isfolder(folder)
            errordlg(sprintf('This is not a folder that exists:\n%s', folder), ...
                'calcCueFrames', 'modal');
            return;
        end
        cfg.folder = folder;
        ok = true;
        delete(f);
    end

    function onQuit(~, ~)
        ok = false;
        delete(f);
    end
end
%

% ========================================================================
% Checklist window - tick which sessions to run
% ========================================================================
function [chosen, ok] = selectFoldersDialog(allFolders, alreadyDone, defaultPick, root)
%SELECTFOLDERSDIALOG Tick which session folders to run calcCueFrames on.
%   Returns a logical mask over allFolders, and ok=false if cancelled.
%   Folders that already have a *_cue_frames.csv are listed but start
%   unticked; ticking one means "recompute and overwrite its cue frames".

chosen = defaultPick;
ok = false;

labels = cell(1, numel(allFolders));
for k = 1:numel(allFolders)
    if alreadyDone(k)
        status = '  [already has cue frames -- tick to redo]';
    else
        status = '';
    end
    labels{k} = sprintf('%s%s', allFolders{k}, status);
end

W = 820; H = 520;
scr = get(0, 'ScreenSize');
f = figure( ...
    'Name', 'calcCueFrames - choose sessions', ...
    'NumberTitle', 'off', 'MenuBar', 'none', 'ToolBar', 'none', ...
    'Units', 'pixels', ...
    'Position', [scr(3)/2 - W/2, scr(4)/2 - H/2, W, H], ...
    'Color', [0.94 0.94 0.94], ...
    'WindowStyle', 'modal', ...
    'CloseRequestFcn', @onCancel);

uicontrol(f, 'Style', 'text', ...
    'Units', 'pixels', 'Position', [20 H-70 W-40 50], ...
    'String', sprintf(['Found %d session folder(s) (each with a .mat file) under:\n%s\n' ...
                       'Ctrl-click / shift-click to change the selection.'], ...
                      numel(allFolders), root), ...
    'HorizontalAlignment', 'left', 'FontSize', 9, ...
    'BackgroundColor', [0.94 0.94 0.94]);

lb = uicontrol(f, 'Style', 'listbox', ...
    'Units', 'pixels', 'Position', [20 90 W-40 H-170], ...
    'String', labels, ...
    'FontName', 'Consolas', 'FontSize', 9, ...
    'Min', 0, 'Max', 2, ...                      % Max>1 => multi-select
    'Value', find(defaultPick), ...
    'BackgroundColor', [1 1 1]);

uicontrol(f, 'Style', 'pushbutton', ...
    'Units', 'pixels', 'Position', [20 25 110 34], ...
    'String', 'Select all', 'FontSize', 9, ...
    'Callback', @(~,~) set(lb, 'Value', 1:numel(labels)));

uicontrol(f, 'Style', 'pushbutton', ...
    'Units', 'pixels', 'Position', [140 25 110 34], ...
    'String', 'Select none', 'FontSize', 9, ...
    'Callback', @(~,~) set(lb, 'Value', []));

uicontrol(f, 'Style', 'pushbutton', ...
    'Units', 'pixels', 'Position', [W-330 25 140 38], ...
    'String', 'Cancel', 'FontSize', 10, ...
    'Callback', @onCancel);

uicontrol(f, 'Style', 'pushbutton', ...
    'Units', 'pixels', 'Position', [W-170 25 150 38], ...
    'String', 'Run', 'FontSize', 10, 'FontWeight', 'bold', ...
    'Callback', @onRun);

uiwait(f);

    function onRun(~, ~)
        sel = get(lb, 'Value');
        chosen = false(1, numel(allFolders));
        chosen(sel) = true;
        ok = true;
        delete(f);
    end

    function onCancel(~, ~)
        ok = false;
        delete(f);
    end
end
%

% ========================================================================
% Already-done detection
% ========================================================================
function tf = folderHasCueOutput(folder)
%FOLDERHASCUEOUTPUT True if this folder already has any cue-frames output
%   from a previous run - csp/csm/us/laser are each written only when that
%   cue type exists for the session (see the main loop above), so "any one
%   of them present" is the right test, not "all four".
% SV, September 1, 2026: I changed
% cueFiles = {'csp_cue_frames.csv', 'csm_cue_frames.csv', 'us_cue_frames.csv', 'laser_cue_frames.csv'};
% tf = any(cellfun(@(f) isfile(fullfile(folder, f)), cueFiles));
% to this: output filenames now carry the session folder's name as a prefix
% (see the main loop above), so this checks by suffix instead of an exact
% name - works regardless of what the prefix is. Also still matches the OLD
% bare filenames (no prefix) that every session already on disk was written
% with by SVv3 and earlier - without this, every already-done session would
% read as "not done" the first time SVv4 runs on an existing cohort, and get
% reprocessed into a second, prefixed copy sitting next to the original
% instead of being correctly skipped.
oldNames = {'csp_cue_frames.csv', 'csm_cue_frames.csv', 'us_cue_frames.csv', 'laser_cue_frames.csv'};
newSuffixes = {'*_csp_cue_frames.csv', '*_csm_cue_frames.csv', '*_us_cue_frames.csv', '*_laser_cue_frames.csv'};
tf = any(cellfun(@(f) isfile(fullfile(folder, f)), oldNames)) ...
   | any(cellfun(@(pat) ~isempty(dir(fullfile(folder, pat))), newSuffixes));
%
end
