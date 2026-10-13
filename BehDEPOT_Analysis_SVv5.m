%% BehDEPOT_Analysis_SVv5.m — PMA (platform-mediated avoidance) behavior scoring
% Author: Sam Vaillancourt (samvail@g.ucla.edu)
%
% =========================================================================
% WHAT THIS SCRIPT DOES
% =========================================================================
% Post-processes BehaviorDEPOT (BehDEPOT) output for platform-mediated
% avoidance (PMA) sessions: tone (CS+) trials alternating with inter-trial
% intervals (ITI), where an animal can escape/avoid a footshock-predicting
% tone by standing on a physical platform ROI. For every already-analyzed
% session it re-scores ROI membership from raw tracking (see v4 changelog
% item 1 below for why it doesn't just trust BehaviorDEPOT's saved
% inROIvector), builds per-tone and per-ITI time bins, and writes one
% Analysis_DT_<roi>.mat file per ROI (e.g. Analysis_DT_platform.mat,
% Analysis_DT_reward.mat) plus diagnostic .fig plots, back into that
% session's own *_analyzed folder.
%
% This does NOT run BehaviorDEPOT itself — it is a second pass over
% sessions BehaviorDEPOT has already Data-Prepped and Behavior-Analyzed
% (see the BehaviorDEPOT app / BehDEPOT_mainscript.m in the BehaviorDEPOT
% repo). Point this script at a folder of sessions BehaviorDEPOT has
% already processed.
%
% =========================================================================
% REQUIREMENTS
% =========================================================================
%  - MATLAB with App Designer / uifigure support (uses uifigure/uicheckbox
%    for the folder-picker dialogs) — no toolboxes beyond base MATLAB.
%  - Helper functions calc_time_plat.m and boutavg.m on the MATLAB path.
%    This script adds its own folder to the path automatically
%    (P.script_dir = pwd, below), so run it FROM the folder it lives in
%    (or containing those two files) rather than with a different current
%    folder, unless you edit P.script_dir yourself.
%  - Each session folder must already contain a BehaviorDEPOT *_analyzed
%    subfolder with Behavior.mat, Tracking.mat, and Params.mat, produced
%    by running the BehaviorDEPOT app's Data Prep + Behavior Analysis
%    stages with a Freezing classifier and a spatial ROI (matching the
%    names in roi_list, below) both enabled.
%
% =========================================================================
% EXPECTED FOLDER STRUCTURE
% =========================================================================
%   <root>\<condition_folder>\<session_folder>\<session_folder>_analyzed\
%                                                   Behavior.mat
%                                                   Tracking.mat
%                                                   Params.mat
%   e.g. DLC_analysis_June2026\sham_TrainD2s1\DCSP_10_sham_TrainD2s1\..._analyzed\
%
%   You point this script at <root> — the folder that CONTAINS the
%   condition folders, NOT a condition folder itself — then pick which
%   condition folders to include from a checkbox list. Every immediate
%   subfolder of a selected condition folder is treated as one session.
%
% =========================================================================
% HOW TO RUN IT
% =========================================================================
% Interactive (normal use — just press Run):
%   1. Open this script in MATLAB and press Run (or F5).
%   2. A folder-picker dialog opens: navigate to and select the ROOT
%      folder that contains your condition folders (see structure above).
%   3. A checkbox window lists every condition folder found in that root,
%      all checked by default. Uncheck any you don't want in this run,
%      then click Run.
%   4. A second checkbox window asks which of the selected condition
%      folders are HABITUATION sessions, i.e. ones where the tone never
%      actually played (see v5 changelog item 1, below). Folders whose
%      name contains "Hab" are pre-checked; adjust if needed and click Run.
%   5. The script processes every session folder inside each selected
%      condition folder, printing progress to the Command Window. A
%      session that errors is logged and skipped rather than aborting the
%      whole batch; a summary of any failures prints at the end.
%
% Headless / non-interactive (e.g. `matlab -batch`, or re-running a known
% batch without re-clicking through the dialogs each time):
%   Predefine these variables in the base workspace BEFORE running the
%   script, and the corresponding dialog(s) above are skipped entirely:
%     BD_root      = 'E:\...\DLC_analysis_June2026';     % the root folder
%     BD_conds     = ["sham_TrainD2s1","tms_TrainD2s1"]; % condition folders to run
%     BD_hab_conds = ["HabD1","HabD2"];    % which of those are habituation
%                                           % (use string.empty if none are)
%   BD_root and BD_conds must BOTH be set to skip the condition-picker
%   dialog. BD_hab_conds is independent and only controls the habituation
%   dialog — leaving it unset still pops that one dialog even in an
%   otherwise-headless run.
%
% =========================================================================
% OUTPUTS (written into each session's own *_analyzed folder)
% =========================================================================
%   Per ROI in roi_list (default "platform", "reward"):
%     Analysis_DT_<roi>.mat  — struct 'Analysis' with fields:
%       .CSp          tone-window metrics: on-ROI time/bins, latency,
%                      freezing, per-trial success (Analysis.CSp.OnPlatSuccessfulTrial)
%       .ITI           inter-trial-interval metrics, incl. .PreTone (the
%                      pre-first-tone baseline window, kept separately)
%       .Locomotion    path length (cm) & rate (cm/s) for baseline/CSp/ITI
%       .Merged        habituation sessions only — merged tone+ITI epoch
%                      metrics (see v5 changelog item 1); absent otherwise
%       .Provenance    scoring body-part, ITI convention, script version,
%                      run date — so any downstream consumer or future
%                      audit can tell how a given file was produced
%     On_<roi>_DT_<roi>.fig            whole-session fraction-on-ROI plot
%     Heat_On_<roi>_Cue_DT_<roi>.fig   per-tone on-ROI heatmap
%     Heat_On_<roi>_ITI_DT_<roi>.fig   per-ITI on-ROI heatmap
%   These per-session .mat files are what a separate downstream script
%   (pma_extractor_SVv7.m) reads to build the group-level summary
%   spreadsheet — this script does not produce that spreadsheet itself.
%
% =========================================================================
% PARAMETERS YOU MAY WANT TO EDIT (see the "Params" section just below)
% =========================================================================
%   bin_size, bout_length, iti_bin     binning granularity for tone/ITI
%   threshold_plat, threshold_success  fraction-of-bin / fraction-of-window
%                                       cutoffs for "on ROI" / "successful trial"
%   begin_win, finish_win              window (s) at the end of each tone
%                                       used to score trial success
%   roi_list                           which Spatial ROI(s) to analyze —
%                                       must match ROI names drawn for
%                                       these sessions in BehaviorDEPOT
%   sample_rate_fallback               used ONLY if a session's Params.mat
%                                       is missing/unreadable; otherwise
%                                       the real per-session frame rate is
%                                       read from Params.Video.frameRate
%
% =========================================================================
% VERSION HISTORY (newest first)
% =========================================================================
%% Sam Vaillancourt, August 27, 2026. v5 changes from v4:
%
%  1) HABITUATION SESSIONS: MERGED TONE+ITI EPOCHS. In the PVcre Aug-2026
%     habituation sessions the PMA software recorded 9 tones but the speaker
%     was physically muted, so no tone ever played. The tone/ITI distinction
%     is therefore meaningless in those sessions - the "tone" windows are
%     just time markers. Splitting them apart would compare an animal's
%     behaviour in one arbitrary 30 s window against an arbitrary 80 s
%     window with no stimulus separating them.
%     Fix: a one-window checkbox picker (folders whose name contains "Hab"
%     are pre-checked) marks which condition folders are habituation. For
%     those, this script additionally computes Analysis.Merged, where epoch
%     i = [CSp_bout(i,1) .. iti_bout(i,2)] - i.e. tone i together with the
%     ITI that follows it, as one contiguous window. This is only well
%     defined because the v4 fix re-aligned ITI_i to FOLLOW tone i; under v3
%     the same merge would have joined a tone to the interval before it.
%     The 9 merged epochs tile the session exactly after the pre-tone
%     baseline, with no gaps or overlap.
%     IMPORTANT: metrics are computed ON the merged window, not by averaging
%     the CSp and ITI columns. Tone is ~30 s and ITI ~80 s, so an unweighted
%     mean of the two would overweight the tone by ~2.7x.
%     The pre-tone baseline is reported separately (Analysis.Merged.BL) and
%     is never pooled into a bin, so it stays usable as the reference point
%     a learning curve is measured against.
%     Non-habituation sessions are untouched: Analysis.Merged is simply not
%     written, and every existing field is byte-for-byte what v4 produced.
%
%  2) SAMPLE RATE READ FROM THE SESSION. v4 hardcoded sample_rate = 49.974.
%     The PVcre Aug-2026 videos are exactly 50.0 fps. Over a ~70,000-frame
%     session that 0.05% error accumulates to ~37 frames of drift by the end
%     - which lands on the last tones, where a habituation learning curve is
%     most informative. v5 reads Params.Video.frameRate from each session's
%     Params.mat and falls back to the old constant with a warning if it is
%     missing. Every duration, rate and latency in the output is affected,
%     so this also slightly changes numbers for re-run older sessions
%     (by ~0.05%, i.e. far below any effect size of interest).
%
% ---------------------------------------------------------------------
% v4 changes from v3 (unchanged in v5, kept for reference):
%% Sam Vaillancourt, August 24, 2026. v4 changes from v3:
% Two fixes, both found by auditing v3's output against the raw per-frame
% data (the binning arithmetic itself was verified correct to within 0.011,
% so neither of these is an arithmetic bug - they're both definitional):
%
%  1) CONSISTENT SCORING POINT (MidBack). v3 read zone membership straight
%     out of SpatialSource.(roi).inROIvector, which BehaviorDEPOT computed
%     from Metrics.Location. Metrics.Location falls through a preference
%     chain in the app's calculateMetrics.m that was changed on 2026-07-22
%     to check Implant BEFORE MidBack. Sessions analyzed before that date
%     therefore scored zone time by the MidBack (body centre) point, and
%     sessions analyzed after scored it by the Implant (head) point.
%     Measured across all 55 sessions in DLC_analysis_June2026:
%       - all 27 sham sessions  -> MidBack
%       - 21 of 28 tms sessions -> Implant
%     i.e. the scoring point was confounded with experimental group on 3 of
%     the 4 experimental days (RetrS2, TrainD1s2, TrainD2s1 - only RetrS1
%     was internally consistent). The two points do not agree: MidBack
%     reads on average +4.0 percentage points MORE time on the platform
%     than Implant (sham +4.8, tms +3.3), and 8 of 55 sessions diverge by
%     more than 10 points - worst cases DCSP_24_tms_RetrS1 (MidBack 0.993
%     vs Implant 0.365) and DCSP_24_tms_TrainD2s1 (0.698 vs 0.184). Since
%     sham was scored by the higher-reading point and tms mostly by the
%     lower-reading one, that difference alone manufactures an apparent
%     sham > tms avoidance effect before any biology.
%     Fix: this script no longer trusts the stored inROIvector. It
%     recomputes zone membership itself for EVERY session from
%     Tracking.Smooth.MidBack against the saved ROI polygon, so all
%     sessions are scored identically regardless of when they were run
%     through the app. Verified 2026-08-24 that this recompute reproduces
%     the stored inROIvector EXACTLY (0 frames different, both ROIs) on
%     every session that was already MidBack-scored - so sham sessions are
%     unchanged by this and only the Implant-scored sessions move.
%     MidBack was chosen (over Implant) because it is the body-centre point,
%     which is the more defensible definition of "the animal is on the
%     platform" for PMA avoidance, and because it is what the majority of
%     sessions already used.
%     NOTE / not fixed here: Metrics.Location also feeds Metrics.Movement,
%     which feeds the app's Freezing classifier. Behavior.Freezing.Vector in
%     the Implant-scored sessions is therefore still Implant-derived. That
%     does not affect any of the four time-in-zone metrics, the visit
%     counts, or the successful-trial counts that pma_extractor pulls, but
%     it does affect the Analysis.CSp.Freezing* fields. Fixing that properly
%     means re-running BehaviorDEPOT data prep on those sessions.
%
%  2) ITI WINDOWS RE-ALIGNED TO FOLLOW THEIR TONE. v3 built the ITI list as
%       ITI_1 = [session start -> tone 1]   (the 80 s pre-tone baseline)
%       ITI_2 = [tone 1 end    -> tone 2]
%       ...
%       ITI_N = [tone N-1 end  -> tone N]
%     and explicitly deleted the interval after the last tone. So the ITI
%     columns were offset one trial from the CSp columns: the column
%     labelled "tone1" was actually pre-session baseline (never an ITI at
%     all), and every other ITI_i was the interval PRECEDING tone i, not
%     following it. Any tone-N-vs-ITI-N comparison in the extractor's binned
%     tabs was therefore comparing a tone against the interval before it.
%     Fix: ITI_i is now the interval FOLLOWING tone i, with ITI_N running
%     from the end of the last tone to the end of the session. Verified
%     2026-08-24 that the post-last-tone tail is exactly 80 s in all 50
%     sessions checked (same as the pre-tone baseline), so the new final
%     window is a consistent, real window - not a ragged leftover.
%     The pre-tone baseline is no longer thrown away silently: it is saved
%     as Analysis.ITI.PreTone (Length/OnPlatPer) for reference.
%
%  3) Added an optional headless/batch entry point (see BD_root/BD_conds
%     below) so this can be re-run non-interactively over a known set of
%     condition folders. Default behaviour with no preset variables is
%     unchanged: the same uigetdir + checkbox window as v3.
%
%% Sam Vaillancourt, July 22, 2026. v3 changes from v2:
% v2 required you to point the script directly at a "condition" folder
% (e.g. .../DLC_analysis_June2026/sham_TrainD2s1) whose immediate
% subfolders are the per-animal session folders. v3 lets you instead point
% it at the HIGHER-level folder that contains multiple condition folders
% (e.g. .../DLC_analysis_June2026, which contains sham_TrainD2s1,
% tms_RetrS1, etc.). A checkbox window lists every immediate subfolder of
% that root (all checked by default) with "Check All" / "Uncheck All" /
% "Run" buttons, so you can choose which condition folders to include in
% one batch run instead of re-running the script once per condition.
% The per-session analysis logic itself (analyze_pma_roi, Behavior.mat
% loading, ROI/freezing calculations) is unchanged from v2 - only the
% folder discovery/selection step is new. v2 is still the right script to
% use if you want to point directly at a single condition folder.

