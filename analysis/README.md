# Statistical analysis

This directory contains the publication-facing R scripts for the UFLN V2.2.1 benchmark study.

The scripts are intentionally separate from the authors' exploratory/private analysis workspace. They operate only on the released CSV files in `data/` and write generated outputs to `analysis/output/`, which is excluded from Git history.

## Software

- R 4.6.2
- Base R only; no contributed packages are required.

## Run order

Run the scripts from the repository root:

1. `Rscript analysis/01_prepare_data.R`
2. `Rscript analysis/02_primary_analysis.R`
3. `Rscript analysis/03_sensitivity_analysis.R`
4. `Rscript analysis/04_generate_tables_figures.R`

## Scripts

### 01_prepare_data.R

Validates the released V2.2.1 result tables, checks expected record counts and identifiers, and writes analysis-ready subsets.

### 02_primary_analysis.R

Implements map-level analysis for the primary MAIN/PATH experiment. Success is summarized first. Successful-run quality metrics are then summarized conditionally. Uncertainty is estimated by stratified bootstrap resampling of maps within the pre-specified difficulty strata.

The script also reports paired planner contrasts as effect magnitudes with percentile bootstrap confidence intervals. The sign convention is `planner_a - planner_b`.

### 03_sensitivity_analysis.R

Analyzes the eight sensitivity conditions. Each non-BASE condition is compared with BASE within planner on shared maps, again using map-level summaries and stratified bootstrap confidence intervals.

### 04_generate_tables_figures.R

Builds compact publication-facing tables and figures from the outputs of scripts 02 and 03.

## Statistical unit

The evaluation map is the primary independent experimental unit. Stochastic seeds characterize within-map variability and are summarized within planner-map before cross-map inference.

This follows `protocol/Statistical_Analysis_Plan_V2_2.md`.

## Important interpretation rule

Failure is analyzed as failure. Failed runs are not converted into short or otherwise attractive path-quality observations. Continuous path, safety, motion and control metrics are summarized only for successful runs and are explicitly conditional on success.

## Generated outputs

Generated files are written below:

```
analysis/output/
  processed/
  tables/
  figures/
```

These files are not tracked by Git. Final manuscript tables/figures should be regenerated from the frozen data and checked against the manuscript before archival release.
