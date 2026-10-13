% ====================================================================== %
% PMA_photometry_complete_SVv1.m
%
% SV 9/8/26: Consolidated entry point merging what used to be two
% separate scripts:
%   - run_PMA_photometry_batch_multiday_SVv1.m (raw TDT processing for a
%     batch of day folders x behaviors x variants - now runBatchMode())
%   - run_PMA_photometry_compare_traces_SVv1.m (overlay two already-saved
%     traces, e.g. TMS vs Sham or Pv vs Sst - now runCompareMode())
% chosen from one mode-select popup at launch. Both modes are otherwise
% functionally unchanged from those two scripts (same TDT stream
% auto-detect / single-vs-dual-color handling, same wizard, same
% scan-and-pick comparison logic) - what changed is the OUTPUT: every
% figure-producing step in both modes now writes ONE multi-page PDF
% report per run (styled after the user's TMS_GroupSummary_*.pdf
% reference: matched y-axis span between paired panels, a gray baseline
% bar, a gray AUC-window band, a dashed line at the aligned event, paired
% animal AUC dot plots with a plain-language stats page) instead of a
% pile of separate PNG/FIG files per condition. See writeReportPDF() and
% its helpers, and buildComparisonReportPDF(), for the new report code.
%
% SV 9/8/26: PDF pages are built with reportPageFigure()'s generous fixed
% margins (bottom margin explicitly reserved, content never touches the
% figure edge) specifically because the reference script's PDF export
% kept clipping plots at the bottom of the page during development -
% don't shrink those margins without checking a real export first.
%
% Predecessor scripts (run_PMA_photometry_batch_SVv5.m,
% run_PMA_photometry_batch_crossgroup_SVv2.m,
% run_PMA_photometry_batch_multiday_SVv1.m,
% run_PMA_photometry_compare_traces_SVv1.m) are superseded by this file's
% two modes and are not included in this repository.
% ====================================================================== %

function PMA_photometry_complete_SVv1(varargin)
% SV 9/9/26: varargin supports an undocumented direct entry,
% PMA_photometry_complete_SVv1('reports_only', root_dir), that skips the
% mode-select popup and the day-folder wizard entirely and just
% (re)builds the consolidated PDF reports from whatever's already saved
% under root_dir - the same thing runBatchMode() does at the end of a
% real batch run, callable on its own. Two uses:
%   1) You already ran a batch, then fixed a report-layer bug (a color,
%      a label, a stats method) and want fresh PDFs without re-running
%      the expensive TDT processing again - just:
%      PMA_photometry_complete_SVv1('reports_only', 'E:\your\dataset\root')
%   2) Automated testing: writeBehaviorReportsAcrossDays and everything
%      it calls are plain functions with no GUI dependency once the
%      day/behavior selections are already on disk, so this entry point
%      lets `matlab -batch` exercise the whole report-generation layer
%      against synthetic data with no interactive dialogs at all.
if nargin >= 1 && strcmpi(varargin{1}, 'reports_only')
    if nargin < 2 || isempty(varargin{2})
        error('Usage: PMA_photometry_complete_SVv1(''reports_only'', root_dir)');
    end
    % SV 9/28/26: optional 3rd argument, a colors struct (see
    % defaultReportColors); omitted -> the colors saved with the newest run.
    if nargin >= 3
        writeBehaviorReportsAcrossDays(varargin{2}, varargin{3});
    else
        writeBehaviorReportsAcrossDays(varargin{2});
    end
    return;
end

% SV 9/9/26: a second undocumented direct entry,
% PMA_photometry_complete_SVv1('scripted_batch', config), runs a FULL
% batch (real TDT reprocessing of every selected day folder, same as
% picking "Run Batch Analysis" interactively) with NO dialogs at all - the
% day-folder/color-mode/behavior-column selections that the 3-step wizard
% normally collects via uifigure/uiwait are instead built directly from a
% plain config struct by buildScriptedParams() (see that function for the
% exact fields). Added so a full re-run after an analysis-logic change
% (not just a report-layer one - reports_only above already covers that)
% doesn't require re-clicking through the wizard by hand every time; the
% config only needs to be written out once for a given dataset/selection.
if nargin >= 1 && strcmpi(varargin{1}, 'scripted_batch')
    if nargin < 2 || isempty(varargin{2})
        error('Usage: PMA_photometry_complete_SVv1(''scripted_batch'', config)');
    end
    original_dir = pwd;
    cleanup_obj = onCleanup(@() restoreWorkingDirectory(original_dir)); %#ok<NASGU>
    script_dir = fileparts(mfilename('fullpath'));
    tdt_folder = fullfile(script_dir, 'TDT');
    if exist(tdt_folder, 'dir')
        addpath(genpath(tdt_folder));
    end
    scripted_params = buildScriptedParams(varargin{2});
    runBatchMode(script_dir, scripted_params);
    return;
end

clc;
close all;

original_dir = pwd;
cleanup_obj = onCleanup(@() restoreWorkingDirectory(original_dir)); %#ok<NASGU>

script_dir = fileparts(mfilename('fullpath'));

tdt_folder = fullfile(script_dir, 'TDT');
if exist(tdt_folder, 'dir')
    addpath(genpath(tdt_folder));
end

mode = selectRunMode();
if isempty(mode)
    fprintf('Cancelled.\n');
    return;
end

switch mode
    case 'batch'
        runBatchMode(script_dir);
    case 'compare'
        runCompareMode();
end

fprintf('\nReturned to original directory:\n%s\n', original_dir);

end

function mode = selectRunMode()
% First popup: which of the two workflows to run. Kept as a separate,
% minimal step rather than folded into either wizard so a user who only
% wants to compare already-saved traces isn't shown the (irrelevant)
% day-folder/behavior wizard at all, and vice versa.

fig = uifigure('Name', 'PMA Photometry - Complete', 'Position', [100 100 520 240]);
fig.UserData.mode = '';
fig.CloseRequestFcn = @(src, evt) uiresume(fig);

g = uigridlayout(fig, [3 1]);
g.RowHeight = {'fit', 'fit', 'fit'};

uilabel(g, 'Text', 'What do you want to do?', 'FontWeight', 'bold');

uibutton(g, 'Text', 'Run Batch Analysis (process raw photometry for day folders)', ...
    'ButtonPushedFcn', @(~, ~) onPick('batch'));
uibutton(g, 'Text', 'Compare Saved Traces (e.g. TMS vs Sham, 465 vs 560)', ...
    'ButtonPushedFcn', @(~, ~) onPick('compare'));

uiwait(fig);

if ~isvalid(fig) || isempty(fig.UserData.mode)
    if isvalid(fig), delete(fig); end
    mode = '';
    return;
end

mode = fig.UserData.mode;
delete(fig);

    function onPick(which)
        fig.UserData.mode = which;
        uiresume(fig);
    end
end

function runBatchMode(script_dir, params)
% SV 9/8/26: body = the original run_PMA_photometry_batch_multiday_SVv1
% top-level function, unchanged apart from being wrapped as a callable
% mode instead of the file's own entry point (clc/close all/cleanup now
% happen once in PMA_photometry_complete_SVv1 instead of here).
%
% SV 9/9/26: params is now an optional 2nd argument - when given (from
% PMA_photometry_complete_SVv1's 'scripted_batch' entry point, via
% buildScriptedParams()), the interactive 3-step wizard is skipped
% entirely and this pre-built params struct is used as-is.
if nargin < 2 || isempty(params)
    params = getPMAParamsMultiDay();
end
params.script_dir = script_dir;

n_days = numel(params.day_folder_list);
n_variants = numel(params.behavior_variants);
fprintf('\n%d day folder(s) x %d behavior variant(s) queued.\n', n_days, n_variants);

run_log = struct('day_label', {}, 'day_type', {}, 'behavior', {}, 'variant_tag', {}, 'status', {}, 'message', {});

for d = 1:n_days
    day_info = params.day_folder_list(d);

    for v = 1:n_variants
        variant = params.behavior_variants(v);

        idx = numel(run_log) + 1;
        run_log(idx).day_label = day_info.name;
        run_log(idx).day_type = day_info.type;
        run_log(idx).behavior = variant.behavior;
        run_log(idx).variant_tag = variant.variant_tag;

        if variant.requires_footshock && ~strcmp(day_info.type, 'TRAIN')
            run_log(idx).status = 'SKIPPED';
            run_log(idx).message = sprintf('Day type is %s; "%s" (%s) needs TRAIN footshock timing.', ...
                day_info.type, variant.behavior, variant.variant_tag);
            fprintf('\nSKIP: %s [%s] x %s (%s) - %s\n', day_info.name, day_info.type, ...
                variant.behavior, variant.variant_tag, run_log(idx).message);
            continue;
        end

        fprintf('\n########################################\n');
        fprintf('DAY: %s [%s]   BEHAVIOR: %s (%s)\n', day_info.name, day_info.type, variant.behavior, variant.variant_tag);
        fprintf('########################################\n');

        day_variant_params = params;
        day_variant_params.video_directory = day_info.path;
        [~, day_variant_params.day_label, ~] = fileparts(day_info.path);
        day_variant_params.behavior = variant.behavior;
        day_variant_params.TRANGE_pre = variant.TRANGE_pre;
        day_variant_params.TRANGE_post = variant.TRANGE_post;
        day_variant_params.BASELINE_PER = variant.BASELINE_PER;
        day_variant_params.AUC_RANGE = variant.AUC_RANGE;
        day_variant_params.auc_tag = variant.auc_tag;
        day_variant_params.platform_epoch = variant.platform_epoch;
        day_variant_params.tone_platform_shock_filter = variant.tone_platform_shock_filter;
        day_variant_params.tone_mode = variant.tone_mode;
        day_variant_params.tone_numbers = variant.tone_numbers;
        day_variant_params.tone_tag = variant.tone_tag;
        day_variant_params.min_platform_bout_sec = variant.min_platform_bout_sec;

        try
            runOneDayFolder(day_variant_params);
            run_log(idx).status = 'OK';
            run_log(idx).message = '';
        catch ME
            run_log(idx).status = 'FAILED';
            run_log(idx).message = ME.getReport();
            warning('Failed: %s x %s (%s)\n%s', day_info.name, variant.behavior, variant.variant_tag, ME.getReport());
        end
    end
end

fprintf('\n=== Multi-day, multi-behavior batch complete ===\n');
for i = 1:numel(run_log)
    fprintf('  %-32s [%-5s]  %-24s  %-28s  %s\n', run_log(i).day_label, run_log(i).day_type, ...
        run_log(i).behavior, run_log(i).variant_tag, run_log(i).status);
end

% SV 9/8/26: consolidated report generation happens ONCE, after every day
% folder in this run has finished processing - re-scans the whole dataset
% root (not just what this run touched) so it also picks up results from
% earlier runs, and stays correct if you only reprocess one group at a
% time. See writeBehaviorReportsAcrossDays().
report_colors = [];
if isfield(params, 'colors')
    report_colors = params.colors;
end
report_update = [];
if isfield(params, 'report_update')
    report_update = params.report_update;
end
writeBehaviorReportsAcrossDays(params.root_directory, report_colors, report_update);

% SV 9/8/26: "Returned to original directory" now printed once by
% PMA_photometry_complete_SVv1 after either mode finishes, since
% original_dir lives in that function's workspace, not this one's.

end

function runOneDayFolder(params)
% SV 8/13/26: body = original SVv5 top-level loop (single day_directory),
% factored out so run_PMA_photometry_batch_multiday_SVv1 can call it once
% per selected day folder with identical params each time.

params.video_folder_list = prepBatch(string(params.video_directory));

if isempty(params.video_folder_list)
    error('No valid animal/session subfolders found in %s', params.video_directory);
end

results_root = fullfile(params.video_directory, 'Photometry_Results');
if ~exist(results_root, 'dir')
    mkdir(results_root);
end

run_folder_name = makeRunFolderName(params);
run_output_dir = fullfile(results_root, run_folder_name);

if ~exist(run_output_dir, 'dir')
    mkdir(run_output_dir);
end

params.run_output_dir = run_output_dir;
params.run_timestamp = datestr(now,'yyyy_mm_dd_HHMMSS');

writeRunLog(params, run_output_dir);

group_result = struct;
group_result.params = params;
group_result.animals = struct([]);
group_result.failed_folders = struct('folder', {}, 'message', {});

for j = 1:length(params.video_folder_list)

    current_video = params.video_folder_list(j);
    video_folder = fullfile(params.video_directory, current_video);

    fprintf('\n========================================\n');
    fprintf('Processing folder %d of %d: %s\n', j, length(params.video_folder_list), current_video);
    fprintf('========================================\n');

    try
        animal_result = processSingleAnimal(video_folder, current_video, params);

        idx = numel(group_result.animals) + 1;
        group_result.animals(idx).mouse = animal_result.mouse;
        group_result.animals(idx).session_folder = animal_result.session_folder;
        group_result.animals(idx).save_file = animal_result.save_file;

    catch ME
        fail_idx = numel(group_result.failed_folders) + 1;
        group_result.failed_folders(fail_idx).folder = char(current_video);
        group_result.failed_folders(fail_idx).message = ME.getReport();
        warning('Failed on folder %s\n%s', current_video, ME.getReport());
    end
end

group_save_file = fullfile(run_output_dir, ...
    sprintf('%s_GROUP_%s_%s_%s.mat', ...
    params.day_label, params.behavior, params.tone_tag, datestr(now,'yyyy_mm_dd_HHMMSS')));

% SV 8/13/26: -v7.3 group save kept hitting "Unable to write to file ...
% because it appears to be corrupt" on every single day x variant, 100% of
% the time, even brand new files with nothing to collide with (ruled out
% via delete-before-save, which did NOT fix it - kept below anyway since
% it's a harmless no-op guard against genuine re-run collisions). Isolated
% testing (mock group_result structs, string-array fields, plain
% matrices) could NOT reproduce the corruption in isolation, but -v7
% succeeded 100% of the time for every single per-animal save in the same
% freshly-mkdir'd folder in the same real run where -v7.3 failed 100% of
% the time for the group save - pointing at a timing-sensitive Windows I/O
% issue specific to -v7.3's HDF5 writer acting on a just-created directory
% (e.g. AV/indexer scanning), not the data itself. group_result only holds
% lightweight metadata at save time (paths/params - the big per-animal
% trial matrices already live in their own separately-saved files), so
% -v7's 2GB-per-variable ceiling isn't a real constraint here. Switching
% to match the per-animal save's proven-reliable format instead of
% chasing the -v7.3 timing issue further.
% old code:
% save(group_save_file, 'group_result', '-v7.3');
if isfile(group_save_file)
    delete(group_save_file);
end
save(group_save_file, 'group_result', '-v7');

fprintf('\nDay batch complete.\n');
fprintf('Group results saved to:\n%s\n', group_save_file);

% SV 9/8/26 (v2, corrected same day): per-run PDF report (writeGroupReportPDF)
% removed - it recreated the exact "one document buried in its own
% parameter-named folder" clutter the user was trying to get away from,
% just at the folder level instead of the PNG level. Every day/behavior/
% variant this run still needs its own Photometry_Results\<run>\ folder
% to hold the raw per-animal .mat data (that part is unavoidable - each
% variant is a genuinely different calc_zall run), but the REPORT is now
% built once, after every day folder in this batch has been processed,
% by writeBehaviorReportsAcrossDays() - one consolidated PDF per
% (behavior, day-pairing) written straight into the dataset root, with
% every tone-bin/epoch combination laid out together and TMS vs Sham
% overlaid on the same axes. See runBatchMode(). CSV/xlsx AUC export
% (exportAUCTables) is unchanged, per-run, that was never the complaint.
auc_tables = exportAUCTables(group_result, params, run_output_dir); %#ok<NASGU>

fprintf('\nAll AUC export complete for %s.\n', params.day_label);

end

function animal_result = processSingleAnimal(video_folder, current_video, params)

validateattributes(video_folder, {'char','string'}, {'nonempty'}, mfilename, 'video_folder');

photometry_candidates = dir(fullfile(video_folder, '*_photometry'));
photometry_candidates = photometry_candidates([photometry_candidates.isdir]);
if isempty(photometry_candidates)
    error('No *_photometry folder found in %s', video_folder);
end
block_dir = fullfile(video_folder, photometry_candidates(1).name);

exp_file = findExperimentFile(video_folder);
metrics_file = findSingleFile(video_folder, fullfile('*analyzed', 'Metrics.mat'), 'Metrics.mat');
beh_file = findBehaviorFile(video_folder);
cue_file = findCueFile(video_folder);
reward_file = [];
if strcmp(params.behavior, 'reward')
    reward_file = findRewardFile(video_folder, current_video);
end

metrics_struct = load(fullfile(metrics_file.folder, metrics_file.name));
behavior_struct = load(fullfile(beh_file.folder, beh_file.name));
exp_struct = load(fullfile(exp_file.folder, exp_file.name));

behavior_fields = fieldnames(behavior_struct);
if isempty(behavior_fields)
    error('Behavior file is empty: %s', fullfile(beh_file.folder, beh_file.name));
end

if isfield(behavior_struct, 'Behavior')
    Behavior = behavior_struct.Behavior;
elseif isfield(behavior_struct, 'Behavior_Filter')
    Behavior = behavior_struct.Behavior_Filter;
else
    Behavior = behavior_struct.(behavior_fields{1});
    warning('Expected variable "Behavior" not found. Using "%s" instead.', behavior_fields{1});
end

if ~isfield(metrics_struct, 'Metrics')
    warning('Metrics.mat loaded but variable "Metrics" was not found: %s', fullfile(metrics_file.folder, metrics_file.name));
end
if isempty(fieldnames(exp_struct))
    error('Experiment file is empty: %s', fullfile(exp_file.folder, exp_file.name));
end

cueframes = readCueFrames(fullfile(cue_file.folder, cue_file.name));
rewardframes = [];
if strcmp(params.behavior, 'reward')
    rewardframes = readRewardFrames(fullfile(reward_file.folder, reward_file.name));
end

processed = loadAndProcessPhotometrySignals( ...
    char(block_dir), ...
    char(fullfile(exp_file.folder, exp_file.name)), ...
    char(fullfile(beh_file.folder, beh_file.name)), ...
    params);

event_data = getBehaviorEvents(Behavior, cueframes, params, rewardframes);

animal_result = struct;
animal_result.mouse = char(current_video);
animal_result.session_folder = video_folder;
animal_result.params = params;
animal_result.input_files = struct( ...
    'experiment', fullfile(exp_file.folder, exp_file.name), ...
    'behavior', fullfile(beh_file.folder, beh_file.name), ...
    'metrics', fullfile(metrics_file.folder, metrics_file.name), ...
    'cue', fullfile(cue_file.folder, cue_file.name), ...
    'photometry_block', block_dir);
if strcmp(params.behavior, 'reward')
    animal_result.input_files.reward = fullfile(reward_file.folder, reward_file.name);
end
animal_result.events = event_data;
animal_result.signals = struct;
animal_result.signals.sst = processed.sig_sst;
animal_result.signals.pv = processed.sig_pv;
animal_result.signals.fs = processed.ds_fs; % SV 9/8/26: for the QC report page's time axis

% SV 9/9/26: tone onset times in seconds, same timebase as
% animal_result.signals.pv/sst - marked as light gray ticks on the QC
% raw-trace page (per user's hand-drawn spec), independent of whichever
% behavior-specific condition labels (platform_entry, tone_on_platform,
% ...) this run has, since tones are the shared temporal backbone across
% every behavior.
tone_onset_frames = max(1, min(round(cueframes(:,1)), numel(processed.beh2fp)));
tone_fp_idx = processed.beh2fp(tone_onset_frames);
animal_result.tone_onsets_sec = tone_fp_idx(:) / processed.ds_fs;

% SV 9/9/26: tone OFFSET times too, same timebase - lets the QC page draw
% each tone as a filled duration BAR (onset to offset) instead of just an
% instantaneous onset tick, per user's hand-drawn spec (a bar in the same
% style as the Baseline/AUC bars on the trial-aligned panels).
if size(cueframes, 2) >= 2
    tone_offset_frames = max(1, min(round(cueframes(:,2)), numel(processed.beh2fp)));
    tone_off_fp_idx = processed.beh2fp(tone_offset_frames);
    animal_result.tone_offsets_sec = tone_off_fp_idx(:) / processed.ds_fs;
else
    animal_result.tone_offsets_sec = animal_result.tone_onsets_sec;
end
animal_result.analysis = struct;
animal_result.analysis.sst = struct;
animal_result.analysis.pv = struct;

animal_result = runSingleCondition(animal_result, processed, event_data.eventA, ...
    event_data.eventA_label, params);

if isfield(event_data, 'eventB') && isfield(event_data, 'eventB_label') && ~isempty(event_data.eventB_label)
    animal_result = runSingleCondition(animal_result, processed, event_data.eventB, ...
        event_data.eventB_label, params);
end

animal_save_dir = fullfile(params.run_output_dir, animal_result.mouse);
if ~exist(animal_save_dir, 'dir')
    mkdir(animal_save_dir);
end

save_file = fullfile(animal_save_dir, ...
    sprintf('%s_%s_%s.mat', animal_result.mouse, params.behavior, params.tone_tag));

% SV 5/22/26 Delete pre-existing .mat before saving to prevent corrupt file errors
animal_result.save_file = save_file;
if isfile(save_file)
    delete(save_file);
end
save(save_file, 'animal_result', '-v7');
% old code:
% animal_result.save_file = save_file;
% save(save_file, 'animal_result', '-v7.3');

fprintf('Saved animal result: %s\n', save_file);

end

function animal_result = runSingleCondition(animal_result, processed, event_matrix, label, params)

% SV 9/8/26: per-trial event onset times in seconds, on the SAME
% timebase as animal_result.signals.pv/sst (i.e. divide by
% animal_result.signals.fs to plot against them) - added so the QC raw-
% trace report page can mark where each trial's event actually happened,
% per user request. beh2fp already maps behavior frames to downsampled
% photometry sample indices (see loadAndProcessPhotometrySignals), so
% this is just that lookup plus a /fs conversion to seconds; clamped to
% valid range since a trial's frame can occasionally fall just past the
% end of a session that ran slightly short.
if ~isempty(event_matrix)
    onset_frames = max(1, min(event_matrix(:,1), numel(processed.beh2fp)));
    fp_idx = processed.beh2fp(onset_frames);
    animal_result.events_sec.(label) = fp_idx(:) / processed.ds_fs;
else
    animal_result.events_sec.(label) = [];
end

if isempty(event_matrix)
    animal_result.analysis.sst.(label).trial_matrix = [];
    animal_result.analysis.sst.(label).mean_trace = [];
    animal_result.analysis.sst.(label).epoc_length = [];
    animal_result.analysis.sst.(label).auc = makeEmptyAUCStruct(params);

    animal_result.analysis.pv.(label).trial_matrix = [];
    animal_result.analysis.pv.(label).mean_trace = [];
    animal_result.analysis.pv.(label).epoc_length = [];
    animal_result.analysis.pv.(label).auc = makeEmptyAUCStruct(params);
    return;
end

% SV 9/8/26: sig_sst is [] for single-color cohorts (no 560 store
% configured in Global settings - see loadAndProcessPhotometrySignals).
% Skip calc_zall on it entirely rather than feeding it an empty signal,
% and leave the sst branch at the same "no data" shape the empty-event
% early-return above already produces, which plotting/AUC export already
% treat as "nothing to draw for this channel".
if ~isempty(processed.sig_sst)
    [zall_sst, ~, epoc_length] = calc_zall( ...
        animal_result.mouse, ...
        processed.sig_sst, ...
        event_matrix, ...
        params.beh_fps, ...
        processed.beh2fp, ...
        params.FP_DS_FACTOR, ...
        params.TRANGE_pre, ...
        params.TRANGE_post, ...
        processed.data, ...
        params.BASELINE_PER, ...
        params.STREAM_STORE_465);

    close all;

    animal_result.analysis.sst.(label).trial_matrix = zall_sst;
    animal_result.analysis.sst.(label).mean_trace = mean(zall_sst, 1, 'omitnan');
    animal_result.analysis.sst.(label).epoc_length = epoc_length;
    animal_result.analysis.sst.(label).auc = calculateAUCFromTraceMatrix(zall_sst, params);
else
    animal_result.analysis.sst.(label).trial_matrix = [];
    animal_result.analysis.sst.(label).mean_trace = [];
    animal_result.analysis.sst.(label).epoc_length = [];
    animal_result.analysis.sst.(label).auc = makeEmptyAUCStruct(params);
end

[zall_pv, ~, epoc_length] = calc_zall( ...
    animal_result.mouse, ...
    processed.sig_pv, ...
    event_matrix, ...
    params.beh_fps, ...
    processed.beh2fp, ...
    params.FP_DS_FACTOR, ...
    params.TRANGE_pre, ...
    params.TRANGE_post, ...
    processed.data, ...
    params.BASELINE_PER, ...
    params.STREAM_STORE_465);

close all;

animal_result.analysis.pv.(label).trial_matrix = zall_pv;
animal_result.analysis.pv.(label).mean_trace = mean(zall_pv, 1, 'omitnan');
animal_result.analysis.pv.(label).epoc_length = epoc_length;
animal_result.analysis.pv.(label).auc = calculateAUCFromTraceMatrix(zall_pv, params);

end

function exp_file = findExperimentFile(video_folder)

candidates = dir(fullfile(video_folder, '*.mat'));
if isempty(candidates)
    error('Experiment .mat file not found in %s', video_folder);
end

names = string({candidates.name});

exclude_patterns = ["behavior", "metrics", "cue", "photometry_results", "animal_result", "_group_"];
keep = true(size(names));

for i = 1:numel(exclude_patterns)
    keep = keep & ~contains(lower(names), lower(exclude_patterns(i)));
end

filtered = candidates(keep);

if isempty(filtered)
    error('No unambiguous experiment .mat file found in %s. Clean up extra MAT files or tighten the file pattern.', video_folder);
end

if numel(filtered) > 1
    listing = strjoin(string({filtered.name}), ', ');
    error('Multiple possible experiment MAT files found in %s: %s', video_folder, listing);
end

exp_file = filtered(1);

end

function file_info = findBehaviorFile(video_folder)

behavior_candidates = [ ...
    dir(fullfile(video_folder, '*_analyzed', 'Behavior_Filter.mat')); ...
    dir(fullfile(video_folder, '*_analyzed', 'Behavior.mat'))];

if isempty(behavior_candidates)
    error('Behavior_Filter.mat or Behavior.mat not found under an *analyzed folder in %s', video_folder);
end

behavior_candidates = behavior_candidates(endsWith({behavior_candidates.name}, '.mat'));

preferred_idx = find(strcmp({behavior_candidates.name}, 'Behavior_Filter.mat'), 1, 'first');
if ~isempty(preferred_idx)
    file_info = behavior_candidates(preferred_idx);
    return;
end

if numel(behavior_candidates) > 1
    listing = strjoin(string({behavior_candidates.name}), ', ');
    warning('Multiple behavior files found; using first available. Candidates: %s', listing);
end

file_info = behavior_candidates(1);

end

function file_info = findCueFile(video_folder)

% SV 8/13/26: every animal folder here has BOTH csp_cue_frames.csv (CS+
% tone onsets - what every behavior below actually keys off of, matching
% Behavior.Temporal.CSp) and us_cue_frames.csv (US/shock cues, unused by
% any behavior this script runs). The old single combined glob relied on
% dir() happening to return csp_* before us_* alphabetically and just
% took cue_candidates(1) - correct in practice on Windows but silent and
% unguaranteed. Now explicitly prefer a csp-named file first; only fall
% back to the broad multi-pattern glob (unchanged) if none is found, so
% datasets without the csp/us split still work exactly as before.
% old code:
% cue_candidates = [ ...
%     dir(fullfile(video_folder, 'Cue*.xls')); ...
%     dir(fullfile(video_folder, 'Cue*.xlsx')); ...
%     dir(fullfile(video_folder, 'Cue*.mat')); ...
%     dir(fullfile(video_folder, '*cue*.csv')); ...
%     dir(fullfile(video_folder, '*cue*.xls')); ...
%     dir(fullfile(video_folder, '*cue*.xlsx')); ...
%     dir(fullfile(video_folder, '*cue*.mat'))];
%
% if isempty(cue_candidates)
%     error('No cue file found in %s (looked for Cue* and *cue*)', video_folder);
% end
%
% if numel(cue_candidates) > 1
%     listing = strjoin(string({cue_candidates.name}), ', ');
%     warning('Multiple cue files found; using first available. Candidates: %s', listing);
% end
%
% file_info = cue_candidates(1);

csp_candidates = [ ...
    dir(fullfile(video_folder, '*csp*cue*.csv')); ...
    dir(fullfile(video_folder, '*csp*cue*.xls')); ...
    dir(fullfile(video_folder, '*csp*cue*.xlsx')); ...
    dir(fullfile(video_folder, '*csp*cue*.mat')); ...
    dir(fullfile(video_folder, '*cue*csp*.csv')); ...
    dir(fullfile(video_folder, '*cue*csp*.xls')); ...
    dir(fullfile(video_folder, '*cue*csp*.xlsx')); ...
    dir(fullfile(video_folder, '*cue*csp*.mat'))];

if ~isempty(csp_candidates)
    if numel(csp_candidates) > 1
        listing = strjoin(string({csp_candidates.name}), ', ');
        warning('Multiple CSp cue files found; using first available. Candidates: %s', listing);
    end
    file_info = csp_candidates(1);
    return;
end

cue_candidates = [ ...
    dir(fullfile(video_folder, 'Cue*.xls')); ...
    dir(fullfile(video_folder, 'Cue*.xlsx')); ...
    dir(fullfile(video_folder, 'Cue*.mat')); ...
    dir(fullfile(video_folder, '*cue*.csv')); ...
    dir(fullfile(video_folder, '*cue*.xls')); ...
    dir(fullfile(video_folder, '*cue*.xlsx')); ...
    dir(fullfile(video_folder, '*cue*.mat'))];

if isempty(cue_candidates)
    error('No cue file found in %s (looked for *csp*cue*, Cue*, and *cue*)', video_folder);
end

if numel(cue_candidates) > 1
    listing = strjoin(string({cue_candidates.name}), ', ');
    warning('Multiple cue files found (none CSp-named); using first available. Candidates: %s', listing);
end

file_info = cue_candidates(1);
end

function file_info = findRewardFile(video_folder, current_video)

video_folder = char(video_folder);
current_video = char(current_video);
parent_dir = fileparts(video_folder);
parts = split(string(current_video), '_');
mouse_id = char(parts(1));
if numel(parts) >= 2
    day_token = char(parts(end));
else
    day_token = '';
end

candidates = [ ...
    dir(fullfile(video_folder, '*Reward*.xls')); ...
    dir(fullfile(video_folder, '*Reward*.xlsx')); ...
    dir(fullfile(video_folder, '*Reward*.csv')); ...
    dir(fullfile(parent_dir, sprintf('%s_%s_Reward*.xls', day_token, mouse_id))); ...
    dir(fullfile(parent_dir, sprintf('%s_%s_Reward*.xlsx', day_token, mouse_id))); ...
    dir(fullfile(parent_dir, sprintf('%s_%s_Reward*.csv', day_token, mouse_id))); ...
    dir(fullfile(parent_dir, sprintf('*%s*Reward*.xls', mouse_id))); ...
    dir(fullfile(parent_dir, sprintf('*%s*Reward*.xlsx', mouse_id))); ...
    dir(fullfile(parent_dir, sprintf('*%s*Reward*.csv', mouse_id)))];

if isempty(candidates)
    error('No reward file found for %s. Expected something like D1_%s_Reward.xlsx or a Reward file inside the session folder.', current_video, mouse_id);
end

[~, ia] = unique(string(fullfile({candidates.folder}, {candidates.name})), 'stable');
candidates = candidates(sort(ia));

if numel(candidates) > 1
    listing = strjoin(string({candidates.name}), ', ');
    warning('Multiple reward files found; using first available. Candidates: %s', listing);
end

file_info = candidates(1);

end

function rewardframes = readRewardFrames(reward_path)

[~,~,reward_ext] = fileparts(reward_path);

switch lower(reward_ext)
    case {'.xls', '.xlsx', '.csv'}
        reward_table = readtable(reward_path);
        rewardframes = table2array(reward_table);
    case '.mat'
        reward_struct = load(reward_path);
        reward_fields = fieldnames(reward_struct);
        if isempty(reward_fields)
            error('Reward file is empty: %s', reward_path);
        end
        rewardframes = reward_struct.(reward_fields{1});
    otherwise
        error('Unsupported reward file type: %s', reward_ext);
end

validateattributes(rewardframes, {'numeric'}, {'2d', 'ncols', 2, 'nonempty'}, mfilename, 'rewardframes');
rewardframes = round(rewardframes);

end

function file_info = findSingleFile(video_folder, pattern, display_name)

candidates = dir(fullfile(video_folder, pattern));

if isempty(candidates)
    error('%s not found in %s', display_name, video_folder);
end

if numel(candidates) > 1
    listing = strjoin(string({candidates.name}), ', ');
    warning('Multiple %s files found; using first available. Candidates: %s', display_name, listing);
end

file_info = candidates(1);

end

function cueframes = readCueFrames(cue_path)

[~,~,cue_ext] = fileparts(cue_path);

switch lower(cue_ext)
    case {'.xls', '.xlsx', '.csv'}
        cue_table = readtable(cue_path);
        cueframes = table2array(cue_table);

    case '.mat'
        cue_struct = load(cue_path);
        cue_fields = fieldnames(cue_struct);

        if isempty(cue_fields)
            error('Cue .mat file is empty: %s', cue_path);
        end

        cueframes = cue_struct.(cue_fields{1});

    otherwise
        error('Unsupported cue file type: %s', cue_ext);
end

validateattributes(cueframes, {'numeric'}, {'2d', 'nonempty'}, mfilename, 'cueframes');

end

function run_folder_name = makeRunFolderName(params)

behavior_part = params.behavior;
tone_part = params.tone_tag;
window_part = sprintf('pre%d_post%d', params.TRANGE_pre, params.TRANGE_post);
baseline_part = sprintf('base%d_%d', params.BASELINE_PER(1), params.BASELINE_PER(2));
auc_part = sprintf('auc%s', makeAUCTag(params.AUC_RANGE));

epoch_part = '';
if isfield(params, 'platform_epoch') && strcmp(params.behavior, 'platform_entry_exit')
    epoch_part = ['__epoch_' params.platform_epoch];
end

shock_filter_part = '';
if isfield(params, 'tone_platform_shock_filter') && strcmp(params.behavior, 'tone_on_vs_off_platform')
    shock_filter_part = ['__shockfilter_' params.tone_platform_shock_filter];
end

run_folder_name = sprintf('%s__%s__%s__%s__%s%s%s', ...
    behavior_part, tone_part, window_part, baseline_part, auc_part, epoch_part, shock_filter_part);

run_folder_name = strrep(run_folder_name, '.', 'p');

end

function writeRunLog(params, run_output_dir)

log_file = fullfile(run_output_dir, 'run_parameters.txt');
fid = fopen(log_file, 'w');

if fid == -1
    warning('Could not create run log file: %s', log_file);
    return;
end

cleanup_obj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, 'PMA photometry batch run\n');
fprintf(fid, 'Timestamp: %s\n', datestr(now));
fprintf(fid, 'Day label: %s\n', params.day_label);
fprintf(fid, 'Video directory: %s\n', params.video_directory);
fprintf(fid, 'Behavior: %s\n', params.behavior);
fprintf(fid, 'Tone mode: %s\n', params.tone_mode);
fprintf(fid, 'Tone numbers: %s\n', mat2str(params.tone_numbers));
if isfield(params, 'platform_epoch')
    fprintf(fid, 'Platform entry/exit epoch: %s\n', params.platform_epoch);
end
if isfield(params, 'tone_platform_shock_filter')
    fprintf(fid, 'Tone on/off platform shock-outcome filter: %s\n', params.tone_platform_shock_filter);
end
fprintf(fid, 'TRANGE_pre: %g\n', params.TRANGE_pre);
fprintf(fid, 'TRANGE_post: %g\n', params.TRANGE_post);
fprintf(fid, 'Baseline: [%g %g]\n', params.BASELINE_PER(1), params.BASELINE_PER(2));
fprintf(fid, 'Behavior fps: %g\n', params.beh_fps);
fprintf(fid, 'Downsample factor: %g\n', params.FP_DS_FACTOR);
fprintf(fid, 'Min platform bout sec: %g\n', params.min_platform_bout_sec);
fprintf(fid, 'Fit skip sec: %g\n', params.fit_skip_sec);
if isfield(params, 'AUC_RANGE')
    fprintf(fid, 'AUC window: [%g %g] sec relative to event\n', params.AUC_RANGE(1), params.AUC_RANGE(2));
    fprintf(fid, 'AUC tag: %s\n', params.auc_tag);
    fprintf(fid, 'AUC method: trapz over unsmoothed event-aligned z-score trace\n');
end
% SV 9/8/26: STREAM_STORE_405 is no longer a fixed param - it's
% auto-detected per animal block (405A vs 415A) in
% loadAndProcessPhotometrySignals, so it's not logged here at the
% day-folder level; see each animal's *_photometry Notes for which one
% was actually used (processed.stream_405_used, if you need to check).
fprintf(fid, 'Color mode: %s\n', params.color_mode);
if isfield(params, 'colors')
    fprintf(fid, 'Report colors: TMS 465=%s, Sham 465=%s, TMS 560=%s, Sham 560=%s\n', ...
        params.colors.tms_pv, params.colors.sham_pv, params.colors.tms_sst, params.colors.sham_sst);
end
fprintf(fid, 'STREAM_STORE_465: %s\n', params.STREAM_STORE_465);
if isempty(params.STREAM_STORE_560)
    fprintf(fid, 'STREAM_STORE_560: (none - single color, no 2nd channel)\n');
    fprintf(fid, 'Channel mapping: 465=%s. No 560 channel this run.\n', params.STREAM_STORE_465);
else
    fprintf(fid, 'STREAM_STORE_560: %s\n', params.STREAM_STORE_560);
    fprintf(fid, 'Channel mapping: 560=%s, 465=%s\n', ...
        params.STREAM_STORE_560, params.STREAM_STORE_465);
end

end

function restoreWorkingDirectory(original_dir)

if isfolder(original_dir)
    cd(original_dir);
end

end

