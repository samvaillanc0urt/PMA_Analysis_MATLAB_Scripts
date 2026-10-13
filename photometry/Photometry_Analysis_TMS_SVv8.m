%% Photometry_Analysis_TMS_SVv8.m
% SV Sep 2026 (SV / Claude). Started as Photometry_Analysis_TMS_GroupSummary_SVv1.m. New script -- not a versioned edit of
% Photometry_Analysis_TMS_SVv6.m, because the scope is different (raw
% folder organization + a group-level tms-vs-sham summary report,
% instead of one QC PDF per processing stage).
% v8 (SV 10/1/26): the whole-session trace panels now start PRE_PAD_S
% before the z-score baseline and mark it with a "Baseline" bar, the t=0
% (first train) line and tick-aligned axes, in the convention of
% PMA_photometry_complete_SVv1.m's drawAnnotationBar/applyRowAxes.
% Also: every page is rendered at its designed size even on a display
% smaller than the figure (tms_page_figure). Nothing else differs from v7.

%% What this script does
% Point it at a raw, unorganized aiTBS/sham stimulation-day photometry
% dump -- one subfolder per subject per recorded session, e.g.
%   PVFP_TmsSham_SV_Aug25_photometry\PVFP_28\        (session 1, "first")
%   PVFP_TmsSham_SV_Aug25_photometry\PVFP_28_tenth\  (session 10, "tenth")
% -- and it will:
%
%   1. Discover subject/session pairs by folder name.
%   2. Ask you which subjects are tms vs sham.
%   3. Auto-detect the fluorescence channel(s) present (GFP/RFP-style
%      signal + isosbestic stream pairs) from the TDT block headers, and
%      ask you what each corresponds to (construct/cell type).
%   4. Auto-detect which TDT epoc channel actually carries the aiTBS
%      pulse-train pattern (~40-80 trains/session, ~6-14s apart) rather
%      than assuming a hardcoded epoc name -- then shows you what it
%      found and lets you override it.
%   5. Show a dry-run rename plan (old folder -> new
%      "<SUBJ>_<Group><SessionNum>_SV_<MonDD>" folder, grouped under
%      "<Group><SessionNum>\", matching the PMA <group>_<Day> convention
%      -- see docs/data_layout.md) and, only after you confirm, moves
%      the folders and writes a manifest CSV so the reorg is reversible.
%   6. For each subject/session/channel: loads the TDT block, subtracts
%      the isosbestic-fit from the signal channel (standard 405/415
%      regression), declutters the aiTBS epoc down to one onset per
%      theta-burst train, and z-scores each train-aligned trial against
%      its own pre-train baseline.
%   7. Builds ONE consolidated report PDF (not one PDF per processing
%      stage), every page 8.5x11in portrait -- each figure is drawn at its
%      own designed size and then scaled down as a whole to fit the page,
%      never re-laid-out. In order: (a) per channel, TMS vs Sham: a
%      Fig1(F/G/H/I)-style summary page (mean+/-SEM z-scored trace, First
%      session and Tenth session, tms vs sham overlaid, plus AUC 0-4s /
%      4-8s bar+scatter with paired First->Tenth lines per subject) and a
%      whole-session page in the style of Gongwer et al. 2026 (Cell) Fig
%      2H-J (the entire ~10-min session z-scored to the few seconds before
%      its first train, mean+/-SEM tms vs sham, AUC in 2-min bins, and
%      TMS-minus-sham AUC First vs Tenth); (b) with two or more channels,
%      the same two pages comparing channel vs channel (e.g. SST vs PV)
%      within TMS and within Sham -- paired, since both channels come from
%      the same animals; (c) raw-signal QC page(s) (full isosbestic-
%      corrected, non-z-scored trace per subject/session, grey lines at
%      each detected train onset, for a quick visual check of signal
%      quality); (d) every statistics page, at the very back. Colours follow
%      SV's palette: TMS in its channel's colour (SST orange, PV yellow),
%      Sham in grey (a darker grey for one of two Sham series together).
%   8. Saves an aggregate .mat with everything computed, plus a text run
%      log recording every auto-detection decision and any subject that
%      was skipped, so a later re-run or manual check has a paper trail.
%
% Nothing on disk is renamed until you explicitly confirm the dry-run
% plan; the report/analysis step works from wherever the session folders
% end up (renamed or left as-is if you decline the reorg).

