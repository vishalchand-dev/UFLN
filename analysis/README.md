# Statistical analysis

This directory contains the publication-facing R scripts used to reproduce the statistical analyses reported for the UFLN benchmark manuscript:

> **UFLN: A Controlled Landmark-Visibility Benchmark for Robot Navigation**

The scripts are clean, standalone versions of the final validated analysis workflow. Exploratory/private analysis workspaces are not included.

## Software

- R 4.6.2
- Base R only; no contributed packages are required.

## Run order

Run the scripts from the repository root:

1. `Rscript analysis/01_reliability.R`
2. `Rscript analysis/02_successful_run_quality.R`
3. `Rscript analysis/03_computation_timing.R`
4. `Rscript analysis/04_sensitivity.R`

Optional explicit input paths may be passed on the command line. By default, the scripts use the released files under `data/primary/` and `data/sensitivity/`.

## Scripts

### 01_reliability.R

Reproduces the primary reliability analysis using the evaluation map as the independent unit.

It includes:

- map-level success proportions for stochastic methods and binary map outcomes for deterministic methods;
- 50,000-resample map-bootstrap confidence intervals;
- 36 paired method comparisons with 50,000 Monte Carlo sign flips;
- Holm correction across the 36 reliability comparisons;
- easy-versus-(medium+hard) exploratory contrasts with Holm correction;
- the geometry-score versus empirical-success diagnostic with a 15,000-resample map bootstrap; and
- failure-termination summaries.

### 02_successful_run_quality.R

Reproduces the successful-run quality analysis.

Successful stochastic repetitions are first reduced to within-planner-map medians. The primary comparison then uses the common complete-block maps on which all nine methods achieved at least one successful run.

It includes:

- eight Friedman complete-block tests;
- Holm correction across the eight omnibus tests;
- Kendall's W effect sizes;
- paired Wilcoxon signed-rank post-hoc tests;
- Holm correction across the 36 method pairs within each metric;
- 50,000-resample map-bootstrap intervals for method summaries and paired median differences;
- descriptive Spearman redundancy checks; and
- pairwise shared-success robustness analysis.

### 03_computation_timing.R

Reproduces the deterministic timing analysis using the dedicated ten-repetition timing records.

It includes:

- median-of-ten reduction for each deterministic method-map pair;
- per-call waypoint-generation timing across all 90 evaluation maps;
- total waypoint-generation and end-to-end timing on the common deterministic-success map set;
- Friedman complete-block tests;
- paired Wilcoxon signed-rank post-hoc comparisons with Holm correction across the six deterministic method pairs;
- A* and Dijkstra workload summaries; and
- supporting stochastic proposer-time summaries.

The archived Phase 3 record did not preserve a verified exact bootstrap-resampling count for the supplementary timing confidence intervals. This script therefore does **not** invent a bootstrap count that cannot be verified from the retained analysis record.

### 04_sensitivity.R

Reproduces the 18-map, eight-condition sensitivity analysis.

It includes:

- exact verification that BASE sensitivity records reproduce the corresponding primary-evaluation records;
- planner-map-condition reliability summaries;
- 30,000-resample paired map-bootstrap intervals;
- 50,000 Monte Carlo sign-flip tests;
- Holm correction across the seven BASE-relative contrasts within each method;
- eight-condition Friedman tests with Holm correction across the nine method-level omnibus tests;
- the equal-planner secondary sensitivity summary, which gives each method equal weight within map; and
- successful-run quality sensitivity summaries after within-planner-map-condition median reduction.

## Statistical unit

The evaluation map is the primary independent experimental unit. Stochastic seeds quantify within-map variability and are reduced within planner-map before cross-map inference.

## Important interpretation rule

Failure is analysed as failure. Failed runs are not assigned artificial path-quality values. Continuous path, safety, motion, and control metrics are analysed only for successful navigation and are interpreted separately from reliability.

## Inputs

- `data/primary/Results_Raw.csv`
- `data/sensitivity/Sensitivity_Raw.csv`

## Generated outputs

Each script writes machine-readable CSV outputs to a phase-specific directory under `analysis_outputs/`.

Generated outputs are not intended to replace the frozen raw data. Manuscript tables, supplementary files, and figures should be checked against the final rerun before archival release.

## Important current status

These scripts reproduce the statistical procedures documented in the current manuscript and retained validation record. The manuscript and derived numerical outputs must still be regenerated after any correction that changes the frozen result data, including the identified goal-tolerance correction.
