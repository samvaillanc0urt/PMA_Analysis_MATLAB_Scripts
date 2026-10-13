%% Sam Vaillancourt, September 28, 2026. Changes made in place to v12:
%
% (Not bumped to v13 - v12 was edited directly.) Nothing below changes a
% number in the workbook - these are output
% options, color, and the figure report's layout and wording.
%
%  1) GROUP COLOR PICKER. Two dropdowns (Sham / TMS) at the bottom of the
%     condition-folder window, each item filled with its own color, with a
%     swatch beside it. Choices, in rainbow order: Shock Red, SST Orange,
%     PV Yellow, CORT Green, UCLA Blue, IT Blue, PT Purple, Cajal Brown,
%     Control Grey. Defaults, per SV: Control Grey Sham, UCLA Blue TMS - so
%     the default report is now BLUE. Pick Shock Red to get the earlier red
%     look back exactly (workbook gradients and icons included).
%     Headless: PX_colors = struct('tms', "Shock Red") (palette name or
%     [R G B] 0-255; unset groups keep their default).
%     The pick drives EVERY group-colored thing: report lines, bars, bands,
%     markers, tick labels and legend text; the Activity Map titles; the
%     workbook's Color Scale gradients, label fills and chart colors; and
%     the epoch icons (speaker / arena artwork). The icons are drawn in
%     accent red CC4125; report_recolor_icon unmixes each pixel into white +
%     accent and re-mixes the accent with the picked TMS color, so linework,
%     pale fill and anti-aliasing carry over. Colors live in group_palette
%     (edit RGB there) and are read through group_color. SST Orange is the
%     meansemplot_SVv1.m value; the rest were read off SV's swatches by eye.
%     The yellow shock bolt is not a group color and is unchanged.
%
%  2) FOUR-GROUP ZONE ROWS SCALE THEIR TEXT. A 9-tone PVFP day shows the 1-9
%     aggregate plus 1-3/4-6/7-9 (DCSP: 1-6 plus 1-3/4-6). The panel layout
%     already derived from the bin list, but fonts and icons were sized for
%     three groups, so on PVFP the "Tones ON"/"Platform" labels ran into
%     their icons and the data. report_zone_blocks now passes a row scale
%     (aggregate width / three-group width: 1 for DCSP, ~0.78 for PVFP) that
%     multiplies every font and icon size in report_panel_paired.
%
%  3) STATS PAGE QUOTES THE REAL DESIGN. It said "n = 7 per group" and
%     "12 tests on a 6-day, 2-bin panel" whatever the data were (DCSP is
%     6 v 4 animals, PVFP 3 v 3 over 7 days x 3 bins). Both now come from
%     the rows being plotted.
%
%  4) A CONDITION FOLDER THAT IS NEITHER sham_ NOR tms_ IS EXCLUDED, per SV.
%     It used to be counted as Sham with only a warning. The test is now the
%     name PREFIX (condition_group), not a substring - "contains 'sham'"
%     would have called PVFP_TmsSham_SV_Aug25_photometry Sham. The GUI lists
%     such folders greyed out with no checkbox; headless drops them from
%     PX_conds with a warning; classify_group errors if one ever gets past.
%
%  5) REMOVED ~970 LINES OF DEAD CODE: write_locomotion_tab_superseded,
%     _superseded_v2, _superseded_v3 and the two
%     build_loco_barline_chart_superseded* helpers. Nothing called any of
%     them (the live tab is write_locomotion_tab), so no output changes for
%     either cohort. They are still in out_of_date\pma_extractor_SVv11.m.
%
%  6) CLEARER ERROR WHEN EVERY ANIMAL IS EXCLUDED. Ticking every subject in
%     the exclusion dialog ("Select All" there EXCLUDES) used to stop with
%     "No real session folders found", which pointed at missing data. It now
%     says every session was excluded and which subjects.
%
%  7) FIGURE REPORT LAYOUT, after SV's review of the first PVFP report:
%     - Shocks Avoided never shows habituation days (no shocks on them).
%     - Timecourse bin tick labels (1-3/4-6/7-9) shrink to the room each tick
%       has, so they no longer run together on 7 days x 3 bins.
%     - All four Velocity panels share one y-axis (report_shared_ylim);
%       velocity summarises as a mean, so one scale fits all. Track length
%       keeps separate scales (its summary is a day total).
%     - Proportion of Time in Zone and Zone Visits: their four timecourse +
%       summary rows fit on one page (S.metric_scale = 0.87).
%     - Zone comparison rows are shorter, so four rows (two days) fit a page,
%       and the Sham/Tms line sits half as far below the tick labels.
%
%  8) NO NEGATIVE FLOOR ON COUNT AXES. Zone Visits panels autoscale, and a
%     small mean with a large SE pushed the y-axis down to -0.5 (present since
%     the report was added, not from the layout changes). Counts and
%     proportions cannot be negative, so the floor is now 0 plus the usual
%     small pad, on the zone comparison panels and the timecourses alike.
%
%  9) SPEED: ICONS ARE CACHED. report_half_label re-read the 1200x1200 icon
%     PNG on every call (~450 per report) and, once the default TMS color
%     became UCLA Blue, recolored all 1.44 M pixels every call as well:
%     measured 74 ms per icon vs 20 ms, ~33 s per report. Each file is now
%     read + recolored once per file and color (8 files), as report_icon
%     already did - faster than before the recoloring existed.
%
% Verified 2026-09-28 by a headless run over all 14 condition folders of
% E:\2026-08-20_PVcre.Fp_PMA_TMS (42 sessions, none failed) with TMS set to
% UCLA Blue, plus the dialog driven from a timer to check the dropdowns,
% plus a default-color run with PVFP_TmsSham_SV_Aug25_photometry passed in
% (excluded as intended; workbook colors identical to the pre-picker ones).
%
% ---------------------------------------------------------------------
%% v10-v12 history (written 2026-09-28 by diffing out_of_date\pma_extractor_
%% SVv9/v10/v11.m against this file - none of the three had a header entry):
%
% v10 (Sept 25, 14:46) from v9:
%  - FIGURE REPORT PDF (new, pma_report_<timestamp>.pdf), from SV's
%    hand-drawn spec: Shocks Avoided, Locomotion, Proportion of Time in
%    Zone, Zone Visits. Timecourse + summary panel per metric.
%  - Output-selection checkboxes in the condition window (Freezing Map PDF,
%    figure report + its four sections); headless equivalent PX_report.
%
% v11 (Sept 25, 15:06) from v10:
%  - Condition folders with no Analysis_DT_platform/reward.mat are listed
%    greyed out with no checkbox (scan_condition_eligibility); headless
%    warns about them instead.
%
% v12 (Sept 25 afternoon - Sept 27) from v11 - see the dated "SV, September
% 25/27" notes at each site for the reasoning:
%  - Figure report second round after SV's review: black non-data text,
%    TMS-only red, [0 1] proportion axes, a line style + marker per animal,
%    one timecourse + one summary per row, new pages per section, per-day
%    zone blocks under a day banner; tone-bin panels as a scaled copy of the
%    aggregate; reward preference for tones ON and OFF.
%  - SV's epoch icons (E:\Data_Graphics\PMA epoch icons) replace the
%    placeholder squares.
%  - Report statistics: panel stars are Sham v Tms Wilcoxon RANK-SUM per day
%    x bin, Holm-corrected together within the panel (the workbook's stats
%    tab still stars from the Holm t-test); value ~ group*day + (1|animal)
%    per metric (report_fit_lme), on a final page explaining every test.
%  - Summary bars: additive metrics (track length, visits) show the day
%    total, rates and proportions the mean ("agg").
%  - Freezing Map PDF -> Activity Map PDF: Letter pages, several animals per
%    page; excluded animals still get a row, marked "(EXCLUDED)".
%
% Also in v9 but missing from its header: the degenerate-session warning
% (a session with under half the tones of the best session that day), and
% TrainD1s3/TrainD2s3 dropped from the DCSP day list.
%
% ---------------------------------------------------------------------
%% Sam Vaillancourt, September 25, 2026. v9 changes from v8/PVFP:
%
% v9 makes this script cohort-agnostic. v7 (DCSP) and v8 (PVFP) were forks of
% each other that differed in three constants; v9 detects which layout the
% selected condition folders use and sets those three itself, so one file
% runs both cohorts. Nothing else changed - a PVFP run produces the same
% workbook v8 did, tab for tab. Dropped the "_PVFP" suffix from the filename
% for the same reason: it is no longer a per-cohort file.
%
%  1) SESSION LAYOUT DETECTION (new block, just after the condition-folder
%     selection). Compares the day names of the selected folders against both
%     canonical day lists and picks the better match, before any session is
%     read - max_tones has to be settled before the row loop pads anything.
%     session_layout_override at the top forces "dcsp" or "pvfp" if the guess
%     is ever wrong; an unrecognisable selection warns and falls back to
%     "pvfp" (v8's behaviour) rather than guessing quietly. The three things
%     it selects:
%       day_order     - PVFP: HabD1-3/TrainD1-3/Retr, one session per day.
%                       DCSP: the s1/s2 sub-session names, v7's list plus the
%                       TrainD1s3/TrainD2s3 entries that exist on disk.
%       max_tones     - 9 (PVFP) or 6 (DCSP).
%       success_bin_ranges/labels - PVFP 1-3/4-6/7-9/1-9; DCSP 1-3/4-6/1-6,
%                       because six tones hold only two terciles and the
%                       whole-session aggregate is "1-6", not "1-9".
%     DCSP tone counts verified 2026-09-25 by counting rows in every
%     csp_cue_frames.csv across the 12 Train/Retr condition folders of
%     E:\2026-02-01_Fp.SST.PV_TMS_PMA_SV: 51 sessions at 6 tones, 17 at 5,
%     15 at 4, none above 6.
%
%  2) THE FOUR zone_time_prop_* TABS ARE NOW BUILT FROM THE BIN LIST rather
%     than hardcoded as 1-9/1-3/4-6/7-9. On DCSP the old code would have
%     written a guaranteed-empty "7-9" tab and labelled the aggregate "1-9"
%     when it is really "1-6". PVFP output is unchanged: same tabs, same
%     names, same left-to-right order (aggregate first).
%
%  3) THE GLMM'S EXCLUSIVE BIN PARTITION IS COMPUTED, NOT HARDCODED. v8
%     passed success_bin_ranges(1:3); that "3" silently assumed the PVFP bin
%     list. v9 keeps the leading bins that introduce no already-counted tone,
%     which gives (1:3) for PVFP and (1:2) for DCSP, and makes the
%     double-counting hazard documented at success_bin_ranges self-enforcing.
%
%  4) NOT CHANGED, because they already handle both layouts: parse_subject
%     (matches DCSP or PVFP since v8), day_from_condition (strips the
%     sham_/tms_ prefix, suffix-agnostic), classify_group, and every
%     startsWith(day,'Hab') / contains(day,'Train') day-type test - those are
%     prefix/substring tests, so "TrainD1s1" behaves exactly like "TrainD1".
%     The hab_reward_rate tab is still uncalled (v8 removed the call); a DCSP
%     run with no Hab folders selected simply has no Hab rows.
%
% ---------------------------------------------------------------------
%% Sam Vaillancourt, September 3, 2026. v8/PVFP changes from v7:
%
% Forked from pma_extractor_SVv7.m for the new PVFP cohort
% (E:\2026-08-20_PVcre.Fp_PMA_TMS and onward), whose task structure and
% output format differ from the DCSP-cohort data every earlier version of
% this script was written against. v7 is left untouched for re-running old
% DCSP-cohort batches; use this file (SVv8_PVFP) going forward for PVFP data.
% Everything not called out below is unchanged from v7.
%
%  1) 9 TONES IS NOW STANDARD (was 4/5/6). Every PVFP Hab/Train/Retr session
%     records 9 tones - confirmed 2026-09-03 against real analyzed sessions
%     on disk. max_tones (all_tones tab width) went from 6 to 9; nothing else
%     needed to change by hand, because metric_col_span/scalar_col_index/
%     tone_avg_formula/bin_rows all already derive their column math FROM
%     max_tones rather than hardcoding it - widening it re-flows every
%     downstream column offset automatically. success_bin_ranges/labels
%     picked up a 4th bin, "1-9" (the whole-session average), alongside the
%     existing 1-3/4-6/7-9 terciles, per SV's request to see all four
%     ranges "everywhere applicable" now that a full 9-tone session exists to
%     average over. The binned_tones tabs went from 3 (1-3/4-6/1-6) to 4
%     (1-3/4-6/7-9/1-9) to match.
%     IMPORTANT for anyone editing bin lists later: "1-9" OVERLAPS the three
%     terciles (it's the same trials counted again, not a new timepoint), so
%     it must never be fed to fit_success_glmm as its own "time" level - see
%     the note where success_bin_ranges is defined, and where
%     fit_success_glmm is called, for how that's kept correct
%     (success_bin_ranges(1:3) goes to the GLMM; the full 4-bin list goes to
%     every display tab).
%
%  2) DAY STRUCTURE CHANGED: HabD1/HabD2/HabD3 -> TrainD1/TrainD2/TrainD3 ->
%     Retr, ONE session per day (was HabD1s1/HabD1s2/.../RetrS1/RetrS2, TWO
%     sub-sessions per day). day_order (the chronological sort key every tab
%     is ordered by) was rewritten to this new 7-entry sequence - verified
%     2026-09-03 against the real condition-folder names on disk (sham_HabD1,
%     sham_HabD2, sham_HabD3, sham_TrainD1, sham_TrainD2, sham_TrainD3,
%     sham_Retr, and the tms_ equivalents - no "s1"/"s2" suffix anywhere). A
%     folder name that doesn't match this list (e.g. a leftover DCSP-cohort
%     "RetrS1") still sorts to the end with a warning instead of erroring, so
%     this script keeps working if it's ever re-pointed at older data - just
%     not chronologically ordered against the new day names.
%
%  3) SUBJECT ID PREFIX: PVFP_NN (was DCSP_NN). parse_subject now matches
%     either "DCSP" or "PVFP" (case-insensitive) rather than swapping one
%     hardcoded prefix for another, per SV's choice - so this script still
%     parses subject numbers correctly if it's ever re-run against an older
%     DCSP-cohort dataset. The matched prefix is echoed back in every place
%     that used to hardcode "DCSP_%d" (scan_available_subjects' exclusion-
%     dialog labels; parse_subject's own "lbl" output used throughout the
%     binned/successful_trials/locomotion tabs) rather than assumed.
%
%  4) NEW TAB: hab_reward_rate. Per SV's request: the PVFP habituation
%     sessions have the tone/shock apparatus present but silent (same
%     "standardize session length" design as the DCSP-cohort Hab sessions -
%     see BehDEPOT_Analysis_SVv5.m's changelog), but the REWARD port IS
%     active on Hab days, so the interesting question there is how quickly
%     each mouse starts working the reward zone, not shock avoidance (which
%     stays meaningless on Hab days and stays excluded from
%     successful_trials/fit_success_glmm, unchanged from v7). One block per
%     Hab day, showing - broken down by individual mouse AND by Sham/TMS
%     group mean, each split 1-3/4-6/7-9/1-9 x Tone/ITI - (A) proportion of
%     time in the reward zone, (B) reward-zone visit count, and (C/D)
%     locomotion distance and rate. See write_hab_reward_tab for the full
%     layout and design rationale, including which parts are live formulas
%     back to all_tones (A) vs. computed literals (B/C/D, same reasoning as
%     the existing successful_trials tab) and why table C (raw distance) is
%     left chart-less while D (rate) is charted.
%     This needed one new field pair on "rows" - Reward_tone_visit_vec /
%     Reward_iti_visit_vec, the per-tone/per-ITI reward visit COUNT (not just
%     the whole-session totals v7 already had) - derived from
%     Analysis.CSp.DurOnPlat(:,3)/Analysis.ITI.DurOnPlat(:,3), which already
%     label every visit row with which tone/ITI it happened in (see
%     calc_time_plat.m). No upstream BehDEPOT_Analysis_SVv5.m change was
%     needed for this - same as every other visit-count field already in
%     this struct.
%     build_success_combined_chart (previously hard-wired to the
%     successful_trials tab's fixed 0-1 "Prop. successful" axis) gained
%     optional y_axis_title/y_axis_mode/y_number_format arguments so
%     hab_reward_rate's visit-count and locomotion-rate charts could reuse
%     its many-category/day-break/SEM-error-bar/dashed-per-animal-line layout
%     without copy-pasting it a second time; the successful_trials call site
%     is unaffected (all three new arguments default to reproduce the exact
%     original behaviour).
%
% ---------------------------------------------------------------------
% v4-v7 changes (unchanged in v8, kept for reference):
%% Sam Vaillancourt, July 22, 2026. v4 changes from v3:
% v3 exported one flat CSV with a "0.000" left as default numeric text, no
% formatting, and included every subfolder as a "session" (including
% non-session folders like "Photometry_Results" / "exclude 25", which just
% showed up as NaN rows). v4 changes:
%  1) Folders that don't actually contain exactly one *_analyzed subfolder
%     are now silently skipped before a row is ever created for them (same
%     idea as the getFiles_batch.m fix in the BehaviorDEPOT app itself: use
%     "does this folder look like a real session" as the filter, not a
%     hardcoded list of folder names to exclude).
%  2) Output is now a formatted .xlsx (built via MATLAB's Excel COM
%     automation - requires Excel installed) instead of a plain CSV, since
%     none of the requested formatting can be represented in a CSV:
%       - Two-row header: each metric name (e.g. "CSp_plat_time") merged
%         across its 6 "toneN" sub-columns; Condition/Subject headers
%         merged vertically across both header rows.
%       - Non-zero cells: "0.000" number format, fill color from a 2-color
%         gradient (0->1) - gray for Condition names containing "sham",
%         red for Condition names containing "tms".
%       - Zero-valued cells: "0" number format (no decimals), light gray
%         font, no fill (excluded from the gradient entirely, per request).
%       - Empty/failed values (NaN, e.g. a session with fewer than 6 tones,
%         or a session that errored) are left as blank cells, not "0".
%       - Metric (numeric) columns are narrow-width, sized to fit "0.000".
%     Colors are computed and written as static per-cell values at export
%     time (not a live Excel "Conditional Formatting" rule), so zero-value
%     cells can be cleanly excluded from the gradient - this is a one-time
%     generated report, not a sheet meant to be hand-edited afterward, so a
%     baked-in color achieves the same visual result as a live rule would.
%
% SV, July 22, 2026: I added 3 more tabs alongside the original (renamed
% "all tones"): "binned tones 1-3", "binned tones 4-6", and "binned tones
% 1-6", each averaging the relevant tone1..toneN columns per session and
% presenting two pivoted views per experimental day (sham_<day>/tms_<day>
% combined into one "<day>" block, e.g. "RetrS1"): a Platform-v-Reward
% table (rows grouped Sham/TMS -> Platform/Reward -> Subject, columns
% "Tones <range>"/"ITIs <range>") and a Tone-v-ITI table (rows grouped
% Sham/TMS -> Tone <range>/ITI <range> -> Subject, columns Platform/
% Reward), side by side, with each day's pair of tables stacked below the
% previous day's. Sham/TMS/Platform/Reward/Tone/ITI label cells get a flat
% light gray (sham) or light red (tms) fill; the numeric data cells get
% the same value-based gray/red gradient and zero-value treatment as the
% "all tones" tab.
%
% SV, July 24, 2026: v5 changes from v4 - both requested so the sheet can
% be hand-verified/hand-edited afterward instead of being a frozen report:
%  1) The binned tabs' numeric cells no longer contain a MATLAB-computed
%     literal average. They now contain a live "=AVERAGE('all tones'!..)"
%     formula pointing at the exact tone1..toneN cells on the "all tones"
%     tab that the value is derived from, so it's visually traceable and
%     recalculates automatically if a raw value on "all tones" changes.
%     Both pivoted tables (Platform-v-Reward and Tone-v-ITI) get their own
%     independent formula back to "all tones" (per SV's choice), rather
%     than one table referencing the other's already-computed cell.
%  2) The baked-in per-cell Interior.Color gradient (on all 4 tabs) is
%     replaced with a live Excel Color Scale conditional-format rule plus
%     a "cell value = 0" rule for the zero-value font color, applied once
%     per contiguous same-group (sham/tms) block of cells, so manually
%     typing a new number into any cell updates its fill color live.
%     Caveat (SV's choice, 2026-07-24): Excel's "Stop If True" can't
%     suppress a Color Scale's fill for specific cells within its range -
%     that only stops other classic/highlight-style rules - so zero-valued
%     cells are no longer fully fill-less; they land at the color scale's
%     pale low end (barely visible for sham, a bit more visible pale-pink
%     for tms) in addition to the gray font. This is not pixel-identical
%     to v4's fully-excluded "no fill" zero treatment, just close to it.
%  3) Widened the "Tones/ITIs/Platform/Reward" header columns on the binned
%     tabs via AutoFit instead of the fixed width sized for "0.000" data,
%     which had been truncating those longer headers.
%  4) Added one embedded Excel chart per pivoted table per day per binned
%     tab (so 2 charts x every day-block x all 3 binned tabs), matching a
%     reference Prism-style plot SV supplied 2026-07-24: bars = group mean
%     (+ SEM error bars) colored gray (sham) / red (tms), with one thin
%     line per subject connecting its paired values, under a 3-level
%     grouped category axis (outer tone-range/Platform-Reward bracket ->
%     Sham/TMS -> Platform-Reward/Tone-ITI). Both charts share one
%     identical layout function (build_paired_barline_chart), fed by live
%     formulas pointing at that day's table rows (in a staging area far to
%     the right of the visible tables, cols T/AD onward) so every plotted
%     number - bars and lines alike - is traceable and stays in sync if the
%     underlying table is hand-edited. Caveat: the SEM error-bar COM call
%     uses a few Excel enum constants (xlY/xlErrorBarIncludeBoth/
%     xlErrorBarTypeCustom) I could not verify against a live Excel
%     session - wrapped in try/catch with a warning + manual fallback
%     instructions if that specific piece doesn't come out right.
%
% SV, July 24, 2026: fixes from SV's first test run of v5 (see
% build_paired_barline_chart for the actual diffs):
%  1) X-axis labels were garbled ("P","l","a","t","f","o","r","m" instead
%     of "Platform"/"Reward"/etc). Root cause confirmed by inspecting the
%     generated .xlsx's raw XML: outer1_label/outer2_label/inner1_label/
%     inner2_label sometimes arrive as plain MATLAB char arrays (e.g. from
%     sprintf), and concatenating char arrays with [a,a,a,a,b,b,b,b] joins
%     their CHARACTERS into one long garbled string instead of building an
%     8-element array - totally different from concatenating actual
%     MATLAB "string" objects. Fixed by forcing all 4 label inputs to
%     "string" at the top of build_paired_barline_chart.
%  2) Bar fill colors switched from Points(i).Interior.Color to
%     Points(i).Format.Fill.ForeColor.RGB (matching the property path
%     already used successfully for the subject lines), since Interior.Color
%     wasn't reliably taking - possibly a knock-on effect of #1 corrupting
%     the category axis, but Format.Fill is the more robust modern API
%     either way.
%  3) Value (y) axis is now fixed to 0-1 (0.2 major unit) instead of
%     Excel's default auto-scaled range, since these are proportions.
%  4) Took another pass at the SEM error bars (still failing per SV's log,
%     COM error 0x800A03EC on every chart): dropped the HasErrorBars=true
%     pre-set and now tries invoke(series,'ErrorBar',...) before falling
%     back to the direct method call - still only moderate confidence,
%     flagged for SV to check specifically.
%
% SV, August 21, 2026: v6 changes from v5 - added 4 new session-level summary
% columns to the "all tones" tab (per SV's request; the binned tabs/charts
% are intentionally untouched here - out of scope per SV's choice):
%  1) Plat_successful_trials - total count of successful CSp trials this
%     session (sum of Analysis.CSp.OnPlatSuccessfulTrial, which
%     BehDEPOT_Analysis_SVv3.m already computes and saves per ROI - no
%     upstream script change needed). Behaviorally: the number of shocks
%     the animal successfully avoided by being on the platform at the end
%     of the tone.
%     SV, August 23, 2026: a matching Reward_successful_trials column was
%     added alongside this on Aug 21 and REMOVED again on Aug 23. It ran
%     the identical end-of-tone occupancy calculation against the reward
%     ROI, so it actually measured "was the animal in the reward zone when
%     the shock would land" - the opposite of avoidance, not "rewards
%     earned without being shocked". Real-data check: 26 of 28 session x
%     ROI pairs scored 0. Dropped as misleading; don't re-add it without
%     defining what a reward "success" should actually mean.
%  2) Plat_total_visits / Reward_total_visits - total number of discrete
%     platform/reward zone entries across the whole session (CSp + ITI
%     combined), taken directly from the row count of
%     Analysis.All_plat_ent - already the exact combined, sorted,
%     one-row-per-visit matrix BehDEPOT_Analysis_SVv3.m builds for this
%     purpose, so again no upstream script change needed.
%  SV, August 23, 2026: I added a tone-vs-ITI breakdown alongside each
%  total from (2) above - Plat_tone_visits / Plat_iti_visits and
%  Reward_tone_visits / Reward_iti_visits - from the row counts of
%  Analysis.CSp.DurOnPlat and Analysis.ITI.DurOnPlat respectively. Those
%  two matrices are exactly what All_plat_ent is built by concatenating, so
%  tone_visits + iti_visits always equals total_visits (a useful built-in
%  sanity check on the sheet). The totals are kept, not replaced.
%  These are single values per session (per SV's choice), not per-tone
%  arrays like the 4 existing time-in-zone metrics, so they're laid out as
%  extra single, vertically-merged-header columns after the tone-grouped
%  metric block - same pattern as the Condition/Subject columns - rather
%  than folded into the existing max_tones-wide metric-group layout. See
%  write_all_tones_tab for the actual column/formatting diffs.
%  FYI, not changed here: Analysis.CSp.OnPlatSuccessfulTrial's threshold
%  check in BehDEPOT_Analysis_SVv3.m (fractionON_end > threshold_success,
%  threshold_success = 1.0) can only ever fire because of the same
%  off-by-one denominator bug already fixed elsewhere in that script -
%  fractionON_end only lands fractionally above 1.0 when the animal was
%  on-ROI for literally the entire end-window, so today this behaves as a
%  de facto "100% on-ROI for that window" check, not a real >100%
%  comparison. Left untouched since it wasn't part of what SV asked to
%  change here - worth SV double-checking whether that's the intended
%  behavior.
%
% SV, July 24, 2026: fixes from SV's second test run:
%  1) Overlapping charts: Chart B is no longer anchored by a fixed cell
%     column (unreliable once column widths vary) - it's now anchored at
%     Chart A's actual right edge in points, which can't overlap regardless
%     of column widths.
%  2) Chart titles shortened to "<Day>: Platform v Reward (<range>)" and
%     given a smaller font; x-axis tick labels also shrunk - fixes the
%     title wrapping/overflow SV saw.
%  3) Y-axis was STILL showing nonsense intervals ("1,1,1,0,1,1") even
%     after the first 0-1 scale fix - root cause: the axis's number format
%     was "sourceLinked" to whatever data cell it inherited from, which
%     happened to be zero-decimal ("0") on some cells, so 0.2/0.4/0.6/0.8
%     all rounded to display as "0" or "1". Now explicitly unlinked and
%     set to "0.0". Also added a small negative y-axis minimum (-0.03)
%     plus catAxis.Crosses = xlAxisCrossesMinimum, per SV's request to
%     leave a visible gap below 0.0 (matching the Prism reference) instead
%     of 0-valued points sitting flush against the axis line.
%  4) Per SV's choice: dropped the SEM error-bar code entirely rather than
%     keep guessing blindly - two different COM call styles both failed
%     identically with no way to diagnose further without a live Excel
%     session. Add SEM error bars by hand on whichever charts matter
%     (Chart Design -> Add Chart Element -> Error Bars -> More Error Bar
%     Options -> Custom). The now-unused SEM formula/range that fed this
%     was also removed from the chart-feeder staging area.
%  5) Confirmed for SV: the columns to the right of each binned tab (now
%     hidden by default) are exactly what feeds these charts - live
%     formulas pointing at that tab's own visible tables, which in turn
%     pull from "all tones". Nothing computed independently.

% SV, August 24, 2026: v7 changes from v6 - two changes, neither of which
% alters any calculation or the workbook layout:
%  1) A headless escape hatch (PX_root / PX_conds / PX_exclude, below) so the
%     report can be regenerated non-interactively after re-running
%     BehDEPOT_Analysis_SVv4.m.
%  2) A subject-exclusion dialog that appears immediately after Run is clicked
%     on the condition-folder window, listing every animal found across the
%     selected conditions with a tickbox to drop it from the ENTIRE analysis
%     (see select_exclusions_gui / scan_available_subjects). Exclusion is by
%     animal number, so ticking DCSP_22 removes all of its sessions on every
%     day. It is applied while "rows" is being built, before any tab writer
%     runs, so an excluded animal is absent from all_tones, successful_trials,
%     zone_visits, all three binned tabs, every chart, and the stats tab's
%     GLMM - and all group means/SEMs are recomputed without it, rather than
%     it merely being hidden from view. Default is nothing excluded, so
%     clicking straight through reproduces v6 behaviour exactly.
% Everything else in this file is byte-for-byte v6.
%
% Worth knowing when reading a v7-generated workbook: the numbers it pulls
% out of Analysis_DT_*.mat changed meaning on 2026-08-24, because
% BehDEPOT_Analysis_SVv4.m changed how they are produced:
%  - Every session's time-in-zone is now scored by the SAME body point
%    (Tracking.Smooth.MidBack). Previously sham sessions were MidBack-scored
%    and most tms sessions were Implant-scored, which confounded the scoring
%    point with experimental group on 3 of the 4 days.
%  - The ITI_* columns are re-aligned. The column labelled "toneN" is now
%    genuinely the ITI FOLLOWING tone N. In v6-and-earlier workbooks, the
%    ITI "tone1" column was actually the 80 s pre-tone baseline and every
%    other ITI column was the interval PRECEDING its tone.
% Both fixes live in BehDEPOT_Analysis_SVv4.m; see its changelog for the
% measured magnitude of each.

%% Select root directory and choose which condition folders to include
% SV, August 24, 2026: I changed
% P.script_dir = pwd; % directory with script files (avoids requiring changes to path)
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
% to this - identical GUI code, just wrapped so predefining PX_root/PX_conds
% in the workspace skips the dialogs (for matlab -batch re-runs):
P.script_dir = pwd; % directory with script files (avoids requiring changes to path)
% SV, September 3, 2026: I added build_pdf/PX_pdf - whether to also build a
% per-animal Freezing Map PDF (see write_freezing_map_pdf, called after the
% main session loop below). Interactive: driven by the new checkbox in
% select_folders_gui, default unchecked. Headless: predefine PX_pdf=true to
% turn it on (any other/no value = off, matching the checkbox's default).
if exist('PX_root','var') && exist('PX_conds','var')
    P.root_directory = PX_root;
    selected_conditions = string(PX_conds);
    condition_folders = list_subfolders(P.root_directory); % only for the "N of M" message below
    build_pdf = exist('PX_pdf','var') && isequal(PX_pdf, true);
    % SV, September 25, 2026: I added the headless equivalent for the figure
    % report - set PX_report to true for all four sections, or to a struct
    % with any of shocks/locomotion/zone_time/zone_visits to pick some.
    report_sections = struct('enabled', false, 'shocks', false, 'locomotion', false, ...
        'zone_time', false, 'zone_visits', false);
    if exist('PX_report','var')
        if isstruct(PX_report)
            fn = fieldnames(PX_report);
            for q = 1:numel(fn)
                report_sections.(fn{q}) = logical(PX_report.(fn{q}));
            end
            report_sections.enabled = true;
        elseif isequal(PX_report, true)
            report_sections = struct('enabled', true, 'shocks', true, 'locomotion', true, ...
                'zone_time', true, 'zone_visits', true);
        end
    end
    fprintf('HEADLESS MODE: root = %s\n', P.root_directory);
    % SV, September 28, 2026: I added - headless group colors. Predefine
    % PX_colors as a struct with sham and/or tms set to a palette name (see
    % group_palette) or an [R G B] 0-255 triplet, e.g.
    %   PX_colors = struct('tms', "Shock Red");
    % Anything left unset keeps the default (Control Grey sham, UCLA Blue tms).
    group_colors = struct('sham', "Control Grey", 'tms', "UCLA Blue");
    if exist('PX_colors','var') && isstruct(PX_colors)
        if isfield(PX_colors, 'sham'), group_colors.sham = PX_colors.sham; end
        if isfield(PX_colors, 'tms'),  group_colors.tms  = PX_colors.tms;  end
    end
    % SV, September 25, 2026: I added - the GUI now refuses to offer a folder
    % with no Analysis_DT_*.mat anywhere in it; headless has no GUI to grey
    % out, so it says the same thing out loud instead of producing an empty run.
    hl_elig = scan_condition_eligibility(P.root_directory, selected_conditions);
    hl_bad = selected_conditions([hl_elig.ready] == 0);
    if ~isempty(hl_bad)
        warning(['%d selected folder(s) contain no session with both ' ...
            'Analysis_DT_platform.mat and Analysis_DT_reward.mat, and will contribute ' ...
            'no rows - run BehDEPOT_Analysis_SVv5 on them first: %s'], ...
            numel(hl_bad), strjoin(hl_bad, ', '));
    end
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

    [selected_conditions, build_pdf, report_sections, group_colors] = select_folders_gui(condition_folders, P.root_directory);
    if isempty(selected_conditions)
        error('No condition folders selected (window closed without clicking Run, or nothing checked). Aborting.');
    end
end
%

% SV, September 28, 2026: I added - drop any selected folder that is neither
% sham_ nor tms_ (excluded by default, per SV; the GUI already refuses to
% tick one, so in practice this catches PX_conds in headless runs).
no_group = arrayfun(@(x) condition_group(x) == "", selected_conditions);
if any(no_group)
    warning('Excluding %d condition folder(s) with no sham_/tms_ prefix: %s', ...
        nnz(no_group), strjoin(selected_conditions(no_group), ', '));
    selected_conditions = selected_conditions(~no_group);
end
if isempty(selected_conditions)
    error('No sham_/tms_ condition folders left to run on.');
end

fprintf('Running on %d of %d condition folder(s): %s\n', ...
    length(selected_conditions), length(condition_folders), strjoin(selected_conditions, ', '));

% SV, September 28, 2026: I added - set BOTH group colors every run (see
% group_color for why this is a persistent store), before anything is drawn.
group_color("sham", group_colors.sham);
group_color("tms",  group_colors.tms);
fprintf('Group colors: sham = %s, tms = %s\n', ...
    mat2str(group_color("sham")), mat2str(group_color("tms")));

% SV, September 25, 2026: I added - session-layout detection, so ONE script
% handles both cohort layouts instead of needing a per-cohort fork (v7_DCSP
% vs v8_PVFP). The two cohorts differ in exactly three constants - the
% chronological day list, how many tones a session records, and therefore
% which tone bins exist - and every other line in this file already derives
% its behaviour from those three, so selecting them here is the whole change.
%
%   "pvfp" - PVFP cohort (E:\2026-08-20_PVcre.Fp_PMA_TMS and onward). ONE
%            session per day, 9 tones. This is exactly what v8 hardcoded.
%   "dcsp" - DCSP cohort (E:\2026-02-01_Fp.SST.PV_TMS_PMA_SV). TWO
%            sessions per day (the "s1"/"s2" suffix), max 6 tones - verified
%            2026-09-25 by counting rows in every csp_cue_frames.csv across
%            the 12 Train/Retr condition folders: 51 sessions with 6 tones,
%            17 with 5, 15 with 4, none above 6.
%
% Detection compares the day names of the CONDITION FOLDERS YOU SELECTED
% against both lists and takes whichever matches more. That runs before any
% session is read, which matters because max_tones has to be known before the
% row loop pads anything. Set session_layout_override below to force it.
session_layout_override = "auto"; % "auto" | "dcsp" | "pvfp"

% Canonical chronological day sequences - the single source of truth for
% "chronological" everywhere in this script. Add new day types HERE, not to
% the sort logic further down.
day_order_pvfp = ["HabD1", "HabD2", "HabD3", "TrainD1", "TrainD2", "TrainD3", "Retr"];
% This is v7's list. SV's requested plotting order for the 2026-02-01 dataset
% is TrainD1s1, TrainD1s2, TrainD2s1, TrainD2s2, RetrS1, RetrS2, and that is
% what selecting those six folders produces.
%
% The four Hab entries lead the list so DCSP habituation days sort correctly
% whenever SV gets to them (SV, 2026-09-25: "i may calculate Hab days for
% DCSP, just not at the moment"). They cost nothing until then - a day name
% that is not among the selected folders simply never comes up.
%
% SV, September 25, 2026: I removed "TrainD1s3" and "TrainD2s3" from this
% list, per SV: "i will not use s3 for anything going forward i dont think".
% Those folders do still exist on disk (sham_TrainD1s3 etc., partially
% populated), so if one is ever selected by accident it now sorts to the end
% with the unmatched-day warning - which is the intended signal that
% something unexpected got ticked, not a silent mis-ordering.
day_order_dcsp = ["HabD1s1", "HabD1s2", "HabD2s1", "HabD2s2", ...
    "TrainD1s1", "TrainD1s2", ...
    "TrainD2s1", "TrainD2s2", ...
    "RetrS1", "RetrS2"];

if session_layout_override ~= "auto"
    session_layout = lower(session_layout_override);
    fprintf('Session layout: %s (forced via session_layout_override).\n', session_layout);
else
    selected_days = strings(1, numel(selected_conditions));
    for sc = 1:numel(selected_conditions)
        selected_days(sc) = day_from_condition(selected_conditions(sc));
    end
    n_match_pvfp = sum(ismember(selected_days, day_order_pvfp));
    n_match_dcsp = sum(ismember(selected_days, day_order_dcsp));

    if n_match_dcsp > n_match_pvfp
        session_layout = "dcsp";
    elseif n_match_pvfp > n_match_dcsp
        session_layout = "pvfp";
    else
        % Nothing recognisable either way (or a genuine tie) - fall back to
        % the PVFP layout v8 hardcoded, loudly, rather than guessing quietly.
        session_layout = "pvfp";
        warning(['Could not tell which session layout these condition folders use ' ...
            '(%d name(s) match the PVFP day list, %d match the DCSP one). ' ...
            'Defaulting to "pvfp". Set session_layout_override at the top of this ' ...
            'script to force the right one.'], n_match_pvfp, n_match_dcsp);
    end
    fprintf('Session layout: %s (auto-detected - %d of %d selected folder(s) matched).\n', ...
        session_layout, max(n_match_pvfp, n_match_dcsp), numel(selected_conditions));
end

if session_layout == "dcsp"
    day_order = day_order_dcsp;
    layout_max_tones = 6;
    % Only two exclusive terciles fit in 6 tones, so the whole-session
    % aggregate is "1-6" rather than "1-9". It still has to come LAST in this
    % list - the overlap-dropping logic that picks the GLMM's bins, the
    % timecourse tab's n_bins-1, and the binned-tab ordering all treat the
    % trailing entry as the aggregate.
    layout_bin_ranges = {1:3, 4:6, 1:6};
    layout_bin_labels = ["Tones 1-3", "Tones 4-6", "Tones 1-6"];
else
    day_order = day_order_pvfp;
    layout_max_tones = 9;
    layout_bin_ranges = {1:3, 4:6, 7:9, 1:9};
    layout_bin_labels = ["Tones 1-3", "Tones 4-6", "Tones 7-9", "Tones 1-9"];
end
%

% SV, August 24, 2026: I added - subject exclusion step, per SV's request that
% a box appear right after clicking Run asking which subjects to drop from the
% ENTIRE analysis. Excluding here (before any row is built) rather than at each
% tab writer is what makes "entire analysis" true for free: every tab -
% all_tones, successful_trials, zone_visits, all three binned tabs, the charts
% they feed, and the stats tab's GLMM - is derived from the "rows" array built
% by the loop below, so a subject that never enters "rows" cannot appear
% anywhere downstream, and the group means/SEMs are recomputed without it
% rather than just being visually hidden.
%
% Exclusion is BY ANIMAL NUMBER, not by session folder: DCSP_22 appears once
% per day, and "exclude from the entire analysis" means all of its sessions
% across every day, not just one. The list is gathered by scanning the selected
% condition folders for real session folders (the same one-*_analyzed-subfolder
% test the main loop uses), so only subjects that would actually have been
% analyzed are offered.
%
% Headless runs skip the dialog: predefine PX_exclude (e.g. PX_exclude=[22 25])
% to exclude non-interactively, or leave it undefined to exclude nothing.
if exist('PX_exclude','var')
    excluded_subjects = PX_exclude(:)';
    fprintf('HEADLESS MODE: excluding subject(s): %s\n', mat2str(excluded_subjects));
else
    available_subjects = scan_available_subjects(P.root_directory, selected_conditions);
    if isempty(available_subjects)
        warning('No real session folders found in the selected condition folder(s) - skipping the exclusion dialog.');
        excluded_subjects = [];
    else
        excluded_subjects = select_exclusions_gui(available_subjects);
    end
end

if isempty(excluded_subjects)
    fprintf('Excluding no subjects - all will be included.\n');
else
    % SV, September 3, 2026: I changed
    % strjoin(arrayfun(@(x) sprintf('DCSP_%d',x), excluded_subjects, 'uni', 0), ', ')
    % to this - hardcoded "DCSP_" no longer matches the PVFP cohort. This
    % console message runs before "rows" exists, so there's no session folder
    % name handy to ask parse_subject about; printing the bare animal number
    % is unambiguous either way (it's the same number typed into PX_exclude
    % or ticked in the dialog), so the cohort prefix is just dropped here
    % rather than guessed.
    fprintf('EXCLUDING %d subject(s) from the entire analysis: %s\n', ...
        numel(excluded_subjects), strjoin(arrayfun(@(x) sprintf('#%d',x), ...
        excluded_subjects, 'uni', 0), ', '));
end
%

% SV, September 3, 2026: I changed
% max_tones = 6; % pad sessions with fewer tones so all rows have the same width
% to this. v7's "forward-looking" 7-9 padding on the success vector (see the
% comment this replaced, below) is no longer forward-looking - 9 tones is now
% the PVFP standard (every Hab/Train/Retr session records 9), so all_tones,
% the binned tabs, and every metric_col_span/scalar_col_index derivation that
% reads max_tones now lay out 9 tone columns instead of 6. This is the only
% line that needed to change for that - metric_col_span and scalar_col_index
% both derive their column math FROM max_tones rather than hardcoding it, so
% widening it here automatically re-flows every downstream column offset.
% Older (6-or-fewer-tone) sessions still work fine: pad_to_len just leaves the
% extra tone7-9 cells blank for them, same as it always has for a short session.
% SV, September 25, 2026: I changed
% max_tones = 9; % pad sessions with fewer tones so all rows have the same width
% to this - the tone count is now a property of the detected session layout
% (9 for PVFP, 6 for DCSP) rather than a constant, so the same script lays
% out the right number of tone columns for either cohort. See the
% session-layout block above. Everything downstream is unaffected:
% metric_col_span/scalar_col_index/tone_avg_formula/bin_rows all already
% derive their column math FROM max_tones.
max_tones = layout_max_tones; % pad sessions with fewer tones so all rows have the same width

% SV, August 23, 2026: I added - tone binning for the new "successful_trials"
% tab (see write_successful_trials_tab). Kept SEPARATE from max_tones on
% purpose: max_tones=6 governs the existing "all_tones" tab layout and every
% binned-tab formula that points into it, and widening it would disturb all
% of that. The per-tone success vector is only consumed by the new tab, so
% it gets its own wider padding (9) to give SV's requested "tones 7-9" bin
% somewhere to live. NOTE: no session in the current dataset has more than 6
% tones (they run 4, 5, or 6), so the 7-9 bin will come out blank until
% 9-tone sessions actually exist - same forward-looking intent as day_order.
% SV, September 3, 2026: I changed
% success_bin_ranges = {1:3, 4:6, 7:9};
% success_bin_labels = ["Tones 1-3", "Tones 4-6", "Tones 7-9"];
% to this - added a 4th "1-9" (whole-session) bin, per SV's request to see
% 1-3/4-6/7-9/1-9 everywhere applicable, now that 9 tones is standard and
% max_tones no longer needs to be kept separate from max_success_tones (both
% are 9 now, but the two variables are kept distinct on purpose - see below).
%
% IMPORTANT for anyone adding a 5th bin here: success_bin_ranges doubles as
% the input to fit_success_glmm, and 1-3/4-6/7-9 is an EXCLUSIVE partition of
% the 9 tones (each tone counted once) but 1-9 OVERLAPS all three - it is not
% a new independent timepoint, it's the same trials counted again. Feeding
% all 4 bins into the GLMM's per-bin "time" predictor would double-count
% every trial (once in its tercile, once again in "1-9"), inflating the
% effective sample size and violating the model's independence assumption.
% write_formatted_xlsx therefore passes only success_bin_ranges(1:3) (the
% exclusive partition) to fit_success_glmm, and the full 4-bin list to the
% successful_trials TABLE and the new hab_reward_rate tab, where an
% overlapping aggregate column is just a display convenience, not a
% statistical observation. Keep that split if you add more display-only bins.
% SV, September 25, 2026: I changed
% success_bin_ranges = {1:3, 4:6, 7:9, 1:9};
% success_bin_labels = ["Tones 1-3", "Tones 4-6", "Tones 7-9", "Tones 1-9"];
% to this - the bin list is a property of the detected session layout too: a
% 6-tone DCSP session has no "7-9" bin, and its whole-session aggregate is
% "1-6". Keeping the aggregate LAST in the list is what the rest of the
% script relies on (see the layout block above). max_success_tones still
% derives itself, so it lands on 9 or 6 automatically.
success_bin_ranges = layout_bin_ranges;
success_bin_labels = layout_bin_labels;
max_success_tones = max(cellfun(@max, success_bin_ranges)); % 9 (PVFP) or 6 (DCSP)

%% Load Analysis_DT_platform/reward.mat for every real session in every selected condition
% SV, August 21, 2026: I changed
% rows = struct('Condition', {}, 'Subject', {}, ...
%     'CSp_plat_time', {}, 'CSp_reward_time', {}, 'ITI_plat_time', {}, 'ITI_reward_time', {});
% to this (4 new session-level scalar fields - see v6 changelog above):
% SV, August 23, 2026: I changed
% rows = struct('Condition', {}, 'Subject', {}, ...
%     'CSp_plat_time', {}, 'CSp_reward_time', {}, 'ITI_plat_time', {}, 'ITI_reward_time', {}, ...
%     'Plat_successful_trials', {}, 'Reward_successful_trials', {}, ...
%     'Plat_total_visits', {}, 'Reward_total_visits', {});
% to this (split total visits into its tone/ITI components too, per SV's
% request - Plat_total_visits/Reward_total_visits are kept as-is, just with
% 2 new fields each alongside them):
% SV, August 23, 2026: I changed (second edit same day - dropped
% 'Reward_successful_trials', {} from this list; see the changelog note at
% the top of this file for why):
% SV, August 23, 2026: I added 'proportion_successful', {} as the first of
% the scalar fields (per SV's request that it come before
% Plat_successful_trials):
% SV, August 24, 2026: I added the 7 Loco_* fields below (per SV's request for a
% "locomotion" tab). They come from Analysis.Locomotion, which
% BehDEPOT_Analysis_SVv4.m computes per window from Tracking.Smooth.MidBack -
% deliberately NOT from Metrics.Movement, which carries the same MidBack/Implant
% group confound v4 removed from time-in-zone (see that script's changelog).
% Distances and durations are both carried so a tone-bin rate can be computed as
% sum(distance)/sum(duration) rather than as a mean of per-window rates: ITI
% windows vary 80-150 s, so a plain mean of rates would weight a short ITI the
% same as a long one.
% SV, September 3, 2026: I added Reward_tone_visit_vec/Reward_iti_visit_vec
% below (no v7 equivalent) - the PER-TONE/PER-ITI reward-zone visit COUNT,
% not just the whole-session Reward_tone_visits/Reward_iti_visits totals v7
% already had. Needed for the new hab_reward_rate tab's visit-count-by-bin
% table (see write_hab_reward_tab): Analysis.CSp.DurOnPlat(:,3) /
% Analysis.ITI.DurOnPlat(:,3) already label every visit row with which
% tone/ITI it happened in (see calc_time_plat.m), so this is a re-bin of data
% BehDEPOT_Analysis_SVv5.m already saves - no upstream script change needed,
% same as every other visit-count field in this struct.
% SV, September 3, 2026: I added Plat_tone_visit_vec/Plat_iti_visit_vec below
% - the platform-side equivalent of Reward_tone_visit_vec/Reward_iti_visit_vec
% above, needed so zone_visits' new time-course chart can show platform AND
% reward visit trends (not just reward). Same derivation, same DurOnPlat
% column-3 re-bin, just against Analysis_platform instead of Analysis_reward.
%
% I also added Merged_PerTimeInROI/Merged_Visits/Merged_Dist/Merged_Dur - per
% SV's request that Habituation locomotion/visits/time-in-zone NOT be split
% into Tone vs ITI (the tone never played on Hab days, so that split has no
% behavioural meaning there - see BehDEPOT_Analysis_SVv5.m's changelog).
% These read Analysis.Merged, which BehDEPOT_Analysis_SVv5.m computes ONLY
% for sessions it was told were habituation - epoch i = tone i's window
% PLUS the ITI immediately following it, treated as one combined "trial
% cycle" window, exactly matching what SV described ("group tone #1, the iti
% immediately after it, ... through tone/iti#3"). Guarded with isfield at the
% read site below (same pattern as Analysis.Locomotion) so a session
% analyzed before BehDEPOT_Analysis_SVv5.m existed just leaves these blank
% instead of erroring the whole session out - re-run BehDEPOT_Analysis on a
% Hab session to populate them if they come back empty.
% SV, September 3, 2026 (later same day): I added Plat_Merged_Visits/
% Plat_Merged_PerTimeInROI alongside - Analysis.Merged is computed once PER
% ROI (analyze_pma_roi runs once for platform, once for reward), so the
% original Merged_* fields above (read off Analysis_reward) only ever
% covered the REWARD zone. zone_visits' Habituation timecourse now needs the
% PLATFORM zone's merged visit count too. Merged_Dist/Merged_Dur are NOT
% duplicated per-ROI here - path length is purely a MidBack tracking
% quantity, identical in Analysis_platform.Merged and Analysis_reward.Merged
% for the same session (same reasoning Loco_tone_dist etc. already documents
% for reading Locomotion off "the platform file, arbitrarily").
rows = struct('Condition', {}, 'Subject', {}, ...
    'CSp_plat_time', {}, 'CSp_reward_time', {}, 'ITI_plat_time', {}, 'ITI_reward_time', {}, ...
    'proportion_successful', {}, 'Plat_successful_trials', {}, 'Plat_success_vector', {}, ...
    'Plat_total_visits', {}, 'Plat_tone_visits', {}, 'Plat_iti_visits', {}, ...
    'Reward_total_visits', {}, 'Reward_tone_visits', {}, 'Reward_iti_visits', {}, ...
    'Plat_tone_visit_vec', {}, 'Plat_iti_visit_vec', {}, ...
    'Reward_tone_visit_vec', {}, 'Reward_iti_visit_vec', {}, ...
    'Loco_BL_dist', {}, 'Loco_BL_dur', {}, ...
    'Loco_tone_dist', {}, 'Loco_tone_dur', {}, ...
    'Loco_iti_dist', {}, 'Loco_iti_dur', {}, 'Loco_px2cm', {}, ...
    'Merged_PerTimeInROI', {}, 'Merged_Visits', {}, 'Merged_Dist', {}, 'Merged_Dur', {}, ...
    'Plat_Merged_PerTimeInROI', {}, 'Plat_Merged_Visits', {}, ...
    'FreezingMapPath', {});
%
% SV, September 27, 2026: I added - sessions dropped by the exclusion dialog,
% kept only so the Activity Map PDF can still show them marked "(EXCLUDED)".
excluded_rows = struct('Condition', {}, 'Subject', {}, 'FreezingMapPath', {});

failed_sessions = {}; % {condition_name, session_name, error_message} - sessions that error after being
                       % recognized as real (i.e. have an *_analyzed folder) get a NaN row, not a halted batch

for c = 1:length(selected_conditions)
    condition_name = selected_conditions(c);
    video_directory = fullfile(P.root_directory, condition_name);
    video_folder_list = prepBatch(string(video_directory)); %Generate list of candidate session folders within this condition

    for j = 1:length(video_folder_list)
        current_video = video_folder_list(j);
        video_folder = strcat(video_directory, '\', current_video);

        % Skip folders that aren't real analyzed session folders (e.g. "Photometry_Results",
        % "exclude 25") - a real session folder has exactly one *_analyzed subfolder inside it.
        % This is name-agnostic on purpose, so it doesn't need updating if new non-session
        % folder names show up later.
        cd(video_folder)
        Analysis_path = dir('*analyzed');
        if numel(Analysis_path) ~= 1
            fprintf('  Skipping non-session folder: %s / %s\n', condition_name, current_video);
            continue
        end

        % SV, August 24, 2026: I added - drop this session entirely if its
        % animal was ticked in the exclusion dialog. Placed AFTER the
        % non-session-folder test (so the console log distinguishes "not a
        % session" from "deliberately excluded") but BEFORE the row is
        % created, so no NaN placeholder row is left behind for it.
        [this_subj_num, ~] = parse_subject(current_video);
        if ~isnan(this_subj_num) && ismember(this_subj_num, excluded_subjects)
            fprintf('  EXCLUDED (user selection): %s / %s\n', condition_name, current_video);
            % SV, September 27, 2026: I added - an excluded animal still gets
            % its Activity Map page, marked "(EXCLUDED)". It contributes
            % nothing to any table, chart or model (it never enters "rows"),
            % but the maps are the one output where seeing the animal you
            % dropped is the point: you look at them to check the call was
            % right. Only the fields the map PDF reads are collected.
            ex_ind = numel(excluded_rows) + 1;
            excluded_rows(ex_ind).Condition = condition_name; %#ok<AGROW>
            excluded_rows(ex_ind).Subject = current_video;
            excluded_rows(ex_ind).FreezingMapPath = '';
            ex_an = dir(fullfile(char(video_folder), '*analyzed'));
            ex_an = ex_an([ex_an.isdir]);
            if numel(ex_an) == 1
                ex_map = fullfile(ex_an(1).folder, ex_an(1).name, 'Freezing Map.jpg');
                if isfile(ex_map)
                    excluded_rows(ex_ind).FreezingMapPath = ex_map;
                end
            end
            continue
        end
        %

        fprintf('Processing %s / %s\n', condition_name, current_video);
        row_ind = numel(rows) + 1;
        rows(row_ind).Condition = condition_name;
        rows(row_ind).Subject = current_video;
        rows(row_ind).CSp_plat_time = nan(1, max_tones);
        rows(row_ind).CSp_reward_time = nan(1, max_tones);
        rows(row_ind).ITI_plat_time = nan(1, max_tones);
        rows(row_ind).ITI_reward_time = nan(1, max_tones);
        % SV, August 21, 2026: I added - scalar defaults for the new
        % session-level columns, same NaN-until-proven-otherwise pattern as
        % the 4 existing metrics above, so a session that errors out below
        % still gets a blank (not zero) cell for these too.
        % SV, August 23, 2026: I added 2 more defaults each for
        % Plat_/Reward_tone_visits and Plat_/Reward_iti_visits (the new
        % tone-vs-ITI visit breakdown - see below).
        % SV, August 23, 2026: I removed
        % rows(row_ind).Reward_successful_trials = NaN;
        % from here (column dropped - see changelog at top of file).
        rows(row_ind).N_tones = NaN; % SV, September 25, 2026: I added - see the degenerate-session check after the row loop
        rows(row_ind).proportion_successful = NaN; % SV, August 23, 2026: I added
        rows(row_ind).Plat_successful_trials = NaN;
        rows(row_ind).Plat_success_vector = nan(1, max_success_tones); % SV, August 23, 2026: I added
        rows(row_ind).Plat_total_visits = NaN;
        rows(row_ind).Plat_tone_visits = NaN;
        rows(row_ind).Plat_iti_visits = NaN;
        rows(row_ind).Reward_total_visits = NaN;
        rows(row_ind).Reward_tone_visits = NaN;
        rows(row_ind).Reward_iti_visits = NaN;
        % SV, September 3, 2026: I added - per-tone/per-ITI visit-count
        % vector defaults, same NaN-until-proven-otherwise pattern as
        % Plat_success_vector above, padded to max_success_tones.
        rows(row_ind).Plat_tone_visit_vec = nan(1, max_success_tones);
        rows(row_ind).Plat_iti_visit_vec = nan(1, max_success_tones);
        rows(row_ind).Reward_tone_visit_vec = nan(1, max_success_tones);
        rows(row_ind).Reward_iti_visit_vec = nan(1, max_success_tones);
        % SV, September 3, 2026: I added - Merged (combined tone+ITI cycle)
        % defaults for the redesigned Habituation charts. Blank/NaN for every
        % non-Hab session (Analysis.Merged is only computed for Hab sessions)
        % - that's the correct default, not a bug: there IS no merged cycle
        % concept on a day where the tone actually played.
        rows(row_ind).Merged_PerTimeInROI = nan(1, max_success_tones);
        rows(row_ind).Merged_Visits = nan(1, max_success_tones);
        rows(row_ind).Merged_Dist = nan(1, max_success_tones);
        rows(row_ind).Merged_Dur = nan(1, max_success_tones);
        rows(row_ind).Plat_Merged_PerTimeInROI = nan(1, max_success_tones);
        rows(row_ind).Plat_Merged_Visits = nan(1, max_success_tones);
        % SV, August 24, 2026: I added - locomotion defaults, same
        % NaN-until-proven-otherwise pattern as everything above, padded to
        % max_success_tones so the "Tones 7-9" bin has somewhere to live.
        rows(row_ind).Loco_BL_dist = NaN;
        rows(row_ind).Loco_BL_dur = NaN;
        rows(row_ind).Loco_tone_dist = nan(1, max_success_tones);
        rows(row_ind).Loco_tone_dur = nan(1, max_success_tones);
        rows(row_ind).Loco_iti_dist = nan(1, max_success_tones);
        rows(row_ind).Loco_iti_dur = nan(1, max_success_tones);
        rows(row_ind).Loco_px2cm = NaN;
        %
        % SV, September 3, 2026: I added - default empty path for the
        % per-session Freezing Map.jpg (see write_freezing_map_pdf), set
        % below only if BehaviorDEPOT actually wrote one for this session.
        rows(row_ind).FreezingMapPath = '';

        try
            cd([Analysis_path.folder '\' Analysis_path.name])

            load('Analysis_DT_platform.mat')
            Analysis_platform = Analysis;
            load('Analysis_DT_reward.mat')
            Analysis_reward = Analysis;

            % SV, September 3, 2026: I added - path to this session's
            % Freezing Map.jpg (written by BehaviorDEPOT into the *_analyzed
            % folder), if it exists. Read outside any isfield guard - a
            % missing file just leaves the default '' from above, same
            % NaN/blank-until-proven-otherwise convention as everything else
            % in this loop.
            fm_path = fullfile(Analysis_path.folder, Analysis_path.name, 'Freezing Map.jpg');
            if isfile(fm_path)
                rows(row_ind).FreezingMapPath = fm_path;
            end

            % SV, September 25, 2026: I added - how many tones this session
            % actually recorded, kept so the check after the row loop can spot
            % a session whose cue file degenerated into one whole-session
            % window (see there). This is the same count pad_to_len is about
            % to pad up to max_tones, just recorded before it is padded.
            rows(row_ind).N_tones = numel(Analysis_platform.CSp.OnPlatPerOnPlat);
            %
            rows(row_ind).CSp_plat_time = pad_to_len(Analysis_platform.CSp.OnPlatPerOnPlat, max_tones);
            rows(row_ind).CSp_reward_time = pad_to_len(Analysis_reward.CSp.OnPlatPerOnPlat, max_tones);
            rows(row_ind).ITI_plat_time = pad_to_len(Analysis_platform.ITI.OnPlatPer, max_tones);
            rows(row_ind).ITI_reward_time = pad_to_len(Analysis_reward.ITI.OnPlatPer, max_tones);
            % SV, August 21, 2026: I added - both already computed/saved by
            % BehDEPOT_Analysis_SVv3.m per session, no upstream script change
            % needed (see v6 changelog above for exactly which fields these
            % come from and why).
            rows(row_ind).Plat_successful_trials = sum(Analysis_platform.CSp.OnPlatSuccessfulTrial);
            % SV, August 23, 2026: I added - proportion_successful, i.e.
            % (trials the animal avoided the shock on) / (total shock trials
            % that session), per SV's request. Denominator is the TONE count:
            % verified against this dataset (2026-08-23) that every Train
            % session has exactly one US/shock cue per CS+ tone
            % (us_cue_frames.csv and csp_cue_frames.csv have identical row
            % counts in every Train session, zero exceptions), so tone count
            % and shock count are the same number on the days shocks exist.
            % Retrieval days have NO us_cue_frames.csv at all (no shocks
            % delivered), but per SV: still report the proportion there,
            % because the question on those days is whether the animal
            % *anticipates* the shock and is on the platform at the end of
            % the tone the way training taught it to.
            % Habituation days are excluded entirely (left blank) per SV -
            % those sessions have no tones and no shocks, so there's nothing
            % to take a proportion of. The n_success_trials==0 guard also
            % covers any other session that somehow has no tones, so this
            % can't divide by zero regardless of day naming.
            success_vec = Analysis_platform.CSp.OnPlatSuccessfulTrial;
            n_shock_trials = numel(success_vec);
            session_day = day_from_condition(rows(row_ind).Condition);
            if startsWith(session_day, 'Hab', 'IgnoreCase', true) || n_shock_trials == 0
                rows(row_ind).proportion_successful = NaN; % blank cell
            else
                rows(row_ind).proportion_successful = sum(success_vec) / n_shock_trials;
                % SV, August 23, 2026: I added - keep the raw per-tone 0/1
                % success vector (NaN-padded out to max_success_tones) so the
                % new "successful_trials" tab can re-derive the same
                % proportion per tone-bin instead of only per whole session.
                % Padding is NaN, not 0, so a session with 5 tones is
                % distinguishable from one that failed all 9 - the bin
                % proportion below drops NaNs rather than counting them.
                rows(row_ind).Plat_success_vector = pad_to_len(success_vec, max_success_tones);
            end
            %
            % SV, August 23, 2026: I removed
            % rows(row_ind).Reward_successful_trials = sum(Analysis_reward.CSp.OnPlatSuccessfulTrial);
            % from here. It was the identical end-of-tone occupancy calculation
            % just pointed at the reward ROI instead of the platform, so it read
            % as "was the animal sitting in the reward zone when the shock would
            % land" - the opposite of avoiding it, and NOT "rewards earned
            % without being shocked" as the name implied. Confirmed against real
            % data (2026-08-23): 26 of 28 session x ROI pairs scored exactly 0,
            % vs. sensible avoidance numbers for the platform version (e.g. 5/5,
            % 5/6), i.e. it carried essentially no signal and invited misreading.
            % Dropped per SV's choice rather than renamed. The platform version
            % above is kept - that one IS the real avoidance measure (shocks
            % successfully avoided by being on the platform at tone end).
            % SV, August 23, 2026: I changed
            % rows(row_ind).Plat_total_visits = size(Analysis_platform.All_plat_ent, 1);
            % rows(row_ind).Reward_total_visits = size(Analysis_reward.All_plat_ent, 1);
            % to this (per SV's request: split each total into its tone/CSp-period
            % and ITI-period components too. Analysis.All_plat_ent is already just
            % [ITI visits; CSp visits] concatenated - see BehDEPOT_Analysis_SVv3.m's
            % "Combines ITI and CSp time on ROI into one matrix" section - so
            % Analysis.CSp.DurOnPlat's row count + Analysis.ITI.DurOnPlat's row
            % count always sum to exactly the same total as before; no upstream
            % script change needed here either, same as the fields above):
            rows(row_ind).Plat_tone_visits = size(Analysis_platform.CSp.DurOnPlat, 1);
            rows(row_ind).Plat_iti_visits = size(Analysis_platform.ITI.DurOnPlat, 1);
            rows(row_ind).Plat_total_visits = size(Analysis_platform.All_plat_ent, 1);
            rows(row_ind).Reward_tone_visits = size(Analysis_reward.CSp.DurOnPlat, 1);
            rows(row_ind).Reward_iti_visits = size(Analysis_reward.ITI.DurOnPlat, 1);
            rows(row_ind).Reward_total_visits = size(Analysis_reward.All_plat_ent, 1);
            % SV, September 3, 2026: I added - the per-tone/per-ITI visit
            % COUNT vector behind the hab_reward_rate tab's binned visit
            % table (see write_hab_reward_tab). DurOnPlat column 3 is which
            % tone/ITI (1..n_tones_this_session) each visit row happened in
            % (calc_time_plat.m: "frames_on_plat(count,3) = jjj"), so this is
            % just a histogram of that column, one count per tone index.
            % n_tones_this_session is read from OnPlatPerOnPlat/OnPlatPer's
            % own length rather than assumed to be 9, so a shorter legacy
            % session still gets NaN-padding (not a misleading 0) beyond the
            % tones it actually had - same convention as Plat_success_vector.
            % SV, September 3, 2026: I added the Plat_ pair alongside, so the
            % zone_visits tab's new time-course chart can show platform visit
            % trends too (not just reward).
            rows(row_ind).Plat_tone_visit_vec = tone_visit_vector( ...
                Analysis_platform.CSp.DurOnPlat, numel(Analysis_platform.CSp.OnPlatPerOnPlat), max_success_tones);
            rows(row_ind).Plat_iti_visit_vec = tone_visit_vector( ...
                Analysis_platform.ITI.DurOnPlat, numel(Analysis_platform.ITI.OnPlatPer), max_success_tones);
            rows(row_ind).Reward_tone_visit_vec = tone_visit_vector( ...
                Analysis_reward.CSp.DurOnPlat, numel(Analysis_reward.CSp.OnPlatPerOnPlat), max_success_tones);
            rows(row_ind).Reward_iti_visit_vec = tone_visit_vector( ...
                Analysis_reward.ITI.DurOnPlat, numel(Analysis_reward.ITI.OnPlatPer), max_success_tones);
            % SV, September 3, 2026: I added - the reward-zone Merged (combined
            % tone+ITI cycle) fields, per SV's request that Habituation not be
            % split into Tone/ITI (see the changelog where these fields are
            % declared on "rows", above, for the full reasoning). Read off
            % Analysis_reward specifically (not platform) since the redesigned
            % hab_reward_rate tab is about reward-zone behaviour. Guarded with
            % isfield: Analysis.Merged only exists on sessions
            % BehDEPOT_Analysis_SVv5.m was told were habituation, so a non-Hab
            % session (or a Hab session analyzed before v5 existed) just leaves
            % these blank rather than erroring the whole session out.
            if isfield(Analysis_reward, 'Merged')
                M = Analysis_reward.Merged;
                rows(row_ind).Merged_PerTimeInROI = pad_to_len(M.PerTimeInROI, max_success_tones);
                rows(row_ind).Merged_Visits = pad_to_len(M.Visits, max_success_tones);
                rows(row_ind).Merged_Dist = pad_to_len(M.Dist_cm, max_success_tones);
                rows(row_ind).Merged_Dur = pad_to_len(M.Dur_s, max_success_tones);
            end
            % SV, September 3, 2026 (later same day): I added - the platform
            % zone's own Merged.PerTimeInROI/Visits (see the "rows" struct
            % changelog above for why this is a separate read from the
            % reward-zone Merged fields above).
            if isfield(Analysis_platform, 'Merged')
                Mp = Analysis_platform.Merged;
                rows(row_ind).Plat_Merged_PerTimeInROI = pad_to_len(Mp.PerTimeInROI, max_success_tones);
                rows(row_ind).Plat_Merged_Visits = pad_to_len(Mp.Visits, max_success_tones);
            end
            % SV, August 24, 2026: I added - locomotion, taken from the platform
            % Analysis file. Analysis.Locomotion is ROI-independent (v4 writes
            % identical values into both the platform and reward files), so
            % reading it off the platform one is arbitrary but sufficient.
            % Guarded with isfield so an Analysis_DT_*.mat produced by SVv3 or
            % earlier - which has no Locomotion struct - leaves blank cells
            % instead of erroring the whole session out.
            if isfield(Analysis_platform, 'Locomotion')
                L = Analysis_platform.Locomotion;
                rows(row_ind).Loco_BL_dist = L.BL.Dist_cm;
                rows(row_ind).Loco_BL_dur  = L.BL.Dur_s;
                rows(row_ind).Loco_tone_dist = pad_to_len(L.CSp.Dist_cm, max_success_tones);
                rows(row_ind).Loco_tone_dur  = pad_to_len(L.CSp.Dur_s,   max_success_tones);
                rows(row_ind).Loco_iti_dist  = pad_to_len(L.ITI.Dist_cm, max_success_tones);
                rows(row_ind).Loco_iti_dur   = pad_to_len(L.ITI.Dur_s,   max_success_tones);
                rows(row_ind).Loco_px2cm = L.px2cm;
            else
                warning(['%s / %s has no Analysis.Locomotion - re-run ' ...
                    'BehDEPOT_Analysis_SVv4.m to populate the locomotion tab for it.'], ...
                    condition_name, current_video);
            end
            %
        catch ME
            warning('%s / %s failed, leaving blank row: %s', condition_name, current_video, ME.message);
            failed_sessions(end+1,:) = {condition_name, current_video, ME.message}; %#ok<AGROW>
        end
    end
end

n_rows = numel(rows);
% SV, September 28, 2026: I added the first branch - excluding every animal
% in the exclusion dialog (e.g. "Select All" there, which EXCLUDES, unlike
% "Check All" in the folder window, which includes) used to land on the
% "no real session folders" message, which sent SV looking for a missing-data
% problem that did not exist.
if n_rows == 0 && ~isempty(excluded_rows)
    error(['Every session was excluded in the subject-exclusion dialog (%d session(s), ' ...
        'subject(s) %s), so there is nothing left to analyse. Run again and leave at ' ...
        'least one subject unticked there - ticked means EXCLUDED.'], ...
        numel(excluded_rows), strjoin(arrayfun(@(x) sprintf('#%d', x), excluded_subjects, 'uni', 0), ', '));
elseif n_rows == 0
    error('No real session folders found across the selected condition folder(s).');
end

if isempty(failed_sessions)
    fprintf('\nAll %d session(s) across %d condition folder(s) processed successfully.\n', n_rows, length(selected_conditions));
else
    fprintf('\n%d session(s) failed (left blank):\n', size(failed_sessions,1));
    for f = 1:size(failed_sessions,1)
        fprintf('  %s / %s: %s\n', failed_sessions{f,1}, failed_sessions{f,2}, failed_sessions{f,3});
    end
end

% SV, August 23, 2026: I added
% (no v5 equivalent - "rows" was previously left in whatever order the
% condition-folder GUI selection + each folder's dir() listing happened to
% produce, which is not chronological. Sorting it here, once, before either
% output tab is built, is what makes BOTH "all tones" (which just writes
% rows in array order) AND the 3 binned tabs (whose day blocks come from
% unique([br.Day],'stable') - first-occurrence order - on a "br" array
% that's itself built by looping over "rows" in order) come out
% chronological, without duplicating this logic in bin_rows too.)
%% Sort sessions into chronological day order (per SV's request, 2026-08-23)
% Canonical experimental day sequence - the single source of truth for
% "chronological" everywhere in this script. Update this list (not the sort
% logic below) if new day types get added to the task.
% SV, September 3, 2026: I changed
% day_order = ["HabD1s1", "HabD1s2", "HabD2s1", "HabD2s2", ...
%     "TrainD1s1", "TrainD1s2", "TrainD2s1", "TrainD2s2", "RetrS1", "RetrS2"];
% to this - v8/PVFP changes the task structure: each day is now ONE session
% (no more s1/s2 sub-sessions within a day), there are 3 habituation days
% instead of 2, 3 training days instead of 2, and a single retrieval day
% instead of two. Verified 2026-09-03 against the real folder names on disk
% (E:\2026-08-20_PVcre.Fp_PMA_TMS): sham_HabD1/HabD2/HabD3, sham_TrainD1/
% TrainD2/TrainD3, sham_Retr (and the tms_ equivalents) - no "s1"/"s2" suffix
% anywhere. A folder name that doesn't match this list (e.g. a leftover
% DCSP-cohort "RetrS1") still sorts to the end with a warning rather than
% erroring - see the unmatched_days handling below - so this script keeps
% working on older data, just not chronologically ordered against the new days.
% SV, September 25, 2026: I changed
% day_order = ["HabD1", "HabD2", "HabD3", "TrainD1", "TrainD2", "TrainD3", "Retr"];
% to this - day_order is now picked by the session-layout block near the top
% of this script (day_order_pvfp vs day_order_dcsp), so both cohorts sort
% chronologically instead of one of them falling through to the
% unmatched-days warning below. Nothing else in this sort changed; the
% unmatched-day fallback still catches genuinely new day types.
% (day_order was assigned above - kept as a no-op assert here so this block
% still reads as the place where the sort key is established.)
assert(exist('day_order', 'var') == 1 && ~isempty(day_order), ...
    'day_order was not set by the session-layout block near the top of this script.');

% SV, September 25, 2026: I added - flag sessions whose tone count collapsed,
% which is the failure mode waiting for SV in the DCSP habituation folders.
% Checked 2026-09-25 across all 39 DCSP Hab sessions: the earlier animals
% (DCSP_14/17/20, DCSP_18/21) have a normal six-tone csp_cue_frames.csv, but
% the later ones (DCSP_22/23/25/26) have a single row spanning the ENTIRE
% session - e.g. "115,45113", a 44,998-frame "tone". Nothing downstream
% errors on that: it arrives here as a one-tone session, pads to NaN, and its
% whole-session average lands in the "Tones 1-3" bin looking like a perfectly
% ordinary trial. That is a wrong number, not a missing one, so it gets a
% warning rather than being silently averaged in.
%
% The test is relative to the best session on the same day, so it does not
% fire on the genuine 4- and 5-tone Train/Retr sessions (max 6 -> threshold
% 3), only on a real collapse. Sessions that failed to load (N_tones NaN) are
% already reported separately above and are skipped here.
row_days_nt = strings(1, n_rows);
row_ntones = nan(1, n_rows);
for i = 1:n_rows
    row_days_nt(i) = day_from_condition(rows(i).Condition);
    if ~isempty(rows(i).N_tones)
        row_ntones(i) = rows(i).N_tones;
    end
end
degenerate_msgs = strings(0);
for d = unique(row_days_nt)
    in_day = (row_days_nt == d) & ~isnan(row_ntones);
    if ~any(in_day), continue; end
    day_best = max(row_ntones(in_day));
    if day_best < 2, continue; end % a whole day of one-tone sessions has no baseline to compare against
    flagged = find(in_day & (row_ntones < day_best / 2));
    for f = flagged
        this_msg = sprintf('%s / %s: %d tone(s) vs %d on this day', ...
            rows(f).Condition, rows(f).Subject, row_ntones(f), day_best);
        degenerate_msgs(end+1) = this_msg; %#ok<AGROW>
    end
end
if ~isempty(degenerate_msgs)
    warning(['%d session(s) recorded far fewer tones than others on the same day. ' ...
        'A single-tone session is usually a cue file that degenerated into one ' ...
        'whole-session window, in which case its binned values are session averages ' ...
        'wearing a tone label - re-run calcCueFrames for it or exclude the subject. ' ...
        'Affected:' newline '  %s'], numel(degenerate_msgs), strjoin(degenerate_msgs, [newline '  ']));
end
%

day_ranks = zeros(1, n_rows);
unmatched_days = strings(0);
for i = 1:n_rows
    d = day_from_condition(rows(i).Condition); % strips the sham_/tms_ prefix - see function below
    idx = find(day_order == d, 1);
    if isempty(idx)
        % Day not in the canonical list (e.g. a not-yet-added day type, or a
        % Condition name that doesn't parse as expected) - sort it after every
        % known day rather than erroring, so this script keeps working as new
        % day types get added over time, per SV's "someday they will be [present]"
        day_ranks(i) = numel(day_order) + 1;
        unmatched_days(end+1) = d; %#ok<AGROW>
    else
        day_ranks(i) = idx;
    end
end
if ~isempty(unmatched_days)
    warning(['%d day(s) not found in the chronological day_order list, sorted to the end ' ...
        '(original relative order preserved): %s'], ...
        numel(unique(unmatched_days)), strjoin(unique(unmatched_days), ', '));
end
% sort() is stable, so rows sharing a day (or sharing the "unmatched" fallback
% rank) keep their original relative order rather than getting reshuffled.
[~, chrono_sort_idx] = sort(day_ranks);
rows = rows(chrono_sort_idx);
%

%% Write formatted .xlsx
metric_names = ["CSp_plat_time", "CSp_reward_time", "ITI_plat_time", "ITI_reward_time"];
% SV, August 21, 2026: I added - the 4 new session-level scalar columns (see
% v6 changelog above), kept as a separate list from metric_names since
% they're single values per session, not tone1..toneN groups like every
% entry in metric_names - write_all_tones_tab lays them out differently.
% SV, August 23, 2026: I changed
% scalar_metric_names = ["Plat_successful_trials", "Reward_successful_trials", ...
%     "Plat_total_visits", "Reward_total_visits"];
% to this (added the tone/ITI visit-count breakdown next to each existing
% total, per SV's request):
% SV, August 23, 2026: I changed (second edit same day - dropped
% "Reward_successful_trials" from this list; see changelog at top of file):
% SV, August 23, 2026: I changed (third edit same day - added
% "proportion_successful" at the FRONT, per SV's request that it come before
% Plat_successful_trials, plus a parallel is-integer flag per column since
% this one is a 0-1 proportion and needs "0.000" formatting while every
% other scalar column is a raw count and should stay integer-formatted):
scalar_metric_names = ["proportion_successful", "Plat_successful_trials", ...
    "Plat_total_visits", "Plat_tone_visits", "Plat_iti_visits", ...
    "Reward_total_visits", "Reward_tone_visits", "Reward_iti_visits"];
scalar_is_integer = [false, true, true, true, true, true, true, true];
% SV, August 23, 2026: I added - which scalar columns get the same live
% gray/red Color Scale + zero-value font conditional formatting that the
% tone metric columns (e.g. ITI_reward_time) already get, per SV's request.
% Only proportion_successful qualifies: that CF is a fixed 0->1 gradient, so
% it's only meaningful for a 0-1 proportion. The count columns stay
% unformatted - a raw count of 2 vs 20 would both just peg the top of a 0-1
% scale, which would be actively misleading.
scalar_apply_gradient = [true, false, false, false, false, false, false, false];
%
out_filename = fullfile(P.root_directory, sprintf('pma_extractor_combined_%s.xlsx', datestr(now,'yyyymmdd_HHMMSS')));

% SV, August 21, 2026: I changed
% write_formatted_xlsx(rows, metric_names, max_tones, out_filename);
% to this (threads scalar_metric_names through to the "all tones" tab only -
% the binned tabs' own write_binned_tab call sites below are intentionally
% untouched, per SV's choice):
% SV, August 23, 2026: I changed
% write_formatted_xlsx(rows, metric_names, scalar_metric_names, max_tones, out_filename);
% to this (threads the new per-column scalar_is_integer flags through):
% SV, August 23, 2026: I changed it again to this (adds scalar_apply_gradient
% for the proportion_successful conditional formatting, plus the tone-bin
% definitions the new "successful_trials" tab is built from):
write_formatted_xlsx(rows, metric_names, scalar_metric_names, scalar_is_integer, ...
    scalar_apply_gradient, success_bin_ranges, success_bin_labels, max_tones, out_filename);
%

fprintf('\nWrote formatted table (%d rows) to: %s\n', n_rows, out_filename);

% SV, September 3, 2026: I added - the optional Freezing Map PDF, per SV's
% request (see select_folders_gui's new checkbox / the PX_pdf headless
% variable, above). Run after the .xlsx is safely written, wrapped in its
% own try/catch so a PDF-building problem (e.g. exportgraphics failing on an
% older MATLAB, or a genuinely corrupt .jpg) can't take down a report that
% otherwise finished successfully.
% SV, September 25, 2026: I added the figure report call here, beside the
% freezing-map one and inside the same kind of try/catch - a plotting problem
% must not cost the workbook, which is already written by this point.
if report_sections.enabled
    try
        write_pma_report_pdf(rows, P.root_directory, day_order, ...
            success_bin_ranges, success_bin_labels, report_sections);
    catch ME
        warning('Figure report PDF failed (workbook is unaffected): %s', ME.message);
    end
end
%

if build_pdf
    try
        write_freezing_map_pdf(rows, P.root_directory, day_order, excluded_rows);
    catch ME
        warning('Freezing Map PDF failed: %s. The .xlsx report above is unaffected.', ME.message);
    end
end
%

%%
% SV, September 3, 2026: I added this whole function (no v7 equivalent), at
% SV's request: a PDF, one page per animal, showing that animal's
% "Freezing Map.jpg" (written by BehaviorDEPOT into each session's
% *_analyzed folder) across every day it ran, left-to-right in chronological
% (day_order) sequence, "so I can see their activity evolve over time".
%
% Reads rows(i).FreezingMapPath - the path to that session's Freezing Map.jpg
% if BehaviorDEPOT wrote one (collected during the main session loop, above -
% see where Analysis_DT_platform.mat is loaded), '' otherwise. A session with
% no Freezing Map.jpg still gets its slot in the row, labelled with the day
% name and a placeholder, so a missing day is visible as a gap rather than
% silently shifting every later day one slot to the left.
%
% day_order is the SAME canonical chronological list the main script sorts
% "rows" by (see the top of this file) - reused here rather than trusting
% "rows"'s own array order, since scan/exclusion could in principle leave
% gaps that don't matter for the main sort but would matter for a
% left-to-right "watch this mouse over time" reading.
function write_freezing_map_pdf(rows, out_dir, day_order, excluded_rows)
if nargin < 4, excluded_rows = struct('Condition', {}, 'Subject', {}, 'FreezingMapPath', {}); end
% SV, September 25, 2026: I rewrote this function's page layout. It used to
% build one content-sized figure per animal, which exportgraphics then cropped
% to a short wide page - 14 animals meant 14 oddly-shaped pages with most of
% each one empty. Per SV's review of FreezingMap_ByAnimal_20260925_151219.pdf:
%   - pages are 8.5 x 11 in Letter now, like the figure report;
%   - the same layout is kept (one row of days per animal, chronological), but
%     several animals fit on a page because the vertical gap between rows is
%     about a quarter of what it was and the gap between an animal's title and
%     its maps about half;
%   - each animal's title names its experimental group, e.g.
%     "DCSP 10 Freezing Maps - Tms", so a page can be read without cross-
%     referencing the condition folders.
%
% Maps keep their true aspect ratio (the Freezing Map.jpg files are 1272x1070,
% so 0.841 tall per unit wide); the row height is derived from the image rather
% than assumed, so a differently shaped map still lays out correctly.
%
% SV, September 25, 2026 (same day, second pass): pages export at 1000 dpi.
% SV: "the resolution here is terrible... it needs to be as high as the actual
% activity map so i can see detail when i zoom in". The first version used
% ContentType 'image' at 200 dpi, which left each 1272x1070 map rendered into
% roughly 240 px of page - unreadable when zoomed. Measured alternatives on one
% real map (edge energy of a zoomed crop, higher is more surviving detail):
%     vector          702x592 per map   4.92
%     image  600 dpi                    5.82
%     image 1000 dpi                    6.74
% Vector loses because MATLAB resamples embedded images down to the rendered
% panel size (~1.2 in wide here) rather than keeping their native pixels. At
% 1000 dpi a panel is ~1220 px across, which matches the 1272 px source, so
% this is the setting that actually satisfies "as high as the activity map".
% The cost is file size - expect tens of MB for a full cohort.

% SV, September 27, 2026: excluded animals are appended here so they get a row
% of maps too, flagged in the title. They were filtered out of "rows" long
% before this point, so they cannot leak into any other output.
is_excluded_row = [false(1, numel(rows)), true(1, numel(excluded_rows))];
for ex = 1:numel(excluded_rows)
    rows(end+1).Condition = excluded_rows(ex).Condition; %#ok<AGROW>
    rows(end).Subject = excluded_rows(ex).Subject;
    rows(end).FreezingMapPath = excluded_rows(ex).FreezingMapPath;
end

n = numel(rows);
subj_nums = nan(1, n); subj_labels = strings(1, n);
has_map = false(1, n);
for i = 1:n
    [num, lbl] = parse_subject(rows(i).Subject);
    subj_nums(i) = num;
    subj_labels(i) = string(lbl);
    has_map(i) = isfield(rows, 'FreezingMapPath') && ~isempty(rows(i).FreezingMapPath) && isfile(rows(i).FreezingMapPath);
end
if ~any(has_map)
    warning(['write_freezing_map_pdf: no session in this run has a Freezing Map.jpg ' ...
        '(re-run BehaviorDEPOT Data Prep/Behavior Analysis if you expect one) - PDF not created.']);
    return
end

uniq_nums = sort(unique(subj_nums(~isnan(subj_nums))));
if isempty(uniq_nums)
    warning('write_freezing_map_pdf: no subject numbers could be parsed from any session - PDF not created.');
    return
end

pdf_filename = fullfile(out_dir, sprintf('ActivityMap_ByAnimal_%s.pdf', datestr(now,'yyyymmdd_HHMMSS'))); %#ok<TNOW1,DATST>
wrote_any = false;

% Widest animal decides the column width, so every animal's days line up
% down the page even when one animal is missing a session.
max_days = 0;
for un = uniq_nums
    max_days = max(max_days, numel(find(subj_nums == un)));
end
if max_days == 0, return; end

margin    = 0.045;
title_h   = 0.016;   % animal title band
title_gap = 0.004;   % title -> maps  (was ~2x this)
row_gap   = 0.010;   % between animals (was ~4x this)
day_lbl_h = 0.012;   % per-day caption above each map

img_aspect = 0.841;  % refined from the first image actually read, below
col_w = (1 - 2*margin) / max_days;
map_h = col_w * (8.5/11) * img_aspect;
row_h = title_h + title_gap + day_lbl_h + map_h + row_gap;

fig = []; y = 1 - margin;

for un = uniq_nums
    idx = find(subj_nums == un);

    ranks = nan(1, numel(idx));
    for j = 1:numel(idx)
        d = day_from_condition(rows(idx(j)).Condition);
        rk = find(day_order == d, 1);
        if isempty(rk), rk = numel(day_order) + 1; end
        ranks(j) = rk;
    end
    [~, ord] = sort(ranks);
    idx = idx(ord);

    % new page when this animal's row will not fit
    if isempty(fig) || ~isgraphics(fig) || (y - row_h) < margin
        if ~isempty(fig) && isgraphics(fig)
            try
                exportgraphics(fig, pdf_filename, 'Append', wrote_any, 'ContentType', 'image', 'Resolution', 1000);
                wrote_any = true;
            catch ME
                warning('write_freezing_map_pdf: could not write a page: %s', ME.message);
            end
            close(fig);
        end
        fig = figure('Units', 'inches', 'Position', [0 0 8.5 11], 'Color', 'w', ...
            'Visible', 'off', 'PaperUnits', 'inches', 'PaperSize', [8.5 11], ...
            'PaperPosition', [0 0 8.5 11]);
        % Same trick as the figure report: exportgraphics crops to drawn
        % content, so this invisible full-page rectangle pins the page to Letter.
        annotation(fig, 'rectangle', [0 0 1 1], 'Color', 'w', 'FaceColor', 'none');
        y = 1 - margin;
    end

    grp = classify_group(rows(idx(1)).Condition);
    if grp == "tms", grp_disp = 'Tms'; else, grp_disp = 'Sham'; end
    % "(EXCLUDED)" in italics when this animal was dropped from the analysis,
    % per SV. \it is the TeX italic switch; the interpreter is already 'tex'
    % here because the group name is color-marked up the same way.
    if any(is_excluded_row(idx))
        excl_tex = '  \it\color[rgb]{0.35,0.35,0.35}(EXCLUDED)';
    else
        excl_tex = '';
    end
    grp_tex = [report_color_tex(grp) grp_disp]; % SV, September 28, 2026: I changed - follows the picked group color
    annotation(fig, 'textbox', [margin, y - title_h, 1 - 2*margin, title_h], ...
        'String', sprintf('%s Activity Maps - %s%s', upper(char(subj_labels(idx(1)))), grp_tex, excl_tex), ...
        'FontSize', 9, 'FontWeight', 'bold', 'Color', 'k', 'EdgeColor', 'none', ...
        'VerticalAlignment', 'middle', 'Interpreter', 'tex');

    map_top = y - title_h - title_gap - day_lbl_h;
    for j = 1:numel(idx)
        x0 = margin + (j-1)*col_w;
        ax = axes(fig, 'Position', [x0 + 0.004, map_top - map_h, col_w - 0.008, map_h]); %#ok<LAXES>
        d = char(day_from_condition(rows(idx(j)).Condition));
        if has_map(idx(j))
            try
                im = imread(rows(idx(j)).FreezingMapPath);
                imshow(im, 'Parent', ax);
            catch ME
                cla(ax); text(ax, 0.5, 0.5, 'unreadable', 'HorizontalAlignment', 'center', 'FontSize', 6);
                axis(ax, [0 1 0 1]); axis(ax, 'off');
                warning('write_freezing_map_pdf: could not read %s: %s', rows(idx(j)).FreezingMapPath, ME.message);
            end
        else
            text(ax, 0.5, 0.5, 'no map', 'HorizontalAlignment', 'center', 'FontSize', 6);
            axis(ax, [0 1 0 1]); axis(ax, 'off');
        end
        title(ax, d, 'Interpreter', 'none', 'FontSize', 6.5, 'FontWeight', 'bold', 'Color', 'k');
    end

    y = y - row_h;
end

if ~isempty(fig) && isgraphics(fig)
    try
        exportgraphics(fig, pdf_filename, 'Append', wrote_any, 'ContentType', 'image', 'Resolution', 1000);
        wrote_any = true;
    catch ME
        warning('write_freezing_map_pdf: could not write the last page: %s', ME.message);
    end
    close(fig);
end

if wrote_any
    fprintf('Wrote Activity Map PDF (Letter pages, several animals per page) to: %s\n', pdf_filename);
else
    warning('write_freezing_map_pdf: nothing was written - PDF not created.');
end
end

%%
function out = pad_to_len(in, target_len)
% Unchanged from v3.
in = in(:)';
out = nan(1, target_len);
if isempty(in)
    return
end
n = min(numel(in), target_len);
out(1:n) = in(1:n);
end

%%
% SV, September 3, 2026: I added - histogram of a DurOnPlat matrix's bout-index
% column (col 3, per calc_time_plat.m) into a 1 x target_len per-tone/per-ITI
% visit-COUNT vector. n_windows is the number of real tone/ITI windows this
% session actually had (from OnPlatPerOnPlat's/OnPlatPer's own length, not
% assumed to be 9): those positions get a real count (0 if the animal never
% entered that window), everything beyond n_windows is left NaN so a shorter
% session's missing tones read as blank, not a misleading zero-visit count -
% same convention pad_to_len/Plat_success_vector already use.
function vec = tone_visit_vector(dur_on_plat, n_windows, target_len)
vec = nan(1, target_len);
if n_windows < 1
    return
end
n_windows = min(n_windows, target_len);
vec(1:n_windows) = 0;
if isempty(dur_on_plat)
    return
end
idx = dur_on_plat(:,3);
idx = idx(idx >= 1 & idx <= n_windows);
for k = 1:numel(idx)
    vec(idx(k)) = vec(idx(k)) + 1;
end
end

%%
%%
% SV, September 25, 2026: I added - decides whether a condition folder has
% anything this script can actually read, so select_folders_gui can list it
% without a checkbox when it does not.
%
% The test deliberately mirrors the row loop exactly, so the dialog can never
% offer a folder the loop would then skip: ignore any folder whose name
% contains "Results" (prepBatch's rule), require exactly one *analyzed
% subfolder (the row loop's own "is this a real session" test), and require
% both Analysis_DT_platform.mat and Analysis_DT_reward.mat inside it - those
% are what BehDEPOT_Analysis_SVv5 writes and what this script loads.
%
% Returns one entry per input folder: .ready is how many sessions are usable,
% .sessions how many candidate session folders were seen at all. A partially
% ready folder stays selectable, because the row loop already handles a
% session that fails to load by leaving a blank row and reporting it.
function elig = scan_condition_eligibility(root_directory, folder_list)

elig = struct('name', {}, 'ready', {}, 'sessions', {});
need = {'Analysis_DT_platform.mat', 'Analysis_DT_reward.mat'};

for i = 1:numel(folder_list)
    cond_path = fullfile(root_directory, char(folder_list(i)));
    ready = 0; sessions = 0;

    d = dir(cond_path);
    d = d([d.isdir] & ~startsWith({d.name}, '.'));
    for j = 1:numel(d)
        if contains(d(j).name, 'Results', 'IgnoreCase', true)
            continue   % prepBatch skips these, so they are not sessions
        end
        sessions = sessions + 1;

        sess_path = fullfile(cond_path, d(j).name);
        an = dir(fullfile(sess_path, '*analyzed'));
        an = an([an.isdir]);
        if numel(an) ~= 1
            continue   % same test the row loop uses to recognise a session
        end

        have = true;
        for k = 1:numel(need)
            if ~isfile(fullfile(sess_path, an(1).name, need{k}))
                have = false;
                break
            end
        end
        if have, ready = ready + 1; end
    end

    elig(i) = struct('name', string(folder_list(i)), 'ready', ready, 'sessions', sessions); %#ok<AGROW>
end
end

function video_folder_list = prepBatch(video_directory)
% Unchanged from v3 - lists the immediate subfolders of video_directory (used here to list
% candidate session folders within a single, already-selected condition folder).
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
% Unchanged from v3 - lists the immediate subfolders of root_dir (used to list the condition
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
% SV, September 3, 2026: I changed the function signature
% function selected = select_folders_gui(folder_list)
% to this - added a second output, build_pdf, and the checkbox that drives
% it, per SV's request for a "make a PDF of Freezing Map.jpg by animal"
% option somewhere in the GUI flow. Placed here (the first dialog of the
% run, decided up front for the whole batch) rather than in the later
% habituation/exclusion dialogs, since it's a whole-run option, not a
% per-day or per-subject one. Default UNCHECKED per SV's explicit request -
% existing callers that only capture the first output (selected_conditions
% = select_folders_gui(...)) are unaffected; see write_freezing_map_pdf for
% what turning it on actually builds.
function [selected, build_pdf, report_sections, colors] = select_folders_gui(folder_list, root_directory)
% Unchanged from v3 - shows a checkbox list of folder_list (all checked by default) with
% "Check All" / "Uncheck All" / "Run" buttons. Returns the string array of folder names
% left checked when "Run" is clicked, or an empty string array if the window is closed
% without clicking Run.

n = numel(folder_list);
row_h = 24;
list_h = n * row_h + 10;
fig_h = min(820, 305 + list_h); % SV, Sept 25: taller again for the output-selection group
                                % SV, Sept 28: +60 for the group-color pickers
fig_w = 420;

fig = uifigure('Name', 'Select condition folders to include', 'Position', [100 100 fig_w fig_h]);
fig.UserData.ran = false;
fig.CloseRequestFcn = @(src, ~) uiresume(src);

uilabel(fig, 'Text', 'Select folders to include:', ...
    'Position', [20 fig_h-30 fig_w-40 20], 'FontWeight', 'bold');

% SV, September 25, 2026: I added - a folder with no BehDEPOT_Analysis_SVv5
% output cannot contribute a single row, so it is now LISTED but given no
% checkbox, per SV: "you can list all the files you have here, but not the
% actual check-box since it cannot be included in the analysis". Seeing the
% folder greyed out says "known about, not ready yet", which is the useful
% signal - silently hiding it would look like the folder had gone missing.
elig = scan_condition_eligibility(root_directory, folder_list);

panel = uipanel(fig, 'Position', [20 258 fig_w-40 fig_h-298], 'Scrollable', 'on');
cb = gobjects(n, 1);   % left unset for ineligible folders - isgraphics() is the test below
for i = 1:n
    ypos = [10, list_h - i*row_h, fig_w-80, row_h];
    % SV, September 28, 2026: I added - a folder that is neither sham_ nor
    % tms_ is listed but cannot be ticked (excluded by default, per SV), the
    % same treatment as a folder with no analysis output below.
    if condition_group(folder_list(i)) == ""
        uilabel(panel, 'Text', sprintf('%s   - not sham_/tms_, excluded', folder_list(i)), ...
            'Position', ypos + [22 0 -22 0], 'FontColor', [0.55 0.55 0.55]);
        continue
    end
    if elig(i).ready > 0
        if elig(i).ready < elig(i).sessions
            txt = sprintf('%s   (%d of %d sessions ready)', folder_list(i), elig(i).ready, elig(i).sessions);
        else
            txt = sprintf('%s   (%d)', folder_list(i), elig(i).ready);
        end
        cb(i) = uicheckbox(panel, 'Text', txt, 'Value', true, 'Position', ypos);
    else
        uilabel(panel, 'Text', sprintf('%s   - no Analysis_DT_*.mat', folder_list(i)), ...
            'Position', ypos + [22 0 -22 0], 'FontColor', [0.55 0.55 0.55]);
    end
end

% SV, September 3, 2026: I added - the Freezing Map PDF option, default
% unchecked. See write_freezing_map_pdf for what it builds.
% SV, September 25, 2026: I changed - one Freezing Map checkbox became an
% output group, per SV: "you can put an option at the beginning to select the
% desired output with checkboxes". The figure report's four sections are
% individually selectable because a full run of all four is a lot of pages.
pdf_cb = uicheckbox(fig, 'Text', 'Activity Map PDF (one page per animal)', ...
    'Value', false, 'Position', [20 236 fig_w-40 18]);
rep_cb = uicheckbox(fig, 'Text', 'Figure report PDF - sections:', ...
    'Value', false, 'Position', [20 216 fig_w-40 18], 'FontWeight', 'bold');
sec_cb = gobjects(4,1);
sec_names = {'Shocks Avoided', 'Locomotion', 'Proportion of Time in Zone', 'Zone Visits'};
for si = 1:4
    sec_cb(si) = uicheckbox(fig, 'Text', sec_names{si}, 'Value', true, 'Enable', 'off', ...
        'Position', [40 216-si*18 fig_w-60 18]);
end
rep_cb.ValueChangedFcn = @(src,~) set(sec_cb, 'Enable', matlab.lang.OnOffSwitchState(src.Value));

% SV, September 28, 2026: I added - a color per group, used by every output
% (workbook, figure report, activity maps). Rainbow-ordered list from
% group_palette; each dropdown item is filled with its own color where this
% MATLAB supports item styles, and the swatch beside it always shows the pick.
% Defaults (SV, 2026-09-28): Control Grey sham, UCLA Blue tms. Shock Red
% reproduces the pre-picker red look exactly.
[pal_names, pal_rgb] = group_palette();
col_dd = gobjects(2,1);
col_sw = gobjects(2,1);
grp_keys = ["sham", "tms"];
grp_text = ["Sham color:", "TMS color:"];
grp_default = ["Control Grey", "UCLA Blue"];
for gi = 1:2
    yy = 106 - (gi-1)*30;
    uilabel(fig, 'Text', grp_text(gi), 'Position', [20 yy 90 22], 'FontWeight', 'bold');
    col_dd(gi) = uidropdown(fig, 'Items', pal_names, 'Value', grp_default(gi), ...
        'Position', [110 yy 170 22]);
    col_sw(gi) = uipanel(fig, 'Position', [290 yy 110 22], 'BorderType', 'line');
    try
        for pk = 1:numel(pal_names) % not "k": setCheckboxes (nested) shares this workspace
            pc = pal_rgb(pk,:) / 255;
            if 0.299*pc(1) + 0.587*pc(2) + 0.114*pc(3) < 0.55, fc = [1 1 1]; else, fc = [0 0 0]; end
            addStyle(col_dd(gi), uistyle('BackgroundColor', pc, 'FontColor', fc), 'item', pk);
        end
    catch
        % item styles on dropdowns need R2023a+; the swatch still shows the pick
    end
    col_dd(gi).ValueChangedFcn = @(src,~) paintSwatch(src, col_sw(gi), pal_names, pal_rgb);
    paintSwatch(col_dd(gi), col_sw(gi), pal_names, pal_rgb);
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
build_pdf = false;
report_sections = struct('enabled', false, 'shocks', false, 'locomotion', false, ...
    'zone_time', false, 'zone_visits', false);
colors = struct('sham', "Control Grey", 'tms', "UCLA Blue");
if isvalid(fig)
    if fig.UserData.ran
        for gi = 1:2
            colors.(grp_keys(gi)) = string(col_dd(gi).Value);
        end
        for i = 1:n
            if isgraphics(cb(i)) && cb(i).Value
                selected(end+1) = folder_list(i); %#ok<AGROW>
            end
        end
        build_pdf = pdf_cb.Value;
        report_sections.enabled     = rep_cb.Value;
        report_sections.shocks      = rep_cb.Value && sec_cb(1).Value;
        report_sections.locomotion  = rep_cb.Value && sec_cb(2).Value;
        report_sections.zone_time   = rep_cb.Value && sec_cb(3).Value;
        report_sections.zone_visits = rep_cb.Value && sec_cb(4).Value;
    end
    delete(fig);
end

    function setCheckboxes(cb, val)
        for k = 1:numel(cb)
            if isgraphics(cb(k))   % ineligible folders have no checkbox to set
                cb(k).Value = val;
            end
        end
    end

    function markRun(fig)
        fig.UserData.ran = true;
        uiresume(fig);
    end

    function paintSwatch(dd, sw, names, rgb)
        sw.BackgroundColor = rgb(strcmp(names, dd.Value), :) / 255;
    end
end

%%
% SV, September 3, 2026 (later same day): I REWROTE this whole function
% again, per SV's hand-drawn sketch. Three changes from the same-day earlier
% rewrite:
%  1) Tone and ITI are no longer interleaved into one 8-category-per-day
%     chart. Train/Retr days now get TWO separate timecourse+summary chart
%     pairs - one for Tone windows only, one for ITI windows only - matching
%     the sketch's "Locomotion Train and Retr Timecourse (ITI)" / "...
%     (Tone)" rows. Each spans TrainD1->TrainD2->TrainD3->Retr with bins
%     1-3/4-6/7-9.
%  2) Habituation locomotion MOVED IN from hab_reward_rate (which no longer
%     computes it at all - see that function's changelog): one timecourse+
%     summary pair, using Analysis.Merged (combined tone+ITI trial cycles,
%     no Tone/ITI split - the tone never played on Hab days), spanning
%     HabD1->HabD2->HabD3, bins 1-3/4-6/7-9.
%  3) Each of those 3 timecourse charts drops the whole-range "1-9" bin (not
%     comparable to a 3-tone bin on the same line - same fix already applied
%     to successful_trials) into its OWN companion "Summary" bar chart
%     (build_summary_bar_chart, one Sham/TMS bar pair per day-block) shown
%     right next to it, per the sketch. See write_simple_trend_table_and_
%     chart for how a single (table, timecourse chart, summary chart)
%     triple is built - this function just calls it 6 times (Distance x 3
%     groups, Rate x 3 groups).
% The "interleaved, Hab-excluded" version from earlier today was kept further
% down as write_locomotion_tab_superseded_v3 until SV, September 28, 2026,
% when it and the two older superseded locomotion tabs were removed (nothing
% called them). It survives in out_of_date\pma_extractor_SVv11.m.
function write_locomotion_tab(Workbook, sheet_name, rows, zero_font_bgr, loco_bin_ranges, loco_bin_labels)

last_sheet = Workbook.Sheets.Item(Workbook.Sheets.Count);
Sheet = Workbook.Sheets.Add;
Sheet.Move([], last_sheet);
Sheet.Name = sheet_name;

% --- Which Hab days and which real (non-Hab) days are actually present,
% chronological - "rows" is pre-sorted upstream, so first-appearance order
% within each subset is already chronological, same trick every other tab
% uses (unique(...,'stable')).
n = numel(rows);
all_days = strings(1, n);
for i = 1:n
    all_days(i) = day_from_condition(rows(i).Condition);
end
is_hab_day = startsWith(all_days, 'Hab', 'IgnoreCase', true);
hab_days = unique(all_days(is_hab_day), 'stable');
real_days = unique(all_days(~is_hab_day), 'stable');

% Each of the 6 write_simple_trend_table_and_chart calls below needs its own
% clear block of hidden staging columns (column-hiding is whole-column, so
% two calls sharing a staging range would silently overwrite each other's
% chart-feeder cells even though they occupy different rows) - stage_base
% spaces them 150 columns apart, comfortably more than any one call needs.
stage_base = 150;

% SV, September 8, 2026: I changed this loop back to stacking Rate's 3
% blocks BELOW Distance's 3 blocks (both at column 1, one shared this_row
% cursor) instead of beside them - per SV's feedback that the September 3
% side-by-side layout put the Velocity plots too far out (column start 100,
% i.e. Excel column CV, since the generous gap below was sized for a
% worst-case AutoFit width rather than the table's actual width). Also
% renamed every chart title from the generic "Locomotion: ..." to
% "Track Length: ..." / "Velocity: ..." so the two metrics' charts stay
% distinguishable at a glance now that they're stacked (both used to share
% the identical title).
this_col = 1;
for m = ["Distance (cm)", "Rate (cm/s)"]
    if m == "Distance (cm)"
        val_hab  = @(k,br) bin_sum(rows(k).Merged_Dist, br);
        val_tone = @(k,br) bin_sum(rows(k).Loco_tone_dist, br);
        val_iti  = @(k,br) bin_sum(rows(k).Loco_iti_dist, br);
        y_title = 'Track length (cm)';
        title_prefix = 'Track Length';
    else
        val_hab  = @(k,br) bin_rate(rows(k).Merged_Dist, rows(k).Merged_Dur, br);
        val_tone = @(k,br) bin_rate(rows(k).Loco_tone_dist, rows(k).Loco_tone_dur, br);
        val_iti  = @(k,br) bin_rate(rows(k).Loco_iti_dist, rows(k).Loco_iti_dur, br);
        y_title = 'Velocity (cm/s)';
        title_prefix = 'Velocity';
    end

    if m == "Distance (cm)", this_row = 1; end % Distance starts the tab; Rate carries on from wherever Distance's last block ended
    this_row = write_simple_trend_table_and_chart(Sheet, this_row, this_col, stage_base, zero_font_bgr, ...
        rows, hab_days, loco_bin_ranges, loco_bin_labels, val_hab, ...
        sprintf('Habituation: %s (tone+ITI combined)', char(m)), 'auto', ...
        sprintf('%s: Habituation timecourse', title_prefix), y_title, 'auto', '0.0', ...
        sprintf('%s: Habituation summary', title_prefix));
    stage_base = stage_base + 150;

    this_row = write_simple_trend_table_and_chart(Sheet, this_row, this_col, stage_base, zero_font_bgr, ...
        rows, real_days, loco_bin_ranges, loco_bin_labels, val_iti, ...
        sprintf('Train/Retr: %s (ITI)', char(m)), 'auto', ...
        sprintf('%s: Train and Retr timecourse (ITI)', title_prefix), y_title, 'auto', '0.0', ...
        sprintf('%s: Train and Retr summary (ITI)', title_prefix));
    stage_base = stage_base + 150;

    % SV, September 8, 2026: I added the missing "this_row = " here - without
    % it, this_row stayed at the value left over from the ITI call above, so
    % Rate's Habituation block (the next iteration's first call) got written
    % starting at that SAME row instead of below this Tone block, silently
    % overwriting it. Same "carry this_row across every call" chaining every
    % other stacked block in this file already relies on.
    this_row = write_simple_trend_table_and_chart(Sheet, this_row, this_col, stage_base, zero_font_bgr, ...
        rows, real_days, loco_bin_ranges, loco_bin_labels, val_tone, ...
        sprintf('Train/Retr: %s (Tone)', char(m)), 'auto', ...
        sprintf('%s: Train and Retr timecourse (Tone)', title_prefix), y_title, 'auto', '0.0', ...
        sprintf('%s: Train and Retr summary (Tone)', title_prefix));
    stage_base = stage_base + 150;
end
end



%%
% SV, August 24, 2026: I added - small helpers for write_locomotion_tab.
function v = safediv(num, den)
if isempty(den) || isnan(den) || den == 0
    v = NaN;
else
    v = num / den;
end
end

function v = meanor(x)
x = x(~isnan(x));
if isempty(x), v = NaN; else, v = mean(x); end
end

function s = upper_first(c)
c = char(c);
if isempty(c), s = c; return; end
if strcmpi(c,'tms'), s = 'TMS'; else, s = [upper(c(1)) lower(c(2:end))]; end
end

%%
% SV, August 24, 2026: I added this whole function (no v6 equivalent).
% Builds the list of animals offered in the exclusion dialog by scanning the
% already-selected condition folders for real session folders, using the SAME
% "exactly one *_analyzed subfolder" test the main loop uses - so the dialog
% can never offer a subject that wouldn't have been analyzed anyway, and never
% omits one that would.
% Returns a struct array (one entry per unique animal number, ascending) with
% fields .num, .label and .sessions (the condition folders it appears in), so
% the dialog can show "DCSP_22 - 4 sessions (sham_RetrS1, ...)" rather than a
% bare number with no context for deciding.
function subjects = scan_available_subjects(root_directory, selected_conditions)

nums = [];
sess = {};
% SV, September 3, 2026: I added - labs, collected alongside nums/sess so the
% display label (whichever cohort prefix parse_subject actually matched on
% this animal's real folder name) survives to the "subjects" struct below,
% instead of a second hardcoded "DCSP_%d" reconstruction.
labs = {};
for c = 1:length(selected_conditions)
    condition_name = selected_conditions(c);
    video_directory = fullfile(root_directory, condition_name);
    if ~isfolder(video_directory), continue; end

    d = dir(video_directory);
    d = d([d.isdir]);
    d = d(~ismember({d.name}, {'.','..'}));

    for j = 1:numel(d)
        video_folder = fullfile(video_directory, d(j).name);
        if numel(dir(fullfile(video_folder,'*analyzed'))) ~= 1
            continue % not a real session folder - same test as the main loop
        end
        [num, lbl] = parse_subject(d(j).name);
        if isnan(num), continue; end

        idx = find(nums == num, 1);
        if isempty(idx)
            nums(end+1) = num;                            %#ok<AGROW>
            sess{end+1} = {char(condition_name)};         %#ok<AGROW>
            labs{end+1} = lbl;                             %#ok<AGROW>
        else
            sess{idx}{end+1} = char(condition_name);
        end
    end
end

[nums, order] = sort(nums);
sess = sess(order);
labs = labs(order);

% SV, September 3, 2026: I changed
% subjects(i).label = sprintf('DCSP_%d', nums(i));
% to this - hardcoded "DCSP_" no longer matches the PVFP cohort's subject
% IDs. labs{} (populated in the scan loop above, alongside nums/sess) carries
% the display label parse_subject actually derived from each animal's real
% folder name (e.g. "pvfp 30"), so the dialog shows the right cohort prefix
% instead of a hardcoded one - and this needs no further changes if a third
% cohort prefix shows up later, since it's just echoing what parse_subject saw.
subjects = struct('num', {}, 'label', {}, 'sessions', {});
for i = 1:numel(nums)
    subjects(i).num = nums(i);
    subjects(i).label = upper(strrep(labs{i}, ' ', '_')); % "pvfp 30" -> "PVFP_30"
    subjects(i).sessions = sess{i};
end
end

%%
% SV, August 24, 2026: I added this whole function (no v6 equivalent).
% The exclusion dialog SV asked for: appears immediately after Run is clicked
% on the condition-folder window, lists every animal found across the selected
% conditions, and returns the animal numbers to drop from the entire analysis.
%
% Deliberately inverted relative to select_folders_gui: that window is an
% INCLUDE list and starts all-checked, this one is an EXCLUDE list and starts
% all-UNCHECKED, so the default action (click Continue immediately) changes
% nothing and matches the pre-v7 behaviour. The button is labelled "Continue"
% rather than "Run" for the same reason - this is a second step in a flow that
% has already been started, not a new one.
%
% Closing the window without clicking Continue aborts the whole script rather
% than silently proceeding with no exclusions, matching how select_folders_gui
% treats a closed window - an ambiguous dismissal shouldn't quietly produce a
% full-cohort report that looks like a deliberate choice.
function excluded = select_exclusions_gui(subjects)

n = numel(subjects);
row_h = 26;
list_h = n * row_h + 10;
fig_h = min(700, 190 + list_h);
fig_w = 520;

fig = uifigure('Name', 'Exclude subjects from the analysis', 'Position', [100 100 fig_w fig_h]);
fig.UserData.confirmed = false;
fig.CloseRequestFcn = @(src, ~) uiresume(src);

uilabel(fig, 'Text', 'Tick any subjects to EXCLUDE from the entire analysis:', ...
    'Position', [20 fig_h-32 fig_w-40 20], 'FontWeight', 'bold');
uilabel(fig, 'Text', 'Leave all unticked to include everything. Exclusions apply to every tab.', ...
    'Position', [20 fig_h-52 fig_w-40 20], 'FontColor', [0.35 0.35 0.35]);

panel = uipanel(fig, 'Position', [20 90 fig_w-40 fig_h-150], 'Scrollable', 'on');
cb = gobjects(n, 1);
for i = 1:n
    s = subjects(i);
    txt = sprintf('%s   -   %d session(s): %s', s.label, numel(s.sessions), ...
        strjoin(s.sessions, ', '));
    cb(i) = uicheckbox(panel, 'Text', txt, 'Value', false, ...
        'Position', [10, list_h - i*row_h, fig_w-80, row_h]);
end

uibutton(fig, 'Text', 'Clear All', 'Position', [20 40 110 30], ...
    'ButtonPushedFcn', @(~, ~) setCheckboxes(cb, false));
uibutton(fig, 'Text', 'Select All', 'Position', [150 40 110 30], ...
    'ButtonPushedFcn', @(~, ~) setCheckboxes(cb, true));
uibutton(fig, 'Text', 'Continue', 'Position', [fig_w-140 40 120 30], ...
    'BackgroundColor', [0.2 0.7 0.3], 'FontColor', [1 1 1], ...
    'ButtonPushedFcn', @(~, ~) markConfirmed(fig));

uiwait(fig);

excluded = [];
aborted = true;
if isvalid(fig)
    if fig.UserData.confirmed
        aborted = false;
        for i = 1:n
            if cb(i).Value
                excluded(end+1) = subjects(i).num; %#ok<AGROW>
            end
        end
    end
    delete(fig);
end
if aborted
    error(['Subject exclusion window closed without clicking Continue. Aborting rather than ' ...
        'silently running with no exclusions.']);
end

    function setCheckboxes(cb, val)
        for k = 1:numel(cb)
            cb(k).Value = val;
        end
    end

    function markConfirmed(fig)
        fig.UserData.confirmed = true;
        uiresume(fig);
    end
end

%%
% SV, August 21, 2026: I changed the function signature
% function write_formatted_xlsx(rows, metric_names, max_tones, out_filename)
% to this (needs scalar_metric_names to pass through to write_all_tones_tab
% - see below):
% SV, August 23, 2026: I changed the function signature again
% function write_formatted_xlsx(rows, metric_names, scalar_metric_names, max_tones, out_filename)
% to this (carries scalar_is_integer through to write_all_tones_tab):
function write_formatted_xlsx(rows, metric_names, scalar_metric_names, scalar_is_integer, ...
    scalar_apply_gradient, success_bin_ranges, success_bin_labels, max_tones, out_filename)
%
% New in v4 - builds the formatted report via Excel COM automation (Windows + Excel
% required). Wrapped so Excel always gets closed/released, even if something errors partway
% through, to avoid leaving an orphaned EXCEL.EXE process running in the background.
%
% SV, July 22, 2026: I changed every cell/range reference in this function away from
% Sheet.Cells(row,col) / Sheet.Cells.Item(row,col) addressing to plain A1-notation range
% strings, e.g. Sheet.Range('C5') or Sheet.Range('C1:H1'), via the new col2letter() helper.
% First attempt (Cells(row,col) shorthand) crashed with MATLAB's "Index in position 1 exceeds
% array bounds" - MATLAB wasn't routing that shorthand through COM's default Item member.
% Second attempt (explicit Cells.Item(row,col)) crashed with "No method 'Item' with matching
% signature found" - the Item call itself wasn't resolving on this Cells interface either.
% A1-notation Range() strings are the most portable way to address cells across different
% MATLAB/Excel COM versions, since Range(char) takes a single unambiguous string argument
% with no method-overload resolution involved. Applied uniformly at every call site below
% rather than shown as a full line-by-line diff for each one, since it's the same mechanical
% substitution repeated many times - let me know if you'd rather see it spelled out per line.

zero_font_bgr = rgb_to_bgr([190 190 190]); % light gray font for zero-valued cells

% SV, July 24, 2026: I added
% (no v4 equivalent - the binned tabs used to carry their own MATLAB-computed literal
% averages and never needed to know the "all tones" tab's name/layout)
% SV, August 23, 2026: I changed
% all_tones_sheet_name = 'all tones';
% to this (spaces -> underscores in every tab name, per SV's request):
all_tones_sheet_name = 'all_tones'; % must match Sheet1.Name below - binned-tab formulas point here
%
all_tones_data_start_row = 3; % must match write_all_tones_tab's header_row1=1/header_row2=2/data_start_row=3
%

Excel = actxserver('Excel.Application');
Excel.Visible = false;
Excel.ScreenUpdating = false;
try
    Workbook = Excel.Workbooks.Add;
    Sheet1 = Workbook.Sheets.Item(1);
    Sheet1.Name = all_tones_sheet_name;
    % SV, August 21, 2026: I changed
    % write_all_tones_tab(Sheet1, rows, metric_names, max_tones, zero_font_bgr);
    % to this (threads scalar_metric_names through - see write_all_tones_tab
    % for the new scalar-column layout it adds):
    % SV, August 23, 2026: I changed
    % write_all_tones_tab(Sheet1, rows, metric_names, scalar_metric_names, max_tones, zero_font_bgr);
    % to this (threads the per-column scalar_is_integer flags through):
    write_all_tones_tab(Sheet1, rows, metric_names, scalar_metric_names, scalar_is_integer, ...
        scalar_apply_gradient, max_tones, zero_font_bgr);
    %

    % SV, August 23, 2026: I added - the new "successful_trials" tab, placed
    % directly after "all_tones" (the binned tabs below append themselves at
    % the end of the workbook, so they land after it; nothing references
    % tabs by position, only by name, so this ordering is purely cosmetic).
    write_successful_trials_tab(Workbook, 'successful_trials', rows, zero_font_bgr, ...
        success_bin_ranges, success_bin_labels);
    %

    % SV, August 24, 2026: I added - the "locomotion" tab, placed directly
    % after successful_trials (each tab writer appends itself at the end of the
    % workbook, so call order is tab order).
    % SV, August 24, 2026: I changed
    % write_locomotion_tab(Workbook, 'locomotion', rows, ...
    %     success_bin_ranges, success_bin_labels);
    % to this - the tab no longer bins by tone range (it is one block per
    % experimental day, with a single ALL-tones and ALL-ITIs total), so the
    % bin definitions are no longer needed here:
    % SV, September 3, 2026: I changed
    % write_locomotion_tab(Workbook, 'locomotion', rows);
    % back to needing the bin definitions again - the redesigned tab bins by
    % 1-3/4-6/7-9/1-9 once more (as a line time-course, not a bar chart - see
    % that function's changelog), and now needs zero_font_bgr for its
    % gradient conditional formatting too:
    % SV, September 8, 2026: I renamed this tab from "locomotion" to
    % "locomotion_timecourse", per SV's request.
    write_locomotion_tab(Workbook, 'locomotion_timecourse', rows, zero_font_bgr, ...
        success_bin_ranges, success_bin_labels);
    %

    % SV, September 3, 2026 (later same day): I REMOVED the "hab_reward_rate"
    % tab call that used to be here. It briefly existed as a dedicated
    % Habituation-only tab (proportion of time in reward zone, reward zone
    % visits, and - until the locomotion redesign - locomotion), but per SV:
    % once locomotion moved into the locomotion tab (Habituation Timecourse+
    % Summary group, using the same Analysis.Merged data) and visits moved
    % into zone_visits (same treatment, both Platform and Reward), nothing
    % unique was left in hab_reward_rate - "you can probably delete the
    % hab_reward_rate tab entirely since it's covered now". The
    % write_hab_reward_tab function itself is left in the file, unused
    % (nothing calls it), rather than deleted outright, in case SV wants a
    % dedicated Hab-only view back later; it was NOT renamed *_superseded
    % since - unlike the locomotion/visits redesigns - there's no direct
    % successor function it was replaced BY, just two other tabs that grew
    % to cover the same ground.

    % SV, August 23, 2026: I added - the "zone_visits" tab: the same two-pivot
    % Platform-v-Reward / Tone-v-ITI comparison the binned tabs give for
    % time-in-zone, but built on the visit-COUNT columns instead. There's only
    % one of these (not three like the binned tabs) because visit counts are
    % whole-session totals with no tone-range axis to bin over.
    % Placed here, directly after successful_trials and BEFORE the binned
    % tabs, per SV. Each tab writer appends itself at the end of the workbook,
    % so call order is tab order - this call had to move up rather than the
    % sheet being repositioned afterwards.
    % SV, August 23, 2026: I changed this and the three write_binned_tab
    % calls below to collect the returned paired-comparison records, which
    % feed the new stats tab written at the end.
    % SV, September 3, 2026: I added the trailing success_bin_ranges/
    % success_bin_labels pair (the trend charts this tab now also builds -
    % see write_visits_tab's own changelog):
    % SV, September 8, 2026: I split the single "zone_visits" tab/call into
    % two - write_zone_visits_timecourse_tab ('zone_visits_timecourse') and
    % write_zone_visits_compared_tab ('zone_visits_compared') - per SV's
    % request; see write_zone_visits_compared_tab's changelog for why. Only
    % the compared tab returns paired-comparison records for the stats tab.
    % SV, September 8, 2026 (later same day): I renamed the 'zone_visits_
    % compared' tab to 'zone_visits_prop' per SV's request. Tab order
    % (timecourse first) is unchanged - already matches what SV asked for.
    write_zone_visits_timecourse_tab(Workbook, 'zone_visits_timecourse', rows, zero_font_bgr, ...
        success_bin_ranges, success_bin_labels);
    all_recs = write_zone_visits_compared_tab(Workbook, 'zone_visits_prop', rows, zero_font_bgr, ...
        metric_names, scalar_metric_names, max_tones, all_tones_sheet_name, all_tones_data_start_row);
    %

    % SV, July 24, 2026: I changed
    % write_binned_tab(Workbook, 'binned tones 1-3', rows, 1:3, '1-3', zero_font_bgr);
    % write_binned_tab(Workbook, 'binned tones 4-6', rows, 4:6, '4-6', zero_font_bgr);
    % write_binned_tab(Workbook, 'binned tones 1-6', rows, 1:6, '1-6', zero_font_bgr);
    % to this (each binned tab now needs to know the metric column layout and the "all
    % tones" tab's name/data-start-row so it can build "=AVERAGE('all tones'!..)" formulas
    % instead of writing a MATLAB-computed literal):
    % SV, August 23, 2026: I changed
    % write_binned_tab(Workbook, 'binned tones 1-3', rows, 1:3, '1-3', zero_font_bgr, ...
    %     metric_names, max_tones, all_tones_sheet_name, all_tones_data_start_row);
    % write_binned_tab(Workbook, 'binned tones 4-6', rows, 4:6, '4-6', zero_font_bgr, ...
    %     metric_names, max_tones, all_tones_sheet_name, all_tones_data_start_row);
    % write_binned_tab(Workbook, 'binned tones 1-6', rows, 1:6, '1-6', zero_font_bgr, ...
    %     metric_names, max_tones, all_tones_sheet_name, all_tones_data_start_row);
    % to this (spaces -> underscores in every tab name, per SV's request):
    % SV, September 3, 2026: I changed
    % all_recs = [all_recs, write_binned_tab(Workbook, 'binned_tones_1-3', rows, 1:3, '1-3', zero_font_bgr, ...
    %     metric_names, max_tones, all_tones_sheet_name, all_tones_data_start_row)];
    % all_recs = [all_recs, write_binned_tab(Workbook, 'binned_tones_4-6', rows, 4:6, '4-6', zero_font_bgr, ...
    %     metric_names, max_tones, all_tones_sheet_name, all_tones_data_start_row)];
    % all_recs = [all_recs, write_binned_tab(Workbook, 'binned_tones_1-6', rows, 1:6, '1-6', zero_font_bgr, ...
    %     metric_names, max_tones, all_tones_sheet_name, all_tones_data_start_row)];
    % to this - added "binned_tones_7-9" and replaced "binned_tones_1-6" with
    % "binned_tones_1-9" (the whole-session average), matching the
    % 1-3/4-6/7-9/1-9 bin set used everywhere else now that 9 tones is
    % standard. write_binned_tab itself needed no changes: tone_range is
    % already a plain argument at each call site, and bin_rows/
    % tone_avg_formula/metric_col_span all derive their column math from
    % max_tones (now 9) rather than a hardcoded width, so a wider tone_range
    % just works.
    % SV, September 3, 2026: I added the trailing success_bin_ranges/
    % success_bin_labels pair to all four calls (the trend chart each tab now
    % also builds needs the FULL bin set, not just its own tone_range - see
    % write_binned_tab's own changelog):
    % SV, September 3, 2026 (later same day): I moved the "binned_tones_1-9"
    % call to be FIRST (tabs are appended to the workbook in call order, so
    % this is what controls left-to-right tab position), per SV's request -
    % it's now also the only one of the four that gets the rich Habituation/
    % ITI/Tone x Reward/Platform trend section (see write_binned_tab's own
    % changelog), so it makes sense as the "landing" tab.
    % SV, September 8, 2026: I renamed all four tabs from the "binned_tones_"
    % prefix to "zone_time_" (binned_tones_1-9 -> zone_time_1-9, etc.), per
    % SV's request. Also pulled the trend section out into its own
    % write_zone_time_timecourse_tab call ('zone_time_timecourse', placed
    % BEFORE the four range-specific tabs, same "timecourse tab first" order
    % as zone_visits_timecourse/zone_visits_compared) - see both functions'
    % changelogs - so write_binned_tab no longer takes/needs
    % success_bin_ranges/success_bin_labels.
    % SV, September 8, 2026 (later same day): I renamed the four range tabs
    % again, from "zone_time_*" to "zone_time_prop_*" (zone_time_1-9 ->
    % zone_time_prop_1-9, etc.), per SV's request. 'zone_time_timecourse'
    % keeps its name - SV only asked to rename the four range-specific tabs -
    % and tab order (timecourse first) is unchanged.
    write_zone_time_timecourse_tab(Workbook, 'zone_time_timecourse', rows, zero_font_bgr, ...
        success_bin_ranges, success_bin_labels);
    % SV, September 25, 2026: I changed these four hardcoded calls
    % all_recs = [all_recs, write_binned_tab(Workbook, 'zone_time_prop_1-9', rows, 1:9, '1-9', ...
    % all_recs = [all_recs, write_binned_tab(Workbook, 'zone_time_prop_1-3', rows, 1:3, '1-3', ...
    % all_recs = [all_recs, write_binned_tab(Workbook, 'zone_time_prop_4-6', rows, 4:6, '4-6', ...
    % all_recs = [all_recs, write_binned_tab(Workbook, 'zone_time_prop_7-9', rows, 7:9, '7-9', ...
    % to this loop over success_bin_ranges - a 6-tone DCSP session has no
    % "7-9" bin, so hardcoding four tabs would have written one guaranteed-
    % empty tab and mislabelled the whole-session aggregate as "1-9" when it
    % is really "1-6". Driving the tabs off the bin list keeps PVFP output
    % byte-identical (aggregate first, then 1-3 / 4-6 / 7-9 - the same order
    % and the same names) and gives DCSP the three tabs it actually has.
    % The short tab label is built from the range itself rather than parsed
    % out of success_bin_labels, so the two can never drift apart.
    bin_tab_order = [numel(success_bin_ranges), 1:numel(success_bin_ranges)-1]; % aggregate tab first
    for bin_tab_i = bin_tab_order
        this_bin_range = success_bin_ranges{bin_tab_i};
        this_bin_label = sprintf('%d-%d', min(this_bin_range), max(this_bin_range));
        all_recs = [all_recs, write_binned_tab(Workbook, ['zone_time_prop_' this_bin_label], ...
            rows, this_bin_range, this_bin_label, zero_font_bgr, ...
            metric_names, max_tones, all_tones_sheet_name, all_tones_data_start_row)]; %#ok<AGROW>
    end
    %

    % SV, August 23, 2026: I added - the stats tab, written last so it can
    % report every comparison collected above plus the successful_trials
    % GLMM. Placed at the end of the workbook as a reference table.
    % SV, September 3, 2026: I changed
    % G = fit_success_glmm(rows, success_bin_ranges);
    % to this - success_bin_ranges is now 4 entries wide (1-3/4-6/7-9/1-9),
    % but the 4th ("1-9") OVERLAPS the first three rather than partitioning
    % the 9 tones, so it must not be fed to the GLMM as its own "time"
    % timepoint (that would double-count every trial - see the note where
    % success_bin_ranges is defined, above). success_bin_ranges(1:3) is the
    % exclusive tercile partition the model needs; the full 4-bin list still
    % goes to write_successful_trials_tab (called above) and to
    % write_hab_reward_tab (below), where an overlapping display column is
    % harmless.
    % SV, September 25, 2026: I changed
    % G = fit_success_glmm(rows, success_bin_ranges(1:3));
    % to this - the "(1:3)" hardcoded that the exclusive partition is the
    % first three bins, which is true for PVFP's 1-3/4-6/7-9/1-9 but not for
    % DCSP's 1-3/4-6/1-6 (there the partition is the first TWO). Selecting
    % bins that introduce no already-counted tone computes the same answer
    % for PVFP, adapts to DCSP, and makes the double-counting hazard
    % described where success_bin_ranges is defined self-enforcing rather
    % than a comment someone has to remember to honour.
    glmm_tones_seen = [];
    glmm_keep = false(1, numel(success_bin_ranges));
    for gb = 1:numel(success_bin_ranges)
        if isempty(intersect(success_bin_ranges{gb}, glmm_tones_seen))
            glmm_keep(gb) = true;
            glmm_tones_seen = [glmm_tones_seen, success_bin_ranges{gb}]; %#ok<AGROW>
        end
    end
    G = fit_success_glmm(rows, success_bin_ranges(glmm_keep));
    write_stats_tab(Workbook, 'stats', G, all_recs);
    %
    %

    Workbook.SaveAs(out_filename, 51); % 51 = xlOpenXMLWorkbook (.xlsx)
    Workbook.Close(false);
    Excel.Quit;
    delete(Excel);
catch ME
    try
        Excel.Quit;
    catch
    end
    delete(Excel);
    rethrow(ME);
end
end

%%
% SV, August 21, 2026: I changed the function signature
% function write_all_tones_tab(Sheet, rows, metric_names, max_tones, zero_font_bgr)
% to this (needs scalar_metric_names for the 4 new session-level summary
% columns appended after the tone-grouped metric block - see below):
% SV, August 23, 2026: I changed the function signature again
% function write_all_tones_tab(Sheet, rows, metric_names, scalar_metric_names, max_tones, zero_font_bgr)
% to this (scalar_is_integer: one logical per scalar column, deciding "0"
% vs "0.000" number format - the counts are integers, proportion_successful
% is not):
function write_all_tones_tab(Sheet, rows, metric_names, scalar_metric_names, scalar_is_integer, ...
    scalar_apply_gradient, max_tones, zero_font_bgr)
%
% Split out of write_formatted_xlsx unchanged, so it can be called as one tab among several
% instead of assuming it owns the whole workbook.

n_rows = numel(rows);
n_metrics = numel(metric_names);
n_scalar = numel(scalar_metric_names); % SV, August 21, 2026: I added

header_row1 = 1; % merged metric name / "Condition" / "Subject"
header_row2 = 2; % "tone1".."tone6" sub-headers
data_start_row = 3;

% --- Condition / Subject headers (merged vertically across both header rows) ---
condHeader = Sheet.Range(sprintf('%s%d:%s%d', col2letter(1), header_row1, col2letter(1), header_row2));
condHeader.Merge; condHeader.Value2 = 'Condition';
condHeader.Font.Bold = true; condHeader.HorizontalAlignment = -4108; condHeader.VerticalAlignment = -4108;

subjHeader = Sheet.Range(sprintf('%s%d:%s%d', col2letter(2), header_row1, col2letter(2), header_row2));
subjHeader.Merge; subjHeader.Value2 = 'Subject';
subjHeader.Font.Bold = true; subjHeader.HorizontalAlignment = -4108; subjHeader.VerticalAlignment = -4108;

% --- Metric group headers (merged across each metric's tone1..toneN block) ---
col_offset = 3;
metric_col_start = containers.Map('KeyType','double','ValueType','double');
for m = 1:n_metrics
    cols = col_offset:(col_offset + max_tones - 1);
    metric_col_start(m) = cols(1);

    groupHeader = Sheet.Range(sprintf('%s%d:%s%d', col2letter(cols(1)), header_row1, col2letter(cols(end)), header_row1));
    groupHeader.Merge; groupHeader.Value2 = char(metric_names(m));
    groupHeader.Font.Bold = true; groupHeader.HorizontalAlignment = -4108;

    for t = 1:max_tones
        toneCell = Sheet.Range(sprintf('%s%d', col2letter(cols(t)), header_row2));
        toneCell.Value2 = sprintf('tone%d', t);
        toneCell.HorizontalAlignment = -4108;
    end

    col_offset = col_offset + max_tones;
end
last_metric_col = col_offset - 1;

% SV, August 21, 2026: I added
% (no v5 equivalent - 4 new session-level scalar summary columns, one column
% each rather than a max_tones-wide group, laid out immediately after the
% tone-grouped metrics with the same vertically-merged-header treatment
% already used for Condition/Subject above. Kept as a separate loop/map from
% the metric_names loop above since these don't have a tone1..toneN
% sub-header row at all.)
scalar_col_start = containers.Map('KeyType','double','ValueType','double');
scol = last_metric_col + 1;
for sm = 1:n_scalar
    scalar_col_start(sm) = scol;
    scalarHeader = Sheet.Range(sprintf('%s%d:%s%d', col2letter(scol), header_row1, col2letter(scol), header_row2));
    scalarHeader.Merge; scalarHeader.Value2 = char(scalar_metric_names(sm));
    scalarHeader.Font.Bold = true; scalarHeader.HorizontalAlignment = -4108; scalarHeader.VerticalAlignment = -4108;
    scol = scol + 1;
end
last_scalar_col = scol - 1;
%

% --- Data rows ---
for i = 1:n_rows
    r = data_start_row + i - 1;
    condition_name = rows(i).Condition;

    Sheet.Range(sprintf('%s%d', col2letter(1), r)).Value2 = char(condition_name);
    Sheet.Range(sprintf('%s%d', col2letter(2), r)).Value2 = char(rows(i).Subject);

    for m = 1:n_metrics
        vals = rows(i).(metric_names(m));
        cstart = metric_col_start(m);
        for t = 1:max_tones
            cell = Sheet.Range(sprintf('%s%d', col2letter(cstart + t - 1), r));
            % SV, July 24, 2026: I changed
            % write_value_cell(cell, vals(t), group, zero_font_bgr);
            % (fill color used to be baked in per-cell here; "group" is no longer needed by
            % write_value_cell at all - see below) to this:
            write_value_cell(cell, vals(t));
            %
        end
    end

    % SV, August 21, 2026: I added - the 4 new scalar columns, one value per
    % row (not a tone loop, unlike the metric block above). is_integer=true
    % so counts render as plain "0"/"12" instead of "0.000"/"12.000" - see
    % write_value_cell's new 3rd argument below.
    % SV, August 23, 2026: I changed
    % write_value_cell(scell, rows(i).(scalar_metric_names(sm)), true);
    % (hardcoded true = every scalar column integer-formatted) to this, so
    % proportion_successful renders as "0.833" while the count columns still
    % render as plain integers:
    for sm = 1:n_scalar
        scell = Sheet.Range(sprintf('%s%d', col2letter(scalar_col_start(sm)), r));
        write_value_cell(scell, rows(i).(scalar_metric_names(sm)), scalar_is_integer(sm));
    end
    %
end
last_data_row = data_start_row + n_rows - 1;

% SV, July 24, 2026: I added
% (no v4 equivalent - fill color used to be baked into each cell inside the loop above via
% write_value_cell/group_fill_bgr; now it's one live Color Scale conditional-format rule per
% contiguous same-group (sham/tms) block of rows, applied across the whole metric column
% range, so editing a value updates its fill automatically)
row_groups = strings(1, n_rows);
for i = 1:n_rows
    row_groups(i) = classify_group(rows(i).Condition);
end
run_start = 1;
for i = 2:(n_rows + 1)
    if i > n_rows || row_groups(i) ~= row_groups(run_start)
        r1 = data_start_row + run_start - 1;
        r2 = data_start_row + (i - 1) - 1;
        apply_group_gradient_cf(Sheet, 3, last_metric_col, r1, r2, row_groups(run_start), zero_font_bgr);
        % SV, August 23, 2026: I added - same live gradient + zero-font CF for
        % any scalar column flagged in scalar_apply_gradient (today just
        % proportion_successful), so it formats identically to a tone metric
        % column like ITI_reward_time, per SV's request. Applied per column
        % rather than as one block range because the flagged columns aren't
        % guaranteed to be contiguous if the column list is reordered later.
        for sm = 1:n_scalar
            if scalar_apply_gradient(sm)
                sc = scalar_col_start(sm);
                apply_group_gradient_cf(Sheet, sc, sc, r1, r2, row_groups(run_start), zero_font_bgr);
            end
        end
        %
        run_start = i;
    end
end
%

% --- Column widths: metric (numeric) columns sized to just fit "0.000" ---
Sheet.Range(sprintf('%s1:%s1', col2letter(3), col2letter(last_metric_col))).EntireColumn.ColumnWidth = 6;
% Condition/Subject columns: fit their actual (longer) text content
Sheet.Range(sprintf('%s1:%s%d', col2letter(1), col2letter(2), last_data_row)).EntireColumn.AutoFit;
% SV, August 21, 2026: I added - AutoFit the new scalar summary columns
% (same reasoning as Condition/Subject above: their header text, e.g.
% "Plat_successful_trials", is much longer than the width-6 fixed metric
% columns sized for "0.000"/short tone data, so a fixed width would clip it).
% Deliberately NOT included in apply_group_gradient_cf's 3:last_metric_col
% range above - these are raw counts, not 0-1 proportions, so folding them
% into that live 0->1 Color Scale would clip/misrepresent them (e.g. a
% count of 2 would render identically to a count of 20). Left as plain,
% unhighlighted cells for now.
% SV, August 23, 2026: the sentence above is now only true of the COUNT
% columns. proportion_successful IS a 0-1 proportion, so per SV's request it
% now gets the same gradient CF as a tone metric column - applied in the
% row-group loop above via scalar_apply_gradient, not here.
if n_scalar > 0
    Sheet.Range(sprintf('%s1:%s%d', col2letter(scalar_col_start(1)), col2letter(last_scalar_col), last_data_row)).EntireColumn.AutoFit;
end
%
end

%%
% SV, August 23, 2026: I added this whole function (no v5 equivalent).
% Builds the "successful_trials" tab SV requested: one row per subject
% (grouped Sham/TMS), one column-block per experimental day in chronological
% order, each split into the tone bins in success_bin_ranges (1-3 / 4-6 /
% 7-9), so avoidance can be read left-to-right WITHIN a session and
% across sessions at the same time.
%
% Layout (mirrors the existing tabs' conventions - merged vertical headers
% like all_tones's Condition/Subject, merged row-group label cells and the
% per-group gradient CF like the binned tabs):
%   col 1 = Sham/TMS row-group label (merged down its block)
%   col 2 = Subject
%   then 3 columns per day: "Tones 1-3" / "Tones 4-6" / "Tones 7-9",
%   under a merged day-name header.
%
% Values are the SAME proportion as the all_tones proportion_successful
% column, just restricted to that bin's tones: (successful trials in bin) /
% (tones actually present in bin). NaN-padding from Plat_success_vector is
% dropped first, so a 5-tone session's "Tones 4-6" bin is 2 tones, not 3,
% and its "Tones 7-9" bin is blank rather than 0.
%
% Habituation days are excluded entirely (no tones, no shocks - nothing to
% take a proportion of), matching the same exclusion on proportion_successful.
%
% Unlike the binned tabs, these cells are computed literals, not live
% "=AVERAGE('all_tones'!..)" formulas: the per-tone 0/1 success values this
% is derived from aren't written to any visible tab, so there's no cell for
% a formula to point at. If SV wants these traceable/hand-editable the same
% way, the fix is to add the per-tone success vector to all_tones as its own
% metric group first, then reference it - flagged, not assumed.
function write_successful_trials_tab(Workbook, sheet_name, rows, zero_font_bgr, ...
    success_bin_ranges, success_bin_labels)

% Same add-then-move pattern write_binned_tab uses (safer than Sheets.Add's
% Before/After args across MATLAB/Excel COM versions).
last_sheet = Workbook.Sheets.Item(Workbook.Sheets.Count);
Sheet = Workbook.Sheets.Add;
Sheet.Move([], last_sheet);
Sheet.Name = sheet_name;

n_bins = numel(success_bin_ranges);

% --- Flatten "rows" into (subject x day) entries, dropping Hab days ---
n = numel(rows);
e_day = strings(1, n); e_group = strings(1, n);
e_subjnum = nan(1, n); e_subjlabel = strings(1, n);
e_vec = cell(1, n);
keep = false(1, n);
for i = 1:n
    d = day_from_condition(rows(i).Condition);
    if startsWith(d, 'Hab', 'IgnoreCase', true)
        continue % excluded per SV - no tones/shocks to take a proportion of
    end
    [num, lbl] = parse_subject(rows(i).Subject);
    e_day(i) = d;
    e_group(i) = classify_group(rows(i).Condition);
    e_subjnum(i) = num;
    e_subjlabel(i) = string(lbl);
    e_vec{i} = rows(i).Plat_success_vector;
    keep(i) = true;
end
if ~any(keep)
    warning('successful_trials tab: no non-habituation sessions found - tab left empty.');
    return
end

% "rows" is already sorted chronologically upstream, so first-appearance
% order here IS chronological day order - same trick the binned tabs use.
days = unique(e_day(keep), 'stable');

% --- Subject list, grouped Sham then TMS, numerically sorted within group ---
subj_nums = []; subj_labels = strings(0); subj_groups = strings(0);
for g = ["sham", "tms"]
    idx = find(keep & e_group == g);
    [~, order] = sort(e_subjnum(idx));
    for k = idx(order)
        if ~ismember(e_subjnum(k), subj_nums)
            subj_nums(end+1) = e_subjnum(k); %#ok<AGROW>
            subj_labels(end+1) = e_subjlabel(k); %#ok<AGROW>
            subj_groups(end+1) = g; %#ok<AGROW>
        end
    end
end
% SV, August 23, 2026: I removed
% n_subj = numel(subj_nums);
% from here - it was only used by the old flat "for s = 1:n_subj" data loop
% and its run-detection CF loop, both replaced by the per-group block loop
% below (which iterates gidx per group instead). Left dead by that refactor;
% checkcode flagged it.

% --- Headers ---
header_row1 = 1; % merged day name
header_row2 = 2; % bin labels
data_start_row = 3;

grpHeader = Sheet.Range(sprintf('%s%d:%s%d', col2letter(1), header_row1, col2letter(1), header_row2));
grpHeader.Merge; grpHeader.Value2 = 'Group';
grpHeader.Font.Bold = true; grpHeader.HorizontalAlignment = -4108; grpHeader.VerticalAlignment = -4108;

subjHeader = Sheet.Range(sprintf('%s%d:%s%d', col2letter(2), header_row1, col2letter(2), header_row2));
subjHeader.Merge; subjHeader.Value2 = 'Subject';
subjHeader.Font.Bold = true; subjHeader.HorizontalAlignment = -4108; subjHeader.VerticalAlignment = -4108;

day_col_start = zeros(1, numel(days));
c = 3;
for d = 1:numel(days)
    day_col_start(d) = c;
    dayHeader = Sheet.Range(sprintf('%s%d:%s%d', col2letter(c), header_row1, col2letter(c + n_bins - 1), header_row1));
    dayHeader.Merge; dayHeader.Value2 = char(days(d));
    dayHeader.Font.Bold = true; dayHeader.HorizontalAlignment = -4108;
    for b = 1:n_bins
        binCell = Sheet.Range(sprintf('%s%d', col2letter(c + b - 1), header_row2));
        binCell.Value2 = char(success_bin_labels(b));
        binCell.HorizontalAlignment = -4108;
    end
    c = c + n_bins;
end
last_col = c - 1;

% --- Data rows, written one Sham/TMS block at a time so each group's
% "<group>_mean" row lands directly under its own last subject ---
% SV, August 23, 2026: I changed this section. It used to write all subject
% rows in one flat loop and then back-fill the group label/CF by detecting
% runs of the same group afterwards. Writing block-by-block instead is what
% lets the mean row be appended inside each group's block (and lets the
% group label + gradient CF cover the mean row too), and it also hands the
% chart builder the exact row spans it needs per group.
blocks = struct('group', {}, 'first_subj_row', {}, 'last_subj_row', {}, 'mean_row', {});
r = data_start_row;
for g = ["sham", "tms"]
    gidx = find(subj_groups == g);
    if isempty(gidx)
        continue
    end
    first_subj_row = r;
    for s = gidx
        Sheet.Range(sprintf('%s%d', col2letter(2), r)).Value2 = char(subj_labels(s));
        for d = 1:numel(days)
            % The (subject, day) session, if this subject ran that day at all
            k = find(keep & e_subjnum == subj_nums(s) & e_day == days(d), 1);
            for b = 1:n_bins
                cellRange = Sheet.Range(sprintf('%s%d', col2letter(day_col_start(d) + b - 1), r));
                if isempty(k)
                    val = NaN; % subject didn't run this day - leave blank
                else
                    val = bin_success_proportion(e_vec{k}, success_bin_ranges{b});
                end
                write_value_cell(cellRange, val);
            end
        end
        r = r + 1;
    end
    last_subj_row = r - 1;

    % SV, August 23, 2026: I added - the "<group>_mean" row, per SV's request.
    % Written as a live "=AVERAGE(<this group's subject rows>)" formula rather
    % than a MATLAB-computed literal, matching the traceable-formula approach
    % the binned tabs already use: the subject rows of a group are contiguous
    % by construction above, so the range is exact, and hand-editing any
    % subject cell updates the mean automatically. AVERAGE ignores blank
    % cells, so a subject who didn't run a given day doesn't drag the mean
    % down - it just averages over the animals that have data.
    mean_row = r;
    mean_label = sprintf('%s_mean', char(g));
    lblCell = Sheet.Range(sprintf('%s%d', col2letter(2), mean_row));
    lblCell.Value2 = mean_label;
    lblCell.Font.Bold = true;
    for d = 1:numel(days)
        for b = 1:n_bins
            cc = day_col_start(d) + b - 1;
            cletter = col2letter(cc);
            cellRange = Sheet.Range(sprintf('%s%d', cletter, mean_row));
            % Snapshot value only decides blank/zero/decimal formatting, same
            % as write_formula_cell's contract elsewhere - the number shown
            % always comes from the live formula.
            vals = nan(1, numel(gidx));
            for kk = 1:numel(gidx)
                s2 = gidx(kk);
                k2 = find(keep & e_subjnum == subj_nums(s2) & e_day == days(d), 1);
                if ~isempty(k2)
                    vals(kk) = bin_success_proportion(e_vec{k2}, success_bin_ranges{b});
                end
            end
            snapshot = mean(vals, 'omitnan');
            formula_str = sprintf('=AVERAGE(%s%d:%s%d)', cletter, first_subj_row, cletter, last_subj_row);
            write_formula_cell(cellRange, formula_str, snapshot);
            cellRange.Font.Bold = true;
        end
    end
    r = r + 1;

    % Group label + gradient CF cover the subject rows AND the mean row
    merge_label_cell(Sheet, 1, first_subj_row, mean_row, group_label(g), g);
    apply_group_gradient_cf(Sheet, 3, last_col, first_subj_row, mean_row, g, zero_font_bgr);

    bi = numel(blocks) + 1;
    blocks(bi).group = g;
    blocks(bi).first_subj_row = first_subj_row;
    blocks(bi).last_subj_row = last_subj_row;
    blocks(bi).mean_row = mean_row;
end
last_data_row = r - 1;
%

% --- Column widths ---
% Bin columns AutoFit rather than the fixed width-6 used for tone data on
% all_tones: "Tones 1-3" is wider than "0.000" and would otherwise clip
% (same problem/fix as the binned tabs' header columns).
Sheet.Range(sprintf('%s1:%s%d', col2letter(1), col2letter(last_col), last_data_row)).EntireColumn.AutoFit;

% SV, August 23, 2026: I changed this from two charts (one per group) to ONE
% combined chart, per SV's request to compare sham vs tms directly. SV's
% screenshot of the first version (E:\troubleshoot) also showed the
% second chart rendering far narrower than the 620pt it was created with,
% which the single-chart layout sidesteps entirely.
% Was:
% chart_stage_col = last_col + 3;
% chart_stage_row = 1;
% CHART_W = 620; CHART_H = 300; chart_gap_pt = 24;
% anchor = Sheet.Range(sprintf('%s%d', col2letter(1), last_data_row + 3));
% next_left = anchor.Left;
% for bi = 1:numel(blocks)
%     co = build_success_timeline_chart(Sheet, blocks(bi), days, success_bin_labels, ...
%         day_col_start, n_bins, subj_labels, subj_groups, ...
%         sprintf('%s: proportion of trials shock avoided', group_label(blocks(bi).group)), ...
%         next_left, anchor.Top, CHART_W, CHART_H, chart_stage_col, chart_stage_row);
%     next_left = co.Left + CHART_W + chart_gap_pt;
%     chart_stage_row = chart_stage_row + numel(days)*n_bins + 12;
% end
% to this:
% SV, September 3, 2026: I changed
% build_success_combined_chart(Sheet, blocks, days, success_bin_labels, ...
%     day_col_start, n_bins, subj_labels, subj_groups, ...
%     'Proportion of trials shock avoided', ...
%     anchor.Left, anchor.Top, 980, 400, chart_stage_col, 1);
% to this - per SV's request: "Tones 1-9" is a whole-session AVERAGE of the
% other three bins, not a fourth timepoint in the 1-3->4-6->7-9 progression,
% so plotting it as a 4th point on the same continuous line made the line
% jump to a value that isn't really "what happened next" and read as visually
% wrong. It now gets its own summary BAR chart (one Sham/TMS bar pair per
% day, individual mice overlaid - same convention the locomotion tab's bars
% already use) via the new build_summary_bar_chart, built from the SAME
% blocks/table this line chart uses. Only bins 1:end-1 (the exclusive
% tercile partition) feed the line chart now; the LAST entry in
% success_bin_ranges/success_bin_labels is assumed to be the whole-session
% "1-9" aggregate - same assumption already documented where
% success_bin_ranges is defined, and where fit_success_glmm is called, at
% the top of this file.
% Also required by build_success_combined_chart's signature change (per-day
% cell arrays of columns/labels instead of a uniform day_col_start+n_bins -
% see that function's own changelog): day_cols/day_labels are built here to
% match.
n_line_bins = n_bins - 1; % excludes the trailing whole-session "1-9" aggregate
day_cols = cell(1, numel(days));
day_labels = cell(1, numel(days));
for d = 1:numel(days)
    day_cols{d} = day_col_start(d) : (day_col_start(d) + n_line_bins - 1);
    day_labels{d} = success_bin_labels(1:n_line_bins);
end
chart_stage_col = last_col + 3; % hidden staging area, clear of the table
anchor = Sheet.Range(sprintf('%s%d', col2letter(1), last_data_row + 3));
co1 = build_success_combined_chart(Sheet, blocks, days, day_cols, day_labels, ...
    subj_labels, subj_groups, ...
    'Proportion of trials shock avoided', ...
    anchor.Left, anchor.Top, 980, 400, chart_stage_col, 1);

summary_stage_col = chart_stage_col + numel(days)*n_line_bins + 20;
summary_col = day_col_start + n_line_bins; % the "1-9" column for each day
summary_left = anchor.Left;
if ~isempty(co1)
    summary_left = co1.Left + 980 + 20;
end
build_summary_bar_chart(Sheet, blocks, days, summary_col, ...
    'Whole-session (Tones 1-9): proportion of trials shock avoided', ...
    'Prop. successful', 'proportion', '0.0', ...
    summary_left, anchor.Top, 300, 400, summary_stage_col, 1);
%

% Hide the chart-feeder staging columns (they're live formulas pointing at
% this tab's own visible table - not meant to be read directly). Each chart
% sets PlotVisibleOnly=false so hiding these doesn't blank the charts.
% SV, September 3, 2026: I widened this range (was chart_stage_col+40) to
% comfortably clear BOTH charts' staging areas now that there are two.
if numel(blocks) > 0
    Sheet.Range(sprintf('%s1:%s1', col2letter(chart_stage_col), ...
        col2letter(summary_stage_col + 2*numel(days) + 20))).EntireColumn.Hidden = true;
end
%
end

%%
% SV, August 23, 2026: I replaced build_success_timeline_chart (which drew
% one chart per group) with this single combined chart, after SV reviewed a
% screenshot of the first version in E:\troubleshoot. Three fixes came
% straight out of that screenshot, plus SV's request to compare groups
% directly:
%  1) Sham and TMS are now on ONE chart/axis so they can be compared
%     directly. See the "AxisGroup" note below for how both SEM bands
%     survive that (Excel stacks every area series on an axis into one
%     cumulative group, which is why two bands couldn't share a chart in the
%     first version).
%  2) Per-animal lines were nearly invisible: they used the LIGHT end of the
%     group gradient ([239 239 239] for sham - almost white on a white plot
%     area). They now use the DARK end, and each animal gets its own dash
%     pattern (dash / dot / dash-dot / long-dash / ...) so individual
%     animals are actually distinguishable, per SV. The group mean stays the
%     only SOLID line and is much thicker, so it still reads as the mean.
%  3) The always-empty "Tones 7-9" categories were plotting as drop-to-zero
%     spikes (clearly visible as triangles in SV's screenshot) rather than
%     being skipped. Any (day, bin) with no data for ANY subject is now left
%     out of the chart's x-axis entirely. It stays in the table above -
%     only the chart skips it - so this self-corrects once real 9-tone
%     sessions exist.
%
% Every plotted number is still a live formula pointing at this tab's own
% visible table, in hidden staging columns.
% SV, September 3, 2026: I added the optional trailing y_axis_title/
% y_axis_mode/y_number_format arguments (all default to reproduce the exact
% original hardcoded behaviour, so the successful_trials call site - which
% still passes only 15 args - is byte-for-byte unaffected). This function was
% otherwise hard-wired to a fixed 0-1 "Prop. successful" axis; the new
% hab_reward_rate tab reuses this same many-category/day-break/SEM-error-bar/
% dashed-per-animal-line chart for visit COUNTS and locomotion RATES too,
% neither of which fits a 0-1 scale, so the axis title/scale/number-format
% are now parameters instead of literals. Everything else in this function -
% the day-break spacer logic, the SEM error bars, the legend cleanup - is
% unchanged and applies identically regardless of which axis mode is used.
% SV, September 3, 2026: I changed the function signature
% function co = build_success_combined_chart(Sheet, blocks, days, bin_labels, ...
%     day_col_start, n_bins, subj_labels, subj_groups, chart_title, ...
%     anchor_left, anchor_top, chart_w, chart_h, stage_col, stage_row, ...
%     y_axis_title, y_axis_mode, y_number_format)
% to this - day_col_start+n_bins (one starting column + a UNIFORM bin count
% for every day) assumed every day had the same number of inner categories.
% That's true for successful_trials (always 3, after splitting "1-9" out -
% see below) but false for the redesigned locomotion/hab_reward_rate tabs,
% where a real day has 8 inner categories (Tone 1-3/4-6/7-9/1-9, then ITI
% 1-3/4-6/7-9/1-9) and a Habituation day has only 4 (the tone never played,
% so there's no separate Tone/ITI split - see write_hab_reward_tab). Replaced
% with day_cols/day_labels: CELL arrays, one entry per day, each an explicit
% list of source columns / category labels for that day - so every day can
% have a different number of inner categories, or none of this generalizing
% mattered to you and every caller still just passes the same-length list for
% every day (successful_trials does exactly that). "days" renamed day_names
% (same meaning, just paired with the new day_cols/day_labels naming).
function co = build_success_combined_chart(Sheet, blocks, day_names, day_cols, day_labels, ...
    subj_labels, subj_groups, chart_title, ...
    anchor_left, anchor_top, chart_w, chart_h, stage_col, stage_row, ...
    y_axis_title, y_axis_mode, y_number_format)
if nargin < 16, y_axis_title = 'Prop. successful'; end
if nargin < 17, y_axis_mode = 'proportion'; end
if nargin < 18, y_number_format = '0.0'; end

% Force to string before any concatenation - same char-array-vs-string trap
% that produced the garbled "P","l","a","t..." axis labels back in July.
day_names = string(day_names);
for dd = 1:numel(day_labels)
    day_labels{dd} = string(day_labels{dd});
end

% --- Decide which (day, bin) points actually carry data ---
% A point is kept only if at least one subject in any group has a non-blank
% value there. This is what suppresses the empty tones-7-9 spikes.
pts_day = []; pts_bin = [];
for d = 1:numel(day_names)
    cols_d = day_cols{d};
    for b = 1:numel(cols_d)
        src_col = cols_d(b);
        has_data = false;
        for bi = 1:numel(blocks)
            for rr = blocks(bi).first_subj_row:blocks(bi).last_subj_row
                v = Sheet.Range(sprintf('%s%d', col2letter(src_col), rr)).Value2;
                if ~isempty(v) && isnumeric(v) && ~isnan(v)
                    has_data = true;
                    break
                end
            end
            if has_data, break; end
        end
        if has_data
            pts_day(end+1) = d; %#ok<AGROW>
            pts_bin(end+1) = b; %#ok<AGROW>
        end
    end
end

% SV, August 23, 2026: I added - insert a spacer point at every day
% boundary, per SV: the lines should BREAK between days (TrainD1s2 |
% TrainD2s1 | RetrS1 | RetrS2) rather than running continuously across them,
% since consecutive days aren't continuous in time. The spacer is a real
% x-axis category whose every series value is =NA(); Excel renders #N/A as a
% gap in line and area series, which is what produces the break. Its
% category label is left blank so the axis just shows a space.
pts_spacer = false(1, numel(pts_day));
if ~isempty(pts_day)
    sd = pts_day(1); sb = pts_bin(1); ss = false;
    for p = 2:numel(pts_day)
        if pts_day(p) ~= pts_day(p-1)
            sd(end+1) = pts_day(p); sb(end+1) = pts_bin(p); ss(end+1) = true; %#ok<AGROW>
        end
        sd(end+1) = pts_day(p); sb(end+1) = pts_bin(p); ss(end+1) = false; %#ok<AGROW>
    end
    pts_day = sd; pts_bin = sb; pts_spacer = ss;
end
%
n_pts = numel(pts_day);
if n_pts == 0
    warning('successful_trials chart: no (day, bin) point has any data - chart skipped.');
    co = [];
    return
end

% --- Staging layout: one COLUMN per x-axis point, one ROW per series ---
cat_row1 = stage_row;     % outer bracket: day name
cat_row2 = stage_row + 1; % inner tick:  tone bin
next_row = stage_row + 2;

% Per group: an invisible base at (mean - SEM), then a band of height
% 2*SEM stacked on it, then the mean line itself.
% SV, August 23, 2026: I changed the staging rows
% blocks(bi).lower_row = next_row;      % was mean-SEM  (area base, then lower bound line)
% blocks(bi).band_row  = next_row + 1;  % was 2*SEM/mean+SEM (area band, then upper bound line)
% blocks(bi).mean_srow = next_row + 2;
% blocks(bi).subj_row0 = next_row + 3;
% to this - a single row holding the raw SEM, because the SEM is now drawn
% as real error bars on the mean series rather than as its own series pair.
% See the mean/error-bar block below for why.
for bi = 1:numel(blocks)
    blocks(bi).sem_row   = next_row;
    blocks(bi).mean_srow = next_row + 1;
    blocks(bi).subj_row0 = next_row + 2;
    blocks(bi).gidx = find(subj_groups == blocks(bi).group);
    next_row = blocks(bi).subj_row0 + numel(blocks(bi).gidx);
end
%

for p = 1:n_pts
    sc = col2letter(stage_col + p - 1);
    d = pts_day(p); b = pts_bin(p);
    src = col2letter(day_cols{d}(b));

    % SV, August 23, 2026: I added - spacer columns get blank category
    % labels and =NA() for every series, which is what breaks the lines
    % between days. Everything below is skipped for them.
    if pts_spacer(p)
        % SV, August 23, 2026: I changed the spacer cells
        % Sheet.Range(...).Formula = '=NA()';   % for every series row
        % to leaving them GENUINELY EMPTY (no formula written at all).
        % Reason, from SV's 2026-08-23 screenshot: #N/A breaks a LINE series
        % into a gap (which worked - the mean lines did split per day), but
        % an AREA series plots #N/A as ZERO, so both SEM bands collapsed to
        % 0.0 at every day boundary instead of stopping. Truly-empty cells
        % plus chart.DisplayBlanksAs = xlNotPlotted (set below) gap BOTH
        % series types. Note it must be an empty cell, not a formula
        % returning "" - Excel treats a formula's empty-string result as
        % non-blank text and charts it as zero, which is the same bug again.
        Sheet.Range(sprintf('%s%d', sc, cat_row1)).Value2 = '';
        Sheet.Range(sprintf('%s%d', sc, cat_row2)).Value2 = '';
        continue
        %
    end
    %

    % SV, August 23, 2026: I changed
    % Sheet.Range(sprintf('%s%d', sc, cat_row1)).Value2 = char(days(d));
    % (the day name was written under EVERY bin, so "TrainD1s2" appeared
    % once per bin) to writing it only where the day changes, so Excel spans
    % it once across that day's bins - same de-duplication as in
    % build_paired_barline_chart, and same reason (SV: repeated axis labels
    % are cluttered and slow to read). The bin label is always written: it is
    % the innermost level and differs at every position anyway.
    % A spacer column resets this, so the first point of each day always
    % re-writes the day name.
    prev_real = find(~pts_spacer(1:p-1), 1, 'last');
    day_changed = isempty(prev_real) || pts_day(prev_real) ~= d;
    % SV, September 3, 2026: I added - force these two category-label cells
    % to TEXT format before writing. Root cause of the "3-Jan"/"6-Apr"/"9-Jul"
    % x-axis SV reported on the hab_reward_rate tab: a bare bin label like
    % "1-3" matches Excel's day-month autodetect pattern, so an unformatted
    % cell silently reinterprets "1-3"/"4-6"/"7-9"/"1-9" as a DATE (Jan 3 /
    % Apr 6 / Jul 9 / Jan 9) and displays it that way - the underlying string
    % was written correctly, Excel just chose to show it as a date. "Tones
    % 1-3" (what this chart's original single caller, successful_trials,
    % passes) never triggered this - only a bare "1-3"-style label does - but
    % forcing text format here unconditionally costs nothing and closes the
    % door on it for every future caller too, not just the one that hit it.
    cellA = Sheet.Range(sprintf('%s%d', sc, cat_row1));
    cellB = Sheet.Range(sprintf('%s%d', sc, cat_row2));
    cellA.NumberFormat = '@';
    cellB.NumberFormat = '@';
    if day_changed
        cellA.Value2 = char(day_names(d));
    end
    %
    cellB.Value2 = char(day_labels{d}(b));

    for bi = 1:numel(blocks)
        blk = blocks(bi);
        subj_rng = sprintf('%s%d:%s%d', src, blk.first_subj_row, src, blk.last_subj_row);
        mean_ref = sprintf('%s%d', src, blk.mean_row);
        % SEM = STDEV/SQRT(COUNT) over this group's subject rows. IFERROR
        % covers the 0- or 1-animal case (STDEV of <2 values errors).
        sem_expr = sprintf('IFERROR(STDEV(%s)/SQRT(COUNT(%s)),0)', subj_rng, subj_rng);

        % IF(...="",NA()) matters: a plain "=C5" on an empty cell returns 0,
        % which would plot as a real 0 instead of a gap.
        % SV, August 23, 2026: I changed these two staging writes
        % Sheet.Range(...lower_row).Formula = '=IF(mean="",NA(),mean-sem)';
        % Sheet.Range(...band_row).Formula  = '=IF(mean="",NA(),mean+sem)';
        % to a single raw-SEM value, now that the SEM is drawn as error bars
        % on the mean series instead of as bound lines / an area band.
        % Left BLANK rather than NA() when there's no mean: an #N/A in the
        % error-bar amount range would make Excel error rather than simply
        % draw no bar at that point.
        Sheet.Range(sprintf('%s%d', sc, blk.sem_row)).Formula = ...
            sprintf('=IF(%s="","",%s)', mean_ref, sem_expr);
        %
        Sheet.Range(sprintf('%s%d', sc, blk.mean_srow)).Formula = ...
            sprintf('=IF(%s="",NA(),%s)', mean_ref, mean_ref);

        for kk = 1:numel(blk.gidx)
            ref = sprintf('%s%d', src, blk.first_subj_row + kk - 1);
            Sheet.Range(sprintf('%s%d', sc, blk.subj_row0 + kk - 1)).Formula = ...
                sprintf('=IF(%s="",NA(),%s)', ref, ref);
        end
    end
end

cat_range = Sheet.Range(sprintf('%s%d:%s%d', col2letter(stage_col), cat_row1, ...
    col2letter(stage_col + n_pts - 1), cat_row2));

co = Sheet.ChartObjects.Add(anchor_left, anchor_top, chart_w, chart_h);
% SV, September 8, 2026: I added - Placement = xlFreeFloating (3), same as
% every other chart builder in this file (build_summary_bar_chart included).
% Without it, a chart's default Placement (xlMoveAndSize) means Excel
% silently repositions/resizes it whenever a column it overlaps gets
% AutoFit again later - which happens routinely here, since
% write_simple_trend_table_and_chart's stacked calls (Habituation/Train-
% Retr ITI/Train-Retr Tone) all reuse the SAME columns, each re-running
% AutoFit on them. Per SV's screenshot: this chart (already correctly
% sized/positioned when built) would drift out of place once a LATER block
% re-autofit the shared columns, while its paired summary chart (already
% free-floating) stayed put - the two ending up far apart even though both
% were positioned correctly relative to the table at the moment each was
% built.
try, co.Placement = 3; catch, end % xlFreeFloating
chart = co.Chart;
chart.ChartType = 4;           % xlLine - per-series types are set below
chart.PlotVisibleOnly = false; % staging columns get hidden at the end
% SV, August 23, 2026: I added - treat the empty day-boundary spacer cells
% as "not plotted" rather than as zero. This is what makes the SEM AREA
% bands actually break between days; without it they drop to 0.0 there (see
% the spacer-cell note above).
try
    chart.DisplayBlanksAs = 1; % xlNotPlotted
catch ME
    warning(['Could not set DisplayBlanksAs on chart "%s": %s. The SEM bands may dip ' ...
        'to zero at day boundaries instead of breaking.'], chart_title, ME.message);
end
%

% Distinct dash pattern per animal (MsoLineDashStyle). Solid (1) is
% deliberately NOT in this list - it's reserved for the group mean.
dash_styles = [4 3 5 7 2 6 8 9]; % dash, roundDot, dashDot, longDash,
                                 % squareDot, dashDotDot, longDashDot,
                                 % longDashDotDot
n_sem_series = 0;

% --- How the SEM ended up as error bars (3 attempts, all 2026-08-23) ---
% There is no separate SEM series here any more. The history is worth
% keeping, because two plausible-looking approaches are dead ends that
% someone will otherwise re-try:
%
%  1) Stacked-AREA fill (invisible mean-SEM pedestal + translucent 2*SEM
%     band, second group pushed to the secondary axis for its own stack).
%     Looked right, but the band collapsed to ZERO at every day boundary.
%     Verified against a live Excel session, not guessed: an area series is
%     always anchored to the value axis, so it drops to zero across a gap.
%     #N/A, a genuinely empty cell, AND DisplayBlanksAs=xlNotPlotted all
%     produced the same V-to-zero; per-point Format.Fill.Visible=0 on the
%     offending segments silently did nothing (no error, no effect); and
%     DisplayBlanksAs=xlInterpolated fixed the area only by ALSO cancelling
%     the line breaks. A true area fill and real day-breaks are mutually
%     exclusive in Excel.
%  2) Two thin dotted BOUND LINES at mean-SEM / mean+SEM. Broke correctly
%     and never showed SEM where there was no data - but SV reported they
%     read as just another subject's dashed animal line.
%  3) Real ERROR BARS on the mean series (what's used now, see below).
%     Satisfies all three constraints at once: unmistakable against the
%     animal lines, absent where there's no data, and breaks between days.
%
% NOTE for future work: error bars were abandoned in July after two COM call
% styles both failed with 0x800A03EC - but that was on the BAR series in
% build_paired_barline_chart. On a LINE series the plain direct call works
% first time (retested live). Don't let the July note discourage using them
% here.
%
% n_sem_series stays 0, which makes the legend-entry deletion further down a
% no-op - there are no helper series left to hide.
%

% --- Per-animal lines (dark + dashed), then the group mean (thick, solid) ---
for bi = 1:numel(blocks)
    blk = blocks(bi);
    % SV, August 23, 2026: I changed the trace colors
    % [~, c_dark] = group_gradient_colors(blk.group);       % animals were c_dark
    % c_mean = round(c_dark * 0.6);                          % mean was 40% darker again
    % to this, per SV: the first version's animal lines (c_light, ~[239 239 239])
    % were invisible, and this version's (c_dark) came out too dark - so the
    % animals now sit at the MIDPOINT of the group's light and dark gradient
    % ends, and the mean drops from 0.6*c_dark back to plain c_dark. Both are
    % "a little less dark" than the last screenshot while keeping the mean
    % clearly the darkest, thickest, only-solid line.
    [c_light, c_dark] = group_gradient_colors(blk.group);
    c_trace = round((c_light + c_dark) / 2);
    c_mean = c_dark;
    %

    for kk = 1:numel(blk.gidx)
        s = chart.SeriesCollection.NewSeries;
        s.Name = char(subj_labels(blk.gidx(kk)));
        s.Values = Sheet.Range(sprintf('%s%d:%s%d', col2letter(stage_col), blk.subj_row0 + kk - 1, ...
            col2letter(stage_col + n_pts - 1), blk.subj_row0 + kk - 1));
        s.XValues = cat_range;
        s.ChartType = 4;       % xlLine
        s.MarkerStyle = -4142; % xlMarkerStyleNone
        s.Format.Line.ForeColor.RGB = rgb_to_bgr(c_trace); % SV, August 23, 2026: was c_dark
        s.Format.Line.Weight = 1.25;
        try
            s.Format.Line.DashStyle = dash_styles(mod(kk - 1, numel(dash_styles)) + 1);
        catch
            % Dash styles are cosmetic - a failure here just leaves that
            % animal solid rather than aborting the whole chart.
        end
    end

    sMean = chart.SeriesCollection.NewSeries;
    % SV, August 23, 2026: I changed the mean series' name
    % sMean.Name = sprintf('%s_mean', char(blk.group));
    % to this - it now carries the SEM error bars, so it is the single
    % legend entry per group, and SV asked for that entry to read
    % "<group>_mean_SEM".
    sMean.Name = sprintf('%s_mean_SEM', char(blk.group));
    %
    sMean.Values = Sheet.Range(sprintf('%s%d:%s%d', col2letter(stage_col), blk.mean_srow, ...
        col2letter(stage_col + n_pts - 1), blk.mean_srow));
    sMean.XValues = cat_range;
    sMean.ChartType = 4;
    sMean.MarkerStyle = -4142;
    sMean.Format.Line.ForeColor.RGB = rgb_to_bgr(c_mean);
    sMean.Format.Line.Weight = 4; % vs 1.25 for the animals
    try
        sMean.Format.Line.DashStyle = 1; % msoLineSolid - the only solid line
    catch
    end

    % SV, August 23, 2026: I added - real +/- SEM error bars on the mean.
    % This is the third thing tried for the SEM, and the one that finally
    % satisfies every constraint at once: it can't be mistaken for an
    % animal's line (SV's complaint about the dotted bound lines), it does
    % not paint SEM where there is no data (SV's complaint about the area
    % fill's drop-to-zero), and it breaks cleanly between days.
    %
    % Worth recording: error bars were abandoned back in July after two COM
    % call styles both failed with 0x800A03EC. That failure was specific to
    % the BAR series in build_paired_barline_chart - retested here against a
    % live Excel session on a LINE series and the plain direct call works
    % first time. Constants: xlY=1, xlErrorBarIncludeBoth=1,
    % xlErrorBarTypeCustom=-4114; the last two args are the plus/minus
    % amount ranges (same SEM range for both, i.e. symmetric).
    try
        sem_range = Sheet.Range(sprintf('%s%d:%s%d', col2letter(stage_col), blk.sem_row, ...
            col2letter(stage_col + n_pts - 1), blk.sem_row));
        sMean.ErrorBar(1, 1, -4114, sem_range, sem_range);
        try
            sMean.ErrorBars.Format.Line.ForeColor.RGB = rgb_to_bgr(c_mean);
            sMean.ErrorBars.Format.Line.Weight = 1.5;
            sMean.ErrorBars.EndStyle = 1; % xlCap - visible end caps
        catch
            % Cosmetic only - default-formatted bars still convey the SEM.
        end
    catch ME
        warning(['Could not add SEM error bars to the %s mean on chart "%s": %s. ' ...
            'The mean and per-animal lines are unaffected - only the error bars are missing.'], ...
            char(blk.group), chart_title, ME.message);
    end
    %
end

chart.HasTitle = true;
chart.ChartTitle.Text = chart_title;
try
    chart.ChartTitle.Font.Size = 12;
catch
end

% Primary y axis: fixed 0-1 proportion scale, with the tick format
% explicitly un-source-linked - without that, Excel inherits a "0" format
% from a source cell and renders 0.2/0.4/... as "0"/"1" (hit in July).
% SV, September 3, 2026: I changed this whole block from the hardcoded
% 0-1/"Prop. successful" version to branch on y_axis_mode - 'proportion'
% (the default, used by successful_trials) is byte-for-byte the original
% code; 'auto' is new, for the hab_reward_rate tab's visit-count and
% locomotion-rate charts, which can't be capped at 1. Same auto-scale-with-
% zero-floor pattern already used by build_paired_barline_chart's 'count'
% mode and build_loco_barline_chart's y-axis, just parameterized here instead
% of copy-pasted a third time.
try
    yAxis = chart.Axes(2, 1); % xlValue, xlPrimary
    yAxis.HasTitle = true;
    yAxis.AxisTitle.Text = y_axis_title;
    if strcmp(y_axis_mode, 'auto')
        yAxis.MinimumScaleIsAuto = false;
        yAxis.MinimumScale = 0; % counts/distances/rates can't be negative
        yAxis.MaximumScaleIsAuto = true;
        yAxis.TickLabels.NumberFormatLinked = false;
        yAxis.TickLabels.NumberFormat = y_number_format;
    else
        yAxis.MinimumScaleIsAuto = false;
        yAxis.MaximumScaleIsAuto = false;
        yAxis.MinimumScale = -0.03;
        yAxis.MaximumScale = 1;
        yAxis.MajorUnit = 0.2;
        yAxis.TickLabels.NumberFormatLinked = false;
        yAxis.TickLabels.NumberFormat = y_number_format;
    end
catch ME
    warning('Could not set the primary y-axis on chart "%s": %s', chart_title, ME.message);
end

% Secondary y axis (only exists if a second group's band was pushed onto
% it): pin to the SAME scale as the primary and hide its labels, so the two
% SEM bands are drawn against identical scales.
% SV, August 23, 2026: I removed the secondary-y-axis block that used to be
% here. It only existed so the second group's stacked-AREA band could have
% its own independent stack; now that both groups' SEM bounds are plain line
% series on the primary axis, nothing stacks and no second axis is created,
% so there is nothing left to pin or hide. Was:
% if numel(blocks) > 1
%     try
%         y2 = chart.Axes(2, 2); % xlValue, xlSecondary
%         y2.MinimumScaleIsAuto = false;
%         y2.MaximumScaleIsAuto = false;
%         y2.MinimumScale = -0.03;
%         y2.MaximumScale = 1;
%         y2.TickLabelPosition = -4142;
%         y2.MajorTickMark = -4142;
%         y2.MinorTickMark = -4142;
%     catch ME
%         warning(...);
%     end
% end
%

try
    catAxis = chart.Axes(1, 1); % xlCategory, xlPrimary
    catAxis.TickLabels.Font.Size = 8;
    catAxis.Crosses = 4; % xlAxisCrossesMinimum
catch ME
    warning('Could not set the x-axis on chart "%s": %s', chart_title, ME.message);
end

% Legend: keep it (it's what maps a dash pattern back to an animal), but
% drop the SEM helper series' entries - they'd otherwise add 4 meaningless
% "sham SEM base"/"tms SEM" rows. Deleted from the highest index down so
% earlier indices stay valid as entries are removed. The series are added
% band-first above, so they occupy legend entries 1..n_sem_series.
% SV, August 23, 2026: I changed this whole block.
% Was:
% try
%     chart.HasLegend = true;
%     chart.Legend.Position = -4152;
%     chart.Legend.Font.Size = 8;
%     for k = n_sem_series:-1:1
%         try
%             chart.Legend.LegendEntries(k).Delete;
%         catch
%             % Non-fatal: worst case the legend keeps a SEM row.
%         end
%     end
% catch
% end
% That silently did nothing - SV's 2026-08-23 screenshot still showed all
% four "sham SEM"/"sham SEM base"/"tms SEM"/"tms SEM base" rows. Root cause
% is the SAME COM Item-resolution problem already documented at the top of
% write_formatted_xlsx for Cells(row,col): MATLAB doesn't reliably route the
% paren-call "LegendEntries(k)" through the collection's default Item
% member, so it threw and the bare inner catch swallowed it. Fixed by
% calling .Item(k) explicitly with a paren-indexing fallback, and by
% VERIFYING against LegendEntries.Count that an entry actually disappeared
% instead of assuming it did - a silent no-op is what hid this last time.
%
% Only the two invisible base-series entries are removed. The band entries
% stay (renamed "<group>_mean_SEM" above), which is what SV asked for.
% SV, August 23, 2026: I changed this block again. The previous version put
% HasLegend / Position / Font.Size / the entry deletion all inside ONE try.
% Per SV's MATLAB log, "chart.Legend.Font.Size = 8" throws on this
% Excel/MATLAB COM pairing ("Unrecognized method, property, or field 'Font'
% for class Interface.000208CD_..."), which aborted the whole block BEFORE
% the deletion loop ever ran - which is why the SEM base entries survived
% again even though the renaming above clearly took effect. Each step now
% gets its own try/catch so a cosmetic failure can't cancel a functional
% one, and the font size falls back to the TextFrame2 path.
try
    chart.HasLegend = true;
catch ME
    warning('Could not show the legend on chart "%s": %s', chart_title, ME.message);
end
try
    chart.Legend.Position = -4152; % xlLegendPositionRight
catch
    % Cosmetic only - Excel's default placement is fine.
end
try
    chart.Legend.Font.Size = 8;
catch
    % Legend.Font doesn't resolve on some Excel/MATLAB COM pairings (see
    % above). The modern TextFrame2 path usually does.
    try
        chart.Legend.Format.TextFrame2.TextRange.Font.Size = 8;
    catch
        % Cosmetic only - leave the legend at its default font size.
    end
end

% Remove just the upper-bound series' legend entries, keeping one
% "<group>_mean_SEM" row per group as SV asked.
% SV, August 23, 2026: the position formula below is unchanged (2*i), but
% for a different reason than before. It used to rely on Excel listing a
% stacked-AREA group top-of-stack first (band, then base). Now that all SEM
% series are plain LINE series, legend order simply follows the order they
% were added - lower, upper, lower, upper - so the upper bound for group i
% is still at position 2*i. Deleted high-to-low so lower indices stay valid.
% Verified against a live Excel session that LegendEntries.Item(k).Delete
% works and that Count actually decreases (it is checked below regardless).
try
    n_groups_with_band = n_sem_series / 2;
    deleted_ok = 0;
    for gi = n_groups_with_band:-1:1
        k = 2 * gi;
        before = legend_entry_count(chart);
        ok = try_delete_legend_entry(chart, k);
        after = legend_entry_count(chart);
        if ok && ~isnan(before) && ~isnan(after) && after < before
            deleted_ok = deleted_ok + 1;
        end
    end
    if deleted_ok < n_groups_with_band
        warning(['Could not remove %d of %d "SEM base" legend entr(y/ies) from chart "%s". ' ...
            'They are the invisible pedestal series under each SEM band - harmless, but to ' ...
            'hide them by hand: click the legend, click that single entry, press Delete.'], ...
            n_groups_with_band - deleted_ok, n_groups_with_band, chart_title);
    end
catch ME
    warning('Could not remove the SEM base legend entries on chart "%s": %s', chart_title, ME.message);
end
%
end

%%
% SV, September 3, 2026: I added this whole function - a summary BAR chart
% for a single-value-per-(day,group) metric, per SV's request: "Tones 1-9"
% (a whole-session average, not a bin in a 1-3->4-6->7-9 progression) doesn't
% belong on the same continuous line as the tercile bins, so it gets its own
% chart here instead. One bar pair (Sham, TMS mean +/- SEM) per day, with
% each mouse's own value overlaid as a circular marker - the same convention
% build_loco_barline_chart already uses for a day-repeating Sham/TMS pair,
% generalized here from a fixed 2-day layout to an arbitrary day count.
%
% "blocks" is the SAME struct build_success_combined_chart takes (group/
% first_subj_row/last_subj_row/mean_row) - this chart reads the SAME table,
% just a different column per day (day_col(d), the day's "1-9" column)
% instead of a per-bin column list, since every subject's row already spans
% every day as a column, not a row.
%
% SV, September 8, 2026: I added the optional trailing star_text/star_yval
% arguments (both default empty, so every existing call is unaffected) plus
% a new 'signed' y_axis_mode - for the new Reward Preference (Reward -
% Platform) charts SV requested: a difference score can be negative, which
% neither existing mode allows ('auto' clamps MinimumScale to 0; the
% fixed-proportion else-branch assumes a 0-1 bound) - and SV's reference
% image wants both a dashed zero-reference line and significance stars
% between the Sham/TMS bars, neither of which this chart drew before. Star
% drawing is adapted from build_paired_barline_chart's (same textbox-over-
% plot-area technique) but generalized to this chart's own n_cat=2*n_days
% layout instead of a hardcoded 8, and one bracket per day/bucket, not 4.
function co = build_summary_bar_chart(Sheet, blocks, day_names, day_col, ...
    chart_title, y_axis_title, y_axis_mode, y_number_format, ...
    anchor_left, anchor_top, chart_w, chart_h, stage_col, stage_row, star_text, star_yval)
if nargin < 15, star_text = {}; end
if nargin < 16, star_yval = []; end

day_names = string(day_names);
n_days = numel(day_names);
n_cat = 2 * n_days;
groups = repmat(["sham", "tms"], 1, n_days);
day_of = repelem(1:n_days, 2);

header_row1 = stage_row;     % day name
header_row2 = stage_row + 1; % Sham/TMS
mean_row    = stage_row + 2;
sem_row     = stage_row + 3;
subj_row0   = stage_row + 4;

% SV, September 3, 2026: I changed
% gi_sham = find(strcmp({blocks.group}, 'sham'), 1);
% gi_tms  = find(strcmp({blocks.group}, 'tms'), 1);
% (and the other two strcmp({blocks.group}, g) call sites below) to this -
% confirmed via a live MATLAB session that strcmp on a cell array of MATLAB
% "string" scalars (which is what blocks(bi).group holds - it's assigned
% from a "for g = ["sham","tms"]" string-array loop variable, not a char
% literal) silently returns all-false instead of matching, even though the
% content looks identical when displayed. [blocks.group] concatenates into a
% proper string array first, so == compares content correctly. This was
% causing the "1-9" summary bar chart to always report "no subjects in
% blocks" and skip itself, even with real data present.
if isempty(blocks)
    group_of_block = strings(1,0);
else
    group_of_block = [blocks.group];
end
gi_sham = find(group_of_block == "sham", 1);
gi_tms  = find(group_of_block == "tms", 1);
n_sham = 0; n_tms = 0;
if ~isempty(gi_sham), n_sham = blocks(gi_sham).last_subj_row - blocks(gi_sham).first_subj_row + 1; end
if ~isempty(gi_tms),  n_tms  = blocks(gi_tms).last_subj_row  - blocks(gi_tms).first_subj_row  + 1; end
n_subj = n_sham + n_tms;
if n_subj == 0
    warning('build_summary_bar_chart: no subjects in "blocks" - chart "%s" skipped.', chart_title);
    co = [];
    return
end

for idx = 1:n_cat
    c = stage_col + idx - 1;
    day_changed = (idx == 1) || (day_of(idx) ~= day_of(idx-1));
    % Force text format before writing - same date-autoconversion guard as
    % build_success_combined_chart (a day name here is never bin-range-like,
    % but this costs nothing and keeps the two functions' habits consistent).
    cellA = Sheet.Range(sprintf('%s%d', col2letter(c), header_row1));
    cellB = Sheet.Range(sprintf('%s%d', col2letter(c), header_row2));
    cellA.NumberFormat = '@'; cellB.NumberFormat = '@';
    if day_changed
        cellA.Value2 = char(day_names(day_of(idx)));
    end
    g = groups(idx);
    cellB.Value2 = group_label(g);

    gi = find(group_of_block == g, 1);
    if ~isempty(gi)
        blk = blocks(gi);
        cl = col2letter(day_col(day_of(idx)));
        rng_str = sprintf('%s%d:%s%d', cl, blk.first_subj_row, cl, blk.last_subj_row);
        Sheet.Range(sprintf('%s%d', col2letter(c), mean_row)).Formula = ...
            sprintf('=IF(COUNT(%s)=0,NA(),AVERAGE(%s))', rng_str, rng_str);
        Sheet.Range(sprintf('%s%d', col2letter(c), sem_row)).Formula = ...
            sprintf('=IFERROR(STDEV(%s)/SQRT(COUNT(%s)),0)', rng_str, rng_str);
    end
end

for idx = 1:n_cat
    c = stage_col + idx - 1;
    g = groups(idx);
    gi = find(group_of_block == g, 1);
    if isempty(gi), continue; end
    blk = blocks(gi);
    cl = col2letter(day_col(day_of(idx)));
    n_group = blk.last_subj_row - blk.first_subj_row + 1;
    if g == "sham", row_off = 0; else, row_off = n_sham; end
    for k = 1:n_group
        data_row = blk.first_subj_row + k - 1;
        Sheet.Range(sprintf('%s%d', col2letter(c), subj_row0 + row_off + k - 1)).Formula = ...
            sprintf('=IF(ISNUMBER(%s%d),%s%d,NA())', cl, data_row, cl, data_row);
    end
end

cat_range  = Sheet.Range(sprintf('%s%d:%s%d', col2letter(stage_col), header_row1, col2letter(stage_col+n_cat-1), header_row2));
mean_range = Sheet.Range(sprintf('%s%d:%s%d', col2letter(stage_col), mean_row, col2letter(stage_col+n_cat-1), mean_row));

co = Sheet.ChartObjects.Add(anchor_left, anchor_top, chart_w, chart_h);
try, co.Placement = 3; catch, end % xlFreeFloating
chart = co.Chart;
chart.ChartType = 51; % xlColumnClustered
chart.PlotVisibleOnly = false;

meanSeries = chart.SeriesCollection.NewSeries;
meanSeries.Name = 'Mean';
meanSeries.Values = mean_range;
meanSeries.XValues = cat_range;
meanSeries.ChartType = 51;
for idx = 1:n_cat
    [c0, ~] = group_gradient_colors(groups(idx));
    try
        meanSeries.Points.Item(idx).Format.Fill.Solid;
        meanSeries.Points.Item(idx).Format.Fill.ForeColor.RGB = rgb_to_bgr(c0);
        meanSeries.Points.Item(idx).Format.Line.Visible = 0;
    catch
    end
end

% SEM error bars on a BAR series: this failed with COM error 0x800A03EC back
% in July (see build_paired_barline_chart's changelog) and was dropped there
% rather than guessed at further. Retried here anyway since a LINE-series
% error bar DID start working cleanly in August (build_success_combined_chart)
% - if it fails the same way on this bar series, this is non-fatal: the bars
% and individual-mouse markers still convey the comparison without it.
try
    sem_range_full = Sheet.Range(sprintf('%s%d:%s%d', col2letter(stage_col), sem_row, col2letter(stage_col+n_cat-1), sem_row));
    meanSeries.ErrorBar(1, 1, -4114, sem_range_full, sem_range_full);
    try
        meanSeries.ErrorBars.EndStyle = 1; % xlCap
    catch
    end
catch ME
    warning(['Could not add SEM error bars to chart "%s": %s. The bars and individual-mouse ' ...
        'markers are unaffected - only the error bars are missing.'], chart_title, ME.message);
end

for idx = 1:n_subj
    if idx <= n_sham, g = "sham"; else, g = "tms"; end
    r = subj_row0 + idx - 1;
    s = chart.SeriesCollection.NewSeries;
    s.Name = sprintf('subj%d', idx);
    s.Values = Sheet.Range(sprintf('%s%d:%s%d', col2letter(stage_col), r, col2letter(stage_col+n_cat-1), r));
    s.XValues = cat_range;
    s.ChartType = 4; % xlLine, with the line hidden - markers only
    [~, c1] = group_gradient_colors(g);
    try
        s.Format.Line.Visible = 0;
        s.MarkerStyle = 8;  % xlMarkerStyleCircle
        s.MarkerSize = 5;
        s.MarkerForegroundColor = rgb_to_bgr(c1);
        s.MarkerBackgroundColor = rgb_to_bgr(c1);
    catch
        s.MarkerStyle = -4142;
        s.Format.Line.Visible = -1;
        s.Format.Line.ForeColor.RGB = rgb_to_bgr(c1);
        s.Format.Line.Weight = 1;
    end
end

% SV, September 8, 2026: I added this zero-reference line, drawn only for
% 'signed' mode (a difference score, where 0 is a meaningful reference
% rather than an axis endpoint) - a dashed horizontal line at y=0, matching
% SV's reference image. Written as a real data series (a row of literal
% zeros, one per category) rather than a chart gridline, since Excel has no
% simple "draw a line at value X" primitive for a category-axis chart.
if strcmp(y_axis_mode, 'signed')
    zero_row = subj_row0 + n_subj;
    zero_range = Sheet.Range(sprintf('%s%d:%s%d', col2letter(stage_col), zero_row, col2letter(stage_col+n_cat-1), zero_row));
    zero_range.Value2 = 0;
    zs = chart.SeriesCollection.NewSeries;
    zs.Name = 'zero';
    zs.Values = zero_range;
    zs.XValues = cat_range;
    zs.ChartType = 4; % xlLine
    try
        zs.Format.Line.Weight = 1;
        zs.Format.Line.ForeColor.RGB = rgb_to_bgr([120 120 120]);
        zs.Format.Line.DashStyle = 4; % msoLineDash
        zs.MarkerStyle = -4142; % xlMarkerStyleNone
    catch
    end
end

chart.HasTitle = true;
chart.ChartTitle.Text = chart_title;
try, chart.ChartTitle.Font.Size = 11; catch, end

try
    yAxis = chart.Axes(2, 1);
    yAxis.HasTitle = true;
    yAxis.AxisTitle.Text = y_axis_title;
    if strcmp(y_axis_mode, 'auto')
        yAxis.MinimumScaleIsAuto = false;
        yAxis.MinimumScale = 0; % counts/distances/rates can't be negative
        yAxis.MaximumScaleIsAuto = true;
    elseif strcmp(y_axis_mode, 'signed')
        % A difference score (Reward - Platform) can land on either side of
        % zero - fully auto lets Excel pick sensible bounds in both
        % directions instead of clamping the minimum at 0 like 'auto' does.
        yAxis.MinimumScaleIsAuto = true;
        yAxis.MaximumScaleIsAuto = true;
    else
        yAxis.MinimumScaleIsAuto = false;
        yAxis.MaximumScaleIsAuto = false;
        yAxis.MinimumScale = -0.03;
        yAxis.MaximumScale = 1;
        yAxis.MajorUnit = 0.2;
    end
    yAxis.TickLabels.NumberFormatLinked = false;
    yAxis.TickLabels.NumberFormat = y_number_format;
catch ME
    warning('Could not set the y-axis on chart "%s": %s', chart_title, ME.message);
end

try
    catAxis = chart.Axes(1, 1);
    catAxis.TickLabels.Font.Size = 8;
catch
end

try, chart.Legend.Delete; catch, end

% SV, September 8, 2026: I added this whole block - significance stars
% between each day/bucket's Sham/TMS bar pair, adapted from
% build_paired_barline_chart's identical textbox-over-plot-area technique
% (see its own changelog) but generalized to n_cat=2*n_days here instead of
% a hardcoded 8, and one bracket per day rather than 4. Only drawn when the
% caller passes star_text (every existing call site leaves it empty, so
% those charts are unaffected).
if ~isempty(star_text)
    try
        pa = chart.PlotArea;
        L0 = pa.InsideLeft; T0 = pa.InsideTop; W0 = pa.InsideWidth; H0 = pa.InsideHeight;
        yax = chart.Axes(2, 1);
        ymin = yax.MinimumScale; ymax = yax.MaximumScale;
        pair_first = 1:2:n_cat; % category pairs (1,2) (3,4) ... one per day
        for k = 1:min(numel(star_text), numel(pair_first))
            txt = star_text{k};
            if isempty(txt), continue; end
            i1 = pair_first(k); i2 = i1 + 1;
            xc = L0 + ((i1 - 0.5) + (i2 - 0.5)) / 2 / n_cat * W0;
            if k <= numel(star_yval) && ~isnan(star_yval(k))
                yv = star_yval(k) + 0.06 * (ymax - ymin);
            else
                yv = ymin + 0.92 * (ymax - ymin);
            end
            yv = min(yv, ymax);
            yp = T0 + (1 - (yv - ymin) / (ymax - ymin)) * H0;
            try
                tb = chart.Shapes.AddTextbox(1, xc - 20, yp - 15, 40, 16); % 1 = msoTextOrientationHorizontal
                tb.TextFrame.Characters.Text = txt;
                tb.TextFrame.HorizontalAlignment = -4108; % xlCenter
                try
                    tb.TextFrame2.TextRange.Font.Size = 12;
                    tb.TextFrame2.TextRange.Font.Bold = true;
                catch
                end
                try
                    tb.Fill.Visible = 0;
                    tb.Line.Visible = 0;
                catch
                end
            catch
                % One marker failing shouldn't lose the others.
            end
        end
    catch ME
        warning(['Could not draw significance markers on chart "%s": %s. The chart is unaffected ' ...
            '- only the on-chart stars are missing.'], chart_title, ME.message);
    end
end

try
    co.ShapeRange.AlternativeText = sprintf(['%s. Grouped bar chart, one Sham/TMS pair per day, ' ...
        'with individual mouse values overlaid as circular markers.'], chart_title);
catch
end
end

%%
% SV, August 23, 2026: I added - LegendEntries.Count, or NaN if it can't be
% read. Used to confirm a legend-entry delete actually took effect rather
% than silently no-opping (see the legend block above).
function n = legend_entry_count(chart)
n = NaN;
try
    n = chart.Legend.LegendEntries.Count;
catch
end
end

%%
% SV, August 23, 2026: I added - delete legend entry k, trying the COM call
% styles in order of reliability. Explicit .Item(k) first (the documented
% form, and the one that fixed the analogous Cells.Item problem elsewhere in
% this file), then paren indexing, then invoke(). Returns whether any style
% ran without throwing - the caller still checks Count to confirm it landed.
function ok = try_delete_legend_entry(chart, k)
ok = false;
try
    chart.Legend.LegendEntries.Item(k).Delete;
    ok = true;
    return
catch
end
try
    chart.Legend.LegendEntries(k).Delete;
    ok = true;
    return
catch
end
try
    entry = invoke(chart.Legend.LegendEntries, 'Item', k);
    entry.Delete;
    ok = true;
catch
end
end

%%
% SV, August 23, 2026: I added - proportion of successful (shock-avoided)
% trials within one tone bin, from the NaN-padded per-tone 0/1 vector.
% Returns NaN (-> blank cell) when the bin contains no real tones, which is
% what makes a 5-tone session's "Tones 7-9" bin blank instead of a
% misleading 0.
function p = bin_success_proportion(success_vec, bin_range)
p = NaN;
if isempty(success_vec)
    return
end
idx = bin_range(bin_range <= numel(success_vec));
if isempty(idx)
    return
end
v = success_vec(idx);
v = v(~isnan(v)); % drop padding for tones this session didn't have
if isempty(v)
    return
end
p = sum(v) / numel(v);
end

%%
% SV, September 3, 2026: I added - mean of a NaN-padded per-cycle vector
% (e.g. Merged.PerTimeInROI) within one bin range, same NaN-until-real-data
% convention as bin_success_proportion/bin_sum below: a bin with nothing real
% in it comes back NaN (-> blank cell), not a misleading 0. Used by
% write_hab_reward_tab for the reward time-in-zone table (a proportion, so
% averaged rather than summed - contrast with bin_sum for counts/distances).
function m = bin_mean(vec, bin_range)
m = NaN;
if isempty(vec)
    return
end
idx = bin_range(bin_range <= numel(vec));
if isempty(idx)
    return
end
v = vec(idx);
v = v(~isnan(v));
if isempty(v)
    return
end
m = mean(v);
end

%%
% SV, September 3, 2026: I added - sum of a NaN-padded per-tone/per-ITI
% vector (visit count or locomotion distance) within one bin range, dropping
% indices beyond what this session actually had. Same NaN-until-real-data
% convention as bin_success_proportion: a bin with nothing real in it comes
% back NaN (-> blank cell), not a misleading 0. Used by write_hab_reward_tab
% for the visit-count and locomotion-distance tables.
function s = bin_sum(vec, bin_range)
s = NaN;
if isempty(vec)
    return
end
idx = bin_range(bin_range <= numel(vec));
if isempty(idx)
    return
end
v = vec(idx);
v = v(~isnan(v));
if isempty(v)
    return
end
s = sum(v);
end

%%
% SV, September 3, 2026: I added - sum(distance)/sum(duration) over one bin
% range, NOT a mean of per-window rates - a bin's windows can vary in length
% (ITI windows especially), so a plain mean of rates would weight a short
% window the same as a long one. Same sum(distance)/sum(duration) convention
% BehDEPOT_Analysis_SVv5.m's Analysis.Locomotion already uses (as did this
% script's superseded locomotion tabs, removed 2026-09-28). Used by write_hab_reward_tab for the
% locomotion-rate table/chart.
function r = bin_rate(dist_vec, dur_vec, bin_range)
r = NaN;
if isempty(dist_vec) || isempty(dur_vec)
    return
end
idx = bin_range(bin_range <= min(numel(dist_vec), numel(dur_vec)));
if isempty(idx)
    return
end
d = dist_vec(idx); d = d(~isnan(d));
t = dur_vec(idx);  t = t(~isnan(t));
if isempty(d) || isempty(t) || sum(t) == 0
    return
end
r = sum(d) / sum(t);
end

%%
% SV, September 3, 2026: I added this whole function - a shared "trend
% table + line time-course chart" block, appended onto an ALREADY-OPEN sheet
% at (start_row, start_col), per SV's request to add the successful_trials-
% style time-course view (bins 1-3/4-6/7-9/1-9 across every day, in one
% picture) to zone_visits and each binned_tones_* tab too ("I am missing
% trends in the data by just summarizing them in this way"). Used from
% write_visits_tab (visit counts) and write_binned_tab (proportion of time
% in zone) so that machinery isn't written a third and fourth time -
% structurally this is write_locomotion_tab's Distance/Rate table, minus the
% two-tables-side-by-side part (only one metric here) and generalized to any
% Sham/TMS-groupable per-tone/per-ITI source via the two callback handles.
%
% start_col matters: these tabs already have their OWN chart-feeder staging
% columns (chart_stage_col_a/b, hidden via EntireColumn.Hidden = true at the
% end of the caller). Column-hiding is whole-column, top to bottom,
% regardless of row - so this block's start_col MUST sit clear of that
% existing hidden range, or its own visible table would silently vanish too.
% Callers pass a start_col comfortably past their own hide range rather than
% reusing column 1 and relying on row separation, which would NOT be enough.
%
% tone_fn(k, bin_range) / iti_fn(k, bin_range) -> a single number for session
% row k of "rows" for that bin range (NaN for no data) - e.g.
% @(k,br) bin_sum(rows(k).Plat_tone_visit_vec, br) for zone_visits, or
% @(k,br) bin_mean(rows(k).CSp_plat_time, br) for binned_tones. Every cell
% here is a computed LITERAL (not a live formula back to another tab) even
% when the source data does exist on all_tones (binned_tones' case) - kept
% simple and consistent with write_successful_trials_tab's own literal
% precedent, since this is supplementary content, not a replacement for
% those tabs' existing live-formula pivot tables.
%
% Returns the row immediately below everything just written, so a caller
% chaining a second block underneath (e.g. write_visits_tab's Platform then
% Reward calls) can pass it straight back in as the next start_row.
function next_row = write_trend_table_and_chart(Sheet, start_row, start_col, zero_font_bgr, ...
    rows, bin_ranges, bin_labels, tone_fn, iti_fn, table_title, is_integer, scale_mode, ...
    chart_title, y_title, y_mode, y_fmt, exclude_hab)

n_bins = numel(bin_ranges);
short_bin_labels = strings(1, n_bins); % "Tones 1-3" -> "1-3"
for b = 1:n_bins
    short_bin_labels(b) = strtrim(erase(bin_labels(b), "Tones"));
end

n = numel(rows);
e_day = strings(1, n); e_group = strings(1, n);
e_subjnum = nan(1, n); e_subjlabel = strings(1, n);
keep = false(1, n);
for i = 1:n
    d = day_from_condition(rows(i).Condition);
    if exclude_hab && startsWith(d, 'Hab', 'IgnoreCase', true)
        continue
    end
    [num, lbl] = parse_subject(rows(i).Subject);
    e_day(i) = d;
    e_group(i) = classify_group(rows(i).Condition);
    e_subjnum(i) = num;
    e_subjlabel(i) = string(lbl);
    keep(i) = true;
end
if ~any(keep)
    warning('%s: no sessions found - trend block skipped.', table_title);
    next_row = start_row;
    return
end
days = unique(e_day(keep), 'stable'); % rows are pre-sorted chronologically upstream
n_days = numel(days);

subj_nums = []; subj_labels = strings(0); subj_groups = strings(0);
for g = ["sham", "tms"]
    idx = find(keep & e_group == g);
    [~, order] = sort(e_subjnum(idx));
    for k = idx(order)
        if ~ismember(e_subjnum(k), subj_nums)
            subj_nums(end+1) = e_subjnum(k); %#ok<AGROW>
            subj_labels(end+1) = e_subjlabel(k); %#ok<AGROW>
            subj_groups(end+1) = g; %#ok<AGROW>
        end
    end
end

group_col = start_col; subj_col = start_col + 1; data_col0 = start_col + 2;
last_col = data_col0 + n_days*2*n_bins - 1;

title_row   = start_row;
header_row2 = start_row + 1; % Group/Subject start, Day bracket
header_row3 = start_row + 2; % (nested) Tone/ITI bracket
header_row4 = start_row + 3; % Group/Subject end, bin labels
data_start_row = start_row + 4;

tblHeader = Sheet.Range(sprintf('%s%d:%s%d', col2letter(group_col), title_row, col2letter(last_col), title_row));
tblHeader.Merge; tblHeader.Value2 = table_title;
tblHeader.Font.Bold = true; tblHeader.Font.Size = 12; tblHeader.HorizontalAlignment = -4108;

grpHeader = Sheet.Range(sprintf('%s%d:%s%d', col2letter(group_col), header_row2, col2letter(group_col), header_row4));
grpHeader.Merge; grpHeader.Value2 = 'Group';
grpHeader.Font.Bold = true; grpHeader.HorizontalAlignment = -4108; grpHeader.VerticalAlignment = -4108;

subjHeader = Sheet.Range(sprintf('%s%d:%s%d', col2letter(subj_col), header_row2, col2letter(subj_col), header_row4));
subjHeader.Merge; subjHeader.Value2 = 'Subject';
subjHeader.Font.Bold = true; subjHeader.HorizontalAlignment = -4108; subjHeader.VerticalAlignment = -4108;

day_tone_col = zeros(1, n_days); day_iti_col = zeros(1, n_days);
for dcol = 1:n_days
    d0 = data_col0 + (dcol-1)*2*n_bins;
    day_tone_col(dcol) = d0;
    day_iti_col(dcol) = d0 + n_bins;

    dayHeader = Sheet.Range(sprintf('%s%d:%s%d', col2letter(d0), header_row2, col2letter(d0+2*n_bins-1), header_row2));
    dayHeader.Merge; dayHeader.Value2 = char(days(dcol));
    dayHeader.Font.Bold = true; dayHeader.HorizontalAlignment = -4108;

    toneHeader = Sheet.Range(sprintf('%s%d:%s%d', col2letter(d0), header_row3, col2letter(d0+n_bins-1), header_row3));
    toneHeader.Merge; toneHeader.Value2 = 'Tone';
    toneHeader.Font.Bold = true; toneHeader.HorizontalAlignment = -4108;

    itiHeader = Sheet.Range(sprintf('%s%d:%s%d', col2letter(d0+n_bins), header_row3, col2letter(d0+2*n_bins-1), header_row3));
    itiHeader.Merge; itiHeader.Value2 = 'ITI';
    itiHeader.Font.Bold = true; itiHeader.HorizontalAlignment = -4108;

    for b = 1:n_bins
        % NumberFormat='@' - date-autoconversion guard, see
        % build_success_combined_chart's changelog.
        bc1 = Sheet.Range(sprintf('%s%d', col2letter(d0+b-1), header_row4));
        bc1.NumberFormat = '@'; bc1.Value2 = char(short_bin_labels(b)); bc1.HorizontalAlignment = -4108;
        bc2 = Sheet.Range(sprintf('%s%d', col2letter(d0+n_bins+b-1), header_row4));
        bc2.NumberFormat = '@'; bc2.Value2 = char(short_bin_labels(b)); bc2.HorizontalAlignment = -4108;
    end
end

blocks = struct('group', {}, 'first_subj_row', {}, 'last_subj_row', {}, 'mean_row', {});
r = data_start_row;
for g = ["sham", "tms"]
    gidx = find(subj_groups == g);
    if isempty(gidx)
        continue
    end
    first_subj_row = r;
    vals = nan(numel(gidx), 2*n_days*n_bins);
    for kk = 1:numel(gidx)
        s = gidx(kk);
        row_r = first_subj_row + kk - 1;
        Sheet.Range(sprintf('%s%d', col2letter(subj_col), row_r)).Value2 = char(subj_labels(s));
        for dcol = 1:n_days
            k = find(keep & e_subjnum == subj_nums(s) & e_day == days(dcol), 1);
            for b = 1:n_bins
                bin_range = bin_ranges{b};
                cc_t = (dcol-1)*2*n_bins + b;
                cc_i = (dcol-1)*2*n_bins + n_bins + b;
                if isempty(k) % subject didn't run this day
                    vT = NaN; vI = NaN;
                else
                    vT = tone_fn(k, bin_range);
                    vI = iti_fn(k, bin_range);
                end
                write_value_cell(Sheet.Range(sprintf('%s%d', col2letter(day_tone_col(dcol)+b-1), row_r)), vT, is_integer);
                write_value_cell(Sheet.Range(sprintf('%s%d', col2letter(day_iti_col(dcol)+b-1), row_r)), vI, is_integer);
                vals(kk,cc_t) = vT; vals(kk,cc_i) = vI;
            end
        end
    end
    last_subj_row = row_r;
    r = last_subj_row + 1;

    mean_row = r;
    lblCell = Sheet.Range(sprintf('%s%d', col2letter(subj_col), mean_row));
    lblCell.Value2 = sprintf('%s_mean', char(g));
    lblCell.Font.Bold = true;
    for dcol = 1:n_days
        for b = 1:n_bins
            for which = ["tone", "iti"]
                if which == "tone"
                    cc = (dcol-1)*2*n_bins + b;
                    cletter = col2letter(day_tone_col(dcol) + b - 1);
                else
                    cc = (dcol-1)*2*n_bins + n_bins + b;
                    cletter = col2letter(day_iti_col(dcol) + b - 1);
                end
                cellRange = Sheet.Range(sprintf('%s%d', cletter, mean_row));
                snapshot = mean(vals(:,cc), 'omitnan');
                formula_str = sprintf('=AVERAGE(%s%d:%s%d)', cletter, first_subj_row, cletter, last_subj_row);
                write_formula_cell(cellRange, formula_str, snapshot);
                cellRange.Font.Bold = true;
            end
        end
    end
    r = r + 1;

    merge_label_cell(Sheet, group_col, first_subj_row, mean_row, group_label(g), g);
    apply_group_gradient_cf(Sheet, data_col0, last_col, first_subj_row, mean_row, g, zero_font_bgr, scale_mode);

    bi = numel(blocks) + 1;
    blocks(bi).group = g;
    blocks(bi).first_subj_row = first_subj_row;
    blocks(bi).last_subj_row = last_subj_row;
    blocks(bi).mean_row = mean_row;
end
last_data_row = r - 1;

day_cols_c = cell(1, n_days);
day_labels_c = cell(1, n_days);
for dcol = 1:n_days
    day_cols_c{dcol} = [day_tone_col(dcol):(day_tone_col(dcol)+n_bins-1), day_iti_col(dcol):(day_iti_col(dcol)+n_bins-1)];
    day_labels_c{dcol} = ["T " + short_bin_labels, "I " + short_bin_labels];
end
CHART_W = 760; CHART_H = 300;
chart_stage_col = last_col + 5;
% SV, September 3, 2026: I changed
% chart_anchor = Sheet.Range(sprintf('A%d', last_data_row + 3));
% to this - hardcoded column "A" put the chart at the LEFT EDGE of the
% sheet regardless of where this table itself actually starts (start_col,
% e.g. col 45 for zone_visits' trend blocks), so it landed directly on top
% of whatever already occupies column A at that row - which, for a trend
% block appended below existing content, is that existing content's own
% tables/charts. Confirmed from SV's screenshot: the new chart was drawn
% overlapping the day-block pivot tables/charts above it. Anchoring at this
% table's own group_col (not "A") is what group_col is FOR.
chart_anchor = Sheet.Range(sprintf('%s%d', col2letter(group_col), last_data_row + 3));
try
    build_success_combined_chart(Sheet, blocks, days, day_cols_c, day_labels_c, ...
        subj_labels, subj_groups, chart_title, chart_anchor.Left, chart_anchor.Top, ...
        CHART_W, CHART_H, chart_stage_col, 1, y_title, y_mode, y_fmt);
catch ME
    warning('Could not build the "%s" trend chart: %s', chart_title, ME.message);
end
try
    Sheet.Range(sprintf('%s1:%s1', col2letter(group_col), col2letter(subj_col))).EntireColumn.AutoFit;
    Sheet.Range(sprintf('%s1:%s1', col2letter(data_col0), col2letter(last_col))).EntireColumn.AutoFit;
catch
end
try
    Sheet.Range(sprintf('%s:%s', col2letter(chart_stage_col), ...
        col2letter(chart_stage_col + 2*n_days*n_bins + n_days + 20))).EntireColumn.Hidden = true;
catch
end

next_row = last_data_row + 3 + ceil(CHART_H/15) + 3;
end

%%
% SV, September 3, 2026 (later same day): I added this whole function - a
% SINGLE-metric sibling of write_trend_table_and_chart (no Tone/ITI
% doubling: one value per subject/day/bin), which ALSO splits the trailing
% whole-range "1-9" bin out into its own companion Summary bar chart instead
% of leaving it in the timecourse - per SV's hand-drawn sketch for the
% locomotion tab redesign, and the same "1-9 doesn't belong on the same line
% as a 3-tone bin" fix already applied to successful_trials.
%
% Used 6 times by write_locomotion_tab (Distance/Rate x Habituation/Train-
% Retr-ITI/Train-Retr-Tone) - each call is one table + its timecourse chart
% + its summary chart, and the 3 write_locomotion_tab calls per metric chain
% together vertically via next_row, same pattern write_trend_table_and_chart
% already uses for write_visits_tab's Platform-then-Reward pair.
%
% day_list is an EXPLICIT chronological day list the caller controls (e.g.
% ["HabD1","HabD2","HabD3"] or ["TrainD1",...,"Retr"]), rather than being
% derived by including/excluding Hab automatically - different calls need
% different day subsets from the SAME "rows" array. Sessions on a day not in
% day_list are simply not matched by any subject/day lookup below, exactly
% as if they didn't exist for this call.
%
% stage_col_base: like write_trend_table_and_chart, this table's own visible
% columns start at start_col, but its (and its summary chart's) HIDDEN
% chart-feeder staging columns start at stage_col_base instead of being
% derived from this table's own width - callers making several calls in a
% row (write_locomotion_tab makes 6) must space stage_col_base far enough
% apart themselves, since column-hiding is whole-column and two calls'
% staging areas landing on the same columns would silently corrupt each
% other's chart data even though their VISIBLE tables sit in different rows.
% SV, September 3, 2026: I added the optional trailing is_integer argument
% (default false, so write_locomotion_tab's existing calls - all decimal
% cm/cm-per-s values - are unaffected). write_visits_tab's new calls pass
% true: visit counts should read "12", not "12.000".
function next_row = write_simple_trend_table_and_chart(Sheet, start_row, start_col, stage_col_base, zero_font_bgr, ...
    rows_in, day_list, bin_ranges, bin_labels, value_fn, table_title, scale_mode, ...
    chart_title, y_title, y_mode, y_fmt, summary_title, is_integer)
if nargin < 18, is_integer = false; end

day_list = string(day_list);
n_bins_full = numel(bin_ranges);
n_bins = n_bins_full - 1; % timecourse excludes the trailing whole-range "1-9" aggregate
short_bin_labels = strings(1, n_bins_full); % "Tones 1-3" -> "1-3"
for b = 1:n_bins_full
    short_bin_labels(b) = strtrim(erase(bin_labels(b), "Tones"));
end

n = numel(rows_in);
e_day = strings(1, n); e_group = strings(1, n);
e_subjnum = nan(1, n); e_subjlabel = strings(1, n);
keep = false(1, n);
for i = 1:n
    d = day_from_condition(rows_in(i).Condition);
    if ~any(d == day_list)
        continue
    end
    [num, lbl] = parse_subject(rows_in(i).Subject);
    e_day(i) = d;
    e_group(i) = classify_group(rows_in(i).Condition);
    e_subjnum(i) = num;
    e_subjlabel(i) = string(lbl);
    keep(i) = true;
end
if ~any(keep)
    warning('%s: no sessions found - trend block skipped.', table_title);
    next_row = start_row;
    return
end
% day_list's OWN order is the chronological order (the caller decided it),
% not first-appearance order in "rows_in" - unlike every other tab's
% unique(...,'stable') trick, since a Tone-only/ITI-only slice of "rows_in"
% doesn't itself carry a meaningful first-appearance order independent of
% day_list.
days = day_list(ismember(day_list, unique(e_day(keep))));
n_days = numel(days);

subj_nums = []; subj_labels = strings(0); subj_groups = strings(0);
for g = ["sham", "tms"]
    idx = find(keep & e_group == g);
    [~, order] = sort(e_subjnum(idx));
    for k = idx(order)
        if ~ismember(e_subjnum(k), subj_nums)
            subj_nums(end+1) = e_subjnum(k); %#ok<AGROW>
            subj_labels(end+1) = e_subjlabel(k); %#ok<AGROW>
            subj_groups(end+1) = g; %#ok<AGROW>
        end
    end
end

group_col = start_col; subj_col = start_col + 1; data_col0 = start_col + 2;
last_col = data_col0 + n_days*n_bins_full - 1; % table shows ALL bins incl. 1-9; only the chart excludes it

title_row   = start_row;
header_row2 = start_row + 1; % Group/Subject start, Day bracket
header_row3 = start_row + 2; % Group/Subject end, bin labels
data_start_row = start_row + 3;

tblHeader = Sheet.Range(sprintf('%s%d:%s%d', col2letter(group_col), title_row, col2letter(last_col), title_row));
tblHeader.Merge; tblHeader.Value2 = table_title;
tblHeader.Font.Bold = true; tblHeader.Font.Size = 12; tblHeader.HorizontalAlignment = -4108;

grpHeader = Sheet.Range(sprintf('%s%d:%s%d', col2letter(group_col), header_row2, col2letter(group_col), header_row3));
grpHeader.Merge; grpHeader.Value2 = 'Group';
grpHeader.Font.Bold = true; grpHeader.HorizontalAlignment = -4108; grpHeader.VerticalAlignment = -4108;

subjHeader = Sheet.Range(sprintf('%s%d:%s%d', col2letter(subj_col), header_row2, col2letter(subj_col), header_row3));
subjHeader.Merge; subjHeader.Value2 = 'Subject';
subjHeader.Font.Bold = true; subjHeader.HorizontalAlignment = -4108; subjHeader.VerticalAlignment = -4108;

day_col_start = zeros(1, n_days);
for dcol = 1:n_days
    c0 = data_col0 + (dcol-1)*n_bins_full;
    day_col_start(dcol) = c0;
    dayHeader = Sheet.Range(sprintf('%s%d:%s%d', col2letter(c0), header_row2, col2letter(c0+n_bins_full-1), header_row2));
    dayHeader.Merge; dayHeader.Value2 = char(days(dcol));
    dayHeader.Font.Bold = true; dayHeader.HorizontalAlignment = -4108;
    for b = 1:n_bins_full
        % NumberFormat='@' - date-autoconversion guard, see
        % build_success_combined_chart's changelog.
        bc = Sheet.Range(sprintf('%s%d', col2letter(c0+b-1), header_row3));
        bc.NumberFormat = '@'; bc.Value2 = char(short_bin_labels(b)); bc.HorizontalAlignment = -4108;
    end
end

blocks = struct('group', {}, 'first_subj_row', {}, 'last_subj_row', {}, 'mean_row', {});
r = data_start_row;
for g = ["sham", "tms"]
    gidx = find(subj_groups == g);
    if isempty(gidx)
        continue
    end
    first_subj_row = r;
    vals = nan(numel(gidx), n_days*n_bins_full);
    for kk = 1:numel(gidx)
        s = gidx(kk);
        row_r = first_subj_row + kk - 1;
        Sheet.Range(sprintf('%s%d', col2letter(subj_col), row_r)).Value2 = char(subj_labels(s));
        for dcol = 1:n_days
            k = find(keep & e_subjnum == subj_nums(s) & e_day == days(dcol), 1);
            for b = 1:n_bins_full
                cc = (dcol-1)*n_bins_full + b;
                if isempty(k) % subject didn't run this day
                    v = NaN;
                else
                    v = value_fn(k, bin_ranges{b});
                end
                write_value_cell(Sheet.Range(sprintf('%s%d', col2letter(day_col_start(dcol)+b-1), row_r)), v, is_integer);
                vals(kk,cc) = v;
            end
        end
    end
    last_subj_row = row_r;
    r = last_subj_row + 1;

    mean_row = r;
    lblCell = Sheet.Range(sprintf('%s%d', col2letter(subj_col), mean_row));
    lblCell.Value2 = sprintf('%s_mean', char(g));
    lblCell.Font.Bold = true;
    for cc = 1:(n_days*n_bins_full)
        dcol = ceil(cc/n_bins_full); b = cc - (dcol-1)*n_bins_full;
        cletter = col2letter(day_col_start(dcol) + b - 1);
        cellRange = Sheet.Range(sprintf('%s%d', cletter, mean_row));
        snapshot = mean(vals(:,cc), 'omitnan');
        formula_str = sprintf('=AVERAGE(%s%d:%s%d)', cletter, first_subj_row, cletter, last_subj_row);
        write_formula_cell(cellRange, formula_str, snapshot);
        cellRange.Font.Bold = true;
    end
    r = r + 1;

    merge_label_cell(Sheet, group_col, first_subj_row, mean_row, group_label(g), g);
    apply_group_gradient_cf(Sheet, data_col0, last_col, first_subj_row, mean_row, g, zero_font_bgr, scale_mode);

    bi = numel(blocks) + 1;
    blocks(bi).group = g;
    blocks(bi).first_subj_row = first_subj_row;
    blocks(bi).last_subj_row = last_subj_row;
    blocks(bi).mean_row = mean_row;
end
last_data_row = r - 1;

% --- Timecourse chart: bins 1..n_bins (excludes the trailing "1-9") ---
day_cols_c = cell(1, n_days);
day_labels_c = cell(1, n_days);
for dcol = 1:n_days
    day_cols_c{dcol} = day_col_start(dcol) : (day_col_start(dcol)+n_bins-1);
    day_labels_c{dcol} = short_bin_labels(1:n_bins);
end
% SV, September 8, 2026: I moved this table's own AutoFit call (used to run
% AFTER both charts were built, down where the second try-block below still
% is) up to HERE, before the timecourse chart is sized/built - the chart's
% width needs the table's REAL (post-AutoFit) width, not a fixed guess. Per
% SV's screenshot: the timecourse chart used to be visibly wider than its
% own table (CHART_W was a fixed 480pt regardless of how narrow AutoFit made
% these bin-label columns), and that same fixed width is what pushed the
% summary chart's old "co1.Left + CHART_W + gap" anchor far past the table's
% actual right edge instead of landing just past it.
try
    Sheet.Range(sprintf('%s1:%s1', col2letter(group_col), col2letter(subj_col))).EntireColumn.AutoFit;
    Sheet.Range(sprintf('%s1:%s1', col2letter(data_col0), col2letter(last_col))).EntireColumn.AutoFit;
catch
end
CHART_W = Sheet.Range(sprintf('%s%d:%s%d', col2letter(group_col), title_row, col2letter(last_col), title_row)).Width;
CHART_H = 280;
chart_stage_col = stage_col_base;
% SV, September 3, 2026: I changed
% chart_anchor = Sheet.Range(sprintf('A%d', last_data_row + 3));
% to this - same fix as write_trend_table_and_chart's identical bug (see its
% changelog): "A" is only correct when start_col happens to be 1, which was
% true for every write_locomotion_tab call (masking the bug there) but false
% for zone_visits' calls (start_col=45), where it put the chart on top of
% whatever already occupies column A at that row.
chart_anchor = Sheet.Range(sprintf('%s%d', col2letter(group_col), last_data_row + 3));
co1 = [];
try
    co1 = build_success_combined_chart(Sheet, blocks, days, day_cols_c, day_labels_c, ...
        subj_labels, subj_groups, chart_title, chart_anchor.Left, chart_anchor.Top, ...
        CHART_W, CHART_H, chart_stage_col, 1, y_title, y_mode, y_fmt);
catch ME
    warning('Could not build the "%s" trend chart: %s', chart_title, ME.message);
end

% --- Summary bar chart: the trailing "1-9" column, one bar-pair per day ---
% SV, September 8, 2026: I changed the summary_left calculation TWICE today.
% First from "co1.Left + CHART_W + 16" to a separate cell lookup (the left
% edge of the column right after the table's own last_col) - meant to fix
% the summary chart drifting far from a table whose real (post-AutoFit)
% width didn't match a fixed CHART_W guess. CHART_W is now genuinely
% table-width-derived, so that reasoning no longer applied, and per SV's
% NEXT screenshot the separate cell lookup introduced a worse version of
% the same symptom: when a later stacked block re-autofits these SAME
% columns (Habituation/Train-Retr ITI/Train-Retr Tone all share start_col),
% a cell-based lookup computed at build time can disagree with where this
% chart's OWN paired timecourse chart (co1) actually ends up once
% Placement=xlFreeFloating is set on it (see build_success_combined_chart's
% changelog) and it stops silently resizing with those later AutoFits.
% Anchoring off co1's own Left+Width instead - "next to its corresponding
% timecourse plot", per SV - is self-consistent by construction: both
% charts are free-floating now, so neither drifts again after later blocks
% run their own AutoFit.
summary_col = day_col_start + n_bins; % the "1-9" column for each day (last of n_bins_full)
summary_gap_pt = 20;
summary_left = chart_anchor.Left;
if ~isempty(co1)
    summary_left = co1.Left + CHART_W + summary_gap_pt;
end
summary_stage_col = stage_col_base + n_days*n_bins + n_days + 15;
try
    build_summary_bar_chart(Sheet, blocks, days, summary_col, summary_title, ...
        y_title, y_mode, y_fmt, summary_left, chart_anchor.Top, 280, CHART_H, summary_stage_col, 1);
catch ME
    warning('Could not build the "%s" summary chart: %s', summary_title, ME.message);
end

try
    Sheet.Range(sprintf('%s:%s', col2letter(chart_stage_col), ...
        col2letter(summary_stage_col + 2*n_days + 20))).EntireColumn.Hidden = true;
catch
end

next_row = last_data_row + 3 + ceil(CHART_H/15) + 3;
end

%%
% SV, August 23, 2026: I changed the signature to return "recs" - the paired
% comparison records behind this tab's charts - so write_formatted_xlsx can
% collect them for the stats tab. Same change as write_visits_tab.
% SV, September 3, 2026: I added the trailing trend_bin_ranges/
% trend_bin_labels parameters - the FULL 1-3/4-6/7-9/1-9 bin set (as
% opposed to tone_range/range_label above, which is just THIS call's own
% single bin), needed for the new trend chart appended at the bottom of this
% tab - see write_trend_table_and_chart's own changelog for why every one of
% the 4 binned_tones_* tabs gets the identical full-range chart, per SV's
% choice.
% SV, September 8, 2026: I dropped the trailing trend_bin_ranges/
% trend_bin_labels parameters - the trend section they fed moved out to its
% own write_zone_time_timecourse_tab function/tab (see that function's
% changelog and the write_formatted_xlsx call site for both).
function recs = write_binned_tab(Workbook, sheet_name, rows, tone_range, range_label, zero_font_bgr, ...
    metric_names, max_tones, all_tones_sheet_name, all_tones_data_start_row)
recs = struct('tab', {}, 'day', {}, 'plot', {}, 'comparison', {}, 'n', {}, ...
    'mean_a', {}, 'mean_b', {}, 'p_t', {}, 'p_t_holm', {}, 'p_w', {}, 'p_w_holm', {}, 'stars', {});
%
% New in v4 - one tab for a given tone-averaging range (1:3, 4:6, or 1:6). For each
% experimental day (Condition with its sham_/tms_ prefix stripped), writes two pivoted
% tables side by side - Platform-v-Reward and Tone-v-ITI - each with rows grouped
% Sham/TMS -> sub-group -> Subject, and stacks each day's pair of tables below the last.
%
% SV, July 24, 2026: I changed the function signature
% function write_binned_tab(Workbook, sheet_name, rows, tone_range, range_label, zero_font_bgr)
% to this (needs the metric column layout + "all tones" tab name/data-start-row to build
% "=AVERAGE('all tones'!..)" formulas - see bin_rows/tone_avg_formula below):
% (signature shown above already reflects the change)
%

% Capture the current last sheet BEFORE adding, then move the new sheet after it - safer
% across MATLAB/Excel COM versions than relying on Sheets.Add(Before,After) with an empty-
% bracket "omitted" Before argument, given the Cells/Item COM quirks already hit above.
last_sheet = Workbook.Sheets.Item(Workbook.Sheets.Count);
Sheet = Workbook.Sheets.Add;
Sheet.Move([], last_sheet);
Sheet.Name = sheet_name;

% SV, July 24, 2026: I changed
% br = bin_rows(rows, tone_range);
% to this (bin_rows now builds "=AVERAGE(...)" formula strings back to "all tones" instead
% of MATLAB-computed literal averages):
br = bin_rows(rows, tone_range, metric_names, max_tones, all_tones_sheet_name, all_tones_data_start_row);
%
days = unique([br.Day], 'stable'); % preserve first-appearance order (matches folder scan order)

t1_col = struct('day',1, 'group',2, 'sub',3, 'subj',4, 'a',5, 'b',6);   % Platform v Reward, cols A-F
t2_col = struct('day',8, 'group',9, 'sub',10, 'subj',11, 'a',12, 'b',13); % Tone v ITI, cols H-M (gap col G)
% SV, September 8, 2026: I added these two - same Reward Preference
% (Reward - Platform) staging columns as write_zone_visits_compared_tab's
% identical addition (see its changelog).
t1_col.pref = t1_col.b + 2;      % col H  - Hab days' "Reward - Platform"
t2_col.pref_tone = t2_col.b + 2; % col O  - Train/Retr Tone "Reward - Platform"
t2_col.pref_iti  = t2_col.b + 3; % col P  - Train/Retr ITI  "Reward - Platform"

row_cursor = 1;
gap_rows = 2;
last_row_overall = 0;

% SV, July 24, 2026: I added
% (no v4 equivalent - v4 had no charts. Chart-feeder ("staging") data lives far to the right
% of the visible tables, cols T (Platform-v-Reward chart) and AD (Tone-v-ITI chart), on its
% own independent row cursor so it can never collide with the visible tables regardless of
% subject count. CHART_W/CHART_H are in points; ROWS_PER_CHART approximates how many
% worksheet rows that many points of chart height will visually cover, using Excel's default
% ~15pt row height, so the next day's table doesn't start underneath a still-visible chart.)
chart_stage_col_a = 20; % col T - Platform v Reward chart data
chart_stage_col_b = 30; % col AD - Tone v ITI chart data
% SV, September 8, 2026: I added these two - Reward Preference chart feeders.
chart_stage_col_c = 40; % Reward Preference (Tone) chart data
chart_stage_col_d = 50; % Reward Preference (ITI) chart data
chart_stage_row = 1;
CHART_W = 380;
CHART_H = 260;
ROWS_PER_CHART = ceil(CHART_H / 15);
chart_gap_pt = 20;
%

for d = 1:numel(days)
    day = days(d);
    day_rows = br([br.Day] == day);
    sham_rows = day_rows([day_rows.Group] == "sham");
    [~, si] = sort([sham_rows.SubjectNum]); sham_rows = sham_rows(si);
    tms_rows = day_rows([day_rows.Group] == "tms");
    [~, ti] = sort([tms_rows.SubjectNum]); tms_rows = tms_rows(ti);

    header_row = row_cursor;
    data_start = row_cursor + 1;

    % SV, September 8, 2026: I added this whole Habituation branch - same fix
    % as write_zone_visits_compared_tab's identical branch (see its
    % changelog): the tone never actually played on a Hab day, so the
    % Tone/ITI split both tables below are built around doesn't mean
    % anything there. Hab days get ONE simple Platform-vs-Reward table on
    % the merged (tone+ITI combined) proportions instead (PlatMerged_v/
    % RewMerged_v, added to bin_rows for exactly this), and skip Table 2
    % (Tone v ITI) entirely, since there is no Tone/ITI distinction to
    % compare. Train/Retr days fall through to the existing two-table,
    % two-chart logic below unchanged.
    if startsWith(day, 'Hab', 'IgnoreCase', true)
        set_header_cell(Sheet, t1_col.subj, header_row, 'Subject');
        set_header_cell(Sheet, t1_col.a, header_row, 'Platform');
        set_header_cell(Sheet, t1_col.b, header_row, 'Reward');
        set_header_cell(Sheet, t1_col.pref, header_row, 'Reward - Platform');

        t1_blocks_hab = struct('group', {}, 'first_subj_row', {}, 'last_subj_row', {}, 'mean_row', {});
        r = data_start;
        for gi = ["sham", "tms"]
            if gi == "sham", grows = sham_rows; else, grows = tms_rows; end
            if isempty(grows), continue; end
            first_subj_row = r;
            for k = 1:numel(grows)
                subj = grows(k);
                Sheet.Range(sprintf('%s%d', col2letter(t1_col.subj), r)).Value2 = subj.SubjectLabel;
                write_value_cell(Sheet.Range(sprintf('%s%d', col2letter(t1_col.a), r)), subj.PlatMerged_v);
                write_value_cell(Sheet.Range(sprintf('%s%d', col2letter(t1_col.b), r)), subj.RewMerged_v);
                write_value_cell(Sheet.Range(sprintf('%s%d', col2letter(t1_col.pref), r)), subj.RewMerged_v - subj.PlatMerged_v);
                r = r + 1;
            end
            last_subj_row = r - 1;
            mean_row = r;
            lblCell = Sheet.Range(sprintf('%s%d', col2letter(t1_col.subj), mean_row));
            lblCell.Value2 = sprintf('%s_mean', char(gi));
            lblCell.Font.Bold = true;
            for cc = [t1_col.a, t1_col.b, t1_col.pref]
                cletter = col2letter(cc);
                cellRange = Sheet.Range(sprintf('%s%d', cletter, mean_row));
                if cc == t1_col.a
                    snapshot = mean([grows.PlatMerged_v], 'omitnan');
                elseif cc == t1_col.b
                    snapshot = mean([grows.RewMerged_v], 'omitnan');
                else
                    snapshot = mean([grows.RewMerged_v] - [grows.PlatMerged_v], 'omitnan');
                end
                formula_str = sprintf('=AVERAGE(%s%d:%s%d)', cletter, first_subj_row, cletter, last_subj_row);
                write_formula_cell(cellRange, formula_str, snapshot);
                cellRange.Font.Bold = true;
            end
            r = r + 1;
            apply_group_gradient_cf(Sheet, t1_col.a, t1_col.b, first_subj_row, mean_row, gi, zero_font_bgr);
            merge_label_cell(Sheet, t1_col.group, first_subj_row, mean_row, group_label(gi), gi);
            t1_blocks_hab(end+1) = struct('group', gi, 'first_subj_row', first_subj_row, ...
                'last_subj_row', last_subj_row, 'mean_row', mean_row); %#ok<AGROW>
        end
        day_block_end = r - 1;
        if day_block_end >= data_start
            merge_label_cell(Sheet, t1_col.day, data_start, day_block_end, char(day), "neutral");
        end
        last_row_overall = max(last_row_overall, day_block_end);

        % No stats/recs on the Platform-v-Reward bar chart itself - matches
        % every other purely-descriptive Habituation summary chart in this
        % workbook - but the Reward Preference chart beside it DOES get an
        % unpaired Sham-vs-TMS stat, per SV's reference image.
        chart_anchor_row = day_block_end + 2;
        anchorA = Sheet.Range(sprintf('%s%d', col2letter(t1_col.day), chart_anchor_row));
        coHab = build_summary_bar_chart(Sheet, t1_blocks_hab, ["Platform", "Reward"], [t1_col.a, t1_col.b], ...
            sprintf('%s: Platform v Reward (%s)', char(day), range_label), 'Prop. Time in Zone', ...
            'proportion', '0.000', anchorA.Left, anchorA.Top, CHART_W, CHART_H, chart_stage_col_a, chart_stage_row);

        % SV, September 8, 2026: I added this Reward Preference chart - same
        % design as write_zone_visits_compared_tab's identical addition (see
        % its changelog): one dot-per-subject + mean+/-SEM bar of (Reward -
        % Platform), Sham vs TMS, dashed zero line, unpaired significance
        % star. Habituation only needs ONE (no Tone/ITI split to duplicate
        % it across); Train/Retr gets two further down.
        pref_left = anchorA.Left;
        if ~isempty(coHab)
            pref_left = coHab.Left + CHART_W + chart_gap_pt;
        end
        pref_sham = [sham_rows.RewMerged_v] - [sham_rows.PlatMerged_v];
        pref_tms  = [tms_rows.RewMerged_v]  - [tms_rows.PlatMerged_v];
        [pref_rec, pref_star, pref_ymax] = run_unpaired_comparison(pref_sham, pref_tms, ...
            sprintf('Sham vs TMS: Reward - Platform (%s)', range_label), sheet_name, char(day), 'Reward Preference');
        recs = [recs, pref_rec]; %#ok<AGROW>
        build_summary_bar_chart(Sheet, t1_blocks_hab, "Preference", t1_col.pref, ...
            sprintf('%s: Reward Preference (%s)', char(day), range_label), 'Reward - Platform (prop. time)', ...
            'signed', '0.000', pref_left, anchorA.Top, CHART_W, CHART_H, chart_stage_col_c, chart_stage_row, ...
            {pref_star}, pref_ymax);

        n_subj_this_day = numel(day_rows);
        chart_stage_row = chart_stage_row + 5 + max(n_subj_this_day, 1) + gap_rows;
        row_cursor = max(day_block_end + 1 + gap_rows, chart_anchor_row + ROWS_PER_CHART + gap_rows);
        continue
    end

    % --- Table 1: Platform v Reward ---
    set_header_cell(Sheet, t1_col.subj, header_row, 'Subject');
    set_header_cell(Sheet, t1_col.a, header_row, sprintf('Tones %s', range_label));
    set_header_cell(Sheet, t1_col.b, header_row, sprintf('ITIs %s', range_label));

    % SV, July 24, 2026: I added
    % (no v4 equivalent - captures each Sham/TMS x Platform/Reward row-block's [start end]
    % row range as it's written, so build_paired_barline_chart can point chart mean/SEM/line
    % formulas straight at these exact table rows afterward)
    t1_blocks = struct();
    %
    r = data_start;
    for gi = ["sham", "tms"]
        if gi == "sham", grows = sham_rows; else, grows = tms_rows; end
        if isempty(grows), continue; end
        group_start = r;
        for pr = ["Platform", "Reward"]
            pr_start = r;
            for k = 1:numel(grows)
                subj = grows(k);
                Sheet.Range(sprintf('%s%d', col2letter(t1_col.subj), r)).Value2 = subj.SubjectLabel;
                % SV, July 24, 2026: I changed
                % if pr == "Platform"
                %     a_val = subj.PlatTone; b_val = subj.PlatITI;
                % else
                %     a_val = subj.RewTone; b_val = subj.RewITI;
                % end
                % write_value_cell(Sheet.Range(sprintf('%s%d', col2letter(t1_col.a), r)), a_val, gi, zero_font_bgr);
                % write_value_cell(Sheet.Range(sprintf('%s%d', col2letter(t1_col.b), r)), b_val, gi, zero_font_bgr);
                % to this (write a live formula + its one-time snapshot value for number-format
                % purposes, instead of just a literal):
                if pr == "Platform"
                    a_f = subj.PlatTone_f; a_v = subj.PlatTone_v;
                    b_f = subj.PlatITI_f;  b_v = subj.PlatITI_v;
                else
                    a_f = subj.RewTone_f; a_v = subj.RewTone_v;
                    b_f = subj.RewITI_f;  b_v = subj.RewITI_v;
                end
                write_formula_cell(Sheet.Range(sprintf('%s%d', col2letter(t1_col.a), r)), a_f, a_v);
                write_formula_cell(Sheet.Range(sprintf('%s%d', col2letter(t1_col.b), r)), b_f, b_v);
                %
                r = r + 1;
            end
            merge_label_cell(Sheet, t1_col.sub, pr_start, r-1, char(pr), gi);
            t1_blocks.(char(gi)).(char(pr)) = [pr_start, r-1]; % SV, July 24, 2026: I added
        end
        % SV, July 24, 2026: I added
        % (no v4 equivalent - fill used to be baked in per-cell above; now one live Color
        % Scale + zero-font rule per contiguous Sham/TMS block, covering both data columns)
        apply_group_gradient_cf(Sheet, t1_col.a, t1_col.b, group_start, r-1, gi, zero_font_bgr);
        %
        merge_label_cell(Sheet, t1_col.group, group_start, r-1, group_label(gi), gi);
    end
    t1_end_row = r - 1;
    if t1_end_row >= data_start
        merge_label_cell(Sheet, t1_col.day, data_start, t1_end_row, char(day), "neutral");
    end

    % --- Table 2: Tone v ITI ---
    set_header_cell(Sheet, t2_col.subj, header_row, 'Subject');
    set_header_cell(Sheet, t2_col.a, header_row, 'Platform');
    set_header_cell(Sheet, t2_col.b, header_row, 'Reward');
    % SV, September 8, 2026: I added these two headers - live "Reward -
    % Platform" columns feeding the new Reward Preference charts below.
    set_header_cell(Sheet, t2_col.pref_tone, header_row, 'Reward - Platform (Tone)');
    set_header_cell(Sheet, t2_col.pref_iti, header_row, 'Reward - Platform (ITI)');

    % SV, July 24, 2026: I added (same reasoning as t1_blocks above)
    t2_blocks = struct();
    %
    r2 = data_start;
    for gi = ["sham", "tms"]
        if gi == "sham", grows = sham_rows; else, grows = tms_rows; end
        if isempty(grows), continue; end
        group_start2 = r2;
        for ti_grp = [string(sprintf('Tone %s', range_label)), string(sprintf('ITI %s', range_label))]
            ti_start = r2;
            if startsWith(ti_grp, 'Tone'), pref_col = t2_col.pref_tone; else, pref_col = t2_col.pref_iti; end
            for k = 1:numel(grows)
                subj = grows(k);
                Sheet.Range(sprintf('%s%d', col2letter(t2_col.subj), r2)).Value2 = subj.SubjectLabel;
                % SV, July 24, 2026: I changed
                % if startsWith(ti_grp, 'Tone')
                %     a_val = subj.PlatTone; b_val = subj.RewTone;
                % else
                %     a_val = subj.PlatITI; b_val = subj.RewITI;
                % end
                % write_value_cell(Sheet.Range(sprintf('%s%d', col2letter(t2_col.a), r2)), a_val, gi, zero_font_bgr);
                % write_value_cell(Sheet.Range(sprintf('%s%d', col2letter(t2_col.b), r2)), b_val, gi, zero_font_bgr);
                % to this (same live-formula approach as Table 1 - this table's cells point
                % straight back to "all tones" too, not to Table 1's cells, per SV's choice):
                if startsWith(ti_grp, 'Tone')
                    a_f = subj.PlatTone_f; a_v = subj.PlatTone_v;
                    b_f = subj.RewTone_f;  b_v = subj.RewTone_v;
                else
                    a_f = subj.PlatITI_f; a_v = subj.PlatITI_v;
                    b_f = subj.RewITI_f;  b_v = subj.RewITI_v;
                end
                write_formula_cell(Sheet.Range(sprintf('%s%d', col2letter(t2_col.a), r2)), a_f, a_v);
                write_formula_cell(Sheet.Range(sprintf('%s%d', col2letter(t2_col.b), r2)), b_f, b_v);
                pref_f = sprintf('=%s%d-%s%d', col2letter(t2_col.b), r2, col2letter(t2_col.a), r2);
                write_formula_cell(Sheet.Range(sprintf('%s%d', col2letter(pref_col), r2)), pref_f, b_v - a_v);
                %
                r2 = r2 + 1;
            end
            merge_label_cell(Sheet, t2_col.sub, ti_start, r2-1, char(ti_grp), gi);
            % SV, July 24, 2026: I added - key by "Tone"/"ITI" (not the full range-suffixed
            % label text) so build_paired_barline_chart can look these blocks up generically
            if startsWith(ti_grp, 'Tone')
                t2_blocks.(char(gi)).Tone = [ti_start, r2-1];
            else
                t2_blocks.(char(gi)).ITI = [ti_start, r2-1];
            end
            %
        end
        % SV, July 24, 2026: I added (same reasoning as Table 1's CF block above)
        apply_group_gradient_cf(Sheet, t2_col.a, t2_col.b, group_start2, r2-1, gi, zero_font_bgr);
        %
        merge_label_cell(Sheet, t2_col.group, group_start2, r2-1, group_label(gi), gi);
    end
    t2_end_row = r2 - 1;
    if t2_end_row >= data_start
        merge_label_cell(Sheet, t2_col.day, data_start, t2_end_row, char(day), "neutral");
    end

    day_block_end = max(t1_end_row, t2_end_row);
    last_row_overall = max(last_row_overall, day_block_end);

    % SV, July 24, 2026: I added
    % (no v4 equivalent - one Prism-style paired bar+line chart per table, embedded directly
    % below that table, matching the reference image SV supplied 2026-07-24. Both charts use
    % the same subject set/day, so they share one chart_stage_row advance below.)
    %
    % SV, July 24, 2026: I changed
    % chart_anchor_row = day_block_end + 2;
    % build_paired_barline_chart(Sheet, t1_blocks, t1_col.a, t1_col.b, "Platform", "Reward", ...
    %     sprintf('Tones %s', range_label), sprintf('ITIs %s', range_label), 'Platform', 'Reward', ...
    %     sprintf('%s (tones %s): Platform v Reward', char(day), range_label), 'Prop. Time in Zone', ...
    %     sprintf('%s%d', col2letter(t1_col.day), chart_anchor_row), CHART_W, CHART_H, ...
    %     chart_stage_col_a, chart_stage_row);
    % build_paired_barline_chart(Sheet, t2_blocks, t2_col.a, t2_col.b, "Tone", "ITI", ...
    %     'Platform', 'Reward', sprintf('Tone %s', range_label), sprintf('ITI %s', range_label), ...
    %     sprintf('%s (tones %s): Tone v ITI', char(day), range_label), 'Prop. Time in Zone', ...
    %     sprintf('%s%d', col2letter(t2_col.day), chart_anchor_row), CHART_W, CHART_H, ...
    %     chart_stage_col_b, chart_stage_row);
    % to this (per SV's 2026-07-24 review of the first test run: (a) anchoring both charts by
    % cell column let Chart B's fixed pixel width overlap Chart A whenever the actual column
    % widths between them summed to less than CHART_W - now Chart B is anchored at Chart A's
    % *actual* right edge (coA.Left + CHART_W + gap) in points, which can never overlap
    % regardless of column widths; (b) shortened the chart titles to "<Day>: Platform v
    % Reward (<range>)"):
    % SV, August 23, 2026: I added - same four-comparison stats as the visits
    % tab, but with transform 'none': these are proportions of time, already
    % bounded 0-1 and far less skewed than the raw visit counts, so log1p
    % would be inappropriate here.
    p1 = struct('label', {}, 'a', {}, 'b', {});
    for oi = ["Tones", "ITIs"]
        for gi = ["sham", "tms"]
            if gi == "sham", gr = sham_rows; else, gr = tms_rows; end
            if oi == "Tones"
                A = [gr.PlatTone_v]; B = [gr.RewTone_v];
            else
                A = [gr.PlatITI_v];  B = [gr.RewITI_v];
            end
            p1(end+1) = struct('label', sprintf('%s / %s %s: Platform vs Reward', ...
                group_label(gi), oi, range_label), 'a', A, 'b', B); %#ok<AGROW>
        end
    end
    [rec1, star1, ymax1] = run_chart_comparisons(p1, 'none', sheet_name, char(day), 'Platform v Reward');

    p2 = struct('label', {}, 'a', {}, 'b', {});
    for oi = ["Platform", "Reward"]
        for gi = ["sham", "tms"]
            if gi == "sham", gr = sham_rows; else, gr = tms_rows; end
            if oi == "Platform"
                A = [gr.PlatTone_v]; B = [gr.PlatITI_v];
            else
                A = [gr.RewTone_v];  B = [gr.RewITI_v];
            end
            p2(end+1) = struct('label', sprintf('%s / %s %s: Tone vs ITI', ...
                group_label(gi), oi, range_label), 'a', A, 'b', B); %#ok<AGROW>
        end
    end
    [rec2, star2, ymax2] = run_chart_comparisons(p2, 'none', sheet_name, char(day), 'Tone v ITI');
    recs = [recs, rec1, rec2]; %#ok<AGROW>
    %

    % SV, September 8, 2026: I added these two unpaired Sham-vs-TMS Reward
    % Preference comparisons (Tone-based and ITI-based), same design as
    % write_zone_visits_compared_tab's identical addition - see its
    % changelog and run_unpaired_comparison's own changelog for why this is
    % a different (unpaired) test from every other comparison on this tab.
    pref_tone_sham = [sham_rows.RewTone_v] - [sham_rows.PlatTone_v];
    pref_tone_tms  = [tms_rows.RewTone_v]  - [tms_rows.PlatTone_v];
    [pref_rec_tone, pref_star_tone, pref_ymax_tone] = run_unpaired_comparison(pref_tone_sham, pref_tone_tms, ...
        sprintf('Sham vs TMS: Reward - Platform (Tone %s)', range_label), sheet_name, char(day), 'Reward Preference (Tone)');
    pref_iti_sham = [sham_rows.RewITI_v] - [sham_rows.PlatITI_v];
    pref_iti_tms  = [tms_rows.RewITI_v]  - [tms_rows.PlatITI_v];
    [pref_rec_iti, pref_star_iti, pref_ymax_iti] = run_unpaired_comparison(pref_iti_sham, pref_iti_tms, ...
        sprintf('Sham vs TMS: Reward - Platform (ITI %s)', range_label), sheet_name, char(day), 'Reward Preference (ITI)');
    recs = [recs, pref_rec_tone, pref_rec_iti]; %#ok<AGROW>
    %

    chart_anchor_row = day_block_end + 2;
    anchorA = Sheet.Range(sprintf('%s%d', col2letter(t1_col.day), chart_anchor_row));
    coA = build_paired_barline_chart(Sheet, t1_blocks, t1_col.a, t1_col.b, "Platform", "Reward", ...
        sprintf('Tones %s', range_label), sprintf('ITIs %s', range_label), 'Platform', 'Reward', ...
        sprintf('%s: Platform v Reward (%s)', char(day), range_label), 'Prop. Time in Zone', ...
        anchorA.Left, anchorA.Top, CHART_W, CHART_H, chart_stage_col_a, chart_stage_row, ...
        'proportion', star1, ymax1);
    coB = build_paired_barline_chart(Sheet, t2_blocks, t2_col.a, t2_col.b, "Tone", "ITI", ...
        'Platform', 'Reward', sprintf('Tone %s', range_label), sprintf('ITI %s', range_label), ...
        sprintf('%s: Tone v ITI (%s)', char(day), range_label), 'Prop. Time in Zone', ...
        coA.Left + CHART_W + chart_gap_pt, anchorA.Top, CHART_W, CHART_H, ...
        chart_stage_col_b, chart_stage_row, 'proportion', star2, ymax2);

    % SV, September 8, 2026: I added these two Reward Preference charts,
    % placed right after the Tone v ITI chart above, per SV's reference
    % image - same reuse-t2_blocks-row-spans design as
    % write_zone_visits_compared_tab's identical addition.
    pref_blocks_tone = struct('group', {}, 'first_subj_row', {}, 'last_subj_row', {}, 'mean_row', {});
    pref_blocks_iti  = struct('group', {}, 'first_subj_row', {}, 'last_subj_row', {}, 'mean_row', {});
    for gi = ["sham", "tms"]
        gc = char(gi);
        if isfield(t2_blocks, gc) && isfield(t2_blocks.(gc), 'Tone')
            span = t2_blocks.(gc).Tone;
            pref_blocks_tone(end+1) = struct('group', gi, 'first_subj_row', span(1), 'last_subj_row', span(2), 'mean_row', NaN); %#ok<AGROW>
        end
        if isfield(t2_blocks, gc) && isfield(t2_blocks.(gc), 'ITI')
            span = t2_blocks.(gc).ITI;
            pref_blocks_iti(end+1) = struct('group', gi, 'first_subj_row', span(1), 'last_subj_row', span(2), 'mean_row', NaN); %#ok<AGROW>
        end
    end
    pref_c_left = coB.Left + CHART_W + chart_gap_pt;
    coC = build_summary_bar_chart(Sheet, pref_blocks_tone, "Preference", t2_col.pref_tone, ...
        sprintf('%s: Reward Preference (Tone, %s)', char(day), range_label), 'Reward - Platform (prop. time)', ...
        'signed', '0.000', pref_c_left, anchorA.Top, CHART_W, CHART_H, ...
        chart_stage_col_c, chart_stage_row, {pref_star_tone}, pref_ymax_tone);
    pref_d_left = pref_c_left + CHART_W + chart_gap_pt;
    if ~isempty(coC)
        pref_d_left = coC.Left + CHART_W + chart_gap_pt;
    end
    build_summary_bar_chart(Sheet, pref_blocks_iti, "Preference", t2_col.pref_iti, ...
        sprintf('%s: Reward Preference (ITI, %s)', char(day), range_label), 'Reward - Platform (prop. time)', ...
        'signed', '0.000', pref_d_left, anchorA.Top, CHART_W, CHART_H, ...
        chart_stage_col_d, chart_stage_row, {pref_star_iti}, pref_ymax_iti);

    n_subj_this_day = numel(day_rows);
    chart_stage_row = chart_stage_row + 5 + max(n_subj_this_day, 1) + gap_rows;
    %

    row_cursor = max(day_block_end + 1 + gap_rows, chart_anchor_row + ROWS_PER_CHART + gap_rows);
end

% SV, September 3, 2026: I added, THEN (September 8, 2026) REMOVED - the
% Platform/Reward "proportion of time in zone" TREND charts used to live
% here, gated to build only on the "1-9" tab (see this changelog's own prior
% entries for that history). Per SV's screenshot, that in-tab placement (at
% a large fixed column offset, trend_metric_col=[45,195], to keep Reward's
% and Platform's blocks from overlapping) just relocated the same "charts
% parked far from anything else on screen" problem the zone_visits split
% already fixed once. This whole section moved out into its own function/
% tab - write_zone_time_timecourse_tab, called once (not per range) from
% write_formatted_xlsx - where Reward's and Platform's 3 blocks each now
% stack at the same column instead of sitting side by side at a fixed
% offset. See that function's own changelog.
%

% --- Column widths ---
% SV, July 24, 2026: I changed
% Sheet.Range(sprintf('%s1:%s1', col2letter(t1_col.a), col2letter(t1_col.b))).EntireColumn.ColumnWidth = 6;
% Sheet.Range(sprintf('%s1:%s1', col2letter(t2_col.a), col2letter(t2_col.b))).EntireColumn.ColumnWidth = 6;
% (fixed width 6 was sized to fit the "0.000" data cells, but that truncated the longer
% header text - "Tones 1-6" / "ITIs 1-6" / "Platform" / "Reward" - to this (AutoFit sizes to
% the widest content in the column, i.e. the header, same pattern already used below for the
% Day/Group/Sub/Subject columns):
% SV, September 8, 2026: I widened both AutoFit ranges through the new
% pref/pref_iti columns, and the hidden-columns range through
% chart_stage_col_d+7 - the Reward Preference columns/chart feeders added
% this same day.
Sheet.Range(sprintf('%s1:%s1', col2letter(t1_col.a), col2letter(t1_col.pref))).EntireColumn.AutoFit;
Sheet.Range(sprintf('%s1:%s1', col2letter(t2_col.a), col2letter(t2_col.pref_iti))).EntireColumn.AutoFit;
%
if last_row_overall >= 1
    Sheet.Range(sprintf('%s1:%s%d', col2letter(t1_col.day), col2letter(t1_col.subj), last_row_overall)).EntireColumn.AutoFit;
    Sheet.Range(sprintf('%s1:%s%d', col2letter(t2_col.day), col2letter(t2_col.subj), last_row_overall)).EntireColumn.AutoFit;
end

% SV, July 24, 2026: I added
% (no v4 equivalent - per SV's 2026-07-24 review: the chart-feeder columns (cols T onward)
% are formula-linked data the charts plot from - every mean/SEM/subject-line number here
% pulls straight off this tab's own visible tables via a same-sheet formula (e.g. "=E5"),
% same as those tables pull from "all tones" - but they're not meant to be read directly, so
% hide them instead of deleting them (deleting would break every chart's data reference).
% build_paired_barline_chart already sets each chart's PlotVisibleOnly=false so hiding these
% columns doesn't blank the charts out. SV, to inspect/verify them later: Home -> Format ->
% Hide & Unhide -> Unhide Columns after selecting columns T:BB.)
Sheet.Range(sprintf('%s1:%s1', col2letter(chart_stage_col_a), col2letter(chart_stage_col_d + 7))).EntireColumn.Hidden = true;
%
end

%%
% SV, September 8, 2026: I added this whole function - the Platform/Reward
% "proportion of time in zone" trend charts (Habituation merged / Train-Retr
% ITI / Train-Retr Tone, each a Timecourse+Summary pair - same design as
% write_locomotion_tab and write_zone_visits_timecourse_tab) PULLED OUT of
% write_binned_tab (see that function's own changelog for why: sharing a
% sheet with the "1-9" tab's day-block tables, even at a large column
% offset, still parked these charts far from anything else on screen).
% Called once from write_formatted_xlsx, not once per tone-range - there is
% only one of these regardless of how many binned_tones_*/zone_time_* tabs
% exist, same as zone_visits_timecourse is one tab serving zone_visits_
% compared. Reward's and Platform's 3 blocks stack at the same column
% (trend_start_col=1) instead of sitting side by side at a fixed offset -
% same fix already applied to write_locomotion_tab's Distance/Rate columns
% and write_zone_visits_timecourse_tab's Reward/Platform columns.
function write_zone_time_timecourse_tab(Workbook, sheet_name, rows, zero_font_bgr, ...
    trend_bin_ranges, trend_bin_labels)

last_sheet = Workbook.Sheets.Item(Workbook.Sheets.Count);
Sheet = Workbook.Sheets.Add;
Sheet.Move([], last_sheet);
Sheet.Name = sheet_name;

all_days_bt = strings(1, numel(rows));
for ii = 1:numel(rows)
    all_days_bt(ii) = day_from_condition(rows(ii).Condition);
end
is_hab_day_bt = startsWith(all_days_bt, 'Hab', 'IgnoreCase', true);
hab_days_bt = unique(all_days_bt(is_hab_day_bt), 'stable');
real_days_bt = unique(all_days_bt(~is_hab_day_bt), 'stable');

trend_start_col = 1;
trend_row = 1;
trend_stage_base = 400;
for metric_name = ["Reward", "Platform"]
    if metric_name == "Reward"
        val_hab  = @(k,br) bin_mean(rows(k).Merged_PerTimeInROI, br);
        val_tone = @(k,br) bin_mean(rows(k).CSp_reward_time, br);
        val_iti  = @(k,br) bin_mean(rows(k).ITI_reward_time, br);
    else
        val_hab  = @(k,br) bin_mean(rows(k).Plat_Merged_PerTimeInROI, br);
        val_tone = @(k,br) bin_mean(rows(k).CSp_plat_time, br);
        val_iti  = @(k,br) bin_mean(rows(k).ITI_plat_time, br);
    end
    m = char(metric_name);

    trend_row = write_simple_trend_table_and_chart(Sheet, trend_row, trend_start_col, trend_stage_base, zero_font_bgr, ...
        rows, hab_days_bt, trend_bin_ranges, trend_bin_labels, val_hab, ...
        sprintf('Prop. Time in %s: Habituation (tone+ITI combined)', m), 'proportion', ...
        sprintf('Prop. Time in %s: Habituation timecourse', m), sprintf('Prop. time in %s', lower(m)), 'proportion', '0.0', ...
        sprintf('Prop. Time in %s: Habituation summary', m));
    trend_stage_base = trend_stage_base + 150;

    trend_row = write_simple_trend_table_and_chart(Sheet, trend_row, trend_start_col, trend_stage_base, zero_font_bgr, ...
        rows, real_days_bt, trend_bin_ranges, trend_bin_labels, val_iti, ...
        sprintf('Prop. Time in %s: Train/Retr (ITI)', m), 'proportion', ...
        sprintf('Prop. Time in %s: Train and Retr timecourse (ITI)', m), sprintf('Prop. time in %s', lower(m)), 'proportion', '0.0', ...
        sprintf('Prop. Time in %s: Train and Retr summary (ITI)', m));
    trend_stage_base = trend_stage_base + 150;

    trend_row = write_simple_trend_table_and_chart(Sheet, trend_row, trend_start_col, trend_stage_base, zero_font_bgr, ...
        rows, real_days_bt, trend_bin_ranges, trend_bin_labels, val_tone, ...
        sprintf('Prop. Time in %s: Train/Retr (Tone)', m), 'proportion', ...
        sprintf('Prop. Time in %s: Train and Retr timecourse (Tone)', m), sprintf('Prop. time in %s', lower(m)), 'proportion', '0.0', ...
        sprintf('Prop. Time in %s: Train and Retr summary (Tone)', m));
    trend_stage_base = trend_stage_base + 150;
end
end

%%
% SV, September 3, 2026: I REWROTE this whole function after SV's review of
% the first version. Three changes:
%  1) X-AXIS DATE BUG. The chart's category axis showed "3-Jan"/"6-Apr"/
%     "9-Jul"/"9-Jan" instead of "1-3"/"4-6"/"7-9"/"1-9". Root cause: Excel
%     auto-detects a bare day-month-shaped string like "1-3" and silently
%     reinterprets it as a date on any cell that isn't explicitly formatted
%     as text - the string written was correct, Excel just chose to DISPLAY
%     it as a date. Fixed generally in build_success_combined_chart (forces
%     NumberFormat='@' on its own category-label cells now - see that
%     function's changelog) and again here on this tab's own visible header
%     cells, below.
%  2) TONE/ITI SPLIT REMOVED. The tone never played during Habituation (see
%     the v8 changelog at the top of this file), so splitting "tone window"
%     from "ITI window" imposed a distinction with no behavioural meaning.
%     Per SV: "group tone #1, the iti immediately after it ... through
%     tone/iti#3" - bucket by the COMBINED trial cycle (tone i + the ITI
%     immediately following it, as one window), not tone/ITI separately.
%     That combined-cycle data is exactly Analysis.Merged, which
%     BehDEPOT_Analysis_SVv5.m already computes for habituation sessions
%     (epoch i = tone i's window through the end of the ITI following it) -
%     see Merged_PerTimeInROI/Merged_Visits/Merged_Dist/Merged_Dur on "rows".
%     NOTE: needs a session analyzed with BehDEPOT_Analysis_SVv5.m or later -
%     a Hab session analyzed with an earlier version has no Analysis.Merged,
%     so its cells here come back blank until it's re-run.
%  3) ONE CHART PER METRIC, spanning HabD1->HabD2->HabD3 as day-blocks with a
%     break between them (build_success_combined_chart's existing day-break
%     machinery), instead of a separate mini-chart per Hab day - matching
%     how every other chart in this workbook shows a full time-course rather
%     than isolated day snapshots (directly addressing "I am missing trends
%     in the data by just summarizing them in this way", SV, about the
%     binned_tones tabs - the same fix applies here for the same reason).
%     This meant restructuring the TABLE from "one row-block per Hab day" to
%     "one row-block for every subject that ran ANY Hab day, with HabD1/
%     HabD2/HabD3 as column-groups" - exactly write_successful_trials_tab's
%     layout, just keyed to a different metric per table and to
%     Analysis.Merged instead of the shock-avoidance vector.
%  4) SV, September 3, 2026 (later same day): LOCOMOTION REMOVED FROM THIS
%     TAB ENTIRELY. Per SV's hand-drawn sketch, Habituation locomotion now
%     lives in write_locomotion_tab instead (Merged-based, same as here, but
%     alongside the Train/Retr locomotion data it's naturally compared
%     against, with its own Timecourse+Summary chart pair - see that
%     function's changelog). This tab dropped from 4 tables/3 charts to 2
%     tables/2 charts; Merged_Dist/Merged_Dur are still read from "rows" (by
%     write_locomotion_tab now, not here).
%
% One tab, 2 tables side by side: rows are subjects (Sham block then TMS
% block), columns are HabD1/HabD2/HabD3 x hab_bin_ranges/hab_bin_labels bins
% (1-3/4-6/7-9/1-9 by default - the SAME bin set used everywhere else in
% this workbook, including the overlapping "1-9" whole-cycle-set aggregate -
% see the note where success_bin_ranges is built, at the top of this file,
% for why that bin is display-only).
%   A. Reward: Prop. time in zone   (Merged.PerTimeInROI)
%   B. Reward: Zone visits (count)  (Merged.Visits)
% Both are computed literals: Analysis.Merged fields aren't written to any
% visible tab, so there's no cell for a live formula to point at - same
% situation/reasoning as write_successful_trials_tab. Every table still gets
% a Sham_mean/TMS_mean row (live "=AVERAGE(this table's own subject rows)")
% and the usual live gray/red gradient conditional formatting.
%
% Charts: A and B each get one combined chart spanning HabD1->HabD2->HabD3.
function write_hab_reward_tab(Workbook, sheet_name, rows, zero_font_bgr, ...
    hab_bin_ranges, hab_bin_labels)

last_sheet = Workbook.Sheets.Item(Workbook.Sheets.Count);
Sheet = Workbook.Sheets.Add;
Sheet.Move([], last_sheet);
Sheet.Name = sheet_name;

n_bins = numel(hab_bin_ranges);
short_bin_labels = strings(1, n_bins); % "Tones 1-3" -> "1-3"
for b = 1:n_bins
    short_bin_labels(b) = strtrim(erase(hab_bin_labels(b), "Tones"));
end

% --- Flatten "rows" into (subject x Hab day) entries. Non-Hab days dropped. ---
n = numel(rows);
e_day = strings(1, n); e_group = strings(1, n);
e_subjnum = nan(1, n); e_subjlabel = strings(1, n);
keep = false(1, n);
for i = 1:n
    d = day_from_condition(rows(i).Condition);
    if ~startsWith(d, 'Hab', 'IgnoreCase', true)
        continue
    end
    [num, lbl] = parse_subject(rows(i).Subject);
    e_day(i) = d;
    e_group(i) = classify_group(rows(i).Condition);
    e_subjnum(i) = num;
    e_subjlabel(i) = string(lbl);
    keep(i) = true;
end
if ~any(keep)
    warning('hab_reward_rate tab: no habituation-day sessions found - tab left empty.');
    return
end
days = unique(e_day(keep), 'stable'); % rows are pre-sorted chronologically upstream
n_days = numel(days);

% --- Subject list, Sham block then TMS block, numerically sorted within
% group - same convention write_successful_trials_tab uses.
subj_nums = []; subj_labels = strings(0); subj_groups = strings(0);
for g = ["sham", "tms"]
    idx = find(keep & e_group == g);
    [~, order] = sort(e_subjnum(idx));
    for k = idx(order)
        if ~ismember(e_subjnum(k), subj_nums)
            subj_nums(end+1) = e_subjnum(k); %#ok<AGROW>
            subj_labels(end+1) = e_subjlabel(k); %#ok<AGROW>
            subj_groups(end+1) = g; %#ok<AGROW>
        end
    end
end

% --- Column layout: 2 tables side by side, each Group|Subject|(n_days*n_bins)
% data cols, one gap column before the next table.
table_defs = struct( ...
    'title',      {'Reward: Prop. time in zone', 'Reward: Zone visits (count)'}, ...
    'is_integer', {false, true}, ...
    'scale_mode', {'proportion', 'auto'});
n_tab = numel(table_defs);
c = 1;
for t = 1:n_tab
    table_defs(t).group_col = c;
    table_defs(t).subj_col = c + 1;
    table_defs(t).data_col0 = c + 2;
    c = c + 2 + n_days*n_bins + 1; % +1 gap column before the next table
end
last_col = c - 2; % undo the trailing gap after the last table

% --- Headers ---
tab_title_row   = 1; % overall tab title, spans everything
table_title_row = 2; % per-table title
header_row2     = 3; % Group/Subject start, HabDay bracket
header_row3     = 4; % Group/Subject end, bin labels
data_start_row  = 5;

overall_hdr = Sheet.Range(sprintf('%s%d:%s%d', col2letter(1), tab_title_row, col2letter(last_col), tab_title_row));
overall_hdr.Merge; overall_hdr.Value2 = 'Habituation Reward Rate (merged tone+ITI trial cycles)';
overall_hdr.Font.Bold = true; overall_hdr.Font.Size = 12; overall_hdr.HorizontalAlignment = -4108;

day_col_start = cell(1, n_tab); % per table: [first data col of HabD1, HabD2, ...]
for t = 1:n_tab
    td = table_defs(t);

    grpHeader = Sheet.Range(sprintf('%s%d:%s%d', col2letter(td.group_col), header_row2, col2letter(td.group_col), header_row3));
    grpHeader.Merge; grpHeader.Value2 = 'Group';
    grpHeader.Font.Bold = true; grpHeader.HorizontalAlignment = -4108; grpHeader.VerticalAlignment = -4108;

    subjHeader = Sheet.Range(sprintf('%s%d:%s%d', col2letter(td.subj_col), header_row2, col2letter(td.subj_col), header_row3));
    subjHeader.Merge; subjHeader.Value2 = 'Subject';
    subjHeader.Font.Bold = true; subjHeader.HorizontalAlignment = -4108; subjHeader.VerticalAlignment = -4108;

    tblHeader = Sheet.Range(sprintf('%s%d:%s%d', col2letter(td.group_col), table_title_row, col2letter(td.data_col0+n_days*n_bins-1), table_title_row));
    tblHeader.Merge; tblHeader.Value2 = td.title;
    tblHeader.Font.Bold = true; tblHeader.HorizontalAlignment = -4108;

    cols_this_tab = zeros(1, n_days);
    for dcol = 1:n_days
        c0 = td.data_col0 + (dcol-1)*n_bins;
        cols_this_tab(dcol) = c0;
        dayHeader = Sheet.Range(sprintf('%s%d:%s%d', col2letter(c0), header_row2, col2letter(c0+n_bins-1), header_row2));
        dayHeader.Merge; dayHeader.Value2 = char(days(dcol));
        dayHeader.Font.Bold = true; dayHeader.HorizontalAlignment = -4108;
        for b = 1:n_bins
            % NumberFormat='@' - the date-autoconversion guard, see this
            % function's own changelog above.
            bc = Sheet.Range(sprintf('%s%d', col2letter(c0+b-1), header_row3));
            bc.NumberFormat = '@';
            bc.Value2 = char(short_bin_labels(b));
            bc.HorizontalAlignment = -4108;
        end
    end
    day_col_start{t} = cols_this_tab;
end

% --- Data rows, one Sham/TMS block at a time (same block-then-mean-row
% pattern write_successful_trials_tab uses) so the group label/CF/chart row
% spans are exact. Per-subject values are also collected into valmats so the
% mean row's snapshot (number-format only - the cell itself is always a live
% formula) can be computed directly from the numbers just written.
blocks = struct('group', {}, 'first_subj_row', {}, 'last_subj_row', {}, 'mean_row', {});
r = data_start_row;
for g = ["sham", "tms"]
    gidx = find(subj_groups == g);
    if isempty(gidx)
        continue
    end
    first_subj_row = r;
    valmats = cell(1, n_tab);
    for t = 1:n_tab
        valmats{t} = nan(numel(gidx), n_days*n_bins);
    end
    for kk = 1:numel(gidx)
        s = gidx(kk);
        row_r = first_subj_row + kk - 1;
        for t = 1:n_tab
            Sheet.Range(sprintf('%s%d', col2letter(table_defs(t).subj_col), row_r)).Value2 = char(subj_labels(s));
        end
        for dcol = 1:n_days
            % The (subject, day) session, if this subject ran that Hab day at all
            k = find(keep & e_subjnum == subj_nums(s) & e_day == days(dcol), 1);
            for b = 1:n_bins
                bin_range = hab_bin_ranges{b};
                cc = (dcol-1)*n_bins + b; % flat column index within this table's data span

                if isempty(k)
                    vA = NaN; vB = NaN; % subject didn't run this Hab day
                else
                    vA = bin_mean(rows(k).Merged_PerTimeInROI, bin_range);
                    vB = bin_sum(rows(k).Merged_Visits, bin_range);
                end
                write_value_cell(Sheet.Range(sprintf('%s%d', col2letter(day_col_start{1}(dcol)+b-1), row_r)), vA);
                write_value_cell(Sheet.Range(sprintf('%s%d', col2letter(day_col_start{2}(dcol)+b-1), row_r)), vB, true);
                valmats{1}(kk,cc) = vA; valmats{2}(kk,cc) = vB;
            end
        end
    end
    last_subj_row = row_r;
    r = last_subj_row + 1;

    % --- group mean row, one per table, live "=AVERAGE(this table's own
    % subject rows)" formula. Always non-integer-formatted (even for the
    % count table), same as write_successful_trials_tab's mean row: a mean
    % of counts is itself not generally a whole number.
    mean_row = r;
    for t = 1:n_tab
        td = table_defs(t);
        lblCell = Sheet.Range(sprintf('%s%d', col2letter(td.subj_col), mean_row));
        lblCell.Value2 = sprintf('%s_mean', char(g));
        lblCell.Font.Bold = true;
        vm = valmats{t};
        for cc = 1:(n_days*n_bins)
            dcol = ceil(cc/n_bins); b = cc - (dcol-1)*n_bins;
            cletter = col2letter(day_col_start{t}(dcol) + b - 1);
            cellRange = Sheet.Range(sprintf('%s%d', cletter, mean_row));
            snapshot = mean(vm(:,cc), 'omitnan');
            formula_str = sprintf('=AVERAGE(%s%d:%s%d)', cletter, first_subj_row, cletter, last_subj_row);
            write_formula_cell(cellRange, formula_str, snapshot);
            cellRange.Font.Bold = true;
        end
    end
    r = r + 1;

    for t = 1:n_tab
        td = table_defs(t);
        merge_label_cell(Sheet, td.group_col, first_subj_row, mean_row, group_label(g), g);
        apply_group_gradient_cf(Sheet, td.data_col0, td.data_col0+n_days*n_bins-1, first_subj_row, mean_row, g, zero_font_bgr, td.scale_mode);
    end

    bi = numel(blocks) + 1;
    blocks(bi).group = g;
    blocks(bi).first_subj_row = first_subj_row;
    blocks(bi).last_subj_row = last_subj_row;
    blocks(bi).mean_row = mean_row;
end
last_data_row = r - 1;

% --- Charts: A (time-in-zone) and B (visits), each spanning
% HabD1->HabD2->HabD3.
chart_stage_col0 = last_col + 5;
chart_stage_block_w = n_days*n_bins + n_days + 6; % headroom incl. day-break spacers
CHART_W = 420; CHART_H = 300; chart_gap_pt = 16;
chart_anchor = Sheet.Range(sprintf('A%d', last_data_row + 3));
chart_specs = struct( ...
    'tab_idx', {1, 2}, ...
    'title',   {'Habituation: reward time in zone', 'Habituation: reward zone visits'}, ...
    'y_title', {'Prop. time in reward zone', 'Reward zone visits (count)'}, ...
    'y_mode',  {'proportion', 'auto'}, ...
    'y_fmt',   {'0.0', '0'});
left = chart_anchor.Left;
for cs = 1:numel(chart_specs)
    spec = chart_specs(cs);
    t = spec.tab_idx;
    day_cols_c = cell(1, n_days);
    day_labels_c = cell(1, n_days);
    for dcol = 1:n_days
        day_cols_c{dcol} = day_col_start{t}(dcol) : (day_col_start{t}(dcol) + n_bins - 1);
        day_labels_c{dcol} = short_bin_labels;
    end
    this_stage_col = chart_stage_col0 + (cs-1)*chart_stage_block_w;
    try
        co = build_success_combined_chart(Sheet, blocks, days, day_cols_c, day_labels_c, ...
            subj_labels, subj_groups, spec.title, left, chart_anchor.Top, CHART_W, CHART_H, this_stage_col, 1, ...
            spec.y_title, spec.y_mode, spec.y_fmt);
        if ~isempty(co)
            left = co.Left + CHART_W + chart_gap_pt;
        end
    catch ME
        warning('Could not build the hab_reward_rate "%s" chart: %s', spec.title, ME.message);
    end
end

% --- Column widths ---
for t = 1:n_tab
    td = table_defs(t);
    Sheet.Range(sprintf('%s1:%s1', col2letter(td.group_col), col2letter(td.subj_col))).EntireColumn.AutoFit;
    Sheet.Range(sprintf('%s1:%s1', col2letter(td.data_col0), col2letter(td.data_col0+n_days*n_bins-1))).EntireColumn.AutoFit;
end

% Hide the chart-feeder staging columns - live formulas pointing at this
% tab's own visible tables, not meant to be read directly (same as every
% other tab's chart staging area).
try
    Sheet.Range(sprintf('%s:%s', col2letter(chart_stage_col0), ...
        col2letter(chart_stage_col0 + numel(chart_specs)*chart_stage_block_w + 10))).EntireColumn.Hidden = true;
catch
end
end

%%
% SV, August 23, 2026: I added this whole function (no v5 equivalent), at
% SV's request: the same two-pivot comparison the binned tabs give for
% time-in-zone, but for the VISIT COUNTS added to all_tones earlier today.
% It answers "does the animal go to the platform vs the reward zone more,
% during tones vs during ITIs" in discrete entries rather than proportion of
% time - the two measures can disagree (a mouse can make many brief visits
% or one long one), which is exactly why SV wanted both.
%
% Layout is deliberately identical to write_binned_tab so the tabs read the
% same way, one pair of tables + charts stacked per experimental day:
%   Table 1 "Platform v Reward": rows Sham/TMS -> Platform/Reward -> Subject,
%       columns "Tone visits" / "ITI visits"
%   Table 2 "Tone v ITI":        rows Sham/TMS -> Tone/ITI -> Subject,
%       columns "Platform" / "Reward"
% Both pivots show the SAME four numbers per subject, sliced the two ways -
% same relationship the binned tabs have.
%
% Three things differ from write_binned_tab, all because these are counts
% rather than 0-1 proportions:
%   - cells are integer-formatted (write_formula_cell's is_integer flag)
%   - the gradient CF uses scale_mode 'auto' (lowest..highest value present)
%     rather than a fixed 0->1 scale, which would peg every count at the top
%   - the charts use y_axis_mode 'count' (auto-scaled, integer ticks)
% Like the binned tabs, every cell is a live formula pointing at all_tones,
% so hand-editing a raw value there flows through to these tables and to the
% charts that feed off them. There is no tone-range axis here - visit counts
% are whole-session totals, so there is one visits tab, not three.
% SV, August 23, 2026: I changed the signature to return "recs", the paired
% comparison records behind this tab's charts, so write_formatted_xlsx can
% collect them for the stats tab. The tab itself is unchanged apart from the
% stars now drawn on its charts.
% SV, September 3, 2026: I added the trailing trend_bin_ranges/
% trend_bin_labels parameters - needed for the new trend charts appended at
% the bottom of this tab, per SV's request to consolidate a visit-count
% time-course into zone_visits - see write_trend_table_and_chart's changelog.
% SV, September 8, 2026: I SPLIT this one function/tab into two - this
% function (now named for what it actually contains) keeps only the
% day-block Platform-v-Reward/Tone-v-ITI comparison tables and paired
% bar-line charts; the Habituation/Train-Retr timecourse+summary trend
% blocks moved out to their own write_zone_visits_timecourse_tab function
% below. Per SV's screenshot: the two sections sharing one sheet (even after
% the September 8 (earlier same day) column swap that put comparisons out at
% comparison_start_col=150) still pushed the comparison tables/charts out to
% a column (ET) far separated from anything else on screen - a second tab
% is a real fix, a bigger column offset would just be the same problem
% moved further out. t1_col/t2_col and chart_stage_col_a/b move back to
% their original col 1/8 and 20/30 positions now that there's no longer a
% second section on the same sheet to stay clear of.
function recs = write_zone_visits_compared_tab(Workbook, sheet_name, rows, zero_font_bgr, ...
    metric_names, scalar_metric_names, max_tones, all_tones_sheet_name, all_tones_data_start_row)
recs = struct('tab', {}, 'day', {}, 'plot', {}, 'comparison', {}, 'n', {}, ...
    'mean_a', {}, 'mean_b', {}, 'p_t', {}, 'p_t_holm', {}, 'p_w', {}, 'p_w_holm', {}, 'stars', {});
%

% Same add-then-move pattern the other tab writers use.
last_sheet = Workbook.Sheets.Item(Workbook.Sheets.Count);
Sheet = Workbook.Sheets.Add;
Sheet.Move([], last_sheet);
Sheet.Name = sheet_name;

vr = visit_rows(rows, metric_names, scalar_metric_names, max_tones, ...
    all_tones_sheet_name, all_tones_data_start_row);
if isempty(vr)
    warning('visits tab: no sessions found - tab left empty.');
    return
end
days = unique([vr.Day], 'stable'); % rows are pre-sorted chronologically upstream

t1_col = struct('day',1, 'group',2, 'sub',3, 'subj',4, 'a',5, 'b',6);    % Platform v Reward, cols A-F
t2_col = struct('day',8, 'group',9, 'sub',10, 'subj',11, 'a',12, 'b',13); % Tone v ITI, cols H-M (gap col G)
% SV, September 8, 2026: I added these two - staging columns for the new
% Reward Preference (Reward - Platform) charts, per SV's reference image.
% pref_hab lives on Table 1 (one row per subject already, on Hab days -
% see that branch below); pref_tone/pref_iti live on Table 2, whose rows
% are already split into Tone/ITI sub-blocks (t2_blocks.<group>.Tone/.ITI)
% - each is a plain "=<Reward cell> - <Platform cell>" live formula on the
% SAME row t2_col.a/b already occupy, so no separate write pass is needed.
t1_col.pref = t1_col.b + 2;      % col H  - Hab days' "Reward - Platform"
t2_col.pref_tone = t2_col.b + 2; % col O  - Train/Retr Tone "Reward - Platform"
t2_col.pref_iti  = t2_col.b + 3; % col P  - Train/Retr ITI  "Reward - Platform"

row_cursor = 1;
gap_rows = 2;
last_row_overall = 0;

chart_stage_col_a = 20;  % col T  - Platform v Reward chart feeder
chart_stage_col_b = 30;  % col AD - Tone v ITI chart feeder
chart_stage_col_c = 40;  % col AN - Reward Preference (Tone) chart feeder
chart_stage_col_d = 50;  % col AX - Reward Preference (ITI) chart feeder
chart_stage_row = 1;
CHART_W = 380;
CHART_H = 260;
ROWS_PER_CHART = ceil(CHART_H / 15);
chart_gap_pt = 20;

for d = 1:numel(days)
    day = days(d);
    day_rows = vr([vr.Day] == day);
    sham_rows = day_rows([day_rows.Group] == "sham");
    [~, si] = sort([sham_rows.SubjectNum]); sham_rows = sham_rows(si);
    tms_rows = day_rows([day_rows.Group] == "tms");
    [~, ti] = sort([tms_rows.SubjectNum]); tms_rows = tms_rows(ti);

    header_row = row_cursor;
    data_start = row_cursor + 1;

    % SV, September 8, 2026: I added this whole Habituation branch. The tone
    % never actually played on a Hab day, so the Tone-visits/ITI-visits split
    % both tables below are built around doesn't mean anything there - per
    % SV, Hab days get ONE simple Platform-vs-Reward table on the merged
    % (tone+ITI combined) totals instead, and skip Table 2 (Tone v ITI)
    % entirely, since there is no Tone/ITI distinction to compare. Train/Retr
    % days are unaffected - they fall through to the existing two-table,
    % two-chart logic below unchanged.
    if startsWith(day, 'Hab', 'IgnoreCase', true)
        set_header_cell(Sheet, t1_col.subj, header_row, 'Subject');
        set_header_cell(Sheet, t1_col.a, header_row, 'Platform');
        set_header_cell(Sheet, t1_col.b, header_row, 'Reward');
        set_header_cell(Sheet, t1_col.pref, header_row, 'Reward - Platform');

        t1_blocks_hab = struct('group', {}, 'first_subj_row', {}, 'last_subj_row', {}, 'mean_row', {});
        r = data_start;
        for gi = ["sham", "tms"]
            if gi == "sham", grows = sham_rows; else, grows = tms_rows; end
            if isempty(grows), continue; end
            first_subj_row = r;
            for k = 1:numel(grows)
                subj = grows(k);
                Sheet.Range(sprintf('%s%d', col2letter(t1_col.subj), r)).Value2 = subj.SubjectLabel;
                write_formula_cell(Sheet.Range(sprintf('%s%d', col2letter(t1_col.a), r)), subj.PlatTotal_f, subj.PlatTotal_v, true);
                write_formula_cell(Sheet.Range(sprintf('%s%d', col2letter(t1_col.b), r)), subj.RewTotal_f, subj.RewTotal_v, true);
                pref_f = sprintf('=%s%d-%s%d', col2letter(t1_col.b), r, col2letter(t1_col.a), r);
                write_formula_cell(Sheet.Range(sprintf('%s%d', col2letter(t1_col.pref), r)), pref_f, subj.RewTotal_v - subj.PlatTotal_v, true);
                r = r + 1;
            end
            last_subj_row = r - 1;
            mean_row = r;
            lblCell = Sheet.Range(sprintf('%s%d', col2letter(t1_col.subj), mean_row));
            lblCell.Value2 = sprintf('%s_mean', char(gi));
            lblCell.Font.Bold = true;
            for cc = [t1_col.a, t1_col.b, t1_col.pref]
                cletter = col2letter(cc);
                cellRange = Sheet.Range(sprintf('%s%d', cletter, mean_row));
                if cc == t1_col.a
                    snapshot = mean([grows.PlatTotal_v], 'omitnan');
                elseif cc == t1_col.b
                    snapshot = mean([grows.RewTotal_v], 'omitnan');
                else
                    snapshot = mean([grows.RewTotal_v] - [grows.PlatTotal_v], 'omitnan');
                end
                formula_str = sprintf('=AVERAGE(%s%d:%s%d)', cletter, first_subj_row, cletter, last_subj_row);
                write_formula_cell(cellRange, formula_str, snapshot);
                cellRange.Font.Bold = true;
            end
            r = r + 1;
            apply_group_gradient_cf(Sheet, t1_col.a, t1_col.b, first_subj_row, mean_row, gi, zero_font_bgr, 'auto');
            merge_label_cell(Sheet, t1_col.group, first_subj_row, mean_row, group_label(gi), gi);
            t1_blocks_hab(end+1) = struct('group', gi, 'first_subj_row', first_subj_row, ...
                'last_subj_row', last_subj_row, 'mean_row', mean_row); %#ok<AGROW>
        end
        day_block_end = r - 1;
        if day_block_end >= data_start
            merge_label_cell(Sheet, t1_col.day, data_start, day_block_end, char(day), "neutral");
        end
        last_row_overall = max(last_row_overall, day_block_end);

        % No stats/recs recorded on the Platform-v-Reward bar chart itself
        % (matches every other purely-descriptive Habituation summary chart
        % in this workbook) - but the NEW Reward Preference chart right next
        % to it DOES get a stat (Sham vs TMS, unpaired - see below), per SV.
        chart_anchor_row = day_block_end + 2;
        anchorA = Sheet.Range(sprintf('%s%d', col2letter(t1_col.day), chart_anchor_row));
        % SV, September 8, 2026: I changed the y_axis_mode argument here from
        % 'count' to 'auto' - build_summary_bar_chart only recognizes the
        % literal 'auto' as its free-scale mode (checks
        % strcmp(y_axis_mode,'auto') - anything else, including 'count',
        % falls through to its FIXED -0.03..1 proportion axis). 'count' is
        % build_paired_barline_chart's keyword for the same thing, not this
        % function's - passing it here silently clipped every visit-count
        % bar to the 0-1 range, which is what produced the garbled "1,1,1,
        % 0,0,0" y-axis ticks SV screenshotted.
        coHab = build_summary_bar_chart(Sheet, t1_blocks_hab, ["Platform", "Reward"], [t1_col.a, t1_col.b], ...
            sprintf('%s: Platform v Reward (visits)', char(day)), 'Zone visits (count)', 'auto', '0', ...
            anchorA.Left, anchorA.Top, CHART_W, CHART_H, chart_stage_col_a, chart_stage_row);

        % SV, September 8, 2026: I added this whole Reward Preference chart -
        % per SV's reference image, one dot-per-subject + mean+/-SEM bar chart
        % of (Reward - Platform), Sham vs TMS, with a dashed zero-reference
        % line and a significance star from an UNPAIRED Sham-vs-TMS test (see
        % run_unpaired_comparison's changelog for why this is a different
        % test from every other chart's paired one). Habituation only needs
        % ONE of these (the merged Platform/Reward table above already has no
        % Tone/ITI split to duplicate it across) - Train/Retr gets two
        % further down (Tone and ITI), per SV.
        pref_left = anchorA.Left;
        if ~isempty(coHab)
            pref_left = coHab.Left + CHART_W + chart_gap_pt;
        end
        pref_sham = [sham_rows.RewTotal_v] - [sham_rows.PlatTotal_v];
        pref_tms  = [tms_rows.RewTotal_v]  - [tms_rows.PlatTotal_v];
        [pref_rec, pref_star, pref_ymax] = run_unpaired_comparison(pref_sham, pref_tms, ...
            'Sham vs TMS: Reward - Platform (visits)', sheet_name, char(day), 'Reward Preference');
        recs = [recs, pref_rec]; %#ok<AGROW>
        build_summary_bar_chart(Sheet, t1_blocks_hab, "Preference", t1_col.pref, ...
            sprintf('%s: Reward Preference (visits)', char(day)), 'Reward - Platform (visits)', ...
            'signed', '0', pref_left, anchorA.Top, CHART_W, CHART_H, chart_stage_col_c, chart_stage_row, ...
            {pref_star}, pref_ymax);

        n_subj_this_day = numel(day_rows);
        chart_stage_row = chart_stage_row + 5 + max(n_subj_this_day, 1) + gap_rows;
        row_cursor = max(day_block_end + 1 + gap_rows, chart_anchor_row + ROWS_PER_CHART + gap_rows);
        continue
    end

    % --- Table 1: Platform v Reward (columns = Tone visits / ITI visits) ---
    set_header_cell(Sheet, t1_col.subj, header_row, 'Subject');
    set_header_cell(Sheet, t1_col.a, header_row, 'Tone visits');
    set_header_cell(Sheet, t1_col.b, header_row, 'ITI visits');

    t1_blocks = struct();
    r = data_start;
    for gi = ["sham", "tms"]
        if gi == "sham", grows = sham_rows; else, grows = tms_rows; end
        if isempty(grows), continue; end
        group_start = r;
        for pr = ["Platform", "Reward"]
            pr_start = r;
            for k = 1:numel(grows)
                subj = grows(k);
                Sheet.Range(sprintf('%s%d', col2letter(t1_col.subj), r)).Value2 = subj.SubjectLabel;
                if pr == "Platform"
                    a_f = subj.PlatTone_f; a_v = subj.PlatTone_v;
                    b_f = subj.PlatITI_f;  b_v = subj.PlatITI_v;
                else
                    a_f = subj.RewTone_f; a_v = subj.RewTone_v;
                    b_f = subj.RewITI_f;  b_v = subj.RewITI_v;
                end
                write_formula_cell(Sheet.Range(sprintf('%s%d', col2letter(t1_col.a), r)), a_f, a_v, true);
                write_formula_cell(Sheet.Range(sprintf('%s%d', col2letter(t1_col.b), r)), b_f, b_v, true);
                r = r + 1;
            end
            merge_label_cell(Sheet, t1_col.sub, pr_start, r-1, char(pr), gi);
            t1_blocks.(char(gi)).(char(pr)) = [pr_start, r-1];
        end
        apply_group_gradient_cf(Sheet, t1_col.a, t1_col.b, group_start, r-1, gi, zero_font_bgr, 'auto');
        merge_label_cell(Sheet, t1_col.group, group_start, r-1, group_label(gi), gi);
    end
    t1_end_row = r - 1;
    if t1_end_row >= data_start
        merge_label_cell(Sheet, t1_col.day, data_start, t1_end_row, char(day), "neutral");
    end

    % --- Table 2: Tone v ITI (columns = Platform / Reward) ---
    set_header_cell(Sheet, t2_col.subj, header_row, 'Subject');
    set_header_cell(Sheet, t2_col.a, header_row, 'Platform');
    set_header_cell(Sheet, t2_col.b, header_row, 'Reward');
    % SV, September 8, 2026: I added these two headers - live "Reward -
    % Platform" columns feeding the new Reward Preference charts below, one
    % per Tone/ITI sub-block row (see the write_formula_cell call added to
    % the loop right under this).
    set_header_cell(Sheet, t2_col.pref_tone, header_row, 'Reward - Platform (Tone)');
    set_header_cell(Sheet, t2_col.pref_iti, header_row, 'Reward - Platform (ITI)');

    t2_blocks = struct();
    r2 = data_start;
    for gi = ["sham", "tms"]
        if gi == "sham", grows = sham_rows; else, grows = tms_rows; end
        if isempty(grows), continue; end
        group_start2 = r2;
        for ti_grp = ["Tone visits", "ITI visits"]
            ti_start = r2;
            if startsWith(ti_grp, 'Tone'), pref_col = t2_col.pref_tone; else, pref_col = t2_col.pref_iti; end
            for k = 1:numel(grows)
                subj = grows(k);
                Sheet.Range(sprintf('%s%d', col2letter(t2_col.subj), r2)).Value2 = subj.SubjectLabel;
                if startsWith(ti_grp, 'Tone')
                    a_f = subj.PlatTone_f; a_v = subj.PlatTone_v;
                    b_f = subj.RewTone_f;  b_v = subj.RewTone_v;
                else
                    a_f = subj.PlatITI_f; a_v = subj.PlatITI_v;
                    b_f = subj.RewITI_f;  b_v = subj.RewITI_v;
                end
                write_formula_cell(Sheet.Range(sprintf('%s%d', col2letter(t2_col.a), r2)), a_f, a_v, true);
                write_formula_cell(Sheet.Range(sprintf('%s%d', col2letter(t2_col.b), r2)), b_f, b_v, true);
                pref_f = sprintf('=%s%d-%s%d', col2letter(t2_col.b), r2, col2letter(t2_col.a), r2);
                write_formula_cell(Sheet.Range(sprintf('%s%d', col2letter(pref_col), r2)), pref_f, b_v - a_v, true);
                r2 = r2 + 1;
            end
            merge_label_cell(Sheet, t2_col.sub, ti_start, r2-1, char(ti_grp), gi);
            % Key by "Tone"/"ITI" so build_paired_barline_chart can look these
            % blocks up generically, same as write_binned_tab does.
            if startsWith(ti_grp, 'Tone')
                t2_blocks.(char(gi)).Tone = [ti_start, r2-1];
            else
                t2_blocks.(char(gi)).ITI = [ti_start, r2-1];
            end
        end
        apply_group_gradient_cf(Sheet, t2_col.a, t2_col.b, group_start2, r2-1, gi, zero_font_bgr, 'auto');
        merge_label_cell(Sheet, t2_col.group, group_start2, r2-1, group_label(gi), gi);
    end
    t2_end_row = r2 - 1;
    if t2_end_row >= data_start
        merge_label_cell(Sheet, t2_col.day, data_start, t2_end_row, char(day), "neutral");
    end

    day_block_end = max(t1_end_row, t2_end_row);
    last_row_overall = max(last_row_overall, day_block_end);

    % SV, August 23, 2026: I added - the four paired comparisons behind each
    % chart, Holm-corrected within that chart (the per-plot family SV chose).
    % The pair ORDER must match the chart's fixed category layout, which is
    % [outer1/sham/f1, outer1/sham/f2, outer1/tms/f1, outer1/tms/f2,
    %  outer2/sham/f1, ...] - so pairs (1,2)(3,4)(5,6)(7,8) are
    % sham-outer1, tms-outer1, sham-outer2, tms-outer2 in that order.
    % 'log1p' because visit counts are strongly right-skewed.
    p1 = struct('label', {}, 'a', {}, 'b', {});
    for oi = ["Tone", "ITI"]
        for gi = ["sham", "tms"]
            if gi == "sham", gr = sham_rows; else, gr = tms_rows; end
            if oi == "Tone"
                A = [gr.PlatTone_v]; B = [gr.RewTone_v];
            else
                A = [gr.PlatITI_v];  B = [gr.RewITI_v];
            end
            p1(end+1) = struct('label', sprintf('%s / %s visits: Platform vs Reward', ...
                group_label(gi), oi), 'a', A, 'b', B); %#ok<AGROW>
        end
    end
    % Reorder to chart-pair order (sham-Tone, tms-Tone, sham-ITI, tms-ITI is
    % already what the nested loops above produce).
    [rec1, star1, ymax1] = run_chart_comparisons(p1, 'log1p', sheet_name, char(day), 'Platform v Reward');

    p2 = struct('label', {}, 'a', {}, 'b', {});
    for oi = ["Platform", "Reward"]
        for gi = ["sham", "tms"]
            if gi == "sham", gr = sham_rows; else, gr = tms_rows; end
            if oi == "Platform"
                A = [gr.PlatTone_v]; B = [gr.PlatITI_v];
            else
                A = [gr.RewTone_v];  B = [gr.RewITI_v];
            end
            p2(end+1) = struct('label', sprintf('%s / %s: Tone vs ITI visits', ...
                group_label(gi), oi), 'a', A, 'b', B); %#ok<AGROW>
        end
    end
    [rec2, star2, ymax2] = run_chart_comparisons(p2, 'log1p', sheet_name, char(day), 'Tone v ITI');
    recs = [recs, rec1, rec2]; %#ok<AGROW>
    %

    % SV, September 8, 2026: I added these two unpaired Sham-vs-TMS
    % comparisons - one Tone-based, one ITI-based Reward Preference (Reward -
    % Platform), per SV: Train/Retr days keep the Tone/ITI split (unlike
    % Habituation, which collapses to one merged preference chart - see that
    % branch's changelog above), so this tab needs TWO of these, not one.
    pref_tone_sham = [sham_rows.RewTone_v] - [sham_rows.PlatTone_v];
    pref_tone_tms  = [tms_rows.RewTone_v]  - [tms_rows.PlatTone_v];
    [pref_rec_tone, pref_star_tone, pref_ymax_tone] = run_unpaired_comparison(pref_tone_sham, pref_tone_tms, ...
        'Sham vs TMS: Reward - Platform (Tone visits)', sheet_name, char(day), 'Reward Preference (Tone)');
    pref_iti_sham = [sham_rows.RewITI_v] - [sham_rows.PlatITI_v];
    pref_iti_tms  = [tms_rows.RewITI_v]  - [tms_rows.PlatITI_v];
    [pref_rec_iti, pref_star_iti, pref_ymax_iti] = run_unpaired_comparison(pref_iti_sham, pref_iti_tms, ...
        'Sham vs TMS: Reward - Platform (ITI visits)', sheet_name, char(day), 'Reward Preference (ITI)');
    recs = [recs, pref_rec_tone, pref_rec_iti]; %#ok<AGROW>
    %

    % --- One paired bar+line chart per table, same as the binned tabs ---
    chart_anchor_row = day_block_end + 2;
    anchorA = Sheet.Range(sprintf('%s%d', col2letter(t1_col.day), chart_anchor_row));
    coA = build_paired_barline_chart(Sheet, t1_blocks, t1_col.a, t1_col.b, "Platform", "Reward", ...
        'Tone visits', 'ITI visits', 'Platform', 'Reward', ...
        sprintf('%s: Platform v Reward (visits)', char(day)), 'Zone visits (count)', ...
        anchorA.Left, anchorA.Top, CHART_W, CHART_H, chart_stage_col_a, chart_stage_row, 'count', ...
        star1, ymax1);
    coB = build_paired_barline_chart(Sheet, t2_blocks, t2_col.a, t2_col.b, "Tone", "ITI", ...
        'Platform', 'Reward', 'Tone visits', 'ITI visits', ...
        sprintf('%s: Tone v ITI (visits)', char(day)), 'Zone visits (count)', ...
        coA.Left + CHART_W + chart_gap_pt, anchorA.Top, CHART_W, CHART_H, ...
        chart_stage_col_b, chart_stage_row, 'count', star2, ymax2);

    % SV, September 8, 2026: I added these two Reward Preference charts,
    % placed right after (not overlapping) the Tone v ITI chart above, per
    % SV's reference image. Each reuses the SAME t2_blocks row spans
    % (Tone/ITI sub-blocks) already built for Table 2 above, just reading
    % the new pref_tone/pref_iti columns instead of a/b.
    pref_blocks_tone = struct('group', {}, 'first_subj_row', {}, 'last_subj_row', {}, 'mean_row', {});
    pref_blocks_iti  = struct('group', {}, 'first_subj_row', {}, 'last_subj_row', {}, 'mean_row', {});
    for gi = ["sham", "tms"]
        gc = char(gi);
        if isfield(t2_blocks, gc) && isfield(t2_blocks.(gc), 'Tone')
            span = t2_blocks.(gc).Tone;
            pref_blocks_tone(end+1) = struct('group', gi, 'first_subj_row', span(1), 'last_subj_row', span(2), 'mean_row', NaN); %#ok<AGROW>
        end
        if isfield(t2_blocks, gc) && isfield(t2_blocks.(gc), 'ITI')
            span = t2_blocks.(gc).ITI;
            pref_blocks_iti(end+1) = struct('group', gi, 'first_subj_row', span(1), 'last_subj_row', span(2), 'mean_row', NaN); %#ok<AGROW>
        end
    end
    % SV, September 8, 2026: build_summary_bar_chart returns [] (and only
    % warns) when a "blocks" argument is empty - e.g. every session for one
    % group missing this day's Tone or ITI rows - so pref_c_left falls back
    % to coB's own right edge rather than dereferencing an empty coC.Left.
    pref_c_left = coB.Left + CHART_W + chart_gap_pt;
    coC = build_summary_bar_chart(Sheet, pref_blocks_tone, "Preference", t2_col.pref_tone, ...
        sprintf('%s: Reward Preference (Tone, visits)', char(day)), 'Reward - Platform (visits)', ...
        'signed', '0', pref_c_left, anchorA.Top, CHART_W, CHART_H, ...
        chart_stage_col_c, chart_stage_row, {pref_star_tone}, pref_ymax_tone);
    pref_d_left = pref_c_left + CHART_W + chart_gap_pt;
    if ~isempty(coC)
        pref_d_left = coC.Left + CHART_W + chart_gap_pt;
    end
    build_summary_bar_chart(Sheet, pref_blocks_iti, "Preference", t2_col.pref_iti, ...
        sprintf('%s: Reward Preference (ITI, visits)', char(day)), 'Reward - Platform (visits)', ...
        'signed', '0', pref_d_left, anchorA.Top, CHART_W, CHART_H, ...
        chart_stage_col_d, chart_stage_row, {pref_star_iti}, pref_ymax_iti);

    n_subj_this_day = numel(day_rows);
    chart_stage_row = chart_stage_row + 5 + max(n_subj_this_day, 1) + gap_rows;

    row_cursor = max(day_block_end + 1 + gap_rows, chart_anchor_row + ROWS_PER_CHART + gap_rows);
end

% --- Column widths (same treatment as the binned tabs) ---
Sheet.Range(sprintf('%s1:%s1', col2letter(t1_col.a), col2letter(t1_col.pref))).EntireColumn.AutoFit;
Sheet.Range(sprintf('%s1:%s1', col2letter(t2_col.a), col2letter(t2_col.pref_iti))).EntireColumn.AutoFit;
if last_row_overall >= 1
    Sheet.Range(sprintf('%s1:%s%d', col2letter(t1_col.day), col2letter(t1_col.subj), last_row_overall)).EntireColumn.AutoFit;
    Sheet.Range(sprintf('%s1:%s%d', col2letter(t2_col.day), col2letter(t2_col.subj), last_row_overall)).EntireColumn.AutoFit;
end

% Hide the chart-feeder columns - live formulas pointing at this tab's own
% visible tables, not meant to be read directly (same as the binned tabs).
% SV, September 8, 2026: I widened this range through chart_stage_col_d+7 -
% the two new Reward Preference charts' staging columns.
Sheet.Range(sprintf('%s1:%s1', col2letter(chart_stage_col_a), col2letter(chart_stage_col_d + 7))).EntireColumn.Hidden = true;
end

%%
% SV, September 3, 2026 (later same day): I added this whole function - the
% SAME "3 groups x Timecourse+Summary pair" design SV's hand-drawn sketch
% specified for the locomotion tab redesign - "this type of design was also
% what i previously meant for you to add to the zone_visits tab". Reuses
% write_simple_trend_table_and_chart directly (see its changelog and
% write_locomotion_tab's call site for the identical pattern): per metric
% (Platform, Reward), one Timecourse+Summary pair for Habituation
% (Analysis.Merged - combined tone+ITI trial cycles, no Tone/ITI split,
% since the tone never played on Hab days), one for Train/Retr ITI visits,
% one for Train/Retr Tone visits - 6 blocks total, stacked vertically via
% trend_row chaining.
%
% This originally lived at the bottom of write_visits_tab, sharing one sheet
% with the day-block Platform-v-Reward/Tone-v-ITI comparison tables above -
% first stacked below them, then (September 8, 2026, earlier same day)
% moved beside them at a large column offset per SV's "timecourse left,
% comparison right" request. Per SV's screenshot, that column-offset
% approach just relocated the same problem: the comparison tables/charts
% still ended up parked out at column ET, nowhere near anything else on
% screen. SV asked for separate tabs instead: this function got PULLED OUT
% into its own function/sheet ("zone_visits_timecourse"), the day-block
% comparison tables/charts stayed in write_zone_visits_compared_tab (see its
% own changelog) on their own sheet ("zone_visits_compared") - see the
% write_formatted_xlsx call site for both. With no second section sharing
% this sheet, trend_start_col goes back to 1 and there's no longer any
% comparison-tab staging range to stay clear of.
function write_zone_visits_timecourse_tab(Workbook, sheet_name, rows, zero_font_bgr, ...
    trend_bin_ranges, trend_bin_labels)

last_sheet = Workbook.Sheets.Item(Workbook.Sheets.Count);
Sheet = Workbook.Sheets.Add;
Sheet.Move([], last_sheet);
Sheet.Name = sheet_name;

all_days_vt = strings(1, numel(rows));
for ii = 1:numel(rows)
    all_days_vt(ii) = day_from_condition(rows(ii).Condition);
end
is_hab_day_vt = startsWith(all_days_vt, 'Hab', 'IgnoreCase', true);
hab_days_vt = unique(all_days_vt(is_hab_day_vt), 'stable');
real_days_vt = unique(all_days_vt(~is_hab_day_vt), 'stable');

trend_start_col = 1;
trend_row = 1;
trend_stage_base = 400;
for metric_name = ["Reward", "Platform"]
    if metric_name == "Reward"
        val_hab  = @(k,br) bin_sum(rows(k).Merged_Visits, br);
        val_tone = @(k,br) bin_sum(rows(k).Reward_tone_visit_vec, br);
        val_iti  = @(k,br) bin_sum(rows(k).Reward_iti_visit_vec, br);
    else
        val_hab  = @(k,br) bin_sum(rows(k).Plat_Merged_Visits, br);
        val_tone = @(k,br) bin_sum(rows(k).Plat_tone_visit_vec, br);
        val_iti  = @(k,br) bin_sum(rows(k).Plat_iti_visit_vec, br);
    end
    m = char(metric_name);

    trend_row = write_simple_trend_table_and_chart(Sheet, trend_row, trend_start_col, trend_stage_base, zero_font_bgr, ...
        rows, hab_days_vt, trend_bin_ranges, trend_bin_labels, val_hab, ...
        sprintf('%s Visits: Habituation (tone+ITI combined)', m), 'auto', ...
        sprintf('%s Visits: Habituation timecourse', m), 'Visits (count)', 'auto', '0', ...
        sprintf('%s Visits: Habituation summary', m), true);
    trend_stage_base = trend_stage_base + 150;

    trend_row = write_simple_trend_table_and_chart(Sheet, trend_row, trend_start_col, trend_stage_base, zero_font_bgr, ...
        rows, real_days_vt, trend_bin_ranges, trend_bin_labels, val_iti, ...
        sprintf('%s Visits: Train/Retr (ITI)', m), 'auto', ...
        sprintf('%s Visits: Train and Retr timecourse (ITI)', m), 'Visits (count)', 'auto', '0', ...
        sprintf('%s Visits: Train and Retr summary (ITI)', m), true);
    trend_stage_base = trend_stage_base + 150;

    trend_row = write_simple_trend_table_and_chart(Sheet, trend_row, trend_start_col, trend_stage_base, zero_font_bgr, ...
        rows, real_days_vt, trend_bin_ranges, trend_bin_labels, val_tone, ...
        sprintf('%s Visits: Train/Retr (Tone)', m), 'auto', ...
        sprintf('%s Visits: Train and Retr timecourse (Tone)', m), 'Visits (count)', 'auto', '0', ...
        sprintf('%s Visits: Train and Retr summary (Tone)', m), true);
    trend_stage_base = trend_stage_base + 150;
end
end

%%
% SV, August 23, 2026: I added - the visits-tab analogue of bin_rows.
% Reshapes the per-session "rows" struct into the Day/Group/Subject fields
% the pivot needs, with each of the four visit counts as a live formula
% pointing at its all_tones cell plus a one-time snapshot value (the
% snapshot only picks the number format, exactly as in bin_rows).
% The four map onto the same field names the binned tabs use, so both tabs
% can share build_paired_barline_chart and the pivot code reads the same:
%   PlatTone <- Plat_tone_visits     PlatITI <- Plat_iti_visits
%   RewTone  <- Reward_tone_visits   RewITI  <- Reward_iti_visits
% SV, September 8, 2026: I added PlatTotal <- Plat_total_visits and
% RewTotal <- Reward_total_visits - the whole-session (tone+ITI combined)
% totals, for write_zone_visits_compared_tab's Habituation days. Per SV: the
% tone never actually played on a Hab day, so splitting Habituation visits
% into "Tone visits"/"ITI visits" columns doesn't mean anything - those
% days should show one merged total instead, the same "Merged" treatment
% Habituation already gets everywhere else in this workbook (locomotion,
% zone_visits_timecourse). Train/Retr days still use the Tone/ITI split.
function vr = visit_rows(rows, metric_names, scalar_metric_names, max_tones, ...
    all_tones_sheet_name, all_tones_data_start_row)
n = numel(rows);
vr = struct('Day', {}, 'Group', {}, 'SubjectNum', {}, 'SubjectLabel', {}, ...
    'PlatTone_f', {}, 'PlatTone_v', {}, 'PlatITI_f', {}, 'PlatITI_v', {}, ...
    'RewTone_f', {}, 'RewTone_v', {}, 'RewITI_f', {}, 'RewITI_v', {}, ...
    'PlatTotal_f', {}, 'PlatTotal_v', {}, 'RewTotal_f', {}, 'RewTotal_v', {});
field_map = { ...
    'PlatTone',  "Plat_tone_visits"; ...
    'PlatITI',   "Plat_iti_visits"; ...
    'RewTone',   "Reward_tone_visits"; ...
    'RewITI',    "Reward_iti_visits"; ...
    'PlatTotal', "Plat_total_visits"; ...
    'RewTotal',  "Reward_total_visits"};
for i = 1:n
    vr(i).Day = day_from_condition(rows(i).Condition);
    vr(i).Group = classify_group(rows(i).Condition);
    [num, lbl] = parse_subject(rows(i).Subject);
    vr(i).SubjectNum = num;
    vr(i).SubjectLabel = lbl;

    % all_tones writes session i to this row, in the same order "rows" is in -
    % the same index mapping bin_rows relies on.
    all_row = all_tones_data_start_row + i - 1;
    for f = 1:size(field_map, 1)
        short = field_map{f, 1};
        col_name = field_map{f, 2};
        c = scalar_col_index(metric_names, scalar_metric_names, max_tones, col_name);
        vr(i).([short '_f']) = sprintf('=''%s''!%s%d', all_tones_sheet_name, col2letter(c), all_row);
        vr(i).([short '_v']) = rows(i).(col_name);
    end
end
end

%%
% SV, August 23, 2026: I added - column index on the all_tones tab for one of
% the session-level scalar columns. Derived the same way write_all_tones_tab
% lays them out (col 3 onward, max_tones columns per entry in metric_names,
% then one column per entry in scalar_metric_names in order), so both stay in
% sync off the same inputs rather than a second hardcoded copy of the column
% math - same reasoning as metric_col_span for the tone-grouped metrics.
function c = scalar_col_index(metric_names, scalar_metric_names, max_tones, scalar_name)
idx = find(scalar_metric_names == scalar_name, 1);
if isempty(idx)
    error('scalar_col_index: "%s" is not in scalar_metric_names.', scalar_name);
end
c = 3 + numel(metric_names) * max_tones + (idx - 1);
end
%%
% SV, August 23, 2026: I added the statistics helpers below (no v5
% equivalent). Design decisions, all made with SV on 2026-08-23 after
% characterising the real data - worth reading before changing any of this:
%
%  * proportion_successful is NOT continuous. It takes only 5 values
%    (0, 1/3, 1/2, 2/3, 1), 80% of observations sit exactly at 0 or 1, and
%    the denominator varies (1, 2 or 3 tones per bin, because sessions run
%    4-6 tones). A t-test/ANOVA on those proportions is not defensible, and
%    averaging them weights a 1-of-1 bin the same as a 3-of-3 bin. So the
%    successful_trials question is answered with a BINOMIAL GLMM on
%    successes/ntrials with a per-animal random intercept, which models the
%    varying denominator correctly and handles the repeated measures and the
%    one missing animal-day.
%  * Visit counts are strongly right-skewed (0..118, skewness ~4), so the
%    paired comparisons are run BOTH ways and both are reported: a paired
%    t-test on log1p(count) and a Wilcoxon signed-rank on the raw counts.
%  * IMPORTANT, and the reason stars come from the t-test: with n=7 per
%    group the smallest achievable two-sided signed-rank p is 2/2^7 =
%    0.0156, so after Holm correction across 4 comparisons nothing can ever
%    fall below 0.05. Drawing stars from the Wilcoxon would mean drawing no
%    stars regardless of the data. Stars therefore come from the
%    Holm-corrected t-test; the Wilcoxon p is reported alongside it in the
%    stats tab so the discrepancy is visible rather than hidden. This was
%    decided BEFORE seeing the results, not chosen after.
%  * Correction is Holm-Bonferroni within each plot (4 comparisons per
%    chart), per SV.
function p_adj = holm_adjust(p_in)
% Holm-Bonferroni step-down adjusted p-values. Monotonicity is enforced (an
% adjusted p can never be smaller than one earlier in the sorted order),
% which is what makes them directly comparable against a single alpha.
p_in = p_in(:)';
valid = ~isnan(p_in);
p_adj = nan(size(p_in));
pv = p_in(valid);
if isempty(pv)
    return
end
[ps, ix] = sort(pv);
m = numel(ps);
adj = zeros(1, m);
for i = 1:m
    adj(i) = min(1, (m - i + 1) * ps(i));
end
for i = 2:m
    adj(i) = max(adj(i), adj(i-1));
end
out = zeros(1, m);
out(ix) = adj;
p_adj(valid) = out;
end

%%
% SV, August 23, 2026: I added - conventional significance marker for an
% already-corrected p-value. Returns '' for NaN (test not run, e.g. a
% comparison with fewer than 2 usable pairs) so nothing is drawn.
function s = sig_stars(p)
if isnan(p)
    s = '';
elseif p < 0.001
    s = '***';
elseif p < 0.01
    s = '**';
elseif p < 0.05
    s = '*';
else
    s = 'n.s.';
end
end

%%
% SV, August 23, 2026: I added - one paired comparison, run both ways.
% transform 'log1p' is used for visit COUNTS (right-skewed), 'none' for the
% binned-tones proportions (already bounded 0-1 and far less skewed).
% Pairs where either value is missing are dropped pairwise. Returns NaN
% p-values rather than erroring when fewer than 2 complete pairs survive.
function [p_t, p_w, n, mean_a, mean_b] = paired_compare(a, b, transform)
a = double(a(:)); b = double(b(:));
ok = ~isnan(a) & ~isnan(b);
a = a(ok); b = b(ok);
n = numel(a);
mean_a = NaN; mean_b = NaN; p_t = NaN; p_w = NaN;
if n < 2
    return
end
mean_a = mean(a); mean_b = mean(b);
if strcmp(transform, 'log1p')
    ta = log1p(a); tb = log1p(b);
else
    ta = a; tb = b;
end
% A pair with zero difference everywhere makes both tests degenerate.
if all(ta == tb)
    p_t = 1; p_w = 1;
    return
end
try
    [~, p_t] = ttest(ta, tb);
catch
    p_t = NaN;
end
try
    p_w = signrank(a, b);
catch
    p_w = NaN;
end
end

%%
% SV, August 23, 2026: I added - runs the 4 paired comparisons behind ONE
% chart and Holm-corrects across exactly those 4 (the per-plot family SV
% chose). pairs is a 4x1 struct array with fields .label, .a, .b. Returns a
% record array for the stats tab plus the star strings in chart-pair order,
% i.e. matching category pairs (1,2) (3,4) (5,6) (7,8).
function [recs, star_text, star_yval] = run_chart_comparisons(pairs, transform, tab_name, day_name, plot_name)
np = numel(pairs);
p_t = nan(1, np); p_w = nan(1, np);
nn = nan(1, np); ma = nan(1, np); mb = nan(1, np);
for k = 1:np
    [p_t(k), p_w(k), nn(k), ma(k), mb(k)] = paired_compare(pairs(k).a, pairs(k).b, transform);
end
p_t_adj = holm_adjust(p_t);
p_w_adj = holm_adjust(p_w);

recs = struct('tab', {}, 'day', {}, 'plot', {}, 'comparison', {}, 'n', {}, ...
    'mean_a', {}, 'mean_b', {}, 'p_t', {}, 'p_t_holm', {}, 'p_w', {}, 'p_w_holm', {}, 'stars', {});
star_text = repmat({''}, 1, np);
star_yval = nan(1, np);
for k = 1:np
    s = sig_stars(p_t_adj(k));
    recs(k).tab = tab_name;
    recs(k).day = day_name;
    recs(k).plot = plot_name;
    recs(k).comparison = pairs(k).label;
    recs(k).n = nn(k);
    recs(k).mean_a = ma(k);
    recs(k).mean_b = mb(k);
    recs(k).p_t = p_t(k);
    recs(k).p_t_holm = p_t_adj(k);
    recs(k).p_w = p_w(k);
    recs(k).p_w_holm = p_w_adj(k);
    recs(k).stars = s;
    % Only significant markers are drawn on the chart - an "n.s." on every
    % non-significant pair would re-clutter the axis SV just had cleaned up.
    if ~isempty(s) && ~strcmp(s, 'n.s.')
        star_text{k} = s;
    end
    ab = [pairs(k).a(:); pairs(k).b(:)];
    ab = ab(~isnan(ab));
    if ~isempty(ab)
        star_yval(k) = max(ab);
    end
end
end

%%
% SV, September 8, 2026: I added this whole function - an UNPAIRED
% two-sample comparison, for the new Reward Preference charts. Every other
% comparison in this workbook (paired_compare/run_chart_comparisons) tests
% the SAME subject's two values against each other (Platform vs Reward);
% this instead tests whether one GROUP's values differ from another's
% (Sham's Reward-Platform preference scores vs TMS's) - a different subject
% in each sample, no pairing between them. NaNs are dropped independently
% per side (no pairwise matching needed, unlike paired_compare).
%
% Welch's t-test (unequal-variance two-sample t-test) rather than the
% pooled-variance version - the two groups' sample sizes/variances aren't
% assumed equal, and Welch's is the safer default absent a reason to assume
% otherwise. Wilcoxon rank-sum (via MATLAB's ranksum, equivalent to
% Mann-Whitney U) is reported alongside it, same "both tests reported, stars
% come from the t-test" convention paired_compare already uses.
function [p_t, p_w, n, mean_a, mean_b] = unpaired_compare(a, b)
a = double(a(:)); a = a(~isnan(a));
b = double(b(:)); b = b(~isnan(b));
n = numel(a) + numel(b);
mean_a = NaN; mean_b = NaN; p_t = NaN; p_w = NaN;
if isempty(a) || isempty(b)
    return
end
mean_a = mean(a); mean_b = mean(b);
if numel(a) >= 2 && numel(b) >= 2
    try
        [~, p_t] = ttest2(a, b, 'Vartype', 'unequal');
    catch
        p_t = NaN;
    end
end
try
    p_w = ranksum(a, b);
catch
    p_w = NaN;
end
end

%%
% SV, September 8, 2026: I added this whole function - runs ONE unpaired
% comparison (Sham vs TMS) and packages it into the same recs-struct shape
% run_chart_comparisons produces, so it slots into the existing stats tab
% unchanged. Only one comparison per chart here (not four), so Holm
% correction is a no-op - holm_adjust on a single p-value returns that same
% p-value (m=1: min(1, 1*p) = p) - but p_t_holm/p_w_holm are still carried
% as separate fields for consistency with every other row in that tab.
function [rec, star, ymax] = run_unpaired_comparison(vals_sham, vals_tms, label, tab_name, day_name, plot_name)
[p_t, p_w, n, mean_a, mean_b] = unpaired_compare(vals_sham, vals_tms);
rec = struct('tab', tab_name, 'day', day_name, 'plot', plot_name, 'comparison', label, ...
    'n', n, 'mean_a', mean_a, 'mean_b', mean_b, 'p_t', p_t, 'p_t_holm', p_t, ...
    'p_w', p_w, 'p_w_holm', p_w, 'stars', sig_stars(p_t));
star = '';
if ~isnan(p_t)
    s = sig_stars(p_t);
    if ~strcmp(s, 'n.s.')
        star = s;
    end
end
allvals = [vals_sham(:); vals_tms(:)];
allvals = allvals(~isnan(allvals));
if isempty(allvals)
    ymax = NaN;
else
    ymax = max(allvals);
end
end

%%
% SV, August 23, 2026: I added - the binomial GLMM behind the
% successful_trials question, plus a training-days-only refit.
%
% Model: successes ~ group*time + (1|animal), Binomial, BinomialSize =
% tones actually in that bin. "time" is the ordered (day, bin) index, i.e.
% the same left-to-right axis the successful_trials chart uses, so the
% time term tests a linear trend across that axis and group:time tests
% whether sham and tms change at different rates.
%
% Two models are fitted on purpose. The full model spans Train AND Retr
% days, so its "time" term mixes within-training change with the
% Train->Retr phase switch and should NOT be read as a learning rate. The
% training-only refit answers the clean learning question. Both are
% reported; see the stats tab.
function G = fit_success_glmm(rows, success_bin_ranges)
G = struct('ok', false, 'msg', '', 'full', [], 'train', [], 'n_obs', 0, 'n_animals', 0);
succ = []; ntr = []; grp = {}; tm = []; sub = {}; isTrain = [];
day_list = strings(0);
for i = 1:numel(rows)
    d = day_from_condition(rows(i).Condition);
    if startsWith(d, 'Hab', 'IgnoreCase', true)
        continue % excluded from the metric itself, so excluded here too
    end
    if ~any(day_list == d)
        day_list(end+1) = d; %#ok<AGROW>
    end
end
for i = 1:numel(rows)
    d = day_from_condition(rows(i).Condition);
    if startsWith(d, 'Hab', 'IgnoreCase', true), continue; end
    v = rows(i).Plat_success_vector;
    if isempty(v) || all(isnan(v)), continue; end
    di = find(day_list == d, 1);
    [num, ~] = parse_subject(rows(i).Subject);
    for b = 1:numel(success_bin_ranges)
        idx = success_bin_ranges{b};
        idx = idx(idx <= numel(v));
        vv = v(idx); vv = vv(~isnan(vv));
        if isempty(vv), continue; end
        succ(end+1,1) = sum(vv); %#ok<AGROW>
        ntr(end+1,1) = numel(vv); %#ok<AGROW>
        grp{end+1,1} = char(classify_group(rows(i).Condition)); %#ok<AGROW>
        tm(end+1,1) = (di - 1) * numel(success_bin_ranges) + b; %#ok<AGROW>
        sub{end+1,1} = sprintf('dcsp%d', num); %#ok<AGROW>
        isTrain(end+1,1) = double(contains(d, 'Train', 'IgnoreCase', true)); %#ok<AGROW>
    end
end
if numel(succ) < 10 || numel(unique(grp)) < 2
    G.msg = 'Not enough data (need both groups and >=10 animal x bin observations).';
    return
end
T = table(succ, ntr, categorical(grp), tm, categorical(sub), isTrain, ...
    'VariableNames', {'successes','ntrials','group','time','animal','isTrain'});
G.n_obs = height(T);
G.n_animals = numel(categories(T.animal));
try
    G.full = fitglme(T, 'successes ~ group*time + (1|animal)', ...
        'Distribution', 'Binomial', 'BinomialSize', T.ntrials);
    G.ok = true;
catch ME
    G.msg = sprintf('Full model failed: %s', ME.message);
    return
end
try
    Tt = T(T.isTrain == 1, :);
    if height(Tt) >= 10 && numel(unique(Tt.time)) > 1 && numel(categories(removecats(Tt.group))) > 1
        G.train = fitglme(Tt, 'successes ~ group*time + (1|animal)', ...
            'Distribution', 'Binomial', 'BinomialSize', Tt.ntrials);
    end
catch
    G.train = []; % non-fatal - the full model is the primary result
end
end
%%
% SV, August 23, 2026: I added this whole function - the "stats" tab. Two
% sections: the binomial GLMM for successful_trials, then every paired
% comparison behind the zone_visits and binned_tones charts, with both the
% t-test and Wilcoxon p-values (raw and Holm-corrected) side by side.
% Stars drawn on the charts come from the p(t) Holm column; that is stated
% on the sheet itself so the choice is visible to anyone reading it.
function write_stats_tab(Workbook, sheet_name, G, recs)
last_sheet = Workbook.Sheets.Item(Workbook.Sheets.Count);
Sheet = Workbook.Sheets.Add;
Sheet.Move([], last_sheet);
Sheet.Name = sheet_name;

r = 1;
r = put_title(Sheet, r, 'STATISTICS');
r = put_note(Sheet, r, ['Generated automatically. Stars on the charts come from the Holm-corrected ' ...
    'paired t-test column (p(t) Holm), decided before results were seen - see the note under ' ...
    'section 2 for why the Wilcoxon cannot be used for that.']);
r = r + 1;

%% ---- Section 1: successful_trials GLMM ----
r = put_title(Sheet, r, '1. successful_trials: does TMS differ from sham, and does time matter?');
r = put_note(Sheet, r, ['Binomial generalised linear mixed model on successes / tones-in-bin, ' ...
    'with a random intercept per animal: successes ~ group*time + (1|animal).']);
r = put_note(Sheet, r, ['Why not an ANOVA on the proportion: that proportion takes only 5 distinct ' ...
    'values, ~80% of observations sit exactly at 0 or 1, and its denominator varies (1-3 tones per ' ...
    'bin, since sessions run 4-6 tones). The GLMM models successes/trials directly, so a 1-of-1 bin ' ...
    'is weighted less than a 3-of-3 bin instead of counting equally.']);
r = put_note(Sheet, r, ['"time" = the ordered (day, bin) index, i.e. the same left-to-right axis as ' ...
    'the successful_trials chart. group:time tests whether the two groups change at different rates.']);
r = r + 1;

if ~G.ok
    r = put_note(Sheet, r, sprintf('MODEL DID NOT RUN: %s', G.msg));
    r = r + 1;
else
    r = put_note(Sheet, r, sprintf('n = %d observations (animal x day x bin) from %d animals.', ...
        G.n_obs, G.n_animals));
    r = r + 1;
    r = put_subtitle(Sheet, r, 'Model A - all days (Train and Retr together)');
    r = write_glme_table(Sheet, r, G.full);
    r = put_note(Sheet, r, ['CAUTION: this model spans training AND retrieval days, so its "time" ' ...
        'term mixes change during training with the Train->Retr phase switch. Do not read it as a ' ...
        'learning rate on its own - see Model B.']);
    r = r + 1;
    if ~isempty(G.train)
        r = put_subtitle(Sheet, r, 'Model B - TRAINING days only (the clean learning question)');
        r = write_glme_table(Sheet, r, G.train);
        r = r + 1;
    else
        r = put_note(Sheet, r, 'Model B (training-only) could not be fitted - too few training timepoints.');
        r = r + 1;
    end
end

%% ---- Section 2: paired comparisons ----
% SV, September 8, 2026: I updated these labels from "zone_visits" /
% "binned_tones" to "zone_visits_compared" / "zone_time", then (later same
% day) to "zone_visits_prop" / "zone_time_prop" - matching each tab-rename
% round made this same day (see write_zone_visits_compared_tab and
% write_binned_tab's call site changelogs). Purely descriptive text, no
% functional lookup depends on these strings.
r = put_title(Sheet, r, '2. zone_visits_prop / zone_time_prop: paired comparisons behind each chart');
r = put_note(Sheet, r, ['Each chart contributes 4 paired comparisons (one per Sham/TMS x period or ' ...
    'zone cell). Holm-Bonferroni correction is applied WITHIN each chart, i.e. across those 4.']);
r = put_note(Sheet, r, ['Both tests are reported. p(t) is a paired t-test - on log1p(count) for ' ...
    'zone_visits_prop, since visit counts are strongly right-skewed (0-118, skewness ~4), and on ' ...
    'the raw proportion for zone_time_prop. p(W) is a Wilcoxon signed-rank on the untransformed values.']);
r = put_note(Sheet, r, ['WHY STARS COME FROM p(t): with n=7 per group the smallest possible two-sided ' ...
    'signed-rank p is 2/2^7 = 0.0156, so after Holm correction across 4 comparisons NO Wilcoxon result ' ...
    'can fall below 0.05, whatever the data. Stars from p(W) would mean no stars ever. Where the two ' ...
    'tests disagree, treat the result as provisional - that disagreement is a real signal that the ' ...
    'effect rests on the distributional assumption.']);
r = put_note(Sheet, r, 'Blank p-values mean the comparison had fewer than 2 complete pairs.');
r = r + 1;

hdr = {'Tab','Day','Plot','Comparison','n','mean A','mean B','p(t)','p(t) Holm','p(W)','p(W) Holm','Stars'};
for c = 1:numel(hdr)
    cell_ = Sheet.Range(sprintf('%s%d', col2letter(c), r));
    cell_.Value2 = hdr{c};
    cell_.Font.Bold = true;
end
r = r + 1;
first_data_row = r;
for i = 1:numel(recs)
    Sheet.Range(sprintf('%s%d', col2letter(1), r)).Value2 = char(recs(i).tab);
    Sheet.Range(sprintf('%s%d', col2letter(2), r)).Value2 = char(recs(i).day);
    Sheet.Range(sprintf('%s%d', col2letter(3), r)).Value2 = char(recs(i).plot);
    Sheet.Range(sprintf('%s%d', col2letter(4), r)).Value2 = char(recs(i).comparison);
    put_num(Sheet, 5, r, recs(i).n, '0');
    put_num(Sheet, 6, r, recs(i).mean_a, '0.000');
    put_num(Sheet, 7, r, recs(i).mean_b, '0.000');
    put_num(Sheet, 8, r, recs(i).p_t, '0.0000');
    put_num(Sheet, 9, r, recs(i).p_t_holm, '0.0000');
    put_num(Sheet, 10, r, recs(i).p_w, '0.0000');
    put_num(Sheet, 11, r, recs(i).p_w_holm, '0.0000');
    sc = Sheet.Range(sprintf('%s%d', col2letter(12), r));
    sc.Value2 = char(recs(i).stars);
    if ~isempty(recs(i).stars) && ~strcmp(recs(i).stars, 'n.s.')
        sc.Font.Bold = true;
    end
    r = r + 1;
end

% Highlight significant corrected t-test p-values so they're findable.
if numel(recs) > 0
    rng = Sheet.Range(sprintf('%s%d:%s%d', col2letter(9), first_data_row, col2letter(9), r-1));
    try
        xlCellValue = 1; xlLess = 6;
        fc = rng.FormatConditions.Add(xlCellValue, xlLess, '0.05');
        fc.Font.Bold = true;
        fc.Interior.Color = rgb_to_bgr([255 235 156]);
    catch
        % Cosmetic only.
    end
end

Sheet.Range(sprintf('A1:%s%d', col2letter(12), r)).EntireColumn.AutoFit;
% Keep the long explanatory notes from stretching column A absurdly wide.
try
    Sheet.Range('A1').EntireColumn.ColumnWidth = 46;
catch
end
end

%%
% SV, August 23, 2026: I added - dump a fitglme's fixed-effect coefficient
% table and its marginal ANOVA onto the sheet.
function r = write_glme_table(Sheet, r, mdl)
ce = mdl.Coefficients;
hdr = {'Term','Estimate','SE','tStat','DF','p','Lower','Upper'};
for c = 1:numel(hdr)
    cc = Sheet.Range(sprintf('%s%d', col2letter(c), r));
    cc.Value2 = hdr{c}; cc.Font.Bold = true;
end
r = r + 1;
names = ce.Name;
for i = 1:numel(names)
    Sheet.Range(sprintf('%s%d', col2letter(1), r)).Value2 = char(string(names{i}));
    put_num(Sheet, 2, r, ce.Estimate(i), '0.0000');
    put_num(Sheet, 3, r, ce.SE(i), '0.0000');
    put_num(Sheet, 4, r, ce.tStat(i), '0.000');
    put_num(Sheet, 5, r, ce.DF(i), '0');
    pcell = Sheet.Range(sprintf('%s%d', col2letter(6), r));
    pcell.Value2 = ce.pValue(i); pcell.NumberFormat = '0.0000';
    if ce.pValue(i) < 0.05
        pcell.Font.Bold = true;
        try
            pcell.Interior.Color = rgb_to_bgr([255 235 156]);
        catch
        end
    end
    put_num(Sheet, 7, r, ce.Lower(i), '0.0000');
    put_num(Sheet, 8, r, ce.Upper(i), '0.0000');
    r = r + 1;
end
% Plain-language reading of the two terms SV actually asked about.
try
    ix_g = find(contains(string(names), 'group') & ~contains(string(names), ':'), 1);
    ix_i = find(contains(string(names), ':'), 1);
    if ~isempty(ix_g)
        r = put_note(Sheet, r, sprintf(['group term p = %.4g -> %s difference between sham and tms ' ...
            'overall.'], ce.pValue(ix_g), verdict(ce.pValue(ix_g))));
    end
    if ~isempty(ix_i)
        r = put_note(Sheet, r, sprintf(['group:time term p = %.4g -> %s evidence that the two groups ' ...
            'change at different rates over time.'], ce.pValue(ix_i), verdict(ce.pValue(ix_i))));
    end
catch
end
end

%%
function s = verdict(p)
% SV, August 23, 2026: I added - plain-language significance wording.
if isnan(p), s = 'no';
elseif p < 0.05, s = 'SIGNIFICANT';
else, s = 'NO significant';
end
end

%%
function r = put_title(Sheet, r, txt)
% SV, August 23, 2026: I added.
c = Sheet.Range(sprintf('A%d', r));
c.Value2 = txt; c.Font.Bold = true; c.Font.Size = 12;
r = r + 1;
end

%%
function r = put_subtitle(Sheet, r, txt)
% SV, August 23, 2026: I added.
c = Sheet.Range(sprintf('A%d', r));
c.Value2 = txt; c.Font.Bold = true;
r = r + 1;
end

%%
function r = put_note(Sheet, r, txt)
% SV, August 23, 2026: I added - explanatory note line. Written into column A
% (not merged across, which would fight AutoFit); wrap is left off so the row
% stays one line high and the text simply spills right over empty cells.
c = Sheet.Range(sprintf('A%d', r));
c.Value2 = txt;
c.Font.Italic = true;
r = r + 1;
end

%%
function put_num(Sheet, col, row, val, fmt)
% SV, August 23, 2026: I added - numeric cell that stays blank for NaN,
% matching how the rest of the workbook treats missing values.
c = Sheet.Range(sprintf('%s%d', col2letter(col), row));
if isnan(val)
    return
end
c.Value2 = val;
c.NumberFormat = fmt;
end
%%
function letter = col2letter(col)
% New in v4 - converts a 1-based column index to its Excel column letter(s) (1->'A',
% 26->'Z', 27->'AA', ...), for building A1-notation range strings.
letter = '';
while col > 0
    rem = mod(col - 1, 26);
    letter = [char('A' + rem), letter]; %#ok<AGROW>
    col = floor((col - 1) / 26);
end
end

%%
function group = classify_group(condition_name)
% New in v4 - decides which color gradient (gray vs red) a row's Condition belongs to.
% SV, September 28, 2026: I changed
% c = lower(condition_name);
% if contains(c, 'sham')
%     group = "sham";
% elseif contains(c, 'tms')
%     group = "tms";
% else
%     warning('Condition "%s" contains neither "sham" nor "tms" - defaulting to the gray (sham) color scale.', condition_name);
%     group = "sham";
% end
% to this, per SV: a folder that is neither must be EXCLUDED, not quietly
% counted as Sham. Folders like that are now dropped before any session is
% read (see condition_group), so reaching the error here means one slipped
% through - which should stop the run rather than mislabel an animal.
group = condition_group(condition_name);
if group == ""
    error('Condition "%s" has no sham_/tms_ prefix and should have been excluded before this point.', condition_name);
end
end

%%
% SV, September 28, 2026: I added - the group a condition folder belongs to,
% from its name PREFIX ("sham_..." / "tms_...", any case), or "" if neither.
% A prefix, not contains(): the dataset layout requires the prefix (see
% E:\PMA_Dataset_Layout.md), and a substring test would call
% "PVFP_TmsSham_SV_Aug25_photometry" Sham. "" means: excluded by default.
function group = condition_group(condition_name)
c = lower(char(condition_name));
if startsWith(c, 'sham_')
    group = "sham";
elseif startsWith(c, 'tms_')
    group = "tms";
else
    group = "";
end
end

% SV, July 24, 2026: I removed group_fill_bgr (New in v4) from here:
% function bgr = group_fill_bgr(value, group)
% % New in v4 - linearly interpolates the fill color for a non-zero cell (0->1) between the
% % gray (sham) or red (tms/experimental) gradient endpoints, matching the two color scales
% % shown in the reference screenshots.
% value = max(0, min(1, value));
% if group == "sham"
%     c0 = [239 239 239]; % light gray
%     c1 = [153 153 153]; % dark gray
% else
%     c0 = [244 204 204]; % light red
%     c1 = [204 65 37];   % dark red
% end
% rgb = round(c0 + value * (c1 - c0));
% bgr = rgb_to_bgr(rgb);
% end
% It computed a static per-cell fill color at export time. Replaced by a live Excel Color
% Scale conditional-format rule (see apply_group_gradient_cf below), which needs just the
% two gradient endpoint colors (now in group_gradient_colors) rather than a per-value color.
%

%%
function [c0, c1] = group_gradient_colors(group)
% New in v5 - the two gradient endpoint RGB colors for a group's Color Scale (0->1), shared
% by apply_group_gradient_cf (live gradient) and merge_label_cell (flat label fill). Kept as
% the single source of these colors instead of duplicating the RGB triplets in both places.
% SV, September 28, 2026: I changed
% if group == "sham"
%     c0 = [239 239 239]; % light gray
%     c1 = [153 153 153]; % dark gray
% else
%     c0 = [244 204 204]; % light red
%     c1 = [204 65 37];   % dark red
% end
% to this - both endpoints are now tints of the group color picked at startup
% (see group_color). c1 is a 60% tint rather than the full color so black
% numbers stay readable on the darkest cells even for a dark pick like IT Blue.
% The two DEFAULT picks keep their original hand-chosen endpoints exactly,
% so a workbook built with the defaults is unchanged from before the picker.
base = double(group_color(group));
[names, rgb] = group_palette();
if isequal(base, rgb(names == "Control Grey", :))
    c0 = [239 239 239]; c1 = [153 153 153];
elseif isequal(base, rgb(names == "Shock Red", :))
    c0 = [244 204 204]; c1 = [204 65 37];
else
    c0 = round(255 - 0.12*(255 - base));
    c1 = round(255 - 0.60*(255 - base));
end
end

%%
% SV, September 28, 2026: I added - the colors SV can pick for each group in
% select_folders_gui, in rainbow order (Cajal Brown and Control Grey have no
% rainbow position, so they close the list). RGB 0-255. SST Orange is the
% line color from meansemplot_SVv1.m; the rest were read off SV's swatch
% images by eye - correct them HERE if a color is off, nothing else needs to
% change. "Shock Red" is the red every earlier report was drawn in.
function [names, rgb] = group_palette()
P = { ...
    'Shock Red',    [217  31  31]; ...
    'SST Orange',   [210 102  36]; ...
    'PV Yellow',    [232 170  20]; ...
    'CORT Green',   [106 142  35]; ...
    'UCLA Blue',    [ 39 116 174]; ...
    'IT Blue',      [ 52  88 140]; ...
    'PT Purple',    [150  50 140]; ...
    'Cajal Brown',  [128  92  45]; ...
    'Control Grey', [ 89  89  89]};
names = string(P(:,1))';
rgb = cell2mat(P(:,2));
end

%%
% SV, September 28, 2026: I added - the one place a group's color lives, so
% the PDF report and the workbook cannot disagree. A persistent store rather
% than a variable threaded through every function: local functions of a
% script cannot see the script's workspace, and the color is needed ~15 calls
% deep in both the COM and the plotting code.
%   group_color("tms")                  -> [R G B], 0-255
%   group_color("tms", "UCLA Blue")     -> sets it (a palette name or an RGB triplet)
% The main script sets BOTH groups at the start of every run, so a pick from
% an earlier run in the same MATLAB session can never leak into this one.
function c = group_color(group, new_val)
persistent C
if isempty(C)
    C = struct('sham', [89 89 89], 'tms', [39 116 174]); % Control Grey, UCLA Blue
end
g = lower(char(group));
if ~strcmp(g, 'tms'), g = 'sham'; end % same fallback as classify_group
if nargin == 2
    if isnumeric(new_val) && numel(new_val) == 3
        C.(g) = double(new_val(:)');
    else
        [names, rgb] = group_palette();
        k = find(strcmpi(names, string(new_val)), 1);
        if isempty(k)
            error('Unknown group color "%s". Choose one of: %s', string(new_val), strjoin(names, ', '));
        end
        C.(g) = rgb(k, :);
    end
end
c = C.(g);
end

%%
% SV, August 23, 2026: I changed the function signature
% function apply_group_gradient_cf(Sheet, col_start, col_end, row_start, row_end, group, zero_font_bgr)
% to this (optional scale_mode, default 'proportion' so every existing call
% site is unchanged). 'proportion' pins the color scale to the numbers 0 and
% 1, which is right for the time-in-zone / proportion_successful cells. The
% new visits tab passes 'auto', which pins it to the lowest and highest
% values actually present instead - a fixed 0->1 scale would make a visit
% count of 2 and one of 40 both peg the top of the scale and look identical.
function apply_group_gradient_cf(Sheet, col_start, col_end, row_start, row_end, group, zero_font_bgr, scale_mode)
if nargin < 8
    scale_mode = 'proportion';
end
%
% New in v5 - replaces the old baked-in per-cell Interior.Color gradient with a live Excel
% Color Scale conditional-format rule over col_start:col_end / row_start:row_end, so manually
% editing a cell's value updates its fill automatically. A separate "cell value = 0" classic
% rule forces the zero-value font color. Per SV's choice (2026-07-24): zero cells still pick
% up the color scale's pale low-end fill, since Excel's "Stop If True" can't suppress a color
% scale's fill for specific cells - that only stops other classic rules - so this is close to
% but not pixel-identical to v4's fully-excluded "no fill" zero treatment.
if row_end < row_start
    return
end
rng = Sheet.Range(sprintf('%s%d:%s%d', col2letter(col_start), row_start, col2letter(col_end), row_end));

xlCellValue = 1; xlEqual = 3; xlConditionValueNumber = 0; % Excel COM enum constants (no named
                                                            % enum access via actxserver, so
                                                            % hardcoded here same as SaveAs's
                                                            % xlOpenXMLWorkbook=51 elsewhere)

zero_rule = rng.FormatConditions.Add(xlCellValue, xlEqual, '0');
zero_rule.Font.Color = zero_font_bgr;

[c0, c1] = group_gradient_colors(group);
cs = rng.FormatConditions.AddColorScale(2);
crit1 = cs.ColorScaleCriteria.Item(1);
crit2 = cs.ColorScaleCriteria.Item(2);
% SV, August 23, 2026: I changed
% crit1.Type = xlConditionValueNumber; crit1.Value = 0; ...
% crit2.Type = xlConditionValueNumber; crit2.Value = 1; ...
% to this, so the endpoints can follow the data for non-proportion columns.
% xlConditionValueLowestValue=1 / xlConditionValueHighestValue=2 need no
% .Value at all - Excel recomputes them live as the cells are edited, which
% keeps the "gradient reacts to hand-edits" property the whole workbook has.
if strcmp(scale_mode, 'auto')
    xlConditionValueLowestValue = 1; xlConditionValueHighestValue = 2;
    crit1.Type = xlConditionValueLowestValue;
    crit2.Type = xlConditionValueHighestValue;
else
    crit1.Type = xlConditionValueNumber; crit1.Value = 0;
    crit2.Type = xlConditionValueNumber; crit2.Value = 1;
end
crit1.FormatColor.Color = rgb_to_bgr(c0);
crit2.FormatColor.Color = rgb_to_bgr(c1);
%
end

%%
function bgr = rgb_to_bgr(rgb)
% New in v4 - Excel COM's Interior.Color / Font.Color expect a single BGR-packed integer.
bgr = rgb(1) + rgb(2)*256 + rgb(3)*65536;
end

%%
% SV, August 21, 2026: I changed the function signature
% function write_value_cell(cellRange, val)
% to this (added an optional is_integer flag, default false, so every
% existing call site - which all pass only 2 args - is unaffected; the new
% scalar success/visit-count columns pass true so counts render as plain
% integers, e.g. "12", instead of "12.000"):
function write_value_cell(cellRange, val, is_integer)
if nargin < 3
    is_integer = false;
end
%
% New in v4 - shared single-cell value/format logic used by the "all tones" tab: blank if
% NaN, plain "0" number format if exactly zero, otherwise "0.000". Fill/font color are no
% longer set here - see below.
%
% SV, July 24, 2026: I changed
% function write_value_cell(cellRange, val, group, zero_font_bgr)
% % ...blank if NaN, plain "0" + light gray font if exactly zero, otherwise "0.000" with a
% % gray/red gradient fill scaled by value.
% if isnan(val)
%     % leave blank
% elseif val == 0
%     cellRange.Value2 = 0;
%     cellRange.NumberFormat = '0';
%     cellRange.Font.Color = zero_font_bgr;
% else
%     cellRange.Value2 = val;
%     cellRange.NumberFormat = '0.000';
%     cellRange.Interior.Color = group_fill_bgr(val, group);
% end
% end
% to this (fill color and the zero-value font color are now both handled by a live
% conditional-format rule applied once per row-block in apply_group_gradient_cf, instead of
% per-cell here, so "group"/"zero_font_bgr" are no longer needed by this function at all):
% SV, August 21, 2026: I changed
% if isnan(val)
%     % leave blank
% elseif val == 0
%     cellRange.Value2 = 0;
%     cellRange.NumberFormat = '0';
% else
%     cellRange.Value2 = val;
%     cellRange.NumberFormat = '0.000';
% end
% to this (added the is_integer branch - counts should read "12", not
% "12.000"; the NaN/zero branches are untouched):
if isnan(val)
    % leave blank
elseif val == 0
    cellRange.Value2 = 0;
    cellRange.NumberFormat = '0';
elseif is_integer
    cellRange.Value2 = val;
    cellRange.NumberFormat = '0';
else
    cellRange.Value2 = val;
    cellRange.NumberFormat = '0.000';
end
%
end
%

%%
% SV, August 23, 2026: I changed the function signature
% function write_formula_cell(cellRange, formula_str, val)
% to this (optional is_integer, defaulting false so every existing 3-arg
% call site is unaffected - the new visits tab passes true, since visit
% counts should read "12", not "12.000". Same pattern already added to
% write_value_cell.)
function write_formula_cell(cellRange, formula_str, val, is_integer)
if nargin < 4
    is_integer = false;
end
%
% New in v5 - like write_value_cell, but writes a live "=AVERAGE(...)" formula (built by
% tone_avg_formula) instead of a MATLAB-computed literal, so the binned tabs stay verifiably
% derived from the raw per-tone numbers on "all tones". Number format is still chosen from
% the one-time snapshot value (val) at generation time - same limitation write_value_cell
% already has, the "0" vs "0.000" choice won't auto-flip if the underlying value is later
% edited to cross zero.
if isnan(val)
    % leave blank - no formula written, since AVERAGE() over an all-blank range would show
    % #DIV/0! instead of nothing (matches write_value_cell leaving NaN cells blank)
elseif val == 0
    cellRange.Formula = formula_str;
    cellRange.NumberFormat = '0';
elseif is_integer % SV, August 23, 2026: I added
    cellRange.Formula = formula_str;
    cellRange.NumberFormat = '0';
else
    cellRange.Formula = formula_str;
    cellRange.NumberFormat = '0.000';
end
end

%%
function set_header_cell(Sheet, col, row, text)
% New in v4 - bold, centered single-cell column header, used in the binned tabs.
c = Sheet.Range(sprintf('%s%d', col2letter(col), row));
c.Value2 = text;
c.Font.Bold = true;
c.HorizontalAlignment = -4108;
end

%%
function merge_label_cell(Sheet, col, r1, r2, text, group)
% New in v4 - merges a single column across rows r1:r2 into one bold, centered label cell
% (used for the Day / Sham-TMS / Platform-Reward / Tone-ITI row-group labels in the binned
% tabs). "sham"/"tms" get a flat light fill matching that group's gradient color; "neutral"
% (the outermost day label) gets no fill. Left as a static bake-in, not conditional
% formatting - these are fixed row/column labels, not a heatmap of editable numeric values,
% so there's nothing for a live rule to react to.
rng = Sheet.Range(sprintf('%s%d:%s%d', col2letter(col), r1, col2letter(col), r2));
rng.Merge;
rng.Value2 = text;
rng.Font.Bold = true;
rng.HorizontalAlignment = -4108;
rng.VerticalAlignment = -4108;
% SV, September 28, 2026: I changed the two hardcoded fills to the group's
% light gradient end, so the labels follow the color picked at startup.
if group == "sham" || group == "tms"
    [c0, ~] = group_gradient_colors(group);
    rng.Interior.Color = rgb_to_bgr(c0);
end
end

%%
function label = group_label(group)
% New in v4 - display text for a Sham/TMS row-group label cell.
if group == "sham"
    label = 'Sham';
elseif group == "tms"
    label = 'TMS';
else
    label = char(group);
end
end

%%
function co = build_paired_barline_chart(Sheet, blocks, col_x, col_y, field1_name, field2_name, ...
    outer1_label, outer2_label, inner1_label, inner2_label, chart_title, y_axis_label, ...
    anchor_left, anchor_top, chart_w, chart_h, stage_col, stage_row, y_axis_mode, star_text, star_yval)
% SV, August 23, 2026: I added the optional star_text/star_yval arguments
% (both default empty, so existing calls are unchanged). star_text is a 1x4
% cellstr of significance markers for category pairs (1,2) (3,4) (5,6) (7,8)
% - the four paired comparisons this chart layout always represents - and
% star_yval the data value each marker should sit above. Drawn as floating
% textboxes after the axes are set; see the block at the end of this function.
if nargin < 20, star_text = {}; end
if nargin < 21, star_yval = []; end
%
% SV, August 23, 2026: I added the optional trailing y_axis_mode argument
% (default 'proportion', so all three binned tabs' existing 18-arg calls are
% unchanged). 'proportion' keeps the fixed -0.03..1 / 0.2-step axis these
% charts have always used; 'count' leaves Excel to auto-scale and formats
% the ticks as integers, which is what the new visits tab needs - visit
% counts run well past 1 and would otherwise all clip at the top of the axis.
if nargin < 19
    y_axis_mode = 'proportion';
end
%
% SV, July 24, 2026: I changed the function signature
% function build_paired_barline_chart(Sheet, blocks, col_x, col_y, field1_name, field2_name, ...
%     outer1_label, outer2_label, inner1_label, inner2_label, chart_title, y_axis_label, ...
%     anchor_cell_addr, chart_w, chart_h, stage_col, stage_row)
% to this (now takes/returns the anchor position in points and the created chart object
% itself, instead of a cell address and nothing - see write_binned_tab: this lets the caller
% anchor the second chart at the FIRST chart's actual right edge, which is the fix for the
% two charts overlapping that SV reported - anchoring both by cell column let Chart B's fixed
% pixel width overlap into Chart A whenever the real column widths between them summed to
% less than chart_w):
% (signature shown above already reflects the change)
% New in v5 - builds one Prism-style paired bar+line chart (bar = group mean with SEM error
% bars, one thin line per subject connecting its two paired values) matching the reference
% image SV supplied 2026-07-24. Used identically for both the "Platform v Reward" chart
% (field1/field2 = "Platform"/"Reward", outer groups = the tone-range columns t1_col.a/b) and
% the "Tone v ITI" chart (field1/field2 = "Tone"/"ITI", outer groups = t2_col.a/b) - same
% 8-category layout either way, per SV's request that both charts be identical in structure;
% only the data bound in by the caller (blocks/col_x/col_y/labels) differs.
%
% Fixed category order (8 total, matching the reference image's bracket nesting outer->inner):
% [x/sham/field1, x/sham/field2, x/tms/field1, x/tms/field2,
%  y/sham/field1, y/sham/field2, y/tms/field1, y/tms/field2]
% "x"/"y" pick col_x/col_y (the two outer-bracket columns); "blocks.sham.<field>"/
% "blocks.tms.<field>" (built by the caller, see t1_blocks/t2_blocks above) are each a
% [first_row last_row] span of that field's subject rows in the visible table.
%
% Chart-feeder data (category headers, mean/SEM formulas, one row per subject for the line
% series) is written starting at (stage_col, stage_row) - see the chart_stage_col_a/b /
% chart_stage_row bookkeeping in write_binned_tab - so every number the chart plots is a live
% formula pointing at the visible table, not a MATLAB-computed literal.
%
% SV, July 24, 2026: I added
% (no v4 equivalent, obviously - fixes the garbled axis labels SV reported after testing.
% Root cause: outer1_label/outer2_label/inner1_label/inner2_label sometimes arrive as plain
% MATLAB char arrays - e.g. from sprintf('Tones %s', range_label) at the call site, or a
% single-quoted literal like 'Platform'. [a, a, a, a, b, b, b, b] concatenates CHAR arrays
% character-by-character into one long char row vector, not an 8-element array of labels -
% totally different from concatenating actual MATLAB "string" objects, which does produce an
% 8-element array as intended. That silently produced a single garbled ~30-70 character blob
% whose first 8 CHARACTERS then got read as if they were the 8 category labels - exactly the
% "P,l,a,t,f,o,r,m" nonsense SV saw on the x-axis. Forcing these 4 inputs to "string" here,
% before anything gets concatenated, is the fix.)
outer1_label = string(outer1_label);
outer2_label = string(outer2_label);
inner1_label = string(inner1_label);
inner2_label = string(inner2_label);
%

outers = [col_x, col_x, col_x, col_x, col_y, col_y, col_y, col_y];
groups = ["sham", "sham", "tms", "tms", "sham", "sham", "tms", "tms"];
fields = [field1_name, field2_name, field1_name, field2_name, field1_name, field2_name, field1_name, field2_name];
outer_labels_row = [outer1_label, outer1_label, outer1_label, outer1_label, outer2_label, outer2_label, outer2_label, outer2_label];
group_labels_row = ["Sham", "Sham", "TMS", "TMS", "Sham", "Sham", "TMS", "TMS"];
field_labels_row = [inner1_label, inner2_label, inner1_label, inner2_label, inner1_label, inner2_label, inner1_label, inner2_label];

header_row1 = stage_row;     % outermost bracket (e.g. "Tones 1-6" / "ITIs 1-6")
header_row2 = stage_row + 1; % Sham/TMS bracket
header_row3 = stage_row + 2; % innermost tick label (e.g. "Platform" / "Reward")
mean_row    = stage_row + 3;
sem_row     = stage_row + 4;
subj_row0   = stage_row + 5; % first subject line-series row

for idx = 1:8
    c = stage_col + idx - 1;
    % SV, August 23, 2026: I changed these three writes
    % Sheet.Range(...header_row1).Value2 = char(outer_labels_row(idx));
    % Sheet.Range(...header_row2).Value2 = char(group_labels_row(idx));
    % Sheet.Range(...header_row3).Value2 = char(field_labels_row(idx));
    % (each wrote its label at EVERY one of the 8 positions) to only writing
    % a label where it actually changes, per SV: repeating "Tone visits" 4x
    % and "Sham" 2x in a row made the axis cluttered and slow to read.
    % Leaving the repeats BLANK is what makes Excel's multi-level category
    % axis span each label once, centred across the columns it covers, with
    % separator ticks between groups - verified against a live Excel session
    % before changing this (test export in the session scratchpad).
    % A level is re-written whenever its own label changes OR any level
    % ABOVE it changes; without that ancestor check, an inner label that
    % happens to repeat across an outer boundary (e.g. ...TMS | TMS...) would
    % silently merge across two different outer groups.
    outer_changed = (idx == 1) || ~strcmp(char(outer_labels_row(idx)), char(outer_labels_row(idx-1)));
    group_changed = outer_changed || ~strcmp(char(group_labels_row(idx)), char(group_labels_row(idx-1)));
    field_changed = group_changed || ~strcmp(char(field_labels_row(idx)), char(field_labels_row(idx-1)));
    if outer_changed
        Sheet.Range(sprintf('%s%d', col2letter(c), header_row1)).Value2 = char(outer_labels_row(idx));
    end
    if group_changed
        Sheet.Range(sprintf('%s%d', col2letter(c), header_row2)).Value2 = char(group_labels_row(idx));
    end
    if field_changed
        Sheet.Range(sprintf('%s%d', col2letter(c), header_row3)).Value2 = char(field_labels_row(idx));
    end
    %

    grp = char(groups(idx));
    fld = char(fields(idx));
    block = [];
    if isfield(blocks, grp) && isfield(blocks.(grp), fld)
        block = blocks.(grp).(fld);
    end
    if ~isempty(block)
        col_letter = col2letter(outers(idx));
        Sheet.Range(sprintf('%s%d', col2letter(c), mean_row)).Formula = ...
            sprintf('=AVERAGE(%s%d:%s%d)', col_letter, block(1), col_letter, block(2));
        % SV, July 24, 2026: I removed the SEM formula that used to be written here
        % (=STDEV(...)/SQRT(COUNT(...)), same range as the mean above) now that nothing
        % reads it - it only ever existed to feed the error-bar COM call SV asked to drop.
        % sem_row stays reserved (unused/blank) in the row layout below rather than
        % renumbering every other row, since it's already inside the hidden staging area.
    end
end

% --- Subject line-series data: one staging row per subject, blank in every column except
% the 2 (of 8) categories that subject actually belongs to ---
n_sham = 0;
if isfield(blocks, 'sham') && isfield(blocks.sham, field1_name)
    b = blocks.sham.(field1_name); n_sham = b(2) - b(1) + 1;
end
n_tms = 0;
if isfield(blocks, 'tms') && isfield(blocks.tms, field1_name)
    b = blocks.tms.(field1_name); n_tms = b(2) - b(1) + 1;
end
n_subj = n_sham + n_tms;

for idx = 1:8
    c = stage_col + idx - 1;
    grp = char(groups(idx));
    fld = char(fields(idx));
    if ~isfield(blocks, grp) || ~isfield(blocks.(grp), fld)
        continue
    end
    block = blocks.(grp).(fld);
    col_letter = col2letter(outers(idx));
    n_group = block(2) - block(1) + 1;
    if grp == "sham", row_offset0 = 0; else, row_offset0 = n_sham; end
    for k = 1:n_group
        data_row = block(1) + k - 1;
        staging_row = subj_row0 + row_offset0 + k - 1;
        Sheet.Range(sprintf('%s%d', col2letter(c), staging_row)).Formula = sprintf('=%s%d', col_letter, data_row);
    end
end

% --- Chart object ---
cat_range = Sheet.Range(sprintf('%s%d:%s%d', col2letter(stage_col), header_row1, col2letter(stage_col+7), header_row3));
mean_range = Sheet.Range(sprintf('%s%d:%s%d', col2letter(stage_col), mean_row, col2letter(stage_col+7), mean_row));
% SV, July 24, 2026: I removed the sem_range Range object that used to be defined here - it
% only existed to feed the now-removed error-bar COM call.

% SV, July 24, 2026: I changed
% anchor = Sheet.Range(anchor_cell_addr);
% co = Sheet.ChartObjects.Add(anchor.Left, anchor.Top, chart_w, chart_h);
% to this (anchor_left/anchor_top are now points passed straight in, not a cell to look up -
% see the function signature change above):
co = Sheet.ChartObjects.Add(anchor_left, anchor_top, chart_w, chart_h);
% SV, September 8, 2026: I added - Placement = xlFreeFloating (3). This was
% the one chart builder in the whole file still missing it (every other one
% - build_success_combined_chart, build_summary_bar_chart, etc. - already
% has it, most fixed earlier this same day). Without it, Excel's default
% Placement (xlMoveAndSize) lets this chart silently drift/resize whenever
% a LATER AutoFit call touches the columns it overlaps - e.g. the one
% write_binned_tab/write_zone_visits_compared_tab run once at the very end,
% after every day's charts are already placed. The new (correctly
% free-floating) Reward Preference charts built right after this one, each
% anchored off "this chart's Left + its width", don't move afterward - so
% this chart drifting out from under them is exactly what produced SV's
% screenshot of the Train/Retr charts overlapping.
try, co.Placement = 3; catch, end % xlFreeFloating
chart = co.Chart;
chart.ChartType = 51; % xlColumnClustered
chart.PlotVisibleOnly = false; % SV, July 24, 2026: I added - the chart-feeder columns get
    % hidden at the end of write_binned_tab per SV's request; without this, Excel's default
    % "only plot visible cells" would blank every chart out once those columns are hidden.

meanSeries = chart.SeriesCollection.NewSeries;
meanSeries.Name = 'Mean';
meanSeries.Values = mean_range;
meanSeries.XValues = cat_range;
meanSeries.ChartType = 51; % xlColumnClustered
for idx = 1:8
    [c0, ~] = group_gradient_colors(groups(idx));
    try
        % SV, July 24, 2026: I changed
        % meanSeries.Points.Item(idx).Interior.Color = rgb_to_bgr(c0);
        % meanSeries.Points.Item(idx).Format.Line.Visible = 0; % no bar outline, matches reference
        % to this (Interior.Color wasn't reliably taking on chart Points - switched to the
        % same Format.Fill/.Format.Line property path already confirmed working for the
        % subject line series below, instead of the older Interior shorthand):
        meanSeries.Points.Item(idx).Format.Fill.Solid;
        meanSeries.Points.Item(idx).Format.Fill.ForeColor.RGB = rgb_to_bgr(c0);
        meanSeries.Points.Item(idx).Format.Line.Visible = 0; % no bar outline, matches reference
        %
    catch
        % Excel errors indexing a Point for a fully-blank category on some versions -
        % harmless to skip, that bar just doesn't get drawn anyway.
    end
end
% SV, July 24, 2026: I removed the automated SEM error-bar code from here. Two different
% Excel COM call styles (direct .ErrorBar(...) method call, and invoke(series,'ErrorBar',...))
% both failed identically on every chart with COM error 0x800A03EC, and without a live Excel
% session to test against there was no reliable way to diagnose further - per SV's choice
% (2026-07-24), dropped rather than keep guessing blindly. Add SEM error bars by hand on
% whichever charts matter: select the "Mean" series -> Chart Design -> Add Chart Element ->
% Error Bars -> More Error Bar Options -> Custom -> set both Plus and Minus to a range you
% compute yourself (e.g. =STDEV(range)/SQRT(COUNT(range)) over that bar's subject values on
% this tab).
%

for idx = 1:n_subj
    if idx <= n_sham, grp = "sham"; else, grp = "tms"; end
    row = subj_row0 + idx - 1;
    s = chart.SeriesCollection.NewSeries;
    s.Name = sprintf('subj%d', idx);
    s.Values = Sheet.Range(sprintf('%s%d:%s%d', col2letter(stage_col), row, col2letter(stage_col+7), row));
    s.XValues = cat_range;
    s.ChartType = 4; % xlLine
    s.MarkerStyle = -4142; % xlMarkerStyleNone
    [~, c1] = group_gradient_colors(grp);
    s.Format.Line.ForeColor.RGB = rgb_to_bgr(c1);
    s.Format.Line.Weight = 1;
end

chart.HasTitle = true;
chart.ChartTitle.Text = chart_title;
% SV, July 24, 2026: I added - the title was wrapping/overflowing at the default chart-title
% font size, especially before the title text itself was shortened (see write_binned_tab's
% call site). Shrinking it is a second, independent fix for the same overflow problem.
try
    chart.ChartTitle.Font.Size = 11;
catch
end
%

try
    yAxis = chart.Axes(2, 1); % xlValue, xlPrimary
    yAxis.HasTitle = true;
    yAxis.AxisTitle.Text = y_axis_label;
catch ME
    warning('Could not set y-axis title on chart "%s": %s', chart_title, ME.message);
end

% SV, July 24, 2026: I changed
% (this used to be inside the same try block as the y-axis title above, with a bare "catch"
% swallowing any failure silently - split out with its own warning so a failure here is
% actually visible instead of quietly leaving Excel's auto-scaled axis in place, which is
% what SV saw: intervals that "don't make any sense" instead of 0.0-1.0 by 0.2.)
% SV, July 24, 2026: I changed
% try
%     yAxis = chart.Axes(2, 1); % xlValue, xlPrimary
%     yAxis.MinimumScaleIsAuto = false;
%     yAxis.MaximumScaleIsAuto = false;
%     yAxis.MinimumScale = 0;
%     yAxis.MaximumScale = 1;
%     yAxis.MajorUnit = 0.2;
% catch ME
%     warning('Could not fix the 0-1 y-axis scale on chart "%s": %s', chart_title, ME.message);
% end
% to this (per SV's second test: the 0.2 gridlines were STILL showing as "1,1,1,0,1,1" -
% turns out the axis's number format was "sourceLinked" to whichever data cell it happened to
% inherit from, which was formatted "0" (zero decimal places) on some of those cells, so
% 0.2/0.4/0.6/0.8 all rounded and displayed as "0" or "1". Explicitly un-linking and setting
% the tick label format fixes that. Also added a small negative MinimumScale, per SV's
% request to leave a little visible gap below 0.0 - like the Prism reference - so points/bars
% sitting exactly at 0 aren't flush against the axis line):
% SV, August 23, 2026: I added the y_axis_mode branch around this block. The
% 'proportion' branch is the original code, unchanged. 'count' lets Excel
% auto-scale (visit counts run to ~40, so a hard 0-1 cap would flatten every
% bar against the top) but still un-links the tick number format, since that
% source-linking bug is not specific to proportions.
if strcmp(y_axis_mode, 'count')
    try
        yAxis = chart.Axes(2, 1); % xlValue, xlPrimary
        yAxis.MinimumScaleIsAuto = false;
        yAxis.MinimumScale = 0;   % counts can't be negative
        yAxis.MaximumScaleIsAuto = true;
        yAxis.TickLabels.NumberFormatLinked = false;
        yAxis.TickLabels.NumberFormat = '0';
    catch ME
        warning('Could not set the count y-axis on chart "%s": %s', chart_title, ME.message);
    end
else
    try
        yAxis = chart.Axes(2, 1); % xlValue, xlPrimary
        yAxis.MinimumScaleIsAuto = false;
        yAxis.MaximumScaleIsAuto = false;
        yAxis.MinimumScale = -0.03;
        yAxis.MaximumScale = 1;
        yAxis.MajorUnit = 0.2;
        yAxis.TickLabels.NumberFormatLinked = false;
        yAxis.TickLabels.NumberFormat = '0.0';
    catch ME
        warning('Could not fix the 0-1 y-axis scale on chart "%s": %s', chart_title, ME.message);
    end
end
%

% SV, July 24, 2026: I changed
% try
%     catAxis = chart.Axes(1, 1); % xlCategory, xlPrimary
%     catAxis.TickLabels.Font.Size = 8;
% catch ME
%     warning('Could not shrink x-axis label font on chart "%s": %s', chart_title, ME.message);
% end
% to this (added Crosses=xlAxisCrossesMinimum so the x-axis line itself is drawn at the value
% axis's new -0.03 minimum instead of snapping back to 0 - without this, the MinimumScale
% padding above wouldn't actually show as a visible gap, since Excel's default behavior is to
% draw the category axis line at value=0 whenever 0 falls inside the value-axis range):
try
    catAxis = chart.Axes(1, 1); % xlCategory, xlPrimary
    catAxis.TickLabels.Font.Size = 8;
    catAxis.Crosses = 4; % xlAxisCrossesMinimum
catch ME
    warning('Could not set x-axis label size/crossing on chart "%s": %s', chart_title, ME.message);
end
%

chart.Legend.Delete;

% SV, August 23, 2026: I added - significance markers above the four paired
% comparisons, drawn as floating textboxes on the chart. Positioning is
% computed from the plot area's inside geometry and the value axis scale
% (both read back from Excel AFTER the axes are configured above, so the
% auto-scaled 'count' axis reports its final max) - verified against a live
% Excel session before wiring this in.
% Only significant markers are passed in; "n.s." pairs come through as ''
% and are skipped, so the chart doesn't get re-cluttered.
if ~isempty(star_text)
    try
        pa = chart.PlotArea;
        L0 = pa.InsideLeft; T0 = pa.InsideTop; W0 = pa.InsideWidth; H0 = pa.InsideHeight;
        yax = chart.Axes(2, 1);
        ymin = yax.MinimumScale; ymax = yax.MaximumScale;
        n_cat = 8;
        pair_first = [1 3 5 7]; % category pairs (1,2) (3,4) (5,6) (7,8)
        for k = 1:min(numel(star_text), numel(pair_first))
            txt = star_text{k};
            if isempty(txt), continue; end
            i1 = pair_first(k); i2 = i1 + 1;
            % x: midway between the two category centres
            xc = L0 + ((i1 - 0.5) + (i2 - 0.5)) / 2 / n_cat * W0;
            % y: a little above the taller of the pair, value -> points
            if k <= numel(star_yval) && ~isnan(star_yval(k))
                yv = star_yval(k) + 0.06 * (ymax - ymin);
            else
                yv = ymin + 0.92 * (ymax - ymin);
            end
            yv = min(yv, ymax);
            yp = T0 + (1 - (yv - ymin) / (ymax - ymin)) * H0;
            try
                tb = chart.Shapes.AddTextbox(1, xc - 20, yp - 15, 40, 16); % 1 = msoTextOrientationHorizontal
                tb.TextFrame.Characters.Text = txt;
                tb.TextFrame.HorizontalAlignment = -4108; % xlCenter
                try
                    tb.TextFrame2.TextRange.Font.Size = 12;
                    tb.TextFrame2.TextRange.Font.Bold = true;
                catch
                end
                try
                    tb.Fill.Visible = 0;
                    tb.Line.Visible = 0;
                catch
                end
            catch
                % One marker failing shouldn't lose the others.
            end
        end
    catch ME
        warning(['Could not draw significance markers on chart "%s": %s. The chart and the ' ...
            'stats tab are unaffected - only the on-chart stars are missing.'], chart_title, ME.message);
    end
end
%
end

%%
function [c0, c1] = metric_col_span(metric_names, max_tones, metric_name)
% New in v5 - deterministic tone1..toneN column span for a given metric name, on the "all
% tones" tab. Derived the same way write_all_tones_tab lays out its headers (col 3 onward,
% max_tones columns per metric, in metric_names order), so both stay in sync automatically
% off the same metric_names/max_tones instead of a second hardcoded copy of the column math.
idx = find(metric_names == metric_name, 1);
c0 = 3 + (idx - 1) * max_tones;
c1 = c0 + max_tones - 1;
end

%%
function [formula_str, val] = tone_avg_formula(vec, tone_range, metric_names, max_tones, metric_name, sheet_name, all_row)
% New in v5 - builds the "=AVERAGE('all tones'!C3:E3)"-style formula string pointing at the
% exact tone_range columns of metric_name on row all_row of the "all tones" tab, plus the
% one-time numeric snapshot (val) write_formula_cell needs to decide blank/zero/nonzero
% formatting. val is intentionally still computed here (not just left to Excel) purely for
% that formatting decision - the actual number shown in the cell always comes from the live
% formula, not from val.
val = mean(vec(tone_range), 'omitnan');
[base_c0, ~] = metric_col_span(metric_names, max_tones, metric_name);
c0 = base_c0 + tone_range(1) - 1;
c1 = base_c0 + tone_range(end) - 1;
formula_str = sprintf('=AVERAGE(''%s''!%s%d:%s%d)', sheet_name, col2letter(c0), all_row, col2letter(c1), all_row);
end

%%
function br = bin_rows(rows, tone_range, metric_names, max_tones, all_tones_sheet_name, all_tones_data_start_row)
% New in v4 - reshapes the per-session "rows" struct (Condition, Subject, and the 4 metrics
% x max_tones each) into one row per session with the tone_range columns reduced to a single
% Platform/Reward x Tone/ITI value each, plus the Day/Group/Subject fields the binned tabs
% are pivoted on.
%
% SV, July 24, 2026: I changed
% br = struct('Day', {}, 'Group', {}, 'SubjectNum', {}, 'SubjectLabel', {}, ...
%     'PlatTone', {}, 'PlatITI', {}, 'RewTone', {}, 'RewITI', {});
% for i = 1:n
%     br(i).Day = day_from_condition(rows(i).Condition);
%     br(i).Group = classify_group(rows(i).Condition);
%     [num, lbl] = parse_subject(rows(i).Subject);
%     br(i).SubjectNum = num;
%     br(i).SubjectLabel = lbl;
%     br(i).PlatTone = mean(rows(i).CSp_plat_time(tone_range), 'omitnan');
%     br(i).PlatITI = mean(rows(i).ITI_plat_time(tone_range), 'omitnan');
%     br(i).RewTone = mean(rows(i).CSp_reward_time(tone_range), 'omitnan');
%     br(i).RewITI = mean(rows(i).ITI_reward_time(tone_range), 'omitnan');
% end
% to this (each of the 4 values is now a formula string + its snapshot value, instead of
% just a literal - "all tones" writes session i to row all_tones_data_start_row+i-1, in the
% same order "rows" is in, which is what makes this index mapping valid):
% SV, September 8, 2026: I added PlatMerged_v/RewMerged_v - the Habituation
% merged (tone+ITI combined) time-in-zone proportion, reduced over this
% call's own tone_range same as the split fields above. Literal only, no
% "_f" live-formula counterpart: Merged_PerTimeInROI/Plat_Merged_PerTimeInROI
% aren't columns on "all_tones" (they're not in metric_names - Habituation-
% only, computed straight from Analysis.Merged, see calcCueFrames_batch's
% own changelog), so there's no live cell for a formula to point at, same
% situation as write_simple_trend_table_and_chart's Merged-based Habituation
% blocks. Needed so write_binned_tab's per-day Habituation branch can show
% ONE merged Platform/Reward value instead of a meaningless Tone/ITI split -
% the tone never actually played on a Hab day, per SV.
n = numel(rows);
br = struct('Day', {}, 'Group', {}, 'SubjectNum', {}, 'SubjectLabel', {}, ...
    'PlatTone_f', {}, 'PlatTone_v', {}, 'PlatITI_f', {}, 'PlatITI_v', {}, ...
    'RewTone_f', {}, 'RewTone_v', {}, 'RewITI_f', {}, 'RewITI_v', {}, ...
    'PlatMerged_v', {}, 'RewMerged_v', {});
for i = 1:n
    br(i).Day = day_from_condition(rows(i).Condition);
    br(i).Group = classify_group(rows(i).Condition);
    [num, lbl] = parse_subject(rows(i).Subject);
    br(i).SubjectNum = num;
    br(i).SubjectLabel = lbl;

    all_row = all_tones_data_start_row + i - 1;
    [br(i).PlatTone_f, br(i).PlatTone_v] = tone_avg_formula(rows(i).CSp_plat_time, tone_range, metric_names, max_tones, "CSp_plat_time", all_tones_sheet_name, all_row);
    [br(i).PlatITI_f, br(i).PlatITI_v] = tone_avg_formula(rows(i).ITI_plat_time, tone_range, metric_names, max_tones, "ITI_plat_time", all_tones_sheet_name, all_row);
    [br(i).RewTone_f, br(i).RewTone_v] = tone_avg_formula(rows(i).CSp_reward_time, tone_range, metric_names, max_tones, "CSp_reward_time", all_tones_sheet_name, all_row);
    [br(i).RewITI_f, br(i).RewITI_v] = tone_avg_formula(rows(i).ITI_reward_time, tone_range, metric_names, max_tones, "ITI_reward_time", all_tones_sheet_name, all_row);
    br(i).PlatMerged_v = mean(rows(i).Plat_Merged_PerTimeInROI(tone_range), 'omitnan');
    br(i).RewMerged_v  = mean(rows(i).Merged_PerTimeInROI(tone_range), 'omitnan');
end
%
end

%%
function day = day_from_condition(condition_name)
% New in v4 - strips the "sham_"/"tms_" prefix off a Condition name to get the shared
% "day" identifier the two groups are combined under (e.g. "sham_RetrS1" -> "RetrS1").
c = char(condition_name);
if startsWith(c, 'sham_', 'IgnoreCase', true)
    day = string(c(6:end));
elseif startsWith(c, 'tms_', 'IgnoreCase', true)
    day = string(c(5:end));
else
    day = string(c);
end
end

%%
function [num, lbl] = parse_subject(subject_name)
% New in v4 - pulls the animal number out of a session folder name (e.g.
% "DCSP_22_sham_RetrS1_SV_Apr12" -> 22, "dcsp 22") for sorting and display in the binned
% tabs. Falls back to the raw folder name if it doesn't match the expected "DCSP_NN" pattern.
% SV, September 3, 2026: I changed
% tok = regexp(char(subject_name), 'DCSP_?(\d+)', 'tokens', 'once', 'ignorecase');
% if isempty(tok)
%     num = NaN;
%     lbl = char(subject_name);
% else
%     num = str2double(tok{1});
%     lbl = sprintf('dcsp %d', num);
% end
% to this - the PVFP cohort's session folders are named "PVFP_NN_..." instead
% of "DCSP_NN_...". Matching either prefix (rather than swapping DCSP for
% PVFP outright) means this script still parses subject numbers correctly if
% it's ever re-pointed at an older DCSP-cohort dataset, per SV's choice. The
% matched prefix is echoed back in "lbl" (lowercased, e.g. "pvfp 30") instead
% of being hardcoded, so display text and the exclusion dialog automatically
% say the right cohort name too - see scan_available_subjects below.
tok = regexp(char(subject_name), '(DCSP|PVFP)_?(\d+)', 'tokens', 'once', 'ignorecase');
if isempty(tok)
    num = NaN;
    lbl = char(subject_name);
else
    num = str2double(tok{2});
    lbl = sprintf('%s %d', lower(tok{1}), num);
end
end


%% ====================================================================
%  SV, September 25, 2026: the figure report PDF, built from SV's hand-drawn
%  spec (Wilke+DeNardo Notes.pdf, 3 pages).
%
%  These are local functions of this script on purpose rather than a separate
%  file: they call sig_stars / unpaired_compare / paired_compare /
%  parse_subject / day_from_condition / classify_group directly, so the stars
%  printed on a figure and the p-values in the stats tab come from one
%  implementation and cannot drift apart.
%
%  LAYOUT. US Letter portrait, 8.5 x 11 in. report_place flows rows down the
%  page and starts a new page when the next row will not fit.
%
%  SV's decisions, 2026-09-25:
%    stars  - one Sham-vs-TMS unpaired test PER TONE BIN.
%    traces - every animal drawn and named in the legend.
%    days   - every selected day, Hab included.
%
%  SV, September 25, 2026 (second round): I changed eight things after SV
%  reviewed the first real report (pma_report_20260925_151127.pdf):
%   1) All non-data text is black now. Only TMS labels stay red, so the red
%      in the document means one thing - this is the TMS group - instead of
%      also meaning "this is a title". TMS tick labels and legend entries get
%      their color through TeX markup (report_tms_markup) because a single
%      axis cannot color its tick labels individually any other way.
%   2) Shocks Avoided is a proportion, so its y-axis is pinned to [0 1]
%      rather than autoscaled (metric.ylim).
%   3) Each animal now gets a unique line style AND marker pair rather than
%      cycling three styles, so a trace is identifiable at a glance.
%   4) The shock bolt was sitting on the x-axis; it is smaller and now sits
%      above the data, clear of both the plot and the stars.
%   5) The arena/speaker glyphs were wrong, so they are gone. Each panel that
%      had one now carries an empty square placeholder for a BioRender graphic
%      SV will supply - see report_placeholder_box.
%   6) Panels were badly compressed in x. Rows now carry ONE timecourse plus
%      ONE summary instead of two of each, roughly doubling every panel's
%      width. The report is longer as a result, which SV preferred to squeezed
%      axes ("i can just zoom in on my own").
%   7) Proportion of Time in Zone and Zone Visits each start on a fresh page.
%   8) The Tones-ON-v-OFF and Platform-v-Reward blocks describe the same day,
%      so each day's blocks now sit under one shaded day banner naming the day
%      and what the group contains.
%  ====================================================================
function write_pma_report_pdf(rows, out_dir, day_order, bin_ranges, bin_labels, sections)

pdf_filename = fullfile(out_dir, sprintf('pma_report_%s.pdf', datestr(now, 'yyyymmdd_HHMMSS'))); %#ok<TNOW1,DATST>

present = unique(arrayfun(@(r) day_from_condition(r.Condition), rows), 'stable');
days = strings(0);
for k = 1:numel(day_order)
    if any(present == day_order(k)), days(end+1) = day_order(k); end %#ok<AGROW>
end
for k = 1:numel(present)
    if ~any(days == present(k)), days(end+1) = present(k); end %#ok<AGROW>
end
if isempty(days)
    warning('write_pma_report_pdf: no days to plot - PDF not created.');
    return
end

% Drop any tone bin no session reaches, per SV: "If there are no 7-9, omit
% this from the plot."
max_t = 0;
for i = 1:numel(rows)
    if ~isempty(rows(i).N_tones) && ~isnan(rows(i).N_tones)
        max_t = max(max_t, rows(i).N_tones);
    end
end
keep_bin = true(1, numel(bin_ranges));
for b = 1:numel(bin_ranges)
    keep_bin(b) = (max_t == 0) || (min(bin_ranges{b}) <= max_t);
end
bin_ranges = bin_ranges(keep_bin);
bin_labels = bin_labels(keep_bin);
tc_bins = report_exclusive_bins(bin_ranges);

S = report_state(pdf_filename);
% SV, September 28, 2026: I added - the design sizes the stats page quotes.
% It used to say "n = 7 per group" and "12 tests on a 6-day, 2-bin panel"
% whatever the data were (the DCSP run is 6 v 4 animals, PVFP 3 v 3).
S.n_days = numel(days);
S.n_bins = numel(tc_bins);
for g = ["sham", "tms"]
    subj = strings(0);
    for i = 1:numel(rows)
        if classify_group(rows(i).Condition) == g
            [num, lbl] = parse_subject(rows(i).Subject);
            if isnan(num), subj(end+1) = string(lbl); else, subj(end+1) = string(num); end %#ok<AGROW>
        end
    end
    S.(['n_' char(g)]) = numel(unique(subj));
end

%% ---- Section 1: Shocks Avoided
if sections.shocks
    S = report_heading(S, 'Shocks Avoided', false);
    % Icon per SV's sketch for this panel: speaker-with-X over the arena with
    % the mouse on the platform (PMA_1). Flagged to SV - shocks are avoided
    % DURING the tone, so PMA_2 may have been meant.
    m = report_metric('Prop. Shocks Avoided', @(r) r.Plat_success_vector, [0 1], 'mean', 'toneonly', 'on');
    % SV, September 28, 2026: I added - habituation days are never drawn here,
    % per SV: "there are no shocks on these days". They only ever showed up as
    % empty columns (the metric is NaN on Hab), so this is the same data on a
    % narrower, readable axis. The mixed model sees the same shock days.
    shock_days = days(~startsWith(days, 'Hab', 'IgnoreCase', true));
    if isempty(shock_days)
        warning('write_pma_report_pdf: no non-habituation days selected - Shocks Avoided skipped.');
    else
        S = report_metric_row(S, rows, shock_days, tc_bins, bin_labels, m, ...
            'Shocks Avoided Timecourse', 'Shocks Avoided Summary');
    end
end

%% ---- Section 2: Locomotion
if sections.locomotion
    S = report_heading(S, 'Locomotion', false);
    loco = { ...
        'Track Length (cm)', @(r) r.Loco_iti_dist, @(r) r.Loco_tone_dist; ...
        'Velocity (cm/s)',   @(r) report_safe_div(r.Loco_iti_dist,  r.Loco_iti_dur), ...
                             @(r) report_safe_div(r.Loco_tone_dist, r.Loco_tone_dur)};
    loco_agg = {'sum', 'mean'};   % distance totals per day; velocity is a rate
    % SV, September 28, 2026: I added - all four VELOCITY panels (tone OFF/ON,
    % timecourse and summary) share one y-axis, per SV. Velocity summarises as
    % a mean, so a summary bar can never exceed the largest per-bin value and
    % one scale honestly fits every panel. Track length keeps separate scales:
    % its summary is a day TOTAL, an order of magnitude above its timecourse.
    loco_lim = {[], report_shared_ylim(rows, {loco{2,2}, loco{2,3}}, tc_bins)};
    for k = 1:size(loco,1)
        S = report_onoff_rows(S, rows, days, tc_bins, bin_labels, ...
            loco{k,1}, loco{k,2}, loco{k,3}, loco_lim{k}, loco_agg{k}, 'toneonly');
    end
end

%% ---- Section 3: Proportion of Time in Zone  (starts a new page, SV item 7)
if sections.zone_time
    S = report_heading(S, 'Proportion of Time in Zone', true);
    % SV, September 28, 2026: I added - the four timecourse+summary rows fit on
    % the heading's page (see metric_scale in report_metric_row).
    S.metric_scale = 0.87;
    S = report_onoff_rows(S, rows, days, tc_bins, bin_labels, ...
        'Prop. Time in Reward', @(r) r.ITI_reward_time, @(r) r.CSp_reward_time, [0 1], 'mean', 'reward');
    S = report_onoff_rows(S, rows, days, tc_bins, bin_labels, ...
        'Prop. Time on Platform', @(r) r.ITI_plat_time, @(r) r.CSp_plat_time, [0 1], 'mean', 'platform');
    S = report_zone_blocks(S, rows, days, bin_ranges, bin_labels, 'Prop. Time in Zone', ...
        @(r) r.CSp_plat_time,   @(r) r.ITI_plat_time, ...
        @(r) r.CSp_reward_time, @(r) r.ITI_reward_time);
    S.metric_scale = 1;
end

%% ---- Section 4: Zone Visits  (starts a new page, SV item 7)
if sections.zone_visits
    S = report_heading(S, 'Zone Visits', true);
    S.metric_scale = 0.87;   % SV, September 28, 2026: same one-page fit as Time in Zone
    S = report_onoff_rows(S, rows, days, tc_bins, bin_labels, ...
        'Reward Zone Visits', @(r) r.Reward_iti_visit_vec, @(r) r.Reward_tone_visit_vec, [], 'sum', 'reward');
    S = report_onoff_rows(S, rows, days, tc_bins, bin_labels, ...
        'Platform Visits', @(r) r.Plat_iti_visit_vec, @(r) r.Plat_tone_visit_vec, [], 'sum', 'platform');
    S = report_zone_blocks(S, rows, days, bin_ranges, bin_labels, 'Zone Visits', ...
        @(r) r.Plat_tone_visit_vec,   @(r) r.Plat_iti_visit_vec, ...
        @(r) r.Reward_tone_visit_vec, @(r) r.Reward_iti_visit_vec);
    S.metric_scale = 1;
end

% SV, September 27, 2026: the last page explains every test in the document.
try
    S = report_stats_page(S);
catch ME
    warning('write_pma_report_pdf: stats page failed: %s', ME.message);
end

report_finish(S);
fprintf('Figure report written: %s\n', pdf_filename);
end

%% --------------------------------------------------------------- state
function S = report_state(pdf_filename)
S = struct('pdf', pdf_filename, 'fig', [], 'y', 0, 'wrote_any', false, ...
    'margin', 0.055, 'top', 0.965, 'bottom', 0.045, 'metric_scale', 1);
S.stats = struct('ok', {}, 'note', {}, 'p_group', {}, 'p_inter', {}, ...
    'n_animals', {}, 'n_obs', {}, 'formula', {}, 'name', {});
end

function S = report_new_page(S)
S = report_flush(S);
S.fig = figure('Units', 'inches', 'Position', [0 0 8.5 11], 'Color', 'w', ...
    'Visible', 'off', 'PaperUnits', 'inches', 'PaperSize', [8.5 11], ...
    'PaperPosition', [0 0 8.5 11]);

% exportgraphics is the only way to APPEND a page, but it crops the output to
% the bounding box of the drawn content rather than honouring PaperSize - a
% sparse page came out 7.1 x 9.1 in instead of Letter. This invisible
% full-page rectangle (white on white) makes the content box the whole page,
% so every page lands at exactly 8.5 x 11 in. print -dpdf would size correctly
% on its own but cannot append, which is why it is not used here.
annotation(S.fig, 'rectangle', [0 0 1 1], 'Color', 'w', 'FaceColor', 'none');

S.y = S.top;
end

function S = report_flush(S)
if ~isempty(S.fig) && isgraphics(S.fig)
    try
        exportgraphics(S.fig, S.pdf, 'Append', S.wrote_any, 'ContentType', 'vector');
        S.wrote_any = true;
    catch ME
        warning('write_pma_report_pdf: could not write a page: %s', ME.message);
    end
    close(S.fig);
    S.fig = [];
end
end

function report_finish(S)
S = report_flush(S); %#ok<NASGU>
end

function [S, y0] = report_row(S, h)
if isempty(S.fig) || ~isgraphics(S.fig) || (S.y - h) < S.bottom
    S = report_new_page(S);
end
y0 = S.y - h;
S.y = y0;
end

function S = report_heading(S, txt, force_new_page)
if force_new_page || isempty(S.fig) || ~isgraphics(S.fig)
    S = report_new_page(S);
end
[S, y0] = report_row(S, 0.040);
annotation(S.fig, 'textbox', [S.margin y0 0.9 0.036], 'String', txt, ...
    'FontSize', 15, 'FontWeight', 'bold', 'Color', 'k', ...
    'EdgeColor', 'none', 'VerticalAlignment', 'middle');
S.y = S.y - 0.006;
end

function ax = report_axes(S, x, y, w, h)
ax = axes(S.fig, 'Position', [x y w h]); %#ok<LAXES>
set(ax, 'FontSize', 6.5, 'Box', 'off', 'TickDir', 'out', 'LineWidth', 0.5, ...
    'XColor', 'k', 'YColor', 'k');
hold(ax, 'on');
end

%% ------------------------------------------------------------- metrics
function m = report_metric(ylabel_txt, fn, ylim_fixed, agg, zone, tone_state)
% SV, September 27, 2026: I added "agg", after SV asked what the locomotion
% summary bar actually shows: "each point should be that animals entire summed
% tracklength across all tones/iti's on that day". It was the mean of the
% per-bin means - a per-window average, not a day total. Additive quantities
% (distance, visit counts) now summarise as 'sum'; rates and proportions stay
% 'mean', where a total would be meaningless. The TIMECOURSE is unchanged: it
% plots per-bin means under either setting.
if nargin < 4 || isempty(agg), agg = 'mean'; end
if nargin < 5, zone = 'none'; end
if nargin < 6, tone_state = ''; end
m = struct('ylabel', ylabel_txt, 'fn', fn, 'ylim', ylim_fixed, 'agg', agg, ...
    'zone', zone, 'tone', tone_state);
end

% SV, September 28, 2026: I added - one [0 top] y-range covering every
% per-animal, per-bin value of several metrics (e.g. velocity tone OFF and ON),
% so panels that must be compared read on the same scale. top is 5 "nice"
% steps (1/2/2.5/5/10 x 10^k), matching the 6 ticks a fixed range gets in
% report_panel_timecourse/summary.
function lim = report_shared_ylim(rows, fns, bins)
vals = [];
for k = 1:numel(fns)
    O = report_collect(rows, fns{k}, bins);
    if ~isempty(O), vals = [vals, O.val]; end %#ok<AGROW>
end
vals = vals(isfinite(vals));
if isempty(vals) || max(vals) <= 0
    lim = [];
    return
end
need = 1.05 * max(vals) / 5;
mag = 10^floor(log10(need));
steps = [1 2 2.5 5 10] * mag;
lim = [0, 5 * steps(find(steps >= need, 1))];
end

function v = report_safe_div(num, den)
num = double(num); den = double(den);
v = nan(size(num));
ok = ~isnan(num) & ~isnan(den) & den > 0;
v(ok) = num(ok) ./ den(ok);
end

function out = report_exclusive_bins(bin_ranges)
seen = [];
keep = false(1, numel(bin_ranges));
for b = 1:numel(bin_ranges)
    if isempty(intersect(bin_ranges{b}, seen))
        keep(b) = true;
        seen = [seen bin_ranges{b}]; %#ok<AGROW>
    end
end
out = bin_ranges(keep);
end

function O = report_collect(rows, fn, bins)
O = struct('day', {}, 'group', {}, 'subj', {}, 'lbl', {}, 'val', {}, 'total', {});
for i = 1:numel(rows)
    try
        v = double(fn(rows(i)));
    catch
        continue
    end
    if isempty(v), continue; end
    b = nan(1, numel(bins));
    for k = 1:numel(bins)
        idx = bins{k};
        idx = idx(idx <= numel(v));
        if isempty(idx), continue; end
        x = v(idx);
        x = x(~isnan(x));
        if ~isempty(x), b(k) = mean(x); end
    end
    if all(isnan(b)), continue; end
    % Day total over every tone/ITI window the bins cover - what the summary
    % uses for additive metrics (see "agg" in report_metric).
    cover = unique([bins{:}]);
    cover = cover(cover <= numel(v));
    cv = v(cover);
    tot = sum(cv(~isnan(cv)));
    [num, lbl] = parse_subject(rows(i).Subject);
    O(end+1) = struct('day', day_from_condition(rows(i).Condition), ...
        'group', classify_group(rows(i).Condition), 'subj', num, ...
        'lbl', string(lbl), 'val', b, 'total', tot); %#ok<AGROW>
end
end

function c = report_color(group)
% SV, September 28, 2026: I changed the hardcoded red/grey to the color
% picked at startup (see group_color).
c = group_color(group) / 255;
end

% SV, September 28, 2026: I added - TeX color markup for a group, shared by
% report_tms_markup and report_legend_subject.
function s = report_color_tex(group)
c = report_color(group);
s = sprintf('\\color[rgb]{%.3f,%.3f,%.3f}', c(1), c(2), c(3));
end

% TMS is the only thing still allowed to be red (SV item 1). Tick labels and
% legend entries cannot be colored per-entry any other way, so they carry
% TeX color markup instead.
function t = report_tms_markup(txt, group)
% SV, September 25, 2026: I changed the Sham color from black to grey, so the
% two group names match the colors their data is drawn in (grey Sham, red Tms).
t = ['\bf' report_color_tex(group) char(txt)];
end

% SV, September 25, 2026: I added - group names read as words now ("Sham",
% "Tms") and are bolded instead of being shouted in full caps, per SV.
function t = report_group_label(g)
if g == "tms"
    t = 'Tms';
else
    t = 'Sham';
end
end

% Each animal gets its own (line style, marker) pair so a trace is
% identifiable (SV item 3). Four styles x nine markers is unique well past
% the seven animals per group these cohorts run.
function [ls, mk] = report_subject_style(si)
styles  = {'-', '--', ':', '-.'};
markers = {'o', 's', '^', 'd', 'v', '>', '<', 'p', 'h'};
ls = styles{mod(si-1, numel(styles)) + 1};
mk = markers{mod(si-1, numel(markers)) + 1};
end

%% ------------------------------------------------- rows of whole panels
% One timecourse + one summary per row. Two of each per row (the first
% version) squeezed both badly - see item 6 in the changelog above.
function S = report_metric_row(S, rows, days, bins, bin_labels, m, t1, t2)
% SV, September 28, 2026: I changed the heights below to scale with
% S.metric_scale (1 everywhere except the two zone sections, 0.87 there, so
% their heading + four rows fit one Letter page). Widths are unchanged.
sc = 1; if isfield(S, 'metric_scale') && ~isempty(S.metric_scale), sc = S.metric_scale; end
h = 0.150*sc;
% SV, September 27, 2026: reserve enough height for the LIFTED title as well
% as the panel - at 1.24x the axes height the title was landing in the row
% above. Row = axes offset + axes + title lift + the title's own line.
[S, y0] = report_row(S, h + 0.094*sc);
% SV, September 27, 2026: I narrowed both panels and widened the legend
% gutter. The legend was running into the summary plot on its right; there is
% now white space on both sides of it (SV item 5).
wt = 0.40; lg = 0.115; ws = 0.215;
O = report_collect(rows, m.fn, bins);

% One mixed model per metric, reported on the stats page at the end.
R = report_fit_lme(O, days, m);
R.name = t1;
if isfield(S, 'stats'), S.stats(end+1) = R; else, S.stats = R; end

report_panel_timecourse(report_axes(S, S.margin, y0+0.038*sc, wt, h-0.014*sc), ...
    O, days, bin_labels, m, t1);
report_panel_summary(report_axes(S, S.margin+wt+lg, y0+0.038*sc, ws, h-0.014*sc), ...
    O, days, m, t2);
end

function S = report_onoff_rows(S, rows, days, bins, bin_labels, ylab, fn_off, fn_on, ylim_fixed, agg, zone)
if nargin < 10 || isempty(agg), agg = 'mean'; end
if nargin < 11, zone = 'none'; end
S = report_metric_row(S, rows, days, bins, bin_labels, ...
    report_metric(ylab, fn_off, ylim_fixed, agg, zone, 'off'), ...
    [ylab ' - Tone OFF:  Timecourse'], [ylab ' - Tone OFF:  Summary']);
S = report_metric_row(S, rows, days, bins, bin_labels, ...
    report_metric(ylab, fn_on, ylim_fixed, agg, zone, 'on'), ...
    [ylab ' - Tone ON:  Timecourse'], [ylab ' - Tone ON:  Summary']);
end

%% ------------------------------------------------------ timecourse panel
function report_panel_timecourse(ax, O, days, bin_labels, m, ttl)
if isempty(O), report_blank(ax, ttl); return; end
nb = min(numel(bin_labels), numel(O(1).val));
if nb == 0, report_blank(ax, ttl); return; end

% SV, September 27, 2026: I reduced the gap between day blocks from a full
% x-slot to 0.35 of one, per SV: "you can reduce the space between 4-6 on the
% left side and 1-3 on the right side to about 1/3 what you have there".
block_gap = 0.35;

xt = []; xtl = strings(0); blocks = zeros(numel(days), 2); pos = 0;
for d = 1:numel(days)
    blocks(d,1) = pos + 1;
    for b = 1:nb
        pos = pos + 1;
        xt(end+1) = pos; %#ok<AGROW>
        xtl(end+1) = string(strrep(char(bin_labels(b)), 'Tones ', '')); %#ok<AGROW>
    end
    blocks(d,2) = pos;
    pos = pos + block_gap;
end

all_y = [];
lh = gobjects(0); ll = strings(0);
mean_handles = gobjects(0);   % raised above the individual traces at the end
for g = ["sham", "tms"]
    col = report_color(g);
    gsel = ([O.group] == g);
    subs = unique([O(gsel).subj]);
    subs = subs(~isnan(subs));

    mean_h = gobjects(0);
    for d = 1:numel(days)
        mu = nan(1, nb); se = nan(1, nb);
        for b = 1:nb
            v = arrayfun(@(o) o.val(b), O(gsel & [O.day] == days(d)));
            v = v(~isnan(v));
            if ~isempty(v)
                mu(b) = mean(v);
                se(b) = std(v) / max(sqrt(numel(v)), 1);
            end
        end
        idx = blocks(d,1):blocks(d,2);
        ok = ~isnan(mu);
        if sum(ok) > 1
            fill(ax, [idx(ok) fliplr(idx(ok))], [mu(ok)+se(ok) fliplr(mu(ok)-se(ok))], col, ...
                'FaceAlpha', 0.14, 'EdgeColor', 'none', 'HandleVisibility', 'off');
        end
        if any(ok)
            hM = plot(ax, idx(ok), mu(ok), '-o', 'Color', col, 'MarkerFaceColor', col, ...
                'MarkerSize', 2.6, 'LineWidth', 1.1, 'HandleVisibility', 'off');
            mean_handles(end+1) = hM; %#ok<AGROW>
            if isempty(mean_h), mean_h = hM; end
            all_y = [all_y, mu(ok)+se(ok), mu(ok)-se(ok)]; %#ok<AGROW>
        end
    end
    if ~isempty(mean_h)
        lh(end+1) = mean_h; %#ok<AGROW>
        ll(end+1) = string(report_legend_group(sprintf('%s (n=%d)', report_group_label(g), numel(subs)), g)); %#ok<AGROW>
    end

    for si = 1:numel(subs)
        yy = nan(1, numel(xt)); k = 0; lbl = "";
        for d = 1:numel(days)
            s1 = find(gsel & [O.day] == days(d) & [O.subj] == subs(si), 1);
            for b = 1:nb
                k = k + 1;
                if ~isempty(s1), yy(k) = O(s1).val(b); end
            end
            if ~isempty(s1), lbl = O(s1).lbl; end
        end
        [ls, mk] = report_subject_style(si);
        hA = gobjects(0);
        for d = 1:numel(days)
            idx = blocks(d,1):blocks(d,2);
            kk = (d-1)*nb + (1:nb);
            if all(isnan(yy(kk))), continue; end
            % SV, September 27, 2026: individual mice at 25% strength - line
            % AND marker. A blended color is used rather than an alpha value
            % because alpha applies to a Line's stroke but not to its markers,
            % which is why the points still looked full-strength before.
            % SV, September 27, 2026: individual animals are lines only now -
            % SV preferred the cleaner look without their dots. The line STYLE
            % still identifies each animal, and the legend swatch still shows
            % its marker, so they remain distinguishable.
            faint = report_tint(col);
            h1 = plot(ax, idx, yy(kk), 'LineStyle', ls, ...
                'Color', faint, 'LineWidth', 0.35, 'Marker', 'none', ...
                'HandleVisibility', 'off');
            if isempty(hA), hA = h1; end
        end
        all_y = [all_y, yy(~isnan(yy))]; %#ok<AGROW>
        if ~isempty(hA)
            lh(end+1) = hA; %#ok<AGROW>
            if strlength(lbl) == 0, lbl = string(sprintf('#%d', subs(si))); end
            ll(end+1) = string(report_legend_subject(lbl, g)); %#ok<AGROW>
        end
    end
end

if isempty(all_y), all_y = [0 1]; end
ylo = min(all_y); yhi = max(all_y);
if ~isfinite(ylo) || ~isfinite(yhi) || yhi <= ylo, ylo = 0; yhi = 1; end

% SV, September 27, 2026: I added headroom above the data. A proportion can sit
% right on 1.0, and the stars / "Tones ON" style annotations were then drawn on
% top of the top gridline or into the title. The axis now extends past the data
% but the TICKS still stop at the real maximum, so the scale reads unchanged.
% SV, September 27, 2026: I changed this so the y-axis RULER stops at the real
% maximum - SV: "i like when the y-axis ends at 1 because there is no high
% value actually possible. i just meant you can have an open space there". The
% stars are drawn ABOVE the axes box with clipping off, so they occupy the gap
% between the axis top and the title instead of pushing the axis past 1.
if ~isempty(m.ylim)
    ylo = m.ylim(1); yhi = m.ylim(2);
    ylim(ax, [ylo, yhi]);
    yticks(ax, linspace(ylo, yhi, 6));
else
    span = yhi - ylo;
    % SV, September 28, 2026: I changed
    % ylo = min(0, ylo);
    % to this - ylo includes mean - SE, which dips below 0 for a small mean
    % with a large SE and dropped the floor to a negative tick on count
    % metrics that cannot be negative. The floor is 0 whenever every value is.
    all_vals = [O.val];
    if all(all_vals(~isnan(all_vals)) >= 0), ylo = 0; else, ylo = min(0, ylo); end
    yhi = yhi + 0.10*span;
    ylim(ax, [ylo, yhi]);
end
% Order matters: snap the ticks FIRST, then pad. Padding first and snapping
% afterwards made the snap extend the ticks down to cover the pad, which is how
% the locomotion axes ended up starting at -100.
if isempty(m.ylim), report_snap_ylim(ax); end   % axis must end ON a tick
report_pad_bottom(ax);   % SV: floor sits just under 0 so points at 0 are readable
yr_full = ylim(ax);
star_y = yr_full(2) + 0.06*diff(yr_full);

% SV, September 27, 2026: I changed the panel stars in two ways after SV asked
% whether the statistics made sense.
%   1) The displayed p-value is the Wilcoxon RANK-SUM, not the Welch t-test.
%      With 7 animals per group, and with proportions and counts as the data,
%      the t-test's normality assumption is not supportable; a rank test needs
%      no such assumption. (unpaired_compare already computed both.)
%   2) Every test in the panel is Holm-corrected TOGETHER. A 6-day, 2-bin panel
%      runs 12 comparisons; uncorrected, about one in twenty lands under 0.05
%      on noise alone, and the previous version corrected none of them
%      (run_unpaired_comparison's p_t_holm is a no-op left over from the
%      workbook, where each chart ran a single comparison).
% See report_fit_lme for the test that actually respects the repeated measures.
p_raw = nan(numel(days), nb);
for d = 1:numel(days)
    for b = 1:nb
        vs = arrayfun(@(o) o.val(b), O(([O.group] == "sham") & [O.day] == days(d)));
        vt = arrayfun(@(o) o.val(b), O(([O.group] == "tms")  & [O.day] == days(d)));
        [~, p_w] = unpaired_compare(vs, vt);
        p_raw(d, b) = p_w;
    end
end
p_adj = nan(size(p_raw));
ok_p = ~isnan(p_raw);
if any(ok_p(:))
    p_adj(ok_p) = holm_adjust(p_raw(ok_p));
end
for d = 1:numel(days)
    for b = 1:nb
        if isnan(p_adj(d,b)), continue; end
        star = sig_stars(p_adj(d,b));
        if strcmp(star, 'n.s.') || isempty(star), continue; end
        text(ax, blocks(d,1)+b-1, star_y, star, 'HorizontalAlignment', 'center', ...
            'FontSize', 7, 'Color', 'k', 'Clipping', 'off');
    end
end

set(ax, 'XTick', xt, 'XTickLabel', cellstr(xtl), 'XLim', [0.4 pos-block_gap+0.6], ...
    'FontSize', 6.5, 'XTickLabelRotation', 0);
% SV, September 28, 2026: I added - the bin tick labels ("1-3", "4-6", "7-9")
% ran into each other on a 7-day x 3-bin PVFP axis. Size them from the room
% each tick actually has: ~0.55 em per character, and 85% of the tick spacing.
% A 6-day x 2-bin DCSP axis has room for the old 6.5 pt, so it is unchanged.
pt_per_unit = (ax.Position(3) * 8.5 * 72) / diff(xlim(ax));
ax.XAxis.FontSize = min(6.5, 0.85 * pt_per_unit / (0.55 * max(strlength(xtl))));
ylabel(ax, m.ylabel, 'FontSize', 7.5, 'Color', 'k');
title(ax, ttl, 'FontSize', 8, 'FontWeight', 'normal', 'Color', 'k');
report_lift_title(ax, 1.24);

% SV, September 27, 2026: day names sit further below the 1-3 / 4-6 tick labels
% than before (SV: "leave more room between the 'TrainD1s1' label and the x-axis
% 1-3 and 4-6 labels") and are never slanted - the font shrinks instead.
day_fs = 7;
if numel(days) > 4, day_fs = 6; end
if numel(days) > 8, day_fs = 5; end
for d = 1:numel(days)
    xc = mean(blocks(d,:));
    th = text(ax, xc, yr_full(1) - 0.20*diff(yr_full), char(days(d)), ...
        'HorizontalAlignment', 'center', 'FontSize', day_fs, 'Color', 'k', ...
        'Clipping', 'off', 'Rotation', 0);
    % SV, September 27, 2026: the bolt used to float above the data. It now sits
    % immediately after the day name like an emoji in running text, one space
    % along, measured from the label's own extent so it tracks any font change.
    if contains(char(days(d)), 'Train', 'IgnoreCase', true)
        ext = th.Extent;   % [x y w h] in data units
        % The gap after the label must be measured in X units. Taking it from
        % ext(4) (a Y quantity) put the bolt ~8 x-units to the right on the
        % 0-800 cm locomotion axis, i.e. outside the plot entirely.
        xr_lbl = xlim(ax);
        report_bolt(ax, ext(1) + ext(3) + 0.018*diff(xr_lbl), ext(2) + ext(4)/2, ext(4)*0.85);
    end
end

% SV, September 27, 2026: the group mean is the point of the plot, so it is
% lifted above the faint individual traces that were drawn after it.
for hm = 1:numel(mean_handles)
    uistack(mean_handles(hm), 'top');
end

icon_name = report_epoch_icon(m.zone, m.tone);
if isempty(icon_name)
    report_placeholder_box(ax);
else
    report_icon(ax, icon_name);
end

if ~isempty(lh)
    p0 = ax.Position;
    lg = legend(ax, lh, cellstr(ll), 'FontSize', 5, 'Box', 'off', ...
        'AutoUpdate', 'off', 'Interpreter', 'tex', 'TextColor', 'k');
    lg.ItemTokenSize = [11 5];
    ax.Position = p0;
    lg.Position = [p0(1)+p0(3)+0.010, ...
        max(p0(2), p0(2) + p0(4)/2 - 0.008*numel(ll)), ...
        0.062, min(p0(4), 0.0150*numel(ll))];
end
end

function report_panel_summary(ax, O, days, m, ttl)
if isempty(O), report_blank(ax, ttl); return; end

% SV, September 27, 2026: this is now a two-pass panel. Everything is measured
% first so the y-limit can be chosen before anything is drawn:
%   - SV: "the max y-axis value should be 30 since there is only 1 dot between
%     30 and 60" - a lone outlier used to push the axis out and squash every
%     bar into the bottom third. The top is now set from the bulk of the data
%     (90th percentile of the individual animals, and every bar's mean+SEM),
%     NOT the single largest point.
%   - A point above that cap is NOT dropped. It is drawn pinned to the top of
%     the axis as a hollow triangle, so "there is a value off the top of this
%     axis" stays visible and nothing is silently hidden.
%   - SV: the y-intercept sits a little below zero so points sitting exactly
%     at 0 are readable instead of being buried in the x-axis.

vals = cell(numel(days), 2);
mus  = nan(numel(days), 2);
ses  = nan(numel(days), 2);
groups = ["sham", "tms"];
for d = 1:numel(days)
    for gi = 1:2
        sel_o = O(([O.group] == groups(gi)) & [O.day] == days(d));
        if isfield(m, 'agg') && strcmp(m.agg, 'sum')
            v = arrayfun(@(o) o.total, sel_o);
        else
            v = arrayfun(@(o) mean(o.val, 'omitnan'), sel_o);
        end
        v = v(~isnan(v));
        vals{d, gi} = v;
        if ~isempty(v)
            mus(d, gi) = mean(v);
            ses(d, gi) = std(v) / max(sqrt(numel(v)), 1);
        end
    end
end

all_pts = [vals{:}];
if ~isempty(m.ylim)
    y_hi = m.ylim(2);
else
    bar_top = max(mus(:) + ses(:));
    if isempty(all_pts)
        y_hi = 1;
    else
        bulk = prctile(all_pts, 90);
        y_hi = max([bar_top, bulk * 1.15]);
    end
    if ~isfinite(y_hi) || y_hi <= 0, y_hi = 1; end
end

pos = 0; xt = []; xtl = strings(0); centres = zeros(1, numel(days));
for d = 1:numel(days)
    first = pos + 1;
    for gi = 1:2
        g = groups(gi);
        pos = pos + 1;
        col = report_color(g);
        v = vals{d, gi};
        if ~isempty(v)
            hb = bar(ax, pos, mus(d,gi), 0.72, 'FaceColor', report_tint(col), 'EdgeColor', 'none');
            report_hide_baseline(hb);
            errorbar(ax, pos, mus(d,gi), ses(d,gi), 'Color', col, 'LineWidth', 0.8, 'CapSize', 3);
            jit = pos + 0.11*randn(1, numel(v));
            inr = v <= y_hi;
            plot(ax, jit(inr), v(inr), 'o', 'MarkerSize', 1.5, ...
                'MarkerFaceColor', 'none', 'MarkerEdgeColor', col, 'LineWidth', 0.4);
            if any(~inr)   % off the top: pinned, not dropped
                plot(ax, jit(~inr), repmat(y_hi, 1, sum(~inr)), '^', 'MarkerSize', 2.2, ...
                    'MarkerFaceColor', 'none', 'MarkerEdgeColor', col, 'LineWidth', 0.4, ...
                    'Clipping', 'off');
            end
        end
        xt(end+1) = pos; %#ok<AGROW>
        xtl(end+1) = string(report_tms_markup(report_group_label(g), g)); %#ok<AGROW>
    end
    centres(d) = (first + pos)/2;
    pos = pos + 0.9;
end

set(ax, 'XTick', xt, 'XTickLabel', cellstr(xtl), 'XLim', [0.3 pos-0.4], ...
    'FontSize', 4.8, 'TickLabelInterpreter', 'tex');
ax.XTickLabelRotation = report_tick_rotation(ax, xtl, 4.8);

ylim(ax, [0 y_hi]);
if ~isempty(m.ylim)
    yticks(ax, linspace(m.ylim(1), m.ylim(2), 6));
else
    report_snap_ylim(ax);
end
report_pad_bottom(ax);

title(ax, ttl, 'FontSize', 8, 'FontWeight', 'normal', 'Color', 'k');
report_lift_title(ax, 1.22);
yr = ylim(ax);
day_fs = 6.5;
if numel(days) > 4, day_fs = 4.4; end
if numel(days) > 8, day_fs = 3.8; end
drop = 0.13; if ax.XTickLabelRotation > 0, drop = 0.21; end
for d = 1:numel(days)
    text(ax, centres(d), yr(1) - drop*diff(yr), char(days(d)), ...
        'HorizontalAlignment', 'center', 'FontSize', day_fs, 'Color', 'k', ...
        'Clipping', 'off', 'Rotation', 0);
end
end

%%
function report_hide_baseline(hb)
% SV, September 27, 2026: I added - bar() draws a baseline at y = 0. With the
% axis floor moved below zero that line reads as a second x-axis floating above
% the real one, which SV asked to remove. The axis ruler stays; only the bar's
% own baseline is hidden.
try
    bl = get(hb, 'BaseLine');
    if ~isempty(bl) && isgraphics(bl)
        set(bl, 'Visible', 'off');
    end
catch
end
end

%%
function report_pad_bottom(ax)
% SV, September 27, 2026: I added - drop the y-intercept slightly below zero so
% a bar or point sitting exactly at 0 is readable instead of being swallowed by
% the x-axis. Only the LIMIT moves; the lowest tick stays at 0, so the scale
% still reads correctly. Not used on the reward preference panels, which are
% centred on zero and have no floor.
yl = ylim(ax);
if abs(yl(1)) > 1e-9, return; end          % only when the axis floor is zero
% SV, September 27, 2026: halved (0.045 -> 0.022) - the first version left far
% too much air under the bars.
ylim(ax, [-0.022*diff(yl), yl(2)]);
end

function S = report_zone_blocks(S, rows, days, bin_ranges, bin_labels, ylab, ...
    plat_on, plat_off, rew_on, rew_off)
% SV, September 27, 2026 (second pass): the tone-bin panels are now a true
% scale copy of the aggregate - reduced in BOTH x and y by the same factor -
% rather than just being squeezed narrower at full height, which is what made
% them look like different plots. They share a baseline with the aggregate.
% Preference panels are much skinnier, per SV.

nb = numel(bin_ranges);
order = [nb, 1:nb-1];              % aggregate first, then each bin
k = 0.62;                          % bins are this fraction of the aggregate, both axes

% The next group's y-axis label and ticks hang to ITS left, so the gap between
% groups has to clear them - at 0.013 the aggregate's preference panel ran into
% the "tones 1-3" axis.
group_gap = 0.042;
inner_frac = 0.16;                 % plot -> its own preference panel (they were touching)
pref_frac  = 0.34;                 % wider now that it carries tone ON and tone OFF pairs

% Solve the aggregate plot width so the row exactly fills the page.
ratio  = 1 + inner_frac + pref_frac;
usable = 1 - 2*S.margin - (numel(order)-1)*group_gap;
Wa = usable / (ratio * (1 + k*(numel(order)-1)));
% SV, September 28, 2026: I added - text and icon scale for the whole row.
% Every font and icon size in report_panel_paired was tuned on the DCSP
% layout, three groups per row (aggregate + 1-3 + 4-6). PVFP's nine tones add
% a 7-9 group, so every panel - the aggregate included - comes out ~22%
% narrower, and at the old sizes the "Tones ON"/"Platform" labels ran into
% their icons and the data. ts is this row's aggregate width relative to the
% three-group one, so a DCSP row is drawn exactly as before (ts = 1) and a
% four-group row shrinks its text and icons with its axes.
Wa_ref = (1 - 2*S.margin - 2*group_gap) / (ratio * (1 + k*2));
ts = min(1, Wa / Wa_ref);

% SV, September 28, 2026: I changed Ha from 0.150 and the space under each
% row (bottom_pad, was 0.058) so FOUR rows - two days, each a banner plus
% two rows - fit one page, per SV: 2 x 0.030 + 4 x (0.132 + 0.078) = 0.90 of
% the 0.92 usable. The lower pad is what the halved Sham/Tms drop (see
% report_panel_paired) gave back.
Ha = 0.132;                        % aggregate plot height
bottom_pad = 0.046;
S.zone_row_h = Ha + 0.078;         % report_day_banner keeps a banner with its first row
is_prop = startsWith(ylab, 'Prop');
if is_prop, pair_ylim = [0 1]; else, pair_ylim = []; end

for d = 1:numel(days)
    S = report_day_banner(S, sprintf('%s   -   zone comparisons (Tones ON v. OFF and Platform v. Reward)', days(d)));

    for pivot = ["zone", "tone"]
        % One preference scale for the whole row, so shapes compare.
        % SV, September 27, 2026: [-1, 1] is right for a PROPORTION difference,
        % which cannot leave those bounds. It is wrong for Zone Visits, where
        % the difference is a raw count - SV: "1 and -1 are not the max and min
        % since we're now dealing with raw visits". Counts get a symmetric
        % scale measured from the data (both tone states, every bin in the
        % row), which report_snap_ylim then rounds out to whole ticks.
        if is_prop
            pref_lim = [-1 1];
        else
            pv_all = [];
            for oi = 1:numel(order)
                pv_all = [pv_all, ...
                    report_pref_values(rows, days(d), bin_ranges{order(oi)}, plat_on,  rew_on), ...
                    report_pref_values(rows, days(d), bin_ranges{order(oi)}, plat_off, rew_off)]; %#ok<AGROW>
            end
            pv_all = pv_all(~isnan(pv_all));
            if isempty(pv_all)
                pref_lim = [-1 1];
            else
                mx = max(abs(pv_all));
                if mx <= 0, mx = 1; end
                pref_lim = [-1.15*mx, 1.15*mx];
            end
        end

        [S, y0] = report_row(S, S.zone_row_h);
        base_y = y0 + bottom_pad;  % shared baseline for every panel in the row
        x = S.margin;
        for oi = 1:numel(order)
            b = order(oi);
            if oi == 1, sc = 1; else, sc = k; end
            plot_w = Wa * sc;
            inner  = plot_w * inner_frac;
            pref_w = plot_w * pref_frac;
            ph     = Ha * sc;

            axA = report_axes(S, x,                  base_y, plot_w, ph);
            axB = report_axes(S, x + plot_w + inner, base_y, pref_w, ph);
            report_panel_paired(axA, axB, rows, days(d), bin_ranges{b}, bin_labels(b), ...
                ylab, pivot, plat_on, plat_off, rew_on, rew_off, pref_lim, oi == 1, ...
                pair_ylim, sc, ts);

            x = x + plot_w + inner + pref_w + group_gap;
        end
    end
end
end

function pv = report_pref_values(rows, day, bin, plat_on, rew_on)
% SV, September 27, 2026: I added - the per-animal reward preference
% (reward - platform, during tones) for one day and tone bin. Pulled out of
% report_panel_paired so a whole row's scale can be fixed before any of its
% panels are drawn.
sel = find(arrayfun(@(r) day_from_condition(r.Condition) == day, rows));
pv = [];
for g = ["sham", "tms"]
    gs = sel(arrayfun(@(i) classify_group(rows(i).Condition) == g, sel));
    p = arrayfun(@(i) report_bin_mean(plat_on, rows(i), bin), gs);
    r = arrayfun(@(i) report_bin_mean(rew_on,  rows(i), bin), gs);
    pv = [pv, r - p]; %#ok<AGROW>
end
end

function S = report_day_banner(S, txt)
% Keep a banner with at least one row of plots under it - a banner stranded
% at the bottom of a page would label the wrong thing.
row_h = 0.194; % SV, September 28, 2026: I changed - was fixed; now the zone row height actually in use
if isfield(S, 'zone_row_h') && ~isempty(S.zone_row_h), row_h = S.zone_row_h; end
if isempty(S.fig) || ~isgraphics(S.fig) || (S.y - 0.030 - row_h) < S.bottom
    S = report_new_page(S);
end
[S, y0] = report_row(S, 0.030);
annotation(S.fig, 'rectangle', [S.margin y0+0.004 1-2*S.margin 0.022], ...
    'FaceColor', [0.90 0.90 0.90], 'EdgeColor', [0.65 0.65 0.65], 'LineWidth', 0.5);
annotation(S.fig, 'textbox', [S.margin+0.008 y0+0.004 1-2*S.margin-0.016 0.022], ...
    'String', txt, 'FontSize', 9, 'FontWeight', 'bold', 'Color', 'k', ...
    'EdgeColor', 'none', 'VerticalAlignment', 'middle');
end

function report_panel_paired(axA, axB, rows, day, bin, bin_label, ylab, pivot, ...
    plat_on, plat_off, rew_on, rew_off, pref_lim, show_pref_ylabel, pair_ylim, sc, ts)
% SV, September 28, 2026: I added ts, the row text/icon scale from
% report_zone_blocks (1 on a three-group DCSP row, ~0.78 on a four-group PVFP
% row). It multiplies every size below, AFTER the max(sc, ...) floors, so the
% floors still keep the small tone-bin panels legible relative to their
% aggregate while the whole row shrinks together.
if nargin < 17 || isempty(ts), ts = 1; end
sel = find(arrayfun(@(r) day_from_condition(r.Condition) == day, rows));
if isempty(sel), report_blank(axA, char(day)); report_blank(axB, ''); return; end

if pivot == "zone"
    half_names = ["Tones ON", "Tones OFF"];
    pair_names = ["Platform", "Reward"];
    getter = {plat_on, rew_on; plat_off, rew_off};
else
    half_names = ["Platform", "Reward"];
    pair_names = ["Tone ON", "Tone OFF"];
    getter = {plat_on, plat_off; rew_on, rew_off};
end

pos = 0; xt = []; xtl = strings(0); lab_x = []; lab_s = strings(0);
half_lo = zeros(1,2); half_hi = zeros(1,2);
pref = struct('sham', [], 'tms', []);
pref_off = struct('sham', [], 'tms', []);
for hh = 1:2
    half_lo(hh) = pos + 1;
    for g = ["sham", "tms"]
        gs = sel(arrayfun(@(i) classify_group(rows(i).Condition) == g, sel));
        col = report_color(g);
        vals = cell(1,2);
        for pp = 1:2
            vals{pp} = arrayfun(@(i) report_bin_mean(getter{hh,pp}, rows(i), bin), gs);
        end
        base = pos;
        for pp = 1:2
            pos = pos + 1;
            v = vals{pp}(~isnan(vals{pp}));
            if ~isempty(v)
                mu = mean(v); se = std(v)/max(sqrt(numel(v)),1);
                hbA = bar(axA, pos, mu, 0.72, 'FaceColor', report_tint(col), 'EdgeColor', 'none');
                report_hide_baseline(hbA);
                errorbar(axA, pos, mu, se, 'Color', col, 'LineWidth', 0.7, 'CapSize', 2);
            end
            xt(end+1) = pos; %#ok<AGROW>
            xtl(end+1) = pair_names(pp); %#ok<AGROW>
        end
        for k = 1:numel(gs)
            y1 = vals{1}(k); y2 = vals{2}(k);
            if ~isnan(y1) && ~isnan(y2)
                plot(axA, [base+1 base+2], [y1 y2], '-o', 'Color', col, ...
                    'LineWidth', 0.4, 'MarkerSize', 1.4, 'MarkerFaceColor', 'none', ...
                    'MarkerEdgeColor', col);
            end
        end
        % SV, September 27, 2026: reward preference is now computed for BOTH
        % tone states, not just tones ON - SV: "i think i forgot to do a sham
        % and tms bar for both tones ON and tones OFF". Each is
        % reward-minus-platform within that tone state.
        if hh == 1
            gs_p = gs;
            pref.(char(g)) = arrayfun(@(i) report_bin_mean(rew_on,  rows(i), bin), gs_p) - ...
                             arrayfun(@(i) report_bin_mean(plat_on, rows(i), bin), gs_p);
            pref_off.(char(g)) = arrayfun(@(i) report_bin_mean(rew_off,  rows(i), bin), gs_p) - ...
                                 arrayfun(@(i) report_bin_mean(plat_off, rows(i), bin), gs_p);
        end
        lab_x(end+1) = base + 1.5; %#ok<AGROW>
        lab_s(end+1) = string(report_tms_markup(report_group_label(g), g)); %#ok<AGROW>
        pos = pos + 0.7;
    end
    half_hi(hh) = pos - 0.7;
    pos = pos + 0.9;
end
% SV, September 27, 2026: the binned panels are a scale copy of the aggregate,
% so their text scales with them (sc) instead of staying full size on a smaller
% plot. Proportions also pin to [0 1] here - that is the real maximum, and
% autoscaling made each panel a different height for the same quantity.
if nargin < 15 || isempty(sc), sc = 1; end
fs_tick = 5.5 * max(sc, 0.75);
set(axA, 'XTick', xt, 'XTickLabel', cellstr(xtl), 'XLim', [0.3 pos-1.1], 'FontSize', fs_tick);
axA.XTickLabelRotation = report_tick_rotation(axA, xtl, fs_tick);
if nargin >= 14 && ~isempty(pair_ylim)
    ylim(axA, pair_ylim);
else
    % SV, September 28, 2026: I added - count panels (Zone Visits) autoscale,
    % and a small mean with a large SE (whisker dipping below 0) made MATLAB
    % drop the floor to -0.5, leaving a band of empty axis under the bars.
    % Every value on these panels is a proportion or a count, never negative,
    % so the floor is 0; report_pad_bottom then adds its usual small pad.
    yl = ylim(axA);
    if yl(1) < 0, ylim(axA, [0 yl(2)]); end
end
report_pad_bottom(axA);   % bars at 0 stay visible; preference panels are exempt
ylabel(axA, ylab, 'FontSize', 6.5*max(sc,0.75)*ts, 'Color', 'k');
title(axA, sprintf('%s (%s)', char(day), strrep(char(bin_label), 'Tones ', 'tones ')), ...
    'FontSize', 7.5*max(sc,0.8)*ts, 'FontWeight', 'normal', 'Color', 'k');
% SV, September 25, 2026: I changed
% subtitle(axA, sprintf('%s v. %s', half_names(1), half_names(2)), ...);
% to this. The subtitle names what the X-AXIS compares - per SV: "since the
% x-axis directly compares platform v reward, thats what should go under the
% title". The two HALVES are the other factor (tone playing on the left four
% bars, not playing on the right four), and they are labelled in-plot by
% report_label_with_placeholder below, which is what the sketch's
% "Tones ON 1-9" / "Tones OFF 1-9" annotations mean.
subtitle(axA, sprintf('%s v. %s', pair_names(1), pair_names(2)), ...
    'FontSize', 6.5*0.66*max(sc,0.8)*ts, 'Color', [0.45 0.45 0.45]);

% Each half of this panel is one condition, labelled in-plot as in the sketch.
% The sketch pairs each label with a speaker or arena glyph; those are the
% graphics that did not render, so each label carries an empty square for the
% BioRender artwork SV will supply (SV, 2026-09-25).
yr = ylim(axA);
for hh = 1:2
    % SV, September 27, 2026: the label sits centred over the two bar-pairs it
    % describes and carries its epoch icon rather than an empty square. Both
    % are pushed behind the data (uistack) so a tall bar covers them instead of
    % being covered - SV: "if data happens to overlap them, they go under".
    if pivot == "zone"
        ic = report_epoch_icon('toneonly', lower(extractAfter(half_names(hh), 'Tones ')));
    else
        ic = report_epoch_icon('zoneonly', lower(half_names(hh)));
    end
    report_half_label(axA, mean([half_lo(hh) half_hi(hh)]), ...
        yr(2) - 0.11*diff(yr), char(half_names(hh)), 6*max(sc,0.8)*ts, ic, ts);
end

yr = ylim(axA);
% SV, September 27, 2026: more clearance between the Sham/Tms label and the
% Platform/Reward tick labels above it, per SV item 3.
grp_drop = 0.24; if axA.XTickLabelRotation > 0, grp_drop = 0.30; end
% SV, September 28, 2026: I added - per SV, the Sham/Tms line sits at HALF
% its old distance below the Platform/Reward (Tone ON/OFF) tick labels. The
% labels' own depth is estimated in points (~3 pt tick pad, then the rotated
% label's height at ~0.55 em per character), so only the empty gap is halved
% and the text cannot land on the labels, whatever the panel size.
pt2data = diff(yr) / (axA.Position(4) * 11 * 72);
rot = axA.XTickLabelRotation;
lab_depth = (3 + fs_tick * (0.55 * max(strlength(xtl)) * sind(rot) + cosd(rot))) * pt2data;
grp_drop = (lab_depth + 0.5 * max(grp_drop*diff(yr) - lab_depth, 0)) / diff(yr);
for q = 1:numel(lab_x)
    text(axA, lab_x(q), yr(1) - grp_drop*diff(yr), lab_s(q), 'HorizontalAlignment', 'center', ...
        'FontSize', 5.5*max(sc,0.8)*ts, 'Interpreter', 'tex', 'Clipping', 'off');
end

if (~isempty(pref.sham) || ~isempty(pref.tms))
    % Four bars: Sham/Tms during tones ON, then Sham/Tms during tones OFF,
    % each pair captioned with its tone icon (SV, 2026-09-27).
    xs = [1 2 3.7 4.7];
    sets = {pref, pref_off};
    k = 0;
    for ss = 1:2
        for g = ["sham", "tms"]
            k = k + 1;
            v = sets{ss}.(char(g)); v = v(~isnan(v));
            col = report_color(g);
            if isempty(v), continue; end
            mu = mean(v); se = std(v)/max(sqrt(numel(v)),1);
            bar(axB, xs(k), mu, 0.72, 'FaceColor', report_tint(col), 'EdgeColor', 'none');
            errorbar(axB, xs(k), mu, se, 'Color', col, 'LineWidth', 0.7, 'CapSize', 2);
            plot(axB, xs(k) + 0.09*randn(1,numel(v)), v, 'o', 'MarkerSize', 1.4, ...
                'MarkerFaceColor', 'none', 'MarkerEdgeColor', col, 'LineWidth', 0.4);
        end
    end
    ticklab = strings(1,4);
    kk = 0;
    for ss = 1:2
        for g = ["sham", "tms"]
            kk = kk + 1;
            ticklab(kk) = string(report_tms_markup(report_group_label(g), g));
        end
    end
    % SV, September 27, 2026: the preference panel carries a single x-axis at
    % zero (SV's "only need a single x-axis at 0") rather than a ruler under the
    % bars, and every panel in the row shares pref_lim so their shapes compare.
    set(axB, 'XTick', xs, 'XTickLabel', {'','','',''}, 'XLim', [0.3 5.4], ...
        'FontSize', 5.5*ts, 'XAxisLocation', 'origin');
    if nargin >= 13 && ~isempty(pref_lim) && diff(pref_lim) > 0
        ylim(axB, pref_lim);
        if abs(pref_lim(2) - 1) < 1e-9 && abs(pref_lim(1) + 1) < 1e-9
            yticks(axB, -1:0.5:1);          % proportion difference
        else
            report_snap_ylim(axB);          % counts: round out to whole ticks
        end
    end
    % Tone icon over each pair, so it is clear which two bars are which.
    yrb2 = ylim(axB);
    report_half_label(axB, mean(xs(1:2)), yrb2(2) - 0.10*diff(yrb2), '', ...
        5*max(sc,0.8)*ts, report_epoch_icon('toneonly', 'on'), ts);
    report_half_label(axB, mean(xs(3:4)), yrb2(2) - 0.10*diff(yrb2), '', ...
        5*max(sc,0.8)*ts, report_epoch_icon('toneonly', 'off'), ts);
    % The row shares one preference scale, so only the leftmost panel needs the
    % axis name - repeating it on every panel is what crowded the plot beside
    % it. Sham/Tms are not re-labelled here either: the bars are in group order
    % and group-colored, and SV asked for "only a single x-axis at 0".
    if nargin >= 13 && show_pref_ylabel
        ylabel(axB, 'Reward Preference', 'FontSize', 5.5*ts, 'Color', 'k');
    end
else
    axis(axB, 'off');
end
end

function v = report_bin_mean(fn, r, bin)
v = NaN;
try
    x = double(fn(r));
catch
    return
end
idx = bin(bin <= numel(x));
if isempty(idx), return; end
x = x(idx); x = x(~isnan(x));
if ~isempty(x), v = mean(x); end
end

%% ----------------------------------------------------------- decoration
function report_blank(ax, ttl)
axis(ax, 'off');
if ~isempty(ttl)
    title(ax, ttl, 'FontSize', 7.5, 'FontWeight', 'normal', 'Color', [0.5 0.5 0.5]);
end
text(ax, 0.5, 0.5, 'no data', 'Units', 'normalized', 'HorizontalAlignment', 'center', ...
    'FontSize', 7, 'Color', [0.5 0.5 0.5]);
end

% SV item 5: the hand-drawn arena/speaker glyphs were wrong, so this is an
% empty square reserved for the BioRender graphic SV will supply. Dropping a
% real image in later means reading it and calling image() over this box.
function c = report_tint(col)
% SV, September 27, 2026: I added - a 25% tint of a group color over white,
% used as the bar fill now that bars are shaded rather than outlined.
c = 1 - 0.25*(1 - col);
end

%%
function t = report_legend_group(txt, group)
% SV, September 27, 2026: I added - group entries in a legend are bold and
% full size; see report_legend_subject for the animals, which are not.
t = report_tms_markup(txt, group);
end

%%
function t = report_legend_subject(txt, group)
% SV, September 27, 2026: I added - per SV, animal entries in the legend are
% NOT bold and are a step smaller than the group entries, so "Sham"/"Tms" read
% as headings over their animals. \rm cancels the bold, \fontsize sets the size
% for that entry only, which is the only way to vary either within one legend.
t = ['\rm\fontsize{4}' report_color_tex(group) char(txt)];
end

%%
function rot = report_tick_rotation(ax, labels, fs)
% SV, September 27, 2026: I added - slant tick labels ONLY when they would not
% otherwise fit, per SV: "x-axis labels should be slanted only if necessary to
% fit their names". Width is estimated from the visible characters (TeX markup
% such as \bf or \color contributes no width), against the space one tick gets.
vis = regexprep(cellstr(labels), '\\[a-zA-Z]+(\{[^}]*\})?', '');
if isempty(vis), rot = 0; return; end
max_chars = max(cellfun(@numel, vis));
axis_w_pt = ax.Position(3) * 8.5 * 72;         % page is 8.5 in wide
per_tick_pt = axis_w_pt / max(numel(vis), 1);
needed_pt = max_chars * fs * 0.58;             % rough advance width per char
if needed_pt > 0.95 * per_tick_pt
    rot = 45;
else
    rot = 0;
end
end

%%
function R = report_fit_lme(O, days, m)
% SV, September 27, 2026: I added - the principled test behind each metric.
%
% WHY. The stars on the panels come from comparing Sham with Tms separately at
% each day and tone bin. That treats every point as an independent sample, but
% the SAME 14 animals are measured on every day, so those samples are not
% independent, and there are ~12 of them per panel. Neither problem is fixable
% by a better two-sample test.
%
% This fits one model per metric instead:
%       value ~ group * day + (1 | animal)
% animal as a random intercept absorbs the repeated measures, "group" asks
% whether Sham and Tms differ overall, and "group:day" asks whether they change
% at different rates across days. One test of the actual question, rather than
% twelve tests of twelve slices of it.
%
% The per-animal value for a day is the same quantity the summary bar shows -
% the day total for additive metrics, the mean over bins otherwise.
%
% Returns NaNs (and why) rather than erroring when the design is too thin to
% fit - a single day, or one group missing.

R = struct('ok', false, 'note', '', 'p_group', NaN, 'p_inter', NaN, ...
    'n_animals', 0, 'n_obs', 0, 'formula', 'value ~ group*day + (1|animal)');

y = []; grp = {}; dayi = []; anim = {};
for d = 1:numel(days)
    sel = O([O.day] == days(d));
    for k = 1:numel(sel)
        if isfield(m, 'agg') && strcmp(m.agg, 'sum')
            v = sel(k).total;
        else
            v = mean(sel(k).val, 'omitnan');
        end
        if isnan(v), continue; end
        y(end+1,1)    = v;            %#ok<AGROW>
        grp{end+1,1}  = char(sel(k).group); %#ok<AGROW>
        dayi(end+1,1) = d;            %#ok<AGROW>
        anim{end+1,1} = char(sel(k).lbl);   %#ok<AGROW>
    end
end

R.n_obs = numel(y);
R.n_animals = numel(unique(anim));
if numel(unique(dayi)) < 2
    R.note = 'only one day present - no day or interaction term';
    return
end
if numel(unique(grp)) < 2
    R.note = 'only one group present';
    return
end
if R.n_obs < 8
    R.note = 'too few observations to fit';
    return
end

try
    tbl = table(y, categorical(grp), dayi, categorical(anim), ...
        'VariableNames', {'value', 'group', 'day', 'animal'});
    lme = fitlme(tbl, 'value ~ group*day + (1|animal)');
    cn = lme.Coefficients.Name;
    pv = lme.Coefficients.pValue;
    gi = find(startsWith(cn, 'group') & ~contains(cn, ':'), 1);
    ii = find(contains(cn, 'group') &  contains(cn, ':'), 1);
    if ~isempty(gi), R.p_group = pv(gi); end
    if ~isempty(ii), R.p_inter = pv(ii); end
    R.ok = true;
catch ME
    R.note = ME.message;
end
end

%%
function S = report_stats_page(S)
% SV, September 27, 2026: I added - the report's last page, explaining every
% test it runs and flagging where the numbers should be read cautiously.
S = report_new_page(S);

% SV, September 28, 2026: I added - n per group from the data (set in write_pma_report_pdf).
n_txt = sprintf('%d Sham v %d Tms', S.n_sham, S.n_tms);
L = {};
L{end+1} = {'H', 'Statistics used in this report'};
L{end+1} = {'P', ['Two different things are reported. The stars ON the plots are ' ...
    'quick post-hoc comparisons. The mixed model in the table below is the test ' ...
    'that actually accounts for the design.']};

L{end+1} = {'S', '1.  Stars on the timecourse panels'};
L{end+1} = {'P', ['Sham vs Tms at each day and tone bin, Wilcoxon rank-sum (a rank test, ' ...
    'so it assumes nothing about the shape of the distribution). With ' n_txt ' animals ' ...
    'a t-test leans on a normality assumption these data do not really support, ' ...
    'and proportions and counts are not Gaussian, so the rank test is the honest default.']};
L{end+1} = {'P', ['Every comparison inside one panel is Holm-corrected together ' ...
    sprintf('(%d tests on a %d-day, %d-bin panel). ', S.n_days*S.n_bins, S.n_days, S.n_bins) ...
    'Uncorrected, roughly one in every twenty ' ...
    'would reach p < 0.05 by chance alone.  * p<0.05   ** p<0.01   *** p<0.001, ' ...
    'all after correction.']};

L{end+1} = {'S', '2.  Mixed-effects model (the main test)'};
L{end+1} = {'P', ['value ~ group * day + (1 | animal).  The same animals are measured ' ...
    'on every day, so the per-bin comparisons above are not independent of each other. ' ...
    'A random intercept per animal absorbs that. "group" asks whether Sham and Tms ' ...
    'differ overall; "group x day" asks whether they change at different rates.']};
L{end+1} = {'P', ['The value per animal per day is the same number the summary bar ' ...
    'shows: the day total for additive metrics (track length, zone visits), the mean ' ...
    'across tone bins otherwise.']};

L{end+1} = {'S', '3.  Shocks avoided'};
L{end+1} = {'P', ['Also modelled in the workbook''s stats tab as a binomial GLMM ' ...
    '(successes out of tones delivered, group*time + (1|animal)), which is the right ' ...
    'family for a proportion built from a count. The figure here shows the same data ' ...
    'descriptively.']};

L{end+1} = {'S', '4.  Platform v. Reward panels'};
L{end+1} = {'P', ['No test is drawn on these. The comparison of interest is within ' ...
    'animal (platform vs reward) crossed with group, which is a 2x2 question the ' ...
    'per-bar stars would misrepresent. The connecting lines show the within-animal ' ...
    'change directly.']};

L{end+1} = {'S', 'Read with care'};
L{end+1} = {'P', [n_txt '. Small samples make every one of these tests ' ...
    'low-powered: a non-significant result here is weak evidence of no effect, not ' ...
    'evidence of absence. The per-bin stars are exploratory even after correction - ' ...
    'treat the mixed model as the result and the stars as a guide to where to look.']};

if isfield(S, 'stats') && ~isempty(S.stats)
    L{end+1} = {'S', 'Mixed model results'};
end

y = S.top;
for i = 1:numel(L)
    kind = L{i}{1}; txt = L{i}{2};
    switch kind
        case 'H', fs = 14; fw = 'bold';     h = 0.030;
        case 'S', fs = 10; fw = 'bold';     h = 0.024;
        otherwise
            fs = 8.5; fw = 'normal';
            % Height from the actual text length - a fixed box let the longer
            % paragraphs run over the heading beneath them.
            chars_per_line = (1 - 2*S.margin) * 8.5 * 72 / (fs * 0.50);
            n_lines = max(1, ceil(numel(txt) / chars_per_line));
            h = n_lines * 0.0135 + 0.004;
    end
    if y - h < S.bottom, break; end
    annotation(S.fig, 'textbox', [S.margin, y - h, 1 - 2*S.margin, h], ...
        'String', txt, 'FontSize', fs, 'FontWeight', fw, 'Color', 'k', ...
        'EdgeColor', 'none', 'VerticalAlignment', 'top', 'FitBoxToText', 'off');
    y = y - h - 0.004;
end

if isfield(S, 'stats') && ~isempty(S.stats)
    hdr = sprintf('%-44s %9s %13s %8s', 'metric', 'p(group)', 'p(group x day)', 'animals');
    annotation(S.fig, 'textbox', [S.margin, y - 0.016, 1 - 2*S.margin, 0.016], ...
        'String', hdr, 'FontSize', 7.5, 'FontName', 'Courier New', 'FontWeight', 'bold', ...
        'Color', 'k', 'EdgeColor', 'none', 'VerticalAlignment', 'top');
    y = y - 0.020;
    for i = 1:numel(S.stats)
        R = S.stats(i);
        if R.ok
            nm = strtrim(strrep(R.name, ':  Timecourse', ''));
            line_txt = sprintf('%-44s %9s %13s %8d', nm(1:min(44,end)), ...
                report_pfmt(R.p_group), report_pfmt(R.p_inter), R.n_animals);
        else
            nm = strtrim(strrep(R.name, ':  Timecourse', ''));
            line_txt = sprintf('%-44s  not fitted: %s', nm(1:min(44,end)), R.note);
        end
        if y - 0.014 < S.bottom, break; end
        annotation(S.fig, 'textbox', [S.margin, y - 0.014, 1 - 2*S.margin, 0.014], ...
            'String', line_txt, 'FontSize', 7, 'FontName', 'Courier New', ...
            'Color', 'k', 'EdgeColor', 'none', 'VerticalAlignment', 'top');
        y = y - 0.015;
    end
end
S.y = y;
end

%%
function t = report_pfmt(p)
if isnan(p)
    t = '-';
elseif p < 0.001
    t = '<0.001';
else
    t = sprintf('%.3f', p);
end
end

%%
function report_icon(ax, icon_name)
% SV, September 27, 2026: I replaced the empty placeholder square with SV's
% BioRender-style epoch icons from
% E:\Data_Graphics\PMA epoch icons\Red - TMS plot red CC4125
% (the red set, per SV "use the red themes graphics for now").
%
% Which icon goes where comes from SV's sketches - see report_epoch_icon for
% the mapping. Icons are 1200x1200 RGBA PNGs, drawn with their alpha so the
% arena sits on the plot background rather than in a white box, and sized so
% they stay SQUARE on the page: the axes' own aspect is folded in, because a
% width in x data-units and a height in y data-units are not comparable.
%
% If the folder is unavailable the empty square comes back, so the report
% still builds on a machine without the graphics drive mounted.

persistent icon_cache
if isempty(icon_cache), icon_cache = containers.Map(); end

icon_dir = fullfile('E:', 'Data_Graphics', 'PMA epoch icons', 'Red - TMS plot red CC4125');
f = fullfile(icon_dir, [icon_name '.png']);
if ~isfile(f)
    report_placeholder_box(ax);
    return
end

% SV, September 28, 2026: I changed the cache key from the file path alone to
% path + TMS color, and recolor on load (report_recolor_icon) - otherwise a
% color picked in an earlier run in the same MATLAB session would stick.
cache_key = [f '|' mat2str(group_color("tms"))];
if isKey(icon_cache, cache_key)
    C = icon_cache(cache_key);
else
    [im, ~, al] = imread(f);
    C = struct('im', report_recolor_icon(im), 'al', al);
    icon_cache(cache_key) = C;
end

% SV, September 27, 2026: icons are sized in INCHES, not as a fraction of the
% axes. Sizing by fraction made the speaker-only icons enormous on the wide
% Shocks/Locomotion panels while the arena icons looked right, because the two
% artworks fill their square canvas differently and the panels differ in width.
xr = xlim(ax); yr = ylim(ax);
if startsWith(icon_name, 'PMA_7') || startsWith(icon_name, 'PMA_8')
    in_w = 0.15;      % speaker-only artwork fills its canvas, so it needs less
else
    in_w = 0.30;      % arena artwork has built-in margin
end
w = (in_w / (ax.Position(3) * 8.5)) * diff(xr);
h = (in_w / (ax.Position(4) * 11)) * diff(yr);

x0 = xr(1) + 0.02*diff(xr);
y1 = yr(2) - 0.02*diff(yr);
y0 = y1 - h;

hi = image(ax, 'XData', [x0, x0+w], 'YData', [y1, y0], 'CData', C.im);
if ~isempty(C.al)
    set(hi, 'AlphaData', C.al);
end
uistack(hi, 'bottom');   % data always wins if they overlap
end

%%
function name = report_epoch_icon(zone, tone_state)
% SV, September 27, 2026: I added - maps a panel to one of SV's 8 epoch icons,
% following the sketches in WilkeDeNardo_Notes_2.pdf.
%   zone: 'platform' | 'reward' | 'none'   tone_state: 'on' | 'off' | ''
name = '';
switch lower(zone)
    case 'platform'
        if strcmpi(tone_state, 'on'), name = 'PMA_2_toneON_onPlatform';
        else,                         name = 'PMA_1_toneOFF_onPlatform';
        end
    case 'reward'
        if strcmpi(tone_state, 'on'), name = 'PMA_3_toneON_atRewardPort';
        else,                         name = 'PMA_4_toneOFF_atRewardPort';
        end
    case 'toneonly'
        if strcmpi(tone_state, 'on'), name = 'PMA_8_toneON';
        else,                         name = 'PMA_7_toneOFF';
        end
    case 'zoneonly'
        if strcmpi(tone_state, 'platform'), name = 'PMA_6_onPlatform';
        else,                               name = 'PMA_5_atRewardPort';
        end
end
end

%%
function report_snap_ylim(ax)
% SV, September 27, 2026: I added - make the y-axis stop ON a tick. MATLAB's
% autoscale routinely leaves the ruler running past the last tick, which SV
% flagged as "a stray line" above the top tick. This extends the limits out to
% whole tick steps so the axis always terminates on a labelled tick, never
% between two.
yt = yticks(ax);
if numel(yt) < 2, return; end
step = yt(2) - yt(1);
if ~isfinite(step) || step <= 0, return; end
yl = ylim(ax);
lo = yt(1);   while lo > yl(1) + 1e-12, lo = lo - step; end
hi = yt(end); while hi < yl(2) - 1e-12, hi = hi + step; end
ylim(ax, [lo hi]);
yticks(ax, lo:step:hi);
end

%%
function report_lift_title(ax, gap)
% SV, September 27, 2026: I added - open space between the top of the y-axis
% and the bottom of the plot title, which SV has now asked for three times.
% The title is nudged up in normalized axes units, which also leaves the stars
% drawn above the axes somewhere to sit.
if nargin < 2, gap = 1.12; end
ax.Title.Units = 'normalized';
p = ax.Title.Position;
ax.Title.Position = [p(1), gap, 0];
end

%%
function report_placeholder_box(ax)
xr = xlim(ax); yr = ylim(ax);
w = 0.070*diff(xr); h = 0.150*diff(yr);
x0 = xr(1) + 0.015*diff(xr);
y0 = yr(2) - h - 0.02*diff(yr);
rectangle(ax, 'Position', [x0 y0 w h], 'EdgeColor', [0.55 0.55 0.55], ...
    'LineWidth', 0.5, 'LineStyle', '-');
end

% A text label with an empty square beside it, for the labels the sketch pairs
% with a speaker or arena graphic ("Tones ON", "Platform", ...). Same reason as
% report_placeholder_box: the glyphs did not render, so the space is reserved.
function report_half_label(ax, xc, y, txt, fs, icon_name, icon_scale)
% SV, September 27, 2026: I added - a half-label ("Tones ON", "Platform", ...)
% with its epoch icon, centred as a unit on xc and stacked underneath the data.
% Supersedes report_label_with_placeholder now that SV has supplied artwork.
% Same physical size wherever it is used, so the tone icons over the reward
% preference bars match the ones on the zone panels beside them.
% SV, September 28, 2026: I added icon_scale (default 1) so a four-group
% PVFP row can shrink its icons with its text - see ts in report_zone_blocks.
% Icons still match each other within a row, which is what "same physical
% size" was protecting.
if nargin < 7 || isempty(icon_scale), icon_scale = 1; end
xr = xlim(ax); yr = ylim(ax);
in_w = 0.17 * icon_scale;
icon_w = (in_w / (ax.Position(3) * 8.5)) * diff(xr);
icon_h = (in_w / (ax.Position(4) * 11)) * diff(yr);

th = text(ax, 0, y, txt, 'HorizontalAlignment', 'left', 'FontSize', fs, ...
    'Color', 'k', 'Clipping', 'off', 'VerticalAlignment', 'middle');
ext = th.Extent;
total_w = ext(3) + 0.25*icon_w + icon_w;
x_text = xc - total_w/2;
th.Position = [x_text, y, 0];
uistack(th, 'bottom');

x_icon = x_text + ext(3) + 0.25*icon_w;
drawn = false;
% SV, September 28, 2026: I added a cache. This function draws ~450 icons in a
% full report but only 8 distinct files exist, and it re-read the 1200x1200
% PNG every time (20 ms) - then, once the TMS default became UCLA Blue,
% re-ran report_recolor_icon on all 1.44 M pixels every time too (74 ms per
% icon, ~33 s per report, measured). Each file is now read and recolored once
% per file + color and reused, same pattern as report_icon.
persistent half_cache
if isempty(half_cache), half_cache = containers.Map(); end
if ~isempty(icon_name)
    f = fullfile('E:', 'Data_Graphics', 'PMA epoch icons', 'Red - TMS plot red CC4125', [icon_name '.png']);
    cache_key = [f '|' mat2str(group_color("tms"))];
    if isKey(half_cache, cache_key)
        C = half_cache(cache_key);
    elseif isfile(f)
        [im, ~, al] = imread(f);
        C = struct('im', report_recolor_icon(im), 'al', al); % follows the picked TMS color
        half_cache(cache_key) = C;
    else
        C = [];
    end
    if ~isempty(C)
        hi = image(ax, 'XData', [x_icon, x_icon+icon_w], ...
                       'YData', [y + icon_h/2, y - icon_h/2], 'CData', C.im, ...
                       'Clipping', 'off');
        if ~isempty(C.al), set(hi, 'AlphaData', C.al); end
        uistack(hi, 'bottom');
        drawn = true;
    end
end
if ~drawn
    rectangle(ax, 'Position', [x_icon, y - icon_h/2, icon_w, icon_h], ...
        'EdgeColor', [0.55 0.55 0.55], 'LineWidth', 0.5);
end
end

%%
% SV, September 28, 2026: I added - the epoch icons are drawn in the red
% accent CC4125 (with a pale tint of it as the fill), and that red is there
% to echo the TMS group color. Once the TMS color can be picked, a red icon
% next to, say, UCLA Blue data would read as a third group. So each pixel is
% unmixed into white + accent + black (black is the zero vector, so it is
% just a least-squares fit of white and accent), and the accent share is
% re-mixed with the picked color. The black linework, the pale fill and the
% anti-aliased edges all carry over. With Shock Red picked the stock art is
% used untouched, so the default report looks exactly as it did.
function im = report_recolor_icon(im)
new_c = double(group_color("tms"));
[names, rgb] = group_palette();
if isequal(new_c, rgb(strcmp(names, "Shock Red"), :)), return; end
cls = class(im);
X = double(reshape(im, [], 3));
if isa(im, 'uint16'), X = X / 257; end
A = [255 255 255; 204 65 37]';          % columns: white, icon accent CC4125
w = max(A \ X', 0);                      % 2 x N mixing weights
Y = ([255 255 255; new_c]' * w)';
Y = min(max(Y, 0), 255);
if isa(im, 'uint16'), Y = Y * 257; end
im = reshape(cast(round(Y), cls), size(im));
end

%%
function report_label_with_placeholder(ax, xc, y, txt, fs)
xr = xlim(ax); yr = ylim(ax);
w = 0.055*diff(xr); h = 0.070*diff(yr);
text(ax, xc - 0.5*w, y, txt, 'HorizontalAlignment', 'right', 'FontSize', fs, ...
    'Color', 'k', 'Clipping', 'off');
rectangle(ax, 'Position', [xc - 0.3*w, y - h/2, w, h], ...
    'EdgeColor', [0.55 0.55 0.55], 'LineWidth', 0.5);
end

function report_bolt(ax, xc, yc, h)
% Small lightning bolt marking a shock day. Each dimension is sized from its
% OWN axis range - taking the width from h (a Y quantity) once made a bolt
% wider than the whole plot on the 0-800 cm locomotion axis.
xr = xlim(ax);
w = 0.007 * diff(xr);
patch(ax, 'XData', xc + w*[0 0.9 0.25 1.0 -0.2 0.35 -0.6], ...
          'YData', yc + h*[1 0.25 0.20 -0.45 0.05 0.10 0.55]*0.9, ...
    'FaceColor', [0.92 0.78 0.12], 'EdgeColor', [0.6 0.48 0.05], ...
    'LineWidth', 0.3, 'Clipping', 'off');
end