function meta = behaviorDefaults()
% SV 8/13/26: user-specified per-behavior prefill defaults (given 2026-08-13).
% min_platform_bout_sec is only meaningful for platform_entry_exit but a
% value is carried for every row so the field always exists uniformly.
% default_epochs is only read for platform_entry_exit; default_tone_bins
% is read for platform_entry_exit, tone_on_vs_off_platform, and
% tone_shock_vs_noshock (unused/empty for the others, harmless).
%
% SV 8/13/26, later same day: platform_entry_exit now also gets tone-bin
% filtering "like the other [tone] behaviors do" (per user request) -
% getPlatformEpochWindows() already used params.tone_numbers internally
% for the tone-relative epochs (tone_pre_shock/whole_tone/shock/
% inter_tone_interval), it just wasn't wired to a real user selection
% before. Default-checked sets also changed per user request: epochs
% default to {inter_tone_interval, whole_tone} instead of all 6; tone
% bins for platform_entry_exit default to {1-3, 1-6} instead of all 3.
%
% SV 8/13/26, later still: tone_on_vs_off_platform's tone bins no longer
% default 4-6 checked (now {1-3, 1-6} like platform_entry_exit); per user
% request, only tone_shock_vs_noshock still defaults all 3 checked.
%
% SV 9/8/26: tone bins widened from 1-6 to 1-9 (added a Tones 7-9 bin;
% "all" now means 1-9) since every PVcre session actually runs 9 tones -
% the old 1-6 cap silently dropped tones 7-9 from every "all" output.
% "Tone On vs Off Platform" renamed to "Tone Onset (On vs Off Platform)"
% per user request, for clarity against the other tone-relative behaviors.
%
% SV 9/8/26, later same day: per user request, platform_entry_exit and
% tone_on_vs_off_platform now default ALL FOUR tone bins checked (not
% just 2) - the new consolidated report (writeBehaviorReportsAcrossDays)
% lays every checked tone bin out side by side in one PDF, so there's no
% longer a reason to default to a subset. tone_on_vs_off_platform's
% shock-outcome filter now defaults to all_trials instead of
% shocked_trials, to match.
%
% SV 9/9/26: tone_shock_vs_noshock's own defaults updated per user's
% screenshot of their own hand-set wizard values - TRANGE_post 50->80 (to
% comfortably fit the AUC window below), AUC_RANGE [0 28]->[28 38], and
% all four tone bins now default-checked (was missing Tones 7-9) to match
% platform_entry_exit/tone_on_vs_off_platform's all-four default above.
meta = struct( ...
    'key',                   {'platform_entry_exit', 'tone_on_vs_off_platform', 'tone_shock_vs_noshock', 'reward'}, ...
    'display',                {'Platform Entries/Exits', 'Tone Onset (On vs Off Platform)', 'Tone Shock vs No-shock', 'Reward'}, ...
    'TRANGE_pre',             {10, 10, 10, 10}, ...
    'TRANGE_post',            {30, 50, 80, 50}, ...
    'BASELINE_PER',           {[0 5], [0 10], [0 10], [0 10]}, ...
    'AUC_RANGE',              {[0 20], [0 28], [28 38], [0 10]}, ...
    'min_platform_bout_sec',  {5, 5, 5, 5}, ...
    'default_epochs',         {{'inter_tone_interval', 'whole_tone'}, {}, {}, {}}, ...
    'default_shock_filter',   {{}, {'all_trials'}, {}, {}}, ...
    'default_tone_bins',      {{'Tones 1-3', 'Tones 4-6', 'Tones 7-9', 'Tones 1-9 (all)'}, ...
                                {'Tones 1-3', 'Tones 4-6', 'Tones 7-9', 'Tones 1-9 (all)'}, ...
                                {'Tones 1-3', 'Tones 4-6', 'Tones 7-9', 'Tones 1-9 (all)'}, ...
                                {}});
end

function bins = toneBinDefinitions()
% SV 8/13/26: tone/shock count is inconsistent across days (sometimes 4,
% 5, or 6 - not a fixed 9), so tone subsetting for tone_on_vs_off_platform
% and tone_shock_vs_noshock is done as named bins instead of an
% exhaustive per-tone checklist. Each checked bin becomes its own separate
% output, same as checked epochs/shock-filters. subsetTones() already
% clamps requested tone indices to however many tones actually exist that
% day, so a day with only 4 tones just contributes fewer trials to the
% 4-6, 7-9, and 1-9 bins rather than erroring.
%
% SV 9/8/26: added Tones 7-9 and widened "all" from 1-6 to 1-9 - every
% PVcre session runs 9 tones, so 1-6 was silently excluding the last 3.
bins = struct( ...
    'label',   {'Tones 1-3', 'Tones 4-6', 'Tones 7-9', 'Tones 1-9 (all)'}, ...
    'numbers', {1:3, 4:6, 7:9, 1:9});
end

function params = getPMAParamsMultiDay()
% SV 8/13/26 (v3, same day, after first live run): 3-step front end, now
% with Back navigation between all 3 popups per user request - each step
% function takes its own previous state and an 'action' comes back so the
% wizard can step forward or backward without losing what was already
% entered:
%  1) selectDayFolders(root_directory, day_candidates, color_mode) -
%     editable Include/Type table (Type is a name-based TRAIN/RETR/OTHER
%     guess, freely reassignable) plus the whole-run Single/Dual Color
%     mode picker (SV 9/8/26). No Back button - it's the first popup.
%  2) selectBehaviorSet(behavior_keys) - multi-select behavior checklist.
%     Back returns to step 1 with its table state intact.
%  3) configureBehaviorColumns(behavior_keys, step3_state, color_mode) -
%     one parameter column per checked behavior, pre-filled per
%     behaviorDefaults() the first time a behavior is shown, or from
%     step3_state.col_result if that behavior was already configured on
%     an earlier visit to this screen. Back returns to step 2 with its
%     checkboxes intact.
% expandBehaviorVariants() then turns each behavior column into one or
% more concrete run variants (one per checked epoch / shock-filter).

params = struct;

default_root = pwd;

disp('Select the root folder containing all "day" folders');
root_directory = uigetdir(default_root, 'Select root folder containing day folders');

if isequal(root_directory, 0)
    error('Folder selection cancelled.');
end

params.root_directory = root_directory;
params.report_update = selectReportMode(root_directory); % SV 10/1/26: new vs. update existing report

day_candidates = [];
% SV 9/9/26 (bugfix): this outer default is what the Select Day Folders
% popup's checkbox actually initializes from (as previous_color_mode) -
% leaving it 'dual' here meant the checkbox opened CHECKED regardless of
% the 'single' default inside selectDayFolders itself, since that
% function only falls back to its own default when previous_color_mode
% is empty, and this was never empty.
color_mode = 'single';
behavior_keys = {};
step3_state = [];

step = 1;
while step <= 3
    switch step
        case 1
            [day_candidates, color_mode] = selectDayFolders(root_directory, day_candidates, color_mode);
            step = 2;

        case 2
            [behavior_keys, action] = selectBehaviorSet(behavior_keys);
            if strcmp(action, 'back')
                step = 1;
            else
                step = 3;
            end

        case 3
            [step3_state, action] = configureBehaviorColumns(behavior_keys, step3_state, color_mode);
            if strcmp(action, 'back')
                step = 2;
            else
                step = 4;
            end
    end
end

selected_days = struct('name', {}, 'path', {}, 'type', {});
for i = 1:numel(day_candidates)
    if ~day_candidates(i).include
        continue;
    end
    selected_days(end+1) = struct('name', day_candidates(i).name, ...
        'path', day_candidates(i).path, 'type', day_candidates(i).type); %#ok<AGROW>
end
if isempty(selected_days)
    error('No day folders selected.');
end
params.day_folder_list = selected_days;

params.behavior_variants = expandBehaviorVariants(step3_state.col_result);
if ~isempty(params.report_update)
    params.report_update.rebuild = unique({params.behavior_variants.behavior}, 'stable');
end

params.beh_fps = step3_state.global_settings.beh_fps;
params.FP_DS_FACTOR = step3_state.global_settings.FP_DS_FACTOR;
params.fit_skip_sec = step3_state.global_settings.fit_skip_sec;
params.plot_types = step3_state.global_settings.plot_types;
% SV 9/28/26: report series colors (group x channel), saved with every
% run's params so reports_only can reuse them - see colorsFromRuns.
params.colors = step3_state.global_settings.colors;

% SV 9/8/26: isosbestic store (405A vs 415A) is auto-detected per TDT
% block in loadAndProcessPhotometrySignals - no longer a fixed param.
% Color mode (chosen in the Select Day Folders popup) decides whether the
% 2nd/Sst signal store is used at all; Single Color forces it off even if
% step3_state carried a value in from a previous Dual Color run this
% session, so switching modes can't leave a stale 560 store behind.
params.color_mode = color_mode;
params.STREAM_STORE_465 = step3_state.global_settings.stream_465;
if strcmp(color_mode, 'dual')
    params.STREAM_STORE_560 = step3_state.global_settings.stream_560;
else
    params.STREAM_STORE_560 = '';
end
params.REF_EPOC = 'PC0_';

end

function params = buildScriptedParams(config)
% Non-interactive equivalent of getPMAParamsMultiDay() - builds the exact
% same params struct the 3-step wizard produces (day_folder_list,
% behavior_variants, global settings, color mode), but from a plain
% config struct instead of uifigure/uiwait dialogs, so a full batch run
% (real TDT reprocessing included) can be reproduced from a script with
% no clicking - see PMA_photometry_complete_SVv1's 'scripted_batch' entry
% point.
%
% config fields:
%   root_directory  (required) - path containing the day folders.
%   day_folders     (required) - cell array of day-folder NAMES to
%                   include, each a direct subfolder of root_directory
%                   (same *_photometry + *_analyzed layout prepBatch
%                   expects).
%   day_types       (optional) - cell array, same length as day_folders,
%                   of 'TRAIN'/'RETR'/'OTHER' overrides. Defaults to the
%                   same name-based auto-detection selectDayFolders uses
%                   (contains 'train'->TRAIN, contains 'retr'->RETR, else
%                   OTHER).
%   color_mode      (optional, default 'single') - 'single' or 'dual'.
%   behaviors       (required) - cell array of behavior keys to run, any
%                   of behaviorDefaults()'s keys ('platform_entry_exit',
%                   'tone_on_vs_off_platform', 'tone_shock_vs_noshock',
%                   'reward'). Each behavior's column settings
%                   (TRANGE_pre/post, BASELINE_PER, AUC_RANGE,
%                   min_platform_bout_sec, epoch_list, shock_filter_list,
%                   tone_bin_list) default to behaviorDefaults()'s own
%                   defaults for that key - the same defaults the wizard
%                   pre-fills a fresh column with - and can be overridden
%                   per-field via a same-named config field, e.g.
%                   config.platform_entry_exit.epoch_list =
%                   {'whole_session'} to run just that one epoch instead
%                   of the default {'inter_tone_interval','whole_tone'}.
%   global_settings (optional) - struct overriding any of beh_fps/
%                   FP_DS_FACTOR/fit_skip_sec/stream_465/stream_560/
%                   plot_types; defaults match the wizard's own defaults
%                   (49.974 / 10 / 10 / 'x465A' / 'x560B' /
%                   {'ALL_ANIMALS','GROUP'}).
if ~isfield(config, 'root_directory') || isempty(config.root_directory)
    error('buildScriptedParams: config.root_directory is required.');
end
if ~isfield(config, 'day_folders') || isempty(config.day_folders)
    error('buildScriptedParams: config.day_folders (cell array of day-folder names) is required.');
end
if ~isfield(config, 'behaviors') || isempty(config.behaviors)
    error('buildScriptedParams: config.behaviors (cell array of behavior keys) is required.');
end

params = struct;
params.root_directory = config.root_directory;

selected_days = struct('name', {}, 'path', {}, 'type', {});
for i = 1:numel(config.day_folders)
    name = config.day_folders{i};
    if isfield(config, 'day_types') && numel(config.day_types) >= i && ~isempty(config.day_types{i})
        day_type = config.day_types{i};
    else
        name_lower = lower(name);
        if contains(name_lower, 'train')
            day_type = 'TRAIN';
        elseif contains(name_lower, 'retr')
            day_type = 'RETR';
        else
            day_type = 'OTHER';
        end
    end
    selected_days(end+1) = struct('name', name, 'path', fullfile(config.root_directory, name), 'type', day_type); %#ok<AGROW>
end
params.day_folder_list = selected_days;

if isfield(config, 'color_mode') && ~isempty(config.color_mode)
    color_mode = config.color_mode;
else
    color_mode = 'single';
end
params.color_mode = color_mode;

gs = struct('beh_fps', 49.974, 'FP_DS_FACTOR', 10, 'fit_skip_sec', 10, ...
    'stream_465', 'x465A', 'stream_560', 'x560B', 'plot_types', {{'ALL_ANIMALS', 'GROUP'}});
if isfield(config, 'global_settings')
    override_fields = fieldnames(config.global_settings);
    for f = 1:numel(override_fields)
        gs.(override_fields{f}) = config.global_settings.(override_fields{f});
    end
end
params.beh_fps = gs.beh_fps;
params.FP_DS_FACTOR = gs.FP_DS_FACTOR;
params.fit_skip_sec = gs.fit_skip_sec;
params.plot_types = gs.plot_types;
% SV 9/28/26: optional config.colors (any of tms_pv / tms_sst / sham_pv /
% sham_sst, each a reportPalette name) over defaultReportColors().
params.colors = defaultReportColors();
if isfield(config, 'colors') && isstruct(config.colors)
    color_fields = fieldnames(config.colors);
    for f = 1:numel(color_fields)
        params.colors.(color_fields{f}) = char(config.colors.(color_fields{f}));
    end
end
params.STREAM_STORE_465 = gs.stream_465;
if strcmp(color_mode, 'dual')
    params.STREAM_STORE_560 = gs.stream_560;
else
    params.STREAM_STORE_560 = '';
end
params.REF_EPOC = 'PC0_';

meta_all = behaviorDefaults();
col_result = struct('behavior', {}, 'TRANGE_pre', {}, 'TRANGE_post', {}, 'BASELINE_PER', {}, 'AUC_RANGE', {}, ...
    'min_platform_bout_sec', {}, 'epoch_list', {}, 'shock_filter_list', {}, 'tone_bin_list', {});
for i = 1:numel(config.behaviors)
    key = config.behaviors{i};
    meta_idx = find(strcmp({meta_all.key}, key), 1);
    if isempty(meta_idx)
        error('buildScriptedParams: unknown behavior key "%s".', key);
    end
    meta = meta_all(meta_idx);
    entry = struct('behavior', key, 'TRANGE_pre', meta.TRANGE_pre, 'TRANGE_post', meta.TRANGE_post, ...
        'BASELINE_PER', meta.BASELINE_PER, 'AUC_RANGE', meta.AUC_RANGE, ...
        'min_platform_bout_sec', meta.min_platform_bout_sec, 'epoch_list', {meta.default_epochs}, ...
        'shock_filter_list', {meta.default_shock_filter}, 'tone_bin_list', {meta.default_tone_bins});
    if isfield(config, key)
        override_fields = fieldnames(config.(key));
        for f = 1:numel(override_fields)
            entry.(override_fields{f}) = config.(key).(override_fields{f});
        end
    end
    col_result(end+1) = entry; %#ok<AGROW>
end

params.behavior_variants = expandBehaviorVariants(col_result);

% SV 10/1/26: optional config.update_report - the name (or _parts folder)
% of an existing report to update instead of making a new one; see
% selectReportMode.
params.report_update = [];
if isfield(config, 'update_report') && ~isempty(config.update_report)
    [~, name] = fileparts(regexprep(char(config.update_report), '_parts[\\/]?$', ''));
    params.report_update = struct('parts_dir', fullfile(config.root_directory, [name '_parts']), 'name', name, ...
        'rebuild', {unique({params.behavior_variants.behavior}, 'stable')});
end

end

function [day_candidates, color_mode] = selectDayFolders(root_directory, previous_day_candidates, previous_color_mode)
% Discovers day-folder candidates under root_directory (same
% *_photometry + *_analyzed test prepBatch uses) and pre-labels each
% TRAIN/RETR/OTHER by name match - but only the FIRST time through; if
% previous_day_candidates is given (re-entering this screen after Back
% from a later step), it's reused as-is so Include/Type edits survive
% instead of being rescanned and reset. Either way shows an editable
% table (Include checkbox + reassignable Type dropdown) so folders whose
% names don't say "train"/"retr" can be corrected by hand. No Back button
% here - it's the first popup in the wizard.
%
% SV 9/8/26: also collects color_mode (Single Color / Dual Color) per
% user request - this is a whole-run setting (not per-day), asked here
% since it's the first popup, and carried through the wizard via
% previous_color_mode/color_mode the same way day_candidates is. Single
% Color means no 2nd/Sst signal store this run regardless of what the
% Global settings panel's Sst store field says (see getPMAParamsMultiDay).

% SV 9/9/26 (bugfix): default is now always Single Color, per user
% request - the previous approach (auto-guessing Dual/Single by peeking
% at whatever *_photometry\StoresListing.txt happened to be found FIRST
% anywhere under the whole root_directory) could silently pick up a
% different day's or a different cohort's listing than the one actually
% being run, guessing Dual for a batch that was entirely Single Color and
% making every animal fail with "Required TDT stream ... not found." A
% wrong default is much more costly here (a whole batch run failing) than
% a wrong-but-obvious Single default (which just means Dual cohorts have
% to check one box), so this no longer guesses from the data at all -
% still fully overridable via the checkbox below.
if nargin < 3 || isempty(previous_color_mode)
    previous_color_mode = 'single';
end

if nargin >= 2 && ~isempty(previous_day_candidates)
    day_candidates = previous_day_candidates;
else
    root_entries = dir(root_directory);
    ignore_names = ["." ".." "Photometry_Results" "Photometry_Results_CrossGroup" "TDT"];

    day_candidates = struct('name', {}, 'path', {}, 'type', {}, 'n_animals', {}, 'include', {});
    for i = 1:numel(root_entries)
        entry = root_entries(i);
        if ~entry.isdir || any(strcmpi(string(entry.name), ignore_names))
            continue;
        end
        candidate_path = fullfile(root_directory, entry.name);
        animal_list = prepBatch(candidate_path);
        if isempty(animal_list)
            continue; % not a day folder (no valid animal/session subfolders)
        end
        name_lower = lower(entry.name);
        if contains(name_lower, 'train')
            day_type = 'TRAIN';
        elseif contains(name_lower, 'retr')
            day_type = 'RETR';
        else
            day_type = 'OTHER';
        end
        day_candidates(end+1) = struct('name', entry.name, 'path', candidate_path, ...
            'type', day_type, 'n_animals', numel(animal_list), 'include', false); %#ok<AGROW>
    end

    if isempty(day_candidates)
        error('No valid day folders (with *_photometry + *_analyzed animal subfolders) found in %s', root_directory);
    end
end

n = numel(day_candidates);
tbl_data = cell(n, 4);
for i = 1:n
    tbl_data{i,1} = day_candidates(i).include;
    tbl_data{i,2} = day_candidates(i).name;
    tbl_data{i,3} = day_candidates(i).type;
    tbl_data{i,4} = day_candidates(i).n_animals;
end

fig = uifigure('Name', 'Select Day Folders', 'Position', [100 100 640 530]);
fig.UserData.confirmed = false;
fig.CloseRequestFcn = @(src, evt) uiresume(fig);

g = uigridlayout(fig, [5 1]);
g.RowHeight = {'fit', 'fit', '1x', 'fit', 'fit'};

uilabel(g, 'Text', sprintf(['Select which day folders to include. Type is a starting guess from the ' ...
    'folder name - correct it if it''s wrong (%d folder(s) found):'], n));

% SV 9/9/26 (per user request): a single checkbox instead of a dropdown -
% unchecked (the default) means Single Color, checked means Dual Color,
% so the common case needs no interaction at all. Labeled by wavelength
% (465/560), not by this lab's cell-type names (Pv/Sst), so the script
% reads sensibly for other labs' reporters - those internal names only
% remain as short field-name shorthand in the code (analysis.pv/.sst),
% never in text a user reads.
color_grid = uigridlayout(g, [1 1]);
color_cb = uicheckbox(color_grid, ...
    'Text', 'Dual Color recording (465 + 560) - leave unchecked for Single Color (465 only)', ...
    'Value', strcmp(previous_color_mode, 'dual'));

uit = uitable(g, 'Data', tbl_data, ...
    'ColumnName', {'Include', 'Day Folder', 'Type', 'N Animals'}, ...
    'ColumnEditable', [true false true false], ...
    'ColumnFormat', {'logical', 'char', {'TRAIN', 'RETR', 'OTHER'}, 'numeric'}, ...
    'ColumnWidth', {60, 'auto', 90, 80});

% SV 9/8/26: Select All / Deselect All added per user request, so a large
% day-folder list doesn't have to be checked/unchecked row by row.
select_grid = uigridlayout(g, [1 2]);
select_grid.ColumnWidth = {'1x', '1x'};
uibutton(select_grid, 'Text', 'Select All', 'ButtonPushedFcn', @(~, ~) setAllInclude(true));
uibutton(select_grid, 'Text', 'Deselect All', 'ButtonPushedFcn', @(~, ~) setAllInclude(false));

% SV 9/8/26: Continue styled green per user request, to read as the
% "go" action now that Select All/Deselect All sit above it.
uibutton(g, 'Text', 'Continue', 'BackgroundColor', [0.30 0.69 0.31], 'FontColor', [1 1 1], ...
    'FontWeight', 'bold', 'ButtonPushedFcn', @(~, ~) onContinue());

uiwait(fig);

if ~isvalid(fig) || ~fig.UserData.confirmed
    if isvalid(fig), delete(fig); end
    error('Day folder selection cancelled.');
end

final_data = uit.Data;
color_mode = ternaryStr(color_cb.Value, 'dual', 'single');
delete(fig);

for i = 1:n
    day_candidates(i).include = logical(final_data{i,1});
    day_candidates(i).type = final_data{i,3};
end

    function setAllInclude(value)
        current_data = uit.Data;
        for r = 1:size(current_data, 1)
            current_data{r, 1} = value;
        end
        uit.Data = current_data;
    end

    function onContinue()
        fig.UserData.confirmed = true;
        uiresume(fig);
    end
end

function [behavior_keys, action] = selectBehaviorSet(previous_checked_keys)
% Multi-select checklist so more than one behavior comparison can run in
% the same execution (each still gets its own independent output).
% previous_checked_keys (from an earlier visit to this screen, e.g. after
% Back from step 3) restores which boxes were checked instead of
% resetting to none-checked. Back returns to the day-folder table.

if nargin < 1
    previous_checked_keys = {};
end

meta = behaviorDefaults();

fig = uifigure('Name', 'Select Behaviors', 'Position', [100 100 420 280]);
fig.UserData.action = '';
fig.CloseRequestFcn = @(src, evt) uiresume(fig);

g = uigridlayout(fig, [numel(meta) + 2, 1]);
g.RowHeight = [{'fit'}, repmat({'fit'}, 1, numel(meta)), {'fit'}];

uilabel(g, 'Text', 'Check every behavior comparison to run in this batch:', 'FontWeight', 'bold');

cb = gobjects(numel(meta), 1);
for i = 1:numel(meta)
    cb(i) = uicheckbox(g, 'Text', meta(i).display, 'Value', any(strcmp(meta(i).key, previous_checked_keys)));
end

button_grid = uigridlayout(g, [1 2]);
button_grid.ColumnWidth = {'1x', '1x'};
uibutton(button_grid, 'Text', 'Back', 'ButtonPushedFcn', @(~, ~) onAction('back'));
uibutton(button_grid, 'Text', 'Continue', 'ButtonPushedFcn', @(~, ~) onAction('continue'));

uiwait(fig);

if ~isvalid(fig) || isempty(fig.UserData.action)
    if isvalid(fig), delete(fig); end
    error('Behavior selection cancelled.');
end

action = fig.UserData.action;
checked = arrayfun(@(h) logical(h.Value), cb);
behavior_keys = {meta(checked).key};
delete(fig);

if strcmp(action, 'continue') && isempty(behavior_keys)
    error('At least one behavior must be selected.');
end

    function onAction(which)
        fig.UserData.action = which;
        uiresume(fig);
    end
end

function [state, action] = configureBehaviorColumns(behavior_keys, previous_state, color_mode)
% One parameter column per checked behavior. A column's fields are
% pre-filled from behaviorDefaults() the first time that behavior is
% shown; if previous_state.col_result already has an entry for that
% behavior key (re-entering after Back then Continue again with it still
% checked), its values are used as the prefill instead, so edits survive
% a round trip through Back. Same idea for the shared global row via
% previous_state.global_settings. Back returns to the behavior checklist.
% Returns state = struct('col_result', ..., 'global_settings', ...) and
% action = 'back' | 'continue'.
%
% SV 9/8/26: color_mode ('single'|'dual', chosen in the Select Day
% Folders popup) decides whether the 2nd/Sst signal store field is shown
% at all - Single Color runs have no 2nd fluorophore to name. The
% isosbestic store is no longer entered here; it's auto-detected per TDT
% block (405A vs 415A) in loadAndProcessPhotometrySignals.

if nargin < 3 || isempty(color_mode)
    color_mode = 'single'; % SV 9/9/26 (bugfix): match the new Single-Color-by-default convention
end

if nargin < 2 || isempty(previous_state)
    previous_state = struct( ...
        'col_result', struct('behavior', {}), ...
        'global_settings', struct('beh_fps', 49.974, 'FP_DS_FACTOR', 10, 'fit_skip_sec', 10, ...
            'stream_465', 'x465A', 'stream_560', 'x560B', ...
            'plot_types', {{'ALL_ANIMALS', 'GROUP'}}, 'colors', defaultReportColors()));
end
if ~isfield(previous_state.global_settings, 'colors')
    previous_state.global_settings.colors = defaultReportColors();
end
prev_col_result = previous_state.col_result;
prev_global = previous_state.global_settings;

meta_all = behaviorDefaults();
n = numel(behavior_keys);

epoch_options = {'whole_session', 'pre_tone_baseline', 'tone_pre_shock', 'shock', 'inter_tone_interval', 'whole_tone'};
shock_filter_options = {'all_trials', 'shocked_trials', 'no_shock_trials'};
tone_bin_options = {toneBinDefinitions().label};

% SV 8/13/26: cols_grid's row was '1x' (fill-remaining-space), which
% forces the behavior panels into a fixed box - a tall column (e.g.
% Platform Entries/Exits with 2 listboxes) got silently clipped at the
% bottom instead of triggering the scrollbar main_grid.Scrollable='on' is
% supposed to provide. '1x' only fills leftover space; it doesn't let
% content grow and get scrolled to. Switched to 'fit' so the row (and
% everything nested in it) sizes to its actual content height, which is
% what Scrollable='on' needs to have something to scroll to. Also bumped
% the default window height so scrolling is the fallback, not the norm.
fig_width = min(1500, 280*n + 260);
fig = uifigure('Name', 'Behavior Parameters', 'Position', [80 80 fig_width 820]);
fig.UserData.action = '';
fig.CloseRequestFcn = @(src, evt) uiresume(fig);

main_grid = uigridlayout(fig, [4 1]);
main_grid.RowHeight = {'fit', 'fit', 'fit', 'fit'};
main_grid.Scrollable = 'on';

uilabel(main_grid, 'Text', ...
    'Global settings (shared by every behavior/day below), then one column per behavior:', ...
    'FontWeight', 'bold');

% SV 8/13/26: Global panel now has 2 internal rows - the existing
% fps/downsample/fit-skip settings, plus a "which plot types to generate"
% checklist (applies to every condition/day in this run; unchecked types
% are never created or saved, not just hidden).
%
% SV 9/8/26: added a 3rd row for the TDT stream store names. These were
% previously hardcoded (x405A/x465A/x560B), which only matches the
% dual-color Sst+Pv rig config (e.g. the Feb-2026 cohort this script
% defaults its root to). Single-color cohorts (e.g. PVcre.Fp Aug-2026,
% recorded as 415A isosbestic + 465A signal only, no 2nd fluorophore)
% need different names, so they're now editable per run. Leaving the 2nd
% signal store blank means "no Sst channel this run" - everything
% downstream (runSingleCondition, plotting, AUC export) already tolerates
% an empty sst trial_matrix, so Pv-only processing falls out for free.
global_panel = uipanel(main_grid, 'Title', 'Global');
global_panel_grid = uigridlayout(global_panel, [4 1]);
global_panel_grid.RowHeight = {'fit', 'fit', 'fit', 'fit'};

global_grid = uigridlayout(global_panel_grid, [1 6]);
global_grid.ColumnWidth = {'fit', 100, 'fit', 100, 'fit', 100};

uilabel(global_grid, 'Text', 'Behavior fps:');
fps_field = uieditfield(global_grid, 'numeric', 'Value', prev_global.beh_fps, 'Limits', [0 Inf]);
uilabel(global_grid, 'Text', 'Downsample factor:');
ds_field = uieditfield(global_grid, 'numeric', 'Value', prev_global.FP_DS_FACTOR, 'Limits', [1 Inf], 'RoundFractionalValues', 'on');
uilabel(global_grid, 'Text', 'Sec skip before 405 fit:');
fitskip_field = uieditfield(global_grid, 'numeric', 'Value', prev_global.fit_skip_sec, 'Limits', [0 Inf]);

% SV 9/8/26: isosbestic store is auto-detected (405A or 415A) per TDT
% block, not entered here. The Sst store field only appears for Dual
% Color runs - Single Color has no 2nd fluorophore to name.
if strcmp(color_mode, 'dual')
    streams_grid = uigridlayout(global_panel_grid, [1 4]);
    streams_grid.ColumnWidth = {'fit', 90, 'fit', 90};
else
    streams_grid = uigridlayout(global_panel_grid, [1 2]);
    streams_grid.ColumnWidth = {'fit', 90};
end
uilabel(streams_grid, 'Text', 'Signal store (465):');
stream465_field = uieditfield(streams_grid, 'text', 'Value', prev_global.stream_465);
if strcmp(color_mode, 'dual')
    uilabel(streams_grid, 'Text', 'Signal store (560):');
    stream560_field = uieditfield(streams_grid, 'text', 'Value', prev_global.stream_560);
end

plots_grid = uigridlayout(global_panel_grid, [1 4]);
plots_grid.ColumnWidth = {'fit', 'fit', 'fit', 'fit'};
uilabel(plots_grid, 'Text', 'Plots to generate:');
allanimals_cb = uicheckbox(plots_grid, 'Text', 'ALL_ANIMALS', 'Value', any(strcmp('ALL_ANIMALS', prev_global.plot_types)));
group_cb = uicheckbox(plots_grid, 'Text', 'GROUP', 'Value', any(strcmp('GROUP', prev_global.plot_types)));
groupclean_cb = uicheckbox(plots_grid, 'Text', 'GROUP_CLEAN', 'Value', any(strcmp('GROUP_CLEAN', prev_global.plot_types)));

% SV 9/28/26 (per user's request, like pma_extractor_SVv12's group color
% pickers): one color per group x channel, from reportPalette, used by
% every report plot. Each dropdown has a swatch beside it showing the pick.
% Single Color runs only show the two 465 pickers.
[pal_names, pal_rgb] = reportPalette();
color_keys = {'tms_pv', 'sham_pv', 'tms_sst', 'sham_sst'};
color_text = {'TMS 465 (GFP):', 'Sham 465 (GFP):', 'TMS 560 (RFP):', 'Sham 560 (RFP):'};
if strcmp(color_mode, 'dual')
    n_pickers = 4;
else
    n_pickers = 2;
end
colors_grid = uigridlayout(global_panel_grid, [1, 3*n_pickers]);
colors_grid.ColumnWidth = repmat({'fit', 110, 18}, 1, n_pickers);
color_dd = gobjects(1, n_pickers);
for ci = 1:n_pickers
    uilabel(colors_grid, 'Text', color_text{ci});
    start_name = prev_global.colors.(color_keys{ci});
    if ~any(strcmp(pal_names, start_name))
        start_name = 'Control Grey';
    end
    color_dd(ci) = uidropdown(colors_grid, 'Items', pal_names, 'Value', start_name);
    swatch = uipanel(colors_grid, 'BorderType', 'line');
    swatch.BackgroundColor = pal_rgb(strcmp(pal_names, start_name), :) / 255;
    color_dd(ci).ValueChangedFcn = @(src, ~) set(swatch, 'BackgroundColor', pal_rgb(strcmp(pal_names, src.Value), :) / 255);
end

cols_grid = uigridlayout(main_grid, [1 n]);
cols_grid.ColumnWidth = repmat({'1x'}, 1, n);

handles = cell(1, n);

for c = 1:n
    key = behavior_keys{c};
    meta = meta_all(strcmp({meta_all.key}, key));

    prev_idx = find(strcmp({prev_col_result.behavior}, key), 1);
    if ~isempty(prev_idx)
        prefill = prev_col_result(prev_idx);
    else
        prefill = struct('TRANGE_pre', meta.TRANGE_pre, 'TRANGE_post', meta.TRANGE_post, ...
            'BASELINE_PER', meta.BASELINE_PER, 'AUC_RANGE', meta.AUC_RANGE, ...
            'min_platform_bout_sec', meta.min_platform_bout_sec, ...
            'epoch_list', {meta.default_epochs}, 'shock_filter_list', {meta.default_shock_filter}, ...
            'tone_bin_list', {meta.default_tone_bins});
    end

    panel = uipanel(cols_grid, 'Title', meta.display);
    h = struct('key', {key});

    % SV 9/8/26: tone-bin listbox rows bumped (80->100, 90->95) to
    % comfortably fit the new 4th entry (Tones 7-9) without needing to
    % scroll inside the listbox.
    switch key
        case 'platform_entry_exit'
            row_heights = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 130, 100};
        case 'tone_on_vs_off_platform'
            row_heights = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 95, 100};
        case 'tone_shock_vs_noshock'
            row_heights = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 100};
        otherwise % reward
            row_heights = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit'};
    end

    pg = uigridlayout(panel, [numel(row_heights) 2]);
    pg.RowHeight = row_heights;
    pg.ColumnWidth = {'fit', '1x'};

    uilabel(pg, 'Text', 'TRANGE pre (s):');
    h.trange_pre = uieditfield(pg, 'numeric', 'Value', prefill.TRANGE_pre, 'Limits', [0 Inf]);
    uilabel(pg, 'Text', 'TRANGE post (s):');
    h.trange_post = uieditfield(pg, 'numeric', 'Value', prefill.TRANGE_post, 'Limits', [0 Inf]);
    uilabel(pg, 'Text', 'Baseline start (s):');
    h.baseline_start = uieditfield(pg, 'numeric', 'Value', prefill.BASELINE_PER(1));
    uilabel(pg, 'Text', 'Baseline end (s):');
    h.baseline_end = uieditfield(pg, 'numeric', 'Value', prefill.BASELINE_PER(2));
    uilabel(pg, 'Text', 'AUC start (s):');
    h.auc_start = uieditfield(pg, 'numeric', 'Value', prefill.AUC_RANGE(1));
    uilabel(pg, 'Text', 'AUC end (s):');
    h.auc_end = uieditfield(pg, 'numeric', 'Value', prefill.AUC_RANGE(2));

    switch key
        case 'platform_entry_exit'
            uilabel(pg, 'Text', 'Min platform bout (s):');
            h.min_bout = uieditfield(pg, 'numeric', 'Value', prefill.min_platform_bout_sec, 'Limits', [0 Inf]);
            uilabel(pg, 'Text', 'Epoch(s):');
            h.epoch_listbox = uilistbox(pg, 'Items', epoch_options, 'Multiselect', 'on', 'Value', prefill.epoch_list);
            uilabel(pg, 'Text', 'Tone bin(s):');
            h.tone_bin_listbox = uilistbox(pg, 'Items', tone_bin_options, 'Multiselect', 'on', 'Value', prefill.tone_bin_list);

        case 'tone_on_vs_off_platform'
            uilabel(pg, 'Text', 'Shock-outcome filter(s):');
            h.shock_filter_listbox = uilistbox(pg, 'Items', shock_filter_options, 'Multiselect', 'on', 'Value', prefill.shock_filter_list);
            uilabel(pg, 'Text', 'Tone bin(s):');
            h.tone_bin_listbox = uilistbox(pg, 'Items', tone_bin_options, 'Multiselect', 'on', 'Value', prefill.tone_bin_list);

        case 'tone_shock_vs_noshock'
            uilabel(pg, 'Text', 'Tone bin(s):');
            h.tone_bin_listbox = uilistbox(pg, 'Items', tone_bin_options, 'Multiselect', 'on', 'Value', prefill.tone_bin_list);
    end

    handles{c} = h;
end

button_grid = uigridlayout(main_grid, [1 2]);
button_grid.ColumnWidth = {'1x', '1x'};
uibutton(button_grid, 'Text', 'Back', 'ButtonPushedFcn', @(~, ~) onAction('back'));
uibutton(button_grid, 'Text', 'Run', 'ButtonPushedFcn', @(~, ~) onAction('continue'));

uiwait(fig);

if ~isvalid(fig) || isempty(fig.UserData.action)
    if isvalid(fig), delete(fig); end
    error('Behavior parameter entry cancelled.');
end

action = fig.UserData.action;

plot_types = {};
if allanimals_cb.Value, plot_types{end+1} = 'ALL_ANIMALS'; end %#ok<AGROW>
if group_cb.Value, plot_types{end+1} = 'GROUP'; end %#ok<AGROW>
if groupclean_cb.Value, plot_types{end+1} = 'GROUP_CLEAN'; end %#ok<AGROW>

if strcmp(color_mode, 'dual')
    stream_560_value = stream560_field.Value;
else
    stream_560_value = '';
end

global_settings = struct('beh_fps', fps_field.Value, 'FP_DS_FACTOR', ds_field.Value, ...
    'fit_skip_sec', fitskip_field.Value, 'stream_465', stream465_field.Value, ...
    'stream_560', stream_560_value, 'plot_types', {plot_types});
colors_out = prev_global.colors;
for ci = 1:n_pickers
    colors_out.(color_keys{ci}) = color_dd(ci).Value;
end
global_settings.colors = colors_out;

col_result = struct('behavior', {}, 'TRANGE_pre', {}, 'TRANGE_post', {}, 'BASELINE_PER', {}, 'AUC_RANGE', {}, ...
    'min_platform_bout_sec', {}, 'epoch_list', {}, 'shock_filter_list', {}, 'tone_bin_list', {});