%% Params
% SV, August 27, 2026: I changed - this is now only the FALLBACK. The real
% sample rate is read per session from Params.Video.frameRate further down
% (see sample_rate_session). Left here so sessions with a broken Params.mat
% still run with v4 behaviour.
% sample_rate = 49.974; % sample rate of camera
%
sample_rate_fallback = 49.974; % used only if Params.Video.frameRate is unreadable
sample_rate = sample_rate_fallback;
bin_size = 5; % seconds you want your CSp bin to be
bout_length = 30; % stimulus length in seconds
iti_bin = 6;
threshold_plat = 0.1; % animal has to be on the ROI this much time in a bin
threshold_success = 1.0;
begin_win = 1; % # of seconds before end of bout that you want to look at
finish_win = .5; % # of seconds you want to stop looking at bout
roi_list = ["platform","reward"]; % Spatial ROI names to analyze;
                                   % produces Analysis_DT_<roi>.mat for each, per session

%% Select root directory and choose which condition folders to include
% SV, August 24, 2026: I changed
% P.script_dir = pwd; % directory with script + helper files (calc_time_plat, boutavg, calc_bw_tones)
% disp('Select the higher-level directory containing condition folders (e.g. DLC_analysis_June2026)');
% P.root_directory = uigetdir('','Select the directory containing condition folders');
% if isequal(P.root_directory, 0)
%     error('No directory selected.');
% end
%
% condition_folders = list_subfolders(P.root_directory);
% if isempty(condition_folders)
%     error('No subfolders found in %s', P.root_directory);
% end
%
% selected_conditions = select_folders_gui(condition_folders);
% if isempty(selected_conditions)
%     error('No condition folders selected (window closed without clicking Run, or nothing checked). Aborting.');
% end
% to this - a headless escape hatch wrapped around the identical GUI code, so
% the whole batch can be re-run non-interactively (e.g. from matlab -batch)
% by predefining BD_root and BD_conds in the workspace first. If those
% variables don't exist, behaviour is byte-for-byte what v3 did:
P.script_dir = pwd; % directory with script + helper files (calc_time_plat, boutavg, calc_bw_tones)
if evalin('base', 'exist(''BD_root'',''var'') && exist(''BD_conds'',''var'')')
    P.root_directory = evalin('base', 'BD_root');
    selected_conditions = string(evalin('base', 'BD_conds'));
    condition_folders = list_subfolders(P.root_directory); % only for the "N of M" message below
    fprintf('HEADLESS MODE: root = %s\n', P.root_directory);
