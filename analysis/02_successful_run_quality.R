# UFLN statistical analysis -- Phase 2: successful-run quality
# Manuscript: "UFLN: A Controlled Landmark-Visibility Benchmark for Robot Navigation"
# R version used for the final validation: R 4.6.2
#
# Continuous quality metrics are conditional on successful navigation.
# Stochastic repetitions are first reduced to one median value per planner-map.
# Primary cross-planner inference uses the complete block of maps on which all
# nine planners have at least one successful run.
#
# Usage:
#   Rscript 02_successful_run_quality.R [path/to/Results_Raw.csv]

options(stringsAsFactors = FALSE)

planner_order <- c(
  "GREEDY", "DVWP", "DIJKSTRA", "ASTAR",
  "ACO", "BA", "FA", "SAFA", "RRT"
)

quality_metrics <- c(
  "path_length",
  "path_ratio",
  "min_clearance",
  "p05_clearance",
  "heading_variation_per_m",
  "linear_accel_rms",
  "angular_accel_rms",
  "control_effort"
)

args <- commandArgs(trailingOnly = TRUE)
results_file <- if (length(args) >= 1) args[1] else file.path("data", "primary", "Results_Raw.csv")

if (!file.exists(results_file)) {
  stop(
    paste0(
      "Results file not found: ", results_file, "\n",
      "Run from the project root or pass Results_Raw.csv as the first argument."
    )
  )
}

output_dir <- file.path("analysis_outputs", "phase2_quality")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

raw <- read.csv(results_file, check.names = FALSE)
main <- subset(raw, phase == "MAIN" & record_type == "PATH")
successful <- subset(main, success == 1)

stopifnot(nrow(main) == 13860)
stopifnot(nrow(successful) == 11292)

# -------------------------------------------------------------------
# 1. Reduce successful repetitions to planner-map medians
# -------------------------------------------------------------------

quality_summary <- aggregate(
  successful[, quality_metrics],
  by = list(
    planner = successful$planner,
    map_id = successful$map_id
  ),
  FUN = median
)

planners_per_map <- table(quality_summary$map_id)
common_maps <- names(planners_per_map[planners_per_map == 9])

quality_common <- subset(
  quality_summary,
  map_id %in% common_maps
)

stopifnot(length(common_maps) == 44)
stopifnot(nrow(quality_common) == 44 * 9)

# -------------------------------------------------------------------
# 2. Friedman omnibus tests and Kendall's W
# -------------------------------------------------------------------

friedman_results <- data.frame(
  metric = character(),
  n_maps = integer(),
  n_planners = integer(),
  chi_square = numeric(),
  df = numeric(),
  p_raw = numeric(),
  kendalls_W = numeric()
)

for (metric in quality_metrics) {
  tmp <- quality_common[, c("map_id", "planner", metric)]

  wide <- reshape(
    tmp,
    idvar = "map_id",
    timevar = "planner",
    direction = "wide"
  )

  wanted_cols <- paste0(metric, ".", planner_order)
  X <- as.matrix(wide[, wanted_cols])

  ft <- friedman.test(X)

  n_maps <- nrow(X)
  k_planners <- ncol(X)
  W <- as.numeric(ft$statistic) / (n_maps * (k_planners - 1))

  friedman_results <- rbind(
    friedman_results,
    data.frame(
      metric = metric,
      n_maps = n_maps,
      n_planners = k_planners,
      chi_square = as.numeric(ft$statistic),
      df = as.numeric(ft$parameter),
      p_raw = ft$p.value,
      kendalls_W = W
    )
  )
}

friedman_results$p_holm <- p.adjust(
  friedman_results$p_raw,
  method = "holm"
)

write.csv(
  friedman_results,
  file.path(output_dir, "friedman_kendallW.csv"),
  row.names = FALSE
)

# -------------------------------------------------------------------
# 3. Manuscript quality table: medians across the 44 common maps
# -------------------------------------------------------------------

table11_all_metrics <- aggregate(
  quality_common[, quality_metrics],
  by = list(planner = quality_common$planner),
  FUN = median
)

table11_all_metrics <- table11_all_metrics[
  match(planner_order, table11_all_metrics$planner),
]

write.csv(
  table11_all_metrics,
  file.path(output_dir, "common44_planner_medians.csv"),
  row.names = FALSE
)

# -------------------------------------------------------------------
# 4. Pairwise paired Wilcoxon tests on the complete 44-map block
#    Holm correction is applied separately within each metric.
# -------------------------------------------------------------------

wilcox_results <- data.frame()

for (metric in quality_metrics) {
  tmp <- quality_common[, c("map_id", "planner", metric)]

  wide <- reshape(
    tmp,
    idvar = "map_id",
    timevar = "planner",
    direction = "wide"
  )

  metric_rows <- data.frame()

  for (i in 1:(length(planner_order) - 1)) {
    for (j in (i + 1):length(planner_order)) {
      p1 <- planner_order[i]
      p2 <- planner_order[j]

      x <- wide[[paste0(metric, ".", p1)]]
      y <- wide[[paste0(metric, ".", p2)]]

      wt <- suppressWarnings(
        wilcox.test(
          x,
          y,
          paired = TRUE,
          exact = FALSE
        )
      )

      metric_rows <- rbind(
        metric_rows,
        data.frame(
          metric = metric,
          planner1 = p1,
          planner2 = p2,
          n_maps = length(x),
          median_difference = median(x - y),
          p_raw = wt$p.value
        )
      )
    }
  }

  metric_rows$p_holm <- p.adjust(
    metric_rows$p_raw,
    method = "holm"
  )

  wilcox_results <- rbind(wilcox_results, metric_rows)
}

