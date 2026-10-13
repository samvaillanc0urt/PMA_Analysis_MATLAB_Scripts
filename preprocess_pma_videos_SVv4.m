%% RUN_preprocess_videos
%  ========================================================================
%  WHAT THIS SCRIPT DOES
%  ========================================================================
%
%  Takes the raw behavior videos from a PMA experiment and turns each one
%  into a much smaller .mp4 with an information panel added above the video
%  frame (the panel never covers any part of the original image).
%
%  The panel shows, synced to the video frame by frame:
%     * a timeline of the whole session with a moving white playhead
%          yellow = tone (CS+/CS-)      green = reward delivered
%          red    = shock (US)          blue  = IR beam broken
%          dark red block = stretch of the session with NO video, i.e. the
%                           camera stopped before the task did
%     * TONE and SHOCK circles that fill in while that event is happening
%     * running counts of Beam Break and Reward Delivery
%     * time elapsed and time remaining
%
%  It also shrinks the files enormously: a ~15 GB .avi becomes a ~0.5-0.8 GB
%  .mp4. Frame rate and frame count are never changed -- only the picture
%  size and compression -- so anything counted in frames stays valid.
%
%  ========================================================================
%  BEFORE YOU RUN THIS: FFMPEG HAS TO BE FINDABLE
%  ========================================================================
%  SV, August 27, 2026: I added this section -- on Sam's own machine ffmpeg
%  already lives inside the PMA Software folder, so this was never spelled
%  out. Anyone else running this standalone file on a different machine
%  needs to know where to put it.
%
%  This script drives ffmpeg to do the actual encoding -- it needs
%  ffmpeg.exe and ffprobe.exe (a build with libx264, libx265, drawtext,
%  drawbox, overlay and pad -- any normal "essentials" Windows build has
%  all of these). It looks in this order and uses the first copy it finds:
%
%    1. The ffmpegExe / ffprobeExe lines in the SETTINGS block below, if
%       you type a full path to the .exe there.
%    2. Anywhere in or under the SAME FOLDER as this script. So on a new
%       machine, the easiest fix is to drop the whole unzipped ffmpeg
%       build folder next to this file -- the build folder's name doesn't
%       matter, and it can be nested any number of levels deep:
%
%          <wherever this script lives>\
%            +-- preprocess_pma_videos_SVv4.m          <== this file
%            +-- ffmpeg-8.1.1-essentials_build\               (any name)
%                  +-- bin\
%                        +-- ffmpeg.exe
%                        +-- ffprobe.exe
%
%    3. Whatever "ffmpeg"/"ffprobe" already resolves to on the system PATH
%       (i.e. ffmpeg is separately installed and set up that way).
%
%  If none of those find it, the script stops with an error before doing
%  any work, saying exactly what it looked for and where -- it does not
%  fail partway through or silently skip encoding.
%
%  Don't have ffmpeg at all? Get a Windows build from
%  https://www.gyan.dev/ffmpeg/builds/ (the "essentials" build is enough).
%
%  ========================================================================
%  HOW TO USE IT
%  ========================================================================
%
%  STEP 1. Open this file in MATLAB and press the green RUN button.
%          (Nothing else needs typing or editing in the code itself.)
%
%  STEP 2. A settings window opens with every preference on one page --
%          the experiment folder (with a Browse... button), video
%          resolution, codec, quality, encode speed, whether to move the
%          original .avi files, and the ffmpeg override paths. Every field
%          is pre-filled with this script's built-in defaults, so someone
%          using this for the first time can just check the folder field
%          and click Run; nothing else needs to be understood or changed.
%
%          THE FOLDER FIELD IS THE IMPORTANT PART -- it needs the
%          EXPERIMENT folder, the one that CONTAINS the day folders:
%
%            Desktop\Sam V\
%              +-- 2026-08-20_PVcre.Fp_PMA_TMS\      <=== PICK THIS ONE
%                    +-- HabD1\
%                    |     +-- PVFP_28_HabD1_SV_Aug20_2026-08-20_12-10-57.mat
%                    |     +-- PVFP_28_HabD1_SV_Aug20_reward_data_20260820_114159.txt
%                    |     +-- PVFP_28_HabD1_SV_Aug20_camera_2026-08-20_11-42-01.avi
%                    |     +-- ... (same three files for mice 29-33)
%                    +-- HabD2\    (same layout)
%                    +-- HabD3\    (same layout)
%
%          NOT  ...\2026-08-20_PVcre.Fp_PMA_TMS\HabD1   <-- one level TOO DEEP
%          NOT  ...\Desktop\Sam V                        <-- one level TOO SHALLOW
%
%          Click Browse... to pick it, or paste/type the path directly.
%          Click Run in this window and it finds HabD1, HabD2, HabD3 (and
%          any other day folder) by itself.
%
%          SV / Claude, September 2, 2026: I added -- if the folder you pick
%          has no day folders directly in it (nothing one level down holds
%          a .mat file), it now looks one level DEEPER before giving up.
%          This covers BehaviorDEPOT's own reorganized layout, where the
%          root's immediate children are condition folders (sham_HabD1s1,
%          tms_TrainD1s1, ...) and the .mat files are one level further in,
%          inside each animal's own session folder:
%
%            2026-02-01_Fp.SST.PV_TMS_PMA_SV\      <=== you can point at this
%              +-- sham_HabD1s1\
%              |     +-- DCSP_14_sham_HabD1s1_SV_Feb7\
%              |           +-- DCSP_14_HabD1s1_SV_Feb7_....mat
%              +-- tms_HabD1s1\
%                    +-- ...
%
%          Each animal's session folder becomes its own one-.mat "day
%          folder" here, so you get every session across every condition
%          folder in one checklist instead of running this once per
%          condition folder. A folder that DOES have .mat files directly
%          in it (the original flat layout above) is unaffected -- the
%          deeper search only runs when the first level comes up empty.
%
%  STEP 3. A checklist appears listing every session it found. Tick the ones
%          you want. Sessions already finished start unticked -- tick one to
%          redo it (that overwrites the existing file, and the summary in
%          step 4 will say so).
%
%  STEP 4. A summary window shows exactly what will be created, from which
%          file, where the originals will be moved, and a time estimate.
%          NOTHING ON DISK HAS CHANGED YET. Click Run to start, Quit to back
%          out with no effect.
%
%  STEP 5. Each video gets a progress bar with a live ETA. The Command Window
%          stays quiet -- one short line per video.
%
%  ------------------------------------------------------------------------
%  WHAT YOU END UP WITH
%  ------------------------------------------------------------------------
%
%    2026-08-20_PVcre.Fp_PMA_TMS\
%      +-- og_large_vids\      <-- every original .avi is MOVED here
%      |                           (moved, never deleted, and only after
%      |                            that video encodes successfully)
%      +-- HabD1\  PVFP_28_..._camera_2026-08-20_11-42-01_preprocessed.mp4
%      +-- HabD2\  ...
%      +-- HabD3\  ...
%      +-- _preprocess_work\   <-- scratch files, safe to delete any time
%
%  Each output keeps the original video's exact filename with _preprocessed
%  added, so it is always obvious which .avi it came from:
%       PVFP_28_HabD1_SV_Aug20_camera_2026-08-20_11-42-01.avi
%    -> PVFP_28_HabD1_SV_Aug20_camera_2026-08-20_11-42-01_preprocessed.mp4
%
%  Roughly 10-12 minutes per video on this machine (CPU only -- no GPU is
%  used or needed). Safe to stop and re-run: finished sessions are skipped,
%  and an interrupted encode leaves a .partial file that is never mistaken
%  for finished work.
%
%  ------------------------------------------------------------------------
%  WHERE THE CODE LIVES
%  ------------------------------------------------------------------------
%
%    Desktop\PMA Software\
%      +-- preprocess_pma_videos_SVv4.m   <== THIS FILE. The only file you need.
%
%  This is the STANDALONE version: everything that lives in
%  engine\preprocess_video_engine.m for the normal (SVv2) copy is folded
%  into this one file instead, as local functions below the settings block.
%  One file, nothing else to copy alongside it -- built for sending to
%  other people in the lab, who would otherwise also need the engine\
%  subfolder sitting next to the script for it to run. On top of that, every
%  setting that could differ from machine to machine is asked for in the
%  Run-time settings window (STEP 2) instead of needing to be typed into the
%  code below -- so a labmate never has to open or edit this file at all.
%
%  The version tag (SVv4) is on this script, so you can always see which
%  version you are running without opening anything else.
%
%  ------------------------------------------------------------------------
%  SV, August 25, 2026: I added this runner script. The heavy lifting lives
%  in engine\preprocess_video_engine.m, which this calls underneath.
%  SV, August 25, 2026: I expanded the header into a description + numbered
%  instructions with a folder-level diagram, per the script-header rule.
%  SV, August 25, 2026: I renamed this from RUN_preprocess_videos.m to
%  preprocess_pma_videos_SVv2.m and moved it into the PMA software folder,
%  with the engine hidden in engine\.
%  SV, August 27, 2026: I added preprocess_pma_videos_SVv3.m -- a standalone
%  single-file version, folding engine\preprocess_video_engine.m's functions
%  in below as local functions, so this one file can be emailed/shared
%  without the engine\ subfolder. preprocess_pma_videos_SVv2.m and
%  engine\preprocess_video_engine.m are untouched; keep using those two for
%  your own day-to-day editing, and re-merge into this file if the engine
%  changes. The only functional difference from v2 is how ffmpeg is located
%  (see resolveTool below) -- it now looks next to this file directly
%  instead of one folder up, since there is no engine\ level to climb out of.
%  SV, August 27, 2026: I added a settings window (preferencesDialog, below)
%  that opens on Run and holds every value from the DEFAULTS block just
%  under this header -- folder, resolution, codec, crf, preset, move-
%  originals, test-seconds, and the ffmpeg override paths. Pre-filled with
%  those defaults, so clicking straight through behaves exactly like typing
%  nothing changed in the old settings block did. Per CLAUDE.md rule 12:
%  a script meant to be shared can't rely on the recipient opening and
%  correctly editing MATLAB code, so every machine/experiment-specific
%  value now lives in that window instead. This is v3-only; v2 still uses
%  the plain settings block since it never leaves Sam's own machine.
%  SV / Claude, September 2, 2026: I added preprocess_pma_videos_SVv4.m --
%  the only change from v3 is findDayFolders (down in the local functions):
%  it now falls back to searching one level deeper when the folder you
%  point it at has no .mat files directly under its immediate children.
%  See the STEP 2 note above for the layout this covers. Nothing else
%  changed; v3 stays where it is for anyone still relying on it.

clear; clc;

%% ------------------------------------------------------------------------
%  DEFAULTS -- these pre-fill the settings window that opens when you press
%  Run (see preferencesDialog, down in the local functions below). Change
%  values here only if you want different defaults to show up in that
%  window every time; for a one-off run, just change them in the window
%  itself instead of editing this code.
%  ------------------------------------------------------------------------

defaults = struct();

% Where the folder browser (inside the settings window) starts. You still
% pick the actual folder there, so this only has to be close.
defaults.startingFolder = 'C:\Users\boba4\Desktop\Sam V';

% Video settings.
defaults.resolution = '640x480';   % size of the video itself; the info panel adds height on top
defaults.codec      = 'libx265';   % 'libx265' = smaller files | 'libx264' = ~3x faster to encode
defaults.crf        = 24;          % lower = better quality, bigger file (18 = high, 28 = small)
defaults.preset     = 'veryfast';  % ultrafast / veryfast / medium / slow -- slower = slightly smaller

% Occasionally useful:
defaults.moveOriginals = true;   % false leaves the big .avi files where they are
defaults.testSeconds   = 0;      % >0 encodes only the first N seconds, to preview the
                                  % look quickly. Test clips are written with a _TESTNs
                                  % name so they never sit where a real output belongs.

