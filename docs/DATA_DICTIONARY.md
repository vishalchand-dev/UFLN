# Data Dictionary

This file will define every released UFLN data field, units, allowed values, and interpretation.

## Primary result records

The final dictionary will document fields including, where applicable:

- planner
- map_id
- seed
- success
- termination_reason
- path_length
- path_ratio
- min_clearance
- p05_clearance
- heading_variation_per_m
- linear_accel_rms
- angular_accel_rms
- control_effort
- proposer_time_mean_s
- proposer_time_total_s
- end_to_end_time_s
- graph_expansions
- edge_checks
- objective_evals
- rrt_nodes
- planning_calls
- scan_recoveries
- visibility_loss_events
- mean_visible_landmarks_decision

## Sensitivity records

The final dictionary will additionally document:

- condition_id
- baseline and perturbed condition definitions
- stochastic seed schedule
- deterministic-run convention

## Units

Units and normalisations will be copied directly from the frozen benchmark protocol and manuscript rather than inferred after release.