else
    disp('Select the higher-level directory containing condition folders (e.g. DLC_analysis_June2026)');
    P.root_directory = uigetdir('','Select the directory containing condition folders');
    if isequal(P.root_directory, 0)
        error('No directory selected.');
    end

    condition_folders = list_subfolders(P.root_directory);
    if isempty(condition_folders)
        error('No subfolders found in %s', P.root_directory);
    end

    selected_conditions = select_folders_gui(condition_folders);
    if isempty(selected_conditions)
        error('No condition folders selected (window closed without clicking Run, or nothing checked). Aborting.');
    end
end
%

fprintf('Running on %d of %d condition folder(s): %s\n', ...
    length(selected_conditions), length(condition_folders), strjoin(selected_conditions, ', '));

%% Which of the selected condition folders are HABITUATION sessions?
% SV, August 27, 2026: I added. One checkbox window, with any folder whose
% name contains "Hab" pre-checked, so the common case is a single click.
% Habituation sessions get the merged tone+ITI epochs (Analysis.Merged);
% every other session is processed exactly as v4 did.
% Headless escape hatch matches the condition picker above: predefine
% BD_hab_conds in the base workspace to skip the dialog (set it to
% string.empty to declare that nothing is habituation).
if evalin('base', 'exist(''BD_hab_conds'',''var'')')
    hab_conditions = string(evalin('base','BD_hab_conds'));
    fprintf('Habituation folders taken from BD_hab_conds.\n');
else
    hab_conditions = select_habituation_gui(selected_conditions);
end

if isempty(hab_conditions)
    fprintf('No folders marked as habituation - all sessions use standard tone/ITI analysis.\n');
else
    fprintf('Habituation folder(s), tone+ITI merged: %s\n', strjoin(hab_conditions, ', '));
end


