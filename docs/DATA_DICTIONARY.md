# Data dictionary

This document describes the released UFLN result tables.

## Files

- `data/primary/Results_Raw.csv` — 18,270 records and 44 columns.
  - 13,860 MAIN/PATH records used for the primary planner evaluation.
  - 3,600 MAIN/TIMING records from the dedicated deterministic timing experiment.
  - 810 DIAGNOSTIC/PATH records retained as non-primary diagnostic cases.
- `data/sensitivity/Sensitivity_Raw.csv` — 7,776 records and 45 columns.
  - Eight sensitivity conditions, 972 records per condition.

The sensitivity file contains all primary fields plus `condition_id`.

## Core identifiers and design fields

| Field | Meaning |
|---|---|
| `record_key` | Unique run/record identifier. |
| `record_type` | Record class, e.g. `PATH` or `TIMING`. |
| `phase` | Experiment phase, e.g. `MAIN`, `DIAGNOSTIC`, or `SENSITIVITY`. |
| `condition_id` | Sensitivity condition identifier; present only in the sensitivity table. |
| `map_id` | Map identifier. |
| `corpus_version` | Corpus version string. |
| `difficulty` | Declared map difficulty stratum. |
| `planner` | Waypoint-generation method. |
| `seed` | Random seed; deterministic planners use the study's deterministic convention. |
| `rep` | Repetition index used by the run schedule. |
| `success` | Binary task-success flag. |
| `termination_reason` | Recorded termination state. |

## Navigation and path fields

| Field | Meaning / unit |
|---|---|
| `nav_steps` | Number of navigation-loop iterations. |
| `tracking_steps` | Number of controller tracking steps. |
| `path_length` | Executed path length in workspace distance units. |
| `reference_length` | Generator-certified feasible reference-route length. |
| `path_ratio` | `path_length / reference_length`. |
| `goal_error` | Final Euclidean distance from the goal. |

## Computation fields

| Field | Meaning / unit |
|---|---|
| `end_to_end_time_s` | End-to-end run time in seconds. |
| `proposer_time_total_s` | Total waypoint-proposer time in seconds. |
| `proposer_time_mean_s` | Mean proposer time per planning call in seconds. |
| `planning_calls` | Number of proposer/planner calls. |
| `objective_evals` | Objective-function evaluations where applicable. |
| `graph_expansions` | Graph-node expansions where applicable. |
| `edge_checks` | Graph-edge checks where applicable. |
| `rrt_nodes` | RRT node count where applicable. |

## Safety, motion, and control fields

| Field | Meaning / unit |
|---|---|
| `min_clearance` | Minimum continuous executed-path clearance relative to inflated obstacles. |
| `p05_clearance` | Fifth-percentile continuous executed-segment clearance. |
| `heading_variation_per_m` | Sum of absolute wrapped heading changes divided by executed path length. |
| `linear_accel_rms` | RMS numerical linear acceleration from controller commands. |
| `angular_accel_rms` | RMS numerical angular acceleration from controller commands. |
| `control_effort` | Comparative implementation-dependent index: integral of `v^2 + 0.2*omega^2` over time; not physical battery energy. |

## UFLN event fields

| Field | Meaning |
|---|---|
| `invalid_proposals` | Invalid waypoint proposals encountered. |
| `fallback_count` | Execution fallback events. |
| `scan_recoveries` | Scan-recovery events. |
| `scan_angle_total_rad` | Total recovery scan angle in radians. |
| `visibility_loss_events` | Visibility-loss events recorded by the navigation loop. |
| `landmark_switches` | Active-landmark selection/switch events. |
| `distinct_landmarks_reached` | Distinct landmarks marked reached during the run. |
| `mean_visible_landmarks_decision` | Mean number of visible landmarks at navigation decision points. |

## Map metadata fields

| Field | Meaning |
|---|---|
| `map_difficulty_score` | Continuous generator difficulty score. |
| `map_obstacle_area_ratio` | Map obstacle-area ratio. |
| `map_reference_path_ratio` | Generator reference-route path-ratio metadata. |
| `map_reference_min_clearance` | Minimum clearance of the generator-certified reference route. |
| `map_backbone_count` | Number of landmarks in the certified landmark backbone. |

## Sensitivity conditions

The sensitivity table uses the following `condition_id` values:

- `BASE`
- `FOV90`
- `FOV150`
- `RANGE12`
- `RANGE18`
- `LM_LOW`
- `LM_HIGH`
- `SAFE30`

Each condition contains 972 records: four deterministic planners evaluated once on each of 18 maps and five stochastic planners evaluated with 10 seeds on each of the same 18 maps.

## Interpretation notes

The evaluation map is the primary independent experimental unit for inferential analysis; stochastic seeds are within-map repetitions. Successful-run quality metrics are conditional on task success. The feasible reference route is used for normalization and is not claimed to be globally optimal.