write.csv(
  wilcox_results,
  file.path(output_dir, "pairwise_wilcoxon_common44.csv"),
  row.names = FALSE
)

wilcox_summary <- aggregate(
  p_holm ~ metric,
  data = wilcox_results,
  FUN = function(x) sum(x < 0.05)
)
names(wilcox_summary)[2] <- "significant_pairs_after_holm"

write.csv(
  wilcox_summary,
  file.path(output_dir, "pairwise_wilcoxon_summary.csv"),
  row.names = FALSE
)

# -------------------------------------------------------------------
# 5. Pre-specified redundancy/supporting correlations
# -------------------------------------------------------------------

correlations <- data.frame(
  pair = c(
    "min_clearance_vs_p05_clearance",
    "heading_variation_vs_angular_accel_rms",
    "path_ratio_vs_control_effort"
  ),
  spearman_rho = c(
    cor(
      quality_common$min_clearance,
      quality_common$p05_clearance,
      method = "spearman"
    ),
    cor(
      quality_common$heading_variation_per_m,
      quality_common$angular_accel_rms,
      method = "spearman"
    ),
    cor(
      quality_common$path_ratio,
      quality_common$control_effort,
      method = "spearman"
    )
  )
)

write.csv(
  correlations,
  file.path(output_dir, "supporting_correlations.csv"),
  row.names = FALSE
)

# -------------------------------------------------------------------
# 6. Shared-success robustness analysis
#    Each planner pair is re-evaluated on every map where both planners
#    have at least one successful run, rather than only on the 44-map
#    all-planner complete block.
# -------------------------------------------------------------------

shared_results <- data.frame()

for (metric in quality_metrics) {
  for (i in 1:(length(planner_order) - 1)) {
    for (j in (i + 1):length(planner_order)) {
      p1 <- planner_order[i]
      p2 <- planner_order[j]

      d1 <- quality_summary[
        quality_summary$planner == p1,
        c("map_id", metric)
      ]
      d2 <- quality_summary[
        quality_summary$planner == p2,
        c("map_id", metric)
      ]

      names(d1)[2] <- "x"
      names(d2)[2] <- "y"

      paired <- merge(d1, d2, by = "map_id")
      shared_diff <- median(paired$x - paired$y)

      main_row <- wilcox_results[
        wilcox_results$metric == metric &
          wilcox_results$planner1 == p1 &
          wilcox_results$planner2 == p2,
      ]

      main_diff <- main_row$median_difference

      wt <- suppressWarnings(
        wilcox.test(
          paired$x,
          paired$y,
          paired = TRUE,
          exact = FALSE
        )
      )

      shared_results <- rbind(
        shared_results,
        data.frame(
          metric = metric,
          planner1 = p1,
          planner2 = p2,
          n_maps = nrow(paired),
          common44_difference = main_diff,
          shared_success_difference = shared_diff,
          direction_agrees = sign(main_diff) == sign(shared_diff),
          p_raw = wt$p.value
        )
      )
    }
  }
}

shared_results$p_holm <- NA_real_

for (metric in quality_metrics) {
  idx <- shared_results$metric == metric
  shared_results$p_holm[idx] <- p.adjust(
    shared_results$p_raw[idx],
    method = "holm"
  )
}

write.csv(
  shared_results,
  file.path(output_dir, "shared_success_robustness.csv"),
  row.names = FALSE
)

# -------------------------------------------------------------------
# Console summary
# -------------------------------------------------------------------

cat("\nUFLN Phase 2: successful-run quality\n")
cat("------------------------------------\n")
cat("Successful primary runs:", nrow(successful), "\n")
cat("Successful planner-map summaries:", nrow(quality_summary), "\n")
cat("Maps with success from all 9 planners:", length(common_maps), "\n")
cat("Rows in complete block:", nrow(quality_common), "\n\n")

print(friedman_results, row.names = FALSE)

cat(
  "\nFriedman tests significant after Holm:",
  sum(friedman_results$p_holm < 0.05),
  "of",
  nrow(friedman_results),
  "\n"
)

cat("\nCommon-44 planner medians:\n")
print(table11_all_metrics, row.names = FALSE)

cat("\nSupporting Spearman correlations:\n")
print(correlations, row.names = FALSE)

cat("\nShared-success robustness:\n")
cat("Total comparisons:", nrow(shared_results), "\n")
cat(
  "Shared-success map-count range:",
  min(shared_results$n_maps),
  "to",
  max(shared_results$n_maps),
  "\n"
)
cat("Median shared-success map count:", median(shared_results$n_maps), "\n")
cat("Direction agreements:", sum(shared_results$direction_agrees), "\n")
cat("Direction reversals:", sum(!shared_results$direction_agrees), "\n")
cat(
  "Agreement percentage:",
  round(100 * mean(shared_results$direction_agrees), 1),
  "%\n"
)

reversals <- subset(shared_results, !direction_agrees)
if (nrow(reversals) > 0) {
  cat(
    "Largest absolute shared-success difference among reversals:",
    max(abs(reversals$shared_success_difference)),
    "\n"
  )
}

cat("\nOutputs written to:", normalizePath(output_dir, winslash = "/", mustWork = FALSE), "\n")
capture.output(sessionInfo(), file = file.path(output_dir, "sessionInfo.txt"))