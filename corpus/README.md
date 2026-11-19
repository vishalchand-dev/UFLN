# UFLN V2.2 corpus

Primary generated corpus: 90 evaluation maps (30 easy, 30 medium, 30 hard) and 15 separate calibration maps (5 per stratum). All primary maps were regenerated for V2.2 with new seeds. No V2.1 primary performance data exist.

Every map stores obstacle geometry, start pose, goal, a fixed feasible reference route, low/medium/high landmark sets, a certified landmark backbone, and geometry/difficulty metadata.

The landmark backbone is a validity certificate only. Tested planners are not given the backbone as a path and remain free to choose among all visible landmarks according to the shared UFLN selector.

`corpus_audit.csv` records the precomputed generator audit. MATLAB QUICK validation independently rechecks the important geometry and landmark-chain properties using the experiment's own geometry functions.

The feasible reference route is used for normalization, but is not claimed to be globally optimal.