for c = 1:n
    h = handles{c};
    display_name = meta_all(strcmp({meta_all.key}, h.key)).display;

    entry = struct;
    entry.behavior = h.key;
    entry.TRANGE_pre = h.trange_pre.Value;
    entry.TRANGE_post = h.trange_post.Value;
    entry.BASELINE_PER = [h.baseline_start.Value, h.baseline_end.Value];
    entry.AUC_RANGE = [h.auc_start.Value, h.auc_end.Value];

    if isfield(h, 'min_bout')
        entry.min_platform_bout_sec = h.min_bout.Value;
    else
        entry.min_platform_bout_sec = 5;
    end
    if isfield(h, 'epoch_listbox')
        entry.epoch_list = h.epoch_listbox.Value;
    else
        entry.epoch_list = {};
    end
    if isfield(h, 'shock_filter_listbox')
        entry.shock_filter_list = h.shock_filter_listbox.Value;
    else
        entry.shock_filter_list = {};
    end
    if isfield(h, 'tone_bin_listbox')
        entry.tone_bin_list = h.tone_bin_listbox.Value;
    else
        entry.tone_bin_list = {};
    end

    if strcmp(action, 'continue')
        if entry.BASELINE_PER(1) > entry.BASELINE_PER(2)
            error('%s: baseline start must be <= baseline end.', display_name);
        end
        if entry.AUC_RANGE(1) >= entry.AUC_RANGE(2)
            error('%s: AUC start must be < AUC end.', display_name);
        end
        if entry.AUC_RANGE(1) < -entry.TRANGE_pre || entry.AUC_RANGE(2) > entry.TRANGE_post
            error('%s: AUC window [%.3f %.3f] must fit inside TRANGE window [%.3f %.3f].', ...
                display_name, entry.AUC_RANGE(1), entry.AUC_RANGE(2), -entry.TRANGE_pre, entry.TRANGE_post);
        end
    end

    col_result(end+1) = entry; %#ok<AGROW>
end

delete(fig);

state = struct('col_result', col_result, 'global_settings', global_settings);

    function onAction(which)
        fig.UserData.action = which;
        uiresume(fig);
    end
end

function behavior_variants = expandBehaviorVariants(col_result)
% Turns each behavior column into one or more concrete run variants: one
% per checked platform_epoch x checked tone bin (platform_entry_exit -
% full cross product; getPlatformEpochWindows() already threads
% params.tone_numbers through for the tone-relative epochs
% tone_pre_shock/whole_tone/shock/inter_tone_interval, so this actually
% restricts which tones' windows count, not just a label - whole_session
% and pre_tone_baseline aren't tone-relative so the bin has no effect on
% those two specifically, which is expected), one per checked
% shock-outcome filter x checked tone bin (tone_on_vs_off_platform - same
% full cross product), and one per checked tone bin (tone_shock_vs_noshock).
% Tone bins come from toneBinDefinitions() (1-3 / 4-6 / 7-9 / 1-9 (all))
% as named bins rather than a per-tone checklist, since actual tone/shock
% counts vary across days - subsetTones() clamps to whatever exists.

behavior_variants = struct('behavior', {}, 'TRANGE_pre', {}, 'TRANGE_post', {}, 'BASELINE_PER', {}, ...
    'AUC_RANGE', {}, 'auc_tag', {}, 'platform_epoch', {}, 'tone_platform_shock_filter', {}, ...
    'tone_mode', {}, 'tone_numbers', {}, 'tone_tag', {}, 'min_platform_bout_sec', {}, ...
    'requires_footshock', {}, 'variant_tag', {});

bins = toneBinDefinitions();

for i = 1:numel(col_result)
    c = col_result(i);

    switch c.behavior
        case 'platform_entry_exit'
            if isempty(c.epoch_list)
                error('Platform Entries/Exits: at least one epoch must be checked.');
            end
            if isempty(c.tone_bin_list)
                error('Platform Entries/Exits: at least one tone bin must be checked.');
            end
            for e = 1:numel(c.epoch_list)
                epoch = c.epoch_list{e};
                for b = 1:numel(c.tone_bin_list)
                    bin_label = c.tone_bin_list{b};
                    bin_numbers = bins(strcmp({bins.label}, bin_label)).numbers;
                    behavior_variants(end+1) = makeVariant(c, 'platform_entry_exit', epoch, 'all_trials', ...
                        bin_numbers, sprintf('epoch:%s|%s', epoch, bin_label), ...
                        any(strcmp(epoch, {'tone_pre_shock', 'shock'}))); %#ok<AGROW>
                end
            end

        case 'tone_on_vs_off_platform'
            if isempty(c.shock_filter_list)
                error('Tone Onset (On vs Off Platform): at least one shock-outcome filter must be checked.');
            end
            if isempty(c.tone_bin_list)
                error('Tone Onset (On vs Off Platform): at least one tone bin must be checked.');
            end
            for f = 1:numel(c.shock_filter_list)
                filt = c.shock_filter_list{f};
                for b = 1:numel(c.tone_bin_list)
                    bin_label = c.tone_bin_list{b};
                    bin_numbers = bins(strcmp({bins.label}, bin_label)).numbers;
                    behavior_variants(end+1) = makeVariant(c, 'tone_on_vs_off_platform', 'whole_session', filt, ...
                        bin_numbers, sprintf('shockfilter:%s|%s', filt, bin_label), false); %#ok<AGROW>
                end
            end

        case 'tone_shock_vs_noshock'
            if isempty(c.tone_bin_list)
                error('Tone Shock vs No-shock: at least one tone bin must be checked.');
            end
            for b = 1:numel(c.tone_bin_list)
                bin_label = c.tone_bin_list{b};
                bin_numbers = bins(strcmp({bins.label}, bin_label)).numbers;
                behavior_variants(end+1) = makeVariant(c, 'tone_shock_vs_noshock', 'whole_session', 'all_trials', ...
                    bin_numbers, bin_label, true); %#ok<AGROW>
            end

        case 'reward'
            behavior_variants(end+1) = makeVariant(c, 'reward', 'whole_session', 'all_trials', ...
                [], 'default', false); %#ok<AGROW>
    end
end

    function v = makeVariant(c, behavior, epoch, shock_filter, tone_numbers, variant_tag, requires_footshock)
        v = struct;
        v.behavior = behavior;
        v.TRANGE_pre = c.TRANGE_pre;
        v.TRANGE_post = c.TRANGE_post;
        v.BASELINE_PER = c.BASELINE_PER;
        v.AUC_RANGE = c.AUC_RANGE;
        v.auc_tag = makeAUCTag(c.AUC_RANGE);
        v.platform_epoch = epoch;
        v.tone_platform_shock_filter = shock_filter;
        v.min_platform_bout_sec = c.min_platform_bout_sec;
        v.requires_footshock = requires_footshock;
        v.variant_tag = variant_tag;

        tone_numbers = sort(tone_numbers);
        if strcmp(behavior, 'reward')
            v.tone_mode = 'all_rewards';
            v.tone_numbers = [];
            v.tone_tag = 'all_rewards';
        elseif isequal(tone_numbers, 1:9)
            v.tone_mode = 'all_tones';
            v.tone_numbers = tone_numbers;
            v.tone_tag = 'all_tones';
        else
            v.tone_mode = 'custom';
            v.tone_numbers = tone_numbers;
            tone_str = sprintf('%d_', tone_numbers);
            tone_str(end) = [];
            v.tone_tag = ['tones_' tone_str];
        end
    end
end

% ================================================================== %
%  AUC CALCULATION AND EXPORT HELPERS                                 %
% ================================================================== %

function auc = calculateAUCFromTraceMatrix(trace_matrix, params)
% Calculate trial-level and per-animal mean-trace AUC from unsmoothed z data.
% Units are z-score * seconds.

if isempty(trace_matrix)
    auc = makeEmptyAUCStruct(params);
    return;
end

if isvector(trace_matrix)
    trace_matrix = reshape(trace_matrix, 1, []);
end

x_axis = linspace(-params.TRANGE_pre, params.TRANGE_post, size(trace_matrix, 2));
idx = find(x_axis >= params.AUC_RANGE(1) & x_axis <= params.AUC_RANGE(2));

if numel(idx) < 2
    error('AUC window %.3f to %.3f sec contains fewer than 2 samples. Increase the window or decrease downsampling.', ...
        params.AUC_RANGE(1), params.AUC_RANGE(2));
end

x_auc = x_axis(idx);
auc_trials = nan(size(trace_matrix, 1), 1);

for tr = 1:size(trace_matrix, 1)
    y = trace_matrix(tr, idx);
    valid = isfinite(x_auc) & isfinite(y);
    if sum(valid) >= 2
        auc_trials(tr) = trapz(x_auc(valid), y(valid));
    end
end

mean_trace = mean(trace_matrix, 1, 'omitnan');
mean_y = mean_trace(idx);
valid_mean = isfinite(x_auc) & isfinite(mean_y);
if sum(valid_mean) >= 2
    auc_mean_trace = trapz(x_auc(valid_mean), mean_y(valid_mean));
else
    auc_mean_trace = NaN;
end

n_valid_trials = sum(isfinite(auc_trials));
if n_valid_trials > 0
    auc_mean_of_trials = mean(auc_trials, 'omitnan');
    auc_std_of_trials = std(auc_trials, 0, 'omitnan');
    auc_sem_of_trials = auc_std_of_trials ./ sqrt(n_valid_trials);
else
    auc_mean_of_trials = NaN;
    auc_std_of_trials = NaN;
    auc_sem_of_trials = NaN;
end

auc = struct;
auc.range_sec = params.AUC_RANGE;
auc.tag = params.auc_tag;
auc.units = 'z_score_seconds';
auc.sample_indices = idx;
auc.n_samples = numel(idx);
auc.trial_auc = auc_trials;
auc.mean_of_trials = auc_mean_of_trials;
auc.std_of_trials = auc_std_of_trials;
auc.sem_of_trials = auc_sem_of_trials;
auc.mean_trace_auc = auc_mean_trace;
auc.n_trials = size(trace_matrix, 1);
auc.n_valid_trials = n_valid_trials;
auc.method = 'trapz over unsmoothed event-aligned z-score trace';
end

function auc = makeEmptyAUCStruct(params)
auc = struct;
if isfield(params, 'AUC_RANGE')
    auc.range_sec = params.AUC_RANGE;
else
    auc.range_sec = [NaN NaN];
end
if isfield(params, 'auc_tag')
    auc.tag = params.auc_tag;
else
    auc.tag = '';
end
auc.units = 'z_score_seconds';
auc.sample_indices = [];
auc.n_samples = 0;
auc.trial_auc = [];
auc.mean_of_trials = NaN;
auc.std_of_trials = NaN;
auc.sem_of_trials = NaN;
auc.mean_trace_auc = NaN;
auc.n_trials = 0;
auc.n_valid_trials = 0;
auc.method = 'trapz over unsmoothed event-aligned z-score trace';
end

