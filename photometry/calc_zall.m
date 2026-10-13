
function [zall, fig, epoc_length] = calc_zall(mouse, sig, bouts, beh_fps, beh2fp, FP_DS_FACTOR, TRANGE_pre, TRANGE_post, data, BASELINE_PER, ref_stream)
% SV 9/8/26: ref_stream (used below only to read the raw fiber-photometry
% sample rate for the x-axis label) is now an optional 11th argument,
% defaulting to 'x465A' - it used to be hardcoded, which is harmless for
% cohorts that do name their 465 store 'x465A' (true for every cohort
% analyzed with this pipeline so far) but would silently mislabel the
% axis for any future cohort whose Global-settings "Signal store (465)"
% field is set to something else.
if nargin < 11 || isempty(ref_stream)
    ref_stream = 'x465A';
end

%% Calculate signal over epocs
% only for use inside FP analysis code 
% needs beh_fps, beh2fp, data structure, FP_DS_FACTOR


% Create the time vector for each stream store
ts1 = round(bouts(:,1) - (TRANGE_pre*beh_fps));
ts2 = round(bouts(:,2) + (TRANGE_post*beh_fps));

% removePost = find(ts2 > length(beh2fp));
% ts1(removePost) = [];
% ts2(removePost) = [];

% enforce same length
tmp_dur = ts2-ts1;
beh_ts = [ts1, ts1+min(tmp_dur)];

temp = beh2fp;
if beh2fp(end) < length(sig)
     x = (length(sig) - beh2fp(end)) / 2;
    for i = size(beh2fp,2)+1: size(beh2fp,2) + x
        temp(i) = temp(i-1) + 2;
    end
    beh2fp = temp;
end


if beh_ts(end, 2) > length(sig)
    temp = beh2fp;
    for i = length(beh2fp)+1:beh_ts(end,2)
        temp(1,i) = temp(1,i-1)+2;
    end
    beh2fp = temp;
else 
    beh2fp = beh2fp;
end

if beh_ts(end,2)>length(beh2fp)
    beh_ts(end,:) = [];
end


% get fp frames corresponding to beh frames, enforce same length
remove = find(beh_ts < 0);
beh_ts(remove,:) = [];

fp_ts = round(beh2fp(beh_ts));
tmp_dur = fp_ts(:,2) - fp_ts(:,1);
fp_ts = [fp_ts(:,1), fp_ts(:,1)+min(tmp_dur)];
epoc_length = min(tmp_dur)+1;

% get baseline frames
bl_beh = round([beh_ts(:,1)+(BASELINE_PER(1)*beh_fps), beh_ts(:,1)+(BASELINE_PER(2)*beh_fps)]);

for i = size(bl_beh,1):-1:1
    if bl_beh(i,1) <= 0
        bl_beh(i,:) = [];
    else
        bl_beh(i,:) = bl_beh(i,:);
    end
end

bl_fp = beh2fp(bl_beh);
tmp_dur = bl_fp(:,2) - bl_fp(:,1);
bl_fp = [bl_fp(:,1), bl_fp(:,1)+min(tmp_dur)];
bl_length = min(tmp_dur);


% get signal for all trials and zscore
zall = zeros(size(bl_beh,1),epoc_length);

for i = 1:size(zall,1)
    zb = mean(sig(bl_fp(i,1):bl_fp(i,2))); % baseline period mean
    
    zsd = std(sig(bl_fp(i,1):bl_fp(i,2))); % baseline period stdev
   
    zall(i,:)=(sig(fp_ts(i,1):fp_ts(i,2)) - zb)/zsd; % Z score per bin
end


% get pre fp frame length for plotting
fp_fps = data.streams.(ref_stream).fs;
fp_fps = round(fp_fps/FP_DS_FACTOR);
pre = TRANGE_pre * fp_fps;
post = TRANGE_post*fp_fps;

% Plot heat map
fig = figure;
imagesc(zall)
colormap('parula'); 
c1 = colorbar; 
title(sprintf('Z-Score Heat Map, %d Trials', size(bl_beh,1)));
ylabel('Trials', 'FontSize', 12);
hold on;
% xline(pre, ':', 'LineWidth', 3);
% xline(epoc_length-post, ':', 'LineWidth', 3);

% get FP fps (downsample adjusted) to label xaxis

xlabel(sprintf('frames (@ %d frames per second)', fp_fps));

%subtitle(sprintf(['Baseline ', num2str(BASELINE_PER)]));
