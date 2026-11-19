# Fast validation strategy

V2.2 separates validation into two layers so ordinary checks do not waste hours of laptop time.

## QUICK validation
`ok = Paper1_V22_validate_quick`

Checks all 105 generated calibration/evaluation map files for safe endpoints, reference-route safety, corpus version, and landmark-backbone/dead-end validity using the MATLAB experiment geometry. It then uses only the dedicated `VAL_SMOKE` map for low-budget proposer contract and RNG checks. It does **not** execute planner performance on the 90 holdout evaluation maps.

This is the command to rerun after ordinary code/config changes.

## DEEP validation
`ok = Paper1_V22_validate_deep`

Runs all nine planner code paths end-to-end only on the dedicated smoke-validation map using a reduced validation-only computational budget. It checks trace schema, continuous safety, termination handling, and full fixed-seed reproducibility. It does not alter scientific planner budgets stored in `Paper1_V22_config`.

Run DEEP after QUICK before calibration and again after final calibration selection immediately before freezing.

Validation is deliberately distinct from calibration. Calibration is a scientific experiment on 15 calibration maps and will still take materially longer than structural validation.


## V2.2.1 implementation guard
QUICK validation now invokes the shared tracker on a short safe waypoint to verify that all tracker outputs are assigned and have the expected schema before DEEP end-to-end validation.
