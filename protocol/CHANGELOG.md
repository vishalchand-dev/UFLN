# Changelog

## V2.2.1
Fresh folder derived from V2.2 after MATLAB deep validation found an implementation-only output-assignment bug in `ufln_track_waypoint`.

- Fixed `seg` so it is assigned on every tracker return path, including immediate waypoint completion and guarded exits.
- Added a lightweight tracker output/contract test to QUICK validation so this class of error is caught in the fast validation stage.
- Added per-planner progress text to DEEP validation.
- No scientific changes to maps, landmarks, robot model, planners, objective, metrics, schedules, calibration design, seeds, or V2.2 corpus.

## V2.2
Fresh folder. V2.1 primary evaluation was never run.

- Rebuilt calibration/evaluation landmark fields around a guaranteed route-linked backbone.
- Added independent MATLAB backbone/dead-end audit.
- Regenerated all 15 calibration and 90 evaluation maps from new seeds.
- Kept true heading-based FOV, sensing range, physical occlusion, finite-radius unicycle model.
- Replaced endpoint/sample safety emphasis with exact continuous segment clearance for circles/rectangles.
- Common stochastic objective now uses normalized progress/step/heading terms and exact continuous clearance over the full r_plan proposal segment.
- Shared tracker changed to stop-and-turn waypoint execution with rotate-only safety recovery.
- Split validation into fast QUICK structural checks and DEEP dedicated-map smoke tests.
- Replaced 3,060-record one-stage calibration with pre-specified two-stage screening/confirmation that reuses duplicate screen records.
- Improved long-run progress/ETA reporting and mandatory hash verification before experimental phases.

## V2.1 retired
Developmental calibration exposed a corpus flaw: random landmark fields could create maps with no viable UFLN landmark progression irrespective of planner. This was caught before primary evaluation and motivated V2.2.
