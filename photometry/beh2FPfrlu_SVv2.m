function beh2fp = beh2FPfrlu_SVv2(exp_file, Beh_file, TDTdata, ref_stream)
% Create a lookup table that maps behavior frames to fiber photometry frames.
%
% SV 9/8/26: ref_stream (the stream whose sample rate defines "fiber
% photometry frames") is now an optional 4th argument, defaulting to
% 'x465A' - it used to be hardcoded to 'x560B', which doesn't exist for
% single-color cohorts (no 2nd fluorophore) and crashed every call. 465
% is always present, dual-color or not.

if nargin < 4 || isempty(ref_stream)
    ref_stream = 'x465A';
end

exp_file = char(exp_file);
Beh_file = char(Beh_file);

expf = load(exp_file); %#ok<NASGU>

% SV 5/21/26 I replaced this:
% load(Beh_file);
% with this:
beh_struct = load(Beh_file);
if isfield(beh_struct, 'Behavior')
    Behavior = beh_struct.Behavior;
elseif isfield(beh_struct, 'Behavior_Filter')
    Behavior = beh_struct.Behavior_Filter;
else
    beh_fields = fieldnames(beh_struct);
    Behavior = beh_struct.(beh_fields{1});
    warning('Expected variable "Behavior" not found in %s. Using "%s" instead.', Beh_file, beh_fields{1});
end
%

session_dir = fileparts(exp_file);

% SV 5/21/26 I replaced this:
% cue_candidates = [ ...
%     dir(fullfile(session_dir, 'Cue*.xls')); ...
%     dir(fullfile(session_dir, 'Cue*.xlsx')); ...
%     dir(fullfile(session_dir, 'Cue*.mat'))];
% with this:
cue_candidates = [ ...
    dir(fullfile(session_dir, 'Cue*.xls')); ...
    dir(fullfile(session_dir, 'Cue*.xlsx')); ...
    dir(fullfile(session_dir, 'Cue*.mat')); ...
    dir(fullfile(session_dir, '*cue*.csv')); ...
    dir(fullfile(session_dir, '*cue*.xls')); ...
    dir(fullfile(session_dir, '*cue*.xlsx'))];
%

if isempty(cue_candidates)
    error('No Cue file found in session folder: %s', session_dir);
end

cue_path = fullfile(cue_candidates(1).folder, cue_candidates(1).name);
[~,~,cue_ext] = fileparts(cue_path);

% SV 5/21/26 I added ", '.csv'" to the case list.
switch lower(cue_ext)
    case {'.xls', '.xlsx', '.csv'}
        cue_table = readtable(cue_path);
        cueframes = table2array(cue_table);

    case '.mat'
        cue_struct = load(cue_path);
        cue_fields = fieldnames(cue_struct);

        if isempty(cue_fields)
            error('Cue file is empty: %s', cue_path);
        end

        cueframes = cue_struct.(cue_fields{1});

    otherwise
        error('Unsupported cue file type: %s', cue_ext);
end

% SV 9/8/26 (v2, corrected same day): PC3_/PC2_/PC0_ is NOT a per-video-
% frame camera sync pulse train - it's the SAME cue events already in
% cueframes (read above from *csp*cue*.csv, in video-frame units),
% recorded independently as a TDT epoc on the photometry clock. The two
% are linked below purely as interp1() correspondence points (one pair
% per cue's onset/offset), so the right epoc is identified by ONSET
% COUNT matching cueframes, not by pulse density/regularity - an earlier
% version of this fix guessed "most onsets" and picked "Tick" (a 1-per-
% second housekeeping heartbeat, not a cue), which is wrong. Try the
% legacy names first (unchanged behavior for rigs that do use them), then
% auto-detect by count - see detectFrameSyncEpoc() below.
if isfield(TDTdata.epocs, 'PC3_')
    sync_name = 'PC3_';
elseif isfield(TDTdata.epocs, 'PC2_')
    sync_name = 'PC2_';
elseif isfield(TDTdata.epocs, 'PC0_')
    sync_name = 'PC0_';
else
    sync_name = detectFrameSyncEpoc(TDTdata, size(cueframes, 1));
    if isempty(sync_name)
        error(['No PC sync channel found in TDTdata.epocs, and auto-detection found no epoc ' ...
            'whose onset count matches (or safely exceeds) the %d cue(s) in cueframes. ' ...
            'Epocs present: %s'], size(cueframes, 1), strjoin(fieldnames(TDTdata.epocs), ', '));
    end
    fprintf('beh2FPfrlu_SVv2: auto-detected sync epoc "%s" (no PC0_/PC2_/PC3_ present).\n', sync_name);
end

sync_epoc = TDTdata.epocs.(sync_name);
n_expected = size(cueframes, 1);
sync_onset = sync_epoc.onset(:);
if isfield(sync_epoc, 'offset')
    sync_offset = sync_epoc.offset(:);
else
    sync_offset = sync_onset;
end

% SV 9/9/26 (bugfix, user-caught): a TDT epoc built from a level signal
% (HIGH during the tone, LOW during the ITI, e.g. this rig's 'tone'/
% 'L_Li' channels) reports EVERY transition as its own onset/offset pair,
% not just the tone-ON ones - confirmed on real data: 18 onsets for 9
% real tones, with onset/offset "durations" alternating ~30s (matches
% cs_dur exactly) / ~80-150s (matches the ITI range) one after another.
% The old logic here treated any surplus as "trailing cues
% calcCueFrames_batch legitimately dropped" and just took the FIRST
% n_expected onsets - for an alternating epoc like this that mixes 5
% tone-ON events with 4 ITI events, corrupting every other computed tone
% time (this is what made 9 tones visually collapse into what looked
% like one continuous block spanning roughly a third of the session,
% instead of spread across it - the ITI segments were silently being
% treated as extra "tones"). When the surplus is EXACTLY double,
% resolveAlternatingToggleEpoc splits it into the two alternating
% subsequences and picks whichever one is internally consistent in
% duration (the real bursts, e.g. tone-ON) over the other (the much more
% variable ITI gaps) - not just take-the-first-N.
if numel(sync_onset) == 2 * n_expected
    [sync_onset, sync_offset] = resolveAlternatingToggleEpoc(sync_onset, sync_offset, n_expected);
elseif numel(sync_onset) > n_expected
    % SV 9/8/26: calcCueFrames_batch legitimately drops trailing cues
    % when the camera stopped before the last tone (see
    % PMA_Dataset_Layout.md's "trailing camera overrun" field note) - the
    % TDT epoc, recorded for the whole session regardless of video
    % length, still has all of them. Cue order is chronological in both,
    % so taking the first n_expected keeps them correctly paired. (This
    % branch is for a genuine surplus of real cue-epoc events, not an
    % alternating level-toggle epoc - see the exactly-double case above.)
    sync_onset = sync_onset(1:n_expected);
    sync_offset = sync_offset(1:n_expected);
elseif numel(sync_onset) < n_expected
    error(['Sync epoc "%s" has fewer onsets (%d) than cueframes has cues (%d) - cannot align. ' ...
        'This usually means the wrong epoc was matched.'], sync_name, numel(sync_onset), n_expected);
end
fp.PC0_times = [sync_onset, sync_offset];

fp.fps = TDTdata.streams.(ref_stream).fs;
fp.PC0_frames = fp.PC0_times * fp.fps;

% SV 5/21/26 I changed:
% behsz = length(Behavior.Spatial.Platform.inROIvector);
% to this:
behsz = length(Behavior.Spatial.platform.inROIvector);
%

beh_frames = cueframes;
fp_frames = fp.PC0_frames;

temp_BEHs = 1;
for iii = 1:size(beh_frames,1)
    temp_BEHs = [temp_BEHs, round(beh_frames(iii,:))]; %#ok<AGROW>
end
temp_BEHs = [temp_BEHs, behsz];

temp_FPs = [];
for iii = 1:size(fp_frames,1)
    temp_FPs = [temp_FPs, round(fp_frames(iii,:))]; %#ok<AGROW>
end

temp_FPs = [ ...
    round(temp_FPs(1) - (temp_BEHs(2)-1) / (temp_BEHs(3)-temp_BEHs(2)) * (temp_FPs(2)-temp_FPs(1))), ...
    temp_FPs, ...
    round(temp_FPs(end) - (temp_BEHs(end-1)-temp_BEHs(end)) / (temp_BEHs(end-2)-temp_BEHs(end-1)) * (temp_FPs(end-1)-temp_FPs(end)))];

vq = interp1(temp_BEHs, temp_FPs, 1:behsz);
beh2fp = round(vq);
end

function [onset_out, offset_out] = resolveAlternatingToggleEpoc(sync_onset, sync_offset, n_expected)
% SV 9/9/26: sync_onset/sync_offset have exactly 2*n_expected entries -
% treat them as an alternating level-toggle epoc (segment 1 = state A,
% segment 2 = state B, segment 3 = state A, ...) and recover which
% alternating subsequence is the real n_expected tone-ON events. The
% tone burst duration (set once by the protocol, e.g. cs_dur) is
% essentially constant every time, while the ITI is drawn from a wide
% random range each time - so the real bursts are whichever alternating
% subsequence has the much more consistent (lower coefficient of
% variation) duration. This makes no assumption about which one starts
% first (odd vs even) or about absolute durations, so it isn't tied to
% this specific protocol's numbers.
durations = sync_offset - sync_onset;

odd_idx = 1:2:numel(sync_onset);
even_idx = 2:2:numel(sync_onset);

odd_cv = durationCV(durations(odd_idx));
even_cv = durationCV(durations(even_idx));

if odd_cv <= even_cv
    pick_idx = odd_idx;
else
    pick_idx = even_idx;
end

onset_out = sync_onset(pick_idx);
offset_out = sync_offset(pick_idx);

if numel(onset_out) ~= n_expected
    % Shouldn't happen given the 2*n_expected precondition, but don't
    % silently misalign if it somehow does.
    onset_out = onset_out(1:min(n_expected, numel(onset_out)));
    offset_out = offset_out(1:min(n_expected, numel(offset_out)));
end
end

function cv = durationCV(d)
% Coefficient of variation (std/mean) of the finite values in d - used to
% tell a consistent-duration burst train apart from a widely-varying gap
% train. Inf/NaN entries (e.g. a final segment with no recorded end) are
% excluded rather than treated as evidence of high variance.
d = d(isfinite(d));
if isempty(d) || mean(d) == 0
    cv = Inf;
    return;
end
cv = std(d) / mean(d);
end

function sync_name = detectFrameSyncEpoc(TDTdata, expected_n)
% SV 9/8/26 (v2, corrected same day): finds the epoc that represents the
% SAME cue events as cueframes (the video-frame-based tone onset/offset
% list, already read from *csp*cue*.csv by the caller), recorded
% independently on the TDT clock. This is NOT a per-video-frame sync
% pulse train - it's the same handful of tone presentations seen through
% two different clocks, used as interp1() correspondence points - so the
% right epoc is identified by matching ONSET COUNT to expected_n, not by
% pulse density. (An earlier version of this function guessed "most
% onsets, regular spacing," meant to detect a camera frame-sync train -
% that assumption was wrong for this pipeline and picked "Tick", a
% 1-per-second housekeeping heartbeat, instead of the real cue epoc.)
%
% Exact count match is used when available. An epoc with MORE onsets
% than expected is also accepted (the caller trims to the first
% expected_n) since calcCueFrames_batch can legitimately drop trailing
% cues from cueframes when the camera stopped before the last tone (see
% PMA_Dataset_Layout.md's "trailing camera overrun" field note) while the
% TDT epoc, recorded for the whole session, still has all of them. An
% epoc with FEWER onsets than expected cannot be the right one.

sync_name = '';
if ~isfield(TDTdata, 'epocs') || isempty(TDTdata.epocs) || expected_n <= 0
    return;
end

names = fieldnames(TDTdata.epocs);
exact_matches = {};
surplus_names = {};
surplus_counts = [];

for i = 1:numel(names)
    name = names{i};
    e = TDTdata.epocs.(name);
    if ~isfield(e, 'onset') || isempty(e.onset)
        continue;
    end
    n = numel(e.onset);
    if n == expected_n
        exact_matches{end+1} = name; %#ok<AGROW>
    elseif n > expected_n
        surplus_names{end+1} = name; %#ok<AGROW>
        surplus_counts(end+1) = n; %#ok<AGROW>
    end
end

if ~isempty(exact_matches)
    sync_name = pickPreferOffset(TDTdata, exact_matches);
    return;
end

if ~isempty(surplus_names)
    % No exact match - prefer the smallest surplus (closest superset of
    % the expected cues), tie-broken by having a real 'offset' field.
    [~, order] = sort(surplus_counts);
    sync_name = pickPreferOffset(TDTdata, surplus_names(order));
end

end

function name = pickPreferOffset(TDTdata, candidate_names)
% Among equally-valid candidates, prefer one with an 'offset' field (a
% real gated duration event, like a tone TTL) over a bare onset-only
% marker; otherwise just take the first (already ordered by the caller
% when order matters).
name = candidate_names{1};
for i = 1:numel(candidate_names)
    if isfield(TDTdata.epocs.(candidate_names{i}), 'offset')
        name = candidate_names{i};
        return;
    end
end
end