% ffmpeg is found automatically -- see "BEFORE YOU RUN THIS: FFMPEG HAS TO
% BE FINDABLE" up near the top of this file for where to put it. These only
% need filling in (in the settings window, or here as the window's default)
% to force a specific copy, e.g. 'C:\ffmpeg\bin\ffmpeg.exe'.
defaults.ffmpegExe  = '';
defaults.ffprobeExe = '';

%% ------------------------------------------------------------------------
%  Nothing below here needs editing.
%  ------------------------------------------------------------------------

% SV, August 27, 2026: I changed
% thisDir = fileparts(mfilename('fullpath'));
% addpath(thisDir);
% addpath(fullfile(thisDir, 'engine'));
% to this:
% (nothing to add to the path -- preprocess_video_engine is a local function
% inside THIS file in the standalone version, not a separate file in an
% engine\ subfolder)

% SV, August 27, 2026: I added
% Settings window (CLAUDE.md rule 12: a shared script can't rely on someone
% else opening and correctly editing the code) -- pops up on Run, pre-filled
% with the DEFAULTS above, covering every value that used to require editing
% this file directly. Falls back to using the defaults untouched if there is
% no display to show it on (same headless-degrades-gracefully pattern as the
% rest of this tool's dialogs).
if usejava('desktop')
    [cfg, ok] = preferencesDialog(defaults);
    if ~ok
        fprintf('Cancelled at the settings window -- nothing was changed.\n');
        return;
    end
else
    warning('preprocess_video:noDisplay', ...
        ['No MATLAB desktop available, so the settings window cannot be ' ...
         'shown. Running with the built-in defaults from this script.']);
    cfg = defaults;
end
%

preprocess_video_engine( ...
    'root',         cfg.startingFolder, ...
    'pickFolder',   false, ...   % already chosen in the settings window above
    'pickSessions', true, ...
    'showDialog',   true, ...
    'resolution',   cfg.resolution, ...
    'codec',        cfg.codec, ...
    'crf',          cfg.crf, ...
    'preset',       cfg.preset, ...
    'ffmpeg',       cfg.ffmpegExe, ...
    'ffprobe',      cfg.ffprobeExe, ...
    'noArchive',    ~cfg.moveOriginals, ...
    'limitSeconds', cfg.testSeconds);


% ==========================================================================
% EVERYTHING BELOW THIS LINE is the processing engine -- folded in here as
% local functions so this single file is standalone (no engine\ subfolder
% needed alongside it). This is the same code as engine\preprocess_video_
% engine.m in the SVv2 two-file version, with one functional change
% (resolveTool's search root -- see the comment there) plus a couple of
% comments updated to describe living in one file instead of two.
%
% Nothing here needs editing for normal use. If you do change something,
% change it in engine\preprocess_video_engine.m too (or re-run the merge),
% since SVv2 and this SVv4 standalone are meant to stay behaviorally
% identical.
% ==========================================================================
function preprocess_video_engine(varargin)
%PREPROCESS_VIDEO_ENGINE  Compress PMA behavior videos and add an event panel.
%
%   SV, August 25, 2026: I renamed this from preprocess_video_SVv2 and moved
%   it into the engine\ subfolder. The version tag now lives on the script
%   you actually open (preprocess_pma_videos_SVv2.m), not on this engine.
%
%   ---------------------------------------------------------------------
%   WHAT THIS DOES
%   ---------------------------------------------------------------------
%
%   The engine behind RUN_preprocess_videos.m. For every session in an
%   experiment folder it writes a much smaller .mp4 with an information
%   panel added ABOVE the video frame -- the panel never covers any part of
%   the original image, so nothing is hidden from scoring or tracking.
%
%   The panel shows, synced frame by frame:
%     * a session timeline with a moving white playhead
%          yellow = tone (CS+/CS-)      green = reward delivered
%          red    = shock (US)          blue  = IR beam broken
%          dark red block = stretch of the session with NO video, i.e. the
%                           camera stopped before the task did
%     * TONE and SHOCK circles that fill while that event is happening
%     * running Beam Break and Reward Delivery counts
%     * time elapsed and time remaining
%
%   Size: a ~15 GB .avi becomes roughly a 0.5-0.8 GB .mp4. Frame rate and
%   frame count are never touched -- only picture size, compression, and the
%   added panel -- so anything measured in frames stays valid.
%
%   SV, August 25, 2026: I expanded this header into a description +
%   instructions with a folder-level diagram, per the script-header rule.
%
%   New in v2 vs v1:
%     * A confirmation window shows the full plan before anything happens --
%       every source -> output pair, where originals get moved, total disk
%       use and a time estimate -- with Run and Quit buttons.
%     * The Command Window stays quiet (no per-frame ffmpeg spam). Each video
%       gets a progress bar instead, with a live ETA.
%
%   MATLAB equivalent of preprocess_video.py. Same inputs, same outputs, same
%   filenames -- the two can be used interchangeably on the same folder tree
%   (each skips work the other already finished).
%
%   For each behavior session (one mouse, one recording) this:
%     1. Reads the MATLAB task-timing file (*_<timestamp>.mat) for per-trial
%        tone (CS+/CS-), shock (US), and reward-laser on/off wall-clock times.
%     2. Reads the reward-Arduino log (*_reward_data_<timestamp>.txt) for beam
%        breaks and physical reward-pump dispenses.
%     3. Reads the raw camera video (*_camera_<timestamp>.avi) and uses the
%        .mat file's camera_on timestamp to place every event on the right
%        video frame.
%     4. Encodes a compressed .mp4 with a panel ABOVE the frame (never
%        overlapping it) showing a session timeline with a moving playhead,
%        tone/shock indicator circles, running Beam Break and Reward Delivery
%        counts, and elapsed / remaining time.
%
%   Frame rate and frame count are never touched -- only spatial resolution,
%   encode quality, and the added panel change the output.
%
%   ---------------------------------------------------------------------
%   HOW TO USE IT
%   ---------------------------------------------------------------------
%
%   NORMALLY YOU DO NOT EDIT THIS FUNCTION.
%   This is folded into preprocess_pma_videos_SVv4.m as a local function so
%   the standalone script is one file. The settings block near the top of
%   THIS SAME FILE is what you open and press Run on; come down here only to
%   change how the panel is drawn or how encoding works -- and make the same
%   change in engine\preprocess_video_engine.m (the SVv2 two-file version),
%   since the two are meant to stay in sync.
%
%   WHICH FOLDER TO POINT IT AT (the one thing that is easy to get wrong):
%   the EXPERIMENT folder, i.e. the one that CONTAINS the day folders --
%   never a day folder itself.
%
%     Desktop\Sam V\
%       +-- 2026-08-20_PVcre.Fp_PMA_TMS\      <=== THIS ONE ('root')
%             +-- HabD1\
%             |     +-- PVFP_28_HabD1_SV_Aug20_2026-08-20_12-10-57.mat
%             |     +-- PVFP_28_HabD1_SV_Aug20_reward_data_20260820_114159.txt
%             |     +-- PVFP_28_HabD1_SV_Aug20_camera_2026-08-20_11-42-01.avi
%             |     +-- ... (same three files for mice 29-33)
%             +-- HabD2\    (same layout)
%             +-- HabD3\    (same layout)
%
%     NOT  ...\2026-08-20_PVcre.Fp_PMA_TMS\HabD1   <-- one level TOO DEEP
%     NOT  ...\Desktop\Sam V                        <-- one level TOO SHALLOW
%
%   Day folders are found automatically: any immediate subfolder holding
%   .mat files counts, so HabD1/HabD2/HabD3 (or any other naming) all work
%   without being listed anywhere.
%
%   Two ways to call it, both fine:
%
%   1. PRESS RUN
%        Set CFG.root in the settings block below, save, press Run. The
%        folder browser opens at CFG.root so it only has to be close.
%        Nothing on disk changes until you click Run in the summary window.
%
%   2. CALL IT WITH ARGUMENTS (overrides the settings block)
%        preprocess_video_engine('root', 'C:\...\2026-08-20_PVcre.Fp_PMA_TMS')
%        preprocess_video_engine('days', 'HabD3')
%        preprocess_video_engine('showDialog', false)   % headless, no window
%
%   Walks every day folder (any subfolder holding .mat files), encodes each
%   session, and moves each original .avi into a single shared og_large_vids
%   archive at the root.
%
%   Each output keeps the original video's exact filename with _preprocessed
%   appended, so it is obvious which .avi it came from:
%     og_large_vids\PVFP_28_HabD1_SV_Aug20_camera_2026-08-20_11-42-01.avi
%     HabD1\PVFP_28_HabD1_SV_Aug20_camera_2026-08-20_11-42-01_preprocessed.mp4
%
%   Sessions whose *_preprocessed.mp4 already exists are skipped, so it is
%   safe to re-run and resumes where it left off.
%
%   NAME-VALUE OPTIONS (mirror the Python flags)
%     'root'          (required) experiment folder holding the day folders
%     'days'          e.g. 'HabD1,HabD3'  -- limit to certain day folders
%     'only'          e.g. 'PVFP_28'      -- limit to certain sessions
%     'resolution'    default '640x480'   -- WxH of the video portion
%     'codec'         'libx265' (default) or 'libx264'
%     'crf'           default 24
%     'preset'        default 'veryfast'
%     'limitSeconds'  >0 encodes only the first N seconds (test runs get their
%                     own _TESTNs.mp4 filename, never the real output name)
%     'force'         true re-encodes sessions whose output already exists
%     'noArchive'     true leaves originals where they are
%     'dryRun'        true lists the plan and changes nothing
%     'ffmpeg'/'ffprobe'  full paths to the executables
%
%   ASSUMPTIONS (worth sanity-checking against how the rig behaves):
%     * "reward delivery" = each state 0 -> state 1 pair on the
%       reward_delivery pin (one pump/solenoid pulse).
%     * "beam break" = each IR_beam_check transition to state 1.
%     * ITI is not separately logged; it is simply "neither tone nor shock on".
%     * camera_on (mat file) is treated as t=0 for the video; the difference
%       against the video's own duration is printed as a sanity check.
%
%   Requires an ffmpeg/ffprobe build with libx264, libx265, drawtext
%   (libfreetype), drawbox, overlay and pad.

%% ========================================================================
%  USER SETTINGS -- edit these, save, then just press Run.
%  ========================================================================
%  Pressing Run uses exactly these values. Anything passed as a name-value
%  pair overrides the matching line below, so both ways of working still
%  behave the same.

CFG.root = 'C:\Users\boba4\Desktop\Sam V\2026-08-20_PVcre.Fp_PMA_TMS';

% SV, August 25, 2026: I added
% SAFETY GATE: shows a window listing every file that will be created, every
% original that will be moved, the disk use and a time estimate -- with Run
% and Quit buttons. Nothing happens until you click Run.
% Set false only for headless/scripted use (then it starts immediately).
CFG.showDialog = true;
%

% SV, August 25, 2026: I added
% Browse for the experiment folder instead of using CFG.root as-is.
% CFG.root is still the starting location the browser opens at.
CFG.pickFolder = true;

% Show a checklist of every session found, so you tick exactly which ones to
% run. Already-finished sessions appear unticked and are re-encoded only if
% you tick them.
CFG.pickSessions = true;
%

% SV, August 25, 2026: I changed
% % SAFETY: true = print the plan and stop, changing nothing.
% % Set this to false when you are ready to actually encode and move files.
% CFG.dryRun = true;
% to this:
% true = print the plan to the Command Window and stop. No window, no work.
% (Default flipped to false because the confirmation window above is now the
% safety gate -- a dry run is no longer the only way to preview safely.)
CFG.dryRun = false;
%

CFG.days   = '';          % '' = all day folders.  e.g. 'HabD1,HabD3'
CFG.only   = '';          % '' = all sessions.     e.g. 'PVFP_28'

CFG.resolution = '640x480';
CFG.codec      = 'libx265';   % 'libx265' (smaller) or 'libx264' (faster)
CFG.crf        = 24;          % lower = better quality, bigger file
CFG.preset     = 'veryfast';

CFG.limitSeconds = 0;      % >0 encodes only the first N seconds, for testing
CFG.force        = false;  % true re-encodes sessions already done
CFG.noArchive    = false;  % true leaves the original .avi files where they are

% SV, August 25, 2026: I changed
% CFG.ffmpeg  = 'C:\Users\boba4\Desktop\PMA Software\ffmpeg-8.1.1-essentials_build-20260822T005010Z-1-001\ffmpeg-8.1.1-essentials_build\bin\ffmpeg.exe';
% CFG.ffprobe = 'C:\Users\boba4\Desktop\PMA Software\ffmpeg-8.1.1-essentials_build-20260822T005010Z-1-001\ffmpeg-8.1.1-essentials_build\bin\ffprobe.exe';
% to this:
% (a hardcoded path breaks the moment the PMA Software folder is renamed or
% moved -- resolveTool searches for the executable instead, so it keeps
% working. Leave these empty to auto-find; set one to force a specific exe.)
CFG.ffmpeg  = '';
CFG.ffprobe = '';
%

%  ========================================================================
%  Nothing below here needs editing for normal use.
%  ========================================================================

p = inputParser;
addParameter(p, 'root',         CFG.root,         @(x) ischar(x) || isstring(x));
addParameter(p, 'days',         CFG.days,         @(x) ischar(x) || isstring(x));
addParameter(p, 'only',         CFG.only,         @(x) ischar(x) || isstring(x));
addParameter(p, 'resolution',   CFG.resolution,   @(x) ischar(x) || isstring(x));
addParameter(p, 'codec',        CFG.codec,        @(x) any(strcmp(x, {'libx264','libx265'})));
addParameter(p, 'crf',          CFG.crf,          @isnumeric);
addParameter(p, 'preset',       CFG.preset,       @(x) ischar(x) || isstring(x));
addParameter(p, 'ffmpeg',       CFG.ffmpeg,       @(x) ischar(x) || isstring(x));
addParameter(p, 'ffprobe',      CFG.ffprobe,      @(x) ischar(x) || isstring(x));
addParameter(p, 'limitSeconds', CFG.limitSeconds, @isnumeric);
addParameter(p, 'force',        CFG.force,        @(x) islogical(x) || isnumeric(x));
addParameter(p, 'noArchive',    CFG.noArchive,    @(x) islogical(x) || isnumeric(x));
addParameter(p, 'dryRun',       CFG.dryRun,       @(x) islogical(x) || isnumeric(x));
% SV, August 25, 2026: I added
addParameter(p, 'showDialog',   CFG.showDialog,   @(x) islogical(x) || isnumeric(x));
addParameter(p, 'pickFolder',   CFG.pickFolder,   @(x) islogical(x) || isnumeric(x));
addParameter(p, 'pickSessions', CFG.pickSessions, @(x) islogical(x) || isnumeric(x));
%
parse(p, varargin{:});
opt = p.Results;

opt.root    = char(opt.root);
opt.days    = char(opt.days);
opt.only    = char(opt.only);
opt.codec   = char(opt.codec);
opt.preset  = char(opt.preset);
opt.ffmpeg  = char(opt.ffmpeg);
opt.ffprobe = char(opt.ffprobe);

if isempty(opt.root)
    error('preprocess_video:noRoot', ...
        ['No ''root'' folder set.\n\n' ...
         'Open %s.m and set CFG.root near the top to your experiment ' ...
         'folder, then press Run.'], mfilename);
end
if ~isfolder(opt.root)
    error('preprocess_video:badRoot', ...
        '''root'' is not a folder:\n    %s', opt.root);
end

% SV, August 25, 2026: I added
% Locate ffmpeg/ffprobe rather than trusting a hardcoded path, so renaming or
% moving the PMA Software folder does not break the tool.
opt.ffmpeg  = resolveTool(opt.ffmpeg,  'ffmpeg.exe');
opt.ffprobe = resolveTool(opt.ffprobe, 'ffprobe.exe');
%

res = regexp(char(opt.resolution), '^(\d+)[xX](\d+)$', 'tokens', 'once');
if isempty(res)
    error('preprocess_video:badResolution', ...
        '''resolution'' must look like 640x480, got: %s', char(opt.resolution));
end
opt.targetW = str2double(res{1});
opt.targetH = str2double(res{2});

cfg = layoutConfig();

% SV, August 25, 2026: I added
% Browse for the experiment folder. Done before anything is derived from
% opt.root, so archiveDir/workDir below pick up whatever is chosen here.
useGui = opt.showDialog && usejava('desktop');
if useGui && opt.pickFolder
    picked = uigetdir(opt.root, ...
        'Select the experiment folder (the one containing HabD1, HabD2, ...)');
    if isequal(picked, 0)
        fprintf('Cancelled at folder selection -- nothing was changed.\n');
        return;
    end
    opt.root = picked;
end
%

archiveDir = fullfile(opt.root, cfg.archiveDirName);
workDir    = fullfile(opt.root, '_preprocess_work');
if ~isfolder(workDir)
    mkdir(workDir);
end

days = findDayFolders(opt.root, opt.days, cfg.archiveDirName);
if isempty(days)
    error('preprocess_video:noDays', ...
        'No day folders with .mat files found under %s', opt.root);
end

% --- plan first, so the run's scope is visible before anything happens ---
% SV, August 25, 2026: I changed
% todo = {};
% skipped = {};
% for k = 1:numel(days)
%     sessions = findSessions(days{k}, archiveDir, cfg.archiveDirName);
%     for j = 1:numel(sessions)
%         s = sessions{j};
%         if ~isempty(opt.only) && ~contains(s.prefix, opt.only)
%             continue;
%         end
%         if isfile(s.out) && ~opt.force
%             skipped{end+1} = s; %#ok<AGROW>
%         else
%             todo{end+1} = s; %#ok<AGROW>
%         end
%     end
% end
% to this:
% (collect every session first with a done/not-done flag, so the checklist
% can show all of them and let the user tick exactly what to run)
allSessions = {};
for k = 1:numel(days)
    sessions = findSessions(days{k}, archiveDir, cfg.archiveDirName);
    for j = 1:numel(sessions)
        s = sessions{j};
        if ~isempty(opt.only) && ~contains(s.prefix, opt.only)
            continue;
        end
        s.alreadyDone = isfile(s.out);
        allSessions{end+1} = s; %#ok<AGROW>
    end
end

% Default selection: everything not already finished (or everything, with
% 'force'). The checklist below can override this either way.
defaultPick = false(1, numel(allSessions));
for k = 1:numel(allSessions)
    defaultPick(k) = opt.force || ~allSessions{k}.alreadyDone;
end

if useGui && opt.pickSessions && ~isempty(allSessions)
    [chosen, ok] = selectSessionsDialog(allSessions, defaultPick, opt.root);
    if ~ok
        fprintf('Cancelled at session selection -- nothing was changed.\n');
        return;
    end
else
    chosen = defaultPick;
end

todo = allSessions(chosen);
skipped = allSessions(~chosen);
%

% SV, August 25, 2026: I changed
% fprintf('Root:    %s\n', opt.root);
% fprintf('Archive: %s\n', archiveDir);
% dayNames = cell(1, numel(days));
% for k = 1:numel(days)
%     [~, dayNames{k}] = fileparts(days{k});
% end
% fprintf('Days:    %s\n', strjoin(dayNames, ', '));
% fprintf('To encode: %d   already done (skipped): %d\n', numel(todo), numel(skipped));
% for k = 1:numel(skipped)
%     [~, n, e] = fileparts(skipped{k}.out);
%     fprintf('  [skip] %s -- %s exists\n', skipped{k}.prefix, [n e]);
% end
% for k = 1:numel(todo)
%     [~, n, e] = fileparts(todo{k}.avi);
%     [~, on_, oe] = fileparts(testOutputPath(todo{k}.out, opt.limitSeconds));
%     fprintf('  [todo] %s\n', [n e]);
%     fprintf('           -> %s\n', [on_ oe]);
% end
% to this:
dayNames = cell(1, numel(days));
for k = 1:numel(days)
    [~, dayNames{k}] = fileparts(days{k});
end

% Probe each source once, up front: gives frame counts for the progress bars
% and a time estimate for the plan window.
if ~isempty(todo)
    fprintf('Reading video details for %d file(s)...\n', numel(todo));
    for k = 1:numel(todo)
        todo{k}.probe = probeVideo(opt.ffprobe, todo{k}.avi);
        todo{k}.frames = plannedFrames(todo{k}.probe, opt.limitSeconds);
    end
end

[planLines, summary] = buildPlanText(todo, skipped, opt, archiveDir, dayNames);

% Console summary stays short; the full list lives in the window (or below,
% for a dry run).
fprintf('%s\n', summary.header{:});

if opt.dryRun
    fprintf('\n');
    fprintf('%s\n', planLines{:});
    fprintf('\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('DRY RUN -- nothing was encoded, nothing was moved.\n');
    fprintf('Set CFG.dryRun = false to run it for real.\n');
    fprintf('------------------------------------------------------------\n');
    return;
end
if isempty(todo)
    fprintf('\nNothing to do.\n');
    return;
end

% SV, August 25, 2026: I added
% --- confirmation window: nothing has been touched up to this point ---
if opt.showDialog
    if ~usejava('desktop')
        warning('preprocess_video:noDisplay', ...
            ['No MATLAB desktop available, so the confirmation window ' ...
             'cannot be shown. Starting immediately.']);
    else
        if ~planDialog(planLines, summary)
            fprintf('\nQuit -- nothing was encoded, nothing was moved.\n');
            return;
        end
    end
end
%

failures = {};
% SV, August 25, 2026: I changed
% for k = 1:numel(todo)
%     fprintf('\n[%d/%d] ', k, numel(todo));
%     try
%         processSession(todo{k}, opt, cfg, workDir);
% to this:
% (runStart feeds the overall "time left" estimate; the extra arguments let
% processSession title its progress bar "Encoding k of N".)
runStart = tic;
for k = 1:numel(todo)
    fprintf('[%d/%d] %s ... ', k, numel(todo), todo{k}.prefix);
    try
        processSession(todo{k}, opt, cfg, workDir, k, numel(todo), runStart);
%
    catch err
        fprintf('\n');
        fprintf(2, '  [FAILED] %s: %s\n', todo{k}.prefix, err.message);
        failures{end+1} = todo{k}.prefix; %#ok<AGROW>
        continue;
    end
    if ~opt.noArchive && opt.limitSeconds <= 0
        archiveOriginal(todo{k}.avi, archiveDir, todo{k}.prefix);
    end
end

fprintf('\nFinished. Encoded %d/%d in %s.\n', ...
    numel(todo) - numel(failures), numel(todo), fmtDuration(toc(runStart)));
if ~isempty(failures)
    fprintf(2, 'Failed: %s\n', strjoin(failures, ', '));
end
end


% ========================================================================
% Plan text + confirmation window
% SV, August 25, 2026: I added this whole section (plannedFrames,
% fmtDuration, buildPlanText, planDialog). v1 had none of it -- it printed
% the plan to the Command Window and started immediately.
% ========================================================================
function n = plannedFrames(probe, limitSeconds)
%PLANNEDFRAMES How many frames this encode will actually write.
n = probe.nbFrames;
if limitSeconds > 0
    n = min(n, round(limitSeconds * probe.fps));
end
end


function s = fmtDuration(sec)
if ~isfinite(sec) || sec < 0
    s = '?';
    return;
end
h = floor(sec / 3600);
m = floor(mod(sec, 3600) / 60);
if h > 0
    s = sprintf('%dh %02dm', h, m);
elseif m > 0
    s = sprintf('%dm %02ds', m, floor(mod(sec, 60)));
else
    s = sprintf('%ds', round(sec));
end
end


function [lines, summary] = buildPlanText(todo, skipped, opt, archiveDir, dayNames)
%BUILDPLANTEXT Human-readable plan: what gets made from what, what moves
%   where, how big, how long.

% Encode speed actually measured on this rig for x265/veryfast at 640x480.
% Only used for the up-front estimate; the live ETA replaces it once the
% first video finishes.
if strcmp(opt.codec, 'libx265')
    assumedFps = 85;
else
    assumedFps = 260;
end

totalFrames = 0;
totalSrcBytes = 0;
for k = 1:numel(todo)
    totalFrames = totalFrames + todo{k}.frames;
    d = dir(todo{k}.avi);
    if ~isempty(d)
        totalSrcBytes = totalSrcBytes + d.bytes;
    end
end
estSeconds = totalFrames / assumedFps;

lines = {};
lines{end+1} = sprintf('%d video(s) will be created:', numel(todo));
lines{end+1} = '';
nRedo = 0;
for k = 1:numel(todo)
    [~, sn, se] = fileparts(todo{k}.avi);
    [outDir, on_, oe] = fileparts(testOutputPath(todo{k}.out, opt.limitSeconds));
    [~, dayName] = fileparts(outDir);
    lines{end+1} = sprintf('%2d. %s', k, [sn se]); %#ok<AGROW>
    % Flag overwrites explicitly -- a ticked already-done session replaces
    % the existing file, which is worth seeing before clicking Run.
    if isfield(todo{k}, 'alreadyDone') && todo{k}.alreadyDone
        nRedo = nRedo + 1;
        lines{end+1} = sprintf('     -> %s\\%s   *** OVERWRITES EXISTING ***', ...
            dayName, [on_ oe]); %#ok<AGROW>
    else
        lines{end+1} = sprintf('     -> %s\\%s', dayName, [on_ oe]); %#ok<AGROW>
    end
    lines{end+1} = sprintf('        (%d frames, %s)', ...
        todo{k}.frames, fmtDuration(todo{k}.frames / assumedFps)); %#ok<AGROW>
end

lines{end+1} = '';
if opt.noArchive || opt.limitSeconds > 0
    lines{end+1} = 'Originals: left where they are (not moved).';
else
    lines{end+1} = sprintf('The %d original .avi file(s) above (%.1f GB) will then be MOVED to:', ...
        numel(todo), totalSrcBytes / 1024^3);
    lines{end+1} = sprintf('     %s', archiveDir);
    lines{end+1} = '(Moved, not deleted -- and only after that video encodes successfully.)';
end

if ~isempty(skipped)
    lines{end+1} = '';
    % Not all skipped sessions are skipped for the same reason now: some are
    % already done, others were simply left unticked in the checklist.
    lines{end+1} = sprintf('Not being processed (%d):', numel(skipped));
    for k = 1:numel(skipped)
        [~, n, e] = fileparts(skipped{k}.out);
        if isfield(skipped{k}, 'alreadyDone') && skipped{k}.alreadyDone
            why = 'already done';
        else
            why = 'not selected';
        end
        lines{end+1} = sprintf('     %-62s (%s)', [n e], why); %#ok<AGROW>
    end
end

summary = struct();
summary.count      = numel(todo);
summary.estSeconds = estSeconds;
summary.header = { ...
    sprintf('Root:    %s', opt.root); ...
    sprintf('Archive: %s', archiveDir); ...
    sprintf('Days:    %s', strjoin(dayNames, ', ')); ...
    sprintf('To encode: %d   already done (skipped): %d', numel(todo), numel(skipped)) };

redoTxt = '';
if nRedo > 0
    redoTxt = sprintf('  |  %d will OVERWRITE an existing file', nRedo);
end
summary.blurb = sprintf( ...
    ['%d video(s) to encode  |  est. %s  |  %s, crf %d, %s, %dx%d%s\n' ...
     'Nothing has been changed yet. Review the list below, then choose.'], ...
    numel(todo), fmtDuration(estSeconds), opt.codec, opt.crf, opt.preset, ...
    opt.targetW, opt.targetH, redoTxt);
end


% SV, August 25, 2026: I added selectSessionsDialog.
function [chosen, ok] = selectSessionsDialog(allSessions, defaultPick, root)
%SELECTSESSIONSDIALOG Tick which sessions to run.
%   Returns a logical mask over allSessions, and ok=false if the user
%   cancelled. Already-finished sessions are listed but start unticked;
%   ticking one means "re-encode and overwrite".
%
%   Rows show file size straight from dir() rather than a probed duration --
%   probing every file first would stall this window for several seconds.

chosen = defaultPick;
ok = false;

labels = cell(1, numel(allSessions));
for k = 1:numel(allSessions)
    d = dir(allSessions{k}.avi);
    if isempty(d)
        szTxt = '   ? GB';
    else
        szTxt = sprintf('%5.1f GB', d.bytes / 1024^3);
    end
    [~, dayName] = fileparts(allSessions{k}.sessionDir);
    if allSessions{k}.alreadyDone
        status = '  [already done -- tick to redo]';
    else
        status = '';
    end
    labels{k} = sprintf('%-6s  %-26s  %s%s', ...
        dayName, allSessions{k}.prefix, szTxt, status);
end

W = 720; H = 520;
scr = get(0, 'ScreenSize');
f = figure( ...
    'Name', 'Choose sessions to process', ...
    'NumberTitle', 'off', 'MenuBar', 'none', 'ToolBar', 'none', ...
    'Units', 'pixels', ...
    'Position', [scr(3)/2 - W/2, scr(4)/2 - H/2, W, H], ...
    'Color', [0.94 0.94 0.94], ...
    'WindowStyle', 'modal', ...
    'CloseRequestFcn', @onCancel);

uicontrol(f, 'Style', 'text', ...
    'Units', 'pixels', 'Position', [20 H-70 W-40 50], ...
    'String', sprintf(['Found %d session(s) in:\n%s\n' ...
                       'Ctrl-click / shift-click to change the selection.'], ...
                      numel(allSessions), root), ...
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
    'String', 'Continue', 'FontSize', 10, 'FontWeight', 'bold', ...
    'Callback', @onContinue);

uiwait(f);

    function onContinue(~, ~)
        sel = get(lb, 'Value');
        chosen = false(1, numel(allSessions));
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


function goAhead = planDialog(lines, summary)
%PLANDIALOG Modal window showing the plan, with Run and Quit buttons.
%   Returns true only if the user clicks Run. Closing the window = Quit.
goAhead = false;

W = 760; H = 560;
scr = get(0, 'ScreenSize');
f = figure( ...
    'Name', 'Video preprocessing -- review before running', ...
    'NumberTitle', 'off', 'MenuBar', 'none', 'ToolBar', 'none', ...
    'Units', 'pixels', ...
    'Position', [scr(3)/2 - W/2, scr(4)/2 - H/2, W, H], ...
    'Color', [0.94 0.94 0.94], ...
    'WindowStyle', 'modal', ...
    'CloseRequestFcn', @onQuit);

uicontrol(f, 'Style', 'text', ...
    'Units', 'pixels', 'Position', [20 H-78 W-40 58], ...
    'String', summary.blurb, ...
    'HorizontalAlignment', 'left', ...
    'FontSize', 10, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.94 0.94 0.94]);

uicontrol(f, 'Style', 'listbox', ...
    'Units', 'pixels', 'Position', [20 80 W-40 H-170], ...
    'String', lines, ...
    'FontName', 'Consolas', 'FontSize', 9, ...
    'Value', 1, 'Min', 0, 'Max', 2, ...   % Max>1 => no selection highlight
    'BackgroundColor', [1 1 1]);

uicontrol(f, 'Style', 'pushbutton', ...
    'Units', 'pixels', 'Position', [W-330 25 140 38], ...
    'String', 'Quit', 'FontSize', 10, ...
    'Callback', @onQuit);

uicontrol(f, 'Style', 'pushbutton', ...
    'Units', 'pixels', 'Position', [W-170 25 150 38], ...
    'String', 'Run', 'FontSize', 10, 'FontWeight', 'bold', ...
    'Callback', @onRun);

uicontrol(f, 'Style', 'text', ...
    'Units', 'pixels', 'Position', [20 28 W-360 32], ...
    'String', 'Run starts encoding and moves originals. Quit changes nothing.', ...
    'HorizontalAlignment', 'left', 'FontSize', 9, ...
    'ForegroundColor', [0.35 0.35 0.35], ...
    'BackgroundColor', [0.94 0.94 0.94]);

uiwait(f);

    function onRun(~, ~)
        goAhead = true;
        delete(f);
    end

    function onQuit(~, ~)
        goAhead = false;
        delete(f);
    end
end


% SV, August 27, 2026: I added preferencesDialog.
% ========================================================================
% Run-time settings window (CLAUDE.md rule 12)
% ========================================================================
function [cfg, ok] = preferencesDialog(defaults)
%PREFERENCESDIALOG Settings window shown on Run.
%   Every value that would otherwise require opening and editing this
%   script -- the experiment folder plus every encode setting -- is asked
%   for here instead, pre-filled from `defaults` (the DEFAULTS block near
%   the top of this file), so someone else in the lab never has to touch
%   the code. Returns a struct with the same fields as `defaults`, and
%   ok=false if the window was cancelled (Quit, or the close box).

cfg = defaults;
ok = false;

W = 640; H = 660;
scr = get(0, 'ScreenSize');
f = figure( ...
    'Name', 'Preprocessing settings -- fill in and click Run', ...
    'NumberTitle', 'off', 'MenuBar', 'none', 'ToolBar', 'none', ...
    'Units', 'pixels', ...
    'Position', [scr(3)/2 - W/2, scr(4)/2 - H/2, W, H], ...
    'Color', [0.94 0.94 0.94], ...
    'WindowStyle', 'modal', ...
    'CloseRequestFcn', @onQuit);

y = H - 20;   % top-down layout cursor -- each helper below moves it down

uicontrol(f, 'Style', 'text', 'Units', 'pixels', ...
    'Position', [20 y-34 W-40 34], ...
    'String', ['Every field is pre-filled with this script''s built-in defaults -- ' ...
               'change what you need, or just click Run.'], ...
    'HorizontalAlignment', 'left', 'FontSize', 9, ...
    'BackgroundColor', [0.94 0.94 0.94]);
y = y - 44;

    function label(txt)
        uicontrol(f, 'Style', 'text', 'Units', 'pixels', ...
            'Position', [20 y-16 W-40 16], ...
            'String', txt, 'HorizontalAlignment', 'left', 'FontSize', 9, ...
            'FontWeight', 'bold', 'BackgroundColor', [0.94 0.94 0.94]);
        y = y - 20;
    end

    function h = editRow(initial, browseFilter, widthOverride)
        %EDITROW One edit box. browseFilter = 'folder' adds a folder-picker
        %   Browse... button; a uigetfile filter cell adds a file picker;
        %   '' (default) adds no button. widthOverride shortens the box for
        %   fields that are always short (numbers), leaving the rest blank.
        if nargin < 2; browseFilter = ''; end
        if nargin < 3 || isempty(widthOverride)
            if isempty(browseFilter)
                w = W - 40;
            else
                w = W - 40 - 110;
            end
        else
            w = widthOverride;
        end
        h = uicontrol(f, 'Style', 'edit', 'Units', 'pixels', ...
            'Position', [20 y-28 w 26], ...
            'String', initial, 'HorizontalAlignment', 'left', ...
            'BackgroundColor', [1 1 1]);
        if ~isempty(browseFilter)
            if ischar(browseFilter) && strcmp(browseFilter, 'folder')
                cb = @(~,~) browseFolder(h);
            else
                cb = @(~,~) browseFile(h, browseFilter);
            end
            uicontrol(f, 'Style', 'pushbutton', 'Units', 'pixels', ...
                'Position', [20+w+10 y-28 100 26], ...
                'String', 'Browse...', 'FontSize', 9, 'Callback', cb);
        end
        y = y - 38;
    end

    function browseFolder(h)
        start = get(h, 'String');
        if ~isfolder(start)
            start = defaults.startingFolder;
        end
        picked = uigetdir(start, 'Select the experiment folder (the one containing the day folders)');
        if ~isequal(picked, 0)
            set(h, 'String', picked);
        end
    end

    function browseFile(h, filterSpec)
        start = get(h, 'String');
        if isempty(start) || ~isfile(start)
            startDir = pwd;
        else
            startDir = fileparts(start);
        end
        [fn, fp] = uigetfile(filterSpec, 'Select the executable', startDir);
        if ~isequal(fn, 0)
            set(h, 'String', fullfile(fp, fn));
        end
    end

    function h = popupRow(items, currentValue)
        idx = find(strcmp(items, currentValue), 1);
        if isempty(idx); idx = 1; end
        h = uicontrol(f, 'Style', 'popupmenu', 'Units', 'pixels', ...
            'Position', [20 y-28 200 26], ...
            'String', items, 'Value', idx, 'BackgroundColor', [1 1 1]);
        y = y - 38;
    end

    function h = checkRow(txt, currentValue)
        h = uicontrol(f, 'Style', 'checkbox', 'Units', 'pixels', ...
            'Position', [20 y-24 W-40 24], ...
            'String', txt, 'Value', currentValue, 'FontSize', 9, ...
            'BackgroundColor', [0.94 0.94 0.94]);
        y = y - 32;
    end

label('Experiment folder (the one CONTAINING the day folders -- see the header comment at the top of this file for a worked example):');
hFolder = editRow(defaults.startingFolder, 'folder');

label('Video resolution (WxH):');
hRes = editRow(defaults.resolution, '', 160);

label('Codec:');
hCodec = popupRow({'libx265', 'libx264'}, defaults.codec);

label('Quality (CRF -- lower = better quality, bigger file; 18 high, 28 small):');
hCrf = editRow(num2str(defaults.crf), '', 100);

label('Encode speed preset (slower = slightly smaller file):');
hPreset = popupRow({'ultrafast', 'veryfast', 'medium', 'slow'}, defaults.preset);

hMove = checkRow('Move original .avi files into og_large_vids\ after encoding', ...
    defaults.moveOriginals);

label('Test only the first N seconds, to preview quickly (0 = full video):');
hTest = editRow(num2str(defaults.testSeconds), '', 100);

label('ffmpeg.exe path (leave blank to find it automatically):');
hFfmpeg = editRow(defaults.ffmpegExe, {'*.exe', 'Executable files (*.exe)'});

label('ffprobe.exe path (leave blank to find it automatically):');
hFfprobe = editRow(defaults.ffprobeExe, {'*.exe', 'Executable files (*.exe)'});

uicontrol(f, 'Style', 'pushbutton', ...
    'Units', 'pixels', 'Position', [W-330 20 140 38], ...
    'String', 'Quit', 'FontSize', 10, ...
    'Callback', @onQuit);

uicontrol(f, 'Style', 'pushbutton', ...
    'Units', 'pixels', 'Position', [W-170 20 150 38], ...
    'String', 'Run', 'FontSize', 10, 'FontWeight', 'bold', ...
    'Callback', @onRun);

uiwait(f);

    function onRun(~, ~)
        folder = strtrim(get(hFolder, 'String'));
        if isempty(folder) || ~isfolder(folder)
            errordlg(sprintf('This is not a folder that exists:\n%s', folder), ...
                'Preprocessing settings', 'modal');
            return;
        end
        resStr = strtrim(get(hRes, 'String'));
        if isempty(regexp(resStr, '^\d+[xX]\d+$', 'once'))
            errordlg('Video resolution must look like 640x480.', ...
                'Preprocessing settings', 'modal');
            return;
        end
        crfVal = str2double(get(hCrf, 'String'));
        if isnan(crfVal) || crfVal < 0
            errordlg('Quality (CRF) must be a number, e.g. 24.', ...
                'Preprocessing settings', 'modal');
            return;
        end
        testVal = str2double(get(hTest, 'String'));
        if isnan(testVal) || testVal < 0
            errordlg('Test seconds must be a number, 0 or more.', ...
                'Preprocessing settings', 'modal');
            return;
        end

        codecItems  = get(hCodec, 'String');
        presetItems = get(hPreset, 'String');

        cfg.startingFolder = folder;
        cfg.resolution     = resStr;
        cfg.codec          = codecItems{get(hCodec, 'Value')};
        cfg.crf            = crfVal;
        cfg.preset         = presetItems{get(hPreset, 'Value')};
        cfg.moveOriginals  = logical(get(hMove, 'Value'));
        cfg.testSeconds    = testVal;
        cfg.ffmpegExe      = strtrim(get(hFfmpeg, 'String'));
        cfg.ffprobeExe     = strtrim(get(hFfprobe, 'String'));

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
% Layout / style configuration
% ========================================================================
function cfg = layoutConfig()
cfg.archiveDirName = 'og_large_vids';
cfg.panelHeight    = 110;      % px, added above the frame, never overlapping it
cfg.toneColor      = [255 205 0];
cfg.shockColor     = [230 40 40];
cfg.timelineBg     = [55 55 55];
cfg.timelineTone   = [255 205 0];
cfg.timelineShock  = [230 40 40];
cfg.timelineReward = [60 210 90];    % green -- reward_delivery ticks
cfg.timelineBeam   = [60 170 255];   % blue  -- IR_beam_check ticks
cfg.playheadColor  = [255 255 255];
% SV, August 25, 2026: I added
% Shading for the stretch of a session that has no video, i.e. the camera
% stopped before the task did. Muted enough that event ticks stay readable
% on top of it.
cfg.timelineNoVideo = [95 30 30];
%
cfg.panelBg        = [18 18 18];
cfg.textColor      = 'white';
cfg.timelineY0     = 6;
cfg.timelineH      = 18;
cfg.eventTickW     = 1;   % green/blue event ticks -- deliberately hairline
cfg.playheadW      = 2;   % white playhead -- slightly thicker so it reads as the cursor
cfg.playheadH      = cfg.timelineH + 8;
cfg.fontFile       = 'C\:/Windows/Fonts/segoeui.ttf';  % ffmpeg-escaped drive colon
end


% SV, August 25, 2026: I added resolveTool.
function exePath = resolveTool(explicitPath, exeName)
%RESOLVETOOL Find ffmpeg.exe / ffprobe.exe without a hardcoded path.
%
%   Order tried:
%     1. explicitPath, if given and it exists
%     2. alongside this engine, under a sibling of the PMA software folder
%        (searched recursively, so the ffmpeg build folder name can change)
%     3. whatever is on the system PATH
%
%   Written this way because the folder holding ffmpeg gets renamed
%   ("PMA Software" -> "PMA_Software") and the build folder carries a version
%   stamp that changes on every ffmpeg update. A literal path would silently
%   rot; this does not.

explicitPath = char(explicitPath);
if ~isempty(explicitPath) && isfile(explicitPath)
    exePath = explicitPath;
    return;
end

% SV, August 27, 2026: I changed
% % This file lives in <software root>\engine\, so go up one level and search.
% thisDir  = fileparts(mfilename('fullpath'));
% softRoot = fileparts(thisDir);
% to this:
% (in the SVv3 standalone file this function lives directly in the software
% root, not inside an engine\ subfolder -- so there is no extra level to
% strip off. Climbing one level here, as the two-file SVv2 version does,
% would search from Desktop\ instead of Desktop\PMA Software\ and could
% miss ffmpeg or pick up a stray copy elsewhere on the Desktop.)
thisDir  = fileparts(mfilename('fullpath'));
softRoot = thisDir;
%

hits = dir(fullfile(softRoot, '**', exeName));
hits = hits(~[hits.isdir]);
if ~isempty(hits)
    % Prefer a path containing \bin\ -- that is the real executable rather
    % than a stray copy in a docs/presets folder.
    isBin = contains(lower({hits.folder}), [filesep 'bin']);
    if any(isBin)
        hits = hits(isBin);
    end
    exePath = fullfile(hits(1).folder, hits(1).name);
    return;
end

% Fall back to PATH.
[status, out] = system(['where ' exeName]);
if status == 0
    lines = strsplit(strtrim(out), newline);
    cand = strtrim(lines{1});
    if isfile(cand)
        exePath = cand;
        return;
    end
end

error('preprocess_video:noFfmpeg', ...
    ['Could not find %s.\n\n' ...
     'Looked in:\n  %s  (and subfolders)\n  and on the system PATH.\n\n' ...
     'Fix: put the ffmpeg build back under that folder, or set the ffmpeg/\n' ...
     'ffprobe path explicitly in the settings block of the script you ran.'], ...
    exeName, softRoot);
end


% ========================================================================
% Discovery
% ========================================================================
function days = findDayFolders(root, onlyDays, archiveDirName)
%FINDDAYFOLDERS Folders that hold .mat session files directly, one call
%   below root -- normally the experiment root's immediate subfolders (day
%   folders like HabD1, each holding every mouse's .mat side by side).
%
%   SV / Claude, September 2, 2026: I added -- if THAT search comes up
%   completely empty, search one level deeper before giving up. This covers
%   a root organized as <root>\<condition>\<session>\*.mat (BehaviorDEPOT's
%   own reorganized layout: condition folders like sham_HabD1s1, each
%   holding one single-session subfolder per animal) -- there, no condition
%   folder itself holds a .mat directly, but each SESSION folder one level
%   further in does, so each of THOSE becomes its own one-.mat "day folder"
%   here. findSessions (below) handles a one-.mat day folder fine either
%   way -- it just finds the single .mat/avi pair in it -- so nothing
%   downstream needed to change. A root with real .mat-holding day folders
%   at the first level (the original flat layout) never reaches this
%   fallback, since it only runs when that first search finds nothing.
days = findMatFolders(root, archiveDirName);
if isempty(days)
    deeper = {};
    d = dir(root);
    d = d([d.isdir]);
    for k = 1:numel(d)
        name = d(k).name;
        if strcmp(name, '.') || strcmp(name, '..') || strcmp(name, archiveDirName)
            continue;
        end
        if startsWith(name, '_')   % _preprocess_work and friends
            continue;
        end
        deeper = [deeper, findMatFolders(fullfile(root, name), archiveDirName)]; %#ok<AGROW>
    end
    if ~isempty(deeper)
        fprintf(['No .mat files directly under %s -- found %d session folder(s) one level ' ...
                 'deeper instead (e.g. <condition>\\<session>\\*.mat). Using those as the day/' ...
                 'session list below.\n'], root, numel(deeper));
        days = deeper;
    end
end
days = sort(days);

if ~isempty(onlyDays)
    wanted = lower(strtrim(strsplit(onlyDays, ',')));
    keep = false(1, numel(days));
    for k = 1:numel(days)
        [~, n] = fileparts(days{k});
        % At the deeper fallback, "day folder" basenames are session names
        % (DCSP_14_sham_HabD1s1_SV_Feb7), not day names -- so also match
        % against the PARENT folder's name (sham_HabD1s1), which is what
        % 'days' actually means one level up from there.
        [parentPath, ~] = fileparts(days{k});
        [~, parentName] = fileparts(parentPath);
        keep(k) = any(strcmp(lower(n), wanted)) || any(strcmp(lower(parentName), wanted));
    end
    days = days(keep);
end
end

function found = findMatFolders(base, archiveDirName)
%FINDMATFOLDERS Immediate subfolders of base that hold a SESSION .mat file
%   directly -- one matching findSessions' own filename pattern
%   (<prefix>_YYYY-MM-DD_HH-MM-SS.mat), not just any .mat file at all.
%
%   SV / Claude, September 2, 2026: I changed this from "any *.mat present"
%   to this stricter regex match. A folder can hold a .mat that has nothing
%   to do with a behavior session -- e.g. DCSP_AllCoh_TmsFp_SV_photometry\
%   has loose TMS_GroupSummary_..._20260901_172257.mat files sitting in it
%   from an earlier analysis run. Those matched "any .mat" and got counted
%   as a one-session "day folder," which made findDayFolders' depth-1 scan
%   come back non-empty and skip the deeper fallback entirely -- silently
%   producing a "Days: DCSP_AllCoh_TmsFp_SV_photometry / 0 to encode"
%   result instead of finding the real session folders one level down.
%   Matching the actual session pattern here is what findSessions was
%   always going to require anyway, so this can only narrow correctly.
found = {};
d = dir(base);
d = d([d.isdir]);
for k = 1:numel(d)
    name = d(k).name;
    if strcmp(name, '.') || strcmp(name, '..') || strcmp(name, archiveDirName)
        continue;
    end
    if startsWith(name, '_')   % _preprocess_work and friends
        continue;
    end
    full = fullfile(base, name);
    mats = dir(fullfile(full, '*.mat'));
    isSessionMat = arrayfun(@(m) ~isempty(regexp(m.name, ...
        '^(.+?)_\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}\.mat$', 'once')), mats);
    if any(isSessionMat)
        found{end+1} = full; %#ok<AGROW>
    end
end
end


function sessions = findSessions(sessionDir, archiveDir, archiveDirName)
%FINDSESSIONS Every session in one day folder (e.g. HabD1).
%   The original .avi may sit in the session folder itself (not yet archived)
%   or in an og_large_vids folder -- the shared archive at the experiment
%   root, or a leftover per-session one from an earlier run. All are searched,
%   so re-running after archiving still finds the source.
searchDirs = {sessionDir, archiveDir, fullfile(sessionDir, archiveDirName)};

sessions = {};
mats = dir(fullfile(sessionDir, '*.mat'));
[~, order] = sort({mats.name});
mats = mats(order);

for k = 1:numel(mats)
    tok = regexp(mats(k).name, ...
        '^(.+?)_\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}\.mat$', 'tokens', 'once');
    if isempty(tok)
        continue;
    end
    prefix = tok{1};

    txts = dir(fullfile(sessionDir, [prefix '_reward_data_*.txt']));
    if isempty(txts)
        fprintf(2, '  [skip] %s: no reward_data .txt found\n', prefix);
        continue;
    end
    [~, torder] = sort({txts.name});
    txts = txts(torder);

    aviPath = '';
    for d = 1:numel(searchDirs)
        if ~isfolder(searchDirs{d})
            continue;
        end
        hits = dir(fullfile(searchDirs{d}, [prefix '_camera_*.avi']));
        if ~isempty(hits)
            [~, horder] = sort({hits.name});
            hits = hits(horder);
            aviPath = fullfile(searchDirs{d}, hits(1).name);
            break;
        end
    end
    if isempty(aviPath)
        fprintf(2, '  [skip] %s: no camera .avi found\n', prefix);
        continue;
    end

    [~, aviName] = fileparts(aviPath);

    s = struct();
    s.prefix     = prefix;
    s.sessionDir = sessionDir;
    s.mat        = fullfile(sessionDir, mats(k).name);
    s.txt        = fullfile(sessionDir, txts(1).name);
    s.avi        = aviPath;
    % Output keeps the original video's exact name with _preprocessed
    % appended, so it is obvious which .avi each .mp4 came from.
    s.out        = fullfile(sessionDir, [aviName '_preprocessed.mp4']);
    sessions{end+1} = s; %#ok<AGROW>
end
end


function outPath = testOutputPath(outPath, limitSeconds)
%TESTOUTPUTPATH Truncated test encodes get their own filename, so a
%   limitSeconds run can never leave a short clip where a full session's
%   output belongs (which skip-if-exists would then treat as finished work).
if limitSeconds <= 0
    return;
end
[d, n, e] = fileparts(outPath);
outPath = fullfile(d, sprintf('%s_TEST%ds%s', n, round(limitSeconds), e));
end


function dest = archiveOriginal(aviPath, archiveDir, prefix)
%ARCHIVEORIGINAL Move the original .avi into the shared og_large_vids archive.
%   The filename must already identify subject and session (it is checked
%   against the session prefix, e.g. PVFP_28_HabD1_SV_Aug20), so nothing is
%   renamed -- but that is verified rather than assumed before moving.
dest = '';
[srcDir, n, e] = fileparts(aviPath);
name = [n e];

if ~startsWith(name, [prefix '_'])
    fprintf(2, ['  [warn] %s does not start with session prefix ''%s'' ' ...
                '-- leaving it where it is\n'], name, prefix);
    return;
end

if strcmpi(fullfile(srcDir), fullfile(archiveDir))
    dest = aviPath;   % already archived
    return;
end

dest = fullfile(archiveDir, name);
if isfile(dest)
    fprintf(2, '  [warn] %s already in archive -- leaving source in place\n', name);
    dest = '';
    return;
end

if ~isfolder(archiveDir)
    mkdir(archiveDir);
end
[ok, msg] = movefile(aviPath, dest);
if ~ok
    fprintf(2, '  [warn] could not archive %s: %s\n', name, msg);
    dest = '';
    return;
end
[~, archName] = fileparts(archiveDir);
fprintf('  archived original -> %s\\%s\n', archName, name);
end


% ========================================================================
% .mat / .txt parsing
% ========================================================================
function dt = matVecToDt(vec)
%MATVECTODT [Y M D H Min S(fractional)] -> datetime.
vec = double(vec(:))';
dt = datetime(vec(1), vec(2), vec(3), vec(4), vec(5), vec(6));
end


function dts = toTimes(arr)
%TOTIMES Normalize a 'ts' field (empty, a single 6-vector, or an Nx6 array)
%   into a column of datetimes.
if isempty(arr)
    dts = NaT(0, 1);
    return;
end
if isvector(arr) && numel(arr) == 6
    arr = reshape(double(arr), 1, 6);
end
n = size(arr, 1);
dts = NaT(n, 1);
for i = 1:n
    dts(i) = matVecToDt(arr(i, :));
end
end


function iv = toIntervals(onArr, offArr)
%TOINTERVALS Pair up on/off timestamp lists into an Nx2 datetime array.
onD  = toTimes(onArr);
offD = toTimes(offArr);
n = min(numel(onD), numel(offD));
if n == 0
    iv = NaT(0, 2);
    return;
end
iv = [onD(1:n), offD(1:n)];
end


function ev = loadMatEvents(matPath)
%LOADMATEVENTS Read the task-timing .mat and express every event in seconds
%   relative to camera_on (which is treated as t=0 for the video).
d = load(matPath);
ts = d.ts;

cameraOn        = matVecToDt(ts.camera_on);
cameraOff       = matVecToDt(ts.camera_off);
rewardArduinoOn = matVecToDt(ts.rewardArduino_on);

ev = struct();
ev.expId    = char(string(d.exp_ID));
ev.duration = seconds(cameraOff - cameraOn);
ev.csDur    = double(d.cs_dur);
ev.usDur    = double(d.us_dur);

ev.csPlus  = relIntervals(toIntervals(ts.csp_on,   ts.csp_off),   cameraOn);
ev.csMinus = relIntervals(toIntervals(ts.csm_on,   ts.csm_off),   cameraOn);
ev.shock   = relIntervals(toIntervals(ts.us_on,    ts.us_off),    cameraOn);
ev.laser   = relIntervals(toIntervals(ts.laser_on, ts.laser_off), cameraOn);

laserOn = toTimes(ts.laser_on);
if isempty(laserOn)
    ev.laserTriggers = zeros(0, 1);
else
    ev.laserTriggers = seconds(laserOn - cameraOn);
end

% Offset that puts the Arduino log's millisecond-relative times on the same
% "seconds since camera_on" axis as everything else.
ev.txtToCameraOffset = seconds(rewardArduinoOn - cameraOn);
end


function rel = relIntervals(iv, cameraOn)
if isempty(iv)
    rel = zeros(0, 2);
    return;
end
rel = [seconds(iv(:,1) - cameraOn), seconds(iv(:,2) - cameraOn)];
end


function log = loadRewardLog(txtPath, txtToCameraOffset)
%LOADREWARDLOG Parse the Arduino pin-transition log.
%   Returns rewardDeliveries (one time per state 0 -> state 1 reward_delivery
%   pair, i.e. one pump dispense) and beamBreaks (one time per IR_beam_check
%   transition to state 1), both in seconds since camera_on.
pumpPending = [];
rewardTimes = [];
beamTimes   = [];

fid = fopen(txtPath, 'r');
if fid < 0
    error('preprocess_video:openTxt', 'Could not open %s', txtPath);
end
cleanup = onCleanup(@() fclose(fid));

while true
    line = fgetl(fid);
    if ~ischar(line)
        break;
    end
    line = strtrim(line);
    if isempty(line)
        continue;
    end
    rec = jsondecode(line);
    tSec = txtToCameraOffset + double(rec.time) / 1000;

    switch rec.pin_name
        case 'reward_delivery'
            if rec.state == 0
                pumpPending = tSec;
            elseif rec.state == 1 && ~isempty(pumpPending)
                rewardTimes(end+1, 1) = pumpPending; %#ok<AGROW>
                pumpPending = [];
            end
        case 'IR_beam_check'
            if rec.state == 1
                beamTimes(end+1, 1) = tSec; %#ok<AGROW>
            end
    end
end

log = struct();
log.rewardDeliveries = rewardTimes;
log.beamBreaks       = beamTimes;
end


% ========================================================================
% ffprobe
% ========================================================================
function info = probeVideo(ffprobePath, videoPath)
cmd = sprintf('"%s" -v error -select_streams v:0 -show_entries stream=width,height,r_frame_rate,nb_frames,duration -of json "%s"', ...
    ffprobePath, videoPath);
[status, out] = system(cmd);
if status ~= 0
    error('preprocess_video:ffprobe', 'ffprobe failed on %s:\n%s', videoPath, out);
end
j = jsondecode(out);
st = j.streams(1);

parts = strsplit(st.r_frame_rate, '/');
fps = str2double(parts{1}) / str2double(parts{2});

info = struct();
info.width    = double(st.width);
info.height   = double(st.height);
info.fps      = fps;
info.nbFrames = str2double(num2str(st.nb_frames));
info.duration = str2double(num2str(st.duration));
end


% ========================================================================
% Icon rendering (drawn once, overlaid per frame)
% ========================================================================
function renderCircleIcon(path, sz, color, filled)
%RENDERCIRCLEICON Ring (empty) or filled disk, as an RGBA PNG.
ringWidth = 3;
pad = ringWidth;
cx = (pad + (sz - pad)) / 2;      % matches the Python/PIL bounding box
radius = (sz - 2*pad) / 2;

[X, Y] = meshgrid(0:sz-1, 0:sz-1);
dist = sqrt((X - cx).^2 + (Y - cx).^2);

if filled
    mask = dist <= radius;
    rgbColor = color;
else
    mask = (dist <= radius) & (dist >= radius - ringWidth);
    rgbColor = [150 150 150];     % grey outline when the event is not active
end

img = zeros(sz, sz, 3, 'uint8');
for c = 1:3
    ch = zeros(sz, sz, 'uint8');
    ch(mask) = rgbColor(c);
    img(:,:,c) = ch;
end
alpha = uint8(mask) * 255;
imwrite(img, path, 'Alpha', alpha);
end


function renderPlayheadBar(path, w, h, color)
img = zeros(h, w, 3, 'uint8');
for c = 1:3
    img(:,:,c) = color(c);
end
alpha = uint8(ones(h, w)) * 255;
imwrite(img, path, 'Alpha', alpha);
end


% ========================================================================
% Filter-graph construction
% ========================================================================
function s = hexColor(rgb)
s = sprintf('0x%02X%02X%02X', rgb(1), rgb(2), rgb(3));
end


function expr = buildEnableExpr(intervals)
%BUILDENABLEEXPR 'between(t\,a\,b)+...' -- '0' (never true) when empty.
if isempty(intervals)
    expr = '0';
    return;
end
parts = cell(1, size(intervals, 1));
for k = 1:size(intervals, 1)
    parts{k} = ['between(t\,' sprintf('%.3f', intervals(k,1)) ...
                '\,' sprintf('%.3f', intervals(k,2)) ')'];
end
expr = strjoin(parts, '+');
end


function expr = buildCumulativeCountExpr(times) %#ok<DEFNU>
%BUILDCUMULATIVECOUNTEXPR Number of `times` at or before the current t.
%
%   SV, August 25, 2026: NO LONGER CALLED -- superseded by appendCounterFilters.
%   Kept as a record of what was tried and ruled out, so the same dead end
%   isn't reached for again:
%     * v1 used a NESTED if() chain -- died at ~100 events (nesting depth).
%     * this FLAT sum fixed that, but still dies at ~286 events (4745 chars)
%       on ffmpeg's expression LENGTH limit.
%   Both failure modes are silent: ffmpeg drops the drawtext and still reports
%   a successful encode, so the counter simply vanishes from the panel.
%
%   Original note, kept for context:
%   Built as a FLAT sum of gte() terms (each is 1 once t passes that event),
%   deliberately NOT a nested if() chain: ffmpeg's expression parser fails on
%   deeply nested expressions -- with ~100 events it errors once per frame
%   ("...))))' is not valid") and silently drops the whole drawtext, so the
%   counter vanishes from the panel instead of failing loudly. A flat sum has
%   no nesting depth, so it scales to any number of events.
if isempty(times)
    expr = '0';
    return;
end
t = sort(times(:));
parts = cell(1, numel(t));
for k = 1:numel(t)
    parts{k} = ['gte(t\,' sprintf('%.3f', t(k)) ')'];
end
expr = strjoin(parts, '+');
end


function expr = fmtTimeExpr(duration, remaining)
%FMTTIMEEXPR Elapsed uses drawtext's built-in %{pts:hms}. Remaining has no
%   built-in countdown form, so it is built by hand as MM:SS from an eif
%   expression (same technique as the event counters).
if ~remaining
    expr = '%{pts\:hms}';
    return;
end
rem  = ['max(0\,' sprintf('%.3f', duration) '-t)'];
mins = ['floor((' rem ')/60)'];
secs = ['floor(mod(' rem '\,60))'];
expr = ['%{eif\:' mins '\:d\:2}\:%{eif\:' secs '\:d\:2}'];
end


function [filterStr, inputs] = buildFilterScript(ev, log, probe, cfg, iconPaths)
%BUILDFILTERSCRIPT Returns the filter_complex text and the ordered list of
%   extra -i inputs it references.
w = probe.width;
h = probe.height;
pw = w;                        % panel width == final frame width
duration = ev.duration;
% SV, August 25, 2026: I added
% Length of the actual video file, which is NOT always the session length --
% on 2 of 18 sessions the camera stopped minutes before the task did. The
% timeline still spans the whole session (so un-filmed trials remain visible),
% but the countdown timer must use this or it never reaches zero.
videoDuration = probe.duration;
%
panelHeight = cfg.panelHeight;

toneWindows  = [ev.csPlus; ev.csMinus];
shockWindows = ev.shock;
rewardTimes  = log.rewardDeliveries;
beamTimes    = log.beamBreaks;

iconSize = floor(panelHeight * 0.42);
iconY    = floor(panelHeight * 0.42);
toneX    = floor(pw * 0.04);
shockX   = floor(pw * 0.20);

timelineY0 = cfg.timelineY0;
timelineH  = cfg.timelineH;
timelineX0 = 8;
timelineW  = pw - 16;

% Fixed input order/index for every extra (icon/bar) input stream, decided up
% front so the timeline and icon sections agree on numbering. Input 0 is the
% source video.
iconKeys = {'tone_off', 'tone_on', 'shock_off', 'shock_on', 'playhead'};
iconIdx = containers.Map(iconKeys, num2cell(1:numel(iconKeys)));

tpos = @(t) timelineX0 + (max(0, min(t, duration)) / duration) * timelineW;

lines = {};
% base panel: pad the (already-scaled) video with a black strip on top
lines{end+1} = sprintf('[0:v]pad=w=%d:h=%d:x=0:y=%d:color=%s[padded]', ...
    pw, h + panelHeight, panelHeight, hexColor(cfg.panelBg));

cur = 'padded';

% --- timeline background bar ---
lines{end+1} = sprintf('[%s]drawbox=x=%d:y=%d:w=%d:h=%d:color=%s@1:t=fill[tl0]', ...
    cur, timelineX0, timelineY0, timelineW, timelineH, hexColor(cfg.timelineBg));
cur = 'tl0';
step = 0;

% SV, August 25, 2026: I added
% If the camera stopped before the task did, shade the un-filmed tail red so
% the missing footage is visible rather than implied by a stalled playhead.
% Drawn immediately after the background bar so event ticks land on top.
noVideoFrom = videoDuration;
if duration - noVideoFrom > 2      % 2s tolerance: normal offset is <1s
    xNo = tpos(noVideoFrom);
    wNo = (timelineX0 + timelineW) - xNo;
    if wNo >= 1
        step = step + 1;
        lines{end+1} = sprintf('[%s]drawbox=x=%.1f:y=%d:w=%.1f:h=%d:color=%s@1:t=fill[tl%d]', ...
            cur, xNo, timelineY0, wNo, timelineH, hexColor(cfg.timelineNoVideo), step); %#ok<AGROW>
        cur = sprintf('tl%d', step);
    end
end
%

for k = 1:size(toneWindows, 1)
    x0 = tpos(toneWindows(k,1));
    x1 = tpos(toneWindows(k,2));
    step = step + 1;
    lines{end+1} = sprintf('[%s]drawbox=x=%.1f:y=%d:w=%.1f:h=%d:color=%s@1:t=fill[tl%d]', ...
        cur, x0, timelineY0, max(2.0, x1 - x0), timelineH, hexColor(cfg.timelineTone), step); %#ok<AGROW>
    cur = sprintf('tl%d', step);
end

for k = 1:size(shockWindows, 1)
    x0 = tpos(shockWindows(k,1));
    x1 = tpos(shockWindows(k,2));
    step = step + 1;
    lines{end+1} = sprintf('[%s]drawbox=x=%.1f:y=%d:w=%.1f:h=%d:color=%s@1:t=fill[tl%d]', ...
        cur, x0, timelineY0, max(2.0, x1 - x0), timelineH, hexColor(cfg.timelineShock), step); %#ok<AGROW>
    cur = sprintf('tl%d', step);
end

for k = 1:numel(rewardTimes)
    step = step + 1;
    lines{end+1} = sprintf('[%s]drawbox=x=%.1f:y=%d:w=%d:h=%d:color=%s@1:t=fill[tl%d]', ...
        cur, tpos(rewardTimes(k)), timelineY0, cfg.eventTickW, timelineH, ...
        hexColor(cfg.timelineReward), step); %#ok<AGROW>
    cur = sprintf('tl%d', step);
end

for k = 1:numel(beamTimes)
    step = step + 1;
    lines{end+1} = sprintf('[%s]drawbox=x=%.1f:y=%d:w=%d:h=%d:color=%s@1:t=fill[tl%d]', ...
        cur, tpos(beamTimes(k)), timelineY0, cfg.eventTickW, timelineH, ...
        hexColor(cfg.timelineBeam), step); %#ok<AGROW>
    cur = sprintf('tl%d', step);
end

% Moving playhead. NOTE: drawbox's x/y expressions do NOT actually vary with
% `t` in this ffmpeg build (8.1.1-essentials) -- confirmed by direct testing:
% identical output at t=0/1/2s, even on a synthetic source, and no error is
% raised. overlay's x/y expressions DO evaluate correctly per frame, so the
% playhead is a small pre-rendered bar overlaid with a dynamic x.
phY0 = timelineY0 - floor((cfg.playheadH - timelineH) / 2);
step = step + 1;
lines{end+1} = ['[' cur '][' num2str(iconIdx('playhead')) ':v]overlay=x=''' ...
    num2str(timelineX0) '+(t/' sprintf('%.6f', duration) ')*' num2str(timelineW) ...
    '-' sprintf('%.1f', cfg.playheadW / 2) ''':y=' num2str(phY0) ...
    ':shortest=1[tl' num2str(step) ']'];
cur = sprintf('tl%d', step);

% --- tone / shock icons: off-icon always, on-icon gated by enable ---
inputs = cell(1, numel(iconKeys));
for k = 1:numel(iconKeys)
    inputs{k} = iconPaths.(iconKeys{k});
end

xPositions = containers.Map( ...
    {'tone_off','tone_on','shock_off','shock_on'}, ...
    {toneX, toneX, shockX, shockX});
enableFor = containers.Map( ...
    {'tone_on','shock_on'}, ...
    {buildEnableExpr(toneWindows), buildEnableExpr(shockWindows)});

for k = 1:4
    key = iconKeys{k};
    step = step + 1;
    if isKey(enableFor, key)
        enClause = [':enable=''' enableFor(key) ''''];
    else
        enClause = '';
    end
    lines{end+1} = ['[' cur '][' num2str(iconIdx(key)) ':v]overlay=x=' ...
        num2str(xPositions(key)) ':y=' num2str(iconY) ':shortest=1' ...
        enClause '[ic' num2str(step) ']']; %#ok<AGROW>
    cur = sprintf('ic%d', step);
end

% --- text: labels, counters, timers ---
textYLabel = iconY + iconSize + 4;
% SV, August 25, 2026: I changed
% beamExpr   = buildCumulativeCountExpr(beamTimes);
% rewardExpr = buildCumulativeCountExpr(rewardTimes);
% to this:
% (nothing here now -- the counters are built as filter chains further down.
% See appendCounterFilters for why the single-expression form was dropped.)
%

% {x, y, text, fontsize}
dt = {
    toneX - 6,           textYLabel, '''TONE''',  16
    shockX - 8,          textYLabel, '''SHOCK''', 16
% SV, August 25, 2026: I changed
%     floor(pw * 0.35),    iconY - 4,  ['''Beam Break\: %{eif\:' beamExpr '\:d}'''],      16
%     floor(pw * 0.35),    iconY + 24, ['''Reward Delivery\: %{eif\:' rewardExpr '\:d}'''], 16
% to this:
% (moved out of this table into appendCounterFilters below -- a single
% expression hits a hard length limit in ffmpeg once a session has a few
% hundred events)
%
    floor(pw * 0.72),    iconY - 4,  ['''Elapsed ' fmtTimeExpr(duration, false) ''''],  18
% SV, August 25, 2026: I changed
%     floor(pw * 0.72),    iconY + 24, ['''Remain  ' fmtTimeExpr(duration, true)  ''''],  18
% to this:
% (counts down the VIDEO, not the session -- otherwise a truncated recording
% leaves the timer stuck minutes above zero)
    floor(pw * 0.72),    iconY + 24, ['''Remain  ' fmtTimeExpr(videoDuration, true)  ''''],  18
%
    };

for k = 1:size(dt, 1)
    step = step + 1;
    lines{end+1} = ['[' cur ']drawtext=fontfile=''' cfg.fontFile ''':text=' dt{k,3} ...
        ':x=' num2str(dt{k,1}) ':y=' num2str(dt{k,2}) ...
        ':fontsize=' num2str(dt{k,4}) ':fontcolor=' cfg.textColor ...
        '[dt' num2str(step) ']']; %#ok<AGROW>
    cur = sprintf('dt%d', step);
end

% SV, August 25, 2026: I added
% Counters are drawn as one small drawtext per value, gated by a time range,
% rather than one drawtext with a giant expression. See appendCounterFilters.
[lines, cur, step] = appendCounterFilters(lines, cur, step, beamTimes, ...
    'Beam Break', floor(pw * 0.35), iconY - 4, 16, cfg.fontFile, cfg.textColor);
[lines, cur, step] = appendCounterFilters(lines, cur, step, rewardTimes, ...
    'Reward Delivery', floor(pw * 0.35), iconY + 24, 16, cfg.fontFile, cfg.textColor);
%

lines{end+1} = ['[' cur ']null[vout]'];

filterStr = strjoin(lines, [';' newline]);
end


% SV, August 25, 2026: I added appendCounterFilters.
function [lines, cur, step] = appendCounterFilters(lines, cur, step, times, ...
                                                   label, x, y, fontSize, font, textColor)
%APPENDCOUNTERFILTERS Running "<label>: N" counter, as one drawtext per value.
%
%   WHY NOT ONE drawtext WITH AN EXPRESSION:
%   ffmpeg's text-expansion expressions have two separate hard limits, and a
%   running count trips both as sessions get busier:
%     * nesting depth -- a nested if() chain fails at roughly 100 events
%       ("...))))' is not valid", once per frame)
%     * total length  -- a flat sum of gte() terms fails too; 286 events makes
%       a 4745-character expression, which ffmpeg also rejects
%   In both cases ffmpeg drops the whole drawtext SILENTLY (the encode still
%   reports success) so the counter just vanishes from the panel.
%
%   Instead: emit one short drawtext per distinct count value, each enabled
%   only for the interval where that value applies. Every expression stays
%   ~30 characters no matter how many events there are, so this scales to any
%   session. Costs one filter per event, which is cheap since only one is
%   ever enabled at a time.

n = numel(times);
t = sort(times(:));

    function addOne(value, enableExpr)
        step = step + 1;
        s = ['[' cur ']drawtext=fontfile=''' font ''':text=''' label '\: ' ...
             num2str(value) '''' ...
             ':x=' num2str(x) ':y=' num2str(y) ...
             ':fontsize=' num2str(fontSize) ':fontcolor=' textColor];
        if ~isempty(enableExpr)
            s = [s ':enable=''' enableExpr ''''];
        end
        s = [s '[ct' num2str(step) ']'];
        lines{end+1} = s;
        cur = ['ct' num2str(step)];
    end

if n == 0
    addOne(0, '');       % always-on zero
    return;
end

% 0 before the first event
addOne(0, ['lt(t\,' sprintf('%.3f', t(1)) ')']);

% k between event k and event k+1  (multiplication acts as logical AND)
for k = 1:n-1
    addOne(k, ['gte(t\,' sprintf('%.3f', t(k)) ')*lt(t\,' sprintf('%.3f', t(k+1)) ')']);
end

% final value from the last event onwards
addOne(n, ['gte(t\,' sprintf('%.3f', t(n)) ')']);
end
%


% ========================================================================
% Per-session pipeline
% ========================================================================
function outPath = processSession(session, opt, cfg, workDir, idx, total, runStart)
prefix = session.prefix;

ev  = loadMatEvents(session.mat);
log = loadRewardLog(session.txt, ev.txtToCameraOffset);

% SV, August 25, 2026: I changed
% probe = probeVideo(opt.ffprobe, session.avi);
% to this:
% (planning already probed every file to build the estimate -- reuse that
% instead of paying for a second probe per session)
% Probed once during planning; re-probe only if called without that.
if isfield(session, 'probe') && ~isempty(session.probe)
    probe = session.probe;
else
    probe = probeVideo(opt.ffprobe, session.avi);
end
if isfield(session, 'frames') && ~isempty(session.frames)
    nFrames = session.frames;
else
    nFrames = plannedFrames(probe, opt.limitSeconds);
end

% SV, August 25, 2026: I changed
% fprintf('=== %s ===\n', prefix);
% fprintf('  video: %dx%d @ %.2ffps, %d frames, %.1fs\n', ...
%     probe.width, probe.height, probe.fps, probe.nbFrames, probe.duration);
% fprintf('  mat duration: %.1fs (diff vs video: %+.2fs)\n', ...
%     ev.duration, ev.duration - probe.duration);
% fprintf('  tone trials: %d, shock: %d, beam breaks: %d, reward deliveries: %d\n', ...
%     size(ev.csPlus,1) + size(ev.csMinus,1), size(ev.shock,1), ...
%     numel(log.beamBreaks), numel(log.rewardDeliveries));
% to this:
% One compact line per session instead of the old multi-line dump.
fprintf('%dx%d %gfps | tone %d, shock %d, beam %d, reward %d | sync %+.2fs\n', ...
    probe.width, probe.height, probe.fps, ...
    size(ev.csPlus,1) + size(ev.csMinus,1), size(ev.shock,1), ...
    numel(log.beamBreaks), numel(log.rewardDeliveries), ...
    ev.duration - probe.duration);
%

% SV, August 25, 2026: I added
% Flag sessions where the camera stopped before the task did -- the tail of
% the behavior has no footage at all, which is easy to miss otherwise.
missingSec = ev.duration - probe.duration;
if missingSec > 2
    fprintf(2, ['    *** WARNING: video is %s SHORTER than the session. ***\n' ...
                '    The last %s of behavior was never filmed; that stretch is\n' ...
                '    shaded red on the timeline.\n'], ...
        fmtDuration(missingSec), fmtDuration(missingSec));
end
%

iconSize = floor(cfg.panelHeight * 0.42);
iconPaths = struct();
iconPaths.tone_off  = fullfile(workDir, 'tone_off.png');
iconPaths.tone_on   = fullfile(workDir, 'tone_on.png');
iconPaths.shock_off = fullfile(workDir, 'shock_off.png');
iconPaths.shock_on  = fullfile(workDir, 'shock_on.png');
iconPaths.playhead  = fullfile(workDir, 'playhead.png');

renderCircleIcon(iconPaths.tone_off,  iconSize, cfg.toneColor,  false);
renderCircleIcon(iconPaths.tone_on,   iconSize, cfg.toneColor,  true);
renderCircleIcon(iconPaths.shock_off, iconSize, cfg.shockColor, false);
renderCircleIcon(iconPaths.shock_on,  iconSize, cfg.shockColor, true);
renderPlayheadBar(iconPaths.playhead, cfg.playheadW, cfg.playheadH, cfg.playheadColor);

scaledProbe = probe;
scaledProbe.width  = opt.targetW;
scaledProbe.height = opt.targetH;

[filterBody, iconInputs] = buildFilterScript(ev, log, scaledProbe, cfg, iconPaths);
fullFilter = ['[0:v]scale=' num2str(opt.targetW) ':' num2str(opt.targetH) '[scaled];' ...
    strrep(filterBody, '[0:v]pad', '[scaled]pad')];

filterScriptPath = fullfile(workDir, [prefix '_filter.txt']);
fid = fopen(filterScriptPath, 'w');
if fid < 0
    error('preprocess_video:writeFilter', 'Could not write %s', filterScriptPath);
end
fprintf(fid, '%s', fullFilter);
fclose(fid);

outPath = testOutputPath(session.out, opt.limitSeconds);
outDir = fileparts(outPath);
if ~isfolder(outDir)
    mkdir(outDir);
end
% Encode to a temp name first, so an interrupted run never leaves a truncated
% file that the next run would mistake for finished work.
[od, on_, oe] = fileparts(outPath);
tmpPath = fullfile(od, [on_ '.partial' oe]);

progressPath  = fullfile(workDir, [prefix '_progress.txt']);
ffmpegLogPath = fullfile(workDir, [prefix '_ffmpeg.log']);

% SV, August 25, 2026: I changed
% cmd = ['"' opt.ffmpeg '" -y'];
% if opt.limitSeconds > 0
%     cmd = [cmd ' -t ' sprintf('%g', opt.limitSeconds)];
% end
% cmd = [cmd ' -i "' session.avi '"'];
% for k = 1:numel(iconInputs)
%     cmd = [cmd ' -loop 1 -i "' iconInputs{k} '"']; %#ok<AGROW>
% end
% cmd = [cmd ' -/filter_complex "' filterScriptPath '"' ...
%     ' -map "[vout]"' ...
%     ' -c:v ' opt.codec ...
%     ' -crf ' num2str(opt.crf) ...
%     ' -preset ' opt.preset ...
%     ' -pix_fmt yuv420p' ...
%     ' -shortest' ...
%     ' "' tmpPath '"'];
%
% [~, outName, outExt] = fileparts(outPath);
% fprintf('  encoding -> %s\n', [outName outExt]);
% status = system(cmd);
% to this:
% (system() blocks and prints a per-frame line to the Command Window. The
% token list below feeds a non-blocking process instead, with -progress going
% to a file so a progress bar can be driven from it -- see
% runFfmpegWithProgress. Tokens also remove all path-quoting concerns.)
% Build the argument list as separate tokens. Passing these straight to the
% process (rather than one shell string) means paths with spaces need no
% quoting at all.
args = {opt.ffmpeg, '-y', '-nostdin', ...
        '-loglevel', 'error', '-nostats', ...
        '-progress', progressPath};
if opt.limitSeconds > 0
    args = [args, {'-t', sprintf('%g', opt.limitSeconds)}];
end
args = [args, {'-i', session.avi}];
for k = 1:numel(iconInputs)
    args = [args, {'-loop', '1', '-i', iconInputs{k}}]; %#ok<AGROW>
end
args = [args, { ...
    '-/filter_complex', filterScriptPath, ...
    '-map', '[vout]', ...
    '-c:v', opt.codec, ...
    '-crf', num2str(opt.crf), ...
    '-preset', opt.preset, ...
    '-pix_fmt', 'yuv420p', ...
    '-shortest', ...
    tmpPath}];

status = runFfmpegWithProgress(args, progressPath, ffmpegLogPath, ...
    nFrames, prefix, idx, total, runStart);
%

if status ~= 0
    if isfile(tmpPath)
        delete(tmpPath);
    end
    errText = '';
    if isfile(ffmpegLogPath)
        errText = strtrim(fileread(ffmpegLogPath));
        if numel(errText) > 600
            errText = ['...' errText(end-599:end)];
        end
    end
    if status == -1
        error('preprocess_video:cancelled', 'Cancelled during %s', prefix);
    end
    error('preprocess_video:ffmpeg', 'ffmpeg failed (exit %d) for %s\n%s', ...
        status, prefix, errText);
end

if isfile(outPath)
    delete(outPath);
end
[ok, msg] = movefile(tmpPath, outPath);
if ~ok
    error('preprocess_video:rename', 'Could not finalize %s: %s', outPath, msg);
end

info = dir(outPath);
fprintf('    done: %.1f MB\n', info.bytes / (1024*1024));
end


% SV, August 25, 2026: I added runFfmpegWithProgress, closeIfValid and
% readProgressFrame. v1 had none of these -- it just called system(cmd) and
% let ffmpeg print a line per frame to the Command Window.
function status = runFfmpegWithProgress(args, progressPath, logPath, ...
                                        nFrames, prefix, idx, total, runStart)
%RUNFFMPEGWITHPROGRESS Launch ffmpeg without blocking, and drive a progress
%   bar from its -progress output.
%
%   Returns ffmpeg's exit code, or -1 if the user pressed Cancel.
%
%   ffmpeg runs with -loglevel error -nostats so it prints nothing per frame;
%   machine-readable progress goes to progressPath instead, and any real
%   error text lands in logPath.

if isfile(progressPath); delete(progressPath); end
if isfile(logPath);      delete(logPath);      end

jArgs = java.util.ArrayList();
for k = 1:numel(args)
    jArgs.add(java.lang.String(args{k}));
end
pb = java.lang.ProcessBuilder(jArgs);
pb.redirectErrorStream(true);
pb.redirectOutput(java.io.File(logPath));   % never fills a pipe buffer
proc = pb.start();

% Start timing before the waitbar: building that figure can take a second or
% two on first call, and a short encode can finish inside that window.
tEncode = tic;

% Progress bar is a convenience, not a requirement: on a headless machine
% (no display, or MATLAB -nodisplay) figures cannot be created, so fall back
% to periodic text progress rather than failing the encode.
wb = [];
try
    wb = waitbar(0, 'Starting...', ...
        'Name', sprintf('Encoding %d of %d', idx, total), ...
        'CreateCancelBtn', 'setappdata(gcbf, ''cancelled'', 1)');
    setappdata(wb, 'cancelled', 0);
catch
    wb = [];
end
cleanupBar = onCleanup(@() closeIfValid(wb));

cancelled = false;
lastFrame = 0;
lastTextPct = -100;

while proc.isAlive()
    pause(0.4);

    if ~isempty(wb) && ishandle(wb) && getappdata(wb, 'cancelled')
        proc.destroy();
        cancelled = true;
        break;
    end

    f = readProgressFrame(progressPath);
    if f > lastFrame
        lastFrame = f;
    end

    frac = 0;
    if nFrames > 0
        frac = min(1, lastFrame / nFrames);
    end

    elapsed = toc(tEncode);
    if frac > 0.01
        etaThis = elapsed * (1 - frac) / frac;
        etaTxt = sprintf('%s left', fmtDuration(etaThis));
    else
        etaTxt = 'estimating...';
    end

    if ~isempty(wb) && ishandle(wb)
        waitbar(frac, wb, sprintf('%s\n%d / %d frames  (%.0f%%)  -  %s', ...
            prefix, lastFrame, nFrames, frac*100, etaTxt));
    elseif frac*100 >= lastTextPct + 10
        % No display: report every 10% on one line instead.
        lastTextPct = floor(frac*100 / 10) * 10;
        fprintf('%d%% ', lastTextPct);
    end
end

if cancelled
    proc.waitFor();
    status = -1;
    return;
end

proc.waitFor();
status = double(proc.exitValue());

% Final count comes from the file, not the last polled tick -- a fast encode
% can finish between ticks (or before the first one).
finalFrame = readProgressFrame(progressPath);
if finalFrame > lastFrame
    lastFrame = finalFrame;
end

if status == 0 && ~isempty(wb) && ishandle(wb)
    waitbar(1, wb, sprintf('%s\nfinishing...', prefix));
end

% Overall pace, printed once per video rather than per frame.
if status == 0
    encSec = toc(tEncode);
    fps = 0;
    if encSec > 0
        fps = lastFrame / encSec;
    end
    fprintf('    encoded in %s (%.0f fps)', fmtDuration(encSec), fps);
    if idx < total
        avgPer = toc(runStart) / idx;
        fprintf(' | ~%s left overall', fmtDuration(avgPer * (total - idx)));
    end
    fprintf('\n');
end
end


function closeIfValid(h)
if ~isempty(h) && ishandle(h)
    delete(h);
end
end


function f = readProgressFrame(progressPath)
%READPROGRESSFRAME Last 'frame=N' value ffmpeg has written, or 0.
%   ffmpeg appends a block of key=value lines every second; only the most
%   recent frame= matters.
f = 0;
if ~isfile(progressPath)
    return;
end
try
    txt = fileread(progressPath);
catch
    return;   % ffmpeg was mid-write; try again next tick
end
tok = regexp(txt, 'frame=(\d+)', 'tokens');
if ~isempty(tok)
    f = str2double(tok{end}{1});
end
end