function auc_tables = exportAUCTables(group_result, params, results_root)
% Export one row per animal/channel/condition and Prism-ready wide files.
%
% Main outputs:
%   - AUC_all_animals_long_<auc_tag>.csv
%   - AUC_trial_level_long_<auc_tag>.csv
%   - AUC_all_exports_<auc_tag>.xlsx
%   - AUC_tables_<auc_tag>.mat
%   - Prism_AUC_Wide_CSVs/*.csv with 560 and 465 as paired columns per condition

condition_labels = getConditionLabelsFromResults(group_result);

auc_tables = struct;
if isempty(condition_labels)
    warning('No condition labels found. Skipping AUC export.');
    auc_tables.long = table();
    auc_tables.trials = table();
    return;
end

auc_dir = fullfile(results_root, 'AUC_Exports');
if ~exist(auc_dir, 'dir'), mkdir(auc_dir); end

prism_dir = fullfile(auc_dir, 'Prism_AUC_Wide_CSVs');
if ~exist(prism_dir, 'dir'), mkdir(prism_dir); end

channels = {'sst', 'pv'};

row_day_label      = strings(0,1);
row_mouse          = strings(0,1);
row_channel        = strings(0,1);
row_condition      = strings(0,1);
row_auc_start      = [];
row_auc_end        = [];
row_auc_mean_trace = [];
row_auc_mean_trial = [];
row_auc_sem_trial  = [];
row_n_trials       = [];
row_n_valid_trials = [];
row_behavior       = strings(0,1);
row_tone_tag       = strings(0,1);

trial_day_label  = strings(0,1);
trial_mouse      = strings(0,1);
trial_channel    = strings(0,1);
trial_condition  = strings(0,1);
trial_index      = [];
trial_auc_value  = [];
trial_auc_start  = [];
trial_auc_end    = [];
trial_behavior   = strings(0,1);
trial_tone_tag   = strings(0,1);

for ai = 1:numel(group_result.animals)
    animal_file = group_result.animals(ai).save_file;
    if ~isfile(animal_file), continue; end

    S = load(animal_file, 'animal_result');
    ar = S.animal_result;

    for ci = 1:numel(condition_labels)
        cond = condition_labels{ci};

        for chi = 1:numel(channels)
            channel = channels{chi};

            if ~isfield(ar.analysis, channel) || ~isfield(ar.analysis.(channel), cond)
                continue;
            end

            entry = ar.analysis.(channel).(cond);
            auc = getAUCStructFromEntry(entry, params);

            row_day_label(end+1,1)      = string(params.day_label); %#ok<AGROW>
            row_mouse(end+1,1)          = string(ar.mouse); %#ok<AGROW>
            row_channel(end+1,1)        = string(channelDisplayName(channel)); %#ok<AGROW>
            row_condition(end+1,1)      = string(cond); %#ok<AGROW>
            row_auc_start(end+1,1)      = auc.range_sec(1); %#ok<AGROW>
            row_auc_end(end+1,1)        = auc.range_sec(2); %#ok<AGROW>
            row_auc_mean_trace(end+1,1) = auc.mean_trace_auc; %#ok<AGROW>
            row_auc_mean_trial(end+1,1) = auc.mean_of_trials; %#ok<AGROW>
            row_auc_sem_trial(end+1,1)  = auc.sem_of_trials; %#ok<AGROW>
            row_n_trials(end+1,1)       = auc.n_trials; %#ok<AGROW>
            row_n_valid_trials(end+1,1) = auc.n_valid_trials; %#ok<AGROW>
            row_behavior(end+1,1)       = string(params.behavior); %#ok<AGROW>
            row_tone_tag(end+1,1)       = string(params.tone_tag); %#ok<AGROW>

            for ti = 1:numel(auc.trial_auc)
                trial_day_label(end+1,1) = string(params.day_label); %#ok<AGROW>
                trial_mouse(end+1,1)     = string(ar.mouse); %#ok<AGROW>
                trial_channel(end+1,1)   = string(channelDisplayName(channel)); %#ok<AGROW>
                trial_condition(end+1,1) = string(cond); %#ok<AGROW>
                trial_index(end+1,1)     = ti; %#ok<AGROW>
                trial_auc_value(end+1,1) = auc.trial_auc(ti); %#ok<AGROW>
                trial_auc_start(end+1,1) = auc.range_sec(1); %#ok<AGROW>
                trial_auc_end(end+1,1)   = auc.range_sec(2); %#ok<AGROW>
                trial_behavior(end+1,1)  = string(params.behavior); %#ok<AGROW>
                trial_tone_tag(end+1,1)  = string(params.tone_tag); %#ok<AGROW>
            end
        end
    end
end

long_table = table( ...
    row_day_label, row_mouse, row_channel, row_condition, ...
    row_auc_start, row_auc_end, row_auc_mean_trace, row_auc_mean_trial, ...
    row_auc_sem_trial, row_n_trials, row_n_valid_trials, ...
    row_behavior, row_tone_tag, ...
    'VariableNames', { ...
        'DayLabel', 'Mouse', 'Channel', 'Condition', ...
        'AUC_Start_s', 'AUC_End_s', 'AUC_MeanTrace', 'AUC_MeanOfTrials', ...
        'AUC_SEMOfTrials', 'NTrials', 'NValidTrials', ...
        'Behavior', 'ToneTag'});

trial_table = table( ...
    trial_day_label, trial_mouse, trial_channel, trial_condition, ...
    trial_index, trial_auc_value, trial_auc_start, trial_auc_end, ...
    trial_behavior, trial_tone_tag, ...
    'VariableNames', { ...
        'DayLabel', 'Mouse', 'Channel', 'Condition', ...
        'TrialIndex', 'TrialAUC', 'AUC_Start_s', 'AUC_End_s', ...
        'Behavior', 'ToneTag'});

auc_tables.long = long_table;
auc_tables.trials = trial_table;

long_csv = fullfile(auc_dir, sprintf('AUC_all_animals_long_%s.csv', params.auc_tag));
trial_csv = fullfile(auc_dir, sprintf('AUC_trial_level_long_%s.csv', params.auc_tag));
long_xlsx = fullfile(auc_dir, sprintf('AUC_all_exports_%s.xlsx', params.auc_tag));
long_mat = fullfile(auc_dir, sprintf('AUC_tables_%s.mat', params.auc_tag));

writetable(long_table, long_csv);
writetable(trial_table, trial_csv);
try
    writetable(long_table, long_xlsx, 'Sheet', 'AUC_animal_level');
    writetable(trial_table, long_xlsx, 'Sheet', 'AUC_trial_level');
catch ME
    warning('Could not write AUC XLSX file. CSV export still succeeded.\n%s', ME.message);
end

auc_tables.prism = struct;

% Prism-friendly exports: one paired numeric 560/465 table per condition.
for ci = 1:numel(condition_labels)
    cond = condition_labels{ci};

    wide_table = makeChannelPrismTable(long_table, cond);

    wide_base = sprintf('PrismWide_AUC_560_vs_465_%s_%s', cond, params.auc_tag);
    wide_base = sanitizeFilename(wide_base);

    wide_csv = fullfile(prism_dir, [wide_base '.csv']);
    writetable(wide_table, wide_csv);

    sheet_name = makeValidSheetName(sprintf('Ch560_Ch465_%s', cond));
    try
        writetable(wide_table, long_xlsx, 'Sheet', sheet_name);
    catch ME
        warning('Could not append Prism-wide sheet "%s" to XLSX.\n%s', sheet_name, ME.message);
    end

    field_name = matlab.lang.makeValidName(sprintf('Ch560_vs_Ch465_%s', cond));
    auc_tables.prism.(field_name) = wide_table;
end

save(long_mat, 'auc_tables', 'params', '-v7');

fprintf('\nAUC exports saved to:\n%s\n', auc_dir);
fprintf('Prism-ready 560-vs-465 wide CSV files saved to:\n%s\n', prism_dir);
fprintf('AUC window: %.3f to %.3f sec relative to event.\n', params.AUC_RANGE(1), params.AUC_RANGE(2));
end

function auc = getAUCStructFromEntry(entry, params)
if isfield(entry, 'auc') && isstruct(entry.auc) && isfield(entry.auc, 'mean_trace_auc')
    auc = entry.auc;
else
    if isfield(entry, 'trial_matrix')
        auc = calculateAUCFromTraceMatrix(entry.trial_matrix, params);
    else
        auc = makeEmptyAUCStruct(params);
    end
end
end

function wide_table = makeChannelPrismTable(long_table, condition_label)
% SV 9/8/26: renamed from makeSstPvPrismTable and relabeled by wavelength
% (Ch560/Ch465) rather than this lab's cell-type reporter names, so the
% exported columns read sensibly for another lab's data too.
keep_cond = long_table.Condition == string(condition_label);
mice = unique(long_table.Mouse(keep_cond), 'stable');

ch560_vals = nan(numel(mice), 1);
ch465_vals = nan(numel(mice), 1);

for mi = 1:numel(mice)
    keep_560 = keep_cond & long_table.Mouse == mice(mi) & long_table.Channel == "560";
    keep_465 = keep_cond & long_table.Mouse == mice(mi) & long_table.Channel == "465";

    if any(keep_560)
        v = long_table.AUC_MeanTrace(keep_560);
        ch560_vals(mi) = v(1);
    end
    if any(keep_465)
        v = long_table.AUC_MeanTrace(keep_465);
        ch465_vals(mi) = v(1);
    end
end

wide_table = table(ch560_vals, ch465_vals, 'VariableNames', {'Ch560', 'Ch465'});
end

function tag = makeAUCTag(auc_range)
start_tag = formatTimeForTag(auc_range(1));
end_tag = formatTimeForTag(auc_range(2));
tag = sprintf('%s_to_%s', start_tag, end_tag);
end

function out = formatTimeForTag(x)
if x < 0
    prefix = 'neg';
else
    prefix = '';
end
x_abs = abs(x);
out = sprintf('%s%g', prefix, x_abs);
out = strrep(out, '.', 'p');
end

function fname = sanitizeFilename(fname)
fname = regexprep(fname, '[^\w\-]', '_');
fname = regexprep(fname, '_+', '_');
fname = regexprep(fname, '_$', '');
end

function sheet_name = makeValidSheetName(sheet_name)
sheet_name = regexprep(sheet_name, '[\\/\?\*\[\]:]', '_');
if strlength(string(sheet_name)) > 31
    sheet_name = char(extractBefore(string(sheet_name), 32));
end
if isempty(sheet_name)
    sheet_name = 'Sheet1';
end
end

function video_folder_list = prepBatch(video_directory)

video_directory = char(video_directory);
directory_contents = dir(video_directory);

ignore_names = [".", "..", "Photometry_Results", "TDT"];

video_folder_list = strings(0,1);

for i = 1:numel(directory_contents)

    item = directory_contents(i);

    if ~item.isdir
        continue;
    end

    item_name = string(item.name);

    if any(strcmp(item_name, ignore_names))
        continue;
    end

    full_item_path = fullfile(video_directory, item.name);

    has_photometry = ~isempty(dir(fullfile(full_item_path, '*_photometry')));
    has_analyzed   = ~isempty(dir(fullfile(full_item_path, '*_analyzed')));

    if ~(has_photometry && has_analyzed)
        continue;
    end

    video_folder_list(end+1,1) = item_name; %#ok<AGROW>
end

video_folder_list = sort(video_folder_list);

end

function processed = loadAndProcessPhotometrySignals(block_folder, exp_filename, beh_file_fullpath, params)

block_folder = char(block_folder);
exp_filename = char(exp_filename);
beh_file_fullpath = char(beh_file_fullpath);

data = TDTbin2mat(block_folder, 'TYPE', {'epocs', 'scalars', 'streams'});

% SV 9/8/26: the 560/Sst channel is now optional - some cohorts (e.g. the
% PVcre.Fp Aug-2026 dataset) are recorded single-color (isosbestic +
% one signal store only, no second fluorophore). Leaving the "560 store"
% global setting blank means "this cohort has no Sst channel"; everything
% downstream (runSingleCondition, plotting, AUC export) already tolerates
% an empty sst trial_matrix/mean_trace the same way it tolerates an empty
% event window, so Pv-only processing falls out of that for free.
has_sst = ~isempty(params.STREAM_STORE_560);

% SV 9/8/26: isosbestic store name auto-detected per block (405A vs
% 415A) per user request, rather than a fixed/manually-entered name -
% different rig configs across cohorts have used both.
store405 = resolveIsosbesticStore(data);
requireStream(data, params.STREAM_STORE_465);
if has_sst
    requireStream(data, params.STREAM_STORE_560);
end

% SV 9/8/26: pass STREAM_STORE_465 explicitly - beh2FPfrlu_SVv2 used to
% hardcode x560B for its frame-rate reference, which doesn't exist for
% single-color cohorts. 465 is always present.
beh2fp = beh2FPfrlu_SVv2(exp_filename, beh_file_fullpath, data, params.STREAM_STORE_465);

s405 = data.streams.(store405).data;
s465 = data.streams.(params.STREAM_STORE_465).data;
if has_sst
    s560 = data.streams.(params.STREAM_STORE_560).data;
else
    s560 = [];
end

ds = params.FP_DS_FACTOR;
s405 = s405(1:ds:end);
s465 = s465(1:ds:end);
if has_sst
    s560 = s560(1:ds:end);
end
beh2fp = max(1, round(beh2fp / ds));

raw_fs = getSamplingRate(data, store405);
ds_fs = raw_fs / ds;
fit_start = max(1, round(params.fit_skip_sec * ds_fs) + 1);

if has_sst
    [fit_sst, coeffs_sst] = fit405toSignal(s405, s560, fit_start);
    sig_sst = s560 - fit_sst;
else
    fit_sst = [];
    coeffs_sst = [];
    sig_sst = [];
end

[fit_pv, coeffs_pv] = fit405toSignal(s405, s465, fit_start);
sig_pv = s465 - fit_pv;

processed = struct;
processed.data = data;
processed.beh2fp = beh2fp;
processed.s405 = s405;
processed.s465 = s465;
processed.s560 = s560;
processed.sig_sst = sig_sst;
processed.sig_pv = sig_pv;
processed.fit_sst = fit_sst;
processed.fit_pv = fit_pv;
processed.fit_coeffs_sst = coeffs_sst;
processed.fit_coeffs_pv = coeffs_pv;
processed.channel_map = struct('sst', params.STREAM_STORE_560, 'pv', params.STREAM_STORE_465);
processed.stream_405_used = store405;
% SV 9/8/26: sample rate of the (downsampled) continuous signals saved so
% the QC report page can build a real seconds time axis for
% animal_result.signals.pv/sst later, without re-deriving it from the raw
% TDT block.
processed.ds_fs = ds_fs;

end

function [y_fit, p] = fit405toSignal(x405, ysig, fit_start)

fit_start = min(max(1, fit_start), numel(x405));

x = double(x405(fit_start:end));
y = double(ysig(fit_start:end));

valid = isfinite(x) & isfinite(y);
x = x(valid);
y = y(valid);

if numel(x) < 10
    warning('Very few valid points available for 405 fit. Using constant fallback.');
    p = [0; mean(ysig,'omitnan')];
    y_fit = p(1).*double(x405) + p(2);
    return;
end

x_range = max(x) - min(x);
x_std = std(x, 'omitnan');

if x_range < 1e-6 || x_std < 1e-4
    warning('405 channel has near-zero variance in fit window. Using constant fallback.');
    p = [0; mean(y,'omitnan')];
    y_fit = p(1).*double(x405) + p(2);
    return;
end

x_mean = mean(x, 'omitnan');
y_mean = mean(y, 'omitnan');
xc = x - x_mean;

xc_var = sum(xc.^2);
if xc_var < 1e-8
    warning('Centered 405 variance too small for stable fit. Using constant fallback.');
    p = [0; y_mean];
    y_fit = p(1).*double(x405) + p(2);
    return;
end

slope = sum(xc .* (y - y_mean)) / xc_var;
intercept = y_mean - slope * x_mean;

p = [slope; intercept];
y_fit = slope .* double(x405) + intercept;

end

function requireStream(data, stream_name)

if ~isfield(data, 'streams') || ~isfield(data.streams, stream_name)
    error('Required TDT stream "%s" not found.', stream_name);
end

end

function store_name = resolveIsosbesticStore(data)
% SV 9/8/26: auto-detects the isosbestic control store rather than
% requiring it to be typed in - different rigs/cohorts have recorded it
% as either "405A" or "415A" (TDTbin2mat exposes both as data.streams.x*
% since MATLAB field names can't start with a digit).
candidates = {'x405A', 'x415A'};

for i = 1:numel(candidates)
    if isfield(data, 'streams') && isfield(data.streams, candidates{i})
        store_name = candidates{i};
        return;
    end
end

if isfield(data, 'streams')
    available = strjoin(fieldnames(data.streams), ', ');
else
    available = '(no streams found)';
end
error('No isosbestic control stream found (looked for x405A and x415A). Streams present: %s', available);

end

function fs = getSamplingRate(data, stream_name)

stream = data.streams.(stream_name);

if isfield(stream, 'fs') && ~isempty(stream.fs) && isfinite(stream.fs)
    fs = double(stream.fs);
else
    error('Sampling rate missing for stream %s.', stream_name);
end

end

function event_data = getBehaviorEvents(Behavior, cueframes, params, rewardframes)

validateBehaviorStruct(Behavior);

event_data = struct;
beh_vec = Behavior.Spatial.platform.inROIvector;
beh_vec = beh_vec(:);
fps = params.beh_fps;
threshold_frames = round(params.min_platform_bout_sec * fps);

if nargin < 4
    rewardframes = [];
end

switch params.behavior

    case 'platform_entry_exit'

        roi = beh_vec;
        transitions = diff([0; roi(:); 0]);
        bout_starts = find(transitions == 1);
        bout_ends   = find(transitions == -1) - 1;
        bouts = [bout_starts, bout_ends];

        % SV 9/9/26 (per user's request): merge two platform bouts
        % separated by a short (<2s) off-platform gap into one continuous
        % visit BEFORE applying the minimum-bout-duration filter below -
        % without this, a mouse hovering right at the ROI boundary
        % (ducking out for a couple seconds and back in several times in
        % a row) gets counted as several separate short entries/exits
        % instead of the one episode a human would call it.
        merge_gap_frames = round(2 * fps);
        bouts = mergeCloseBouts(bouts, merge_gap_frames);

        for i = size(bouts,1):-1:1
            if bouts(i,2) - bouts(i,1) < threshold_frames
                bouts(i,:) = [];
            end
        end

        entries = [bouts(:,1), bouts(:,1)];
        exits = [bouts(:,2), bouts(:,2)];

        entries = filterPlatformEventsByEpoch(entries, cueframes, length(beh_vec), fps, params);
        exits = filterPlatformEventsByEpoch(exits, cueframes, length(beh_vec), fps, params);

        entries = trimEventsToWindow(entries, length(beh_vec), fps, params.TRANGE_pre, params.TRANGE_post);
        exits = trimEventsToWindow(exits, length(beh_vec), fps, params.TRANGE_pre, params.TRANGE_post);

        event_data.eventA = entries;
        event_data.eventA_label = makePlatformEpochAwareLabel('platform_entry', params);

        event_data.eventB = exits;
        event_data.eventB_label = makePlatformEpochAwareLabel('platform_exit', params);

    case 'tone_on_vs_off_platform'
        tones = cueframes;
        tones = subsetTones(tones, params.tone_numbers);
        tones(:,2) = tones(:,1);
        tones = filterToneEventsByShockOutcome(tones, beh_vec, fps, params);
        tones = trimEventsToWindow(tones, length(beh_vec), fps, params.TRANGE_pre, params.TRANGE_post);

        tonesOnP = tones;
        tonesOffP = tones;

        for i = size(tones,1):-1:1
            tone_idx = round(tones(i,1));
            if beh_vec(tone_idx) == 0
                tonesOnP(i,:) = [];
            end
            if beh_vec(tone_idx) == 1
                tonesOffP(i,:) = [];
            end
        end

        event_data.eventA = tonesOnP;
        event_data.eventA_label = makeTonePlatformShockAwareLabel('tone_on_platform', params);

        event_data.eventB = tonesOffP;
        event_data.eventB_label = makeTonePlatformShockAwareLabel('tone_off_platform', params);

    case 'tone_shock_vs_noshock'
        tones = cueframes;
        tones = subsetTones(tones, params.tone_numbers);
        tones(:,2) = tones(:,1);
        tones = trimEventsToWindow(tones, length(beh_vec), fps, params.TRANGE_pre, params.TRANGE_post);

        tonesSh = tones;
        tonesNS = tones;

        for i = size(tones,1):-1:1
            start_idx = round(tones(i,1) + 28*fps);
            end_idx = round(tones(i,1) + 30*fps);

            if start_idx < 1 || end_idx > length(beh_vec)
                tonesSh(i,:) = [];
                tonesNS(i,:) = [];
                continue;
            end

            if any(beh_vec(start_idx:end_idx) == 0)
                tonesNS(i,:) = [];
            else
                tonesSh(i,:) = [];
            end
        end

        event_data.eventA = tonesSh;
        event_data.eventA_label = makeToneAwareLabel('tone_shock', params);

        event_data.eventB = tonesNS;
        event_data.eventB_label = makeToneAwareLabel('tone_noshock', params);

    case 'reward'
        if isempty(rewardframes)
            error('Reward analysis selected, but no reward frame data was provided.');
        end

        rewards = rewardframes;
        rewards = trimEventsToWindow(rewards, length(beh_vec), fps, params.TRANGE_pre, params.TRANGE_post);

        event_data.eventA = rewards;
        event_data.eventA_label = 'reward';

    otherwise
        error('Unknown behavior option: %s', params.behavior);
end

end

function bouts_out = mergeCloseBouts(bouts_in, max_gap_frames)
% Merges consecutive [start end] bout rows (already sorted by start
% frame - findStartStop-style diff detection naturally produces them in
% order) whenever the OFF-platform gap between one bout's end and the
% next bout's start is shorter than max_gap_frames - collapsing
% boundary-hovering (several brief re-entries a couple seconds apart)
% into one continuous visit before the minimum-bout-duration threshold is
% applied.
bouts_out = bouts_in;
if size(bouts_out, 1) < 2
    return;
end
i = 1;
while i < size(bouts_out, 1)
    gap = bouts_out(i+1, 1) - bouts_out(i, 2) - 1;
    if gap < max_gap_frames
        bouts_out(i, 2) = bouts_out(i+1, 2);
        bouts_out(i+1, :) = [];
    else
        i = i + 1;
    end
end
end

function tones_out = filterToneEventsByShockOutcome(tones_in, beh_vec, fps, params)

if isempty(tones_in) || ~isfield(params, 'tone_platform_shock_filter') || strcmp(params.tone_platform_shock_filter, 'all_trials')
    tones_out = tones_in;
    return;
end

tones_out = tones_in;

for i = size(tones_in,1):-1:1
    tone_start = round(tones_in(i,1));
    shock_start = round(tone_start + 28*fps);
    shock_end = round(tone_start + 30*fps);

    if shock_start < 1 || shock_end > length(beh_vec)
        tones_out(i,:) = [];
        continue;
    end

    was_shocked = any(beh_vec(shock_start:shock_end) == 0);

    switch params.tone_platform_shock_filter
        case 'shocked_trials'
            if ~was_shocked
                tones_out(i,:) = [];
            end
        case 'no_shock_trials'
            if was_shocked
                tones_out(i,:) = [];
            end
        otherwise
            error('Unknown tone on/off platform shock-outcome filter: %s', params.tone_platform_shock_filter);
    end
end

end

function label_out = makeTonePlatformShockAwareLabel(base_label, params)

label_out = makeToneAwareLabel(base_label, params);

if ~isfield(params, 'tone_platform_shock_filter') || strcmp(params.tone_platform_shock_filter, 'all_trials')
    return;
end

label_out = sprintf('%s_%s', label_out, params.tone_platform_shock_filter);

end

function events_out = filterPlatformEventsByEpoch(events_in, cueframes, signal_length, fps, params)

if isempty(events_in) || ~isfield(params, 'platform_epoch') || strcmp(params.platform_epoch, 'whole_session')
    events_out = events_in;
    return;
end

windows = getPlatformEpochWindows(cueframes, signal_length, fps, params);
events_out = events_in;

if isempty(windows)
    events_out = zeros(0, size(events_in,2));
    return;
end

for i = size(events_out,1):-1:1
    event_idx = round(events_out(i,1));
    if ~eventInWindows(event_idx, windows)
        events_out(i,:) = [];
    end
end

end

function windows = getPlatformEpochWindows(cueframes, signal_length, fps, params)

windows = [];

switch params.platform_epoch
    case 'pre_tone_baseline'
        if isempty(cueframes)
            windows = [1 signal_length];
        else
            windows = [1 max(1, round(cueframes(1,1)) - 1)];
        end

    case 'tone_pre_shock'
        tones = subsetTones(cueframes, params.tone_numbers);
        tone_start = round(tones(:,1));
        tone_pre_shock_end = round(tones(:,1) + 28*fps) - 1;
        windows = [tone_start tone_pre_shock_end];

    case 'whole_tone'
        tones = subsetTones(cueframes, params.tone_numbers);
        windows = round(tones(:,1:2));

    case 'shock'
        tones = subsetTones(cueframes, params.tone_numbers);
        shock_start = round(tones(:,1) + 28*fps);
        shock_end = round(tones(:,1) + 30*fps);
        windows = [shock_start shock_end];

    case 'inter_tone_interval'
        selected_tones = params.tone_numbers(:)';
        selected_tones = selected_tones(selected_tones >= 1 & selected_tones < size(cueframes,1));

        if isempty(selected_tones)
            windows = zeros(0,2);
            return;
        end

        windows = zeros(numel(selected_tones), 2);
        for k = 1:numel(selected_tones)
            tone_idx = selected_tones(k);
            windows(k,:) = [round(cueframes(tone_idx,2)) + 1, round(cueframes(tone_idx+1,1)) - 1];
        end

    otherwise
        error('Unknown platform epoch option: %s', params.platform_epoch);
end

windows(:,1) = max(1, windows(:,1));
windows(:,2) = min(signal_length, windows(:,2));
windows = windows(windows(:,2) >= windows(:,1), :);

end

function tf = eventInWindows(event_idx, windows)

tf = any(event_idx >= windows(:,1) & event_idx <= windows(:,2));

end

function label_out = makePlatformEpochAwareLabel(base_label, params)

if ~isfield(params, 'platform_epoch') || strcmp(params.platform_epoch, 'whole_session')
    label_out = base_label;
    return;
end

label_out = sprintf('%s_%s', base_label, params.platform_epoch);

if isfield(params, 'tone_mode') && ~strcmp(params.tone_mode, 'all_tones') && ...
        any(strcmp(params.platform_epoch, {'tone_pre_shock', 'shock', 'inter_tone_interval', 'whole_tone'}))
    tone_str = sprintf('%d_', params.tone_numbers);
    tone_str(end) = [];
    label_out = sprintf('%s_tones_%s', label_out, tone_str);
end

end

function tones_out = subsetTones(cueframes, tone_numbers)

n_available = size(cueframes,1);

if isempty(tone_numbers)
    error('No tone numbers selected.');
end

% SV 5/22/26 I changed this:
% if any(tone_numbers < 1) || any(tone_numbers > n_available)
%     error('Requested tone number exceeds number of tones in Cue file. Available tones: 1-%d', n_available);
% end
% to this:
tone_numbers = tone_numbers(tone_numbers >= 1 & tone_numbers <= n_available);
% If tone_numbers is 1:9 (all_tones), clamp to however many tones exist


tones_out = cueframes(tone_numbers, :);

end

function label_out = makeToneAwareLabel(base_label, params)

if strcmp(params.tone_mode, 'all_tones')
    label_out = base_label;
    return;
end

tone_str = sprintf('%d_', params.tone_numbers);
tone_str(end) = [];

label_out = sprintf('%s_tones_%s', base_label, tone_str);

end

function events = trimEventsToWindow(events, signal_length, fps, trange_pre, trange_post)

if isempty(events)
    return;
end

for i = size(events,1):-1:1
    event_idx = round(events(i,1));
    first_needed = event_idx - round(trange_pre * fps);
    last_needed = event_idx + round(trange_post * fps);

    if first_needed < 1 || last_needed > signal_length
        events(i,:) = [];
    end
end

end

function validateBehaviorStruct(Behavior)

required_paths = { ...
    {'Spatial', 'platform', 'inROIvector'}};

for i = 1:numel(required_paths)
    path_parts = required_paths{i};
    current = Behavior;
    for j = 1:numel(path_parts)
        field_name = path_parts{j};
        if ~isstruct(current) || ~isfield(current, field_name)
            error('Behavior structure missing required field: %s', strjoin(path_parts, '.'));
        end
        current = current.(field_name);
    end
end

end

function cumulative = appendTraceMatrix(cumulative, new_data)

if isempty(new_data)
    return;
end

if isvector(new_data)
    new_data = reshape(new_data, 1, []);
end

if isempty(cumulative)
    cumulative = new_data;
    return;
end

if size(new_data,2) ~= size(cumulative,2)
    new_width = min(size(new_data,2), size(cumulative,2));
    warning('Trace lengths differ (%d vs %d). Truncating to shortest shared length (%d).', ...
        size(cumulative,2), size(new_data,2), new_width);
    cumulative = cumulative(:, 1:new_width);
    new_data = new_data(:, 1:new_width);
end

cumulative = [cumulative; new_data];

end

function [x_out, data_out] = thinSmoothedTraces(x_axis, data)
% SV 9/28/26: keeps every k-th sample of already-smoothed trace rows so a
% panel is drawn from ~800 points per trace instead of every ~100 Hz
% sample (thousands per trace, every one a vector vertex in the PDF). The
% traces have just been through a 25-sample moving mean, so a stride of a
% few samples drops nothing visible; the last sample is always kept so
% the trace still reaches the end of the window. Used for drawing only -
% AUC and the saved data are computed from the full-rate trial matrix.
target = 800;
n = numel(x_axis);
if n <= target
    x_out = x_axis;
    data_out = data;
    return;
end
k = floor(n / target);
idx = 1:k:n;
if idx(end) ~= n
    idx(end+1) = n;
end
x_out = x_axis(idx);
data_out = data(:, idx);
end

function [x_out, y_out] = decimateMinMax(x, y, n_bins)
% SV 9/28/26: min/max-envelope decimation of an UNSMOOTHED signal for
% plotting: split into n_bins equal runs and keep each run's lowest and
% highest sample, in time order. Peaks and troughs survive exactly (unlike
% plain subsampling, which can step over a spike), while the vertex count
% drops to 2*n_bins.
x = x(:)';
y = y(:)';
n = numel(y);
if n <= 2 * n_bins
    x_out = x;
    y_out = y;
    return;
end
edges = round(linspace(0, n, n_bins + 1));
x_out = zeros(1, 2 * n_bins);
y_out = zeros(1, 2 * n_bins);
for b = 1:n_bins
    idx = (edges(b) + 1):edges(b + 1);
    seg = y(idx);
    [mn, i_mn] = min(seg);
    [mx, i_mx] = max(seg);
    if i_mn <= i_mx
        pick = [i_mn, i_mx];
        vals = [mn, mx];
    else
        pick = [i_mx, i_mn];
        vals = [mx, mn];
    end
    x_out(2*b - 1:2*b) = x(idx(pick));
    y_out(2*b - 1:2*b) = vals;
end
end

function smoothed = smoothTraceMatrix(data, window_size)

if isempty(data)
    smoothed = data;
    return;
end

if nargin < 2 || isempty(window_size) || window_size <= 1
    smoothed = data;
    return;
end

smoothed = smoothdata(data, 2, 'movmean', window_size, 'omitnan');

end

function h = plotShadedMean(data, options)

if isempty(data)
    h = gobjects(0);
    return;
end

if isvector(data)
    data = reshape(data, 1, []);
end

if ~isfield(options,'color_area'), options.color_area = [0.8 0.8 0.8]; end
if ~isfield(options,'color_line'), options.color_line = [0 0 0]; end
if ~isfield(options,'alpha'), options.alpha = 0.30; end
if ~isfield(options,'line_width'), options.line_width = 2; end
if ~isfield(options,'error'), options.error = 'sem'; end
if ~isfield(options,'x_axis'), options.x_axis = 1:size(data,2); end

x = options.x_axis(:)';

data_mean = mean(data, 1, 'omitnan');
data_std  = std(data, 0, 1, 'omitnan');
n = sum(~isnan(data), 1);
n(n == 0) = NaN;

switch lower(options.error)
    case 'std'
        err = data_std;
    case 'sem'
        err = data_std ./ sqrt(n);
    case 'var'
        err = data_std.^2;
    case 'c95'
        err = (data_std ./ sqrt(n)) * 1.96;
    otherwise
        error('Unknown error type: %s', options.error);
end

fill([x fliplr(x)], [data_mean+err fliplr(data_mean-err)], ...
    options.color_area, ...
    'EdgeColor', 'none', ...
    'FaceAlpha', options.alpha);
hold on;

h = plot(x, data_mean, ...
    'Color', options.color_line, ...
    'LineWidth', options.line_width);

end

function condition_labels = getConditionLabelsFromResults(group_result)

condition_labels = {};

for i = 1:numel(group_result.animals)
    animal_file = group_result.animals(i).save_file;

    if ~isfile(animal_file)
        continue;
    end

    S = load(animal_file, 'animal_result');
    animal_result = S.animal_result;

    if isfield(animal_result, 'analysis') && isfield(animal_result.analysis, 'sst')
        labels = fieldnames(animal_result.analysis.sst);

        keep = false(size(labels));
        for k = 1:numel(labels)
            if isstruct(animal_result.analysis.sst.(labels{k}))
                keep(k) = true;
            end
        end
        labels = labels(keep);

        if ~isempty(labels)
            condition_labels = labels(:)';
            return;
        end
    end
end

end

function event_lines = getEventLines(params)

switch params.behavior
    case 'platform_entry_exit'
        event_lines = [0];
    case 'tone_on_vs_off_platform'
        event_lines = [0 28 30];
    case 'tone_shock_vs_noshock'
        event_lines = [0 28 30];
    otherwise
        event_lines = [0];
end

end

function x_axis = makeTimeAxisFromMatrix(dataA, dataB, params)

nA = 0;
nB = 0;

if ~isempty(dataA), nA = size(dataA,2); end
if ~isempty(dataB), nB = size(dataB,2); end

n = max(nA, nB);

if n == 0
    x_axis = [];
    return;
end

x_axis = linspace(-params.TRANGE_pre, params.TRANGE_post, n);

end

function h = plotShadedMeanWithHandle(data, x_axis, color_area, color_line, alpha_val, line_width, ax)
% SV 9/28/26 (bugfix): ax (target axes) is now an explicit argument - this
% used to draw into gca, which is only the intended panel when its figure
% happens to be the current one. The cross-day reports build four
% documents' figures side by side, so from the second day on each
% document's means/SEM went into whichever figure was current (missing
% from their own panel, drawn onto another document's). Omitted -> gca,
% for any older caller.
if nargin < 7 || isempty(ax)
    ax = gca;
end

data_mean = mean(data, 1, 'omitnan');
data_std = std(data, 0, 1, 'omitnan');
n = sum(~isnan(data), 1);
n(n == 0) = NaN;
err = data_std ./ sqrt(n);

fill(ax, [x_axis fliplr(x_axis)], [data_mean+err fliplr(data_mean-err)], ...
    color_area, 'EdgeColor', 'none', 'FaceAlpha', alpha_val);
hold(ax, 'on');

h = plot(ax, x_axis, data_mean, 'Color', color_line, 'LineWidth', line_width);

end

function clean_title = makeCleanTitle(day_label, condition_label)

cond = strrep(condition_label, '_', ' ');
cond = regexprep(cond, ' tones .*$', '');
cond = lower(cond);

if ~isempty(cond)
    cond(1) = upper(cond(1));
end

words = split(cond, ' ');
for i = 1:numel(words)
    w = words{i};
    if ~isempty(w)
        w(1) = upper(w(1));
        words{i} = w;
    end
end

cond_clean = strjoin(words, ' ');

clean_title = sprintf('%s %s', day_label, cond_clean);

end

function y_limits = getFixedYLimits(behavior_name)

switch behavior_name
    case 'platform_entry_exit'
        y_limits = [-2 5];
    case 'tone_on_vs_off_platform'
        y_limits = [-2 5];
    case 'tone_shock_vs_noshock'
        y_limits = [-2 5];
    case 'reward'
        y_limits = [];
    otherwise
        y_limits = [];
end

end

% ====================================================================== %
%  NEW REPORT SYSTEM (SV 9/8/26) - one multi-page PDF per run instead of %
%  a pile of per-condition PNG/FIG files. Shared by Batch and Compare    %
%  modes. Design follows the user's TMS_GroupSummary_*.pdf reference:    %
%  matched y-axis SPAN (not necessarily identical limits) between two    %
%  side-by-side panels, a gray "Baseline" bar spanning Params.BASELINE_  %
%  PER, a gray "AUC window" bar spanning Params.AUC_RANGE, a dashed line %
%  at the aligned event, paired-animal AUC dot plots with a plain-       %
%  language stats page, and a QC page of raw per-animal traces.          %
% ====================================================================== %

function c = channelColor(channel)
% SV 9/8/26: fixed convention per user request - 465 (green GCaMP
% channel) is always green, 560 (red-shifted channel) is always red,
% everywhere in this file's plots.
switch lower(channel)
    case 'pv'
        c = struct('line', [0.13 0.62 0.27], 'area', [0.72 0.90 0.76]);
    case 'sst'
        c = struct('line', [0.80 0.15 0.15], 'area', [0.95 0.75 0.75]);
    otherwise
        c = struct('line', [0.3 0.3 0.3], 'area', [0.8 0.8 0.8]);
end
end

function name = channelDisplayName(channel)
% SV 9/8/26: 'pv'/'sst' remain the internal field names throughout this
% file (animal_result.analysis.pv/.sst etc.) - short, stable, and never
% shown to a user. Every piece of text a user actually reads (plot
% legends, panel titles, exported CSV/xlsx column values and file names,
% GUI labels) goes through this instead, so the script reads by
% wavelength (465/560) rather than this lab's cell-type reporter names
% (Pv/Sst), which wouldn't mean anything for another lab's data.
switch lower(channel)
    case 'pv'
        name = '465';
    case 'sst'
        name = '560';
    otherwise
        name = upper(channel);
end
end

function fig = reportPageFigure(width_in, height_in)
% SV 9/9/26 (bugfix): dimensions are now a parameter, not a fixed 10x15in
% portrait canvas for every page regardless of what it holds - a tall,
% narrow portrait canvas divided into a grid of panels gives each panel a
% tall/narrow aspect too (long Y axis, squashed X axis), which is wrong
% for a time-series trace plot and didn't match the user's hand-drawn
% layout. Callers building a grid of panels now size the canvas from the
% actual row/col count so panels come out close to the intended
% proportions; callers with no particular row/col grid (the stats text
% page) can omit both args and get a reasonable default.
if nargin < 2 || isempty(width_in) || isempty(height_in)
    % SV 9/28/26 (per user's request - portrait always): default is now
    % US Letter PORTRAIT (was 11 x 8.5 landscape).
    width_in = 8.5;
    height_in = 11;
end
fig = figure('Color', 'w', 'Units', 'inches', 'Position', [0.5 0.5 width_in height_in], 'Visible', 'off');

% SV 9/9/26: exportgraphics() does NOT export the whole figure canvas by
% default - it tightly crops the PDF page to the bounding box of actual
% rendered ink. A plain invisible axes does not influence that bounding
% box (confirmed empirically), but a real drawn primitive at the canvas
% corners, colored the same as the page background so nothing is
% visible, does - this white-on-white rectangle the exact size of the
% figure keeps the exported page matching the declared canvas above.
% NOTE: this only works for pages with NO tiledlayout in the figure - a
% tiledlayout's own auto-sizing overrides/ignores this anchor (also
% confirmed empirically), so for tiledlayout pages the actual exported
% page size is whatever the tiledlayout decides to occupy, not
% necessarily width_in x height_in - what matters there is the
% requested ASPECT RATIO/relative panel proportions, not the absolute
% inches.
anchor = axes(fig, 'Position', [0 0 1 1], 'XColor', 'none', 'YColor', 'none', 'HitTest', 'off', 'Tag', 'canvas_anchor');
rectangle(anchor, 'Position', [0 0 1 1], 'EdgeColor', 'w', 'FaceColor', 'none', 'LineWidth', 0.01, 'HitTest', 'off');
xlim(anchor, [0 1]);
ylim(anchor, [0 1]);
uistack(anchor, 'bottom');

end

function appendPageToPDF(fig, pdf_path, is_first_page)
% exportgraphics(...,'Append',true) builds a multi-page PDF one figure at
% a time. is_first_page starts a fresh file (overwriting any stale PDF
% from an earlier run of this same day/behavior/variant); later pages
% append to it.
if is_first_page
    if isfile(pdf_path)
        delete(pdf_path);
    end
    exportgraphics(fig, pdf_path, 'ContentType', 'vector');
else
    exportgraphics(fig, pdf_path, 'ContentType', 'vector', 'Append', true);
end
end

function fitPDFToLetter(pdf_path)
% SV 9/28/26 (per user's request): every report PDF ends up on US Letter
% portrait pages (8.5 x 11 in). Pages are still BUILT exactly as before -
% each at its own natural size, which is what keeps every plot's
% proportions, spacing and font-to-panel ratios intact - and this pass
% then places each finished page onto a Letter page as a uniformly scaled
% vector copy: fit to the 7.5 in usable width (0.5 in margin each side),
% also shrunk further if the scaled height wouldn't fit 10 in, scaled UP
% if the page is smaller than that, centered horizontally, top-aligned.
% Nothing is re-laid-out or rasterized - text and lines scale along with
% the plots, and zooming in the PDF viewer recovers full detail.
%
% Why Python: exportgraphics has no page-size option (it crops the page
% to the drawn content - see reportPageFigure), print() can't append
% pages, and this machine has no Ghostscript. The PyMuPDF package (pip
% install pymupdf) does vector page placement directly; the code lives in
% assemble_photometry_report.py ('fit' mode) beside this script and is
% run as a command by runReportPython (SV 10/1/26 - it used MATLAB's own
% Python interface, but R2024b's Python, 3.10 here, has no PyMuPDF). If no
% Python with PyMuPDF is found the natural-size PDF is left as-is with a
% warning, rather than failing the report.
% SV 9/28/26: a page that is already 8.5 x 11 (the natively-built report
% pages) is copied through unchanged, not shrunk into the margins again.
if ~isfile(pdf_path)
    return;
end
[ok, msg] = runReportPython({'fit', char(pdf_path)});
if ~ok
    warning('Could not refit %s onto 8.5x11 pages - pages left at their natural size.\n%s', pdf_path, msg);
end
end

function [ok, msg] = runReportPython(args)
% SV 10/1/26: runs assemble_photometry_report.py (beside this script) with
% args (cellstr) as a command, using the first Python found that can
% import PyMuPDF: MATLAB's configured Python (pyenv), then the Windows
% "py -3" launcher, then "python" on the PATH. Not MATLAB's in-process
% Python interface - the Python version a MATLAB release supports may not
% be the one PyMuPDF is installed in (R2024b uses 3.10 here; PyMuPDF is in
% 3.14). ok = false with msg explaining why when it can't run.
ok = false;
msg = '';
script = fullfile(fileparts(mfilename('fullpath')), 'assemble_photometry_report.py');
if ~isfile(script)
    msg = sprintf('Report helper not found: %s', script);
    return;
end
py = findReportPython();
if isempty(py)
    msg = 'No Python with the PyMuPDF package was found (install it with: pip install pymupdf).';
    return;
end
quoted = cellfun(@(a) ['"' a '"'], args, 'UniformOutput', false);
[status, out] = system(sprintf('%s "%s" %s', py, script, strjoin(quoted, ' ')));
ok = status == 0;
if ~ok
    msg = strtrim(out);
end
end

function py = findReportPython()
% The command that starts a Python able to import PyMuPDF ('' if none),
% remembered for the rest of the MATLAB session once found.
persistent cached
if ~isempty(cached)
    py = cached;
    return;
end
py = '';
candidates = {};
try
    pe = pyenv;
    if strlength(pe.Executable) > 0
        candidates{end+1} = ['"' char(pe.Executable) '"'];
    end
catch
end
candidates = [candidates, {'py -3', 'python'}];
for k = 1:numel(candidates)
    [status, ~] = system(sprintf('%s -c "import pymupdf"', candidates{k}));
    if status == 0
        py = candidates{k};
        cached = py;
        return;
    end
end
end

function drawAnnotationBar(ax, x_range, y_pos, color, label_text)
% A thin horizontal bar under the trace marking a named time window
% (Baseline, AUC window, ...), matching the reference PDF's style.
%
% SV 9/9/26 (per user's request): the label sits CENTERED directly above
% its own bar (not off to the left of it, which could read as belonging
% to whatever's to the bar's left instead) - trace data is allowed to sit
% under/behind the label if the window happens to be narrow.
if isempty(x_range) || any(isnan(x_range))
    return;
end
% SV 9/9/26 (per user's request): thinner bar and smaller label text
% (was LineWidth 3 / FontSize 8) - these were reading as heavier/bigger
% than they need to be relative to everything else on the panel.
line(ax, x_range, [y_pos y_pos], 'Color', color, 'LineWidth', 1.5, 'HandleVisibility', 'off');
if ~isempty(label_text)
    center_x = mean(x_range);
    text(ax, center_x, y_pos, label_text, 'Color', color, 'FontSize', 4.5, ... % SV 10/1/26: was 6
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
end
end

function matchYAxesAcrossPanels(ax_list)
% SV 9/8/26: per user request - when two related panels sit side by side
% (e.g. two conditions of the same behavior, or Trace A vs Trace B in
% Compare mode), the Y-axis SPAN (scale) is matched between them so
% effect sizes are visually comparable, but each panel keeps its own
% data-driven lower bound - the "Y intercept" is allowed to differ.
if numel(ax_list) < 2
    return;
end
spans = zeros(1, numel(ax_list));
lims = cell(1, numel(ax_list));
for i = 1:numel(ax_list)
    lims{i} = ylim(ax_list(i));
    spans(i) = diff(lims{i});
end
max_span = max(spans);
for i = 1:numel(ax_list)
    lo = lims{i}(1);
    ylim(ax_list(i), [lo, lo + max_span]);
end
end

function [sig_label, p_val] = describeComparison(a, b, is_paired)
% Nonparametric comparison - paired (Wilcoxon signed-rank, same animals
% in both conditions, e.g. platform_entry vs platform_exit) or unpaired
% (Wilcoxon rank-sum, independent groups, e.g. TMS vs Sham). Degrades to
% an n-only label if the Statistics Toolbox isn't available, or if there
% isn't enough data to test. Small photometry cohorts (often 3-6 animals
% per group here) rarely reach conventional significance even with a
% real effect - see the report's own stats-page caveat text for why that
% is a power limitation, not evidence of no effect.
a = a(~isnan(a));
b = b(~isnan(b));
p_val = NaN;

if is_paired && numel(a) ~= numel(b)
    sig_label = 'ns (unequal paired n)';
    return;
end
if numel(a) < 2 || numel(b) < 2
    sig_label = sprintf('ns (n=%d,%d too small)', numel(a), numel(b));
    return;
end

try
    if is_paired
        p_val = signrank(a, b);
    else
        p_val = ranksum(a, b);
    end
catch
    sig_label = sprintf('n=%d,%d (Statistics Toolbox unavailable)', numel(a), numel(b));
    return;
end

if p_val < 0.001
    stars = '***';
elseif p_val < 0.01
    stars = '**';
elseif p_val < 0.05
    stars = '*';
else
    stars = 'ns';
end
sig_label = sprintf('%s (p=%.3f)', stars, p_val);
end

function channels = getChannelsWithData(group_result, condition_labels)
% Which of Pv/Sst actually have non-empty trial data anywhere in this
% run - Sst is legitimately absent for single-color cohorts.
channels = {};
candidates = {'pv', 'sst'};
for ci = 1:numel(candidates)
    channel = candidates{ci};
    found = false;
    for i = 1:numel(group_result.animals)
        animal_file = group_result.animals(i).save_file;
        if ~isfile(animal_file), continue; end
        S = load(animal_file, 'animal_result');
        ar = S.animal_result;
        for c = 1:numel(condition_labels)
            cond = condition_labels{c};
            if isfield(ar.analysis, channel) && isfield(ar.analysis.(channel), cond) ...
                    && ~isempty(ar.analysis.(channel).(cond).trial_matrix)
                found = true;
                break;
            end
        end
        if found, break; end
    end
    if found
        channels{end+1} = channel; %#ok<AGROW>
    end
end
end

% ====================================================================== %
%  COMPARE MODE (SV 9/8/26) - merged in from what used to be the         %
%  separate run_PMA_photometry_compare_traces_SVv1.m. Scanning/picker    %
%  logic (scanPhotometryResults..loadTraceGroup) is unchanged from that  %
%  script; only the output changed, from 3 separate PNG/FIG files to one %
%  multi-page PDF report (buildComparisonReportPDF) using the same       %
%  shared report helpers Batch mode uses (channelColor, reportPageFigure,%
%  appendPageToPDF, drawAnnotationBar, matchYAxesAcrossPanels,           %
%  describeComparison).
% ====================================================================== %

function runCompareMode()
% Does NOT re-process raw TDT data - reads the animal_result_*.mat files
% Batch mode already saved under each day folder's
% Photometry_Results\<run>\<animal>\, so it only works on day/behavior/
% variant combinations already run through Batch mode.

disp('Select the dataset root (same root you point Batch Analysis mode at)');
root_dir = uigetdir(pwd, 'Select dataset root');
if isequal(root_dir, 0)
    error('Folder selection cancelled.');
end

fprintf('Scanning %s for saved photometry results...\n', root_dir);
runs = scanPhotometryResults(root_dir);

if isempty(runs)
    error(['No saved photometry results found under %s.\nRun Batch Analysis ' ...
        'mode on this dataset first - Compare mode only compares traces that ' ...
        'are already saved to disk.'], root_dir);
end

fprintf('Found %d run(s) with saved results across %d day folder(s).\n', ...
    numel(runs), numel(unique({runs.day_folder})));

selection = pickTraces(runs);
if isempty(selection)
    fprintf('Cancelled.\n');
    return;
end

fprintf('\nLoading Trace A: %s | %s | %s | %s\n', selection.A.day_folder, ...
    selection.A.run_folder, selection.A.condition_label, selection.A.channel_display);
traceA = loadTraceGroup(selection.A);

fprintf('Loading Trace B: %s | %s | %s | %s\n', selection.B.day_folder, ...
    selection.B.run_folder, selection.B.condition_label, selection.B.channel_display);
traceB = loadTraceGroup(selection.B);

if traceA.n == 0
    error('Trace A has no animals with data for that condition/channel. Pick a different combination.');
end
if traceB.n == 0
    error('Trace B has no animals with data for that condition/channel. Pick a different combination.');
end

out_dir = makeComparisonOutputDir(root_dir, selection);
fprintf('\nSaving comparison to:\n%s\n', out_dir);

buildComparisonReportPDF(traceA, traceB, selection, out_dir);
exportComparisonAUC(traceA, traceB, selection, out_dir);
writeCompareSummary(traceA, traceB, selection, out_dir);

fprintf('\nComparison complete.\n');

end

% ---------------------------------------------------------------------- %
%  SCANNING - build an index of what's already saved on disk             %
% ---------------------------------------------------------------------- %

function runs = scanPhotometryResults(root_dir)
% One entry per <day_folder>\Photometry_Results\<run_folder> that has a
% GROUP_*.mat with at least one successfully-processed animal. Condition
% labels and channel availability (Pv always, Sst if real data exists)
% are resolved lazily later (peekRunDetails), not during this scan, so
% opening the tool stays fast even on a dataset with many runs.

runs = struct('day_folder', {}, 'day_path', {}, 'run_folder', {}, 'run_path', {}, ...
    'group_mat_path', {}, 'group_datenum', {}, 'behavior', {}, 'tone_tag', {}, 'n_animals', {}, ...
    'animals', {}, 'params', {});

root_entries = dir(root_dir);
for i = 1:numel(root_entries)
    entry = root_entries(i);
    if ~entry.isdir || any(strcmp(entry.name, {'.', '..'}))
        continue;
    end

    results_dir = fullfile(root_dir, entry.name, 'Photometry_Results');
    if ~isfolder(results_dir)
        continue;
    end

    run_entries = dir(results_dir);
    for j = 1:numel(run_entries)
        run_entry = run_entries(j);
        if ~run_entry.isdir || any(strcmp(run_entry.name, {'.', '..'}))
            continue;
        end

        run_path = fullfile(results_dir, run_entry.name);
        group_candidates = dir(fullfile(run_path, '*_GROUP_*.mat'));
        if isempty(group_candidates)
            continue;
        end

        % SV 9/8/26: a re-run overwrites the run_folder's per-animal files
        % in place but adds a NEW timestamped GROUP file rather than
        % replacing the old one - always take the most recently modified
        % so a stale GROUP file from an earlier failed attempt never wins
        % over a later successful re-run of the same parameters.
        [~, newest_idx] = max([group_candidates.datenum]);
        group_mat_path = fullfile(run_path, group_candidates(newest_idx).name);

        try
            S = load(group_mat_path, 'group_result');
        catch ME
            warning('Could not load %s: %s', group_mat_path, ME.message);
            continue;
        end
        if ~isfield(S, 'group_result') || ~isfield(S.group_result, 'animals') || isempty(S.group_result.animals)
            continue; % nothing succeeded in this run - skip
        end

        gr = S.group_result;
        idx = numel(runs) + 1;
        runs(idx).day_folder = entry.name;
        runs(idx).day_path = fullfile(root_dir, entry.name);
        runs(idx).run_folder = run_entry.name;
        runs(idx).run_path = run_path;
        runs(idx).group_mat_path = group_mat_path;
        % SV 9/28/26: lets selectRunsForReport prefer the newest of two
        % runs covering the same report cell.
        runs(idx).group_datenum = group_candidates(newest_idx).datenum;
        runs(idx).behavior = gr.params.behavior;
        runs(idx).tone_tag = gr.params.tone_tag;
        runs(idx).n_animals = numel(gr.animals);
        runs(idx).animals = gr.animals;
        runs(idx).params = gr.params;
    end
end

end

function details = peekRunDetails(run_entry)
% Loads the FIRST available animal's saved file for this run to discover
% which condition labels exist and whether real (non-empty) Sst data is
% present - deferred until a run is actually selected in the picker, not
% during the initial scan.

details = struct('labels', {{}}, 'has_sst', false);

for i = 1:numel(run_entry.animals)
    animal_file = run_entry.animals(i).save_file;
    if ~isfile(animal_file)
        continue;
    end
    S = load(animal_file, 'animal_result');
    ar = S.animal_result;
    if ~isfield(ar, 'analysis') || ~isfield(ar.analysis, 'pv')
        continue;
    end

    pv_labels = fieldnames(ar.analysis.pv);
    keep = false(size(pv_labels));
    for k = 1:numel(pv_labels)
        keep(k) = isstruct(ar.analysis.pv.(pv_labels{k}));
    end
    details.labels = pv_labels(keep)';

    if isfield(ar.analysis, 'sst')
        sst_labels = fieldnames(ar.analysis.sst);
        for k = 1:numel(sst_labels)
            e = ar.analysis.sst.(sst_labels{k});
            if isstruct(e) && isfield(e, 'trial_matrix') && ~isempty(e.trial_matrix)
                details.has_sst = true;
                break;
            end
        end
    end

    return; % first available animal is enough
end

end

% ---------------------------------------------------------------------- %
%  PICKER UI                                                             %
% ---------------------------------------------------------------------- %

function selection = pickTraces(runs)
% Two side-by-side panels (Trace A / Trace B), each with cascading
% dropdowns: Day folder -> Run (behavior+variant) -> Condition -> Channel.
% Returns selection = struct('A', ..., 'B', ...) or [] if cancelled.

day_folders = unique({runs.day_folder}, 'stable');

fig = uifigure('Name', 'Compare Photometry Traces', 'Position', [80 80 1000 420]);
fig.UserData.action = '';
fig.CloseRequestFcn = @(src, evt) uiresume(fig);

main_grid = uigridlayout(fig, [3 1]);
main_grid.RowHeight = {'fit', '1x', 'fit'};

uilabel(main_grid, 'Text', ...
    ['Pick two already-saved traces to overlay. Trace B''s day defaults to auto-matching ' ...
     'Trace A''s run/condition/channel when an identical run exists there (e.g. sham_Retr vs tms_Retr).'], ...
    'FontWeight', 'bold', 'WordWrap', 'on');

panels_grid = uigridlayout(main_grid, [1 2]);
panels_grid.ColumnWidth = {'1x', '1x'};

hA = buildTracePanel(panels_grid, 'Trace A', day_folders, runs, []);
hB = buildTracePanel(panels_grid, 'Trace B', day_folders, runs, hA);

button_grid = uigridlayout(main_grid, [1 2]);
button_grid.ColumnWidth = {'1x', '1x'};
uibutton(button_grid, 'Text', 'Cancel', 'ButtonPushedFcn', @(~, ~) onAction('cancel'));
uibutton(button_grid, 'Text', 'Compare', 'BackgroundColor', [0.30 0.69 0.31], 'FontColor', [1 1 1], ...
    'FontWeight', 'bold', 'ButtonPushedFcn', @(~, ~) onAction('compare'));

uiwait(fig);

if ~isvalid(fig) || isempty(fig.UserData.action) || strcmp(fig.UserData.action, 'cancel')
    if isvalid(fig), delete(fig); end
    selection = [];
    return;
end

selA = readTracePanel(hA, runs);
selB = readTracePanel(hB, runs);
delete(fig);

if isempty(selA) || isempty(selB)
    error('Both Trace A and Trace B must have a condition and channel selected.');
end

selection = struct('A', selA, 'B', selB);

    function onAction(which)
        fig.UserData.action = which;
        uiresume(fig);
    end
end

function h = buildTracePanel(parent, title_str, day_folders, runs, other_panel)
% Builds one Trace panel's dropdowns and wires cascading updates. If
% other_panel is given (building Trace B), selecting a day auto-suggests
% the run/condition/channel that mirrors whatever Trace A currently has
% selected, when an identically-named run exists under this day.

panel = uipanel(parent, 'Title', title_str);
pg = uigridlayout(panel, [4 2]);
pg.RowHeight = {'fit', 'fit', 'fit', 'fit'};
pg.ColumnWidth = {'fit', '1x'};

uilabel(pg, 'Text', 'Day folder:');
day_dd = uidropdown(pg, 'Items', day_folders, 'Value', day_folders{1});
uilabel(pg, 'Text', 'Behavior run:');
run_dd = uidropdown(pg, 'Items', {'-'}, 'Value', '-');
uilabel(pg, 'Text', 'Condition:');
cond_dd = uidropdown(pg, 'Items', {'-'}, 'Value', '-');
uilabel(pg, 'Text', 'Channel:');
chan_dd = uidropdown(pg, 'Items', {'-'}, 'Value', '-');

h = struct('day_dd', day_dd, 'run_dd', run_dd, 'cond_dd', cond_dd, 'chan_dd', chan_dd);

day_dd.ValueChangedFcn = @(src, evt) onDayChanged();
run_dd.ValueChangedFcn = @(src, evt) onRunChanged();

onDayChanged(); % populate initial state for the first day in the list

    function onDayChanged()
        this_day_runs = runs(strcmp({runs.day_folder}, day_dd.Value));
        run_names = {this_day_runs.run_folder};
        if isempty(run_names)
            run_dd.Items = {'-'};
            run_dd.Value = '-';
        else
            run_dd.Items = run_names;
            % SV 9/8/26: auto-suggest the identically-parameterized run
            % under this day if Trace A already picked one (the common
            % tms-vs-sham-same-day-same-behavior case).
            if ~isempty(other_panel) && any(strcmp(other_panel.run_dd.Value, run_names))
                run_dd.Value = other_panel.run_dd.Value;
            else
                run_dd.Value = run_names{1};
            end
        end
        onRunChanged();
    end

    function onRunChanged()
        if strcmp(run_dd.Value, '-')
            cond_dd.Items = {'-'}; cond_dd.Value = '-';
            chan_dd.Items = {'-'}; chan_dd.Value = '-';
            return;
        end
        this_run = runs(strcmp({runs.day_folder}, day_dd.Value) & strcmp({runs.run_folder}, run_dd.Value));
        this_run = this_run(1);
        details = peekRunDetails(this_run);

        if isempty(details.labels)
            cond_dd.Items = {'-'}; cond_dd.Value = '-';
        else
            cond_dd.Items = details.labels;
            if ~isempty(other_panel) && any(strcmp(other_panel.cond_dd.Value, details.labels))
                cond_dd.Value = other_panel.cond_dd.Value;
            else
                cond_dd.Value = details.labels{1};
            end
        end

        % SV 9/8/26: dropdown shows wavelength (465/560), not this lab's
        % cell-type names, for shareability - 'pv'/'sst' remain the
        % internal keys via ItemsData (used everywhere else in this file
        % to index into animal_result.analysis.pv/.sst).
        if details.has_sst
            chan_items = {'pv', 'sst'};
        else
            chan_items = {'pv'};
        end
        chan_dd.ItemsData = chan_items;
        chan_dd.Items = cellfun(@channelDisplayName, chan_items, 'UniformOutput', false);
        if ~isempty(other_panel) && any(strcmp(other_panel.chan_dd.Value, chan_items))
            chan_dd.Value = other_panel.chan_dd.Value;
        else
            chan_dd.Value = chan_items{1};
        end
    end

end

function sel = readTracePanel(h, runs)

if strcmp(h.run_dd.Value, '-') || strcmp(h.cond_dd.Value, '-') || strcmp(h.chan_dd.Value, '-')
    sel = [];
    return;
end

this_run = runs(strcmp({runs.day_folder}, h.day_dd.Value) & strcmp({runs.run_folder}, h.run_dd.Value));
this_run = this_run(1);

sel = struct;
sel.day_folder = h.day_dd.Value;
sel.run_folder = h.run_dd.Value;
sel.condition_label = h.cond_dd.Value;
sel.channel = h.chan_dd.Value; % 'pv' | 'sst' (internal key, via ItemsData)
sel.channel_display = channelDisplayName(h.chan_dd.Value); % '465' | '560'
sel.run_entry = this_run;

end

% ---------------------------------------------------------------------- %
%  DATA LOADING                                                          %
% ---------------------------------------------------------------------- %

function trace = loadTraceGroup(sel)
% Loads every animal's saved trial_matrix/mean_trace/AUC for the chosen
% (run, condition, channel), skipping animals with no data for it (e.g. a
% condition that matched zero events for that animal that day).

run_entry = sel.run_entry;

trace = struct;
trace.day_folder = sel.day_folder;
trace.run_folder = sel.run_folder;
trace.condition_label = sel.condition_label;
trace.channel = sel.channel;
trace.channel_display = sel.channel_display;
trace.behavior = run_entry.behavior;
trace.tone_tag = run_entry.tone_tag;
trace.TRANGE_pre = run_entry.params.TRANGE_pre;
trace.TRANGE_post = run_entry.params.TRANGE_post;
if isfield(run_entry.params, 'BASELINE_PER')
    trace.BASELINE_PER = run_entry.params.BASELINE_PER;
else
    trace.BASELINE_PER = [];
end
if isfield(run_entry.params, 'AUC_RANGE')
    trace.AUC_RANGE = run_entry.params.AUC_RANGE;
else
    trace.AUC_RANGE = [];
end
trace.mean_traces = [];   % one row per animal
trace.animal_names = {};
trace.animal_mean_auc = [];
trace.trial_auc = [];     % pooled across animals, trial-level
trace.trial_auc_animal = {}; % which animal each trial_auc entry belongs to
trace.n = 0;

for i = 1:numel(run_entry.animals)
    animal_file = run_entry.animals(i).save_file;
    if ~isfile(animal_file)
        continue;
    end
    S = load(animal_file, 'animal_result');
    ar = S.animal_result;

    if ~isfield(ar.analysis, sel.channel) || ~isfield(ar.analysis.(sel.channel), sel.condition_label)
        continue;
    end
    entry = ar.analysis.(sel.channel).(sel.condition_label);
    if isempty(entry.trial_matrix)
        continue;
    end

    trace.mean_traces = appendTraceMatrix(trace.mean_traces, entry.mean_trace);
    trace.animal_names{end+1} = ar.mouse; %#ok<AGROW>

    if isfield(entry, 'auc') && ~isempty(entry.auc)
        trace.animal_mean_auc(end+1) = entry.auc.mean_of_trials; %#ok<AGROW>
        for ti = 1:numel(entry.auc.trial_auc)
            trace.trial_auc(end+1) = entry.auc.trial_auc(ti); %#ok<AGROW>
            trace.trial_auc_animal{end+1} = ar.mouse; %#ok<AGROW>
        end
    else
        trace.animal_mean_auc(end+1) = NaN; %#ok<AGROW>
    end
end

trace.n = numel(trace.animal_names);
if isempty(trace.mean_traces)
    trace.x_axis = [];
else
    trace.x_axis = linspace(-trace.TRANGE_pre, trace.TRANGE_post, size(trace.mean_traces, 2));
end

end

% ---------------------------------------------------------------------- %
%  PLOTTING - one multi-page PDF report (SV 9/8/26)                      %
% ---------------------------------------------------------------------- %

function plotCompareOverlayPanel(ax, traceA, traceB, label_A, label_B)
% Overlays Trace A and Trace B's group mean +/- SEM, with individual-
% animal thin lines, the aligned-event dashed line, and Baseline/AUC-
% window bars pulled from Trace A's run parameters (noted as approximate
% if Trace B's window differs - see the stats page).
hold(ax, 'on');

smooth_window = 25;
dataA = smoothdata(traceA.mean_traces, 2, 'movmean', smooth_window, 'omitnan');
dataB = smoothdata(traceB.mean_traces, 2, 'movmean', smooth_window, 'omitnan');

colA = channelColor(traceA.channel);
colB = channelColor(traceB.channel);
% SV 9/8/26: when both traces are the SAME channel (e.g. TMS Pv vs Sham
% Pv), color alone can't distinguish them since both map to the same
% hue by design - use solid vs dashed instead so the channel-color
% convention (green=Pv, red=Sst) still holds for both lines.
if strcmp(traceA.channel, traceB.channel)
    styleA = '-'; styleB = '--';
else
    styleA = '-'; styleB = '-';
end

for i = 1:size(dataA, 1)
    plot(ax, traceA.x_axis, dataA(i,:), 'Color', [colA.line 0.15], 'LineStyle', styleA, ...
        'LineWidth', 0.6, 'HandleVisibility', 'off');
end
for i = 1:size(dataB, 1)
    plot(ax, traceB.x_axis, dataB(i,:), 'Color', [colB.line 0.15], 'LineStyle', styleB, ...
        'LineWidth', 0.6, 'HandleVisibility', 'off');
end

hA = plotShadedMeanWithHandle(dataA, traceA.x_axis, colA.area, colA.line, 0.30, 2, ax);
set(hA, 'LineStyle', styleA);
hB = plotShadedMeanWithHandle(dataB, traceB.x_axis, colB.area, colB.line, 0.30, 2, ax);
set(hB, 'LineStyle', styleB);

event_lines = getEventLines(struct('behavior', traceA.behavior));
for k = 1:numel(event_lines)
    xline(ax, event_lines(k), '--', 'Color', [0.6 0.6 0.6], 'LineWidth', 0.9, 'HandleVisibility', 'off');
end

y0 = ylim(ax);
span = diff(y0);
if span == 0, span = 1; end
bar_gap = span * 0.10;
baseline_y = y0(1) - bar_gap;
auc_y = y0(1) - 2*bar_gap;
ylim(ax, [y0(1) - 2.6*bar_gap, y0(2)]);

if ~isempty(traceA.BASELINE_PER)
    baseline_actual = -traceA.TRANGE_pre + traceA.BASELINE_PER;
    drawAnnotationBar(ax, baseline_actual, baseline_y, [0.5 0.5 0.5], 'Baseline');
end
if ~isempty(traceA.AUC_RANGE)
    drawAnnotationBar(ax, traceA.AUC_RANGE, auc_y, [0.5 0.5 0.5], 'AUC window'); % SV 9/28/26: grey, was blue
end

box(ax, 'off');
set(ax, 'TickDir', 'out');
xlabel(ax, 'Time (s)');
ylabel(ax, 'z-score');
legend(ax, [hA hB], {sprintf('%s (n=%d)', label_A, traceA.n), sprintf('%s (n=%d)', label_B, traceB.n)}, ...
    'Location', 'best', 'Box', 'off');
title(ax, sprintf('%s vs %s', label_A, label_B), 'Interpreter', 'none');

end

function stat_line = plotCompareAUCPanel(ax, traceA, traceB, label_A, label_B)
% Per-animal AUC dot plot with mean+/-SEM. Auto-detects paired (same
% animals appear in both traces - e.g. Pv vs Sst within one group, use
% Wilcoxon signed-rank with connecting lines) vs unpaired (different
% animals - e.g. TMS vs Sham, use Wilcoxon rank-sum).
hold(ax, 'on');

colA = channelColor(traceA.channel);
colB = channelColor(traceB.channel);

jitterA = (rand(size(traceA.animal_mean_auc)) - 0.5) * 0.15;
jitterB = (rand(size(traceB.animal_mean_auc)) - 0.5) * 0.15;
scatter(ax, 1 + jitterA, traceA.animal_mean_auc, 45, colA.line, 'filled');
scatter(ax, 2 + jitterB, traceB.animal_mean_auc, 45, colB.line, 'filled');

meanA = mean(traceA.animal_mean_auc, 'omitnan');
semA = std(traceA.animal_mean_auc, 'omitnan') / sqrt(sum(~isnan(traceA.animal_mean_auc)));
meanB = mean(traceB.animal_mean_auc, 'omitnan');
semB = std(traceB.animal_mean_auc, 'omitnan') / sqrt(sum(~isnan(traceB.animal_mean_auc)));

errorbar(ax, 1, meanA, semA, 'o', 'Color', colA.line, 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', colA.line);
errorbar(ax, 2, meanB, semB, 'o', 'Color', colB.line, 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', colB.line);

common = intersect(traceA.animal_names, traceB.animal_names);
is_paired = ~isempty(common) && numel(common) == min(traceA.n, traceB.n);

if ~isempty(common)
    for k = 1:numel(common)
        i1 = find(strcmp(traceA.animal_names, common{k}), 1);
        i2 = find(strcmp(traceB.animal_names, common{k}), 1);
        plot(ax, [1 2], [traceA.animal_mean_auc(i1), traceB.animal_mean_auc(i2)], ...
            'Color', [0.5 0.5 0.5 0.4], 'LineWidth', 1, 'HandleVisibility', 'off');
    end
end

xlim(ax, [0.5 2.5]);
set(ax, 'XTick', [1 2], 'XTickLabel', {label_A, label_B}, 'TickLabelInterpreter', 'none', 'TickDir', 'out');
ylabel(ax, 'AUC (z-score * s), per-animal mean of trials');
box(ax, 'off');

if is_paired
    paired_a = nan(1, numel(common));
    paired_b = nan(1, numel(common));
    for k = 1:numel(common)
        i1 = find(strcmp(traceA.animal_names, common{k}), 1);
        i2 = find(strcmp(traceB.animal_names, common{k}), 1);
        paired_a(k) = traceA.animal_mean_auc(i1);
        paired_b(k) = traceB.animal_mean_auc(i2);
    end
    sig_label = describeComparison(paired_a, paired_b, true);
    pair_str = 'paired (same animals)';
else
    sig_label = describeComparison(traceA.animal_mean_auc, traceB.animal_mean_auc, false);
    pair_str = 'unpaired';
end
title(ax, sprintf('n=%d vs %d, %s, %s', traceA.n, traceB.n, pair_str, sig_label), 'FontSize', 9, 'Interpreter', 'none');

stat_line = sprintf('[AUC] %s vs %s (%s): %s', label_A, label_B, pair_str, sig_label);

end

function buildComparisonReportPDF(traceA, traceB, selection, out_dir) %#ok<INUSD>
% SV 9/8/26: replaces the old 3-separate-PNG output with one multi-page
% PDF: Page 1 = overlay + AUC comparison, Page 2 = per-animal tiles
% (Trace A left, Trace B right), Page 3 = plain-text stats.

label_A = makeTraceLabel(traceA);
label_B = makeTraceLabel(traceB);
pdf_path = fullfile(out_dir, 'comparison_report.pdf');

% ---- Page 1 ----
fig1 = reportPageFigure();
tl = paddedTiledLayout(fig1, 3, 1, 'loose');
title(tl, sprintf('%s vs %s', label_A, label_B), 'Interpreter', 'none', 'FontWeight', 'bold', 'FontSize', 13);

ax1 = nexttile(tl, 1);
plotCompareOverlayPanel(ax1, traceA, traceB, label_A, label_B);

ax2 = nexttile(tl, 2);
stat_line = plotCompareAUCPanel(ax2, traceA, traceB, label_A, label_B);
% row 3 intentionally left empty - bottom-margin reserve

appendPageToPDF(fig1, pdf_path, true);
close(fig1);

% ---- Page 2: per-animal tiles, two columns (A | B) ----
fig2 = reportPageFigure();
nMax = max(traceA.n, traceB.n);
tl2 = paddedTiledLayout(fig2, nMax + 1, 2, 'compact');
title(tl2, sprintf('%s (left) vs %s (right) - per animal', label_A, label_B), ...
    'Interpreter', 'none', 'FontWeight', 'bold');

smooth_window = 25;
dataA = smoothdata(traceA.mean_traces, 2, 'movmean', smooth_window, 'omitnan');
dataB = smoothdata(traceB.mean_traces, 2, 'movmean', smooth_window, 'omitnan');
colA = channelColor(traceA.channel);
colB = channelColor(traceB.channel);

for r = 1:nMax
    axL = nexttile(tl2, (r-1)*2 + 1);
    if r <= traceA.n
        plot(axL, traceA.x_axis, dataA(r,:), 'Color', colA.line, 'LineWidth', 1.2);
        xline(axL, 0, '--', 'Color', [0.7 0.7 0.7]);
        title(axL, traceA.animal_names{r}, 'Interpreter', 'none', 'FontSize', 9);
        box(axL, 'off'); set(axL, 'TickDir', 'out', 'FontSize', 8);
    else
        axis(axL, 'off');
    end

    axR = nexttile(tl2, (r-1)*2 + 2);
    if r <= traceB.n
        plot(axR, traceB.x_axis, dataB(r,:), 'Color', colB.line, 'LineWidth', 1.2);
        xline(axR, 0, '--', 'Color', [0.7 0.7 0.7]);
        title(axR, traceB.animal_names{r}, 'Interpreter', 'none', 'FontSize', 9);
        box(axR, 'off'); set(axR, 'TickDir', 'out', 'FontSize', 8);
    else
        axis(axR, 'off');
    end
end

appendPageToPDF(fig2, pdf_path, false);
close(fig2);

% ---- Page 3: stats text ----
fig3 = reportPageFigure();
writeCompareStatsTextPage(fig3, traceA, traceB, label_A, label_B, stat_line);
appendPageToPDF(fig3, pdf_path, false);
close(fig3);

fitPDFToLetter(pdf_path);

fprintf('Report written: %s\n', pdf_path);

end

function writeCompareStatsTextPage(fig, traceA, traceB, label_A, label_B, stat_line)

% SV 9/9/26 (per user's request): margin widened (was 0.06/0.06/0.88/
% 0.88) so text doesn't sit right up against the page edge.
axes(fig, 'Position', [0.10 0.08 0.80 0.84], 'Visible', 'off'); %#ok<LAXES>

lines = {};
lines{end+1} = 'Statistics Report';
lines{end+1} = sprintf('%s vs %s', label_A, label_B);
lines{end+1} = '';
lines{end+1} = 'Method and justification:';
lines{end+1} = 'Nonparametric comparison of per-animal mean AUC. Paired (Wilcoxon';
lines{end+1} = 'signed-rank) when both traces share the same animals (e.g. 465 vs 560';
lines{end+1} = 'within one group); unpaired (Wilcoxon rank-sum / Mann-Whitney U) when they';
lines{end+1} = 'do not (e.g. TMS vs Sham, different animals). Neither test assumes a normal';
lines{end+1} = 'distribution, which photometry AUC values are not guaranteed to follow and';
lines{end+1} = 'which is not safe to assume at small n.';
lines{end+1} = '';
lines{end+1} = 'Significance stars: * p<0.05, ** p<0.01, *** p<0.001, ns = not significant';
lines{end+1} = '(p>=0.05). No multiple-comparison correction applied - treat as exploratory.';
lines{end+1} = 'At small n (a handful of animals, typical for a pilot cohort) even a real';
lines{end+1} = 'effect can fail to reach conventional significance - a null result reflects';
lines{end+1} = 'a power limitation, not evidence of no effect.';
lines{end+1} = '';

if traceA.TRANGE_pre ~= traceB.TRANGE_pre || traceA.TRANGE_post ~= traceB.TRANGE_post
    lines{end+1} = sprintf(['NOTE: Trace A and Trace B were run with different TRANGE windows ' ...
        '(A: -%g to %g s, B: -%g to %g s). Traces are still aligned on the event at t=0, ' ...
        'but their x-axis extents differ, and the overlay panel''s Baseline/AUC-window bars ' ...
        'are drawn from Trace A''s parameters only.'], ...
        traceA.TRANGE_pre, traceA.TRANGE_post, traceB.TRANGE_pre, traceB.TRANGE_post);
    lines{end+1} = '';
end

lines{end+1} = sprintf('Trace A: %s (n=%d)', label_A, traceA.n);
lines{end+1} = sprintf('Trace B: %s (n=%d)', label_B, traceB.n);
lines{end+1} = '';
lines{end+1} = 'Results:';
lines{end+1} = '';
lines{end+1} = stat_line;

text(0, 1, strjoin(lines, sprintf('\n')), 'Units', 'normalized', 'VerticalAlignment', 'top', ...
    'FontName', 'Consolas', 'FontSize', 10, 'Interpreter', 'none');

end

% ---------------------------------------------------------------------- %
%  EXPORT + SUMMARY (CSV/txt exports - unchanged, never the complaint)   %
% ---------------------------------------------------------------------- %

function exportComparisonAUC(traceA, traceB, selection, out_dir) %#ok<INUSD>

group = [repmat({makeTraceLabel(traceA)}, traceA.n, 1); repmat({makeTraceLabel(traceB)}, traceB.n, 1)];
mouse = [traceA.animal_names(:); traceB.animal_names(:)];
mean_auc = [traceA.animal_mean_auc(:); traceB.animal_mean_auc(:)];

per_animal_table = table(group, mouse, mean_auc, ...
    'VariableNames', {'Trace', 'Mouse', 'Mean_AUC_per_animal'});
writetable(per_animal_table, fullfile(out_dir, 'auc_per_animal.csv'));

trial_group = [repmat({makeTraceLabel(traceA)}, numel(traceA.trial_auc), 1); ...
               repmat({makeTraceLabel(traceB)}, numel(traceB.trial_auc), 1)];
trial_mouse = [traceA.trial_auc_animal(:); traceB.trial_auc_animal(:)];
trial_auc = [traceA.trial_auc(:); traceB.trial_auc(:)];

trial_table = table(trial_group, trial_mouse, trial_auc, ...
    'VariableNames', {'Trace', 'Mouse', 'Trial_AUC'});
writetable(trial_table, fullfile(out_dir, 'auc_trial_level.csv'));

end

function writeCompareSummary(traceA, traceB, selection, out_dir) %#ok<INUSD>

log_file = fullfile(out_dir, 'compare_summary.txt');
fid = fopen(log_file, 'w');
if fid == -1
    warning('Could not create summary log file: %s', log_file);
    return;
end
cleanup_obj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, 'Photometry trace comparison\n');
fprintf(fid, 'Timestamp: %s\n\n', datestr(now));

printSideCT(fid, 'Trace A', traceA);
fprintf(fid, '\n');
printSideCT(fid, 'Trace B', traceB);

if traceA.TRANGE_pre ~= traceB.TRANGE_pre || traceA.TRANGE_post ~= traceB.TRANGE_post
    fprintf(fid, ['\nNOTE: Trace A and Trace B were run with different TRANGE windows ' ...
        '(A: -%g to %g s, B: -%g to %g s). Traces are still aligned on the event at t=0, ' ...
        'but their x-axis extents differ.\n'], ...
        traceA.TRANGE_pre, traceA.TRANGE_post, traceB.TRANGE_pre, traceB.TRANGE_post);
end

sig_label = describeComparison(traceA.animal_mean_auc, traceB.animal_mean_auc, false);
fprintf(fid, '\nUnpaired AUC comparison: n = %d vs %d, %s\n', traceA.n, traceB.n, sig_label);

end

function printSideCT(fid, label, trace)
fprintf(fid, '%s:\n', label);
fprintf(fid, '  Day folder: %s\n', trace.day_folder);
fprintf(fid, '  Run: %s\n', trace.run_folder);
fprintf(fid, '  Behavior: %s\n', trace.behavior);
fprintf(fid, '  Condition: %s\n', trace.condition_label);
fprintf(fid, '  Channel: %s\n', trace.channel_display);
fprintf(fid, '  TRANGE: -%g to %g s\n', trace.TRANGE_pre, trace.TRANGE_post);
fprintf(fid, '  Animals (n=%d): %s\n', trace.n, strjoin(trace.animal_names, ', '));
end

% ---------------------------------------------------------------------- %
%  SMALL LOCAL UTILITIES                                                 %
% ---------------------------------------------------------------------- %

function out_dir = makeComparisonOutputDir(root_dir, selection)

results_root = fullfile(root_dir, 'Photometry_Comparisons');
if ~exist(results_root, 'dir'), mkdir(results_root); end

name_A = safeFileNameCT(sprintf('%s_%s', selection.A.day_folder, selection.A.channel_display));
name_B = safeFileNameCT(sprintf('%s_%s', selection.B.day_folder, selection.B.channel_display));
folder_name = sprintf('%s__vs__%s__%s', name_A, name_B, datestr(now, 'yyyy_mm_dd_HHMMSS'));

out_dir = fullfile(results_root, folder_name);
if ~exist(out_dir, 'dir'), mkdir(out_dir); end

end

function s = safeFileNameCT(s)
s = regexprep(s, '[^A-Za-z0-9_-]', '_');
end

function label = makeTraceLabel(trace)
label = sprintf('%s | %s | %s', trace.day_folder, strrep(trace.condition_label, '_', ' '), trace.channel_display);
end



% ====================================================================== %
%  CROSS-DAY BEHAVIOR REPORTS                                             %
%  SV 9/28/26 (v3): one document set per BEHAVIOR covering every day, in  %
%  experiment order (Hab -> Train -> Retr), written into the dataset      %
%  root - see writeBehaviorReportsAcrossDays for the file names and page  %
%  layout. Replaces the v2 layout (one PDF per behavior x Session, a      %
%  tiledlayout grid of every epoch x tone bin, separate full-page AUC dot %
%  plots), which is kept in outdated_SV\ for reference.                   %
%                                                                         %
%  Series A vs series B stays generic (reportComparisonSpecs): TMS vs     %
%  Sham within a channel, or GFP (465) vs RFP (560) within a group.       %
% ====================================================================== %

function tl = paddedTiledLayout(fig, nrows, ncols, tile_spacing)
% SV 9/9/26: every report page's tiledlayout goes through here so every
% page gets the SAME generous, explicit margin on all four sides -
% tiledlayout's own 'Padding','loose' option is qualitative (a small
% fixed amount) and, combined with the figure filling edge-to-edge by
% default, was not enough on its own; the reference script's PDF export
% kept clipping content at the page edges during development. Setting
% Units to 'normalized' and OuterPosition explicitly reserves real space
% - ~8% left/right/bottom, ~11% top (room for the title+subtitle) - that
% survives into the exported PDF as visible margin, on every side, not
% just the bottom.
% SV 9/9/26 (per user's request): margins widened again (was 0.05/0.05/
% 0.90/0.87) - text/axis labels were still reading as right up against
% the page edge.
tl = tiledlayout(fig, nrows, ncols, 'TileSpacing', tile_spacing, 'Padding', 'loose');
tl.Units = 'normalized';
tl.OuterPosition = [0.08 0.08 0.84 0.81];
end

function writeBehaviorReportsAcrossDays(root_dir, colors, update)
% SV 10/1/26 (v4, per user's request): ONE PDF for the whole dataset,
% <root_dir>\PhotometryReport_<yyyymmdd>.pdf, replacing v3's one file per
% behavior x comparison (+ separate QC files). Organized as:
%   1. Contents page - every behavior x comparison x day as a link, plus
%      the stats and QC sections.
%   2. Plots - per behavior (Platform Entry/Exit, Tone Onset, Shock/
%      No-shock), per comparison (the four dual-color comparisons, or the
%      one TMS-vs-Sham 465 comparison for single-color data - see
%      reportComparisonSpecs), the days in experiment order (Hab -> Train
%      -> Retr, sortDayKeys) - so one behavior x comparison reads straight
%      through as a timeline. Page layout per day is unchanged from v3
%      (see writeDayRows).
%   3. Stats - one block per behavior x comparison.
%   4. QC - per behavior, per channel, the days in order.
% Every page carries a clickable navigation bar at the top (jump to the
% same day in another behavior or comparison, or another day of this one;
% Contents/Stats/QC), and the PDF has a matching bookmark outline.
%
% MATLAB draws each section into a temporary PDF and records what is on
% every page (behavior, comparison, kind, day); assemble_photometry_report.py
% (next to this script, run through MATLAB's Python interface with PyMuPDF)
% then merges them in order and adds the contents page, navigation links
% and bookmarks. If that step fails, the section PDFs are moved into
% root_dir instead so nothing is lost.
%
% colors (optional): the series colors (see defaultReportColors). Omitted
% -> the colors saved with the newest run that has any, else the defaults.
%
% SV 10/1/26 (per user's request): the report's building blocks - one PDF
% per section plus manifest.json - are kept next to it in
% <report name>_parts\, so a later run can UPDATE it: update (optional,
% from selectReportMode) = struct('parts_dir', <an existing report's
% _parts folder>, 'name', ..., 'rebuild', {behavior keys}). Only the
% behaviors in update.rebuild are rebuilt from the saved results; every
% other behavior's sections are copied from that report unchanged. The
% result is always a NEW report named by today's date (newReportName), so
% the old one is never overwritten. Omitted/empty -> a full new report.
if nargin < 2
    colors = [];
end
if nargin < 3
    update = [];
end
fprintf('\nBuilding photometry report...\n');
warning('off', 'MATLAB:print:ContentTypeImageSuggested');
animalResultCache('clear');

runs = scanPhotometryResults(root_dir);
if isempty(runs)
    warning('No saved photometry results found under %s - skipping report generation.', root_dir);
    return;
end
keep = false(1, numel(runs));
for i = 1:numel(runs)
    keep(i) = ~isempty(splitGroupAndDayKey(runs(i).day_folder));
end
runs = runs(keep);
if isempty(runs)
    warning(['No day folders matched the tms_*/sham_* naming convention - skipping report ' ...
        'generation. (Day folders must start with "tms_" or "sham_" for this pairing to work.)']);
    return;
