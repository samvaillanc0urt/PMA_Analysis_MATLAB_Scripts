# Data layout

Most scripts find their inputs by **folder and file name**. If a rule below is broken, the usual result is a silently wrong answer rather than an error, so set the layout up once and keep it.

## Structure

```
<dataset root>\                         e.g. 2026-08-20_PVcre_PMA (first acquisition day + cohort)
├── sham_HabD1\                         condition = <group>_<Day>
│   ├── PVFP_01_sham_HabD1_SV_Aug20\    session = one animal, one day
│   │   ├── PVFP_01_HabD1_SV_Aug20_2026-08-20_10-02-11.mat
│   │   ├── PVFP_01_HabD1_SV_Aug20_camera_<ts>_preprocessed.mp4
│   │   ├── PVFP_01_..._DLC_<network>_filtered.csv
│   │   ├── PVFP_01_..._reward_data_<ts>.txt
│   │   ├── PVFP_01_sham_HabD1_SV_Aug20_csp_cue_frames.csv     generated (step 4)
│   │   ├── PVFP_01_sham_HabD1_SV_Aug20_analyzed\              generated (steps 5–6)
│   │   ├── PVFP_01_sham_HabD1_SV_Aug20_photometry\            TDT block, if recorded
│   │   └── quality_control\                                   extras (see below)
│   └── …
├── tms_HabD1\
├── … one sham_/tms_ pair per day …
└── og_large_vids\                      original .avi files (moved here by step 1)
```

## Naming

| Level | Pattern | Example | Read by |
|---|---|---|---|
| Condition | `<group>_<Day>` | `tms_TrainD1` | Group comes from the prefix (`sham_` / `tms_`, lowercase). Day = the rest; sham and tms folders with the same day are paired. |
| Day | `HabD1–3`, `TrainD1–3`, `Retr` | `Retr` | Day type comes from the name (`Hab` / `Train` / `Retr`). A day split into two recordings uses `s1` / `s2`: `TrainD1s1`. |
| Session | `<SUBJECT>_<group>_<Day>_SV_<MonDD>` | `PVFP_01_tms_TrainD1_SV_Aug26` | The subject ID must match `PVFP_<n>` or `DCSP_<n>`. The folder name also becomes the cue-file prefix. |

Habituation-day filenames from the rig contain no group (`PVFP_01_HabD1_…`), even though the folder name does. That's expected. Don't rename the files: their names link them back to the rig logs, and the folders carry the organization.

## Session folder contents

| File | Comes from | Used by |
|---|---|---|
| `<prefix>_<date>_<time>.mat` | rig: tone, shock and camera timestamps (`ts.*`) | steps 1, 4, 8 |
| `<prefix>_camera_<ts>.avi` → `…_preprocessed.mp4` | rig → step 1 | steps 3, 4, 5 |
| `<prefix>_reward_data_<ts>.txt` | rig: reward-port and beam-break events | step 1 |
| `…DLC_<network>_filtered.csv` | step 3 | step 5 |
| `<session>_csp_cue_frames.csv` (+ `_us_`, `_csm_`, `_laser_`) | step 4 | steps 5, 8 |
| `<session>_analyzed\` | step 5 (`Behavior/Tracking/Metrics/Params.mat`), step 6 (`Analysis_DT_*.mat`) | steps 6, 7, 8 |
| `<session>_photometry\` | TDT acquisition (`.tev .tsq .tbk .tdx .tin .tnt`, `Notes.txt`) | step 8 |

**Keep extras out of the top level.** Raw `.avi` files, unfiltered DLC `.csv`/`.h5`, DLC-labeled videos and output from older networks belong in `quality_control\`.

## Rules the scripts depend on

| Rule | What happens if it's broken |
|---|---|
| Exactly one `.mat`, one video and one DLC table at the top of each session folder | Step 4 uses whichever it finds first, so it may read the wrong video. Every cue frame is then shifted, and no error appears. |
| Exactly one `*_analyzed` folder per session | Step 6 skips the session with an error. Step 7 drops it and only prints a console line. |
| Condition folders start with `sham_` or `tms_` | Step 7 excludes the folder, and step 8's report can't pair the groups. |
| Day names contain `Hab`, `Train` or `Retr` | The day type is wrong. Analyses that need shocks run only on `Train` days. |
| Subject IDs are `PVFP_<n>` or `DCSP_<n>` | The animal is missing from step 7's exclusion list and Activity Map, and the stats treat all such animals as one. |
| `*_photometry` sits directly in the session folder, next to `*_analyzed` | Step 8 doesn't find the session. |
| BehaviorDEPOT ROIs are named `platform` and `reward`, and the event is named `CSp` | Step 6 fails or writes nothing for that session. |
| Leave the dataset where it is after running step 8 | Step 8's group files store absolute paths, so moving the data breaks report rebuilds and Compare mode. |

## Reorganizing a raw acquisition dump

The rig writes one flat folder per day, with every animal's files side by side. To convert it:

1. **Map each subject to its group** using the training-day filenames (`_Tms_` / `_Sham_`). Check that all training days agree, then apply the same map to the habituation days.
2. **Work out each file's destination,** `<group>_<Day>\<SUBJ>_<group>_<Day>_SV_<MonDD>\`. Stop on any file whose name doesn't parse or whose group contradicts the map. That's a mislabeled session.
3. **Do a dry run first.** List every source → destination pair and read it before moving anything. Write the list to a manifest CSV so the move can be undone. Moves within the same drive are instant.
4. **File the photometry.** Rename each TDT block `<session>_photometry` and move it into its session folder. Match blocks by the `Subject:` line in `Notes.txt`, not by the folder name, and check that its `Start:` time matches the video. Photometry without a video stays at the root.
5. **Tidy up.** Keep one copy of shared stimulus files (e.g. `csp.wav`) at the root, delete the emptied day folders, and move extras into `quality_control\`.

## Pre-flight check: camera dropouts

`ts.camera_off − ts.camera_on` in the rig `.mat` should match the video's duration to within about 1 s. If the video is shorter, check whether the last tone still falls inside it.

- Step 1 prints a warning when the video is short.
- Step 4 drops any cues that fall after the video ends, so the session is analyzed with fewer tones. Missing tones appear as NaN, not 0.