%% Loop over selected condition folders, then over each session folder within
failed_sessions = {}; % {condition_name, session_name, error_message} - sessions that errored are skipped, not fatal
total_sessions = 0;
for c = 1:length(selected_conditions)
    condition_name = selected_conditions(c);
    P.video_directory = fullfile(P.root_directory, condition_name);
    P.video_folder_list = prepBatch(string(P.video_directory)); %Generate list of session folders to analyze within this condition

    for j = 1:length(P.video_folder_list)
        current_video = P.video_folder_list(j);
        total_sessions = total_sessions + 1;
        fprintf('Processing %s / %s\n', condition_name, current_video);
        try
            addpath(P.script_dir)
            video_folder = strcat(P.video_directory, '\', current_video);
            cd(video_folder) %Folder with data files
            Analysis_path = dir('*analyzed');
            if numel(Analysis_path) ~= 1
                error('Expected exactly one *analyzed folder in %s, found %d', video_folder, numel(Analysis_path));
            end
            cd([Analysis_path.folder '\' Analysis_path.name])
            folder = pwd;

            load('Behavior.mat')

            % Two export formats exist across sessions:
            %  - older BehDEPOT_zzfork app: adds Behavior_Filter.mat (Temporal.CSp.EventBouts/EventVector,
            %    Spatial.<roi>.inROIvector)
            %  - newer BehaviorDEPOT_v1.6 app: no Behavior_Filter.mat; the same info lives directly in
            %    Behavior.mat (Temporal.CSp.Bouts/Vector, Spatial.<roi>.inROIvector)
            % Detect per-session and normalize to a common set of variables so the rest of the
            % pipeline (and the ROI loop below) doesn't need to care which app produced the data.
            if isfile('Behavior_Filter.mat')
                load('Behavior_Filter.mat')
                SpatialSource = Behavior_Filter.Spatial;
                CSp_bout = Behavior_Filter.Temporal.CSp.EventBouts;
                CSp_on = Behavior_Filter.Temporal.CSp.EventVector;
            else
                SpatialSource = Behavior.Spatial;
                CSp_bout = Behavior.Temporal.CSp.Bouts;
                CSp_on = Behavior.Temporal.CSp.Vector;
            end
            % SV, August 24, 2026: I changed
            % CSp_off = ~CSp_on;
            % to this. THIRD BUG, found 2026-08-24 while verifying the v4
            % re-run - pre-existing, present in v3 and every earlier version.
            % v3's 2026-07-24 changelog describes fixing an implicit-expansion
            % bug in "CSp_on.*on_plat" by transposing on_plat to a row. That
            % fix assumed CSp_on is ALWAYS a row. It isn't: in the older
            % Behavior_Filter export format, Temporal.CSp.EventVector is a
            % COLUMN ([N x 1]), so "CSp_on.*on_plat.'" still implicitly
            % expands to an N x N matrix, and onPlatByCue's linear indexing
            % then reads only its first column - collapsing every tone value
            % to CSp_on .* on_plat(1). The symptom is unmistakable and was
            % sitting in the real output: all six tones reading exactly 0.00
            % when the animal happened to be off-ROI at frame 1, or exactly
            % 1.00 when it happened to be on-ROI at frame 1.
            % Measured 2026-08-24: 5 of the 55 sessions use the Behavior_Filter
            % format and were ALL affected - DCSP_22/23/25/26_sham_RetrS1
            % (0.00 x6, 0.00 x6, 0.00 x6, 1.00 x6) and DCSP_10_sham_RetrS2
            % (0.00 x4). Every one of those CSp_plat_time / CSp_reward_time
            % value in the v6 spreadsheet was therefore fabricated by this bug,
            % not measured. Forcing both to rows makes the multiplication a
            % plain elementwise AND regardless of which format produced them:
            CSp_on = CSp_on(:).';
            CSp_off = ~CSp_on;
            %

            % --- Shared across ROIs: CSp/ITI bout timing is ROI-independent ---
            % SV, August 24, 2026: I changed
            % clear iti_bout iti_length
            % iti_bout(1,1) = 1;
            % iti_bout(1,2) = CSp_bout(1,1)-1;
            % for iii = 1:length(CSp_bout)-1
            %     iti_bout(iii+1,1) = CSp_bout(iii,2)+1;
            %     iti_bout(iii+1,2) = CSp_bout(iii+1,1)-1;
            % end
            % iti_bout(length(CSp_bout)+1,1) = CSp_bout(end,2)+1;
            % iti_bout(end, 2) = length(Behavior.Freezing.Vector);
            % iti_bout(end,:) = [];
            %
            % for kkk = 1:length(iti_bout)
            %     iti_length(kkk) = iti_bout(kkk,2) - iti_bout(kkk,1)+1;
            % end
            % to this: the old block made ITI_1 the pre-tone baseline and every
            % subsequent ITI_i the interval PRECEDING tone i, then deleted the
            % interval after the last tone - so the ITI columns were offset one
            % trial from the CSp columns (see the v4 changelog at the top).
            % ITI_i is now the interval FOLLOWING tone i, and ITI_N runs from
            % the end of the last tone to the end of the session (verified to
            % be a consistent 80 s window in every session). The pre-tone
            % baseline is kept separately rather than discarded:
            clear iti_bout iti_length
            n_tones = size(CSp_bout,1);
            iti_bout = zeros(n_tones,2);
            for iii = 1:n_tones-1
                iti_bout(iii,1) = CSp_bout(iii,2)+1;
                iti_bout(iii,2) = CSp_bout(iii+1,1)-1;
            end
            iti_bout(n_tones,1) = CSp_bout(end,2)+1;
            iti_bout(n_tones,2) = length(Behavior.Freezing.Vector);

            for kkk = 1:size(iti_bout,1)
                iti_length(kkk) = iti_bout(kkk,2) - iti_bout(kkk,1)+1;
            end

            % Pre-tone baseline window (what used to occupy the ITI_1 slot),
            % passed through so it is still reportable instead of lost.
            pretone_bout = [1, CSp_bout(1,1)-1];
            %

            % SV, August 24, 2026: I changed
            % for r = 1:length(roi_list)
            %     roi = char(roi_list(r));
            %     animal_id = ['DT_', roi];
            %     analyze_pma_roi(roi, animal_id, SpatialSource, Behavior, CSp_bout, CSp_on, CSp_off, iti_bout, iti_length, ...
            %         sample_rate, bin_size, iti_bin, threshold_plat, threshold_success, begin_win, finish_win, folder);
            % end
            % to this: Tracking (for the MidBack re-scoring) and pretone_bout
            % (for the preserved baseline window) now have to reach the per-ROI
            % analysis body:
            Tracking_S = load(fullfile(folder,'Tracking.mat'));

            % SV, August 27, 2026: I added - per-session sample rate, read
            % from this session's own Params.mat instead of the hardcoded
            % constant. See v5 changelog item 2.
            sample_rate_session = sample_rate_fallback;
            try
                Pm_sr = load(fullfile(folder,'Params.mat'));
                if isfield(Pm_sr.Params,'Video') && isfield(Pm_sr.Params.Video,'frameRate') ...
                        && isnumeric(Pm_sr.Params.Video.frameRate) && Pm_sr.Params.Video.frameRate > 0
                    sample_rate_session = Pm_sr.Params.Video.frameRate;
                else
                    warning('Params.Video.frameRate missing in %s - using fallback %.3f fps', folder, sample_rate_fallback);
                end
            catch
                warning('Could not read Params.mat in %s - using fallback %.3f fps', folder, sample_rate_fallback);
            end

            % Habituation? If so build merged tone+ITI epochs: epoch i runs
            % from the start of tone i to the end of the ITI that follows it.
            % Only well defined because v4 re-aligned ITI_i to FOLLOW tone i.
            is_hab = ismember(condition_name, hab_conditions);
            if is_hab
                merged_bout = [CSp_bout(:,1), iti_bout(:,2)];
            else
                merged_bout = [];
            end

            for r = 1:length(roi_list)
                roi = char(roi_list(r));
                animal_id = ['DT_', roi];
                analyze_pma_roi(roi, animal_id, SpatialSource, Behavior, CSp_bout, CSp_on, CSp_off, iti_bout, iti_length, ...
                    sample_rate_session, bin_size, iti_bin, threshold_plat, threshold_success, begin_win, finish_win, folder, ...
                    Tracking_S.Tracking, pretone_bout, merged_bout);
            end
            %
        catch ME
            warning('%s / %s failed, skipping: %s', condition_name, current_video, ME.message);
            failed_sessions(end+1,:) = {condition_name, current_video, ME.message}; %#ok<AGROW>
        end
    end
end

if isempty(failed_sessions)
    fprintf('\nAll %d session(s) across %d condition folder(s) processed successfully.\n', total_sessions, length(selected_conditions));
else
    fprintf('\n%d of %d session(s) failed:\n', size(failed_sessions,1), total_sessions);
    for f = 1:size(failed_sessions,1)
        fprintf('  %s / %s: %s\n', failed_sessions{f,1}, failed_sessions{f,2}, failed_sessions{f,3});
    end
end

%%
function analyze_pma_roi(roi, animal_id, SpatialSource, Behavior, CSp_bout, CSp_on, CSp_off, iti_bout, iti_length, ...
    sample_rate, bin_size, iti_bin, threshold_plat, threshold_success, begin_win, finish_win, folder, ...
    Tracking, pretone_bout, merged_bout)
% Unchanged from BehDEPOT_Analysis_SVv2.m - reproduces BehDEPOT_Analysis_v1_3.m's per-ROI
% analysis body exactly, parameterized by roi ('platform' or 'reward') instead of hardcoded
% text, so both ROI outputs can be generated from one Behavior(.mat/_Filter.mat) load instead
% of running the whole script twice with find/replace.
% SpatialSource is either Behavior_Filter.Spatial or Behavior.Spatial,
% whichever the calling session's export format provides - both expose
% the same SpatialSource.(roi).inROIvector shape.

% SV, August 24, 2026: I changed
% on_plat = SpatialSource.(roi).inROIvector';
% off_plat = ~(SpatialSource.(roi).inROIvector)';
% to this: the stored inROIvector was scored by whichever point the app's
% Metrics.Location happened to resolve to when that session was processed -
% MidBack for sessions run before 2026-07-22, Implant for sessions run after
% (see the v4 changelog at the top of this file for the measured impact).
% Recomputing it here from Tracking.Smooth.MidBack against the saved ROI
% polygon makes the scoring point identical for every session regardless of
% when it was analyzed. Verified 2026-08-24 to reproduce the stored vector
% EXACTLY (0 frames different) on every already-MidBack-scored session.
if ~isfield(Tracking, 'Smooth') || ~isfield(Tracking.Smooth, 'MidBack')
    error('Tracking.Smooth.MidBack not found - cannot re-score ROI membership for %s', roi);
end
midback = Tracking.Smooth.MidBack;

% ROI polygon: Behavior.Spatial.<roi>.ROI is the primary source. Sessions
% exported by the older zzfork app carry a Behavior_Filter.Spatial that has
% no .ROI field, so fall back to Params.roi/roi_names there. Both were
% confirmed to reproduce the stored inROIvector exactly.
roi_poly = [];
if isfield(Behavior, 'Spatial') && isfield(Behavior.Spatial, roi) ...
        && isfield(Behavior.Spatial.(roi), 'ROI')
    roi_poly = Behavior.Spatial.(roi).ROI;
else
    Pm = load(fullfile(folder,'Params.mat'));
    idx = find(strcmp(string(Pm.Params.roi_names), roi), 1);
    if isempty(idx)
        error('ROI polygon for "%s" not found in Behavior.Spatial or Params.roi_names', roi);
    end
    roi_poly = Pm.Params.roi{idx};
end

in_roi = inpolygon(midback(1,:), midback(2,:), roi_poly(:,1), roi_poly(:,2));
on_plat  = in_roi(:);   % column, matching the orientation the old code produced
off_plat = ~in_roi(:);
%
% SV, July 24, 2026: I changed
% intersect_CSp = CSp_on.*on_plat; %EventVector when the animal is on the ROI during the CSp
% intersect_iti = CSp_off.*on_plat; % EventVector when on ROI during iti
% freeze_onROI = SpatialSource.(roi).inROIvector.'.*Behavior.Freezing.Vector;
% to this: on_plat/off_plat are column vectors (transposed above) but CSp_on/CSp_off/
% Behavior.Freezing.Vector are row vectors, so "row .* column" was silently triggering MATLAB
% implicit expansion into a full 39364x39364 matrix instead of a per-frame elementwise AND.
% onPlatByCue(i,:) = intersect_CSp(CSp_bout(i,1):CSp_bout(i,2)) then linearly-indexed only into
% that matrix's FIRST COLUMN (since every bout frame number < 39364), which works out to
% CSp_on(1)*on_plat(:) - i.e. every CSp_plat_time/CSp_reward_time value was silently scaled by
% the single scalar CSp_on(1) (always 0, since frame 1 is before the first tone) instead of
% reflecting real per-frame on-ROI behavior. Confirmed by running this against real Behavior.mat:
% before this fix OnPlatPerOnPlat came out all-zero for every tone; after, it matches an
% independent mean(inROIvector(bout_start:bout_end)) recompute to within ~0.5%. Transposing
% on_plat/off_plat/inROIvector back to a row just for these three multiplications (not touching
% their column-oriented use elsewhere, e.g. calc_time_plat) keeps both operands 1xN so the
% multiplication is a plain elementwise AND again:
intersect_CSp = CSp_on.*on_plat.'; %EventVector when the animal is on the ROI during the CSp
intersect_iti = CSp_off.*on_plat.'; % EventVector when on ROI during iti
% SV, August 24, 2026: I changed
% freeze_onROI = SpatialSource.(roi).inROIvector.*Behavior.Freezing.Vector;
% to this, so "freezing while on the ROI" uses the same re-scored MidBack
% membership vector as everything else above rather than the stored one
% (in_roi is the row-oriented equivalent of the old inROIvector):
% SV, August 24, 2026: I added - Behavior.Freezing.Vector is forced to a row
% for the same reason CSp_on is above: in_roi is a row, so a column-oriented
% Freezing.Vector here would implicitly expand to an N x N matrix and quietly
% corrupt every freezing-on-ROI number the same way. Normalizing once rather
% than assuming an orientation.
freeze_vec = Behavior.Freezing.Vector(:).';
freeze_onROI = in_roi.*freeze_vec;
%
%
% SV, August 24, 2026: I changed
% freezeall = Behavior.Freezing.Vector;
% to this (use the row-normalized copy, same reason as above):
freezeall = freeze_vec;
%

for i = 1:length(iti_bout)
    % SV, July 24, 2026: I changed
    % iti_fraction80s(i) = mean(SpatialSource.(roi).inROIvector(iti_bout(i,1):iti_bout(i,1)+80*sample_rate));
    % to this: 80*sample_rate = 80*49.974 = 3997.92, a non-integer index bound that threw
    % "Integer operands are required for colon operator when used as index" on every session -
    % MATLAB tolerated it by auto-rounding, but floor() makes that explicit instead of implicit.
    % SV, August 24, 2026: I changed
    % iti_fraction80s(i) = mean(SpatialSource.(roi).inROIvector(iti_bout(i,1):iti_bout(i,1)+floor(80*sample_rate)));
    % to this: (a) use the re-scored MidBack vector like everything else, and
    % (b) clamp the window to the end of the ITI. Under v4's ITI definition
    % the final ITI is itself ~80 s, so the unclamped "+floor(80*sample_rate)"
    % could run one frame past the end of the session and throw:
    win_end = min(iti_bout(i,1)+floor(80*sample_rate), iti_bout(i,2));
    iti_fraction80s(i) = mean(in_roi(iti_bout(i,1):win_end));
    %
end
Analysis.ITI.Length = iti_length/sample_rate;
Analysis.ITI.first80 = iti_fraction80s;

% SV, August 24, 2026: I added - the pre-tone baseline window that used to
% occupy the ITI_1 slot before v4 re-aligned the ITIs to follow their tone.
% Kept here so the baseline is still available for reference rather than
% being silently dropped by the re-alignment.
Analysis.ITI.PreTone.Bout = pretone_bout;
Analysis.ITI.PreTone.Length = (pretone_bout(2)-pretone_bout(1)+1)/sample_rate;
Analysis.ITI.PreTone.OnPlatPer = mean(in_roi(pretone_bout(1):pretone_bout(2)));
%

% SV, August 24, 2026: I added - per-window locomotion (track length), for the
% new "locomotion" tab in pma_extractor_SVv7.m.
%
% Computed here from Tracking.Smooth.MidBack rather than read from
% Metrics.Movement.DistanceTraveled, for exactly the same reason the ROI
% membership is re-scored above: Metrics.Movement is derived from
% Metrics.Location, so it inherits the MidBack/Implant split (34 sessions
% MidBack, 21 Implant). Measured 2026-08-24, whole-session Implant path length
% runs 0.15x to 1.73x the MidBack path length for the same animal (median
% 0.83x) - a head-mounted point picks up head turns and rearing that the body
% centre doesn't - so using Metrics.Movement would reintroduce the identical
% group-confounded artifact into locomotion that v4 just removed from time-in-
% zone. Recomputing from MidBack keeps every session on one definition.
%
% Both distance (cm) and rate (cm/s) are stored per window. The rate is the
% comparable quantity: a tone window is ~30 s but an ITI window is ~107 s
% (3.6x longer), so raw distance totals are dominated by window duration.
% px2cm was verified to be 18 in all 55 sessions of this dataset, so cm are
% comparable across animals.
%
% This block is ROI-independent, so it computes the same numbers into both
% Analysis_DT_platform.mat and Analysis_DT_reward.mat. Left duplicated rather
% than special-cased: it's a handful of sums, and keeping every consumer able
% to read locomotion off whichever Analysis file it already loaded is simpler
% than introducing a separate output file.
Pm_loc = load(fullfile(folder,'Params.mat'));
if isfield(Pm_loc.Params,'px2cm') && isnumeric(Pm_loc.Params.px2cm) && Pm_loc.Params.px2cm > 0
    px2cm_loc = Pm_loc.Params.px2cm;
else
    px2cm_loc = NaN;
    warning('Params.px2cm missing or invalid in %s - locomotion will be NaN', folder);
end

% path length in cm between two frame indices (inclusive)
pathlen_cm = @(a,b) sum(sqrt(sum(diff(midback(:,a:b),1,2).^2,1))) / px2cm_loc;

n_tones_loc = size(CSp_bout,1);
csp_dist = nan(1,n_tones_loc); csp_dur = nan(1,n_tones_loc);
iti_dist = nan(1,n_tones_loc); iti_dur = nan(1,n_tones_loc);
for i_loc = 1:n_tones_loc
    csp_dist(i_loc) = pathlen_cm(CSp_bout(i_loc,1), CSp_bout(i_loc,2));
    csp_dur(i_loc)  = (CSp_bout(i_loc,2)-CSp_bout(i_loc,1)+1)/sample_rate;
    iti_dist(i_loc) = pathlen_cm(iti_bout(i_loc,1), iti_bout(i_loc,2));
    iti_dur(i_loc)  = (iti_bout(i_loc,2)-iti_bout(i_loc,1)+1)/sample_rate;
end

Analysis.Locomotion.Source   = 'Tracking.Smooth.MidBack';
Analysis.Locomotion.Units    = 'Dist_cm = path length in cm; Rate_cmps = Dist_cm / Dur_s';
Analysis.Locomotion.px2cm    = px2cm_loc;

Analysis.Locomotion.BL.Dist_cm   = pathlen_cm(pretone_bout(1), pretone_bout(2));
Analysis.Locomotion.BL.Dur_s     = (pretone_bout(2)-pretone_bout(1)+1)/sample_rate;
Analysis.Locomotion.BL.Rate_cmps = Analysis.Locomotion.BL.Dist_cm / Analysis.Locomotion.BL.Dur_s;

Analysis.Locomotion.CSp.Dist_cm   = csp_dist;
Analysis.Locomotion.CSp.Dur_s     = csp_dur;
Analysis.Locomotion.CSp.Rate_cmps = csp_dist ./ csp_dur;

Analysis.Locomotion.ITI.Dist_cm   = iti_dist;
Analysis.Locomotion.ITI.Dur_s     = iti_dur;
Analysis.Locomotion.ITI.Rate_cmps = iti_dist ./ iti_dur;
%

% SV, August 27, 2026: I added - MERGED TONE+ITI EPOCHS (habituation only).
%
% For habituation sessions the tone never actually played (speaker muted),
% so tone-vs-ITI is not a real contrast and the useful unit is the whole
% trial cycle. merged_bout(i,:) = [start of tone i, end of the ITI that
% follows it], which after the v4 ITI re-alignment tiles the session exactly
% once the pre-tone baseline is set aside.
%
% Everything here is computed ON the merged window. It is deliberately NOT
% derived by averaging the CSp and ITI columns above: the tone is ~30 s and
% the ITI ~80 s, so an unweighted mean of the two would overweight the tone
% by roughly 2.7x.
%
% on_plat is the re-scored MidBack in-ROI vector built earlier in this
% function, so these inherit the same single scoring point as every other
% zone metric. Empty merged_bout (non-habituation) leaves Analysis.Merged
% unwritten, so v4 consumers see no change.
if ~isempty(merged_bout)
    n_merged = size(merged_bout,1);

    merged_perTime  = nan(1,n_merged);   % fraction of epoch spent in the ROI
    merged_visits   = nan(1,n_merged);   % number of separate entries into the ROI
    merged_latency  = nan(1,n_merged);   % s from epoch start to first entry (NaN = never)
    merged_dist     = nan(1,n_merged);
    merged_dur      = nan(1,n_merged);

    on_plat_row = on_plat(:).';          % on_plat is a column; work in rows here

    for i_m = 1:n_merged
        a = merged_bout(i_m,1);
        b = merged_bout(i_m,2);
        seg = on_plat_row(a:b);

        merged_perTime(i_m) = mean(seg);

        % entries = rising edges, counting an epoch that starts already
        % inside the ROI as one entry at frame 1
        d_seg = diff([0 seg]);
        merged_visits(i_m) = sum(d_seg == 1);

        first_in = find(seg, 1, 'first');
        if isempty(first_in)
            merged_latency(i_m) = NaN;
        else
            merged_latency(i_m) = (first_in - 1) / sample_rate;
        end

        merged_dist(i_m) = pathlen_cm(a, b);
        merged_dur(i_m)  = (b - a + 1) / sample_rate;
    end

    Analysis.Merged.Definition   = 'epoch i = [CSp_bout(i,1) .. iti_bout(i,2)], i.e. tone i plus the ITI following it';
    Analysis.Merged.Bouts        = merged_bout;
    Analysis.Merged.PerTimeInROI = merged_perTime;
    Analysis.Merged.Visits       = merged_visits;
    Analysis.Merged.Latency_s    = merged_latency;
    Analysis.Merged.Dist_cm      = merged_dist;
    Analysis.Merged.Dur_s        = merged_dur;
    Analysis.Merged.Rate_cmps    = merged_dist ./ merged_dur;

    % Pre-tone baseline, reported separately and never pooled into a bin so
    % it stays usable as the reference the learning curve is measured against.
    bl_a = pretone_bout(1);
    bl_b = pretone_bout(2);
    bl_seg = on_plat_row(bl_a:bl_b);
    bl_first = find(bl_seg, 1, 'first');
    Analysis.Merged.BL.PerTimeInROI = mean(bl_seg);
    Analysis.Merged.BL.Visits       = sum(diff([0 bl_seg]) == 1);
    if isempty(bl_first)
        Analysis.Merged.BL.Latency_s = NaN;
    else
        Analysis.Merged.BL.Latency_s = (bl_first - 1) / sample_rate;
    end
    Analysis.Merged.BL.Dist_cm   = pathlen_cm(bl_a, bl_b);
    Analysis.Merged.BL.Dur_s     = (bl_b - bl_a + 1) / sample_rate;
    Analysis.Merged.BL.Rate_cmps = Analysis.Merged.BL.Dist_cm / Analysis.Merged.BL.Dur_s;
end
%

% Latency to go ON the ROI during CSp bouts & duration on ROI
[latency_CSp_on_plat, CSp_frames_on_plat] = calc_time_plat(on_plat,CSp_bout,sample_rate);

if isempty(CSp_frames_on_plat) == 0
    CSp_avg_bout_on=boutavg(CSp_frames_on_plat, CSp_bout);
    Analysis.CSp.AvgDurOn = CSp_avg_bout_on;
end

Analysis.CSp.LatencyOnPlat = latency_CSp_on_plat;
Analysis.CSp.DurOnPlat = CSp_frames_on_plat;

% Calculates when the mouse was ON the ROI during the ITI period
[latency_iti_on_plat, iti_frames_on_plat] = calc_time_plat(on_plat,iti_bout,sample_rate);

Analysis.ITI.LatencyOnPlat = latency_iti_on_plat;
Analysis.ITI.DurOnPlat = iti_frames_on_plat;

% Latency to EXIT (OFF) the ROI after each CSp (during ITI) and duration of time off the
% ROI during ITI (DOESN'T INCLUDE TIME AFTER LAST CSp)
[latency_iti_off_plat, iti_frames_off_plat] = calc_time_plat(off_plat,iti_bout,sample_rate);

if isempty(iti_frames_off_plat) == 0
    iti_avg_bout_off=boutavg(iti_frames_off_plat, iti_bout);
    Analysis.ITI.DurOffPlat = iti_frames_off_plat(:,3:4);
    Analysis.ITI.AvgDurOn = iti_avg_bout_off;
end

Analysis.ITI.LatencyOffPlat = latency_iti_off_plat;

% Combines ITI and CSp time on ROI into one matrix
new_CSp = [CSp_frames_on_plat, ones(size(CSp_frames_on_plat,1),1)];
new_iti = [iti_frames_on_plat, zeros(size(iti_frames_on_plat,1),1)];
combined = [new_iti;new_CSp];
sorted_combined = sortrows(combined);

% Divides time during CSp or ITI into bins to calculate how much time they
% spent on the ROI for each
% THRESHOLD IS LOW = 0.1
for i = 1:length(CSp_bout)
    onPlatByCue(i,:) = intersect_CSp(CSp_bout(i,1):CSp_bout(i,2));
end

bout_time= (CSp_bout(1,2)-CSp_bout(1,1))/sample_rate;
% SV, July 24, 2026: I changed
% bin_frames = ((CSp_bout(1,2)-CSp_bout(1,1))*bin_size)/bout_time; %calc # of frames in bin_size
% to this: bin_frames algebraically simplifies to bin_size*sample_rate (e.g. 5*49.974 =
% 249.87), a non-integer, which crashed the "1+(k-1)*bin_frames:k*bin_frames" indexing below
% with "Array indices must be positive integers or logical values" on every k>1 for every
% session - confirmed by running this exact line against DCSP_19_tms_RetrS1's real Behavior.mat.
% floor() matches what the ITI version of this same calculation already does correctly below.
bin_frames = floor(((CSp_bout(1,2)-CSp_bout(1,1))*bin_size)/bout_time); %calc # of frames in bin_size
%

PerBinsOnPlatCue = zeros(length(CSp_bout),floor(bout_time/bin_size));
for j = 1:length(CSp_bout)
    for k = 1:floor(bout_time/bin_size)
        data_bin(k) = sum(onPlatByCue(j,1+(k-1)*bin_frames:k*bin_frames));
        fractionON = data_bin(k)/bin_frames;
        PerBinsOnPlatCue(j,k) = fractionON;
        if(fractionON)>threshold_plat
            threshON(j,k)=1;
        else
            threshON(j,k)=0;
        end
    end
end

for iii = 1:length(iti_bout)
    temp_iti_frames = iti_bout(iii,2)-iti_bout(iii,1);
    iti_frames = floor(temp_iti_frames/iti_bin);
    % SV, July 24, 2026: I changed
    % OnPlatByITIbin(1,:) = on_plat(iti_bout(iii,1):iti_bout(iii,1)+iti_frames);
    % ...
    % OnPlatByITIbin(1+jjj,:) = on_plat(start+(jjj*iti_frames)+1:start+(jjj*iti_frames)+1+iti_frames);
    % to this: both ranges were inclusive-inclusive, giving iti_frames+1 samples per bin, but
    % "sum_ITIbin = sum(OnPlatByITIbin,2)/iti_frames" below divides by iti_frames (one less than
    % the actual sample count) - so a bin the animal spent 100% on the ROI summed to iti_frames+1,
    % divided by iti_frames, coming out slightly ABOVE 1.0 (confirmed in real output: values like
    % 1.0015 for ITI_plat_time, which is impossible for a true fraction). Trimming each range to
    % exactly iti_frames samples fixes the numerator/denominator mismatch.
    for jjj = 1:iti_bin-1
        OnPlatByITIbin(1,:) = on_plat(iti_bout(iii,1):iti_bout(iii,1)+iti_frames-1);
        start = iti_bout(iii,1);
        OnPlatByITIbin(1+jjj,:) = on_plat(start+(jjj*iti_frames)+1:start+(jjj*iti_frames)+iti_frames);
    end
    %
    sum_ITIbin = sum(OnPlatByITIbin,2)/iti_frames;
    PerBinsOnPlatITI(iii,:) = sum_ITIbin';
    clear OnPlatByITIbin
end

OnPlatPerOnPlat = [];
for iii = 1:size(PerBinsOnPlatCue,1)
    OnPlatPerOnPlat(iii) = mean(PerBinsOnPlatCue(iii,:));
end

ITI_PerOnPlat = [];
for iii = 1:size(PerBinsOnPlatITI,1)
    ITI_PerOnPlat(iii) = mean(PerBinsOnPlatITI(iii,:));
end

Analysis.CSp.OnPlatPerOnPlat = OnPlatPerOnPlat;
Analysis.ITI.OnPlatPer = ITI_PerOnPlat;
Analysis.CSp.OnPlatBins.PerOnPlatCue = PerBinsOnPlatCue;
Analysis.ITI.OnPlatBins.PerOnPlatITI = PerBinsOnPlatITI;
Analysis.All_plat_ent = sorted_combined;

% INDIVIDUAL Animal Freezing on ROI Assesment with Temporal Binning
FreezeonPlatByCue = zeros(length(CSp_bout),(CSp_bout(1,2)-CSp_bout(1,1)+1));

for i = 1:length(CSp_bout)
    FreezeonPlatByCue(i,:) = freeze_onROI(CSp_bout(i,1):CSp_bout(i,2));
    PerFreezeonROICSp(i) = sum(FreezeonPlatByCue(i,:))/length(FreezeonPlatByCue(i,:));
end

for i = 1:length(CSp_bout)
    FreezeByCue(i,:) = freezeall(CSp_bout(i,1):CSp_bout(i,2));
    PerFreezeByCue(i) = sum(FreezeByCue(i,:))/length(FreezeByCue(i,:));
end

bout_time= (CSp_bout(1,2)-CSp_bout(1,1))/sample_rate;
% SV, July 24, 2026: I changed
% bin_frames = ((CSp_bout(1,2)-CSp_bout(1,1))*bin_size)/bout_time;
% to this (same non-integer indexing crash as the OnPlat binning above, same fix):
bin_frames = floor(((CSp_bout(1,2)-CSp_bout(1,1))*bin_size)/bout_time);
%

PerFreezeonROICSpPerBin = zeros(length(CSp_bout),floor(bout_time/bin_size));
for j = 1:length(CSp_bout)
    for k = 1:floor(bout_time/bin_size)
        data_bin(k) = sum(FreezeonPlatByCue(j,1+(k-1)*bin_frames:k*bin_frames));
        fractionON = data_bin(k)/bin_frames;
        PerFreezeonROICSpPerBin(j,k) = fractionON;
        threshON_freeze(j,k)=1;
        threshON_freeze(j,k)=0;
    end
end

for iii = 1:length(iti_bout)
    temp_iti_frames = iti_bout(iii,2)-iti_bout(iii,1);
    iti_frames = floor(temp_iti_frames/iti_bin);
    % SV, July 24, 2026: I changed
    % FreezeByITIbin(1,:) = freezeall(iti_bout(iii,1):iti_bout(iii,1)+iti_frames);
    % ...
    % FreezeByITIbin(1+jjj,:) = freezeall(start+(jjj*iti_frames)+1:start+(jjj*iti_frames)+1+iti_frames);
    % to this: same off-by-one as the OnPlatByITIbin fix above (PerBinsFreezeITI itself isn't
    % currently saved to Analysis/used anywhere, but fixed for consistency since it's the same bug):
    for jjj = 1:iti_bin-1
        FreezeByITIbin(1,:) = freezeall(iti_bout(iii,1):iti_bout(iii,1)+iti_frames-1);
        start = iti_bout(iii,1);
        FreezeByITIbin(1+jjj,:) = freezeall(start+(jjj*iti_frames)+1:start+(jjj*iti_frames)+iti_frames);
    end
    %
    sum_ITIbin = sum(FreezeByITIbin,2)/iti_frames;
    PerBinsFreezeITI(iii,:) = sum_ITIbin';
    clear FreezeByITIbin
end

Analysis.CSp.FreezingPerFreeze = PerFreezeByCue;
Analysis.CSp.FreezingOnPlatPerFreeze = PerFreezeonROICSp;
Analysis.CSp.FreezingOnPlatBins.PerOnPlatCue = PerFreezeonROICSpPerBin;

% Boolean EventVector looking at whether animal is on ROI during the last 2s cue bout
end_threshON = [];

% SV, July 24, 2026: I changed
% start_frame = length(onPlatByCue)-(sample_rate*begin_win);
% finish_frame = length(onPlatByCue)-(sample_rate*finish_win)-1;
% to this: sample_rate*begin_win (49.974) and sample_rate*finish_win (24.987) are both
% non-integer, so start_frame/finish_frame were non-integer index bounds, same warning as the
% iti_fraction80s fix above. floor() makes the rounding explicit.
start_frame = length(onPlatByCue)-floor(sample_rate*begin_win);
finish_frame = length(onPlatByCue)-floor(sample_rate*finish_win)-1;
%

for j = 1:length(CSp_bout)
    data_end = sum(onPlatByCue(j,start_frame:finish_frame));
    fractionON_end = data_end/(finish_frame-start_frame);
   if(fractionON_end)>threshold_success
        end_threshON(j)=1;
   else
        end_threshON(j)=0;
   end
end

Analysis.CSp.OnPlatSuccessfulTrial = end_threshON;

% SV, August 24, 2026: I added - provenance stamp, so any downstream consumer
% (or a future audit) can tell at a glance which body point scored this file
% and which ITI convention it used, instead of having to infer it from the
% file's modified date the way the 2026-08-24 audit had to.
Analysis.Provenance.ScoringPoint = 'Tracking.Smooth.MidBack';
Analysis.Provenance.LocomotionSource = 'Tracking.Smooth.MidBack (NOT Metrics.Movement)';
Analysis.Provenance.ITIConvention = 'ITI_i = interval FOLLOWING tone i; ITI_N runs to end of session';
Analysis.Provenance.Script = 'BehDEPOT_Analysis_SVv4.m';
Analysis.Provenance.RunDate = datestr(now,'yyyy-mm-dd HH:MM:SS');
%

assignin('base',['Analysis_',animal_id],Analysis);
filename = ['Analysis_',animal_id,'.mat'];
save(fullfile(folder,filename),'Analysis');

% Plot: fraction of time on ROI across the whole session with CSp bouts highlighted
exp_time = length(on_plat)/sample_rate;
bin_frames = floor((length(on_plat)*bin_size)/exp_time);

for iii = 1:floor(exp_time/bin_size)
    data_bin(iii) = sum(on_plat(1+(iii-1)*bin_frames:iii*bin_frames));
    FractionON = data_bin(iii)/bin_frames;
    FracOnPlatBin(iii) = FractionON;
end

CSp_bout_sec=CSp_bout./sample_rate;
CSp_bout_bin=CSp_bout_sec./bin_size;

fig_onplat = figure('Visible','off');clf;
area(1:length(FracOnPlatBin),FracOnPlatBin,'FaceAlpha',.8);
hold on;
ylim([0,1.1]);
for iii=1:length(CSp_bout_bin)
    rectangle('Position',[CSp_bout_bin(iii,1),0,CSp_bout_bin(iii,2)-CSp_bout_bin(iii,1),1.1],'FaceColor',[1,0,0,.3],'EdgeColor','none');
end
title(['Fraction time on ', roi, ' in 5s bins']);xlabel('Time (min)');ylabel(['Fraction time on ', roi]);
xticks = get(gca,'xtick');
scaling  = 5/60;
newlabels = arrayfun(@(x) sprintf('%.1f', scaling * x), xticks, 'un', 0);
set(gca,'xticklabel',newlabels);

heatmap_onplat = figure('Visible','off');clf;heatmap(PerBinsOnPlatCue,'CellLabelColor','none')
colormap parula
grid off
title([animal_id,': Avg time on ', roi, ' during Cue']);
xlabel('Bin');ylabel('Cue')

heatmap_onplat_iti = figure('Visible','off');clf;heatmap(PerBinsOnPlatITI,'CellLabelColor','none')
colormap parula
grid off
title([animal_id,': Avg time on ', roi, ' during ITI']);
xlabel('Bin');ylabel('ITI')

fig_filename = ['On_',roi,'_',animal_id,'.fig'];
saveas(fig_onplat, fullfile(folder,fig_filename));

fig_filename = ['Heat_On_',roi,'_Cue_',animal_id,'.fig'];
saveas(heatmap_onplat, fullfile(folder,fig_filename));

fig_filename = ['Heat_On_',roi,'_ITI_',animal_id,'.fig'];
saveas(heatmap_onplat_iti, fullfile(folder,fig_filename));

close(fig_onplat); close(heatmap_onplat); close(heatmap_onplat_iti);

end

%%
function video_folder_list = prepBatch(video_directory)
% Unchanged from v2 - lists the immediate subfolders of video_directory (used here to list
% the session folders within a single, already-selected condition folder).
cd(video_directory)
directory_contents = dir;
directory_contents(1:2) = [];
ii = 0;

for i = 1:size(directory_contents, 1)
current_structure = directory_contents(i);
if current_structure.isdir
ii = ii + 1;
video_folder_list(ii) = string(current_structure.name);
disp([num2str(i) ' directory loaded'])
end
end
end

%%
function folders = list_subfolders(root_dir)
% New in v3 - lists the immediate subfolders of root_dir (used to list the condition
% folders within the higher-level root directory, for the checkbox selection window).
cd(root_dir)
d = dir;
d(1:2) = [];
folders = strings(0);
for i = 1:numel(d)
    if d(i).isdir
        folders(end+1) = string(d(i).name); %#ok<AGROW>
    end
end
end

%%
function selected = select_folders_gui(folder_list)
% New in v3 - shows a checkbox list of folder_list (all checked by default) with
% "Check All" / "Uncheck All" / "Run" buttons. Returns the string array of folder names
% left checked when "Run" is clicked, or an empty string array if the window is closed
% without clicking Run.

n = numel(folder_list);
row_h = 24;
list_h = n * row_h + 10;
fig_h = min(650, 140 + list_h);
fig_w = 420;

fig = uifigure('Name', 'Select condition folders to analyze', 'Position', [100 100 fig_w fig_h]);
fig.UserData.ran = false;
fig.CloseRequestFcn = @(src, ~) uiresume(src);

uilabel(fig, 'Text', 'Select folders to include:', ...
    'Position', [20 fig_h-30 fig_w-40 20], 'FontWeight', 'bold');

panel = uipanel(fig, 'Position', [20 90 fig_w-40 fig_h-130], 'Scrollable', 'on');
cb = gobjects(n, 1);
for i = 1:n
    cb(i) = uicheckbox(panel, 'Text', folder_list(i), 'Value', true, ...
        'Position', [10, list_h - i*row_h, fig_w-80, row_h]);
end

uibutton(fig, 'Text', 'Check All', 'Position', [20 40 110 30], ...
    'ButtonPushedFcn', @(~, ~) setCheckboxes(cb, true));
uibutton(fig, 'Text', 'Uncheck All', 'Position', [150 40 110 30], ...
    'ButtonPushedFcn', @(~, ~) setCheckboxes(cb, false));
uibutton(fig, 'Text', 'Run', 'Position', [fig_w-130 40 110 30], ...
    'BackgroundColor', [0.2 0.7 0.3], 'FontColor', [1 1 1], ...
    'ButtonPushedFcn', @(~, ~) markRun(fig));

uiwait(fig);

selected = strings(0);
if isvalid(fig)
    if fig.UserData.ran
        for i = 1:n
            if cb(i).Value
                selected(end+1) = folder_list(i); %#ok<AGROW>
            end
        end
    end
    delete(fig);
end

    function setCheckboxes(cb, val)
        for k = 1:numel(cb)
            cb(k).Value = val;
        end
    end

    function markRun(fig)
        fig.UserData.ran = true;
        uiresume(fig);
    end
end


function selected = select_habituation_gui(folder_list)
% SV, August 27, 2026: I added. Same checkbox pattern as select_folders_gui,
% but the default state of each box is "is this name a habituation folder?"
% rather than all-checked, so for the usual HabD1/HabD2/HabD3 batch the whole
% dialog is one click on Run. Returns the checked folder names.

n = numel(folder_list);
row_h = 24;
list_h = n * row_h + 10;
fig_h = min(650, 160 + list_h);
fig_w = 460;

fig = uifigure('Name', 'Which folders are HABITUATION sessions?', 'Position', [120 120 fig_w fig_h]);
fig.UserData.ran = false;
fig.CloseRequestFcn = @(src, ~) uiresume(src);

uilabel(fig, 'Text', 'Check any folder whose tones never actually played:', ...
    'Position', [20 fig_h-30 fig_w-40 20], 'FontWeight', 'bold');
uilabel(fig, 'Text', 'These get merged tone+ITI epochs. Names containing "Hab" are pre-checked.', ...
    'Position', [20 fig_h-52 fig_w-40 20]);

panel = uipanel(fig, 'Position', [20 90 fig_w-40 fig_h-150], 'Scrollable', 'on');
cb = gobjects(n, 1);
for i = 1:n
    is_hab_guess = contains(folder_list(i), 'hab', 'IgnoreCase', true);
    cb(i) = uicheckbox(panel, 'Text', folder_list(i), 'Value', is_hab_guess, ...
        'Position', [10, list_h - i*row_h, fig_w-80, row_h]);
end

uibutton(fig, 'Text', 'Check All', 'Position', [20 40 110 30], ...
    'ButtonPushedFcn', @(~, ~) arrayfun(@(h) set(h, 'Value', true), cb));
uibutton(fig, 'Text', 'Uncheck All', 'Position', [150 40 110 30], ...
    'ButtonPushedFcn', @(~, ~) arrayfun(@(h) set(h, 'Value', false), cb));
uibutton(fig, 'Text', 'Run', 'Position', [fig_w-130 40 110 30], ...
    'ButtonPushedFcn', @(~, ~) confirmRun(fig));

uiwait(fig);

if isvalid(fig) && fig.UserData.ran
    % logical(): arrayfun returns a double array, and indexing a string
    % array with 0/1 doubles errors (0 is not a valid index).
    keep = logical(arrayfun(@(h) h.Value, cb));
    selected = string(folder_list(keep));
    delete(fig);
else
    % Window closed without Run: treat as "nothing is habituation" rather
    % than aborting, since that is the harmless default.
    selected = string.empty;
    if isvalid(fig)
        delete(fig);
    end
end

    function confirmRun(f)
        f.UserData.ran = true;
        uiresume(f);
    end
end