%% Manual entries (edit before running if defaults don't fit your data)
FP_DS_FACTOR   = 10;   % downsample factor for the fluorescence streams
TRANGE_pre     = 2;    % seconds before each theta-burst train onset
TRANGE_post    = 8;    % seconds after each theta-burst train onset (2s burst + 8s inter-burst = 10s cycle)
% The z-score baseline window is NOT set here -- it's confirmed/overridden
% via a popup below (default [-2 0]) so it's easy to try different windows
% without editing the script.
AUC_WIN1       = [0 4];  % first AUC window (s, relative to train onset) -- matches Fig1H
AUC_WIN2       = [4 8];  % second AUC window (s, relative to train onset) -- matches Fig1I
DECLUTTER_GAP  = 5;      % seconds; onsets closer together than this collapse into one train-start onset
SESSION_LABELS = {'First','Tenth'};  % session 1 = "First", session 10 = "Tenth" (specific, not "Last" -- you may not always record all 10)
SESSION_NUMS   = [1 10];
PRE_RECORDING_TRIM_S  = 90; % seconds of recording to keep BEFORE the FIRST train onset; anything earlier is dropped
POST_RECORDING_TRIM_S = 90; % seconds of recording to keep AFTER the LAST train onset; anything past that (e.g. a forgotten-running recorder) is dropped before signal processing
MARGIN_IN      = 0.25;   % margin (inches) inside each report figure, and again around it on the 8.5x11in portrait page it is scaled onto
SESSION_BL_S     = 5;       % whole-session page (Gongwer et al. 2026 Cell, Fig 2H-J style): seconds right before the first train that the WHOLE session is z-scored against
SESSION_BIN_MIN  = 0:2:10;  % whole-session page: AUC bin edges (min from the first train) -- 0-2, 2-4, ..., 8-10 as in Fig 2I
SESSION_SMOOTH_S = 0.2;     % whole-session page: moving average (s) applied to each animal's trace for DISPLAY only (AUCs use the unsmoothed trace), as in the paper's methods
PRE_PAD_S        = 30;      % whole-session trace panels: seconds plotted BEFORE the baseline window starts, so the baseline (and a little before it) is visible -- display only

clearvars -except FP_DS_FACTOR TRANGE_pre TRANGE_post AUC_WIN1 AUC_WIN2 DECLUTTER_GAP SESSION_LABELS SESSION_NUMS PRE_RECORDING_TRIM_S POST_RECORDING_TRIM_S MARGIN_IN SESSION_BL_S SESSION_BIN_MIN SESSION_SMOOTH_S PRE_PAD_S

if exist('TDTbin2mat', 'file') ~= 2
    error(['You must add the folder ''TDTMatlabSDK-master'' to your path so MATLAB can use it for the ''TDTbin2mat'' function:' newline ...
           '1. On the Home tab, in the Environment section, click Set Path.' newline ...
           '2. Click Add with Subfolders...' newline ...
           '3. Navigate to and select the extracted TDTMatlabSDK folder (from https://github.com/tdtneuro/TDTMatlabSDK).' newline ...
           '4. Click Save, then click Close.']);
end

%% 1. Select the raw data folder
disp('Select the folder containing one subfolder per subject/session (e.g. PVFP_TmsSham_SV_Aug25_photometry)');
parent_dir = uigetdir('', 'Select the raw TMS/sham photometry folder');
if isequal(parent_dir, 0)
    error('No folder selected.');
end
[~, parent_name] = fileparts(parent_dir);

%% 2. Discover subject/session pairs
[subjects, discover_warnings, layout] = tms_discover_subjects(parent_dir);
if isempty(subjects)
    error('No First/Tenth session folder pairs found in %s (checked both the raw and the already-organized layout).', parent_dir);
end
if strcmp(layout, 'organized')
    fprintf('Folders already appear organized under a Group<N>\\ layout -- skipping rename and re-reading group from the folder names.\n');
end
fprintf('Found %d subject(s) with both First and Tenth sessions:\n', numel(subjects));
for i = 1:numel(subjects)
    fprintf('  %s\n', subjects(i).name);
end
if ~isempty(discover_warnings)
    fprintf('Skipped/unmatched folders:\n');
    for i = 1:numel(discover_warnings)
        fprintf('  %s\n', discover_warnings{i});
    end
end

%% 2.5. Optionally exclude subjects (before any further per-subject prompts/work)
excludeNames = tms_prompt_exclude_subjects({subjects.name});
if ~isempty(excludeNames)
    fprintf('Excluding %d subject(s): %s\n', numel(excludeNames), strjoin(excludeNames, ', '));
    subjects = subjects(~ismember({subjects.name}, excludeNames));
    if isempty(subjects)
        error('All subjects were excluded -- nothing left to analyze.');
    end
end

%% 3. Ask group assignment (tms/sham) per subject -- unless the organized
% layout already encodes it in the folder names
if strcmp(layout, 'organized')
    for i = 1:numel(subjects)
        fprintf('  %s -> %s (from folder name)\n', subjects(i).name, subjects(i).group);
    end
else
    groupMap = tms_prompt_groups({subjects.name});
    for i = 1:numel(subjects)
        subjects(i).group = groupMap(subjects(i).name); % 'tms' or 'sham'
    end
end

%% 4. Extract the MonDD naming token from the parent folder name (e.g. "Aug25")
% Only needed to build new folder names, so skip it when there's nothing left to rename.
if strcmp(layout, 'organized')
    monthday = '';
else
    monthday = tms_extract_monthday(parent_name);
    if isempty(monthday)
        candidates = tms_find_monthday_candidates(parent_name);
        options = [candidates, {'Other (type manually)'}];
        monthday = tms_choice_or_type({'Could not parse a "SV_MonDD" token from the parent folder name.', ...
                                        'Pick the MonDD tag to use for renamed folders:'}, options, 'Month/day tag');
    end
    fprintf('Using MonDD tag: %s\n', monthday);
end

%% 5. Peek TDT stream headers (fast partial read) and detect channel(s) per subject
for i = 1:numel(subjects)
    hdr = TDTbin2mat(subjects(i).first_folder, 'TYPE', {'streams'}, 'T2', 1);
    subjects(i).streamNames = fieldnames(hdr.streams);
    subjects(i).channels = tms_detect_channels(subjects(i).streamNames);
    if isempty(subjects(i).channels)
        warning('No signal/isosbestic stream pair detected for %s -- this subject will be skipped.', subjects(i).name);
    end
end

%% 6. Ask what each detected channel corresponds to
subjects = tms_prompt_channel_labels(subjects);

%% 6.5. Confirm/override the z-score baseline window
BASELINE_WINDOW = tms_prompt_baseline_window(TRANGE_pre);
fprintf('Using baseline window: [%.2f, %.2f]s relative to TMS onset\n', BASELINE_WINDOW(1), BASELINE_WINDOW(2));

%% 7. Build and show the dry-run rename plan (skip entirely if already organized)
if strcmp(layout, 'organized')
    fprintf('Skipping rename -- folders are already in the organized Group<N>\\ layout.\n');
    plan = struct('src', {}, 'dst', {});
else
    plan = tms_build_rename_plan(subjects, parent_dir, monthday, SESSION_NUMS);
    fprintf('\n--- Dry-run rename plan ---\n');
    for i = 1:numel(plan)
        fprintf('  %s\n  -> %s\n', plan(i).src, plan(i).dst);
    end
    do_rename = questdlg('Rename/move the folders above? (A manifest CSV will be written so this is reversible.)', ...
                          'Confirm folder reorg', 'Yes, rename', 'No, leave as-is', 'No, leave as-is');
    if strcmp(do_rename, 'Yes, rename')
        tms_execute_rename(plan, parent_dir);
        % point subjects at the new locations
        for i = 1:numel(subjects)
            for p = 1:numel(plan)
                if strcmp(plan(p).src, subjects(i).first_folder), subjects(i).first_folder = plan(p).dst; end
                if strcmp(plan(p).src, subjects(i).last_folder),  subjects(i).last_folder  = plan(p).dst; end
            end
        end
        fprintf('Folders renamed.\n');
    else
        fprintf('Skipping rename -- analyzing sessions from their current locations.\n');
    end
end

%% 8. Pre-scan epocs across all sessions and confirm the TMS epoc channel to use
sessionFolders = {};
for i = 1:numel(subjects)
    sessionFolders{end+1} = subjects(i).first_folder; %#ok<AGROW>
    sessionFolders{end+1} = subjects(i).last_folder;  %#ok<AGROW>
end
epocChoice = tms_resolve_ref_epoc(sessionFolders, DECLUTTER_GAP);

%% 9. Process every subject x session x channel
runLog = {};
results = struct('subject', {}, 'group', {}, 'session', {}, 'channel', {}, ...
                  't', {}, 'zall', {}, 'traw', {}, 'auc1', {}, 'auc2', {}, 'aucFull', {}, ...
                  'fullTrace_t', {}, 'fullTrace_sig', {}, 'trainOnsets', {}, 'refEpoc', {}, 'pulseRelTimes', {});

for i = 1:numel(subjects)
    subj = subjects(i);
    if isempty(subj.channels)
        runLog{end+1} = sprintf('SKIPPED %s: no fluorescence channel detected.', subj.name); %#ok<AGROW>
        continue
    end
    folders = {subj.first_folder, subj.last_folder};
    for s = 1:2
        folder = folders{s};
        ref_epoc = epocChoice(folder);
        try
            data = TDTbin2mat(folder, 'TYPE', {'epocs','streams'});
        catch ME
            runLog{end+1} = sprintf('SKIPPED %s / %s: TDTbin2mat failed (%s)', subj.name, SESSION_LABELS{s}, ME.message); %#ok<AGROW>
            continue
        end
        if ~isfield(data.epocs, ref_epoc)
            runLog{end+1} = sprintf('SKIPPED %s / %s: epoc "%s" not present in this session.', subj.name, SESSION_LABELS{s}, ref_epoc); %#ok<AGROW>
            continue
        end
        rawOnsets = data.epocs.(ref_epoc).onset;
        trains = tms_declutter_trains(rawOnsets, DECLUTTER_GAP);
        % Individual pulse times within each train, relative to that train's
        % own onset -- lets the report show where the sub-pulses actually
        % fall on the same trial-aligned time axis as the z-scored trace,
        % whatever the TTL line actually captured (not assumed/idealized).
        pulseRelTimes = tms_pulse_rel_times(rawOnsets, trains, DECLUTTER_GAP);
        runLog{end+1} = sprintf('%s / %s: epoc=%s, %d trains detected.', subj.name, SESSION_LABELS{s}, ref_epoc, numel(trains)); %#ok<AGROW>

        for c = 1:numel(subj.channels)
            ch = subj.channels(c);
            if ~isfield(data.streams, ch.sigStream) || ~isfield(data.streams, ch.isoStream)
                runLog{end+1} = sprintf('SKIPPED %s / %s / %s: stream missing from this session.', subj.name, SESSION_LABELS{s}, ch.label); %#ok<AGROW>
                continue
            end
            s_sig = data.streams.(ch.sigStream).data;
            s_iso = data.streams.(ch.isoStream).data;
            fs_native = data.streams.(ch.sigStream).fs;

            minlen = min(numel(s_sig), numel(s_iso));
            s_sig = s_sig(1:minlen);
            s_iso = s_iso(1:minlen);

            % Recording sometimes keeps running before/after the session
            % itself (forgot to start/stop it in sync) -- keep only
            % PRE_RECORDING_TRIM_S before the first train through
            % POST_RECORDING_TRIM_S after the last train, before the
            % 405/415 fit, so a long stray head/tail can't skew it or
            % clutter the raw QC trace. Onsets are re-based to the
            % trimmed signal's new t=0.
            trainsForChan = trains;
            startSample = 1;
            if ~isempty(trains)
                startTime = max(0, trains(1) - PRE_RECORDING_TRIM_S);
                startSample = min(minlen, max(1, round(startTime * fs_native) + 1));
                endSample = min(minlen, round((trains(end) + POST_RECORDING_TRIM_S) * fs_native));
                s_sig = s_sig(startSample:endSample);
                s_iso = s_iso(startSample:endSample);
                trainsForChan = trains - (startSample - 1) / fs_native;
            end

            s_sig = s_sig(1:FP_DS_FACTOR:end);
            s_iso = s_iso(1:FP_DS_FACTOR:end);
            fs = fs_native / FP_DS_FACTOR;

            % 405/415-onto-signal linear fit and subtraction (centered to
            % avoid the "badly conditioned polynomial" warning that
            % appears when fitting on raw, un-centered fluorescence counts)
            iso_c = s_iso - mean(s_iso);
            bls = polyfit(iso_c, s_sig, 1);
            fit_sig = bls(1) .* iso_c + bls(2);
            corrected = s_sig - fit_sig;

            [zall, traw, t] = tms_epoch_and_zscore(corrected, fs, trainsForChan, TRANGE_pre, TRANGE_post, BASELINE_WINDOW);
            if isempty(zall)
                runLog{end+1} = sprintf('SKIPPED %s / %s / %s: no trials fit inside the recording window.', subj.name, SESSION_LABELS{s}, ch.label); %#ok<AGROW>
                continue
            end

            idx1 = t >= AUC_WIN1(1) & t <= AUC_WIN1(2);
            idx2 = t >= AUC_WIN2(1) & t <= AUC_WIN2(2);
            idxFull = t >= 0 & t <= TRANGE_post;
            auc1 = trapz(t(idx1), zall(:, idx1), 2);
            auc2 = trapz(t(idx2), zall(:, idx2), 2);
            aucFull = trapz(t(idxFull), zall(:, idxFull), 2);

            r = struct();
            r.subject = subj.name;
            r.group = subj.group;
            r.session = SESSION_LABELS{s};
            r.channel = ch.label;
            r.t = t;
            r.zall = zall;
            r.traw = traw;
            r.auc1 = auc1;
            r.auc2 = auc2;
            r.aucFull = aucFull;
            r.fullTrace_t = (0:numel(corrected)-1) / fs;
            r.fullTrace_sig = corrected;
            r.trainOnsets = trainsForChan;
            r.refEpoc = ref_epoc;
            r.pulseRelTimes = pulseRelTimes;
            results(end+1) = r; %#ok<AGROW>
        end
    end
end

if isempty(results)
    error('No sessions were successfully processed -- see run log below.\n%s', strjoin(runLog, newline));
end

%% 9.5. Whole-session activity, z-scored to a pre-session baseline (Gongwer et al. 2026 Fig 2H-J)
[wholeSession, wsLog] = tms_whole_session(results, subjects, SESSION_LABELS, SESSION_BL_S, SESSION_BIN_MIN, SESSION_SMOOTH_S, TRANGE_post, PRE_PAD_S);
runLog = [runLog, wsLog];
wholeSessionPairs = tms_whole_session_pairs(wholeSession); % channel vs channel within TMS and within Sham (empty for a single-colour cohort)

%% 10. Save aggregate results + run log
timestamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
out_mat = fullfile(parent_dir, sprintf('TMS_GroupSummary_%s_%s.mat', parent_name, timestamp));
save(out_mat, 'results', 'subjects', 'plan', 'runLog', 'FP_DS_FACTOR', 'TRANGE_pre', 'TRANGE_post', 'BASELINE_WINDOW', 'AUC_WIN1', 'AUC_WIN2', ...
     'wholeSession', 'wholeSessionPairs', 'SESSION_BL_S', 'SESSION_BIN_MIN', 'SESSION_SMOOTH_S');
out_log = fullfile(parent_dir, sprintf('TMS_GroupSummary_%s_%s_runlog.txt', parent_name, timestamp));
fid = fopen(out_log, 'w');
fprintf(fid, '%s\n', runLog{:});
fclose(fid);
fprintf('Saved aggregate results to %s\nSaved run log to %s\n', out_mat, out_log);

%% 11. Build the consolidated report (group-level figure pages, then raw-QC pages, then every stats page -- all 8.5x11in portrait)
out_pdf = fullfile(parent_dir, sprintf('TMS_GroupSummary_%s_%s.pdf', parent_name, timestamp));
tms_build_report(results, subjects, SESSION_LABELS, AUC_WIN1, AUC_WIN2, out_pdf, parent_name, TRANGE_post, BASELINE_WINDOW, MARGIN_IN, wholeSession, wholeSessionPairs);
fprintf('Saved report to %s\n', out_pdf);


%% ======================= Local functions =======================

function [subjects, warnings, layout] = tms_discover_subjects(parent_dir)
% Try the raw, un-renamed layout first ("PVFP_28" / "PVFP_28_tenth" sitting
% directly in parent_dir). If nothing matches, fall back to the already-
% organized layout this script itself produces ("Tms1\PVFP_28_Tms1_SV_..."),
% so re-running the script on a folder it already renamed doesn't error out
% or try to rename things a second time.
[subjects, warnings] = tms_discover_subjects_raw(parent_dir);
if ~isempty(subjects)
    layout = 'raw';
    return
end
[subjects, warnings] = tms_discover_subjects_organized(parent_dir);
layout = 'organized';
end

function [subjects, warnings] = tms_discover_subjects_raw(parent_dir)
% Pair "PVFP_28" (session 1 / First) with "PVFP_28_tenth" (session 10 / Tenth).
d = dir(parent_dir);
d = d([d.isdir] & ~ismember({d.name}, {'.','..'}));
names = {d.name};
is_tenth = endsWith(names, '_tenth', 'IgnoreCase', true);

base_of_tenth = cell(size(names));
base_of_tenth(is_tenth) = extractBefore(names(is_tenth), '_tenth');

warnings = {};
subjects = struct('name', {}, 'first_folder', {}, 'last_folder', {});
firstNames = names(~is_tenth);
for i = 1:numel(firstNames)
    subj = firstNames{i};
    tenthMatch = find(is_tenth & strcmpi(base_of_tenth, subj), 1);
    if isempty(tenthMatch)
        warnings{end+1} = sprintf('%s has no matching "*_tenth" (Tenth session) folder -- skipped.', subj); %#ok<AGROW>
        continue
    end
    subjects(end+1) = struct('name', subj, ...
                              'first_folder', fullfile(parent_dir, subj), ...
                              'last_folder', fullfile(parent_dir, names{tenthMatch})); %#ok<AGROW>
end
% Flag any "_tenth" folders with no matching first-session folder
usedTenth = {subjects.last_folder};
for i = 1:numel(names)
    if is_tenth(i) && ~any(strcmp(fullfile(parent_dir, names{i}), usedTenth))
        warnings{end+1} = sprintf('%s has no matching first-session folder -- skipped.', names{i}); %#ok<AGROW>
    end
end
end

function [subjects, warnings] = tms_discover_subjects_organized(parent_dir)
% Look for "<Group><N>\<SUBJ>_<Group><N>_SV_<MonDD>" (N = 1 or 10) --
% the layout tms_execute_rename produces. Group is read back out of the
% folder name, so re-running the script on already-organized folders
% skips the tms/sham prompt too.
warnings = {};
subjects = struct('name', {}, 'first_folder', {}, 'last_folder', {}, 'group', {});

d = dir(parent_dir);
d = d([d.isdir] & ~ismember({d.name}, {'.','..'}));
groupDirNames = {d.name};
tok = regexp(groupDirNames, '^([A-Za-z]+?)(1|10)$', 'tokens', 'once');

sessionMap = containers.Map();
for i = 1:numel(groupDirNames)
    if isempty(tok{i})
        continue
    end
    groupName = lower(tok{i}{1});
    sessNum = str2double(tok{i}{2});
    groupPath = fullfile(parent_dir, groupDirNames{i});
    sd = dir(groupPath);
    sd = sd([sd.isdir] & ~ismember({sd.name}, {'.','..'}));
    for j = 1:numel(sd)
        m = regexp(sd(j).name, '^(.+?)_[A-Za-z]+\d+_SV_', 'tokens', 'once');
        if isempty(m)
            warnings{end+1} = sprintf('Could not parse a subject name out of "%s" -- skipped.', sd(j).name); %#ok<AGROW>
            continue
        end
        subj = m{1};
        if ~isKey(sessionMap, subj)
            sessionMap(subj) = struct('first_folder', '', 'last_folder', '', 'group', groupName); %#ok<NASGU>
        end
        entry = sessionMap(subj);
        entry.group = groupName;
        if sessNum == 1
            entry.first_folder = fullfile(groupPath, sd(j).name);
        else
            entry.last_folder = fullfile(groupPath, sd(j).name);
        end
        sessionMap(subj) = entry; %#ok<NASGU>
    end
end

names_ = keys(sessionMap);
for i = 1:numel(names_)
    e = sessionMap(names_{i});
    if isempty(e.first_folder) || isempty(e.last_folder)
        warnings{end+1} = sprintf('%s is missing a First or Tenth session folder in the organized layout -- skipped.', names_{i}); %#ok<AGROW>
        continue
    end
    subjects(end+1) = struct('name', names_{i}, 'first_folder', e.first_folder, ...
                              'last_folder', e.last_folder, 'group', e.group); %#ok<AGROW>
end
end

function excludeNames = tms_prompt_exclude_subjects(subjectNames)
% Checkbox list -- check any subject to EXCLUDE from the whole analysis
% (e.g. bad signal, wrong construct). Nothing checked = everyone included,
% no confirmation needed; anything checked gets a confirm/redo loop since
% it's easy to misclick and this determines what gets analyzed at all.
if isempty(subjectNames)
    excludeNames = {};
    return
end
initialSel = [];
while true
    [sel, ok] = listdlg('ListString', subjectNames, 'SelectionMode', 'multiple', ...
                         'InitialValue', initialSel, ...
                         'PromptString', {'Check any subjects to EXCLUDE from this analysis.', ...
                                          'Leave unchecked to include everyone.'}, ...
                         'ListSize', [300 max(150, 18*numel(subjectNames))], ...
                         'OKString', 'Continue', 'CancelString', 'Cancel');
    if ~ok
        error('Subject exclusion selection cancelled.');
    end
    excludeNames = subjectNames(sel);
    if isempty(excludeNames)
        return
    end
    msg = sprintf('Excluding: %s\n\nIs this correct?', strjoin(excludeNames, ', '));
    confirm = questdlg(msg, 'Confirm exclusions', 'Yes, correct', 'No, redo', 'Yes, correct');
    if strcmp(confirm, 'Yes, correct')
        return
    end
    initialSel = sel;
end
end

function groupMap = tms_prompt_groups(subjectNames)
% Checkbox list -- no typing. Check every subject that is TMS/aiTBS;
% anything left unchecked is assigned Sham. Shows the resulting split
% back for confirmation before locking it in (Redo re-opens the checklist).
initialTms = []; % remembers the previous pass's checks if the user redoes it
while true
    [sel, ok] = listdlg('ListString', subjectNames, 'SelectionMode', 'multiple', ...
                         'InitialValue', initialTms, ...
                         'PromptString', {'Check every subject that is TMS/aiTBS.', 'Everything left unchecked will be assigned Sham.'}, ...
                         'ListSize', [300 max(150, 20*numel(subjectNames))], ...
                         'OKString', 'Continue', 'CancelString', 'Cancel');
    if ~ok
        error('Group assignment cancelled.');
    end
    resolved = repmat({'sham'}, size(subjectNames));
    resolved(sel) = {'tms'};

    tmsList = strjoin(subjectNames(sel), ', ');
    shamList = strjoin(subjectNames(setdiff(1:numel(subjectNames), sel)), ', ');
    if isempty(tmsList), tmsList = '(none)'; end
    if isempty(shamList), shamList = '(none)'; end
    msg = sprintf('TMS: %s\nSham: %s\n\nIs this correct?', tmsList, shamList);
    confirm = questdlg(msg, 'Confirm group assignment', 'Yes, correct', 'No, redo', 'Yes, correct');
    if strcmp(confirm, 'Yes, correct')
        groupMap = containers.Map(subjectNames, resolved);
        return
    end
    initialTms = sel; % keep their previous checks pre-checked on redo
end
end

function monthday = tms_extract_monthday(parent_name)
tok = regexp(parent_name, '_SV_([A-Za-z]{3}\d{1,2})', 'tokens', 'once');
if isempty(tok)
    monthday = '';
else
    monthday = tok{1};
end
end

function candidates = tms_find_monthday_candidates(parent_name)
% Any MonDD-shaped substring anywhere in the folder name (e.g. "Aug25"),
% used to build a checklist instead of asking the user to type one.
toks = regexp(parent_name, '[A-Za-z]{3}\d{1,2}', 'match');
candidates = unique(toks, 'stable');
end

function label = tms_choice_or_type(promptLines, options, dlgTitle)
% Checkbox/list pick from a preset list of options, whose last entry must
% be 'Other (type manually)' -- only picking that opens a typing dialog.
% No typing required for anything that's already in the preset list.
while true
    [sel, ok] = listdlg('ListString', options, 'SelectionMode', 'single', ...
                         'PromptString', promptLines, 'ListSize', [480 200], ...
                         'OKString', 'Select', 'CancelString', 'Cancel');
    if ~ok
        error('%s cancelled.', dlgTitle);
    end
    if sel < numel(options) % anything but the trailing 'Other' entry
        label = options{sel};
        return
    end
    answer = inputdlg({'Type the label to use:'}, dlgTitle, 1, {''});
    if isempty(answer) || isempty(strtrim(answer{1}))
        continue % back to the checklist rather than accepting a blank label
    end
    label = strtrim(answer{1});
    return
end
end

function baselineWindow = tms_prompt_baseline_window(trangePre)
% Checkbox-first (matching this script's other dialogs), typing only via
% "Other" -- and unlike tms_choice_or_type, "Other" here jumps straight to
% a two-number dialog rather than a single text box, since a baseline
% window is inherently two numbers. [-2 0] is the default/first option;
% TRANGE_pre bounds how far back a baseline start can go, since that's how
% much pre-onset data is actually loaded per trial.
presetLabels = {'-2 to 0 (default)', '-2 to -0.5', '-1.5 to 0', '-1 to 0', 'Other (type manually)'};
presetVals   = {[-2 0], [-2 -0.5], [-1.5 0], [-1 0]};
while true
    [sel, ok] = listdlg('ListString', presetLabels, 'SelectionMode', 'single', ...
                         'PromptString', {'Pick the baseline window for z-scoring', ...
                                          '(seconds, relative to each TMS train onset):'}, ...
                         'ListSize', [340 150], 'OKString', 'Select', 'CancelString', 'Cancel');
    if ~ok
        error('Baseline window selection cancelled.');
    end
    if sel <= numel(presetVals)
        baselineWindow = presetVals{sel};
    else
        answer = inputdlg({'Baseline start (s, relative to TMS onset, e.g. -2):', ...
                            'Baseline end (s, relative to TMS onset, e.g. -0.5):'}, ...
                           'Custom baseline window', 1, {'-2', '0'});
        if isempty(answer)
            continue % back to the checklist rather than erroring out
        end
        baselineWindow = [str2double(answer{1}), str2double(answer{2})];
    end

    if numel(baselineWindow) ~= 2 || any(isnan(baselineWindow)) || baselineWindow(1) >= baselineWindow(2)
        uiwait(warndlg('Baseline start must be a number less than baseline end.', 'Invalid baseline window'));
        continue
    end
    if baselineWindow(1) < -trangePre
        uiwait(warndlg(sprintf(['Baseline start (%.2fs) is earlier than the %.2fs of pre-onset data loaded ' ...
            '(TRANGE_pre) -- pick a later start, or increase TRANGE_pre in the script''s manual entries.'], ...
            baselineWindow(1), trangePre), 'Invalid baseline window'));
        continue
    end
    return
end
end

function subjects = tms_prompt_channel_labels(subjects)
% Ask what each detected channel signature (region+band) corresponds to,
% via a preset checklist (falls back to typing only via "Other" -- see
% tms_choice_or_type). Subjects sharing the same signature are asked once,
% together.
presetGreen = {'PV [GCaMP7f]', 'SST [sRGECO]', 'SST [GCaMP7f]', ...
               'GCaMP', 'sRGECO', 'Other (type manually)'};
presetRed = {'SST [jRGECO1a]', 'RFP', 'Other (type manually)'};

sigKey = @(chans) strjoin(arrayfun(@(c) sprintf('%s:%s', c.region, c.band), chans, 'UniformOutput', false), ',');

sigMap = containers.Map();
for i = 1:numel(subjects)
    if isempty(subjects(i).channels), continue; end
    key = sigKey(subjects(i).channels);
    if ~isKey(sigMap, key)
        sigMap(key) = {};
    end
    sigMap(key) = [sigMap(key), subjects(i).name]; %#ok<NASGU>
end

keys_ = keys(sigMap);
labelsByKey = containers.Map();
for k = 1:numel(keys_)
    key = keys_{k};
    subjsForKey = sigMap(key);
    exampleIdx = find(strcmp({subjects.name}, subjsForKey{1}), 1);
    chans = subjects(exampleIdx).channels;
    labels = cell(1, numel(chans));
    for c = 1:numel(chans)
        if strcmp(chans(c).band, 'red')
            options = presetRed;
        else
            options = presetGreen;
        end
        % The channel identity (which of possibly several simultaneously-
        % recorded channels this is) is the thing that actually needs to be
        % unmissable here -- put it first, in plain terms, and keep every
        % line short rather than one long "Subjects: ..." line that can
        % visually crowd out the actual question in listdlg's prompt area.
        promptLines = [{sprintf('%s CHANNEL (%s signal / %s isosbestic)', upper(chans(c).band), chans(c).sigStream, chans(c).isoStream), ...
                         'What construct/cell type does THIS channel correspond to?', ...
                         '(every subject below has this exact channel -- this is not asking', ...
                         'which subjects have it, just what to call it)', ...
                         sprintf('Applies to all %d subjects:', numel(subjsForKey))}, ...
                        tms_wrap_text(strjoin(subjsForKey, ', '), 60)];
        labels{c} = tms_choice_or_type(promptLines, options, 'Channel label');
    end
    labelsByKey(key) = labels;
end

for i = 1:numel(subjects)
    if isempty(subjects(i).channels), continue; end
    key = sigKey(subjects(i).channels);
    labels = labelsByKey(key);
    for c = 1:numel(subjects(i).channels)
        subjects(i).channels(c).label = labels{c};
    end
end
end

function plan = tms_build_rename_plan(subjects, parent_dir, monthday, sessionNums)
plan = struct('src', {}, 'dst', {});
for i = 1:numel(subjects)
    groupCap = [upper(subjects(i).group(1)) lower(subjects(i).group(2:end))];
    folders = {subjects(i).first_folder, subjects(i).last_folder};
    for s = 1:2
        groupDay = sprintf('%s%d', groupCap, sessionNums(s));
        newName = sprintf('%s_%s_SV_%s', subjects(i).name, groupDay, monthday);
        dst = fullfile(parent_dir, groupDay, newName);
        plan(end+1) = struct('src', folders{s}, 'dst', dst); %#ok<AGROW>
    end
end
end

function tms_execute_rename(plan, parent_dir)
timestamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
manifest = fullfile(parent_dir, sprintf('_tms_reorg_manifest_%s.csv', timestamp));
fid = fopen(manifest, 'w');
fprintf(fid, 'source,destination\n');
for i = 1:numel(plan)
    dstParent = fileparts(plan(i).dst);
    if ~exist(dstParent, 'dir')
        mkdir(dstParent);
    end
    if exist(plan(i).dst, 'dir')
        warning('Destination already exists, skipping: %s', plan(i).dst);
        continue
    end
    movefile(plan(i).src, plan(i).dst);
    fprintf(fid, '"%s","%s"\n', plan(i).src, plan(i).dst);
end
fclose(fid);
fprintf('Reorg manifest written to %s\n', manifest);
end

function epocChoice = tms_resolve_ref_epoc(sessionFolders, declutter_gap)
% Pre-scan epocs (fast, TYPE={'epocs'} only) for every session, auto-detect
% the aiTBS-pattern epoc per session, and confirm with the user in ONE
% dialog when detection agrees across all sessions.
%
% A larger/older cohort can have genuinely different epoc naming across
% subsets of sessions (e.g. Feb-recorded sessions offering an ambiguous
% PtC0-vs-PC1_ choice, Apr-recorded sessions resolving cleanly to PC3_ on
% their own) -- sessions that resolve unambiguously on their own are never
% re-asked, and sessions that stay ambiguous are grouped by the exact set
% of candidate names they're offering, so "60 sessions all offering the
% same PtC0-vs-PC1_ choice" is one dialog, not 60.
epocChoice = containers.Map();
detected = cell(numel(sessionFolders), 1);
allInfo = cell(numel(sessionFolders), 1);
for i = 1:numel(sessionFolders)
    data = TDTbin2mat(sessionFolders{i}, 'TYPE', {'epocs'});
    [best, info] = tms_detect_epoc(data.epocs, struct('declutter_gap', declutter_gap));
    detected{i} = best;
    allInfo{i} = info;
end

uniqueDetected = unique(detected(~cellfun(@isempty, detected)));
allResolved = ~any(cellfun(@isempty, detected));
needsAsking = cellfun(@isempty, detected); % logical mask, one per session

if allResolved && isscalar(uniqueDetected)
    ref = uniqueDetected{1};
    msg = sprintf('Auto-detected TMS epoc channel: "%s" (consistent across all %d sessions).\nUse this for every session?', ref, numel(sessionFolders));
    choice = questdlg(msg, 'Confirm TMS epoc channel', 'Yes, use this', 'No, let me pick per session', 'Yes, use this');
    if strcmp(choice, 'Yes, use this')
        for i = 1:numel(sessionFolders)
            epocChoice(sessionFolders{i}) = ref;
        end
        return
    end
    % Declined even though every session individually agreed -- the user
    % wants manual control, so treat every session as needing a fresh ask
    % below (still grouped by candidate set, so this stays one dialog
    % unless sessions actually differ).
    needsAsking(:) = true;
end

for i = 1:numel(sessionFolders)
    if ~needsAsking(i)
        epocChoice(sessionFolders{i}) = detected{i};
    end
end

toAsk = find(needsAsking);
sigOf = @(info) strjoin(sort({info.candidates.name}), '|');
sigs = cellfun(@(info) sigOf(info), allInfo(toAsk), 'UniformOutput', false);
uniqueSigs = unique(sigs);

for g = 1:numel(uniqueSigs)
    % Row vector, explicitly -- toAsk descends from find() on a column-
    % shaped logical (detected is built as an Nx1 cell), so without this
    % "for m = members" would iterate its single COLUMN as one non-scalar
    % block instead of element-by-element, and sessionFolders{m} on a
    % vector m fails ("Only one-dimensional indexing is supported").
    members = toAsk(strcmp(sigs, uniqueSigs{g}))';
    info = allInfo{members(1)};
    cand = info.candidates;
    if isempty(cand)
        error('No epoc fields found for session: %s', sessionFolders{members(1)});
    end
    items = arrayfun(@(c) sprintf('%s  ->  %d pulse-trains, ~%.1fs apart%s', ...
                     c.name, c.nTrains, c.interval, ternary(c.matches, '  [looks like the TMS pattern]', '  [does not look like the TMS pattern]')), cand, 'UniformOutput', false);
    if numel(members) > 1
        headline = sprintf('%d session(s) recorded more than one TTL/timing channel that could be marking the TMS pulses.', numel(members));
    else
        headline = sprintf('This session recorded more than one TTL/timing channel that could be marking the TMS pulses.');
    end
    promptLines = {headline, ...
                    'This is separate from the green/red fluorescence channels -- it is the digital', ...
                    'pulse-timing signal (shared by both) that marks exactly when each TMS pulse fired.', ...
                    'Pick which recorded channel actually has the pulses:'};
    [sel, ok] = listdlg('ListString', items, 'SelectionMode', 'single', ...
                         'PromptString', promptLines, 'ListSize', [560 200]);
    if ~ok
        error('Epoc selection cancelled.');
    end
    for m = members
        epocChoice(sessionFolders{m}) = cand(sel).name;
    end
end
end

function out = ternary(cond, a, b)
if cond, out = a; else, out = b; end
end

function train_onsets = tms_declutter_trains(onsets, gapThresh)
if nargin < 2, gapThresh = 5; end
onsets = sort(onsets(:));
if isempty(onsets)
    train_onsets = onsets;
    return
end
keep = true(size(onsets));
for i = 2:numel(onsets)
    if onsets(i) - onsets(i-1) < gapThresh
        keep(i) = false;
    end
end
train_onsets = onsets(keep);
end

function relTimes = tms_pulse_rel_times(rawOnsets, trainOnsets, gapThresh)
% For each declustered train onset, find the raw (un-decluttered) pulse
% onsets that belong to it (up to gapThresh later, or the next train's
% onset if that comes sooner) and express them relative to that train's
% own onset. Pooling across trains gives the actual pulse-timing pattern
% the TTL line captured, whatever it turns out to be -- not an idealized
% guess at the stimulation protocol.
rawOnsets = sort(rawOnsets(:));
trainOnsets = sort(trainOnsets(:));
relChunks = cell(numel(trainOnsets), 1);
for k = 1:numel(trainOnsets)
    lo = trainOnsets(k);
    if k < numel(trainOnsets)
        hi = min(lo + gapThresh, trainOnsets(k+1));
    else
        hi = lo + gapThresh;
    end
    inTrain = rawOnsets(rawOnsets >= lo & rawOnsets < hi);
    relChunks{k} = inTrain - lo;
end
relTimes = cell2mat(relChunks);
end

function [best_name, info] = tms_detect_epoc(epocs, opts)
if nargin < 2, opts = struct; end
if ~isfield(opts,'min_trains'), opts.min_trains = 40; end
if ~isfield(opts,'max_trains'), opts.max_trains = 80; end
if ~isfield(opts,'min_gap'),    opts.min_gap    = 6;  end
if ~isfield(opts,'max_gap'),    opts.max_gap    = 14; end
if ~isfield(opts,'min_onsets'), opts.min_onsets = 40; end
if ~isfield(opts,'exclude'),    opts.exclude    = {'Tick','Note'}; end
if ~isfield(opts,'declutter_gap'), opts.declutter_gap = 5; end

fn = fieldnames(epocs);
fn = fn(~ismember(fn, opts.exclude));

candidates = struct('name',{},'nOnsets',{},'nTrains',{},'interval',{},'matches',{},'onsets',{});
for i = 1:numel(fn)
    f = fn{i};
    if ~isfield(epocs.(f), 'onset')
        continue
    end
    onsets = epocs.(f).onset;
    c = struct();
    c.name = f;
    c.nOnsets = numel(onsets);
    if c.nOnsets < opts.min_onsets
        c.nTrains = NaN; c.interval = NaN; c.matches = false; c.onsets = onsets;
        candidates(end+1) = c; %#ok<AGROW>
        continue
    end
    trains = tms_declutter_trains(onsets, opts.declutter_gap);
    c.nTrains = numel(trains);
    if c.nTrains >= 2
        c.interval = median(diff(trains));
    else
        c.interval = NaN;
    end
    c.matches = c.nTrains >= opts.min_trains && c.nTrains <= opts.max_trains && ...
                c.interval >= opts.min_gap && c.interval <= opts.max_gap;
    c.onsets = onsets;
    candidates(end+1) = c; %#ok<AGROW>
end

info = struct();
info.candidates = candidates;
info.identical_group = {};

matchIdx = find([candidates.matches]);
if isempty(matchIdx)
    best_name = '';
    return
end
if isscalar(matchIdx)
    best_name = candidates(matchIdx).name;
    return
end

refOnsets = candidates(matchIdx(1)).onsets;
allIdentical = true;
for k = 2:numel(matchIdx)
    o = candidates(matchIdx(k)).onsets;
    if numel(o) ~= numel(refOnsets) || ~isequal(o, refOnsets)
        allIdentical = false;
        break
    end
end
if allIdentical
    names = {candidates(matchIdx).name};
    [~, order] = sort(names);
    best_name = names{order(1)};
    info.identical_group = names;
else
    best_name = '';
end
end

function chans = tms_detect_channels(streamNames)
streamNames = cellstr(streamNames);
tok = regexp(streamNames, '^x?(\d{3})([A-Za-z])$', 'tokens', 'once');

regions = struct();
for i = 1:numel(streamNames)
    if isempty(tok{i}), continue; end
    wl = str2double(tok{i}{1});
    region = upper(tok{i}{2});
    key = ['R' region];
    if ~isfield(regions, key)
        regions.(key) = struct('region', region, 'streams', {{}}, 'wavelengths', []);
    end
    regions.(key).streams{end+1} = streamNames{i};
    regions.(key).wavelengths(end+1) = wl;
end

% Some dual-color rigs record one shared isosbestic reference for BOTH
% emission channels (e.g. a single 405A alongside both 465A and 560B,
% rather than a 405A/415B isosbestic per region) -- collect every
% isosbestic stream globally so a region with a signal but no region-local
% isosbestic partner can still borrow one, instead of being silently
% dropped as an unpaired stream.
keys_ = fieldnames(regions);
globalIso = struct('name', {}, 'wavelength', {});
for k = 1:numel(keys_)
    r = regions.(keys_{k});
    for j = 1:numel(r.wavelengths)
        if r.wavelengths(j) <= 430
            globalIso(end+1) = struct('name', r.streams{j}, 'wavelength', r.wavelengths(j)); %#ok<AGROW>
        end
    end
end

chans = struct('region', {}, 'isoStream', {}, 'sigStream', {}, ...
                'isoWavelength', {}, 'sigWavelength', {}, 'band', {}, 'label', {});
for k = 1:numel(keys_)
    r = regions.(keys_{k});
    isoIdxLocal = find(r.wavelengths <= 430);
    sigIdxLocal = find(r.wavelengths > 430);
    if isempty(sigIdxLocal)
        continue % nothing to pair as a signal channel in this region
    end
    [~, best] = max(r.wavelengths(sigIdxLocal)); % one signal per region; take the longest wavelength if several
    sigIdx = sigIdxLocal(best);

    if ~isempty(isoIdxLocal)
        [~, bestIso] = min(r.wavelengths(isoIdxLocal));
        isoName = r.streams{isoIdxLocal(bestIso)};
        isoWl = r.wavelengths(isoIdxLocal(bestIso));
    elseif ~isempty(globalIso)
        isoName = globalIso(1).name; % shared isosbestic, borrowed from another region
        isoWl = globalIso(1).wavelength;
    else
        continue % no isosbestic anywhere -- can't correct this signal
    end

    c = struct();
    c.region = r.region;
    c.isoStream = isoName;
    c.sigStream = r.streams{sigIdx};
    c.isoWavelength = isoWl;
    c.sigWavelength = r.wavelengths(sigIdx);
    if c.sigWavelength < 500
        c.band = 'green';
    else
        c.band = 'red';
    end
    c.label = c.band;
    chans(end+1) = c; %#ok<AGROW>
end
end

function [zall, traw, t] = tms_epoch_and_zscore(sig, fs, onsets_sec, pre_s, post_s, baselineWindow)
% baselineWindow - [start end], seconds relative to each trial's onset
% (typically both <= 0, e.g. [-2 0]) -- the window each trial's z-score
% mean/std is computed over.
sig = sig(:)';
pre  = round(pre_s  * fs);
post = round(post_s * fs);
blStartOffset = round(baselineWindow(1) * fs); % samples relative to onset (usually negative)
blEndOffset   = round(baselineWindow(2) * fs);

onset_idx = round(onsets_sec(:) * fs) + 1;
keep = (onset_idx - pre >= 1) & (onset_idx + post <= numel(sig));
onset_idx = onset_idx(keep);

n = numel(onset_idx);
npts = pre + post + 1;
zall = nan(n, npts);
traw = nan(n, npts);

for i = 1:n
    idx0 = onset_idx(i);
    window = sig(idx0 - pre : idx0 + post);
    traw(i, :) = window;
    blwin = sig(idx0 + blStartOffset : idx0 + blEndOffset);
    zb = mean(blwin);
    zsd = std(blwin);
    if zsd == 0 || isnan(zsd)
        zsd = eps;
    end
    zall(i, :) = (window - zb) / zsd;
end

t = linspace(-pre_s, post_s, npts);
end

function tms_equalize_yspan(axArray)
% Give every axes the same y-axis SPAN (max of their auto-scaled spans),
% each still centered on its own data so different baseline offsets
% between panels are preserved -- only the scale factor is matched.
lims = cell2mat(arrayfun(@(a) ylim(a), axArray, 'UniformOutput', false)');
spans = lims(:,2) - lims(:,1);
commonSpan = max(spans);
for k = 1:numel(axArray)
    center = mean(lims(k,:));
    ylim(axArray(k), [center - commonSpan/2, center + commonSpan/2]);
end
end

function [mat, t] = tms_stack_traces(resultsSubset)
% Stack each result's per-subject mean trace into one [nSubjects x
% nTimepoints] matrix, truncating to the shortest common length in case
% the measured sample rate drifted slightly between sessions.
traces = arrayfun(@(r) mean(r.zall, 1, 'omitnan'), resultsSubset, 'UniformOutput', false);
minLen = min(cellfun(@numel, traces));
mat = cell2mat(cellfun(@(v) v(1:minLen), traces, 'UniformOutput', false)');
t = resultsSubset(1).t(1:minLen);
end

function [meanTrace, semTrace] = tms_mean_sem(mat)
meanTrace = mean(mat, 1, 'omitnan');
n = sum(~isnan(mat(:,1)));
semTrace = std(mat, 0, 1, 'omitnan') / sqrt(max(n,1));
end

function tms_plot_area_sem(ax, t, mat, color_line, color_area, lineName)
% mat - [nSubjects x nTime] per-subject mean traces (drives mean+/-SEM)
hold(ax, 'on');
[m, e] = tms_mean_sem(mat);
xv = [t, fliplr(t)];
yv = [m+e, fliplr(m-e)];
patch(ax, xv, yv, color_area, 'EdgeColor', 'none', 'FaceAlpha', 0.45, 'HandleVisibility', 'off');
plot(ax, t, m, 'Color', color_line, 'LineWidth', 2, 'DisplayName', lineName);
end

function tms_sig_bracket(ax, x1, x2, y, label, span)
tickH = 0.03 * span;
plot(ax, [x1 x1 x2 x2], [y-tickH y y y-tickH], 'Color', 'k', 'LineWidth', 1, 'HandleVisibility', 'off');
% A small explicit gap above the bracket line (rather than sitting right
% on it) keeps the label glyphs from visually merging into the line at
% small font sizes.
text(ax, mean([x1 x2]), y + 0.05*span, label, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 9, 'FontWeight', 'bold');
end

function s = tms_stars(p)
if isnan(p)
    s = 'n/a';
elseif p < 0.001
    s = '***';
elseif p < 0.01
    s = '**';
elseif p < 0.05
    s = '*';
else
    s = 'ns';
end
end

function s = tms_sem(v)
v = v(~isnan(v));
if numel(v) < 1
    s = NaN;
else
    s = std(v) / sqrt(numel(v));
end
end

function tms_build_report(results, subjects, sessionLabels, aucWin1, aucWin2, out_pdf, parent_name, trangePost, baselineWindow, marginIn, wholeSession, wholeSessionPairs)
% Page order: every group-level figure page first -- per channel, TMS vs
% Sham (summary + whole-session); then, for every pair of channels, channel
% vs channel within TMS and within Sham (summary + whole-session) -- then
% the per-animal raw QC pages, then every statistics page at the very back.
if exist(out_pdf, 'file')
    delete(out_pdf);
end

channels = unique({results.channel}, 'stable');
aucWins = {aucWin1, aucWin2};
shamGrey = tms_sham_grey(false);
statsQueue = {}; % statistics pages, written last in this order

% --- Per channel: TMS vs Sham ---
for ci = 1:numel(channels)
    chLabel = channels{ci};
    chResults = results(strcmp({results.channel}, chLabel));
    A = struct('name', 'Sham', 'short', 'Sham', 'color', shamGrey, 'results', chResults(strcmp({chResults.group}, 'sham')));
    B = struct('name', 'TMS', 'short', 'TMS', 'color', tms_channel_color(chLabel), 'results', chResults(strcmp({chResults.group}, 'tms')));
    statsList = tms_run_channel_stats(chResults, subjects, sessionLabels, trangePost, aucWin1, aucWin2);
    tms_build_summary_page(A, B, statsList, sprintf('%s -- %s -- TMS vs Sham', parent_name, chLabel), ...
        sessionLabels, aucWins, baselineWindow, 'session', out_pdf, marginIn);
    wsBlocks = {};
    wsIdx = find(strcmp({wholeSession.channel}, chLabel), 1);
    if ~isempty(wsIdx)
        ws = wholeSession(wsIdx);
        tms_build_whole_session_page(tms_ws_spec_groups(ws, parent_name), sessionLabels, out_pdf, marginIn);
        wsBlocks = tms_stats_blocks_ws_groups(ws);
    end
    statsQueue{end+1} = struct('header', sprintf('%s -- TMS vs Sham', chLabel), ...
        'blocks', {[tms_stats_blocks_train(statsList, 'groups'), wsBlocks]}); %#ok<AGROW>
end

% --- Every pair of channels, compared within TMS and within Sham ---
groupDefs = {'tms', 'TMS'; 'sham', 'Sham'};
for a = 1:numel(channels) - 1
    for b = a+1:numel(channels)
        for g = 1:size(groupDefs, 1)
            grp = groupDefs{g, 1};
            rA = results(strcmp({results.channel}, channels{a}) & strcmp({results.group}, grp));
            rB = results(strcmp({results.channel}, channels{b}) & strcmp({results.group}, grp));
            if isempty(rA) || isempty(rB)
                continue
            end
            [colA, colB] = tms_pair_colors(channels{a}, channels{b}, grp);
            A = struct('name', channels{a}, 'short', tms_short_label(channels{a}), 'color', colA, 'results', rA);
            B = struct('name', channels{b}, 'short', tms_short_label(channels{b}), 'color', colB, 'results', rB);
            pairTitle = sprintf('%s: %s vs %s', groupDefs{g, 2}, channels{a}, channels{b});
            statsList = tms_run_pair_stats(A, B, sessionLabels, trangePost, aucWin1, aucWin2);
            tms_build_summary_page(A, B, statsList, sprintf('%s -- %s', parent_name, pairTitle), ...
                sessionLabels, aucWins, baselineWindow, 'series', out_pdf, marginIn);
            wsBlocks = {};
            pIdx = find(strcmp({wholeSessionPairs.group}, grp) & ...
                        cellfun(@(c) isequal(c, channels([a b])), {wholeSessionPairs.channels}), 1);
            if ~isempty(pIdx)
                pr = wholeSessionPairs(pIdx);
                tms_build_whole_session_page(tms_ws_spec_pair(pr, A, B, parent_name, pairTitle), sessionLabels, out_pdf, marginIn);
                wsBlocks = tms_stats_blocks_ws_pair(pr, A.short, B.short, groupDefs{g, 2});
            end
            statsQueue{end+1} = struct('header', pairTitle, ...
                'blocks', {[tms_stats_blocks_train(statsList, 'channels'), wsBlocks]}); %#ok<AGROW>
        end
    end
end

% --- Per-animal raw QC pages, every channel ---
bottomMarginIn = marginIn + 0.75; % see the matching note in tms_build_summary_page
grayColor = shamGrey;
for ci = 1:numel(channels)
    chLabel = channels{ci};
    chResults = results(strcmp({results.channel}, chLabel));
    tmsColor = tms_channel_color(chLabel);
    % --- Raw QC page(s): full isosbestic-corrected trace per subject/session ---
    % exportgraphics silently caps page HEIGHT somewhere between 18in and
    % 18.5in (confirmed empirically: a bare figure taller than that comes
    % back with /MediaBox stuck at a fixed height regardless of how much
    % taller was requested, independent of Resolution or width) -- so a
    % cohort with enough subjects to need more than ~18in at 2in/subject
    % must be split across multiple QC pages rather than growing one
    % figure past that cap.
    subjNames = unique({chResults.subject}, 'stable');
    nSubj = numel(subjNames);
    maxSubjPerQcPage = 8; % 8 x 2in/subject = 16in, safely under the ~18in cap
    page2W = 16; % inches
    nQcPages = ceil(nSubj / maxSubjPerQcPage);
    for pageIdx = 1:nQcPages
        pageSubjIdx = (pageIdx-1)*maxSubjPerQcPage + 1 : min(pageIdx*maxSubjPerQcPage, nSubj);
        pageSubjNames = subjNames(pageSubjIdx);
        nSubjThisPage = numel(pageSubjNames);
        page2H = max(3, 2*nSubjThisPage); % inches
        fig2 = tms_page_figure(page2W, page2H);
        tl2 = tiledlayout(fig2, nSubjThisPage, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
        tl2.OuterPosition = [marginIn/page2W, bottomMarginIn/page2H, 1 - 2*marginIn/page2W, 1 - (marginIn + bottomMarginIn)/page2H];
        titleStr = sprintf('%s -- %s -- raw isosbestic-corrected traces (QC)', parent_name, chLabel);
        if nQcPages > 1
            titleStr = sprintf('%s (%d/%d)', titleStr, pageIdx, nQcPages);
        end
        title(tl2, titleStr, 'Interpreter', 'none');
        for si = 1:nSubjThisPage
            name = pageSubjNames{si};
            grp = groupOfSafe(subjects, name);
            col = grayColor; if strcmp(grp, 'tms'), col = tmsColor; end
            rowAxes = gobjects(1, 2);
            rowOnsets = cell(1, 2);
            for s = 1:2
                ax = nexttile(tl2);
                rowAxes(s) = ax;
                r = chResults(strcmp({chResults.subject}, name) & strcmp({chResults.session}, sessionLabels{s}));
                if isempty(r)
                    axis(ax, 'off');
                    continue
                end
                r = r(1);
                % Mildly decimated (a full session at ~100Hz is 70,000+ points
                % per line) -- same vector-complexity concern as the trial
                % overlays on page 1, and imperceptible for a QC trace.
                dsIdx = 1:3:numel(r.fullTrace_sig);
                plot(ax, r.fullTrace_t(dsIdx), r.fullTrace_sig(dsIdx), 'Color', col, 'LineWidth', 0.5);
                hold(ax, 'on');
                % The first ~10s often carries a large settling
                % transient/artifact from the isosbestic fit or recording
                % onset -- it's still drawn in full (not cropped from the
                % data), but the y-axis autoscale is computed on data from
                % 10s onward only, so that early spike can't force the
                % whole trace into a huge, dynamics-flattening scale. A
                % trace whose spike exceeds this range just runs off the
                % top/bottom of the panel rather than being hidden.
                stableMask = r.fullTrace_t >= 10;
                if any(stableMask)
                    stableData = r.fullTrace_sig(stableMask);
                    stLo = min(stableData); stHi = max(stableData);
                    stPad = 0.05 * (stHi - stLo);
                    if stPad == 0 || isnan(stPad), stPad = 1; end
                    ylim(ax, [stLo - stPad, stHi + stPad]);
                end
                rowOnsets{s} = r.trainOnsets;
                title(ax, sprintf('%s (%s) -- %s', name, grp, sessionLabels{s}), 'FontSize', 8, 'Interpreter', 'none');
                box(ax, 'off');
                set(ax, 'TickDir', 'out');
                xlim(ax, [0 780]);
                xticks(ax, 0:60:780);
                if si == nSubjThisPage
                    xlabel(ax, 'Time (s)');
                end
            end
            % Match the y-axis SCALE within this subject's row so First and
            % Tenth are directly comparable. tms_equalize_yspan only ever
            % WIDENS a panel to the larger of the two spans (re-centered on its
            % own data), so neither trace can end up cut off.
            validRow = rowAxes(arrayfun(@(a) isgraphics(a) && strcmp(get(a,'Visible'),'on'), rowAxes));
            if numel(validRow) == 2
                tms_equalize_yspan(validRow);
            end
            % Train-onset markers are drawn last, against each panel's FINAL
            % y-limits, so they span the full panel height after rescaling.
            for s = 1:2
                if isempty(rowOnsets{s}) || ~isgraphics(rowAxes(s))
                    continue
                end
                ax = rowAxes(s);
                yl = ylim(ax);
                for tr = 1:numel(rowOnsets{s})
                    plot(ax, [rowOnsets{s}(tr) rowOnsets{s}(tr)], yl, 'Color', [0.8 0.8 0.8 0.4], 'LineWidth', 0.3);
                end
                ylim(ax, yl); % the marker lines must not re-expand the axis
            end
        end
        tms_export_letter_page(fig2, out_pdf, 200, marginIn);
        close(fig2);
    end
end

% --- Every statistics page, at the very back ---
for k = 1:numel(statsQueue)
    tms_write_stats_pages(statsQueue{k}.blocks, statsQueue{k}.header, out_pdf, parent_name, marginIn);
end
end

function c = tms_channel_color(label)
% TMS traces take their channel's cell-type colour from SV's palette
% (E:\MATLAB_Software\Colour palette - swatches.png): SST Orange #CF6721,
% PV Yellow #F7AB03; any other construct falls back to TMS Blue #64A3D8.
if ~isempty(regexp(label, '\<SST\>', 'once'))
    c = [207 103 33] / 255;
elseif ~isempty(regexp(label, '\<PV\>', 'once'))
    c = [247 171 3] / 255;
else
    c = [100 163 216] / 255;
end
end

function c = tms_sham_grey(dark)
% Sham is always Control Grey #808080; the darker #404040 is only for the
% second of two Sham series drawn together (Sham: channel vs channel).
if dark
    c = [64 64 64] / 255;
else
    c = [128 128 128] / 255;
end
end

function [colA, colB] = tms_pair_colors(labelA, labelB, grp)
% TMS: each channel in its own colour. Sham: both grey, and the channel
% whose TMS colour is darker (SST orange vs PV yellow) gets the darker grey,
% so the light/dark pairing reads the same way on the TMS and Sham pages.
colA = tms_channel_color(labelA);
colB = tms_channel_color(labelB);
if strcmp(grp, 'sham')
    lum = @(c) c * [0.2126; 0.7152; 0.0722];
    if lum(colA) <= lum(colB)
        colA = tms_sham_grey(true);
        colB = tms_sham_grey(false);
    else
        colA = tms_sham_grey(false);
        colB = tms_sham_grey(true);
    end
end
end

function s = tms_short_label(label)
% 'SST [jRGECO1a]' -> 'SST' (bar labels and legends have little room)
s = strtrim(regexprep(label, '\s*\[[^\]]*\]', ''));
if isempty(s)
    s = label;
end
end

function tms_build_summary_page(A, B, statsList, pageTitle, sessionLabels, aucWins, baselineWindow, pairing, out_pdf, marginIn)
% Fig1(F/G/H/I)-style summary page for any two series A and B -- Sham vs
% TMS on a channel's own page, or channel vs channel within one group.
% A, B: struct('name', 'short', 'color', 'results'), results being that
% series' per-train entries from both sessions.
% pairing - how the AUC panels pair up animals:
%   'session': bars A-First, A-Tenth, B-First, B-Tenth; each animal's
%              First->Tenth joined; brackets test First vs Tenth per series
%   'series':  bars A-First, B-First, A-Tenth, B-Tenth; each animal's A->B
%              joined (the same animals in both series -- two channels
%              recorded at once); brackets test A vs B per session
baselineColor = [0.45 0.45 0.45 0.55]; % translucent gray line
baselineTextColor = [0.5 0.5 0.5];     % text has no alpha channel, so a light gray stands in
% baselineWindow ([start end] s, relative to train onset) is exactly what
% tms_epoch_and_zscore used, so the marker always matches the chosen baseline.

% OuterPosition (not Position) is what includes the axis labels, tick
% labels and layout title -- setting Position instead leaves those
% drawn outside the box, where the page edge clips them.
page1W = 14; page1H = 10; % inches
% Extra bottom margin beyond marginIn, kept from when exportgraphics was
% clipping this edge -- now just whitespace below the figure on the page.
bottomMarginIn = marginIn + 0.75;
fig = tms_page_figure(page1W, page1H);
tl = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
tl.OuterPosition = [marginIn/page1W, bottomMarginIn/page1H, 1 - 2*marginIn/page1W, 1 - (marginIn + bottomMarginIn)/page1H];
title(tl, pageTitle, 'Interpreter', 'none');

% --- Panels 1-2: mean+/-SEM z-scored trace, First and Tenth, A vs B overlaid ---
series = {A, B};
traceAxes = gobjects(1, 2);
pulseRel = cell(1, 2);
for s = 1:2
    ax = nexttile(tl, s);
    traceAxes(s) = ax;
    envLo = []; envHi = [];
    for k = 1:2
        S = series{k};
        r = S.results(strcmp({S.results.session}, sessionLabels{s}));
        if isempty(r), continue; end
        pulseRel{s} = [pulseRel{s}; vertcat(r.pulseRelTimes)];
        [mat, t] = tms_stack_traces(r);
        tms_plot_area_sem(ax, t, mat, S.color, S.color, sprintf('%s (n=%d)', S.name, numel(r)));
        [m, e] = tms_mean_sem(mat);
        envLo = [envLo, min(m - e)]; envHi = [envHi, max(m + e)]; %#ok<AGROW>
    end

    % Scale the view to the mean+/-SEM envelope, with extra room at the
    % bottom for the baseline/pulse row.
    if ~isempty(envLo)
        lo = min(envLo); hi = max(envHi);
        rng = hi - lo;
        if rng == 0 || isnan(rng), rng = 1; end
        ylim(ax, [lo - 0.30*rng, hi + 0.15*rng]);
    end

    statEntry = tms_find_stat(statsList, sprintf('trace_s%d', s));
    if isnan(statEntry.p)
        statTxt = sprintf('%s vs %s: %s', A.short, B.short, statEntry.stars);
    else
        statTxt = sprintf('%s vs %s: %s (p=%.3f)', A.short, B.short, statEntry.stars, statEntry.p);
    end
    % Carried as an invisible line so the significance result reads as
    % a legend row instead of floating text over the data.
    plot(ax, NaN, NaN, 'LineStyle', 'none', 'Marker', 'none', 'DisplayName', statTxt);

    xline(ax, 0, '--', 'Color', [0.6 0.6 0.6], 'HandleVisibility', 'off');
    xlabel(ax, 'Time from TBS onset (s)');
    ylabel(ax, 'Z-score');
    title(ax, sprintf('%s session', sessionLabels{s}));
    legend(ax, 'Location', 'northeast');
    box(ax, 'off');
    set(ax, 'TickDir', 'out');
end
% Same y-axis SCALE (span) for First and Tenth, each keeping its own center.
tms_equalize_yspan(traceAxes);

% Baseline window and the pooled TMS pulse times share one row near the
% bottom of the (now final) axis.
for s = 1:2
    ax = traceAxes(s);
    yl = ylim(ax);
    yRow = yl(1) + 0.07 * diff(yl);
    plot(ax, baselineWindow, [yRow yRow], 'Color', baselineColor, 'LineWidth', 1.2, 'HandleVisibility', 'off');
    text(ax, mean(baselineWindow), yRow + 0.02*diff(yl), 'Baseline', ...
         'Color', baselineTextColor, 'FontSize', 7, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
    % Rounding to 20ms and unique() collapses the tens of thousands of
    % near-identical pooled pulse hits to the handful of distinct times.
    pulseTimes = unique(round(pulseRel{s} / 0.02) * 0.02);
    if ~isempty(pulseTimes)
        plot(ax, pulseTimes, yRow * ones(size(pulseTimes)), '|', 'Color', [0.15 0.45 0.75 0.6], 'MarkerSize', 5, 'HandleVisibility', 'off');
        text(ax, mean(pulseTimes), yRow + 0.02*diff(yl), 'TMS pulses', ...
             'Color', [0.1 0.35 0.65], 'FontSize', 7, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
    end
end

% --- Panels 3-4: AUC bar+scatter for each AUC window ---
aucFields = {'auc1', 'auc2'};
aucAxes = gobjects(1, 2);
namesA = unique({A.results.subject}, 'stable');
namesB = unique({B.results.subject}, 'stable');
if strcmp(pairing, 'series')
    namesA = intersect(namesA, namesB, 'stable');
    namesB = namesA;
end
for w = 1:2
    ax = nexttile(tl, 2+w);
    aucAxes(w) = ax;
    getAuc = @(R, names, sess) arrayfun(@(k) local_mean_auc(R, names{k}, sess, aucFields{w}), 1:numel(names));
    aF = getAuc(A.results, namesA, sessionLabels{1});
    aT = getAuc(A.results, namesA, sessionLabels{2});
    bF = getAuc(B.results, namesB, sessionLabels{1});
    bT = getAuc(B.results, namesB, sessionLabels{2});
    p1 = tms_find_stat(statsList, sprintf('auc%d_pair1', w)).p;
    p2 = tms_find_stat(statsList, sprintf('auc%d_pair2', w)).p;
    if strcmp(pairing, 'session')
        vals = {aF, aT, bF, bT};
        colors = {A.color, A.color, B.color, B.color};
        xLabels = {[A.short '-' sessionLabels{1}], [A.short '-' sessionLabels{2}], [B.short '-' sessionLabels{1}], [B.short '-' sessionLabels{2}]};
        lineColors = {A.color, B.color};
    else
        vals = {aF, bF, aT, bT};
        colors = {A.color, B.color, A.color, B.color};
        xLabels = {[A.short '-' sessionLabels{1}], [B.short '-' sessionLabels{1}], [A.short '-' sessionLabels{2}], [B.short '-' sessionLabels{2}]};
        lineColors = {[0.6 0.6 0.6], [0.6 0.6 0.6]};
    end
    tms_auc_bar_scatter(ax, xLabels, vals, colors, lineColors, p1, p2);
    title(ax, sprintf('AUC %g-%gs', aucWins{w}(1), aucWins{w}(2)));
end
% Same y-axis SCALE between the two AUC windows too.
tms_equalize_yspan(aucAxes);

% Drawn at 14x10in as designed, then scaled as a whole onto an 8.5x11in
% portrait page (see tms_export_letter_page).
tms_export_letter_page(fig, out_pdf, 300, marginIn);
close(fig);
end

function tms_auc_bar_scatter(ax, xLabels, vals, colors, lineColors, p1, p2)
% Four bars (mean +/- SEM) with every animal's value on top. Bars 1-2 and
% bars 3-4 are each a paired comparison -- vals{1}(k)/vals{2}(k) and
% vals{3}(k)/vals{4}(k) are the same animal, joined by a line in
% lineColors{1} / lineColors{2} -- with a significance bracket over each
% pair (p1, p2: the exact comparisons tms_run_*_stats ran).
hold(ax, 'on');
xpos = [1 2 3.5 4.5];
means = cellfun(@(v) mean(v, 'omitnan'), vals);
sems  = cellfun(@tms_sem, vals);
for i = 1:4
    bar(ax, xpos(i), means(i), 0.6, 'FaceColor', colors{i}, 'FaceAlpha', 0.25, 'EdgeColor', colors{i}, 'HandleVisibility', 'off');
    errorbar(ax, xpos(i), means(i), sems(i), 'Color', colors{i}, 'LineStyle', 'none', 'LineWidth', 1.5, 'HandleVisibility', 'off');
end

pairs = {[1 2], [3 4]};
for q = 1:2
    i1 = pairs{q}(1); i2 = pairs{q}(2);
    for k = 1:numel(vals{i1})
        plot(ax, xpos([i1 i2]), [vals{i1}(k) vals{i2}(k)], '-', 'Color', [lineColors{q} 0.5], 'HandleVisibility', 'off');
    end
    for i = [i1 i2]
        plot(ax, repmat(xpos(i), size(vals{i})), vals{i}, 'o', 'LineStyle', 'none', 'MarkerFaceColor', colors{i}, ...
             'MarkerEdgeColor', 'none', 'MarkerSize', 4, 'HandleVisibility', 'off');
    end
end

set(ax, 'XTick', xpos, 'XTickLabel', xLabels);
box(ax, 'off');
set(ax, 'TickDir', 'out');
ylabel(ax, 'AUC');

% Significance bracket over each paired comparison.
allVals = cell2mat(cellfun(@(v) v(:)', vals, 'UniformOutput', false));
allTop = [means + sems, allVals];
allTop = allTop(~isnan(allTop));
span = max(allTop) - min([means - sems, allTop]);
if isempty(span) || span == 0 || isnan(span), span = 1; end
pad = 0.10 * span;
pVals = [p1, p2];
for q = 1:2
    i1 = pairs{q}(1); i2 = pairs{q}(2);
    yTop = max([vals{i1}(:); vals{i2}(:); means(i1)+sems(i1); means(i2)+sems(i2)], [], 'omitnan') + pad;
    tms_sig_bracket(ax, xpos(i1), xpos(i2), yTop, tms_stars(pVals(q)), span);
end
end

function statsList = tms_run_pair_stats(A, B, sessionLabels, trangePost, aucWin1, aucWin2)
% Every stat on a channel-vs-channel summary page (one group, e.g. TMS:
% SST vs PV). Both series are the SAME animals -- the channels are recorded
% at the same time -- so every test is paired:
%   trace_s1, trace_s2      -- A vs B within a session, full post-onset AUC
%   auc<w>_pair1 / _pair2   -- A vs B in the First / Tenth session, on the
%                              AUC_WIN1/AUC_WIN2 windows (the bar pairs)
names = intersect(unique({A.results.subject}, 'stable'), unique({B.results.subject}, 'stable'), 'stable');
getVec = @(R, sess, field) arrayfun(@(k) local_mean_auc(R, names{k}, sess, field), 1:numel(names));
pairedJust = ['Same animals, both channels recorded at the same time -- Wilcoxon signed-rank test, the paired ' ...
              'nonparametric test.'];
statsList = struct('key', {}, 'panel', {}, 'comparison', {}, 'test', {}, 'n1', {}, 'n2', {}, 'p', {}, 'stat', {}, 'stars', {}, 'justification', {});
for s = 1:2
    x = getVec(A.results, sessionLabels{s}, 'aucFull');
    y = getVec(B.results, sessionLabels{s}, 'aucFull');
    [p, stat] = tms_safe_signrank(x, y);
    statsList(end+1) = struct('key', sprintf('trace_s%d', s), 'panel', sprintf('%s session trace', sessionLabels{s}), ...
        'comparison', sprintf('%s vs %s, full post-onset AUC (0-%gs) (paired)', A.short, B.short, trangePost), ...
        'test', 'Wilcoxon signed-rank', 'n1', numel(x), 'n2', numel(y), 'p', p, 'stat', stat, ...
        'stars', tms_stars(p), 'justification', pairedJust); %#ok<AGROW>
end
aucFields = {'auc1', 'auc2'};
aucWins = {aucWin1, aucWin2};
for w = 1:2
    for s = 1:2
        x = getVec(A.results, sessionLabels{s}, aucFields{w});
        y = getVec(B.results, sessionLabels{s}, aucFields{w});
        [p, stat] = tms_safe_signrank(x, y);
        statsList(end+1) = struct('key', sprintf('auc%d_pair%d', w, s), ...
            'panel', sprintf('AUC %g-%gs panel', aucWins{w}(1), aucWins{w}(2)), ...
            'comparison', sprintf('%s: %s vs %s (paired)', sessionLabels{s}, A.short, B.short), ...
            'test', 'Wilcoxon signed-rank', 'n1', numel(x), 'n2', numel(y), 'p', p, 'stat', stat, ...
            'stars', tms_stars(p), 'justification', pairedJust); %#ok<AGROW>
    end
end
end

function pairs = tms_whole_session_pairs(ws)
% Channel-vs-channel versions of the whole-session analysis, within each
% group (e.g. TMS: SST vs PV; Sham: SST vs PV), for every pair of channels.
% Both channels come from the same animals at the same time, so rows are
% matched by animal and Channel is a within-animal factor.
pairs = struct('group', {}, 'channels', {}, 'sessionLabels', {}, 'subjects', {}, 'blSec', {}, 'binEdgesMin', {}, ...
               'binLabels', {}, 'tMin', {}, 'onsetsMin', {}, 'traces', {}, 'auc', {}, 'stats', {});
for a = 1:numel(ws) - 1
    for b = a+1:numel(ws)
        A = ws(a);
        B = ws(b);
        nT = min(numel(A.tMin), numel(B.tMin)); % same recordings, so the same grid -- guard anyway
        for grp = {'tms', 'sham'}
            names = intersect(A.subjects(strcmp(A.groups, grp{1})), B.subjects(strcmp(B.groups, grp{1})), 'stable');
            if isempty(names)
                continue
            end
            [~, ia] = ismember(names, A.subjects);
            [~, ib] = ismember(names, B.subjects);
            traces = {cellfun(@(m) m(ia, 1:nT), A.traces, 'UniformOutput', false), ...
                      cellfun(@(m) m(ib, 1:nT), B.traces, 'UniformOutput', false)};
            auc = {A.auc(ia, :, :), B.auc(ib, :, :)};
            pairs(end+1) = struct('group', grp{1}, 'channels', {{A.channel, B.channel}}, ...
                'sessionLabels', {A.sessionLabels}, 'subjects', {names}, 'blSec', A.blSec, ...
                'binEdgesMin', A.binEdgesMin, 'binLabels', {A.binLabels}, 'tMin', A.tMin(1:nT), ...
                'onsetsMin', {A.onsetsMin}, 'traces', {traces}, 'auc', {auc}, ...
                'stats', tms_whole_session_pair_stats(auc{1}, auc{2}, A.binLabels)); %#ok<AGROW>
        end
    end
end
end

function st = tms_whole_session_pair_stats(aucA, aucB, binLabels)
% Channel x Time bin, both within animals: two-way RM ANOVA, then a paired
% t-test of A vs B in each bin, Sidak-corrected across all bins.
nB = numel(binLabels);
sidak = @(p) 1 - (1 - p).^nB;
for s = 1:2
    I = tms_rm_anova_within(aucA(:, :, s), aucB(:, :, s), 'Channel');
    I.binP = nan(1, nB);
    for b = 1:nB
        I.binP(b) = sidak(tms_safe_ttest(aucA(:, b, s), aucB(:, b, s)));
    end
    st.I(s) = I;
end
end

function spec = tms_ws_spec_groups(ws, parent_name)
% Whole-session page spec for one channel: Sham vs TMS, plus Fig 2J's
% TMS-minus-Sham First vs Tenth (two tones of the channel's TMS colour,
% open vs filled markers).
isSham = strcmp(ws.groups, 'sham');
isTms  = strcmp(ws.groups, 'tms');
tmsCol = tms_channel_color(ws.channel);
darkCol = 0.6 * tmsCol;
spec.title = sprintf('%s -- %s -- TMS vs Sham -- whole-session activity (z-scored to the %gs before the first train)', ...
                     parent_name, ws.channel, ws.blSec);
spec.A = struct('name', 'Sham', 'color', tms_sham_grey(false), ...
                'traces', {{ws.traces{1}(isSham, :), ws.traces{2}(isSham, :)}}, 'auc', ws.auc(isSham, :, :));
spec.B = struct('name', 'TMS', 'color', tmsCol, ...
                'traces', {{ws.traces{1}(isTms, :), ws.traces{2}(isTms, :)}}, 'auc', ws.auc(isTms, :, :));
spec.tMin = ws.tMin;
spec.blSec = ws.blSec;
spec.binEdgesMin = ws.binEdgesMin;
spec.binLabels = ws.binLabels;
spec.onsetsMin = ws.onsetsMin;
spec.paired = false;
spec.I = ws.stats.I;
spec.J = struct('D1', ws.stats.D(:, :, 1), 'D2', ws.stats.D(:, :, 2), 'stats', ws.stats.J, ...
                'names', {ws.sessionLabels}, 'colors', {{tmsCol, darkCol}}, 'faces', {{'w', darkCol}}, ...
                'title', sprintf('TMS minus Sham -- %s vs %s', ws.sessionLabels{1}, ws.sessionLabels{2}), ...
                'ylabel', 'AUC (difference from Sham)');
end

function spec = tms_ws_spec_pair(pr, A, B, parent_name, pairTitle)
% Whole-session page spec for channel vs channel within one group -- the
% same animals in both, so the AUC-per-bin dots are joined per animal.
% No Fig 2J panel: "difference from Sham" is a TMS-vs-Sham construct.
spec.title = sprintf('%s -- %s -- whole-session activity (z-scored to the %gs before the first train)', ...
                     parent_name, pairTitle, pr.blSec);
spec.A = struct('name', A.name, 'color', A.color, 'traces', pr.traces(1), 'auc', pr.auc{1});
spec.B = struct('name', B.name, 'color', B.color, 'traces', pr.traces(2), 'auc', pr.auc{2});
spec.tMin = pr.tMin;
spec.blSec = pr.blSec;
spec.binEdgesMin = pr.binEdgesMin;
spec.binLabels = pr.binLabels;
spec.onsetsMin = pr.onsetsMin;
spec.paired = true;
spec.I = pr.stats.I;
spec.J = [];
end

function tms_build_whole_session_page(spec, sessionLabels, out_pdf, marginIn)
% One page in the style of Gongwer et al. 2026 (Cell) Fig 2H-J for two
% series A and B (see tms_ws_spec_groups / tms_ws_spec_pair): the
% whole-session mean+/-SEM trace for each session (2H), AUC per time bin for
% each session (2I) and, when spec.J is set, a Fig 2J-style difference
% panel. Drawn at the summary page's 14in width so both come out at the
% same scale -- and the same type size -- on the letter page.
hasJ = ~isempty(spec.J);
nCols = 2 + hasJ;
series = {spec.A, spec.B};

pageW = 14; pageH = 14; % inches
bottomMarginIn = marginIn + 0.75; % see the matching note in tms_build_summary_page
fig = tms_page_figure(pageW, pageH);
tl = tiledlayout(fig, 3, nCols, 'TileSpacing', 'compact', 'Padding', 'compact');
tl.OuterPosition = [marginIn/pageW, bottomMarginIn/pageH, 1 - 2*marginIn/pageW, 1 - (marginIn + bottomMarginIn)/pageH];
title(tl, spec.title, 'Interpreter', 'none');

% --- Fig 2H: the whole session, one full-width row per session ---
% v8: the window starts PRE_PAD_S before the z-score baseline, and the
% baseline is marked the way PMA_photometry_complete_SVv1.m marks it
% (drawAnnotationBar / applyRowAxes): a grey "Baseline" bar just above the
% x-axis, y-limits on a 1/2/5 x 10^k tick grid whose floor drops one more
% tick when the bar needs the room, a dashed line at the aligned event
% (t = 0, the first train), and both ends of every axis on a labeled tick.
traceAxes = gobjects(1, 2);
traceRng = nan(2, 2); % [lo hi] of each panel's mean +/- SEM
for s = 1:2
    ax = nexttile(tl, nCols*(s-1) + 1, [1 nCols]);
    traceAxes(s) = ax;
    hold(ax, 'on');
    % Train markers first, so the traces draw over them
    if ~isempty(spec.onsetsMin{s})
        xline(ax, spec.onsetsMin{s}, 'Color', [0.86 0.86 0.86], 'LineWidth', 0.5, 'HandleVisibility', 'off');
    end
    % The aligned-event line (as in the PMA script): t = 0, the first train
    xline(ax, 0, '--', 'Color', [0.6 0.6 0.6], 'LineWidth', 0.45, 'HandleVisibility', 'off');
    rngS = [Inf -Inf];
    for k = 1:2
        S = series{k};
        mat = S.traces{s};
        mat = mat(~all(isnan(mat), 2), :);
        if isempty(mat), continue; end
        [lo, hi] = tms_plot_area_sem_cols(ax, spec.tMin, mat, S.color, sprintf('%s (n=%d)', S.name, size(mat, 1)));
        rngS = [min(rngS(1), lo), max(rngS(2), hi)];
    end
    traceRng(s, :) = rngS;
    tms_set_x_ticks_on_ends(ax, [spec.tMin(1), spec.tMin(end)], spec.binEdgesMin);
    xlabel(ax, 'Time from first TBS train (min)');
    ylabel(ax, 'Z-score');
    title(ax, sprintf('%s session -- activity across the entire session', sessionLabels{s}));
    legend(ax, 'Location', 'northeast', 'Orientation', 'horizontal');
    box(ax, 'off');
    set(ax, 'TickDir', 'out');
end
% Same y SCALE for First and Tenth (as on the summary page), on a shared
% tick grid, with the legend's headroom kept at the top
[yLims, yStep, barY] = tms_trace_row_y_limits(traceRng, 0.22);
for s = 1:2
    ax = traceAxes(s);
    set(ax, 'YLim', yLims(s, :), 'YTick', yLims(s, 1):yStep:yLims(s, 2));
    tms_draw_annotation_bar(ax, [-spec.blSec 0] / 60, barY(s), [0.5 0.5 0.5], 'Baseline');
    % A small marker along the top edge of every train line (as in the
    % paper), placed against the final y-limits
    yl = ylim(ax);
    if ~isempty(spec.onsetsMin{s})
        plot(ax, spec.onsetsMin{s}, repmat(yl(2), size(spec.onsetsMin{s})), 'v', 'MarkerSize', 3, ...
             'MarkerFaceColor', [0.7 0.7 0.7], 'MarkerEdgeColor', 'none', 'Clipping', 'off', 'HandleVisibility', 'off');
    end
    ylim(ax, yl);
end

% --- Fig 2I: AUC per time bin, one panel per session, A vs B ---
binAxes = gobjects(1, 2);
for s = 1:2
    ax = nexttile(tl, 2*nCols + s);
    binAxes(s) = ax;
    YA = spec.A.auc(:, :, s);
    YB = spec.B.auc(:, :, s);
    I = spec.I(s);
    tms_binned_pair(ax, YA, YB, {spec.A.color, spec.B.color}, {spec.A.color, spec.B.color}, ...
        {sprintf('%s (n=%d)', spec.A.name, nnz(any(~isnan(YA), 2))), sprintf('%s (n=%d)', spec.B.name, nnz(any(~isnan(YB), 2)))}, ...
        spec.binLabels, spec.paired);
    plot(ax, NaN, NaN, 'LineStyle', 'none', 'Marker', 'none', 'DisplayName', tms_effect_legend_text(I.effects(1).name, I.effects(1)));
    title(ax, sprintf('%s session -- AUC per bin', sessionLabels{s}));
    ylabel(ax, 'AUC');
    xlabel(ax, 'Time (min)');
    legend(ax, 'Location', 'northwest', 'Box', 'off');
end
tms_equalize_yspan(binAxes);
for s = 1:2
    tms_bin_stars(binAxes(s), spec.A.auc(:, :, s), spec.B.auc(:, :, s), spec.I(s).binP);
end

% --- Fig 2J-style difference panel, First vs Tenth (same animals) ---
if hasJ
    J = spec.J;
    ax = nexttile(tl, 3*nCols);
    nPaired = nnz(any(~isnan(J.D1), 2) & any(~isnan(J.D2), 2));
    tms_binned_pair(ax, J.D1, J.D2, J.colors, J.faces, ...
        {sprintf('%s (n=%d)', J.names{1}, nPaired), sprintf('%s (n=%d)', J.names{2}, nPaired)}, spec.binLabels, true);
    plot(ax, NaN, NaN, 'LineStyle', 'none', 'Marker', 'none', 'DisplayName', tms_effect_legend_text(J.stats.effects(1).name, J.stats.effects(1)));
    title(ax, J.title);
    ylabel(ax, J.ylabel);
    xlabel(ax, 'Time (min)');
    legend(ax, 'Location', 'northwest', 'Box', 'off');
    tms_bin_stars(ax, J.D1, J.D2, J.stats.binP);
end

tms_export_letter_page(fig, out_pdf, 300, marginIn);
close(fig);
end

function blocks = tms_stats_blocks_train(statsList, kind)
% Statistics-page blocks for a summary page's per-train tests.
% kind: 'groups' (Sham vs TMS on one channel) or 'channels' (channel vs
% channel within one group).
if strcmp(kind, 'groups')
    method = ['All tests in this section are nonparametric. Comparisons between independent groups ' ...
        '(Sham vs TMS within one session) use the Wilcoxon rank-sum test (Mann-Whitney U). Comparisons of the ' ...
        'same animals across sessions (First vs Tenth within one group) use the Wilcoxon signed-rank test, ' ...
        'which accounts for the paired/repeated-measures design. Neither test assumes a normal distribution, ' ...
        'which photometry AUC values are not guaranteed to follow and which is not safe to assume at small n.'];
else
    method = ['All tests in this section are nonparametric. Both channels are recorded at the same time in the ' ...
        'same animals, so every comparison here is paired: the Wilcoxon signed-rank test, channel vs channel on ' ...
        'the full post-onset AUC for the trace panels, and within each session for the AUC panels (each ' ...
        'animal''s two channels joined by a line there). It does not assume a normal distribution, which is not ' ...
        'safe to assume at small n. The two channels are different indicators, each z-scored against its own ' ...
        'baseline noise, so this compares responses relative to each channel''s own noise, not absolute activity.'];
end
blocks = {[{'Per-train responses (summary page) -- method and justification:'}, tms_wrap_text(method, 95)]};
blocks{end+1} = tms_wrap_text(['Significance stars: * p<0.05, ** p<0.01, *** p<0.001, ns = not significant ' ...
    '(p>=0.05). No multiple-comparison correction is applied across the 6 per-train tests below -- treat those p-values as ' ...
    'exploratory rather than confirmatory. At very small n (e.g. n=2 per group, as in a small pilot cohort) ' ...
    'even a real effect cannot reach conventional significance thresholds -- a null result there reflects a ' ...
    'power limitation, not evidence of no effect. With n=2 vs n=2 there are only 6 possible rank orderings, ' ...
    'so only a few distinct p-values are achievable at all -- two different comparisons landing on the exact ' ...
    'same p-value by coincidence is expected at this sample size, not a sign of a computation error.'], 95);
blocks{end+1} = {'Per-train results:'};
for i = 1:numel(statsList)
    e = statsList(i);
    blk = {sprintf('[%s]', e.panel), sprintf('  %s', e.comparison)};
    if isnan(e.p)
        blk{end+1} = sprintf('  %s: p = n/a (n=%d,%d -- insufficient data, or Statistics Toolbox unavailable)', e.test, e.n1, e.n2); %#ok<AGROW>
    else
        blk{end+1} = sprintf('  %s: statistic = %.3f, p = %.4f  [%s]  (n=%d,%d)', e.test, e.stat, e.p, e.stars, e.n1, e.n2); %#ok<AGROW>
    end
    blocks{end+1} = blk; %#ok<AGROW>
end
end

function blocks = tms_stats_blocks_ws_groups(ws)
% Statistics-page blocks for a channel's whole-session page (Sham vs TMS).
nB = numel(ws.binLabels);
blocks = {[{'Whole-session activity (whole-session page) -- method and justification:'}, ...
    tms_wrap_text(sprintf(['Each session''s full isosbestic-corrected trace is z-scored ONCE against the %gs ' ...
    'immediately before its first train (not per train), so build-up or decline across the whole session ' ...
    'stays visible. AUC (z x s) is taken over that baseline epoch (BL) and each time bin. As in Gongwer et ' ...
    'al. 2026 (Cell) Fig 2I/J: two-way repeated-measures ANOVA (sphericity assumed), then per-bin ' ...
    'comparisons Sidak-corrected across all %d bins of the panel. AUC per bin: Group (Sham vs TMS, between ' ...
    'animals) x Time bin (within), with a pooled-variance t-test of Sham vs TMS in each bin. TMS minus Sham: ' ...
    'each TMS animal''s AUC minus the mean Sham AUC for the same session and bin; Session (First vs Tenth, ' ...
    'the same TMS animals) x Time bin, both within animals, with a paired t-test of First vs Tenth in each ' ...
    'bin. Unlike the per-train tests these are parametric, matching the paper''s analysis; normality cannot ' ...
    'be checked at this n, so treat them as exploratory too.'], ws.blSec, nB), 95)]};
for s = 1:2
    I = ws.stats.I(s);
    blocks{end+1} = [{sprintf('[AUC per bin -- %s session]  Sham n=%d, TMS n=%d', ws.sessionLabels{s}, I.n(1), I.n(2))}, ...
        tms_anova_lines(I.effects), {'  Sham vs TMS in each bin, Sidak-corrected:'}, ...
        tms_bin_p_lines(ws.binLabels, I.binP)]; %#ok<AGROW>
end
J = ws.stats.J;
blocks{end+1} = [{sprintf('[TMS minus Sham -- %s vs %s]  TMS n=%d (paired)', ws.sessionLabels{1}, ws.sessionLabels{2}, J.n)}, ...
    tms_anova_lines(J.effects), {sprintf('  %s vs %s in each bin, Sidak-corrected:', ws.sessionLabels{1}, ws.sessionLabels{2})}, ...
    tms_bin_p_lines(ws.binLabels, J.binP)];
end

function blocks = tms_stats_blocks_ws_pair(pr, shortA, shortB, groupName)
% Statistics-page blocks for a channel-vs-channel whole-session page.
nB = numel(pr.binLabels);
blocks = {[{'Whole-session activity (whole-session page) -- method and justification:'}, ...
    tms_wrap_text(sprintf(['Each session''s full isosbestic-corrected trace is z-scored ONCE against the %gs ' ...
    'immediately before its first train, and AUC (z x s) is taken over that baseline epoch (BL) and each time ' ...
    'bin. %s and %s are recorded at the same time in the same animals, so Channel is a within-animal factor: ' ...
    'two-way repeated-measures ANOVA, Channel x Time bin, both within animals (sphericity assumed), then a ' ...
    'paired t-test of %s vs %s in each bin, Sidak-corrected across all %d bins -- the design of Gongwer et al. ' ...
    '2026 (Cell) Fig 2I with channel in place of group. Parametric, like the paper''s analysis; treat as ' ...
    'exploratory at this n. Each channel is a different indicator z-scored against its own baseline noise, ' ...
    'so this compares responses relative to that noise, not absolute activity.'], pr.blSec, shortA, shortB, shortA, shortB, nB), 95)]};
for s = 1:2
    I = pr.stats.I(s);
    blocks{end+1} = [{sprintf('[AUC per bin -- %s, %s session]  %s vs %s, n=%d (paired)', groupName, pr.sessionLabels{s}, shortA, shortB, I.n)}, ...
        tms_anova_lines(I.effects), {sprintf('  %s vs %s in each bin, Sidak-corrected:', shortA, shortB)}, ...
        tms_bin_p_lines(pr.binLabels, I.binP)]; %#ok<AGROW>
end
end

function tms_write_stats_pages(blocks, header, out_pdf, parent_name, marginIn)
% Lays statistics blocks (a paragraph, or one test's result lines) out on
% as many 8.5x11in pages as they need, never splitting a block.
pageW = 8.5; pageH = 11; % inches, letter portrait -- easiest to read as plain text
maxLinesPerPage = 48;    % 10pt Consolas lines that fit the text area below, header included
bottomMarginIn = marginIn + 0.75; % see the matching note in tms_build_summary_page
headerLines = 3;         % title, dataset line, blank
pages = {{}};
for b = 1:numel(blocks)
    blk = [blocks{b}, {''}];
    if ~isempty(pages{end}) && headerLines + numel(pages{end}) + numel(blk) > maxLinesPerPage
        pages{end+1} = {}; %#ok<AGROW>
    end
    pages{end} = [pages{end}, blk];
end

for p = 1:numel(pages)
    titleStr = sprintf('Statistics Report -- %s', header);
    if numel(pages) > 1
        titleStr = sprintf('%s (%d/%d)', titleStr, p, numel(pages));
    end
    lines = [{titleStr, parent_name, ''}, pages{p}];

    % Text is anchored to the axis's top-left corner, so the axis rect IS
    % the text margin. The 95-character wrap width keeps the longest line
    % inside it at 10pt Consolas.
    fig = tms_page_figure(pageW, pageH);
    ax = axes(fig, 'Position', [marginIn/pageW, bottomMarginIn/pageH, 1 - 2*marginIn/pageW, 1 - (marginIn + bottomMarginIn)/pageH]);
    xlim(ax, [0 1]); ylim(ax, [0 1]);
    axis(ax, 'off');
    text(ax, 0, 1, strjoin(lines, newline), 'FontName', 'Consolas', 'FontSize', 10, ...
         'VerticalAlignment', 'top', 'Interpreter', 'none');

    % Through the same raster page export as the figure pages -- trades the
    % text being selectable/searchable for margins that come out exactly
    % as set (already letter-sized, so it is placed 1:1, not shrunk).
    tms_export_letter_page(fig, out_pdf, 200, marginIn);
    close(fig);
end
end

function fig = tms_page_figure(widthIn, heightIn)
% An invisible report figure of the designed size. R2024b still clamps an
% invisible figure's window to the display (a 16in-tall QC page came back
% 14.35in tall on a 2560x1440 screen), so the size is pinned in
% PaperPosition too -- print -RGBImage (tms_export_letter_page) renders
% that, so the page comes out as designed on any display.
fig = figure('Color', 'w', 'Units', 'inches', 'Position', [0 0 widthIn heightIn], 'Visible', 'off', ...
             'PaperUnits', 'inches', 'PaperPositionMode', 'manual', 'PaperPosition', [0 0 widthIn heightIn]);
end

function tms_export_letter_page(fig, out_pdf, srcDpi, marginIn)
% Append FIG to OUT_PDF as one 8.5x11in portrait page, shrunk to fit inside
% marginIn of the page edges (top-aligned, centered left-right) -- never
% re-laid-out. The figure is first rasterized at its own designed size
% (print -RGBImage renders the whole figure, exactly, in every release),
% which keeps every font, line width and gap in proportion; only the
% finished picture is scaled. The page is built at whatever resolution maps
% that raster 1:1 onto its fitted size, so the scaled figure keeps all the
% detail it had at srcDpi. The white page margin is part of the page image
% itself, leaving exportgraphics no blank space it could crop away.
pageW = 8.5; pageH = 11; % inches, letter portrait
img = print(fig, '-RGBImage', sprintf('-r%d', srcDpi));
[imgH, imgW, ~] = size(img);
if abs(imgW/srcDpi - pageW) < 0.01 && abs(imgH/srcDpi - pageH) < 0.01
    % Already exactly letter-sized (the stats pages) -- it carries its own
    % margins, so place it as-is rather than shrinking it inside a second set.
    pageDpi = srcDpi;
    x0 = 0;
    y0 = 0;
else
    % Only ever scale DOWN; an even dpi keeps 8.5in x dpi a whole pixel count.
    pageDpi = max([srcDpi, imgW / (pageW - 2*marginIn), imgH / (pageH - 2*marginIn)]);
    pageDpi = 2 * ceil(pageDpi / 2);
    x0 = floor((pageW * pageDpi - imgW) / 2);
    y0 = round(marginIn * pageDpi);
end
canvas = repmat(uint8(255), [round(pageH * pageDpi), round(pageW * pageDpi), 3]);
canvas(y0 + (1:imgH), x0 + (1:imgW), :) = img;

pageFig = figure('Color', 'w', 'Units', 'inches', 'Position', [0 0 pageW pageH], 'Visible', 'off');
ax = axes(pageFig, 'Units', 'normalized', 'Position', [0 0 1 1]);
image(ax, canvas);
axis(ax, 'off');
% Which ContentType puts that page image into the PDF faithfully depends on
% the release's PDF engine (each checked on real output, page by page):
%  - R2024b and earlier (Java/Apache FOP): 'image' screen-captures a region
%    a few dozen pixels smaller than the figure and stretches it over the
%    page, cutting off the bottom edge -- the long-standing "margins look
%    off" problem -- while 'vector' embeds the image at exactly its place.
%  - R2026a (Qt): 'image' is pixel-exact, while 'vector' downsamples the
%    image to screen resolution (96dpi) as a JPEG.
if isMATLABReleaseOlderThan('R2025a')
    exportgraphics(pageFig, out_pdf, 'Append', true, 'ContentType', 'vector');
else
    exportgraphics(pageFig, out_pdf, 'Append', true, 'Resolution', pageDpi, 'ContentType', 'image');
end
close(pageFig);
end

function [ws, logLines] = tms_whole_session(results, subjects, sessionLabels, blSec, binEdgesMin, smoothSec, trangePost, prePadSec)
% Whole-session analysis in the style of Gongwer et al. 2026 (Cell) Fig
% 2H-J, one entry per channel. The per-train z-scoring on the summary page
% re-baselines every train against its own pre-train window, so it is blind
% by construction to activity that builds up (or sags) across the whole
% ~10-min session. Here each session's isosbestic-corrected trace is instead
% z-scored ONCE against the blSec right before its first real train, time
% is re-zeroed to that train, and AUC is taken over that baseline epoch
% ("BL") plus each binEdgesMin bin.
% prePadSec: the display traces start this many seconds before the baseline
% window (v8) -- display only; the z-score and AUCs don't depend on it.
logLines = {};
groupOf = containers.Map({subjects.name}, {subjects.group});
nBins = numel(binEdgesMin) - 1;
binLabels = [{'BL'}, arrayfun(@(b) sprintf('%g-%g', binEdgesMin(b), binEdgesMin(b+1)), 1:nBins, 'UniformOutput', false)];
gridStep = 0.05; % s -- common display grid every animal's trace is resampled onto for the mean+/-SEM
loggedDrops = containers.Map(); % onsets are shared by every channel of a session -- log a dropped one once
channels = unique({results.channel}, 'stable');
ws = struct('channel', {}, 'sessionLabels', {}, 'subjects', {}, 'groups', {}, 'blSec', {}, 'binEdgesMin', {}, ...
            'binLabels', {}, 'auc', {}, 'tMin', {}, 'traces', {}, 'onsetsMin', {}, 'stats', {});
for ci = 1:numel(channels)
    chResults = results(strcmp({results.channel}, channels{ci}));
    subjNames = unique({chResults.subject}, 'stable');
    nSubj = numel(subjNames);
    auc = nan(nSubj, nBins + 1, 2); % subject x [BL, bins] x session
    zTraces = cell(nSubj, 2);       % [t; smoothed z] per animal, t in s from the first train
    relOnsets = cell(nSubj, 2);
    for k = 1:nSubj
        for s = 1:2
            r = chResults(strcmp({chResults.subject}, subjNames{k}) & strcmp({chResults.session}, sessionLabels{s}));
            if isempty(r) || isempty(r(1).trainOnsets)
                continue
            end
            r = r(1);
            [onsets, nDropped] = tms_regular_trains(r.trainOnsets);
            dropKey = [subjNames{k} '|' sessionLabels{s}];
            if nDropped > 0 && ~isKey(loggedDrops, dropKey)
                loggedDrops(dropKey) = true;
                logLines{end+1} = sprintf(['WHOLE-SESSION %s / %s: ignored %d isolated onset(s) before the regular ' ...
                    'train sequence (first at %.2fs, %.1fs ahead of the next train) -- session start taken as %.2fs.'], ...
                    subjNames{k}, sessionLabels{s}, nDropped, r.trainOnsets(1), onsets(1) - max(r.trainOnsets(1:nDropped)), onsets(1)); %#ok<AGROW>
            end
            t = r.fullTrace_t(:)' - onsets(1);
            if t(1) > -blSec
                logLines{end+1} = sprintf('WHOLE-SESSION SKIPPED %s / %s / %s: only %.1fs of recording before the first train (need %gs of baseline).', ...
                    subjNames{k}, sessionLabels{s}, channels{ci}, -t(1), blSec); %#ok<AGROW>
                continue
            end
            if t(1) > -(blSec + prePadSec)
                % Plot what exists: this animal's trace starts later than the
                % rest of the display window (the mean+/-SEM there is over the
                % animals that do have data).
                msg = sprintf(['WHOLE-SESSION %s / %s / %s: only %.1fs of recording before the first train -- ' ...
                    'plotting from there (PRE_PAD_S asks for %gs before the %gs baseline).'], ...
                    subjNames{k}, sessionLabels{s}, channels{ci}, -t(1), prePadSec, blSec);
                warning('%s', msg);
                logLines{end+1} = msg; %#ok<AGROW>
            end
            sig = double(r.fullTrace_sig(:)');
            blMask = t >= -blSec & t < 0;
            z = (sig - mean(sig(blMask))) / std(sig(blMask));
            auc(k, 1, s) = trapz(t(blMask), z(blMask));
            for b = 1:nBins
                lo = binEdgesMin(b) * 60;
                hi = binEdgesMin(b+1) * 60;
                if t(end) >= hi % a bin the recording doesn't fully cover stays NaN, not a truncated AUC
                    m = t >= lo & t <= hi;
                    auc(k, b+1, s) = trapz(t(m), z(m));
                end
            end
            fs = 1 / median(diff(t));
            zTraces{k, s} = [t; movmean(z, max(1, round(smoothSec * fs)))];
            relOnsets{k, s} = onsets(:)' - onsets(1);
        end
    end
    have = ~cellfun(@isempty, zTraces);
    if ~any(have(:))
        logLines{end+1} = sprintf('WHOLE-SESSION SKIPPED channel %s: no session had enough pre-session baseline.', channels{ci}); %#ok<AGROW>
        continue
    end

    % One display grid for both sessions: prePadSec before the baseline
    % start through the end of the last train's post-window (or the last
    % bin, if later), the end clipped to what every included recording
    % covers. An animal with less pre-train data than the grid's start is
    % NaN there (warned above).
    lastOnset = median(cellfun(@(o) o(end), relOnsets(have)));
    tEnd = max(binEdgesMin(end) * 60, lastOnset + trangePost);
    tEnd = min([tEnd, cellfun(@(z) z(1, end), zTraces(have))']);
    tGrid = -(blSec + prePadSec) : gridStep : tEnd;
    traces = {nan(nSubj, numel(tGrid)), nan(nSubj, numel(tGrid))};
    onsetsMin = cell(1, 2);
    for s = 1:2
        for k = find(have(:, s))'
            traces{s}(k, :) = interp1(zTraces{k, s}(1, :), zTraces{k, s}(2, :), tGrid, 'linear');
        end
        % One marker per train at the median time of the n-th train across
        % animals -- they differ by well under a second, so this reads as
        % one line per train rather than a smear of near-duplicates.
        on = relOnsets(have(:, s), s);
        if isempty(on)
            continue
        end
        M = nan(numel(on), max(cellfun(@numel, on)));
        for j = 1:numel(on)
            M(j, 1:numel(on{j})) = on{j};
        end
        onsetsMin{s} = median(M, 1, 'omitnan') / 60;
    end

    groups = cellfun(@(n) groupOf(n), subjNames, 'UniformOutput', false);
    ws(end+1) = struct('channel', channels{ci}, 'sessionLabels', {sessionLabels}, 'subjects', {subjNames}, ...
        'groups', {groups}, 'blSec', blSec, 'binEdgesMin', binEdgesMin, 'binLabels', {binLabels}, 'auc', auc, ...
        'tMin', tGrid / 60, 'traces', {traces}, 'onsetsMin', {onsetsMin}, ...
        'stats', tms_whole_session_stats(auc, groups, binLabels)); %#ok<AGROW>
end
end

function [onsets, nDropped] = tms_regular_trains(onsets)
% Drop isolated onsets at the START of a session that aren't part of the
% regular train sequence. The DCSP cohort's PC3_ epoc logs a spurious onset
% at the very start of the recording (t=0), a minute or more before the
% real first train. The per-train analysis already discards it (no room for
% a pre-train window at t=0), but a whole-session alignment would otherwise
% treat recording start as session start and leave no pre-session baseline.
onsets = sort(onsets(:))';
nDropped = 0;
if numel(onsets) < 3
    return
end
regularGap = median(diff(onsets));
while numel(onsets) >= 3 && onsets(2) - onsets(1) > 2 * regularGap
    onsets(1) = [];
    nDropped = nDropped + 1;
end
end

function st = tms_whole_session_stats(auc, groups, binLabels)
% Gongwer et al. 2026's own Fig 2I/J statistics: two-way repeated-measures
% ANOVA, then per-bin comparisons Sidak-corrected across every bin of the
% panel (p_adj = 1-(1-p)^nBins). auc is subject x bin x session.
isSham = strcmp(groups, 'sham');
isTms  = strcmp(groups, 'tms');
nB = numel(binLabels);
sidak = @(p) 1 - (1 - p).^nB;
for s = 1:2
    A = auc(:, :, s);
    I = tms_rm_anova_mixed(A(isSham, :), A(isTms, :));
    I.binP = nan(1, nB);
    for b = 1:nB
        I.binP(b) = sidak(tms_safe_ttest2(A(isSham, b), A(isTms, b)));
    end
    st.I(s) = I;
end
% Fig 2J: each TMS animal's AUC minus the mean Sham AUC for the same
% session and bin ("difference from sham"), First vs Tenth. These are the
% same TMS animals in both sessions, so Session is a within-animal factor
% here (the paper's IT-vs-PT factor in 2J was between animals).
st.D = auc(isTms, :, :) - mean(auc(isSham, :, :), 1, 'omitnan');
J = tms_rm_anova_within(st.D(:, :, 1), st.D(:, :, 2), 'Session');
J.binP = nan(1, nB);
for b = 1:nB
    J.binP(b) = sidak(tms_safe_ttest(st.D(:, b, 1), st.D(:, b, 2)));
end
st.J = J;
end

function out = tms_rm_anova_mixed(Ya, Yb)
% Two-way mixed repeated-measures ANOVA: group (rows of Ya vs rows of Yb,
% different animals) x repeated level (columns). Sphericity assumed
% (uncorrected p), as Prism reports it by default. Animals missing any
% level are dropped. NaN on failure, same contract as tms_safe_ranksum.
Ya = Ya(all(~isnan(Ya), 2), :);
Yb = Yb(all(~isnan(Yb), 2), :);
out.n = [size(Ya, 1), size(Yb, 1)];
out.effects = tms_empty_effects({'Group', 'Time bin', 'Group x Time bin'});
if min(out.n) < 1 || sum(out.n) < 3 || exist('fitrm', 'file') ~= 2
    return
end
try
    k = size(Ya, 2);
    T = array2table([Ya; Yb], 'VariableNames', arrayfun(@(j) sprintf('Y%d', j), 1:k, 'UniformOutput', false));
    T.Group = categorical([repmat({'A'}, out.n(1), 1); repmat({'B'}, out.n(2), 1)]);
    rm = fitrm(T, sprintf('Y1-Y%d ~ Group', k), 'WithinDesign', table(categorical((1:k)'), 'VariableNames', {'Bin'}));
    bt = anova(rm); % between-animals effect, tested on each animal's mean across bins
    between = cellstr(string(bt.Between));
    out.effects(1) = tms_effect_row(bt, find(strcmp(between, 'Group')), find(strcmp(between, 'Error')), 'Group');
    rt = ranova(rm, 'WithinModel', 'Bin');
    rn = rt.Properties.RowNames;
    out.effects(2) = tms_effect_row(rt, find(strcmp(rn, '(Intercept):Bin')), find(strcmp(rn, 'Error(Bin)')), 'Time bin');
    out.effects(3) = tms_effect_row(rt, find(strcmp(rn, 'Group:Bin')), find(strcmp(rn, 'Error(Bin)')), 'Group x Time bin');
catch
    out.effects = tms_empty_effects({'Group', 'Time bin', 'Group x Time bin'});
end
end

function out = tms_rm_anova_within(Y1, Y2, factorName)
% Two-way fully within-animal repeated-measures ANOVA: a two-level factor
% (Y1 vs Y2 -- e.g. First vs Tenth session, or channel vs channel -- the
% SAME animals, rows matched) x repeated level (columns). factorName only
% labels the results. Same conventions and NaN-on-failure contract as
% tms_rm_anova_mixed.
effectNames = {factorName, 'Time bin', [factorName ' x Time bin']};
keep = all(~isnan(Y1), 2) & all(~isnan(Y2), 2);
Y1 = Y1(keep, :);
Y2 = Y2(keep, :);
out.n = size(Y1, 1);
out.effects = tms_empty_effects(effectNames);
if out.n < 2 || exist('fitrm', 'file') ~= 2
    return
end
try
    k = size(Y1, 2);
    T = array2table([Y1, Y2], 'VariableNames', arrayfun(@(j) sprintf('Y%d', j), 1:2*k, 'UniformOutput', false));
    W = table(categorical([repmat({'S1'}, k, 1); repmat({'S2'}, k, 1)]), categorical([1:k, 1:k]'), ...
              'VariableNames', {'Session', 'Bin'});
    rm = fitrm(T, sprintf('Y1-Y%d ~ 1', 2*k), 'WithinDesign', W);
    rt = ranova(rm, 'WithinModel', 'Session*Bin');
    rn = rt.Properties.RowNames;
    % ('Session' is just the internal name of the two-level factor)
    out.effects(1) = tms_effect_row(rt, find(strcmp(rn, '(Intercept):Session')), find(strcmp(rn, 'Error(Session)')), effectNames{1});
    out.effects(2) = tms_effect_row(rt, find(strcmp(rn, '(Intercept):Bin')), find(strcmp(rn, 'Error(Bin)')), effectNames{2});
    out.effects(3) = tms_effect_row(rt, find(strcmp(rn, '(Intercept):Session:Bin')), find(strcmp(rn, 'Error(Session:Bin)')), effectNames{3});
catch
    out.effects = tms_empty_effects(effectNames);
end
end

function e = tms_empty_effects(names)
e = struct('name', names, 'F', NaN, 'df1', NaN, 'df2', NaN, 'p', NaN);
end

function e = tms_effect_row(tbl, rowIdx, errIdx, name)
e = tms_empty_effects({name});
if isscalar(rowIdx) && isscalar(errIdx)
    e.F = tbl.F(rowIdx);
    e.df1 = tbl.DF(rowIdx);
    e.df2 = tbl.DF(errIdx);
    e.p = tbl.pValue(rowIdx);
end
end

function p = tms_safe_ttest2(x, y)
% Pooled-variance two-sample t-test (the per-bin follow-up to a two-way RM
% ANOVA). NaN on failure, same contract as tms_safe_ranksum.
x = x(~isnan(x));
y = y(~isnan(y));
p = NaN;
if numel(x) < 2 || numel(y) < 2 || exist('ttest2', 'file') ~= 2
    return
end
try
    [~, p] = ttest2(x, y);
catch
    p = NaN;
end
end

function p = tms_safe_ttest(x, y)
% Paired t-test (x and y matched by animal). NaN on failure.
x = x(:); y = y(:);
keep = ~isnan(x) & ~isnan(y);
p = NaN;
if nnz(keep) < 2 || exist('ttest', 'file') ~= 2
    return
end
try
    [~, p] = ttest(x(keep), y(keep));
catch
    p = NaN;
end
end

function [lo, hi] = tms_plot_area_sem_cols(ax, t, mat, color, lineName)
% tms_plot_area_sem with the mean +/- SEM taken at each time point over the
% animals that have data there -- an animal with less pre-train recording
% than the display window is NaN at its start (v8) -- and identical to it
% wherever every animal has data. Returns the [lo hi] extent of the
% mean +/- SEM, which is what sets the panel's y-range.
m = mean(mat, 1, 'omitnan');
n = sum(~isnan(mat), 1);
e = std(mat, 0, 1, 'omitnan') ./ sqrt(max(n, 1));
ok = n > 0; % gaps only ever occur at the start, so this range is contiguous
tt = t(ok); m = m(ok); e = e(ok);
e(isnan(e)) = 0;
hold(ax, 'on');
patch(ax, [tt, fliplr(tt)], [m+e, fliplr(m-e)], color, 'EdgeColor', 'none', 'FaceAlpha', 0.45, 'HandleVisibility', 'off');
plot(ax, tt, m, 'Color', color, 'LineWidth', 2, 'DisplayName', lineName);
lo = min(m - e);
hi = max(m + e);
end

function [lims, step, barY] = tms_trace_row_y_limits(rngs, topRoom)
% PMA_photometry_complete_SVv1.m's rowYAxisLimits, for the First/Tenth
% trace panels together: limits on a 1/2/5 x 10^k grid (~4 increments of
% the larger panel's range), the floor at the first tick at or below the
% data, dropped one more tick if that leaves too little room for the
% Baseline bar (which goes at floor + 0.1 step). Kept from v7: the top
% leaves topRoom x range for the legend, and both panels get the same span
% (whole extra ticks split between top and bottom), each keeping its own
% centre.
rngs(:, 2) = rngs(:, 2) + topRoom * (rngs(:, 2) - rngs(:, 1));
bad = ~all(isfinite(rngs), 2) | rngs(:, 2) <= rngs(:, 1);
rngs(bad, :) = repmat([-1 1], nnz(bad), 1);
step = tms_nice_step(max(rngs(:, 2) - rngs(:, 1)) / 4);
nP = size(rngs, 1);
lims = zeros(nP, 2);
for i = 1:nP
    lo = floor(rngs(i, 1) / step) * step;
    if rngs(i, 1) - lo < 0.3 * step
        lo = lo - step;
    end
    hi = ceil(rngs(i, 2) / step) * step;
    if hi <= lo
        hi = lo + step;
    end
    lims(i, :) = [lo hi];
end
nSteps = round((lims(:, 2) - lims(:, 1)) / step);
extra = max(nSteps) - nSteps;
lims(:, 1) = lims(:, 1) - floor(extra / 2) * step;
lims(:, 2) = lims(:, 2) + ceil(extra / 2) * step;
barY = lims(:, 1) + 0.1 * step;
end

function s = tms_nice_step(v)
% Smallest of 1, 2, 5 x 10^k that is >= v (the PMA script's niceStep).
if ~(v > 0)
    s = 1;
    return
end
p = 10^floor(log10(v));
s = 10 * p;
for m = [1 2 5]
    if m * p >= v
        s = m * p;
        return
    end
end
end

function tms_set_x_ticks_on_ends(ax, xl, tickMin)
% The PMA script's setXTicksOnEnds for this minutes axis: ticks at the bin
% edges plus both window ends, all labeled -- every axis starts and ends on
% a labeled tick.
xlim(ax, xl);
inner = tickMin(tickMin > xl(1) + 1e-9 & tickMin < xl(2) - 1e-9);
ticks = [xl(1), inner(:)', xl(2)];
labels = arrayfun(@(t) sprintf('%g', round(t, 2)), ticks, 'UniformOutput', false);
set(ax, 'XTick', ticks, 'XTickLabel', labels);
end

function tms_draw_annotation_bar(ax, x_range, y_pos, color, label_text)
% Copied from PMA_photometry_complete_SVv1.m's drawAnnotationBar: a thin
% horizontal bar under the trace marking a named time window, its label
% centred directly above it (trace data may sit under the label if the
% window is narrow).
if isempty(x_range) || any(isnan(x_range))
    return
end
line(ax, x_range, [y_pos y_pos], 'Color', color, 'LineWidth', 1.5, 'HandleVisibility', 'off');
if ~isempty(label_text)
    text(ax, mean(x_range), y_pos, label_text, 'Color', color, 'FontSize', 4.5, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
end
end

function tms_binned_pair(ax, YA, YB, colors, faces, names, binLabels, pairLines)
% Fig 2I/J-style per-bin dot columns: every animal as a dot, the group mean
% as a short bar with +/-SEM whiskers, A just left and B just right of each
% bin's tick. pairLines joins each animal's A and B dots (rows matched --
% the same animal in both). Leaves headroom above the data for
% tms_bin_stars and the legend.
hold(ax, 'on');
nB = numel(binLabels);
off = 0.18;
halfW = 0.12;
X = {(1:nB) - off, (1:nB) + off};
Y = {YA, YB};
if pairLines
    for b = 1:nB
        for k = 1:size(YA, 1)
            plot(ax, [X{1}(b) X{2}(b)], [YA(k, b) YB(k, b)], '-', 'Color', [0.78 0.78 0.78], ...
                 'LineWidth', 0.5, 'HandleVisibility', 'off');
        end
    end
end
for g = 1:2
    for b = 1:nB
        v = Y{g}(:, b);
        v = v(~isnan(v));
        plot(ax, repmat(X{g}(b), size(v)), v, 'o', 'MarkerSize', 5, 'MarkerEdgeColor', colors{g}, ...
             'MarkerFaceColor', faces{g}, 'LineWidth', 1, 'HandleVisibility', 'off');
        if isempty(v), continue; end
        mu = mean(v);
        plot(ax, X{g}(b) + [-halfW halfW], [mu mu], '-', 'Color', colors{g}, 'LineWidth', 1.5, 'HandleVisibility', 'off');
        errorbar(ax, X{g}(b), mu, tms_sem(v), 'Color', colors{g}, 'LineStyle', 'none', 'LineWidth', 1, 'HandleVisibility', 'off');
    end
    % Legend entry only
    plot(ax, NaN, NaN, 'o', 'MarkerSize', 5, 'MarkerEdgeColor', colors{g}, 'MarkerFaceColor', faces{g}, ...
         'LineWidth', 1, 'DisplayName', names{g});
end
yline(ax, 0, '--', 'Color', [0.75 0.75 0.75], 'HandleVisibility', 'off');
set(ax, 'XTick', 1:nB, 'XTickLabel', binLabels, 'TickDir', 'out');
xlim(ax, [0.4, nB + 0.6]);
box(ax, 'off');
allV = [YA(:); YB(:)];
allV = allV(~isnan(allV));
if ~isempty(allV)
    lo = min([allV; 0]); hi = max([allV; 0]);
    span = hi - lo;
    if span == 0, span = 1; end
    ylim(ax, [lo - 0.08*span, hi + 0.45*span]); % the top ~30% is for the stars and the legend
end
end

function tms_bin_stars(ax, YA, YB, binP)
% A short bar + stars over every bin whose Sidak-corrected p < 0.05 -- as in
% the paper, only significant bins are marked (every p, significant or
% not, is listed on the statistics page).
yl = ylim(ax);
span = diff(yl);
for b = find(binP < 0.05)
    top = max([YA(:, b); YB(:, b)], [], 'omitnan');
    yBar = top + 0.06 * span;
    plot(ax, b + [-0.18 0.18], [yBar yBar], 'k-', 'LineWidth', 1, 'HandleVisibility', 'off');
    text(ax, b, yBar + 0.01 * span, tms_stars(binP(b)), 'HorizontalAlignment', 'center', ...
         'VerticalAlignment', 'bottom', 'FontSize', 9, 'FontWeight', 'bold');
end
ylim(ax, yl);
end

function s = tms_effect_legend_text(label, e)
if isnan(e.p)
    s = sprintf('%s (RM ANOVA): n/a', label);
else
    s = sprintf('%s (RM ANOVA): %s (p=%.3f)', label, tms_stars(e.p), e.p);
end
end

function v = local_mean_auc(chResults, name, sess, field)
r = chResults(strcmp({chResults.subject}, name) & strcmp({chResults.session}, sess));
if isempty(r)
    v = NaN;
else
    v = mean(r(1).(field), 'omitnan');
end
end

function [p, stat] = tms_safe_ranksum(x, y)
% Wilcoxon rank-sum (Mann-Whitney U) for two independent groups. Returns
% NaN rather than erroring when there's nothing to test (too little data,
% or Statistics and Machine Learning Toolbox unavailable) so a stats
% failure never takes down the whole report.
x = x(~isnan(x));
y = y(~isnan(y));
p = NaN; stat = NaN;
if numel(x) < 1 || numel(y) < 1 || exist('ranksum', 'file') ~= 2
    return
end
try
    [p, ~, statsOut] = ranksum(x, y);
    if isfield(statsOut, 'ranksum')
        stat = statsOut.ranksum;
    end
catch
    p = NaN; stat = NaN;
end
end

function [p, stat] = tms_safe_signrank(x, y)
% Wilcoxon signed-rank test for paired/repeated-measures data (same
% subjects, two sessions). Same NaN-on-failure contract as tms_safe_ranksum.
x = x(:); y = y(:);
keep = ~isnan(x) & ~isnan(y);
x = x(keep); y = y(keep);
p = NaN; stat = NaN;
if numel(x) < 1 || exist('signrank', 'file') ~= 2
    return
end
try
    [p, ~, statsOut] = signrank(x, y);
    if isfield(statsOut, 'signedrank')
        stat = statsOut.signedrank;
    end
catch
    p = NaN; stat = NaN;
end
end

function statsList = tms_run_channel_stats(chResults, subjects, sessionLabels, trangePost, aucWin1, aucWin2)
% Every stat shown on report page 1, for one channel. Six tests total:
%   trace_s1, trace_s2  -- Sham vs TMS within a session (unpaired), on the
%                           full post-onset AUC -- matches the "is this
%                           session's trace different between groups"
%                           question the trace panels visualize.
%   auc<w>_pair1/_pair2 -- First vs Tenth within Sham / TMS (paired), on the
%                           AUC_WIN1/AUC_WIN2 windows -- matches the
%                           paired lines already drawn on the AUC panels.
groupOf = containers.Map({subjects.name}, {subjects.group});
subjNames = unique({chResults.subject}, 'stable');
shamNames = subjNames(cellfun(@(n) strcmp(groupOf(n), 'sham'), subjNames));
tmsNames  = subjNames(cellfun(@(n) strcmp(groupOf(n), 'tms'),  subjNames));

getVec = @(names, sess, field) arrayfun(@(k) local_mean_auc(chResults, names{k}, sess, field), 1:numel(names));

unpairedJust = ['Independent groups (different animals) -- Wilcoxon rank-sum test (Mann-Whitney U), a ' ...
                'nonparametric test that makes no assumption about the underlying distribution, appropriate ' ...
                'given the small group sizes typical of a pilot photometry cohort.'];
pairedJust = ['Same animals measured twice (First vs Tenth session) -- Wilcoxon signed-rank test, the paired ' ...
              'nonparametric analog of the paired t-test, appropriate for repeated measures on the same ' ...
              'subject without assuming normally-distributed differences.'];

statsList = struct('key', {}, 'panel', {}, 'comparison', {}, 'test', {}, 'n1', {}, 'n2', {}, 'p', {}, 'stat', {}, 'stars', {}, 'justification', {});

for s = 1:2
    x = getVec(shamNames, sessionLabels{s}, 'aucFull');
    y = getVec(tmsNames,  sessionLabels{s}, 'aucFull');
    [p, stat] = tms_safe_ranksum(x, y);
    e = struct('key', sprintf('trace_s%d', s), ...
                'panel', sprintf('%s session trace', sessionLabels{s}), ...
                'comparison', sprintf('Sham vs TMS, full post-onset AUC (0-%gs)', trangePost), ...
                'test', 'Wilcoxon rank-sum', 'n1', numel(x), 'n2', numel(y), ...
                'p', p, 'stat', stat, 'stars', tms_stars(p), 'justification', unpairedJust);
    statsList(end+1) = e; %#ok<AGROW>
end

aucFields = {'auc1', 'auc2'};
aucWins = {aucWin1, aucWin2};
for w = 1:2
    panelName = sprintf('AUC %g-%gs panel', aucWins{w}(1), aucWins{w}(2));

    xF = getVec(shamNames, sessionLabels{1}, aucFields{w});
    xL = getVec(shamNames, sessionLabels{2}, aucFields{w});
    [pS, statS] = tms_safe_signrank(xF, xL);
    eS = struct('key', sprintf('auc%d_pair1', w), 'panel', panelName, ...
                 'comparison', sprintf('Sham: %s vs %s (paired)', sessionLabels{1}, sessionLabels{2}), ...
                 'test', 'Wilcoxon signed-rank', 'n1', numel(xF), 'n2', numel(xL), ...
                 'p', pS, 'stat', statS, 'stars', tms_stars(pS), 'justification', pairedJust);
    statsList(end+1) = eS; %#ok<AGROW>

    yF = getVec(tmsNames, sessionLabels{1}, aucFields{w});
    yL = getVec(tmsNames, sessionLabels{2}, aucFields{w});
    [pT, statT] = tms_safe_signrank(yF, yL);
    eT = struct('key', sprintf('auc%d_pair2', w), 'panel', panelName, ...
                 'comparison', sprintf('TMS: %s vs %s (paired)', sessionLabels{1}, sessionLabels{2}), ...
                 'test', 'Wilcoxon signed-rank', 'n1', numel(yF), 'n2', numel(yL), ...
                 'p', pT, 'stat', statT, 'stars', tms_stars(pT), 'justification', pairedJust);
    statsList(end+1) = eT; %#ok<AGROW>
end
end

function e = tms_find_stat(statsList, key)
idx = find(strcmp({statsList.key}, key), 1);
if isempty(idx)
    e = struct('p', NaN, 'stars', 'n/a');
else
    e = statsList(idx);
end
end

function outLines = tms_wrap_text(str, width)
% Manual word-wrap for the plain-text stats page (a Consolas/monospace
% text() block has no built-in wrapping).
words = strsplit(str, ' ');
outLines = {};
cur = '';
for i = 1:numel(words)
    w = words{i};
    if isempty(cur)
        candidate = w;
    else
        candidate = [cur ' ' w];
    end
    if length(candidate) > width && ~isempty(cur)
        outLines{end+1} = cur; %#ok<AGROW>
        cur = w;
    else
        cur = candidate;
    end
end
if ~isempty(cur)
    outLines{end+1} = cur;
end
end

function lines = tms_anova_lines(effects)
lines = {};
for k = 1:numel(effects)
    e = effects(k);
    if k == 1
        lead = '  RM ANOVA  ';
    else
        lead = '            ';
    end
    if isnan(e.p)
        lines{end+1} = sprintf('%s%-20s n/a (insufficient data, or Statistics Toolbox unavailable)', lead, [e.name ':']); %#ok<AGROW>
    else
        lines{end+1} = sprintf('%s%-20s F(%d,%d) = %.3f, p = %.4f  [%s]', lead, [e.name ':'], e.df1, e.df2, e.F, e.p, tms_stars(e.p)); %#ok<AGROW>
    end
end
end

function lines = tms_bin_p_lines(binLabels, binP)
% Three bins per line, e.g. "BL    p=0.8123 [ns]    0-2   p=0.0412 [*]"
cells = cell(1, numel(binLabels));
for b = 1:numel(binLabels)
    if isnan(binP(b))
        cells{b} = sprintf('%-5s p=n/a', binLabels{b});
    else
        cells{b} = sprintf('%-5s p=%.4f %-5s', binLabels{b}, binP(b), ['[' tms_stars(binP(b)) ']']);
    end
end
lines = {};
for b = 1:3:numel(cells)
    lines{end+1} = ['    ' strjoin(cells(b:min(b+2, end)), '    ')]; %#ok<AGROW>
end
end

function g = groupOfSafe(subjects, name)
idx = find(strcmp({subjects.name}, name), 1);
if isempty(idx)
    g = 'unknown';
else
    g = subjects(idx).group;
end
end