end

if isempty(colors)
    colors = colorsFromRuns(runs);
end
reportColorStore('set', colors);

[report_name, parts_dir] = newReportName(root_dir);
mkdir(parts_dir);

% Behaviors in a fixed, meaningful order (anything unrecognized last).
behaviors = unique({runs.behavior}, 'stable');
known = {'platform_entry_exit', 'tone_on_vs_off_platform', 'tone_shock_vs_noshock', 'reward'};
[~, ord] = sort(cellfun(@(b) find([strcmp(known, b), true], 1), behaviors));
behaviors = behaviors(ord);

sections = struct('file', {}, 'behavior', {}, 'behavior_label', {}, 'comparison', {}, ...
    'comparison_label', {}, 'kind', {}, 'page_kinds', {}, 'page_days', {});

% Update mode: the base report's sections, and which behaviors to rebuild.
base_sections = sections;
if ~isempty(update)
    base_sections = loadReportSections(update.parts_dir, sections);
    fprintf('Updating report %s: rebuilding %s; reusing the rest.\n', update.name, strjoin(update.rebuild, ', '));
    reused = setdiff(unique({base_sections.behavior}, 'stable'), update.rebuild, 'stable');
    behaviors = unique([behaviors, reused], 'stable');
    [~, ord] = sort(cellfun(@(b) find([strcmp(known, b), true], 1), behaviors));
    behaviors = behaviors(ord);
end

for bi = 1:numel(behaviors)
    b = behaviors{bi};
    if ~isempty(update) && ~any(strcmp(update.rebuild, b))
        % Not recalculated this run: copy this behavior's sections as-is.
        keep_sec = base_sections(strcmp({base_sections.behavior}, b));
        for k = 1:numel(keep_sec)
            [~, nm, ext] = fileparts(keep_sec(k).file);
            dest = fullfile(parts_dir, [nm ext]);
            copyfile(keep_sec(k).file, dest, 'f');
            keep_sec(k).file = dest;
        end
        sections = [sections, keep_sec]; %#ok<AGROW>
        continue;
    end
    try
        new_sections = writeBehaviorDocuments(parts_dir, runs(strcmp({runs.behavior}, b)), b);
        sections = [sections, new_sections]; %#ok<AGROW>
    catch ME
        warning('Failed to build report sections for %s:\n%s', b, ME.getReport());
    end
    animalResultCache('clear');
end
if isempty(sections)
    warning('No report pages were produced.');
    return;
end

[~, dataset_name] = fileparts(char(root_dir));
c = reportColorStore('get');
info = { ...
    sprintf('Dataset: %s', root_dir), ...
    sprintf('Generated %s by PMA_photometry_complete_SVv1', datestr(now, 'yyyy-mm-dd HH:MM')), ...
    sprintf('Colors: TMS 465 = %s, Sham 465 = %s, TMS 560 = %s, Sham 560 = %s', ...
        c.tms_pv, c.sham_pv, c.tms_sst, c.sham_sst)};
if ~isempty(update)
    info{end+1} = sprintf('Updated from %s: rebuilt %s', update.name, strjoin(update.rebuild, ', '));
end
out_pdf = fullfile(root_dir, [report_name '.pdf']);
assembled = assemblePhotometryReport(sections, out_pdf, sprintf('Photometry Report  |  %s', dataset_name), info, parts_dir);
if assembled
    fprintf('Report written: %s\n', out_pdf);
else
    fprintf('Report sections kept (unassembled) in: %s\n', parts_dir);
end
end

function [name, parts_dir] = newReportName(root_dir)
% PhotometryReport_<yyyymmdd>; if that already exists (a second report the
% same day), the time is appended so an existing report is never replaced.
name = sprintf('PhotometryReport_%s', datestr(now, 'yyyymmdd'));
if isfile(fullfile(root_dir, [name '.pdf'])) || isfolder(fullfile(root_dir, [name '_parts']))
    name = sprintf('PhotometryReport_%s', datestr(now, 'yyyymmdd_HHMMSS'));
end
parts_dir = fullfile(root_dir, [name '_parts']);
end

function sections = loadReportSections(parts_dir, template)
% Reads an existing report's manifest.json back into the sections struct
% (same fields as template), keeping only sections whose PDF still exists.
sections = template;
mf = fullfile(parts_dir, 'manifest.json');
if ~isfile(mf)
    warning('No manifest in %s - nothing can be reused from it.', parts_dir);
    return;
end
M = jsondecode(fileread(mf));
raw = M.sections;
if iscell(raw)
    raw = [raw{:}];
end
for k = 1:numel(raw)
    r = raw(k);
    if ~isfile(r.file)
        [~, nm, ext] = fileparts(r.file);
        alt = fullfile(parts_dir, [nm ext]);
        if ~isfile(alt)
            continue;
        end
        r.file = alt;
    end
    sections(end+1) = struct('file', r.file, 'behavior', r.behavior, 'behavior_label', r.behavior_label, ... %#ok<AGROW>
        'comparison', r.comparison, 'comparison_label', r.comparison_label, 'kind', r.kind, ...
        'page_kinds', {asCell(r.page_kinds)}, 'page_days', {asCell(r.page_days)});
end
end

function c = asCell(v)
% jsondecode gives a cell for a JSON string array, a char for one string,
% and [] for an empty array.
if iscell(v)
    c = v(:)';
elseif ischar(v)
    c = {v};
else
    c = {};
end
end

