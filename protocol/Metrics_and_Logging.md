# V2.2 metrics and logging

Primary reliability: success, termination reason, task/map coverage.
Path: executed length D and D/D_ref, where D_ref is the fixed generator-certified feasible reference route. D_ref is not claimed to be a globally optimal path.
Computation: proposer_time_total_s and proposer_time_mean_s separately from end_to_end_time_s. Graph expansions, edge checks, objective evaluations, and RRT node counts are logged where applicable.
Safety: continuous minimum clearance Cmin and 5th-percentile segment clearance C05 relative to robot-radius + safety-margin inflated obstacles.
Motion/control: heading variation per metre, RMS linear acceleration, RMS angular acceleration, and a control-effort index integral(v^2 + 0.2 omega^2) dt. This is not battery energy.
UFLN-specific: invalid proposals, fallback count, scan recoveries, scan angle, visibility-loss events, landmark switches, distinct landmarks reached, and mean visible landmarks at decisions.

Trace fields: time, x, y, theta, v, omega, active landmark, visible landmark count, proposed waypoint, executed waypoint, continuous point clearance at the trace state, scan flag, fallback flag. All failed path traces and designated representative successes are retained.
