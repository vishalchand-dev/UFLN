# Paper 1 experimental protocol V2.2

## Scientific role
This is intended as the first journal introduction and broad simulation validation of UFLN as a benchmark protocol. Planner comparisons demonstrate the protocol's ability to expose robustness, quality, safety, computation, and visibility trade-offs under one declared contract.

## Partitions
**Calibration:** 15 independent generated maps, five per difficulty stratum. No evaluation-map performance may be used for parameter selection.

**Primary evaluation:** 90 independent generated maps, 30 easy, 30 medium, 30 hard. Difficulty strata differ in reference detour, obstacle density, corridor clearance, and a continuous geometry score.

**Diagnostic suite:** 15 historical thesis-linked start-goal cases retained as diagnostic anchors. They are not counted as independent primary environments.

**Sensitivity subset:** 18 evaluation-map IDs fixed in advance, six per difficulty stratum. Sensitivity is run only after the primary dataset is complete.

## Repetitions
Primary stochastic planners ACO, BA, FA, SAFA, RRT: 30 seeds per evaluation map.
Deterministic GREEDY, DVWP, Dijkstra, A*: one primary path per map plus 10 dedicated timing repetitions per map after warm-up.

## Two-stage calibration
Stage A screening: all four pre-specified candidates per tunable planner, six fixed calibration maps (two per stratum), five seeds for stochastic planners. Stage B confirmation: the two pre-specified-rule finalists per planner, all 15 calibration maps, ten seeds. Screening records that also belong to the confirmation design are reused rather than rerun.

Final selection is lexicographic: observed task/run success first, then median reference-normalized path length among successes, then median proposer time. This is a calibration rule, not the paper's final planner ranking.

## Holdout rule
After evaluation begins, no change to planner parameters, UFLN settings, corpus generation, stopping rules, or metric definitions is allowed. A scientific bug requires a new version, new validation, new freeze, and a new run.