function update = selectReportMode(root_directory)
% SV 10/1/26 (per user's request): asked at the start of a batch run when
% the dataset already has photometry reports. "Make a new report" (default)
% builds a full new report from every behavior's saved results. "Update an
% existing report" rebuilds only the behaviors chosen in the rest of the
% wizard (they are the ones re-processed this run) and copies every other
% behavior's pages from the chosen report; the result is saved under a new
% dated name, the chosen report is left as it is. Returns [] for a new
% report, else struct('parts_dir', 'name', 'rebuild') - rebuild is filled
% in by getPMAParamsMultiDay once the behaviors are chosen.
update = [];
cands = dir(fullfile(root_directory, 'PhotometryReport_*_parts', 'manifest.json'));
if isempty(cands)
    return;
end
[~, ord] = sort([cands.datenum], 'descend');
cands = cands(ord);
names = cell(1, numel(cands));
for k = 1:numel(cands)
    [~, folder] = fileparts(cands(k).folder);
    names{k} = regexprep(folder, '_parts$', '');
end

fig = uifigure('Name', 'Photometry report', 'Position', [100 100 560 250]);
fig.UserData.ok = false;
fig.CloseRequestFcn = @(src, evt) uiresume(fig);
g = uigridlayout(fig, [5 1]);
g.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit'};
uilabel(g, 'Text', 'This dataset already has photometry reports. What should this run produce?', 'FontWeight', 'bold');
mode_dd = uidropdown(g, 'Items', {'Make a new report', 'Update an existing report'}, 'Value', 'Make a new report');
report_dd = uidropdown(g, 'Items', names, 'Value', names{1}, 'Enable', 'off');
mode_dd.ValueChangedFcn = @(src, ~) set(report_dd, 'Enable', matlab.lang.OnOffSwitchState(strcmp(src.Value, 'Update an existing report')));
uilabel(g, 'WordWrap', 'on', 'Text', ['Update: only the behaviors you select in the next steps are recalculated and rebuilt; ' ...
    'every other behavior is copied from the chosen report. The result is saved as a new report with today''s date - ' ...
    'the chosen report is not changed.']);
uibutton(g, 'Text', 'Continue', 'BackgroundColor', [0.30 0.69 0.31], 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
    'ButtonPushedFcn', @(~, ~) onOK());
uiwait(fig);
if ~isvalid(fig) || ~fig.UserData.ok
    if isvalid(fig), delete(fig); end
    error('Report choice cancelled.');
end
if strcmp(mode_dd.Value, 'Update an existing report')
    name = report_dd.Value;
    update = struct('parts_dir', fullfile(root_directory, [name '_parts']), 'name', name, 'rebuild', {{}});
end
delete(fig);

    function onOK()
        fig.UserData.ok = true;
        uiresume(fig);
    end
end

function ok = assemblePhotometryReport(sections, out_pdf, title_str, info, parts_dir)
% Hands the section list to assemble_photometry_report.py (beside this
% script) as a JSON manifest, run via runReportPython. Returns false (with
% a warning) if no Python with PyMuPDF is found or the merge fails.
ok = false;
manifest = struct('title', title_str, 'info', {info}, 'sections', sections);
manifest_path = fullfile(parts_dir, 'manifest.json');
fid = fopen(manifest_path, 'w', 'n', 'UTF-8');
if fid == -1
    warning('Could not write report manifest %s.', manifest_path);
    return;
end
fwrite(fid, jsonencode(manifest), 'char');
fclose(fid);

[ok, msg] = runReportPython({'assemble', manifest_path, char(out_pdf)});
ok = ok && isfile(out_pdf);
if ~ok
    warning('Could not assemble the single-PDF report - section PDFs are kept instead.\n%s', msg);
end
end

function sections = writeBehaviorDocuments(parts_dir, bruns, behavior)
% All report sections for one behavior, as temporary PDFs in parts_dir:
% one per comparison (plot pages for every day, then that comparison's
% stats pages) and one QC section per channel. Returns their manifest
% entries (see writeBehaviorReportsAcrossDays). Days are the outer loop,
% with the animal cache cleared after each, and every section is appended
% to in step, so each day's saved results are loaded once for all of them.
sections = struct('file', {}, 'behavior', {}, 'behavior_label', {}, 'comparison', {}, ...
    'comparison_label', {}, 'kind', {}, 'page_kinds', {}, 'page_days', {});
condition_labels = canonicalBaseLabels(behavior);
if isempty(condition_labels)
    warning('No canonical condition labels known for behavior %s - skipping.', behavior);
    return;
end

day_of_run = cell(1, numel(bruns));
for i = 1:numel(bruns)
    [~, day_of_run{i}] = splitGroupAndDayKey(bruns(i).day_folder);
end
days = sortDayKeys(unique(day_of_run));

is_dual = false;
for i = 1:numel(bruns)
    if isfield(bruns(i).params, 'STREAM_STORE_560') && ~isempty(bruns(i).params.STREAM_STORE_560)
        is_dual = true;
        break;
    end
end
specs = reportComparisonSpecs(is_dual);
max_tones = maxTonesInRuns(bruns);
prefix = behaviorDocPrefix(behavior);

docs = cell(1, numel(specs));
for si = 1:numel(specs)
    tag = specs(si).file_tag;
    if isempty(tag)
        tag = 'TMSvsSham';
    end
    docs{si} = reportDocState(fullfile(parts_dir, sprintf('%s__%s.pdf', prefix, tag)), ...
        sprintf('%s  |  %s', behaviorDisplayName(behavior), specs(si).title_tag), specs(si).trace_caption);
end

qc_channels = {'pv'};
if is_dual
    qc_channels{end+1} = 'sst';
end
qc_paths = cell(size(qc_channels));
qc_page_days = cell(size(qc_channels));
for qi = 1:numel(qc_channels)
    qc_paths{qi} = fullfile(parts_dir, sprintf('%s__QC_%s.pdf', prefix, channelFluorName(qc_channels{qi})));
    qc_page_days{qi} = {};
end

for d = 1:numel(days)
    day = days{d};
    day_runs = bruns(strcmp(day_of_run, day));
    tms_all = day_runs(strncmpi({day_runs.day_folder}, 'tms_', 4));
    sham_all = day_runs(strncmpi({day_runs.day_folder}, 'sham_', 5));

    % Report grid: newest run per cell, epochs/filters in report order only.
    g = struct('behavior', behavior, 'day_key', day, ...
        'tms_runs', selectRunsForReport(tms_all, behavior, true), ...
        'sham_runs', selectRunsForReport(sham_all, behavior, true));
    row_keys = reportRowKeys(behavior, [g.tms_runs, g.sham_runs]);
    col_keys = reportColKeys([g.tms_runs, g.sham_runs], max_tones);
    if isempty(row_keys) || isempty(col_keys)
        continue;
    end
    fprintf('  %s: %s\n', behavior, day);

    for si = 1:numel(specs)
        try
            docs{si} = writeDayRows(docs{si}, g, specs(si), condition_labels, row_keys, col_keys, max_tones);
        catch ME
            warning('Failed on %s / %s / %s:\n%s', behavior, day, specs(si).stats_header, ME.getReport());
        end
    end

    % QC: newest run per cell but EVERY epoch/filter kept, so the raw-trace
    % event ticks show every tagged event, not just the report's epochs.
    g_qc = struct('behavior', behavior, 'day_key', day, ...
        'tms_runs', selectRunsForReport(tms_all, behavior, false), ...
        'sham_runs', selectRunsForReport(sham_all, behavior, false));
    for qi = 1:numel(qc_channels)
        try
            n_qc = writeGroupQCPage(qc_paths{qi}, g_qc, condition_labels, qc_channels{qi});
            qc_page_days{qi} = [qc_page_days{qi}, repmat({day}, 1, n_qc)];
        catch ME
            warning('QC pages failed on %s / %s / %s:\n%s', behavior, day, qc_channels{qi}, ME.getReport());
        end
    end

    animalResultCache('clear');
end

for si = 1:numel(specs)
    P = writeReportStatsPages(docs{si}, specs(si), behavior);
    P = reportDocFlush(P);
    if ~P.wrote
        continue;
    end
    sections(end+1) = struct('file', P.pdf, 'behavior', behavior, ... %#ok<AGROW>
        'behavior_label', behaviorDisplayName(behavior), 'comparison', specs(si).nav_label, ...
        'comparison_label', specs(si).title_tag, 'kind', 'plots', ...
        'page_kinds', {P.page_kinds}, 'page_days', {P.page_days});
end
for qi = 1:numel(qc_paths)
    if ~isfile(qc_paths{qi})
        continue;
    end
    fitPDFToLetter(qc_paths{qi});
    fluor = channelFluorName(qc_channels{qi});
    sections(end+1) = struct('file', qc_paths{qi}, 'behavior', behavior, ... %#ok<AGROW>
        'behavior_label', behaviorDisplayName(behavior), 'comparison', fluor, ...
        'comparison_label', sprintf('QC: raw %s %s traces', fluor, channelDisplayName(qc_channels{qi})), ...
        'kind', 'qc', 'page_kinds', {repmat({'qc'}, 1, numel(qc_page_days{qi}))}, ...
        'page_days', qc_page_days(qi));
end
end

function P = writeDayRows(P, g, spec, condition_labels, row_keys, col_keys, max_tones)
% One day's section of one comparison document: a day banner, then one row
% per (condition, row key) - condition outer, so e.g. platform entry ITI,
% entry Tone, exit ITI, exit Tone. Each row: aggregate panel (col_keys{1},
% the all-tones bin) at full size, then each tone bin as a scaled copy
% (factor k in both x and y) on the same baseline. Y-axis span is matched
% across the row; the AUC inset is drawn after that, behind the traces.
runsA = groupRuns(g, spec.a_group);
runsB = groupRuns(g, spec.b_group);
if isempty(runsA) && isempty(runsB)
    return;
end
if spec.is_paired && isempty(runsA)
    return;
end
if spec.is_paired
    req_a = spec.b_channel;
    req_b = spec.a_channel;
else
    req_a = '';
    req_b = '';
end

% Row geometry, inches on an 8.5 x 11 portrait page (0.5 in margins).
L = reportLayout();
ncols = numel(col_keys);
is_agg = isAggregateToneTag(col_keys{1});
if is_agg
    n_small = ncols - 1;
    Wa = (L.usable_w - L.ylab_w - n_small * L.gap) / (1 + n_small * L.k);
else
    n_small = 0;
    Wa = (L.usable_w - L.ylab_w - (ncols - 1) * L.gap) / ncols;
end

P = reportDayBanner(P, g.day_key);

for c = 1:numel(condition_labels)
    cond = condition_labels{c};
    action_label = condLabelDisplayName(cond);
    for r = 1:numel(row_keys)
        rk = row_keys{r};
        % Skip a row nobody ran (e.g. a shock-filter only one group has).
        if isempty(findRun(runsA, rk, col_keys{1}, g.behavior)) && isempty(findRun(runsB, rk, col_keys{1}, g.behavior))
            any_run = false;
            for j = 1:ncols
                any_run = any_run || ~isempty(findRun(runsA, rk, col_keys{j}, g.behavior)) ...
                    || ~isempty(findRun(runsB, rk, col_keys{j}, g.behavior));
            end
            if ~any_run
                continue;
            end
        end

        P = reportDocEnsure(P, L.row_h);
        base_y = P.y - L.row_h + L.bottom_pad;
        x = L.left + L.ylab_w;
        row_axes = gobjects(1, 0);
        row_auc = cell(0, 4);
        row_params = {};
        row_small = false(1, 0);
        row_rng = [Inf -Inf];
        row_data = cell(0, 2);
        for j = 1:ncols
            if j == 1 || n_small == 0
                sc = 1;
            else
                sc = L.k;
            end
            w = Wa * sc;
            h = L.Ha * sc;
            ax = axes(P.fig, 'Units', 'inches', 'Position', [x, base_y, w, h]); %#ok<LAXES>
            x = x + w + L.gap;

            ck = col_keys{j};
            runA = findRun(runsA, rk, ck, g.behavior);
            runB = findRun(runsB, rk, ck, g.behavior);
            [dataA, nA, ~, ~, aucA, nA_trials] = loadRunSeriesByBase(runA, g.behavior, spec.a_channel, cond, spec.a_label, spec.a_color, req_a);
            [dataB, nB, ~, ~, aucB, nB_trials] = loadRunSeriesByBase(runB, g.behavior, spec.b_channel, cond, spec.b_label, spec.b_color, req_b);
            if ~isempty(runA)
                ref_params = runA.params;
            elseif ~isempty(runB)
                ref_params = runB.params;
            else
                ref_params = [];
            end

            col_label = toneTagDisplayLabel(ck, max_tones);
            row_label = rowKeyDisplayLabel(g.behavior, rk);
            if isToneOnOffPlatformCond(cond)
                parts = toneOnsetPanelTitleParts(toneOnOffWord(cond), row_label, col_label);
                panel_title = strtrim(sprintf('%s %s', parts{1}, parts{2}));
            elseif isShockNoShockCond(cond)
                parts = shockOutcomePanelTitleParts(shockedWord(cond), row_label, col_label);
                panel_title = strtrim(sprintf('%s %s', parts{1}, parts{2}));
            else
                panel_title = makeGridPanelTitle(action_label, row_label, col_label);
            end

            if isempty(ref_params) || (isempty(dataA) && isempty(dataB))
                text(ax, 0.5, 0.5, 'No data', 'Units', 'normalized', 'HorizontalAlignment', 'center', ...
                    'Color', [0.6 0.6 0.6], 'FontSize', 7 * sc);
                axis(ax, 'off');
                title(ax, panel_title, 'Interpreter', 'none', 'FontSize', 7.5 * max(sc, 0.8), 'FontWeight', 'bold');
                continue;
            end

            event_lines = getEventLines(ref_params);
            xlim_vals = [-ref_params.TRANGE_pre, ref_params.TRANGE_post];
            [legend_tex, mean_rng] = plotTwoTraceOverlayPanel(ax, dataA, nA, spec.a_label, spec.a_color, ...
                dataB, nB, spec.b_label, spec.b_color, event_lines, xlim_vals, ref_params, [], [], true, nA_trials, nB_trials);
            set(ax, 'FontSize', 7 * max(sc, 0.8), 'LineWidth', 0.5);
            setPanelTitleWithLegend(ax, panel_title, legend_tex, 7.5 * max(sc, 0.8), 6.5 * max(sc, 0.8));

            row_axes(end+1) = ax; %#ok<AGROW>
            row_auc(end+1, :) = {aucA, aucB, panel_title, sc}; %#ok<AGROW>
            row_params{end+1} = ref_params; %#ok<AGROW>
            row_small(end+1) = sc < 1; %#ok<AGROW>
            row_rng = [min(row_rng(1), mean_rng(1)), max(row_rng(2), mean_rng(2))];
            row_data(end+1, :) = {dataA, dataB}; %#ok<AGROW>

            if ~isempty(aucA) && ~isempty(aucB)
                sig_label = describeComparison(aucA, aucB, spec.is_paired);
                P.stats{end+1} = sprintf('[%s | %s] %s vs %s (%s, n=%d,%d): %s', g.day_key, panel_title, ...
                    spec.a_label, spec.b_label, ternaryStr(spec.is_paired, 'paired', 'unpaired'), ...
                    numel(aucA), numel(aucB), sig_label);
            end
        end

        % SV 10/1/26: one y-axis for the whole row (same data, total +
        % bins), ending on labeled ticks, bars just above the x-axis - see
        % applyRowAxes - and one AUC range shared by every inset in it.
        applyRowAxes(row_axes, row_rng, row_params, true, row_small);
        inset_vals = [];
        for j = 1:numel(row_axes)
            inset_vals = [inset_vals; insetValues(row_auc{j,1}); insetValues(row_auc{j,2})]; %#ok<AGROW>
        end
        R = insetRowRange(inset_vals);
        for j = 1:numel(row_axes)
            ax = row_axes(j);
            xr = xlim(ax);
            yr = ylim(ax);
            x_range = [xr(1) + 0.935*(xr(2)-xr(1)), xr(2) - 0.01*(xr(2)-xr(1))];
            y_range = [yr(1) + 0.52*(yr(2)-yr(1)), yr(1) + 0.95*(yr(2)-yr(1))];
            drawAUCInset(ax, row_auc{j,1}, spec.a_color, row_auc{j,2}, spec.b_color, x_range, y_range, ...
                spec.is_paired, row_auc{j,4}, R);
            if strcmp(cond, 'tone_shock')
                drawShockDelayLabel(ax, row_data{j,1}, row_data{j,2}, row_params{j}, spec, row_auc{j,4});
            end
        end

        P.y = P.y - L.row_h;
    end
end
end

function drawShockDelayLabel(ax, dataA, dataB, p, spec, sc)
% SV 10/1/26 (per user's request, option A from the delay preview): on a
% "Shocked during tones" panel, prints in grey beside the shock markers
% how long after the shock each series' GROUP-MEAN response reaches 50% of
% its rise (shockResponseDelay). The shock starts shock_onset_s after tone
% onset - the same 28 s used to classify shocked trials (getBehaviorEvents,
% filterToneEventsByShockOutcome) - so a delay far from the usual few
% tenths of a second, or negative, flags responses that are not aligned
% with the shock (e.g. timestamp problems).
shock_onset_s = 28;
shock_end_s = 30;
if isempty(dataA) && isempty(dataB)
    return;
end
parts = {};
if ~isempty(dataA)
    tA = linspace(-p.TRANGE_pre, p.TRANGE_post, size(dataA, 2));
    parts{end+1} = sprintf('%s %s', spec.a_label, formatDelay(shockResponseDelay(tA, mean(dataA, 1, 'omitnan'), shock_onset_s)));
end
if ~isempty(dataB)
    tB = linspace(-p.TRANGE_pre, p.TRANGE_post, size(dataB, 2));
    parts{end+1} = sprintf('%s %s', spec.b_label, formatDelay(shockResponseDelay(tB, mean(dataB, 1, 'omitnan'), shock_onset_s)));
end
yr = ylim(ax);
text(ax, shock_end_s + 1.5, yr(1) + 0.97 * diff(yr), sprintf('shock->response (50%% rise):\n%s', strjoin(parts, '   ')), ...
    'FontSize', 5 * max(sc, 0.8), 'Color', [0.45 0.45 0.45], 'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'top', 'Interpreter', 'none');
end

function s = formatDelay(v)
if isnan(v)
    s = 'n.r.';   % no clear response (rise < 1 z)
else
    s = sprintf('%+.2f s', v);
end
end

function delay = shockResponseDelay(t, y, ts)
% Seconds from the shock (ts) to the trace's 50%-rise point. Baseline =
% mean over [ts-5, ts-2] s; peak = max over [ts-3, ts+5] s (starting
% BEFORE the shock, so a response that leads the marker gives a negative
% delay rather than being missed); delay = first time the trace reaches
% baseline + 50% of the rise. NaN when the rise is under 1 z. Computed on
% the unsmoothed mean trace, lightly smoothed (5 samples) here.
delay = NaN;
y = movmean(y, 5);
bwin = t >= ts - 5 & t <= ts - 2;
swin = find(t >= ts - 3 & t <= ts + 5);
if ~any(bwin) || isempty(swin)
    return;
end
base = mean(y(bwin), 'omitnan');
[pk, ip] = max(y(swin));
if ~(pk - base >= 1)
    return;
end
c = find(y(swin(1:ip)) >= base + 0.5 * (pk - base), 1, 'first');
if ~isempty(c)
    delay = t(swin(c)) - ts;
end
end

function L = reportLayout()
% Page/row geometry for the cross-day comparison documents, in inches.
% Aggregate panel Ha tall; tone-bin panels are k-scale copies (x and y) of
% it on the same baseline. Four rows plus a day banner fit a page.
L = struct();
L.page_w = 8.5;
L.page_h = 11;
L.left = 0.5;
L.usable_w = 7.5;
L.top = 10.0;          % below the per-page title + caption
L.bottom = 0.5;
L.ylab_w = 0.42;       % y tick labels + "z-score" left of the first panel
L.gap = 0.40;          % between panels (holds the next panel's y labels)
L.k = 0.62;
L.Ha = 1.30;
L.bottom_pad = 0.42;   % x tick labels + "Time (s)"
L.top_pad = 0.45;      % two-line panel title (title + colored N/n legend)
L.row_h = L.bottom_pad + L.Ha + L.top_pad;
L.banner_h = 0.32;
end

function P = reportDocState(pdf_path, title_str, caption)
% SV 10/1/26: page_kinds/page_days record, per page written, whether it is
% a 'plots' or 'stats' page and which day it shows - the single-PDF
% assembler builds its navigation links and bookmarks from these.
P = struct('pdf', pdf_path, 'fig', [], 'y', 0, 'wrote', false, 'title', title_str, ...
    'caption', caption, 'stats', {{}}, 'page_kinds', {{}}, 'page_days', {{}}, ...
    'cur_kind', 'plots', 'cur_day', '');
if isfile(pdf_path)
    delete(pdf_path);
end
end

function P = reportDocNewPage(P)
% A fresh 8.5 x 11 in portrait page with the document title and caption
% at the top. The white full-page rectangle makes exportgraphics keep the
% whole Letter page instead of cropping to the drawn content (same trick
% as pma_extractor_SVv12's report_new_page - works because these pages use
% plain axes, not tiledlayout).
P = reportDocFlush(P);
L = reportLayout();
P.page_kinds{end+1} = P.cur_kind;
P.page_days{end+1} = P.cur_day;
P.fig = figure('Color', 'w', 'Units', 'inches', 'Position', [0.5 0.5 L.page_w L.page_h], 'Visible', 'off', ...
    'PaperUnits', 'inches', 'PaperSize', [L.page_w L.page_h], 'PaperPosition', [0 0 L.page_w L.page_h]);
annotation(P.fig, 'rectangle', [0 0 1 1], 'Color', 'w', 'FaceColor', 'none');
annotation(P.fig, 'textbox', [L.left/L.page_w, 10.30/L.page_h, L.usable_w/L.page_w, 0.28/L.page_h], ...
    'String', P.title, 'FontSize', 11, 'FontWeight', 'bold', 'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'Interpreter', 'none');
annotation(P.fig, 'textbox', [L.left/L.page_w, 10.05/L.page_h, L.usable_w/L.page_w, 0.24/L.page_h], ...
    'String', P.caption, 'FontSize', 7, 'FontAngle', 'italic', 'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'Interpreter', 'none');
P.y = L.top;
end

function P = reportDocFlush(P)
if ~isempty(P.fig) && isgraphics(P.fig)
    exportgraphics(P.fig, P.pdf, 'ContentType', 'vector', 'Append', P.wrote);
    P.wrote = true;
    close(P.fig);
end
P.fig = [];
end

function P = reportDocEnsure(P, h)
L = reportLayout();
if isempty(P.fig) || ~isgraphics(P.fig) || (P.y - h) < L.bottom
    P = reportDocNewPage(P);
end
end

function P = reportDayBanner(P, day_key)
% A shaded banner naming the day, kept on the same page as the first row
% under it (a banner stranded at the bottom of a page would label nothing).
L = reportLayout();
% A new day always starts a new page (SV 10/1/26), so every page belongs
% to exactly one day and the navigation bar's day links land on its top.
P.cur_day = day_key;
P = reportDocNewPage(P);
y0 = P.y - L.banner_h;
annotation(P.fig, 'rectangle', [L.left/L.page_w, (y0 + 0.05)/L.page_h, L.usable_w/L.page_w, 0.22/L.page_h], ...
    'FaceColor', [0.90 0.90 0.90], 'EdgeColor', [0.65 0.65 0.65], 'LineWidth', 0.5);
annotation(P.fig, 'textbox', [(L.left + 0.08)/L.page_w, (y0 + 0.05)/L.page_h, (L.usable_w - 0.16)/L.page_w, 0.22/L.page_h], ...
    'String', day_key, 'FontSize', 9, 'FontWeight', 'bold', 'EdgeColor', 'none', ...
    'VerticalAlignment', 'middle', 'Interpreter', 'none');
P.y = y0;
end

function P = writeReportStatsPages(P, spec, behavior)
% The closing statistics pages of one comparison document: method text,
% then every panel's AUC test (collected by writeDayRows), paginated.
if isempty(P.stats) && ~P.wrote && (isempty(P.fig) || ~isgraphics(P.fig))
    return;   % nothing was ever drawn for this comparison
end
lines = {};
lines{end+1} = 'Statistics Report';
lines{end+1} = sprintf('%s (%s)', behaviorDisplayName(behavior), spec.stats_header);
lines{end+1} = '';
lines{end+1} = 'Method and justification:';
if spec.is_paired
    lines{end+1} = 'Paired comparison (Wilcoxon signed-rank) of per-animal mean AUC between the';
    lines{end+1} = 'GFP (465) and RFP (560) channels within one group - both channels are';
    lines{end+1} = 'recorded from the same animals, so each animal is compared against itself.';
    lines{end+1} = 'Only animals with valid data in BOTH channels for a given panel are included.';
    lines{end+1} = 'Both channels are z-scored against their own baseline, so the comparison is';
    lines{end+1} = 'of response size relative to baseline noise, not of raw fluorescence.';
else
    lines{end+1} = 'Unpaired comparison (Wilcoxon rank-sum / Mann-Whitney U) of per-animal mean';
    lines{end+1} = 'AUC between the TMS and Sham groups - independent groups of different animals.';
end
lines{end+1} = 'Neither test assumes a normal distribution.';
lines{end+1} = '';
lines{end+1} = 'Significance: * p<0.05, ** p<0.01, *** p<0.001, ns = not significant. No';
lines{end+1} = 'multiple-comparison correction is applied - treat p-values as exploratory. At';
lines{end+1} = 'small n even a real effect can fail to reach significance; a null result';
lines{end+1} = 'reflects limited power, not evidence of no effect.';
lines{end+1} = '';
lines{end+1} = 'Results ([day | panel] series A vs series B):';
lines{end+1} = '';
if isempty(P.stats)
    lines{end+1} = '(No comparisons available - one or both sides had no data.)';
else
    lines = [lines, P.stats];
end

per_page = 72;
L = reportLayout();
P.cur_kind = 'stats';
P.cur_day = '';
for start = 1:per_page:numel(lines)
    P = reportDocNewPage(P);
    chunk = lines(start:min(numel(lines), start + per_page - 1));
    ax = axes(P.fig, 'Units', 'inches', 'Position', [L.left, L.bottom, L.usable_w, L.top - L.bottom - 0.1], ...
        'Visible', 'off'); %#ok<LAXES>
    text(ax, 0, 1, strjoin(chunk, newline), 'Units', 'normalized', 'VerticalAlignment', 'top', ...
        'FontName', 'Consolas', 'FontSize', 7.5, 'Interpreter', 'none');
end
end

function runs_out = selectRunsForReport(run_list, behavior, report_rows_only)
% One run per (row key, tone tag): when the same cell was run more than
% once (e.g. an older run with different windows left in the same
% Photometry_Results folder), the one with the newest GROUP file wins -
% older copies used to be picked arbitrarily, and their stale per-animal
% folders showed up as duplicate animals on the QC pages. With
% report_rows_only, rows not in the report's row order are dropped too
% (whole_session and pre_tone_baseline for platform entries/exits - see
% reportRowOrder).
runs_out = run_list([]);
if isempty(run_list)
    return;
end

% Stale runs from before the dataset was reorganized still sit in
% Photometry_Results, listing animals under their OLD session-folder
% names (e.g. DCSP_11_tms_RetrS1, now DCSP_11_tms_RetrS1_SV_Feb12). An
% animal whose session folder no longer exists in the day folder is
% dropped, and a run left with no animals is dropped entirely - otherwise
% such a run can win a cell (or the QC roster) with data nobody can map
% back to a current session.
keep_run = true(1, numel(run_list));
for i = 1:numel(run_list)
    live = false(1, numel(run_list(i).animals));
    for a = 1:numel(run_list(i).animals)
        an = run_list(i).animals(a);
        if isfield(an, 'session_folder') && ~isempty(an.session_folder)
            live(a) = isfolder(an.session_folder);
        else
            live(a) = isfolder(fullfile(run_list(i).day_path, an.mouse));
        end
    end
    run_list(i).animals = run_list(i).animals(live);
    run_list(i).n_animals = sum(live);
    keep_run(i) = any(live);
end
run_list = run_list(keep_run);
if isempty(run_list)
    return;
end

keys = cell(1, numel(run_list));
for i = 1:numel(run_list)
    keys{i} = [rowKeyForBehavior(behavior, run_list(i).params) '|' run_list(i).tone_tag];
end
[ukeys, ~, idx] = unique(keys, 'stable');
pick = zeros(1, numel(ukeys));
for u = 1:numel(ukeys)
    members = find(idx == u);
    [~, newest] = max([run_list(members).group_datenum]);
    pick(u) = members(newest);
end
runs_out = run_list(pick);
if report_rows_only
    allowed = reportRowOrder(behavior);
    keep = false(1, numel(runs_out));
    for i = 1:numel(runs_out)
        keep(i) = any(strcmp(rowKeyForBehavior(behavior, runs_out(i).params), allowed));
    end
    runs_out = runs_out(keep);
end
end

function order = reportRowOrder(behavior)
% SV 9/28/26 (per user's request): the rows a report shows, in order.
% whole_session and pre_tone_baseline are not shown (and not wizard
% defaults) - they overlap the ITI/tone epochs and cluttered every page
% with rows of mostly "No data".
switch behavior
    case 'platform_entry_exit'
        order = {'inter_tone_interval', 'whole_tone', 'tone_pre_shock', 'shock'};
    case 'tone_on_vs_off_platform'
        order = {'all_trials', 'shocked_trials', 'no_shock_trials'};
    otherwise
        order = {'default'};
end
end

function row_keys = reportRowKeys(behavior, run_list)
% reportRowOrder, restricted to the rows some run in run_list actually has.
order = reportRowOrder(behavior);
present = arrayfun(@(r) rowKeyForBehavior(behavior, r.params), run_list, 'UniformOutput', false);
row_keys = order(ismember(order, present));
end

function col_keys = reportColKeys(run_list, max_tones)
% Tone-bin columns in display order (aggregate first), keeping only bins
% some run has AND that start at or below the most tones any animal
% received - a 6-tone cohort gets no 7-9 column.
order = {'all_tones', 'tones_1_2_3', 'tones_4_5_6', 'tones_7_8_9', 'all_rewards'};
first_tone = [1, 1, 4, 7, 1];
present = unique({run_list.tone_tag});
col_keys = {};
for i = 1:numel(order)
    if any(strcmp(present, order{i})) && first_tone(i) <= max(1, max_tones)
        col_keys{end+1} = order{i}; %#ok<AGROW>
    end
end
end

function tf = isAggregateToneTag(tone_tag)
tf = any(strcmp(tone_tag, {'all_tones', 'all_rewards'}));
end

function n = maxTonesInRuns(run_list)
% The most tones any animal received, across every day folder in run_list
% (one run per day folder is enough - every run of a session shares the
% same tone onsets). 9 if nothing could be read.
n = 0;
seen = {};
for i = 1:numel(run_list)
    if any(strcmp(seen, run_list(i).day_folder))
        continue;
    end
    seen{end+1} = run_list(i).day_folder; %#ok<AGROW>
    for a = 1:numel(run_list(i).animals)
        f = run_list(i).animals(a).save_file;
        if ~isfile(f)
            continue;
        end
        ar = animalResultCache(f);
        if isfield(ar, 'tone_onsets_sec')
            n = max(n, numel(ar.tone_onsets_sec));
        end
    end
end
if n == 0
    n = 9;
end
end

function out = sortDayKeys(keys)
% Experiment order: Hab days, then Train, then Retr, then anything else;
% within each, by day number (D1, D2, ...) then session number (s1, s2,
% ...). e.g. HabD1s1, HabD1s2, HabD2s1, TrainD1s1, ..., RetrS1, RetrS2.
n = numel(keys);
sort_key = zeros(n, 3);
for i = 1:n
    s = lower(keys{i});
    if startsWith(s, 'hab')
        stage = 1;
    elseif startsWith(s, 'train')
        stage = 2;
    elseif startsWith(s, 'retr')
        stage = 3;
    else
        stage = 4;
    end
    dtok = regexp(s, 'd(\d+)', 'tokens', 'once');
    stok = regexp(s, 's(\d+)$', 'tokens', 'once');
    dnum = 0;
    snum = 0;
    if ~isempty(dtok), dnum = str2double(dtok{1}); end
    if ~isempty(stok), snum = str2double(stok{1}); end
    sort_key(i, :) = [stage, dnum, snum];
end
[~, order] = sortrows([sort_key, (1:n)']);
out = keys(order);
end

function prefix = behaviorDocPrefix(behavior)
% SV 9/28/26 (per user's request): document file-name prefixes.
switch behavior
    case 'platform_entry_exit'
        prefix = 'PlatEntryExit';
    case 'tone_on_vs_off_platform'
        prefix = 'OnOffPlat_ToneOnset';
    case 'tone_shock_vs_noshock'
        prefix = 'ShockNoshockTone';
    case 'reward'
        prefix = 'Reward';
    otherwise
        prefix = behavior;
end
end

function name = behaviorDisplayName(behavior)
switch behavior
    case 'platform_entry_exit'
        name = 'Platform Entry/Exit';
    case 'tone_on_vs_off_platform'
        name = 'Tone Onset, On vs Off Platform';
    case 'tone_shock_vs_noshock'
        name = 'Tone, Shocked vs Not Shocked';
    case 'reward'
        name = 'Reward';
    otherwise
        name = strrep(behavior, '_', ' ');
end
end

function name = channelFluorName(channel)
switch lower(channel)
    case 'pv'
        name = 'GFP';
    case 'sst'
        name = 'RFP';
    otherwise
        name = upper(channel);
end
end

function [grp, day_key] = splitGroupAndDayKey(day_folder)
% Mirrors the day_from_condition()/classify_group() convention documented
% in PMA_Dataset_Layout.md: tms_/sham_ as a lowercase name prefix, the
% remainder shared between the two groups' condition folders.
grp = '';
day_key = '';
lower_name = lower(day_folder);
if startsWith(lower_name, 'tms_')
    grp = 'tms';
    day_key = day_folder(5:end);
elseif startsWith(lower_name, 'sham_')
    grp = 'sham';
    day_key = day_folder(6:end);
end
end

function specs = reportComparisonSpecs(is_dual)
% SV 9/28/26: the comparisons each behavior's document set is built from.
% Series A/B each name a group ('tms'/'sham' - whose runs to read), a
% channel ('pv' = 465/GFP, 'sst' = 560/RFP) and a color (seriesColor - the
% user-picked palette colors). Single-color: one TMS-vs-Sham 465 document
% (file_tag ''). Dual-color:
%   1) GFP  TMS vs Sham  (unpaired, different animals)
%   2) RFP  TMS vs Sham  (unpaired)
%   3) TMS  GFP vs RFP   (paired - same animals, both channels)
%   4) Sham GFP vs RFP   (paired)
% When Sham GFP and Sham RFP share a color (both Control Grey by default),
% the Sham GFP-vs-RFP document draws RFP in Dark Grey so the two differ.
tms_vs_sham = @(channel, file_tag, title_tag, header, nav) makeSpec(file_tag, title_tag, header, ...
    'tms', channel, 'TMS', seriesColor('tms', channel), ...
    'sham', channel, 'Sham', seriesColor('sham', channel), false, nav);

if ~is_dual
    specs = tms_vs_sham('pv', '', 'TMS vs Sham, 465', 'TMS vs Sham', 'TMS v Sham');
    return;
end

sham_rfp = seriesColor('sham', 'sst');
if isequal(sham_rfp.line, seriesColor('sham', 'pv').line)
    sham_rfp = paletteColor('Dark Grey');
end
specs = [ ...
    tms_vs_sham('pv',  'GFP_TMSvsSham', 'TMS vs Sham, GFP 465', 'TMS vs Sham, GFP 465', 'GFP: TMS v Sham'), ...
    tms_vs_sham('sst', 'RFP_TMSvsSham', 'TMS vs Sham, RFP 560', 'TMS vs Sham, RFP 560', 'RFP: TMS v Sham'), ...
    makeSpec('TMS_GFPvsRFP', 'TMS animals: GFP 465 vs RFP 560', 'TMS: GFP vs RFP', ...
        'tms', 'pv', 'GFP', seriesColor('tms', 'pv'), 'tms', 'sst', 'RFP', seriesColor('tms', 'sst'), true, 'TMS: GFP v RFP'), ...
    makeSpec('Sham_GFPvsRFP', 'Sham animals: GFP 465 vs RFP 560', 'Sham: GFP vs RFP', ...
        'sham', 'pv', 'GFP', seriesColor('sham', 'pv'), 'sham', 'sst', 'RFP', sham_rfp, true, 'Sham: GFP v RFP')];
end

function spec = makeSpec(file_tag, title_tag, header, a_group, a_channel, a_label, a_color, ...
    b_group, b_channel, b_label, b_color, is_paired, nav_label)
% nav_label (SV 10/1/26): the comparison's short name in the single-PDF
% report's navigation bar and contents page.
if is_paired
    note = 'Only animals with valid data in both channels; paired Wilcoxon signed-rank; gray lines in the AUC inset join each animal''s two channels.';
else
    note = 'Unpaired Wilcoxon rank-sum.';
end
caption = sprintf(['%s = %s, %s = %s. Gray bars = baseline and AUC window. Y-axis span matched within each row. ' ...
    'AUC inset (top right): dots = animals, cross = mean +/- SEM, star = p<0.05. %s'], ...
    a_label, a_color.name, b_label, b_color.name, note);
spec = struct('file_tag', file_tag, 'title_tag', title_tag, 'stats_header', header, ...
    'a_group', a_group, 'a_channel', a_channel, 'a_label', a_label, 'a_color', a_color, ...
    'b_group', b_group, 'b_channel', b_channel, 'b_label', b_label, 'b_color', b_color, ...
    'is_paired', is_paired, 'trace_caption', caption, 'nav_label', nav_label);
end

function runs = groupRuns(g, group)
% The tms_* or sham_* half of a (behavior, Session) group's runs.
if strcmp(group, 'tms')
    runs = g.tms_runs;
else
    runs = g.sham_runs;
end
end

% ---------------------------------------------------------------------- %
%  SERIES COLORS (SV 9/28/26, per user's request) - picked per group x    %
%  channel in the wizard from the same palette as pma_extractor_SVv12's   %
%  group_palette (plus Dark Grey), saved with every run's params, and     %
%  read back from there by reports_only.                                  %
% ---------------------------------------------------------------------- %

function [names, rgb] = reportPalette()
% RGB 0-255, same values as pma_extractor_SVv12.m's group_palette, plus
% Dark Grey (a second grey for plots where both series would otherwise be
% Control Grey, e.g. Sham GFP vs Sham RFP).
P = { ...
    'Shock Red',    [217  31  31]; ...
    'SST Orange',   [210 102  36]; ...
    'PV Yellow',    [232 170  20]; ...
    'CORT Green',   [106 142  35]; ...
    'UCLA Blue',    [ 39 116 174]; ...
    'IT Blue',      [ 52  88 140]; ...
    'PT Purple',    [150  50 140]; ...
    'Cajal Brown',  [128  92  45]; ...
    'Control Grey', [ 89  89  89]; ...
    'Dark Grey',    [ 35  35  35]};
names = P(:, 1)';
rgb = cell2mat(P(:, 2));
end

function colors = defaultReportColors()
% DCSP defaults (SV 9/28/26): TMS PV (GFP) yellow, TMS SST (RFP) orange,
% Sham grey in both channels.
colors = struct('tms_pv', 'PV Yellow', 'tms_sst', 'SST Orange', ...
    'sham_pv', 'Control Grey', 'sham_sst', 'Control Grey');
end

function out = reportColorStore(action, value)
% The one place the current series colors live (persistent, so the deep
% plotting helpers can read it without threading it through every call).
% reportColorStore('set', colors_struct) / reportColorStore('get').
persistent C
if isempty(C)
    C = defaultReportColors();
end
if strcmp(action, 'set') && nargin >= 2 && isstruct(value)
    f = fieldnames(value);
    for i = 1:numel(f)
        C.(f{i}) = char(value.(f{i}));
    end
end
out = C;
end

function colors = colorsFromRuns(runs)
% The colors saved with the newest run that has any (see
% configureBehaviorColumns), else the defaults.
colors = defaultReportColors();
best = -Inf;
for i = 1:numel(runs)
    if isfield(runs(i).params, 'colors') && isstruct(runs(i).params.colors) && runs(i).group_datenum > best
        best = runs(i).group_datenum;
        colors = runs(i).params.colors;
    end
end
end

function c = paletteColor(name)
% struct('line', rgb 0-1, 'area', light tint for SEM shading, 'name', name)
[names, rgb] = reportPalette();
k = find(strcmpi(names, name), 1);
if isempty(k)
    warning('Unknown color "%s" - using Control Grey.', name);
    k = find(strcmp(names, 'Control Grey'), 1);
end
line_rgb = rgb(k, :) / 255;
c = struct('line', line_rgb, 'area', line_rgb + (1 - line_rgb) * 0.70, 'name', names{k});
end

function c = seriesColor(group, channel)
C = reportColorStore('get');
key = sprintf('%s_%s', lower(group), lower(channel));
if isfield(C, key)
    c = paletteColor(C.(key));
else
    c = paletteColor('Control Grey');
end
end

% ---------------------------------------------------------------------- %
%  SAVED-RESULT CACHE                                                     %
% ---------------------------------------------------------------------- %

function ar = animalResultCache(animal_file)
% SV 9/28/26: the report builders read the same per-animal .mat files many
% times over (every panel, every comparison, the QC pages). This keeps each
% one in memory after its first load, WITHOUT the whole-session raw
% signals (the bulk of the file; only the QC raw-trace panel needs them
% and loads them itself). animalResultCache('clear') empties it - done per
% day and per behavior so memory stays bounded, and at the start of each
% report build so files rewritten by a batch run are never served stale.
persistent M
if isempty(M) || strcmp(animal_file, 'clear')
    M = containers.Map('KeyType', 'char', 'ValueType', 'any');
    if strcmp(animal_file, 'clear')
        ar = [];
        return;
    end
end
key = char(animal_file);
if isKey(M, key)
    ar = M(key);
    return;
end
S = load(key, 'animal_result');
ar = S.animal_result;
if isfield(ar, 'signals')
    ar.signals = rmfield(ar.signals, intersect(fieldnames(ar.signals), {'pv', 'sst'}));
end
M(key) = ar;
end

function out = uniqueSorted(items, sort_key_fcn)
% Deduplicates a cell array of strings and orders it - alphabetically by
% default, or by sort_key_fcn(item) when given (used for tone bins, so
% they read left-to-right as all, 1-3, 4-6, 7-9 per the hand-drawn spec).
items = unique(items, 'stable');
if nargin < 2 || isempty(sort_key_fcn)
    out = sort(items);
    return;
end
keys = cellfun(sort_key_fcn, items);
[~, order] = sort(keys);
out = items(order);
end

function label = rowKeyForBehavior(behavior, run_params)
% The grid's ROW dimension is behavior-specific: platform_entry_exit
% varies by epoch, tone_on_vs_off_platform by shock-outcome filter,
% everything else has no such sub-dimension (single row).
switch behavior
    case 'platform_entry_exit'
        label = run_params.platform_epoch;
    case 'tone_on_vs_off_platform'
        label = run_params.tone_platform_shock_filter;
    otherwise
        label = 'default';
end
end

function label = rowKeyDisplayLabel(behavior, row_key)
% SV 9/9/26: short row labels per the hand-drawn spec (ITI, Tone, ...)
% instead of the raw underscore_case key.
switch behavior
    case 'platform_entry_exit'
        switch row_key
            case 'inter_tone_interval', label = 'ITI';
            case 'whole_tone', label = 'Tone';
            case 'whole_session', label = 'Whole Session';
            case 'pre_tone_baseline', label = 'Pre-Tone';
            case 'tone_pre_shock', label = 'Pre-Shock';
            case 'shock', label = 'Shock';
            otherwise, label = strrep(row_key, '_', ' ');
        end
    case 'tone_on_vs_off_platform'
        switch row_key
            case 'all_trials', label = 'All Trials';
            case 'shocked_trials', label = 'Shocked';
            case 'no_shock_trials', label = 'No Shock';
            otherwise, label = strrep(row_key, '_', ' ');
        end
    otherwise
        if strcmp(row_key, 'default')
            label = '';
        else
            label = strrep(row_key, '_', ' ');
        end
end
end

function label = toneTagDisplayLabel(tone_tag, max_tones)
% SV 9/28/26 (per user's request): max_tones (optional) - the most tones
% any animal in the dataset received. The all-tones bin is labeled with the
% real range, e.g. "Tones 1-6 (all)" for a 6-tone cohort like DCSP, not
% the nominal 1-9.
if nargin < 2 || isempty(max_tones) || max_tones < 1 || max_tones > 9
    max_tones = 9;
end
switch tone_tag
    case 'all_tones'
        label = sprintf('Tones 1-%d (all)', max_tones);
    case 'tones_1_2_3'
        label = 'Tones 1-3';
    case 'tones_4_5_6'
        label = 'Tones 4-6';
    case 'tones_7_8_9'
        label = 'Tones 7-9';
    case 'all_rewards'
        label = 'Rewards';
    otherwise
        label = strrep(tone_tag, '_', ' ');
end
end

function order = toneTagSortOrder(tone_tag)
% SV 9/9/26: "all" reads FIRST per the hand-drawn spec (all, 1-3, 4-6,
% 7-9), not last.
switch tone_tag
    case 'all_tones'
        order = 1;
    case 'tones_1_2_3'
        order = 2;
    case 'tones_4_5_6'
        order = 3;
    case 'tones_7_8_9'
        order = 4;
    otherwise
        order = 5;
end
end

function run = findRun(run_list, row_key, tone_tag, behavior)
% Locates the one run (if any) in run_list matching this grid cell's
% row/column - [] if that combination was never run for this group.
run = [];
for i = 1:numel(run_list)
    r = run_list(i);
    if ~strcmp(r.tone_tag, tone_tag)
        continue;
    end
    if ~strcmp(rowKeyForBehavior(behavior, r.params), row_key)
        continue;
    end
    run = r;
    return;
end
end

function c = groupColor(group, channel)
% SV 9/9/26: Sham is always gray, regardless of channel. TMS's color
% reflects the CHANNEL being shown (green for 465/Pv, red for 560/Sst,
% via channelColor) - this is what lets the same "TMS vs Sham" panel
% design extend to the planned 560-channel report set later without a
% new color scheme: only the channel argument changes.
% SV 9/28/26: now the user-picked series color for (group, channel) - see
% seriesColor/defaultReportColors (DCSP: TMS GFP yellow, TMS RFP orange,
% Sham grey) - instead of the fixed green/red/grey.
if nargin < 2 || isempty(channel)
    channel = 'pv';
end
switch lower(group)
    case {'tms', 'sham'}
        c = seriesColor(group, channel);
    otherwise
        c = struct('line', [0.3 0.3 0.3], 'area', [0.8 0.8 0.8]);
end
end

function [colors, names, styles] = markerPalette()
% Distinct colors (AND, per user's request, distinct dotted/dashed line
% styles) for marking each condition_label's trial events on the QC
% raw-trace page (e.g. platform_entry vs platform_exit) - so entries and
% exits can be told apart, and individually counted, by eye even without
% relying on color alone. Cycles if a behavior ever has more than 4
% condition labels, which none of the 4 known behaviors do.
colors = {[0.20 0.40 0.90], [0.60 0.20 0.70], [0.90 0.50 0.10], [0.10 0.60 0.60]};
names = {'Blue', 'Purple', 'Orange', 'Teal'};
styles = {':', '--', '-.', '-'};
end

function [data, n] = loadGroupTraces(run_entry, channel, condition_label, require_channel)
% One row per animal's mean_trace for the given channel ('pv' or 'sst').
%
% SV 9/28/26: require_channel (optional, e.g. 'sst' when loading 'pv') -
% for the within-group GFP-vs-RFP comparison, only animals that ALSO have
% valid data in require_channel are kept, so both sides of that paired
% comparison are built from exactly the same animals, in the same order.
%
% SV 9/9/26 (v2, corrected same day): each animal's trace length is
% checked against what IT should be - (TRANGE_pre+TRANGE_post) seconds
% at THAT animal's own saved photometry sample rate
% (animal_result.signals.fs) - not against what OTHER animals in the
% same group happened to produce. A first version compared animals to
% each other (excluding whichever length was in the minority), but real
% output showed that fails when MORE than half a group's animals have a
% degenerate short trace (e.g. a platform bout very close to the end of
% the session, truncated by calc_zall) - majority vote then picked the
% broken length as "typical" and excluded the one good animal instead.
% Comparing each animal to its own theoretical expectation is robust to
% that regardless of how many animals in the group are affected. Traces
% under half the expected length are excluded and logged (not silently
% averaged in or silently dropped); animals without a saved sample rate
% (old data predating that field) fall back to the previous behavior
% (kept as-is, deferring to appendTraceMatrix's own length handling).
if nargin < 4
    require_channel = '';
end
data = [];
n = 0;
if isempty(run_entry)
    return;
end

trange_total = run_entry.params.TRANGE_pre + run_entry.params.TRANGE_post;

for i = 1:numel(run_entry.animals)
    animal_file = run_entry.animals(i).save_file;
    if ~isfile(animal_file), continue; end
    ar = animalResultCache(animal_file); % SV 9/28/26: cached, see animalResultCache
    if ~isfield(ar.analysis, channel) || ~isfield(ar.analysis.(channel), condition_label)
        continue;
    end
    entry = ar.analysis.(channel).(condition_label);
    if isempty(entry.trial_matrix)
        continue;
    end
    if isDegenerateTraceEntry(ar, entry, trange_total, channel, condition_label, 'loadGroupTraces')
        continue;
    end
    if ~isempty(require_channel) && ~hasValidChannelData(ar, require_channel, condition_label, trange_total, false)
        continue;
    end
    trace = entry.mean_trace(:)';
    data = appendTraceMatrix(data, trace);
end
n = size(data, 1);

end

function total_trials = loadGroupTotalTrials(run_entry, channel, condition_label, require_channel)
% Sums each qualifying animal's own trial count (trial_matrix rows) for
% one condition within a group's run - the SAME per-animal
% inclusion/exclusion rule as loadGroupTraces (isDegenerateTraceEntry), so
% this total lines up with exactly the animals whose mean traces make up
% the group average shown alongside it. Used for the "N=<subjects>,
% n=<total trials>" label format (see makeSeriesLabel) - N is the animal
% count loadGroupTraces/loadGroupAUCValues already return; this is the
% separate total-trial count reported alongside it, per user's request.
% SV 9/28/26: require_channel (optional) - same meaning as in
% loadGroupTraces.
if nargin < 4
    require_channel = '';
end
total_trials = 0;
if isempty(run_entry)
    return;
end
trange_total = run_entry.params.TRANGE_pre + run_entry.params.TRANGE_post;
for i = 1:numel(run_entry.animals)
    animal_file = run_entry.animals(i).save_file;
    if ~isfile(animal_file), continue; end
    ar = animalResultCache(animal_file); % SV 9/28/26: cached, see animalResultCache
    if ~isfield(ar.analysis, channel) || ~isfield(ar.analysis.(channel), condition_label)
        continue;
    end
    entry = ar.analysis.(channel).(condition_label);
    if isempty(entry.trial_matrix)
        continue;
    end
    if isDegenerateTraceEntry(ar, entry, trange_total, channel, condition_label, 'loadGroupTotalTrials')
        continue;
    end
    if ~isempty(require_channel) && ~hasValidChannelData(ar, require_channel, condition_label, trange_total, false)
        continue;
    end
    total_trials = total_trials + size(entry.trial_matrix, 1);
end
end

function tf = isDegenerateTraceEntry(ar, entry, trange_total, channel, condition_label, caller_name)
% SV 9/9/26: shared by loadGroupTraces and loadGroupAUCValues - a trial
% window can collapse to just 1-2 samples (calc_zall sizes EVERY trial in
% a condition to the SHORTEST one, so a single trial near a session
% boundary can silently truncate the whole animal's average for that
% condition down to almost nothing - a known pre-existing data-quality
% edge case, not something this report layer can correct). That
% collapse corrupts mean_trace AND the AUC computed from the same
% degenerate trial_matrix, so both loaders need to exclude it the same
% way rather than only the trace ever being filtered while a
% meaningless AUC value silently rode along into the AUC statistics.
%
% SV 9/28/26: an empty caller_name means "quiet" - no warning. Used by
% hasValidChannelData, which re-checks the OTHER channel of a GFP-vs-RFP
% pair; that channel's own loader already warns about it once.
quiet = isempty(caller_name);
tf = false;
trace_len = numel(entry.mean_trace);
if isfield(ar, 'signals') && isfield(ar.signals, 'fs') && ~isempty(ar.signals.fs) && ar.signals.fs > 0
    expected_len = trange_total * ar.signals.fs;
    if trace_len < 0.5 * expected_len
        if ~quiet
            warning('%s: excluding %s (trace has %d samples, expected ~%.0f for a %g s window at %.2f Hz) from the group average for %s/%s.', ...
                caller_name, ar.mouse, trace_len, expected_len, trange_total, ar.signals.fs, channel, condition_label);
        end
        tf = true;
        return;
    end
end

% SV 9/9/26 (bugfix): a trial whose BASELINE window collapses to a
% constant/near-constant signal (std = 0 - the same window-collapse
% mechanism noted above, applied to the baseline instead of the whole
% trial) makes calc_zall's z-score divide by zero, injecting actual +-Inf
% into that trial's row of the trial_matrix. mean() does not ignore Inf
% the way 'omitnan' ignores NaN, so a SINGLE such trial poisons the
% animal's entire mean_trace at every sample where that trial was Inf -
% this was rendering as invisible/"floating dot" traces and NaN AUC
% (Inf-Inf or mean-of-Inf) even though the trace LENGTH looked
% completely normal, so the length check above never caught it.
if any(~isfinite(entry.mean_trace))
    if ~quiet
        warning('%s: excluding %s (mean trace contains non-finite values - a trial''s baseline window likely had zero variance, causing a divide-by-zero in z-scoring) from the group average for %s/%s.', ...
            caller_name, ar.mouse, channel, condition_label);
    end
    tf = true;
end
end

function tf = hasValidChannelData(ar, channel, condition_label, trange_total, need_auc)
% SV 9/28/26: true if this animal has usable data for condition_label in
% the given channel - the same inclusion rule the group loaders apply
% (non-empty trial_matrix, not degenerate, and, if need_auc, a finite
% per-animal AUC). Used to restrict a GFP-vs-RFP (465-vs-560) comparison
% to animals that are valid in BOTH channels, so the paired test compares
% each animal against itself.
tf = false;
if ~isfield(ar, 'analysis') || ~isfield(ar.analysis, channel) || ~isfield(ar.analysis.(channel), condition_label)
    return;
end
entry = ar.analysis.(channel).(condition_label);
if isempty(entry.trial_matrix)
    return;
end
if isDegenerateTraceEntry(ar, entry, trange_total, channel, condition_label, '')
    return;
end
if need_auc && (~isfield(entry, 'auc') || ~isfinite(entry.auc.mean_of_trials))
    return;
end
tf = true;
end

function vals = loadGroupAUCValues(run_entry, channel, condition_label, require_channel)
% SV 9/9/26 (bugfix): now applies the same degenerate-trial-window
% exclusion as loadGroupTraces (see isDegenerateTraceEntry) - AUC values
% computed from a collapsed 1-2 sample trial_matrix are scientifically
% meaningless in the exact same way the trace itself is, and used to
% flow straight into the AUC grid page / stats page unfiltered even
% after the trace-level fix excluded that same animal from the trace
% grid, silently corrupting group AUC comparisons with a few near-zero
% garbage values.
%
% SV 9/28/26: require_channel (optional) - same meaning as in
% loadGroupTraces; here the other channel must also have a finite AUC,
% so both sides of a paired GFP-vs-RFP test line up animal for animal.
if nargin < 4
    require_channel = '';
end
vals = [];
if isempty(run_entry)
    return;
end
trange_total = run_entry.params.TRANGE_pre + run_entry.params.TRANGE_post;
for i = 1:numel(run_entry.animals)
    animal_file = run_entry.animals(i).save_file;
    if ~isfile(animal_file), continue; end
    ar = animalResultCache(animal_file); % SV 9/28/26: cached, see animalResultCache
    if ~isfield(ar.analysis, channel) || ~isfield(ar.analysis.(channel), condition_label)
        continue;
    end
    entry = ar.analysis.(channel).(condition_label);
    if isempty(entry.trial_matrix) || ~isfield(entry, 'auc')
        continue;
    end
    if isDegenerateTraceEntry(ar, entry, trange_total, channel, condition_label, 'loadGroupAUCValues')
        continue;
    end
    if ~isfinite(entry.auc.mean_of_trials)
        % Belt-and-suspenders: isDegenerateTraceEntry already excludes
        % non-finite mean_trace values (the usual cause), but the AUC is
        % computed from the underlying trial_matrix independently, so
        % skip a non-finite AUC directly too rather than assume it can
        % never happen any other way.
        continue;
    end
    if ~isempty(require_channel) && ~hasValidChannelData(ar, require_channel, condition_label, trange_total, true)
        continue;
    end
    vals(end+1) = entry.auc.mean_of_trials; %#ok<AGROW>
end
end

function [trial_matrix, mouse_found] = loadSingleAnimalTrialMatrix(run_entry, mouse_name, channel, condition_label)
% Trial-level data (not the animal's already-averaged mean_trace) for one
% specific animal - used by the QC page's per-animal drill-down panel, so
% that panel can show trial-to-trial SEM for just this one animal.
trial_matrix = [];
mouse_found = false;
if isempty(run_entry)
    return;
end
for i = 1:numel(run_entry.animals)
    if ~strcmp(run_entry.animals(i).mouse, mouse_name)
        continue;
    end
    animal_file = run_entry.animals(i).save_file;
    if ~isfile(animal_file)
        return;
    end
    ar = animalResultCache(animal_file); % SV 9/28/26: cached, see animalResultCache
    mouse_found = true;
    if ~isfield(ar.analysis, channel) || ~isfield(ar.analysis.(channel), condition_label)
        return;
    end
    entry = ar.analysis.(channel).(condition_label);
    if isempty(entry.trial_matrix)
        return;
    end
    % SV 9/9/26 (bugfix): only excludes genuinely BROKEN (non-finite,
    % Inf-poisoned - see isDegenerateTraceEntry) trials here, NOT merely
    % "shorter than the group's usual window" the way
    % loadGroupTraces/loadGroupAUCValues do. That length check exists to
    % stop one truncated animal from silently shrinking a GROUP average
    % window for everyone else - it doesn't apply to a single animal's
    % own drill-down view, which has no one else's window to protect and
    % where showing a shorter-but-real trial average is far more useful
    % than showing nothing (this was hiding a Sham animal's own trace
    % entirely - visible platform entries/exits in its raw trace, but its
    % drill-down panel showed only the opposite group's reference,
    % looking exactly like a missing/wrong-colored trace).
    if any(~isfinite(entry.mean_trace))
        warning('loadSingleAnimalTrialMatrix: excluding %s (mean trace contains non-finite values) for %s/%s.', ...
            ar.mouse, channel, condition_label);
        return;
    end
    trial_matrix = entry.trial_matrix;
    return;
end
end

function run = pickAnyRun(run_list)
if isempty(run_list)
    run = [];
else
    run = run_list(1);
end
end

function run = pickBestRun(run_list)
% SV 9/9/26: like pickAnyRun, but picks whichever run (epoch/tone-bin
% variant) has the MOST successfully-processed animals, instead of just
% the first one scanned - used wherever the QC page needs ONE
% representative run for a group (the per-animal drill-down reference),
% so that representative run covers as much of the cohort as possible
% rather than an arbitrary, possibly animal-sparse, variant.
run = [];
if isempty(run_list)
    return;
end
best_n = -1;
for i = 1:numel(run_list)
    if run_list(i).n_animals > best_n
        best_n = run_list(i).n_animals;
        run = run_list(i);
    end
end
end

function run = pickBestRunForCondition(run_list, behavior, base_label, channel)
% SV 9/9/26 (bugfix): pickBestRun's "most animals" score is for the run
% as a WHOLE (however many animals succeeded at all, across every
% condition it saved) - a run can score well on that while still being
% empty/degenerate for one SPECIFIC condition (e.g. very few real
% platform-entry trials happen during an "inter_tone_interval" epoch run
% even if that run otherwise processed every animal fine). When multiple
% runs tied on overall animal count, pickBestRun had no way to prefer the
% one that's actually good for the condition being drawn, which is why a
% Sham animal's drill-down panel could come up with NO valid own-trace
% (own_n = 0, so only the TMS reference trace showed - easy to misread
% as "the sham trace is green"). This instead resolves each candidate
% run's field for base_label and scores it by how many animals actually
% have real, non-degenerate data for THAT exact field
% (loadGroupTraces already carries that exclusion logic).
% SV 9/28/26: channel (optional, default 'pv') - scored on whichever
% channel the QC page is drawing (465 or 560).
if nargin < 4 || isempty(channel)
    channel = 'pv';
end
run = [];
best_score = -1;
for i = 1:numel(run_list)
    r = run_list(i);
    field = resolveConditionField(behavior, base_label, r.params);
    [~, n] = loadGroupTraces(r, channel, field);
    if n > best_score
        best_score = n;
        run = r;
    end
end
if isempty(run)
    run = pickBestRun(run_list);
end
end

function entries = animalListFromRun(run_entry)
entries = struct('file', {}, 'mouse', {}, 'group', {});
if isempty(run_entry)
    return;
end
grp = splitGroupAndDayKey(run_entry.day_folder);
for i = 1:numel(run_entry.animals)
    idx = numel(entries) + 1;
    entries(idx).file = run_entry.animals(i).save_file;
    entries(idx).mouse = run_entry.animals(i).mouse;
    entries(idx).group = grp;
end
end

function entries = unionAnimalListFromRuns(run_list)
% SV 9/9/26 (bugfix): the QC page used to list only the animals present
% in ONE arbitrarily-picked run (pickAnyRun) - since different epoch/
% tone-bin variant runs can have different animals succeed or fail (a
% per-animal, per-variant thing), that silently dropped animals from the
% QC page's roster whenever the picked run happened not to be the one
% where they succeeded (e.g. only 4 of 6 animals shown). This instead
% takes the UNION of animals across every run in the group - the raw
% signal/tone-onsets used to draw each animal's row are identical
% regardless of which run's saved file they're read from (same session,
% just windowed differently downstream), so any one run containing that
% animal is a valid source for it.
entries = struct('file', {}, 'mouse', {}, 'group', {});
seen = {};
for r = 1:numel(run_list)
    run_entry = run_list(r);
    grp = splitGroupAndDayKey(run_entry.day_folder);
    for i = 1:numel(run_entry.animals)
        mouse = run_entry.animals(i).mouse;
        if any(strcmp(seen, mouse))
            continue;
        end
        seen{end+1} = mouse; %#ok<AGROW>
        idx = numel(entries) + 1;
        entries(idx).file = run_entry.animals(i).save_file;
        entries(idx).mouse = mouse;
        entries(idx).group = grp;
    end
end
end

function [data, n, label, color, auc_vals] = loadRunSeries(run_entry, channel, condition_label, label, color) %#ok<INUSD>
[data, n] = loadGroupTraces(run_entry, channel, condition_label);
auc_vals = loadGroupAUCValues(run_entry, channel, condition_label);
end

function [vals, label, color] = loadRunAUCSeries(run_entry, channel, condition_label, label, color) %#ok<INUSD>
vals = loadGroupAUCValues(run_entry, channel, condition_label);
end

function bases = canonicalBaseLabels(behavior)
% SV 9/9/26: the small, STABLE set of base condition labels per behavior
% - unlike the raw saved field names under ar.analysis.pv (which are
% these bases plus an epoch/tone-bin suffix that varies per run, see
% resolveConditionField), these are the same across every row/col of a
% report grid, so they're what the grid's per-condition PDF pages should
% iterate over. Must match the eventA_label/eventB_label base strings
% passed into make*AwareLabel() in getBehaviorEventData (or the bare
% 'reward' label for the reward behavior, which has no such wrapper).
switch behavior
    case 'platform_entry_exit'
        bases = {'platform_entry', 'platform_exit'};
    case 'tone_on_vs_off_platform'
        bases = {'tone_on_platform', 'tone_off_platform'};
    case 'tone_shock_vs_noshock'
        bases = {'tone_shock', 'tone_noshock'};
    case 'reward'
        bases = {'reward'};
    otherwise
        bases = {};
end
end

function field = resolveConditionField(behavior, base_label, run_params)
% Reconstructs the EXACT field name under ar.analysis.pv/.sst that a run
% with these params would have saved a given base condition label as -
% by calling the very same make*AwareLabel helper used when the field was
% originally created (see getBehaviorEventData), so this can never drift
% out of sync with however that naming scheme evolves.
switch behavior
    case 'platform_entry_exit'
        field = makePlatformEpochAwareLabel(base_label, run_params);
    case 'tone_on_vs_off_platform'
        field = makeTonePlatformShockAwareLabel(base_label, run_params);
    case 'tone_shock_vs_noshock'
        field = makeToneAwareLabel(base_label, run_params);
    case 'reward'
        field = base_label;
    otherwise
        field = base_label;
end
end

function [data, n, label, color, auc_vals, n_trials] = loadRunSeriesByBase(run_entry, behavior, channel, base_label, label, color, require_channel) %#ok<INUSD>
% Like loadRunSeries, but takes a canonical base_label and resolves it to
% this specific run's actual saved field name first - see
% resolveConditionField for why that resolution can't be skipped.
%
% n_trials (per user's request): total behavior-trial count summed across
% the n subjects, alongside the animal count n - see makeSeriesLabel.
%
% SV 9/28/26: require_channel (optional) - passed through to the group
% loaders; see loadGroupTraces.
if nargin < 7
    require_channel = '';
end
data = [];
n = 0;
auc_vals = [];
n_trials = 0;
if isempty(run_entry)
    return;
end
field = resolveConditionField(behavior, base_label, run_entry.params);
[data, n] = loadGroupTraces(run_entry, channel, field, require_channel);
auc_vals = loadGroupAUCValues(run_entry, channel, field, require_channel);
n_trials = loadGroupTotalTrials(run_entry, channel, field, require_channel);
end

function [vals, label, color, n_trials] = loadRunAUCSeriesByBase(run_entry, behavior, channel, base_label, label, color, require_channel) %#ok<INUSD>
if nargin < 7
    require_channel = '';
end
vals = [];
n_trials = 0;
if isempty(run_entry)
    return;
end
field = resolveConditionField(behavior, base_label, run_entry.params);
vals = loadGroupAUCValues(run_entry, channel, field, require_channel);
n_trials = loadGroupTotalTrials(run_entry, channel, field, require_channel);
end

function s = ternaryStr(cond, a, b)
if cond
    s = a;
else
    s = b;
end
end

function label = makeSeriesLabel(base_label, n_subjects, n_trials)
% SV 9/9/26 (per user's request): "TMS (N=3, n=17)" - N = number of
% subjects (animals) the group mean is averaged over, n = the total
% number of behavior trials (summed across those subjects) that went
% into it - distinct numbers that were previously both just labeled "n",
% which conflated "how many animals" with "how many trials". n_trials is
% optional (empty/NaN) for callers with no group-vs-trial distinction
% (e.g. the QC page's single-animal drill-down panel, where n already
% unambiguously means that one animal's own trial count) - falls back to
% the plain "(n=X)" form there.
if isempty(n_trials) || isnan(n_trials)
    label = sprintf('%s (n=%d)', base_label, n_subjects);
else
    label = sprintf('%s (N=%d, n=%d)', base_label, n_subjects, n_trials);
end
end

function [legend_tex, mean_rng] = plotTwoTraceOverlayPanel(ax, dataA, nA, labelA, colorA, dataB, nB, labelB, colorB, event_lines, xlim_vals, ref_params, aucA, aucB, show_auc_bar, nA_trials, nB_trials, event_line_color, event_line_style) %#ok<INUSD>
% SV 10/1/26 (per user's picks from the style previews): this now draws
% the traces and event lines ONLY. It no longer sets its own y-limits or
% draws the Baseline/AUC bars - every panel of a row gets the SAME
% y-axis, ending on labeled ticks (applyRowAxes, called by the caller once
% the whole row is drawn), and the bars sit just above that shared
% x-axis. mean_rng returns [min max] of the smoothed group mean +/- SEM
% drawn here, which is what sets the row's y-range (faint individual
% traces may run past it and are clipped). show_auc_bar is now read by
% applyRowAxes instead. Mean line 0.6 and event lines 0.45 wide (were
% 1.1 / 0.9).
% One grid cell: series A vs series B mean +/- SEM overlaid, individual-
% row thin lines, the aligned-event dashed line, and Baseline/AUC-window
% bars beneath - generic over what A and B actually are (TMS vs Sham
% today; a channel or a single animal vs a group reference elsewhere in
% this file).
%
% SV 9/9/26 (bugfix): per user's clarification, the earlier "inline
% Label (n=X) text at the end of each trace" design is GONE - those
% labels cluttered the right edge of the plotted data. This function now
% returns legend_tex (a TeX-formatted, per-series-colored string, e.g.
% '\color[rgb]{...}TMS (N=3, n=7)   \color[rgb]{...}Sham (N=3, n=27)')
% instead of drawing it - the CALLER combines it with the panel's own
% title as a second, smaller title line directly underneath (see
% writeTraceGridPage/writeGroupQCPage's use of texEscape below), which is
% what "second line under the title" actually meant.
%
% aucA/aucB (optional, trailing) are per-animal AUC value vectors for the
% small in-panel AUC dot-plot inset (per user's hand-drawn spec and
% reference figure) - omitted entirely (no inset drawn) by callers that
% don't have AUC values handy, e.g. the QC page's per-animal drill-down
% panels.
%
% show_auc_bar (optional, trailing, default true) - SV 9/9/26 (per user's
% request): the QC page's per-animal drill-down panels don't compute AUC
% at all, so the AUC window bar/label doesn't apply there and is now
% suppressed for those calls; the Baseline bar is unaffected (still a
% meaningful window regardless of whether AUC is being reported).
if nargin < 13, aucA = []; end
if nargin < 14, aucB = []; end
if nargin < 15, show_auc_bar = true; end
if nargin < 16, nA_trials = []; end
if nargin < 17, nB_trials = []; end
% SV 9/9/26 (per user's request): the aligned-event line (t=0) is
% colored/styled to match the SAME condition's marker on the raw-trace QC
% panel (blue dotted for platform_entry, purple dashed for
% platform_exit, via markerPalette) when the caller has a specific
% condition in mind (plotAnimalOwnTracePanel) - defaults to the original
% plain gray dashed line for callers comparing two different conditions
% at once (the main TMS-vs-Sham grid), where t=0 isn't tied to one single
% colored condition.
if nargin < 18 || isempty(event_line_color), event_line_color = [0.6 0.6 0.6]; end
if nargin < 19 || isempty(event_line_style), event_line_style = '--'; end
legend_tex = '';
mean_rng = [Inf -Inf];
hold(ax, 'on');

if isempty(dataA) && isempty(dataB)
    text(ax, 0.5, 0.5, 'No data', 'Units', 'normalized', 'HorizontalAlignment', 'center', 'Color', [0.6 0.6 0.6]);
    axis(ax, 'off');
    return;
end

smooth_window = 25;
legend_parts = {};

if ~isempty(dataA)
    x_axis = linspace(-ref_params.TRANGE_pre, ref_params.TRANGE_post, size(dataA, 2));
    data = smoothTraceMatrix(dataA, smooth_window);
    [x_axis, data] = thinSmoothedTraces(x_axis, data);
    for i = 1:size(data, 1)
        plot(ax, x_axis, data(i,:), 'Color', [colorA.line 0.12], 'LineWidth', 0.3, 'HandleVisibility', 'off');
    end
    plotShadedMeanWithHandle(data, x_axis, colorA.area, colorA.line, 0.30, 0.6, ax);
    mean_rng = meanSemExtent(mean_rng, data);
    legend_parts(end+1,:) = {makeSeriesLabel(labelA, nA, nA_trials), colorA.line}; %#ok<AGROW>
end

if ~isempty(dataB)
    x_axis = linspace(-ref_params.TRANGE_pre, ref_params.TRANGE_post, size(dataB, 2));
    data = smoothTraceMatrix(dataB, smooth_window);
    [x_axis, data] = thinSmoothedTraces(x_axis, data);
    for i = 1:size(data, 1)
        plot(ax, x_axis, data(i,:), 'Color', [colorB.line 0.12], 'LineWidth', 0.3, 'HandleVisibility', 'off');
    end
    plotShadedMeanWithHandle(data, x_axis, colorB.area, colorB.line, 0.30, 0.6, ax);
    mean_rng = meanSemExtent(mean_rng, data);
    legend_parts(end+1,:) = {makeSeriesLabel(labelB, nB, nB_trials), colorB.line}; %#ok<AGROW>
end

legend_str_parts = cell(1, size(legend_parts, 1));
for k = 1:size(legend_parts, 1)
    c = legend_parts{k, 2};
    legend_str_parts{k} = sprintf('\\color[rgb]{%.3f,%.3f,%.3f}%s', c(1), c(2), c(3), legend_parts{k,1});
end
legend_tex = strjoin(legend_str_parts, '   ');

for k = 1:numel(event_lines)
    xline(ax, event_lines(k), event_line_style, 'Color', event_line_color, 'LineWidth', 0.45, 'HandleVisibility', 'off');
end
if ~isempty(xlim_vals)
    xlim(ax, xlim_vals);
end

% (Baseline/AUC bars and the y-axis: see applyRowAxes.)

box(ax, 'off');
set(ax, 'TickDir', 'out', 'FontSize', 8);
xlabel(ax, 'Time (s)');
ylabel(ax, 'z-score');

% SV 9/9/26 (bugfix, third pass): the AUC inset is NO LONGER drawn here.
% It used to be positioned in THIS panel's own data coordinates at THIS
% point in time - but writeTraceGridPage's row-wide Y-axis span matching
% (matchYAxesAcrossPanels) runs AFTER every panel in the row has been
% plotted, and for any panel that isn't the row's own widest-span one,
% that stretches its ylim taller - moving the real top-right corner
% somewhere the inset was never anchored to, since the inset had already
% been drawn against the panel's OWN pre-stretch range. The inset is now
% drawn by the caller in a second pass, after matchYAxesAcrossPanels has
% set every panel's FINAL limits (see writeTraceGridPage) - see
% drawAUCInset for why it's still plotted directly in the host ax's own
% data coordinates rather than a separate axes.

end

function rng = meanSemExtent(rng, data)
% Widens rng ([min max]) to cover the group mean +/- SEM of data's rows -
% the quantity that sets a report row's y-range (SV 10/1/26, option Y2).
m = mean(data, 1, 'omitnan');
n = sum(~isnan(data), 1);
n(n == 0) = NaN;
e = std(data, 0, 1, 'omitnan') ./ sqrt(n);
e(~isfinite(e)) = 0;
lo = min(m - e);
hi = max(m + e);
if isfinite(lo), rng(1) = min(rng(1), lo); end
if isfinite(hi), rng(2) = max(rng(2), hi); end
end

function applyRowAxes(axs, rng, ref_params, show_auc_bar, is_small)
% SV 10/1/26 (per user's rules, chosen from the axis previews): every
% panel of one row - the all-tones aggregate and its tone bins, i.e. the
% same data - gets IDENTICAL y-limits and ticks; both ends of every axis
% (y and x) sit on a labeled tick; the y-range is set by the group
% mean +/- SEM (rng, from plotTwoTraceOverlayPanel's mean_rng) so the
% responses fill the panel, and faint individual traces beyond it are
% clipped at the edge; the Baseline and AUC-window bars sit just above
% the x-axis. ref_params: one params struct per axes (cell), for the
% window and bar positions. is_small: logical per axes (tone-bin panels
% thin their x labels).
if isempty(axs)
    return;
end
if ~all(isfinite(rng)) || rng(2) <= rng(1)
    rng = [-1 1];
end
[lo, hi, step, bar_y] = rowYAxisLimits(rng);
for i = 1:numel(axs)
    ax = axs(i);
    p = ref_params{i};
    set(ax, 'YLim', [lo hi], 'YTick', lo:step:hi, 'Clipping', 'on');
    if isfield(p, 'BASELINE_PER') && ~isempty(p.BASELINE_PER)
        drawAnnotationBar(ax, -p.TRANGE_pre + p.BASELINE_PER, bar_y, [0.5 0.5 0.5], 'Baseline');
    end
    if show_auc_bar && isfield(p, 'AUC_RANGE') && ~isempty(p.AUC_RANGE)
        drawAnnotationBar(ax, p.AUC_RANGE, bar_y, [0.5 0.5 0.5], 'AUC');
    end
    setXTicksOnEnds(ax, [-p.TRANGE_pre, p.TRANGE_post], is_small(i));
end
end

function [lo, hi, step, bar_y] = rowYAxisLimits(rng)
% Y-limits on a 1/2/5 x 10^k tick grid (~4 increments): the floor is the
% first tick at or below the lowest value, dropped one more tick only if
% that leaves too little room for the Baseline/AUC bars, which go just
% above the floor.
span = max(rng(2) - rng(1), eps);
step = niceStep(span / 4);
lo = floor(rng(1) / step) * step;
if rng(1) - lo < 0.3 * step
    lo = lo - step;
end
hi = ceil(rng(2) / step) * step;
if hi <= lo
    hi = lo + step;
end
bar_y = lo + 0.1 * step;
end

function s = niceStep(v)
% Smallest of 1, 2, 5 x 10^k that is >= v.
if ~(v > 0)
    s = 1;
    return;
end
p = 10^floor(log10(v));
s = 10 * p;
for m = [1 2 5]
    if m * p >= v
        s = m * p;
        return;
    end
end
end

function s = niceStep25(v)
% Smallest of 1, 2, 2.5, 5 x 10^k that is >= v (allows 25, 250 ...).
if ~(v > 0)
    s = 1;
    return;
end
p = 10^floor(log10(v));
s = 10 * p;
for m = [1 2 2.5 5]
    if m * p >= v
        s = m * p;
        return;
    end
end
end

function setXTicksOnEnds(ax, xl, is_small)
% X ticks every 10 s with both window ends labeled (SV 10/1/26: every axis
% starts and ends on a labeled tick). On small panels with a long window
% only -10/start, 0, every 20 s and the end are labeled, so they don't
% crowd.
xlim(ax, xl);
ticks = xl(1):10:xl(2);
if ticks(end) ~= xl(2)
    ticks(end+1) = xl(2);
end
labels = arrayfun(@(t) sprintf('%g', t), ticks, 'UniformOutput', false);
if is_small && diff(xl) > 40
    keep = (mod(ticks, 20) == 0) | ticks == xl(1) | ticks == xl(2);
    labels(~keep) = {''};
end
set(ax, 'XTick', ticks, 'XTickLabel', labels);
end

function R = insetRowRange(vals)
% SV 10/1/26: the ONE integer range every AUC inset in a row shares (same
% data as total + bins -> same scale): includes 0, 3-4 increments from a
% 1/2/2.5/5 x 10^k step; all ticks labeled when there are at most 4,
% otherwise only the two ends and 0.
vals = vals(isfinite(vals));
lo = min([vals(:); 0]);
hi = max([vals(:); 0]);
step = max(niceStep25(max(hi - lo, 1) / 4), 1);
lo = floor(lo / step) * step;
hi = ceil(hi / step) * step;
if hi <= lo
    hi = lo + step;
end
ticks = lo:step:hi;
if numel(ticks) <= 4
    labeled = true(size(ticks));
else
    labeled = ticks == lo | ticks == hi | ticks == 0;
end
R = struct('lo', lo, 'hi', hi, 'ticks', ticks, 'labeled', labeled);
end

function vals = insetValues(v)
% The values an AUC inset must fit: every dot plus the mean +/- SEM ends.
v = v(isfinite(v));
vals = v(:);
if ~isempty(v)
    se = std(v) / sqrt(numel(v));
    if ~isfinite(se), se = 0; end
    vals = [vals; mean(v) - se; mean(v) + se];
end
end

function label = condLabelDisplayName(cond)
% Human-readable "Platform Entry" / "Tone On Platform" style name for a
% canonical base condition label (see canonicalBaseLabels) - used to
% prefix grid panel titles so a reader can tell which condition a panel
% shows without having to go back to the page title.
switch cond
    case 'tone_noshock'
        label = 'Tone No Shock';
    otherwise
        words = strsplit(cond, '_');
        words = cellfun(@(w) [upper(w(1)) w(2:end)], words, 'UniformOutput', false);
        label = strjoin(words, ' ');
end
end

function tf = isToneOnOffPlatformCond(cond)
% SV 9/9/26: tone_on_platform/tone_off_platform get their own dedicated
% "On-Platform Tone Onset 1-9 (all)" title wording (per user's request),
% distinct from every other condition's generic makeGridPanelTitle
% format (e.g. platform_entry/exit's "Platform Entry for ITI 1-3").
tf = strcmpi(cond, 'tone_on_platform') || strcmpi(cond, 'tone_off_platform');
end

function word = toneOnOffWord(cond)
% 'On' for tone_on_platform, 'Off' for tone_off_platform - only call this
% after isToneOnOffPlatformCond(cond) confirms cond is one of the two.
if strcmpi(cond, 'tone_on_platform')
    word = 'On';
else
    word = 'Off';
end
end

function parts = toneOnsetPanelTitleParts(onoff, row_label, col_label)
% Builds the {before, after} split for the tone-onset title format (per
% user's 9/9/26 request): trace-grid panels join them with a space into
% one line ("On-Platform Tone Onset 1-9 (all)" / "Off-Platform Tone
% Onset 4-6"); the AUC grid prefixes "AUC: " onto `before` and puts
% `after` on its own line beneath it, matching how the generic
% makeGridPanelTitle-based pages split at " for ".
%
% col_label already reads "Tones 1-9 (all)"/"Tones 1-3"/etc (see
% toneTagDisplayLabel) - strip the leading "Tones " so the numeric range
% follows directly after "Tone Onset". row_label is "All Trials" for the
% common case and is dropped there (redundant/uninteresting default),
% but kept as a leading qualifier for the Shocked/No-Shock shock-outcome
% filter rows so that real information isn't silently lost when a page
% has more than the default single row.
range_label = col_label;
if startsWith(range_label, 'Tones ', 'IgnoreCase', true)
    range_label = range_label(numel('Tones ')+1:end);
end
before = sprintf('%s-Platform', onoff);
if ~isempty(row_label) && ~strcmpi(row_label, 'All Trials')
    before = sprintf('%s %s', row_label, before);
end
after = sprintf('Tone Onset %s', range_label);
parts = {before, after};
end

function tf = isShockNoShockCond(cond)
% SV 9/9/26: tone_shock/tone_noshock get their own dedicated "Shocked
% during Tones 1-9 (all)" / "Not-Shocked during Tones 4-6" title wording
% (per user's request), distinct from every other condition's generic
% makeGridPanelTitle format.
tf = strcmpi(cond, 'tone_shock') || strcmpi(cond, 'tone_noshock');
end

function word = shockedWord(cond)
% 'Shocked' for tone_shock, 'Not-Shocked' for tone_noshock - only call
% this after isShockNoShockCond(cond) confirms cond is one of the two.
if strcmpi(cond, 'tone_shock')
    word = 'Shocked';
else
    word = 'Not-Shocked';
end
end

function parts = shockOutcomePanelTitleParts(word, row_label, col_label)
% Builds the {before, after} split for the "Shocked during Tones 1-9
% (all)" / "Not-Shocked during Tones 4-6" title format (per user's
% 9/9/26 request), used by tone_shock/tone_noshock panels. Unlike
% toneOnsetPanelTitleParts, the "Tones " prefix on col_label is KEPT
% here (col_label already reads "Tones 1-9 (all)"/"Tones 4-6"/etc, see
% toneTagDisplayLabel) - the user's own example keeps it ("during Tones
% 1-9 (all)", not "during 1-9 (all)"). row_label is always empty for
% tone_shock_vs_noshock (its single row - see rowKeyDisplayLabel) but is
% prepended defensively if ever non-empty, so no information is silently
% dropped.
before = word;
if ~isempty(row_label)
    before = sprintf('%s %s', row_label, word);
end
after = sprintf('during %s', col_label);
parts = {before, after};
end

function id = shortAnimalID(mouse_name)
% Extracts just the subject ID (e.g. "PVFP_28") from the full folder-name
% mouse identifier (e.g. "PVFP_28_tms_Retr_SV_Aug29") - per the dataset
% layout convention (<SUBJ>_<group>_<Day>_SV_<MonDD>), the subject ID
% itself is a <Letters>_<Digits> pair at the start. Falls back to the
% full name if that pattern isn't found, so nothing goes blank.
tok = regexp(mouse_name, '^[A-Za-z]+_\d+', 'match', 'once');
if isempty(tok)
    id = mouse_name;
else
    id = tok;
end
end

function s = texEscape(s)
% Escapes characters MATLAB's TeX interpreter would otherwise treat as
% special (subscript/superscript/grouping) - needed wherever a panel
% title is combined with a TeX-interpreted colored legend line into the
% same title() call (see setPanelTitleWithLegend), since Interpreter
% applies to the WHOLE title text uniformly and animal IDs like "PVFP_28"
% contain underscores TeX would otherwise misread as a subscript.
s = strrep(s, '\', '\\');
s = strrep(s, '_', '\_');
s = strrep(s, '^', '\^');
s = strrep(s, '{', '\{');
s = strrep(s, '}', '\}');
end

function setPanelTitleWithLegend(ax, panel_title, legend_tex, title_font_size, legend_font_size)
% SV 9/9/26 (per user's request): the panel's own title (e.g. "Platform
% Entry for ITI 1-3") is unchanged; when legend_tex (returned by
% plotTwoTraceOverlayPanel) is non-empty, a second, smaller line with the
% colored "TMS (N=X, n=Y)   Sham (N=X, n=Y)" legend is added directly
% beneath it - this REPLACES the legend text that used to sit inline at
% the end of each trace. A single title() text object can't mix two
% different font sizes across its own lines on its own, but MATLAB's TeX
% interpreter's \fontsize{} command can override just the legend line's
% size inline, so the title line keeps its own normal size while the
% legend line stays smaller underneath it.
if isempty(legend_tex)
    title(ax, panel_title, 'Interpreter', 'none', 'FontSize', title_font_size);
else
    title(ax, {texEscape(panel_title), sprintf('\\fontsize{%d}%s', legend_font_size, legend_tex)}, ...
        'Interpreter', 'tex', 'FontSize', title_font_size);
end
end

function panel_title = makeGridPanelTitle(action_label, row_label, col_label)
% Builds "<action_label> for <row> <col>" (e.g. "Platform Entry for ITI
% 1-3"), dropping a redundant leading "Tones " from col_label when
% row_label already names a tone-related epoch (platform_entry_exit's
% "ITI"/"Tone" rows) - without this, those panels read as the confusing
% "Tone Tones 1-3" / doubled-up "ITI Tones 1-3" the hand-drawn spec never
% shows (it just writes "ITI 1-3", "Tone 4-6", ...).
if (strcmpi(row_label, 'iti') || strcmpi(row_label, 'tone')) && startsWith(col_label, 'Tones ', 'IgnoreCase', true)
    col_label = col_label(numel('Tones ')+1:end);
end
row_col = strtrim(sprintf('%s %s', row_label, col_label));
if isempty(action_label)
    panel_title = row_col;
else
    panel_title = strtrim(sprintf('%s for %s', action_label, row_col));
end
end

function drawAUCInset(ax, valsA, colorA, valsB, colorB, x_range, y_range, is_paired, text_scale, R)
% Small embedded AUC dot-plot inset in a trace panel's top-right corner:
% per-animal AUC for series A and B on an integer y-axis, plus a
% significance star. Plotted directly in the host axes' own DATA
% coordinates (x_range/y_range, a sub-box of the panel) rather than as a
% separate axes - a free-standing axes does not survive exportgraphics'
% cropping of tiledlayout figures (SV 9/9/26), and staying inside the one
% axes keeps it exactly where the caller placed it.
%
% SV 10/1/26 (user's picks from the inset trait sheet - D3, M2, L3 - and
% the axis rules):
%  - R (optional, from insetRowRange): ONE range shared by every inset of
%    a row (total + tone bins = same data -> same scale), on a 1/2/2.5/5
%    x 10^k grid with 3-4 increments; all ticks labeled, or only the two
%    ends and 0 when there are more than 4. Omitted -> this inset's own.
%  - "AUC" written vertically beside the axis, 3.5 pt regular (L3).
%  - dots (D3): light tint of the series color with a thin, slightly
%    darker tint edge, so the mean/SEM marker reads on top of them.
%  - mean/SEM (M2): darker shade of the series color - short mean tick
%    0.7 wide, SEM line 0.35 with perpendicular end caps.
%  - paired comparisons (GFP vs RFP, same animals - valsA/valsB in the
%    same animal order, see loadGroupAUCValues' require_channel): a thin
%    grey line joins each animal's two dots.
%  - red *, **, *** above the inset when p < 0.05 (same test as the stats
%    page, is_paired); nothing when not significant.
%  - drawn BEHIND the trace data (moved to the bottom of the axes' draw
%    order at the end), so the traces sit on top.
% text_scale (optional, default 1): shrinks the inset's text along with a
% smaller tone-bin panel.
if nargin < 8 || isempty(is_paired)
    is_paired = false;
end
if nargin < 9 || isempty(text_scale)
    text_scale = 1;
end
valsA = valsA(:);
valsB = valsB(:);
if is_paired && numel(valsA) == numel(valsB)
    ok = isfinite(valsA) & isfinite(valsB);
    valsA = valsA(ok);
    valsB = valsB(ok);
else
    valsA = valsA(isfinite(valsA));
    valsB = valsB(isfinite(valsB));
end
if isempty(valsA) && isempty(valsB)
    return;
end
if nargin < 10 || isempty(R)
    R = insetRowRange([insetValues(valsA); insetValues(valsB)]);
end

x0 = x_range(1); x1 = x_range(2);
y0 = y_range(1); y1 = y_range(2);
w = x1 - x0;
map_y = @(v) y0 + (v - R.lo) / (R.hi - R.lo) * (y1 - y0);
y_zero = map_y(0);

n_before = numel(ax.Children);
hold(ax, 'on');

axis_color = [0.35 0.35 0.35];
axis_x = x0;
fs = 5 * text_scale;
plot(ax, [axis_x axis_x], [y0 y1], 'Color', axis_color, 'LineWidth', 0.4, 'HandleVisibility', 'off');
for k = 1:numel(R.ticks)
    ty = map_y(R.ticks(k));
    tick_w = 0.05 * w;
    if R.labeled(k)
        tick_w = 0.07 * w;
    end
    plot(ax, [axis_x - tick_w, axis_x], [ty ty], 'Color', axis_color, 'LineWidth', 0.4, 'HandleVisibility', 'off');
    if R.labeled(k)
        text(ax, axis_x - 0.1*w, ty, sprintf('%d', round(R.ticks(k))), 'FontSize', fs, ...
            'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', 'Color', axis_color);
    end
end
text(ax, axis_x - 0.85*w, (y0 + y1) / 2, 'AUC', 'FontSize', 3.5 * max(text_scale, 0.8), 'Rotation', 90, ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'Color', axis_color);
plot(ax, [axis_x x1], [y_zero y_zero], 'Color', axis_color, 'LineWidth', 0.4, 'HandleVisibility', 'off');

xA = x0 + 0.34*w;
xB = x0 + 0.74*w;
jitter_w = 0.14*w;
xsA = xA + (rand(size(valsA)) - 0.5) * jitter_w;
xsB = xB + (rand(size(valsB)) - 0.5) * jitter_w;

if is_paired && ~isempty(valsA) && numel(valsA) == numel(valsB)
    for k = 1:numel(valsA)
        plot(ax, [xsA(k) xsB(k)], [map_y(valsA(k)) map_y(valsB(k))], 'Color', [0.60 0.60 0.60], ...
            'LineWidth', 0.15, 'HandleVisibility', 'off');
    end
end
plotAUCDotColumnData(ax, xA, xsA, valsA, colorA, map_y, jitter_w);
plotAUCDotColumnData(ax, xB, xsB, valsB, colorB, map_y, jitter_w);

if ~isempty(valsA) && ~isempty(valsB)
    [~, p_val] = describeComparison(valsA, valsB, is_paired);
    stars = '';
    if p_val < 0.001
        stars = '***';
    elseif p_val < 0.01
        stars = '**';
    elseif p_val < 0.05
        stars = '*';
    end
    if ~isempty(stars)
        text(ax, (xA + xB)/2, y1 + 0.02*(y1-y0), stars, 'FontSize', 8 * text_scale, 'FontWeight', 'bold', ...
            'Color', [0.85 0.20 0.15], 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
    end
end

% Everything just drawn goes to the back of the draw order (Children(1)
% is drawn on top), so the traces render over the inset.
kids = ax.Children;
n_new = numel(kids) - n_before;
if n_new > 0
    ax.Children = [kids(n_new+1:end); kids(1:n_new)];
end

end

function plotAUCDotColumnData(ax, x, xs, vals, color, map_y, jitter_w)
% One column of the AUC inset (see drawAUCInset), in the host panel's DATA
% coordinates via map_y; xs = each dot's (jittered) x.
% SV 10/1/26 (user's picks D3 + M2): light tinted dots with a thin tint
% edge; mean and SEM in a darker shade of the series color on top.
if isempty(vals)
    return;
end
dot_fill = color.line + (1 - color.line) * 0.70;
dot_edge = color.line + (1 - color.line) * 0.42;
scatter(ax, xs, arrayfun(map_y, vals), 0.8, 'o', 'filled', 'MarkerFaceColor', dot_fill, ...
    'MarkerEdgeColor', dot_edge, 'LineWidth', 0.2, 'HandleVisibility', 'off');
mark = color.line * 0.7;
m = mean(vals);
s = std(vals) / sqrt(numel(vals));
if ~isfinite(s), s = 0; end
mean_half = 0.75 * jitter_w;
cap_half = 0.30 * jitter_w;
plot(ax, [x x], [map_y(m - s), map_y(m + s)], 'Color', mark, 'LineWidth', 0.35, 'HandleVisibility', 'off');
if s > 0
    plot(ax, [x - cap_half, x + cap_half], [map_y(m - s) map_y(m - s)], 'Color', mark, 'LineWidth', 0.35, 'HandleVisibility', 'off');
    plot(ax, [x - cap_half, x + cap_half], [map_y(m + s) map_y(m + s)], 'Color', mark, 'LineWidth', 0.35, 'HandleVisibility', 'off');
end
plot(ax, [x - mean_half, x + mean_half], [map_y(m) map_y(m)], 'Color', mark, 'LineWidth', 0.7, 'HandleVisibility', 'off');
end

function seconds_max = maxProtocolSessionLengthSec(n_cs)
% SV 9/28/26: n_cs (optional, default 9) - the number of CS+ tones to
% size the session for. The QC page now passes the most tones actually
% detected among the Session's animals (see qcSessionAxisMaxSec), so a
% cohort that only ever runs 6 tones (e.g. DCSP) isn't drawn on a 9-tone
% time axis with a third of every panel empty.
% SV 9/9/26: the PMA/TMS fear-conditioning protocol's own maximum
% possible session length (per the Fear Conditioning Experiment
% Designer's parameters - user-confirmed 9/9/26): 80s baseline + 9 CS+
% presentations of 30s each + 8 inter-CS gaps (9 presentations means 8
% gaps between them) at the max 150s each + 80s post-experiment hold.
% Shock (2s) falls inside each 30s CS+ window, not additional time. Used
% as a fixed, protocol-derived X-axis ceiling for the QC page's raw
% traces so every animal's row shares the same time base regardless of
% exactly how long that particular recording ran past the protocol's own
% event schedule.
if nargin < 1 || isempty(n_cs) || n_cs < 1
    n_cs = 9;
end
baseline_s = 80;
cs_duration_s = 30;
n_gaps = n_cs - 1;
max_iti_s = 150;
post_hold_s = 80;
seconds_max = baseline_s + n_cs*cs_duration_s + n_gaps*max_iti_s + post_hold_s;
end

function [seconds_max, max_tones] = qcSessionAxisMaxSec(entries)
% SV 9/28/26 (per user's request): the QC raw-trace x-axis limit for one
% Session's QC pages - the protocol's maximum possible length
% (maxProtocolSessionLengthSec) for the MOST tones detected in any of
% this Session's animals (TMS and Sham together, so every row on every
% page shares one time base), rounded DOWN to the 120 s tick grid so the
% axis ends on a labeled tick. 6 tones -> 1090 s -> 1080; 9 tones ->
% 1630 s -> 1560. Falls back to the 9-tone length if no animal has saved
% tone onsets.
tick_s = 120;
max_tones = 0;
for i = 1:numel(entries)
    if ~isfile(entries(i).file)
        continue;
    end
    ar = animalResultCache(entries(i).file);
    if isfield(ar, 'tone_onsets_sec')
        max_tones = max(max_tones, numel(ar.tone_onsets_sec));
    end
end
if max_tones == 0
    max_tones = 9;
end
seconds_max = floor(maxProtocolSessionLengthSec(max_tones) / tick_s) * tick_s;
end

function plotRawTraceWithMarkers(ax, entry, condition_labels, marker_colors, behavior, run_list, marker_styles, channel, session_max_s)
% Raw whole-session 465 trace for one animal, colored by group, with
% every tone onset marked as a light gray tick and each condition
% label's trial events marked in its own distinct color AND line style -
% per the hand-drawn spec (blue for platform entry, purple for platform
% exit, etc. via markerPalette()) plus, per user's request, a distinct
% dash pattern per condition so entries vs. exits (etc.) can be told
% apart, and individually counted, even without relying on color alone.
if nargin < 7 || isempty(marker_styles)
    marker_styles = {':'};
end
% SV 9/28/26: channel (optional, default 'pv') - which saved raw signal
% (ar.signals.pv = 465/GFP, ar.signals.sst = 560/RFP) to draw.
if nargin < 8 || isempty(channel)
    channel = 'pv';
end
%
% SV 9/9/26: condition_labels are canonical base labels now (see
% canonicalBaseLabels).
%
% SV 9/9/26 (bugfix): run_list (every run in this animal's group, not
% just one picked run) is needed because each epoch/tone-bin variant run
% saves events_sec under a DIFFERENT field name (resolveConditionField)
% AND, more importantly, each epoch filters that condition's events down
% to only the ones that fall inside that epoch's own window (e.g. an
% "inter_tone_interval" run keeps only entries that happened during an
% ITI) - showing just one variant's events made this QC view look like
% most real behavioral events were missing, when they were only excluded
% from THAT variant's own trial definition. Taking the union of this
% animal's events for a condition across every run in the group gives
% the most complete, honest picture of everything that was ever tagged
% as that event type.
hold(ax, 'on');

if ~isfile(entry.file)
    text(ax, 0.5, 0.5, sprintf('%s missing', entry.mouse), 'Units', 'normalized', ...
        'HorizontalAlignment', 'center', 'Color', [0.6 0.6 0.6]);
    axis(ax, 'off');
    return;
end
S = load(entry.file, 'animal_result');
ar = S.animal_result;
if ~isfield(ar, 'signals') || ~isfield(ar.signals, channel) || isempty(ar.signals.(channel)) ...
        || ~isfield(ar.signals, 'fs') || isempty(ar.signals.fs)
    text(ax, 0.5, 0.5, sprintf('%s: no raw %s signal saved', entry.mouse, channelDisplayName(channel)), 'Units', 'normalized', ...
        'HorizontalAlignment', 'center', 'Color', [0.6 0.6 0.6]);
    axis(ax, 'off');
    return;
end

sig = ar.signals.(channel);
t = (0:numel(sig)-1) / ar.signals.fs;
col = groupColor(entry.group, channel);
% SV 9/9/26 (per user's request): thinner again (was 0.15, then 0.25
% before that) - dense, fast-varying raw traces were still reading as a
% thick "fuzzy caterpillar" band rather than a legible line.
% SV 9/28/26: plotted from a min/max-envelope reduction of the raw signal
% (decimateMinMax) - every raw sample as a vector vertex made each QC page
% several MB. Each of the 3000 bins keeps its own lowest and highest
% sample, so spikes and the trace's visual envelope are unchanged.
[t_plot, sig_plot] = decimateMinMax(t, sig, 3000);
plot(ax, t_plot, sig_plot, 'Color', col.line, 'LineWidth', 0.1);

% SV 9/9/26 (per user's request): fixed X-axis (0 to the protocol's own
% maximum possible session length) instead of each panel auto-ranging to
% its own recording's length - so every animal's raw trace sits on the
% SAME time base and lines up visually, the same reasoning as matching
% Y-axis span across this column. A session that ran past this (pure
% recording lead-out after the protocol's own event schedule ended, not
% part of the protocol itself) is simply not shown past that edge - nothing
% is deleted, just not in view.
% SV 9/9/26 (per user's request): capped at 1580s (was the protocol's
% full theoretical max, ~1630s) - nothing meaningful happens in that last
% ~50s tail across this dataset, so it's cropped from view entirely
% rather than left as dead empty axis space.
% SV 9/28/26 (per user's request): session_max_s (optional 9th arg) now
% comes from qcSessionAxisMaxSec - sized to the most tones actually
% detected in this Session rather than always 9. The old fixed 9-tone
% value (capped at 1580) is kept only as the default.
if nargin < 9 || isempty(session_max_s)
    session_max_s = floor(min(maxProtocolSessionLengthSec(), 1580) / 120) * 120; % SV 10/1/26: end on a labeled tick
end
xlim(ax, [0, session_max_s]);
% SV 9/9/26 (per user's request): tick every 120s instead of MATLAB's
% default auto-spacing (~200s on a session this long) - readable now that
% the panel itself is much wider (see qcRawTraceColSpan).
set(ax, 'XTick', 0:120:session_max_s);

% SV 9/9/26 (bugfix): Y-axis is set explicitly from the actual
% peaks/valleys of the data in the window that matters (20s in, past the
% recording-onset settling artifact/initial spike common right at the
% start of a fiber photometry trace, through the protocol's own 27-minute
% ceiling) - NOT MATLAB's default auto-scaling over the full visible
% x-range, which would let that early artifact (or anything past the
% protocol's real end) blow out the range for the part anyone actually
% looks at. (Was 10s - per user's correction, the settling spike can run
% past that, so the exclusion window is now 20s as originally specified.)
window_mask = t >= 20 & t <= session_max_s;
if any(window_mask)
    y_data_lo = min(sig(window_mask));
    y_data_hi = max(sig(window_mask));
else
    y_data_lo = min(sig);
    y_data_hi = max(sig);
end
if ~isfinite(y_data_lo) || ~isfinite(y_data_hi) || y_data_hi <= y_data_lo
    y_data_lo = -1;
    y_data_hi = 1;
end
% SV 10/1/26 (per user's axis rule): the y-axis now starts and ends on a
% labeled tick of a 1/2/5 x 10^k grid around that range (rowYAxisLimits),
% with the tone bars just above the x-axis, instead of a 5% pad.
[y_lo, y_hi, y_step, tone_bar_y] = rowYAxisLimits([y_data_lo, y_data_hi]);

% SV 9/9/26 (per user's spec, corrected): tones are drawn as a filled
% duration BAR (onset to offset), in the SAME style as the Baseline/AUC
% bars on the trial-aligned panels - not a thin instantaneous tick -
% since a tone is a time RANGE, not a point event. Sits just below the
% trace, matching where those other bars sit relative to their traces.
set(ax, 'YLim', [y_lo y_hi], 'YTick', y_lo:y_step:y_hi, 'Clipping', 'on');

if isfield(ar, 'tone_onsets_sec') && ~isempty(ar.tone_onsets_sec)
    onsets = ar.tone_onsets_sec;
    if isfield(ar, 'tone_offsets_sec') && numel(ar.tone_offsets_sec) == numel(onsets)
        offsets = ar.tone_offsets_sec;
    else
        % SV 9/9/26: animal_result files saved before tone_offsets_sec was
        % added won't have it (reports_only re-reads already-saved .mat
        % files rather than reprocessing raw TDT data), so derive it here
        % instead of falling back to zero-width (invisible) bars - see
        % deriveToneOffsetsFromCue.
        offsets = deriveToneOffsetsFromCue(ar, onsets);
    end
    for k = 1:numel(onsets)
        line(ax, [onsets(k) offsets(k)], [tone_bar_y tone_bar_y], 'Color', [0.55 0.55 0.55], ...
            'LineWidth', 3, 'HandleVisibility', 'off');
    end
end

% SV 9/9/26 (per user's spec): each condition_label (platform_entry,
% platform_exit, ...) gets its OWN color AND line style (markerPalette),
% spanning the full trace height, so entry vs. exit (etc.) are visually
% distinguishable from each other and from the tone bars above - and, per
% user's later request, from each other by dash pattern too (not just
% color), so the number of each can be individually counted by eye.
for c = 1:numel(condition_labels)
    base_label = condition_labels{c};
    mcolor = marker_colors{mod(c-1, numel(marker_colors)) + 1};
    mstyle = marker_styles{mod(c-1, numel(marker_styles)) + 1};
    times = unionEventTimesForAnimal(run_list, entry.mouse, entry.file, behavior, base_label);
    for k = 1:numel(times)
        xline(ax, times(k), mstyle, 'Color', mcolor, 'LineWidth', 0.9, 'HandleVisibility', 'off');
    end
end

box(ax, 'off');
% SV 9/9/26 (per user's request): shorter tick marks (was MATLAB's
% default TickLength, [0.01 0.025] - too long/chunky once this panel got
% much wider) and a bigger tick-label font (was 7 - too small once the
% panel got much wider) - scoped to just this raw whole-session trace
% panel; the z-scored drill-down panels already have the right tick size.
set(ax, 'TickDir', 'out', 'FontSize', 10, 'TickLength', [0.004 0.01]);

end

function offsets = deriveToneOffsetsFromCue(ar, onsets)
% Reconstructs tone OFFSET times (seconds, same timebase as onsets)
% without needing animal_result to have been resaved by a full
% reprocessing run.
%
% SV 9/9/26 (bugfix, replaces an interp1-based version): the first
% version of this tried to reconstruct offsets from the cue file's
% [onset_frame, offset_frame] pairs by fitting a frame->second mapping
% via interp1 on the onset correspondence points and applying it to the
% offset frames - fragile, and it produced garbage for at least one real
% animal (offsets landing at or past the NEXT tone's onset, making 9
% separate tone bars render as what looked like one long continuous
% bar). The experiment definition file (input_files.experiment, saved by
% every past run) is much more direct: it stores cs_dur - the CS+/tone
% duration in seconds, a single fixed value confirmed against the Fear
% Conditioning Experiment Designer's own "CS+ Laser (s)" field (30s for
% this protocol) - so offset = onset + cs_dur needs no interpolation or
% frame-timebase reasoning at all.
offsets = onsets;
if ~isfield(ar, 'input_files') || ~isfield(ar.input_files, 'experiment') || ~isfile(ar.input_files.experiment)
    return;
end
try
    S = load(ar.input_files.experiment, 'cs_dur');
catch
    return;
end
if ~isfield(S, 'cs_dur') || isempty(S.cs_dur) || ~isnumeric(S.cs_dur)
    return;
end
cs_dur = double(S.cs_dur(1));
if ~isfinite(cs_dur) || cs_dur <= 0
    return;
end
offsets = onsets + cs_dur;
end

function times = unionEventTimesForAnimal(run_list, mouse_name, fallback_file, behavior, base_label)
% Collects this one animal's event_sec times for base_label from EVERY
% run in run_list that has them (each run resolves to its own saved
% field name via resolveConditionField), deduplicated - see the note in
% plotRawTraceWithMarkers for why the union (not just one run) is used.
times = [];
if isempty(run_list)
    run_list = struct([]);
end
files_checked = {};
for r = 1:numel(run_list)
    run_entry = run_list(r);
    animal_file = '';
    for i = 1:numel(run_entry.animals)
        if strcmp(run_entry.animals(i).mouse, mouse_name)
            animal_file = run_entry.animals(i).save_file;
            break;
        end
    end
    if isempty(animal_file) || ~isfile(animal_file) || any(strcmp(files_checked, animal_file))
        continue;
    end
    field = resolveConditionField(behavior, base_label, run_entry.params);
    ar = animalResultCache(animal_file); % SV 9/28/26: cached, see animalResultCache
    if isfield(ar, 'events_sec') && isfield(ar.events_sec, field) && ~isempty(ar.events_sec.(field))
        times = [times; ar.events_sec.(field)(:)]; %#ok<AGROW>
    end
end
if isempty(times) && isfile(fallback_file)
    % No run in run_list had this animal (shouldn't normally happen -
    % fallback_file is where its raw trace itself came from) - nothing
    % more to do, times stays empty.
end
times = unique(round(times, 3));
end

function [legend_tex, mean_rng, ref_params] = plotAnimalOwnTracePanel(ax, entry, base_label, tms_runs, sham_runs, behavior, event_line_color, event_line_style, channel)
% SV 10/1/26: also returns mean_rng and ref_params so writeGroupQCPage can
% give the animal's drill-down row one shared axis (applyRowAxes);
% ref_params is [] when the panel has no data.
% This one animal's own trial-level mean +/- SEM, superimposed on its own
% individual trial traces - aggregating ONLY this animal's own
% entries/exits for base_label, per the hand-drawn spec ("these plots
% only aggregate the events from PVFP 28" - no other animal's data goes
% into this panel).
%
% event_line_color/event_line_style (optional, trailing) - per user's
% request: the t=0 aligned-event line is colored/styled to match this
% same condition's marker on the raw-trace QC panel (e.g. blue dotted for
% platform_entry, purple dashed for platform_exit - see markerPalette),
% so a reader can visually tie a drill-down panel back to its tick color
% on the left. Defaults to plotTwoTraceOverlayPanel's own plain gray
% dashed line if omitted.
if nargin < 7, event_line_color = []; end
if nargin < 8, event_line_style = []; end
% SV 9/28/26: channel (optional, default 'pv') - 465/GFP or 560/RFP.
if nargin < 9 || isempty(channel), channel = 'pv'; end
%
% SV 9/9/26 (bugfix): an earlier version of this panel also overlaid the
% OPPOSITE group's aggregate as a second "reference" trace. Per user
% clarification, that was never asked for - each per-animal drill-down
% panel should show exactly one trace: this animal's own mean+SEM over
% its own trials.
%
% base_label is a canonical base condition label (see canonicalBaseLabels)
% - the actual saved field name is resolved from this animal's own run
% (resolveConditionField), since each run's field name carries its own
% epoch/tone-bin suffix.

own_runs = sham_runs;
own_color = groupColor('sham', channel);
own_group_label = 'Sham';
if strcmp(entry.group, 'tms')
    own_runs = tms_runs;
    own_color = groupColor('tms', channel);
    own_group_label = 'TMS';
end

legend_tex = '';
mean_rng = [Inf -Inf];
ref_params = [];
own_run = pickBestRunForAnimalCondition(own_runs, entry.mouse, behavior, base_label, channel);
if isempty(own_run)
    text(ax, 0.5, 0.5, 'No data', 'Units', 'normalized', 'HorizontalAlignment', 'center', 'Color', [0.6 0.6 0.6]);
    axis(ax, 'off');
    return;
end
ref_params = own_run.params;
event_lines = getEventLines(ref_params);
xlim_vals = [-ref_params.TRANGE_pre, ref_params.TRANGE_post];

% SV 9/9/26 (per user's request): pool this animal's trials across every
% EPOCH variant (inter_tone_interval, whole_tone, ...) within the
% all_tones tone-bin ONLY - not across tone-bin variants (tones_1_2_3/
% 4_5_6/7_8_9 are subsets of all_tones, so pooling across bins would
% double-count trials already included in all_tones). Epoch variants ARE
% disjoint (a platform entry/exit happens either during a tone or between
% tones, never both), so pooling them recovers every real trial exactly
% once - this is "every single platform entry/exit across the session"
% for this one animal, matching the raw-trace column's tick count instead
% of whichever single epoch/tone-bin variant happened to have the most
% trials.
%
% SV 9/28/26 (bugfix): not every variant IS disjoint - whole_session
% contains the ITI and tone entries, tone_pre_shock/shock sit inside
% whole_tone, and shocked_trials is a subset of all_trials - so pooling
% "every all_tones run" counted those trials twice or more. qcPoolRuns now
% picks a set that covers each trial exactly once.
own_all_tone_runs = qcPoolRuns(own_runs, behavior);
trial_matrix = [];
for i = 1:numel(own_all_tone_runs)
    field = resolveConditionField(behavior, base_label, own_all_tone_runs(i).params);
    tm = loadSingleAnimalTrialMatrix(own_all_tone_runs(i), entry.mouse, channel, field);
    % SV 9/9/26 (bugfix): plain vertcat errors outright if two epoch
    % runs' trial windows differ by even one sample (a recurring
    % off-by-one across this pipeline - see appendTraceMatrix, used the
    % same way when pooling across ANIMALS) - reuse that same
    % truncate-to-shortest-shared-length helper here instead.
    trial_matrix = appendTraceMatrix(trial_matrix, tm);
end
own_n = size(trial_matrix, 1);

% SV 9/9/26 (per user's request): legend just says "TMS (n=X)" / "Sham
% (n=X)" - like the group-comparison grid pages - rather than the
% animal's own name, since each of these panels only ever has the one
% group's data in it anyway (no TMS-vs-Sham comparison here, just this
% one animal's own trials). show_auc_bar=false: these panels don't
% compute AUC, so the AUC window bar doesn't apply here (Baseline bar
% still shown).
[legend_tex, mean_rng] = plotTwoTraceOverlayPanel(ax, trial_matrix, own_n, own_group_label, own_color, ...
    [], 0, '', own_color, event_lines, xlim_vals, ref_params, [], [], false, [], [], event_line_color, event_line_style);
if isempty(trial_matrix)
    ref_params = [];
end

end

function pool = qcPoolRuns(run_list, behavior)
% SV 9/28/26: the all-tones runs whose trials a QC drill-down panel pools,
% chosen so every trial is counted exactly once (see
% plotAnimalOwnTracePanel):
%   platform_entry_exit     - whole_session alone if it was run (every
%                             entry/exit of the session, once); otherwise
%                             the disjoint pre_tone_baseline + ITI + tone
%                             epochs that were run.
%   tone_on_vs_off_platform - the all_trials run.
%   anything else           - its all-tones run(s) (one per cell already,
%                             see selectRunsForReport).
pool = run_list([]);
if isempty(run_list)
    return;
end
all_tone = run_list(strcmp({run_list.tone_tag}, 'all_tones'));
if isempty(all_tone)
    all_tone = run_list;
end
keys = arrayfun(@(r) rowKeyForBehavior(behavior, r.params), all_tone, 'UniformOutput', false);
switch behavior
    case 'platform_entry_exit'
        if any(strcmp(keys, 'whole_session'))
            pool = all_tone(strcmp(keys, 'whole_session'));
        else
            pool = all_tone(ismember(keys, {'pre_tone_baseline', 'inter_tone_interval', 'whole_tone'}));
        end
    case 'tone_on_vs_off_platform'
        pool = all_tone(strcmp(keys, 'all_trials'));
    otherwise
        pool = all_tone;
end
if isempty(pool)
    pool = all_tone(1);
end
end

function run = pickBestRunForAnimalCondition(run_list, mouse_name, behavior, base_label, channel)
% Like pickBestRunForCondition, but scored by THIS ONE animal's own trial
% count for the condition (loadSingleAnimalTrialMatrix) rather than the
% whole group's - different animals in the same group can each have
% their best data in a different epoch/tone-bin variant.
% SV 9/28/26: channel (optional, default 'pv').
if nargin < 5 || isempty(channel)
    channel = 'pv';
end
run = [];
best_score = -1;
for i = 1:numel(run_list)
    r = run_list(i);
    field = resolveConditionField(behavior, base_label, r.params);
    tm = loadSingleAnimalTrialMatrix(r, mouse_name, channel, field);
    n = size(tm, 1);
    if n > best_score
        best_score = n;
        run = r;
    end
end
if isempty(run)
    run = pickBestRunForCondition(run_list, behavior, base_label, channel);
end
end

function span = qcRawTraceColSpan()
% Number of "fine" tiledlayout columns (see writeGroupQCPage) the QC
% page's raw whole-session trace panel spans, relative to one drill-down
% column's width. Shared by writeOneBehaviorDayReport (sizing the page
% canvas) and writeGroupQCPage (the actual tiledlayout/nexttile spans) so
% the two stay in sync.
%
% SV 9/9/26 (per user's request): widened from 2 to 6 - at this raw
% signal's native sampling density (often ~50-100Hz over a 1500+s
% session), a normal panel width packs so many real data points into so
% few pixel columns that it reads as a solid "fuzzy" band no matter the
% line width (confirmed empirically - thinning the line further barely
% changed it). This is genuine VECTOR content, not rasterized at export,
% so giving it much more physical page width resolves the real
% underlying dynamics instead of hiding them - confirmed by rendering the
% existing PDF at high zoom, which already showed crisp detail once
% magnified; the fix is to make that same detail visible at normal
% viewing size instead of requiring the reader to zoom in.
span = 6;
end

function n = qcMaxAnimalsPerPage()
% Max animals grouped onto a single QC page before starting a new one -
% per user's request. exportgraphics silently caps a tiledlayout figure's
% exported page HEIGHT regardless of the declared figure size (confirmed
% empirically: requesting a much taller figure produced no taller a page
% - print() respects an explicit size correctly, but its PDF output can't
% be appended into a multi-page PDF, and this system has no Ghostscript
% to merge separate PDFs afterward, so that route was a dead end). Since
% that height ceiling is roughly fixed regardless of row count, putting
% FEWER rows on one page is the only way to give each row a bigger share
% of it - so a 6-animal group becomes two 3-animal pages instead of one
% cramped 6-row page.
n = 3;
end

function n_pages = writeGroupQCPage(pdf_path, g, condition_labels, channel)
% SV 10/1/26: returns how many pages it appended (0 if none), so the
% single-PDF assembler can tag each QC page with its day.
n_pages = 0;
% Per the hand-drawn spec: for every animal, a row with (1) its raw
% whole-session 465 trace (tone onsets ticked gray, each condition's
% trial events ticked in a distinct color) plus (2) one drill-down panel
% per condition_label aggregating ONLY that one animal's own trials for
% that condition (plotAnimalOwnTracePanel) - mean+SEM over its own
% individual trial traces, nothing from any other animal.
%
% SV 9/9/26 (bugfix): now creates/sizes/exports its own page(s) - possibly
% more than one, see qcMaxAnimalsPerPage - instead of being handed one
% pre-made figure to fill, since the right canvas size depends on how
% many animals actually land on EACH page, not the group's total.

% SV 9/9/26 (bugfix): the drill-down panels resolve their own best run
% PER (animal, condition) now (plotAnimalOwnTracePanel /
% pickBestRunForAnimalCondition / pickBestRunForCondition) rather than
% from one run picked upfront for the whole group - the animal ROSTER
% itself is still the union across every run in the group
% (unionAnimalListFromRuns), so an animal that failed to process for
% whichever variant a single "best" pick would have landed on still
% shows up with its raw trace, instead of silently vanishing.
%
% SV 9/28/26: channel (optional, default 'pv') - which channel's raw
% traces and drill-downs to draw, so the RFP (560) TMS-vs-Sham report
% gets its own 560 QC pages.
if nargin < 4 || isempty(channel)
    channel = 'pv';
end
entries = [unionAnimalListFromRuns(g.tms_runs), unionAnimalListFromRuns(g.sham_runs)];
n = numel(entries);
if n == 0
    return;
end

% SV 9/9/26 (per user's request): sorted by numeric subject ID (e.g.
% PVFP_28, 29, 30, ...) rather than left in tms-then-sham union order, so
% splitting across pages lands on a predictable, natural boundary (e.g.
% "PVFP 28-30" on page 1, "31-33" on page 2) regardless of which group
% (tms/sham) each animal happens to belong to.
sort_keys = zeros(1, n);
for i = 1:n
    tok = regexp(shortAnimalID(entries(i).mouse), '\d+', 'match', 'once');
    if isempty(tok)
        sort_keys(i) = i;
    else
        sort_keys(i) = str2double(tok);
    end
end
[~, sort_idx] = sort(sort_keys);
entries = entries(sort_idx);

[marker_colors, marker_names, marker_styles] = markerPalette();
style_names = {'dotted', 'dashed', 'dash-dot', 'solid'};

% SV 9/28/26: one shared x-axis limit for every raw-trace row on every QC
% page of this Session, from the most tones detected (qcSessionAxisMaxSec).
[session_max_s, session_max_tones] = qcSessionAxisMaxSec(entries);

% SV 9/9/26 (bugfix): tiledlayout in this MATLAB version has no
% ColumnWidth property (confirmed unavailable), so equal-width columns is
% the default - the raw whole-session trace column instead spans several
% of these finer columns (nexttile's [1 N] span, N = qcRawTraceColSpan())
% to get much more than a drill-down column's width, since it needs to
% show a much longer time axis (a whole session vs. one trial window)
% legibly - see qcRawTraceColSpan's own note for why this needed to grow
% further still (raw signal density, not panel size, per se).
fine_ncols = qcRawTraceColSpan() + numel(condition_labels);

per_page = qcMaxAnimalsPerPage();
n_qc_pages = ceil(n / per_page);

for page_i = 1:n_qc_pages
    page_entries = entries((page_i-1)*per_page + 1 : min(n, page_i*per_page));
    n_page = numel(page_entries);

    % SV 9/9/26 (per user's request): sized from THIS PAGE's own (smaller)
    % row count, not the group's total - see qcMaxAnimalsPerPage for why
    % fewer rows per page is what actually buys each row more height.
    qc_w = min(90, max(24, 3.0 * fine_ncols + 4));
    qc_h = min(64, max(15, 6.8 * max(1, n_page) + 4.8));
    fig = reportPageFigure(qc_w, qc_h);

    tl = paddedTiledLayout(fig, n_page + 1, fine_ncols, 'compact');
    page_suffix = '';
    if n_qc_pages > 1
        page_suffix = sprintf(' (page %d of %d)', page_i, n_qc_pages);
    end
    title(tl, sprintf('%s -- %s -- raw isosbestic-corrected %s traces (QC)%s', strrep(g.behavior, '_', ' '), g.day_key, ...
        channelDisplayName(channel), page_suffix), 'Interpreter', 'none', 'FontWeight', 'bold');

    caption_parts = {sprintf('TMS = %s, Sham = %s.', seriesColor('tms', channel).name, seriesColor('sham', channel).name), ...
        sprintf('Gray bar = tone on (up to %d per animal this session).', session_max_tones)};
    for c = 1:numel(condition_labels)
        mname = marker_names{mod(c-1, numel(marker_names)) + 1};
        sname = style_names{mod(c-1, numel(style_names)) + 1};
        caption_parts{end+1} = sprintf('%s %s ticks = %s.', mname, sname, strrep(condition_labels{c}, '_', ' ')); %#ok<AGROW>
    end
    subtitle(tl, strjoin(caption_parts, ' '), 'FontAngle', 'italic', 'FontSize', 8);

    for i = 1:n_page
        e = page_entries(i);
        row_start = (i - 1) * fine_ncols;

        if strcmp(e.group, 'tms')
            group_runs = g.tms_runs;
        else
            group_runs = g.sham_runs;
        end

        ax = nexttile(tl, row_start + 1, [1 qcRawTraceColSpan()]);
        plotRawTraceWithMarkers(ax, e, condition_labels, marker_colors, g.behavior, group_runs, marker_styles, channel, session_max_s);
        title(ax, sprintf('%s (%s)', e.mouse, upper(e.group)), 'Interpreter', 'none', 'FontSize', 8);
        if i == n_page
            xlabel(ax, 'Time (s)');
        end
        % SV 9/9/26 (bugfix, per user's request): each animal's raw-trace
        % panel now keeps its OWN tight, spike-excluded Y-range instead of
        % being stretched to match whichever animal in the group has the
        % widest range (matchYAxesAcrossPanels, removed here) - that
        % cross-animal matching was dragging the very early
        % settling-artifact spike (already excluded when THIS panel computes
        % its own range - see plotRawTraceWithMarkers) back into view
        % whenever a different animal's own (real, non-artifact) dynamic
        % range was simply wider.

        cond_axes = gobjects(1, 0);
        cond_param_list = {};
        row_rng = [Inf -Inf];
        for c = 1:numel(condition_labels)
            cond = condition_labels{c};
            ax2 = nexttile(tl, row_start + qcRawTraceColSpan() + c);
            % SV 9/9/26 (per user's request): the drill-down panel's t=0
            % line uses the SAME color/style as this condition's tick
            % marks on the raw-trace panel (markerPalette) - e.g. blue
            % dotted for platform_entry, purple dashed for platform_exit.
            mcolor = marker_colors{mod(c-1, numel(marker_colors)) + 1};
            mstyle = marker_styles{mod(c-1, numel(marker_styles)) + 1};
            [legend_tex, cond_rng, cond_params] = plotAnimalOwnTracePanel(ax2, e, cond, g.tms_runs, g.sham_runs, g.behavior, mcolor, mstyle, channel);
            % SV 9/9/26 (per user's request, superseding the "PVFP_28 Retr:
            % ..." wording below): the short animal ID + day key prefix is
            % dropped from every drill-down panel's title - the raw-trace
            % panel immediately to its left already names the animal (and
            % the page title above already names the day), so repeating
            % both on every one of that animal's drill-down panels was
            % redundant. Applies to every behavior's drill-down panels, not
            % just tone_shock_vs_noshock's (which is why this sits outside
            % the isShockNoShockCond branch below).
            %
            % The trailing "(all)" on the non-shock/noshock branches flags
            % that this pools every trial across both epochs in the
            % all_tones bin (see plotAnimalOwnTracePanel), i.e. every
            % entry/exit shown by the left-column raw-trace ticks - not
            % just whichever one epoch/tone-bin variant is being shown.
            % SV 9/9/26 (per user's request): tone_on_platform/
            % tone_off_platform use the abbreviated "On-Plat"/"Off-Plat
            % Tone Onset (all)" wording instead of condLabelDisplayName's
            % generic "Tone On Platform"/"Tone Off Platform", matching the
            % trace/AUC grid pages' new tone-onset title format above.
            % SV 9/9/26 (per user's request): tone_shock/tone_noshock use
            % "Shocked during Tone" / "Not-Shocked during Tone" (no "(all)"
            % suffix - per the user's own exact wording), matching the
            % "Shocked"/"Not-Shocked" wording on the trace/AUC grid pages.
            if isToneOnOffPlatformCond(cond)
                panel_title = sprintf('%s-Plat Tone Onset (all)', toneOnOffWord(cond));
            elseif isShockNoShockCond(cond)
                panel_title = sprintf('%s during Tone', shockedWord(cond));
            else
                panel_title = sprintf('%s (all)', condLabelDisplayName(cond));
            end
            setPanelTitleWithLegend(ax2, panel_title, legend_tex, 8, 7);
            if ~isempty(cond_params)
                cond_axes(end+1) = ax2; %#ok<AGROW>
                cond_param_list{end+1} = cond_params; %#ok<AGROW>
                row_rng = [min(row_rng(1), cond_rng(1)), max(row_rng(2), cond_rng(2))];
            end
        end
        % SV 9/9/26 (per user's clarification): Y-axis span matched WITHIN
        % this animal's row (its own entry/exit/etc. drill-down panels, same
        % units, directly comparable) but not across different animals' rows
        % - same rule as the main comparison grid pages. The raw-trace panel
        % is left out of this row-match: different x-axis/duration and
        % purpose (whole-session QC view vs. trial-aligned response).
        % SV 10/1/26: identical y-axis across this animal's drill-down
        % panels, ending on labeled ticks, Baseline bar above the x-axis.
        applyRowAxes(cond_axes, row_rng, cond_param_list, false, false(1, numel(cond_axes)));
    end

    % SV 9/28/26: QC pages now start their own document (the cross-day
    % __QC_GFP/__QC_RFP PDFs), so the very first page creates the file.
    appendPageToPDF(fig, pdf_path, ~isfile(pdf_path));
    close(fig);
    n_pages = n_pages + 1;
end

end
