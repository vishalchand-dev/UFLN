# UFLN statistical analysis -- Phase 4: sensitivity analysis
# Manuscript: "UFLN: A Controlled Landmark-Visibility Benchmark for Robot Navigation"
# R version used for the final validation: R 4.6.2
#
# Reliability is reduced to one success value per planner-map-condition.
# Stochastic planners contribute a success proportion over 10 seeds; deterministic
# planners contribute one binary outcome. Equal-planner map-level reliability is
# then constructed by averaging the nine planner values within each map-condition.
#
# Usage:
#   Rscript 04_sensitivity.R [Sensitivity_Raw.csv] [Results_Raw.csv]
#
# Defaults:
#   data/sensitivity/Sensitivity_Raw.csv
#   data/primary/Results_Raw.csv

options(stringsAsFactors = FALSE)

planner_order <- c(
  "GREEDY", "DVWP", "DIJKSTRA", "ASTAR",
  "ACO", "BA", "FA", "SAFA", "RRT"
)

stochastic_planners <- c("ACO", "BA", "FA", "SAFA", "RRT")
deterministic_planners <- c("GREEDY", "DVWP", "DIJKSTRA", "ASTAR")

condition_order <- c(
  "BASE",
  "FOV90",
  "FOV150",
  "RANGE12",
  "RANGE18",
  "LM_LOW",
  "LM_HIGH",
  "SAFE30"
)

perturbations <- condition_order[condition_order != "BASE"]

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
sensitivity_file <- if (length(args) >= 1) args[1] else file.path("data", "sensitivity", "Sensitivity_Raw.csv")
results_file <- if (length(args) >= 2) args[2] else file.path("data", "primary", "Results_Raw.csv")

if (!file.exists(sensitivity_file)) {
  stop(
    paste0(
      "Sensitivity file not found: ", sensitivity_file, "\n",
      "Run from the project root or pass Sensitivity_Raw.csv as the first argument."
    )
  )
}

if (!file.exists(results_file)) {
  stop(
    paste0(
      "Results file not found: ", results_file, "\n",
      "Pass Results_Raw.csv as the second argument."
    )
  )
}

output_dir <- file.path("analysis_outputs", "phase4_sensitivity")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

sens <- read.csv(sensitivity_file, check.names = FALSE)
final_raw <- read.csv(results_file, check.names = FALSE)

stopifnot(nrow(sens) == 7776)
stopifnot(length(unique(sens$map_id)) == 18)
stopifnot(setequal(unique(sens$planner), planner_order))
stopifnot(setequal(unique(sens$condition_id), condition_order))

# -------------------------------------------------------------------
# 1. Structural checks
# -------------------------------------------------------------------

rep_counts <- aggregate(
  success ~ planner + map_id + condition_id,
  data = sens,
  FUN = length
)
names(rep_counts)[4] <- "n_records"

stopifnot(all(
  rep_counts$n_records[rep_counts$planner %in% stochastic_planners] == 10
))
stopifnot(all(
  rep_counts$n_records[rep_counts$planner %in% deterministic_planners] == 1
))

duplicate_keys <- duplicated(
  sens[, c("planner", "map_id", "condition_id", "seed")]
)
stopifnot(sum(duplicate_keys) == 0)

structural_summary <- data.frame(
  item = c(
    "rows",
    "maps",
    "planners",
    "conditions",
    "planner_map_condition_combinations",
    "duplicate_record_keys"
  ),
  value = c(
    nrow(sens),
    length(unique(sens$map_id)),
    length(unique(sens$planner)),
    length(unique(sens$condition_id)),
    nrow(rep_counts),
    sum(duplicate_keys)
  )
)

write.csv(
  structural_summary,
  file.path(output_dir, "structural_summary.csv"),
  row.names = FALSE
)

# -------------------------------------------------------------------
# 2. Verify BASE sensitivity records exactly reproduce matching MAIN/PATH
#    scientific fields from the primary evaluation.
# -------------------------------------------------------------------

base <- subset(sens, condition_id == "BASE")
main_final <- subset(
  final_raw,
  phase == "MAIN" & record_type == "PATH"
)

key_cols <- c("planner", "map_id", "seed")

base_keys <- unique(base[, key_cols])

main_match <- merge(
  main_final,
  base_keys,
  by = key_cols
)

scientific_fields <- c(
  "success",
  "termination_reason",
  "goal_error",
  "path_length",
  "path_ratio",
  "min_clearance",
  "p05_clearance",
  "heading_variation_per_m",
  "linear_accel_rms",
  "angular_accel_rms",
  "control_effort",
  "distinct_landmarks_reached",
  "landmark_switches",
  "visibility_loss_events",
  "scan_recoveries",
  "scan_angle_total_rad",
  "fallback_count",
  "nav_steps",
  "tracking_steps",
  "planning_calls",
  "mean_visible_landmarks_decision",
  "graph_expansions",
  "edge_checks",
  "objective_evals",
  "rrt_nodes",
  "invalid_proposals"
)

cmp <- merge(
  base[, c(key_cols, scientific_fields)],
  main_match[, c(key_cols, scientific_fields)],
  by = key_cols,
  suffixes = c("_BASE", "_MAIN")
)

baseline_comparison <- data.frame(
  field = scientific_fields,
  mismatches = NA_integer_
)

for (i in seq_along(scientific_fields)) {
  f <- scientific_fields[i]
  x <- cmp[[paste0(f, "_BASE")]]
  y <- cmp[[paste0(f, "_MAIN")]]

  both_na <- is.na(x) & is.na(y)

  if (is.numeric(x) || is.integer(x)) {
    same <- both_na |
      (!is.na(x) & !is.na(y) & x == y)
  } else {
    same <- both_na |
      (!is.na(x) & !is.na(y) & as.character(x) == as.character(y))
  }

  baseline_comparison$mismatches[i] <- sum(!same)
}

stopifnot(nrow(base) == 972)
stopifnot(nrow(cmp) == 972)
stopifnot(sum(baseline_comparison$mismatches) == 0)

write.csv(
  baseline_comparison,
  file.path(output_dir, "BASE_vs_MAIN_exact_reproduction.csv"),
  row.names = FALSE
)

# -------------------------------------------------------------------
# 3. Map-level reliability construction and descriptive condition summaries
# -------------------------------------------------------------------

sens_map <- aggregate(
  success ~ planner + map_id + condition_id,
  data = sens,
  FUN = mean
)

stopifnot(nrow(sens_map) == 9 * 18 * 8)

raw_condition_success <- aggregate(
  success ~ condition_id,
  data = sens,
  FUN = mean
)
raw_condition_success$success_percent <- 100 * raw_condition_success$success
raw_condition_success <- raw_condition_success[
  match(condition_order, raw_condition_success$condition_id),
  c("condition_id", "success_percent")
]

equal_map <- aggregate(
  success ~ map_id + condition_id,
  data = sens_map,
  FUN = mean
)

equal_condition <- aggregate(
  success ~ condition_id,
  data = equal_map,
  FUN = mean
)
equal_condition$mean_success_percent <- 100 * equal_condition$success
equal_condition <- equal_condition[
  match(condition_order, equal_condition$condition_id),
]

base_equal_percent <- equal_condition$mean_success_percent[
  equal_condition$condition_id == "BASE"
]

equal_condition$change_vs_BASE_pp <-
  equal_condition$mean_success_percent - base_equal_percent

equal_condition <- equal_condition[
  ,
  c("condition_id", "mean_success_percent", "change_vs_BASE_pp")
]

write.csv(
  raw_condition_success,
  file.path(output_dir, "raw_run_condition_success.csv"),
  row.names = FALSE
)

write.csv(
  equal_condition,
  file.path(output_dir, "equal_planner_condition_success.csv"),
  row.names = FALSE
)

# -------------------------------------------------------------------
# 4. Equal-planner BASE-relative sensitivity inference
#    30,000 paired-map bootstrap resamples
#    50,000 Monte Carlo sign flips
#    Holm correction across seven perturbations
# -------------------------------------------------------------------

set.seed(20261118)

B_boot <- 30000
B_sign <- 50000

base_eq <- subset(
  equal_map,
  condition_id == "BASE",
  select = c("map_id", "success")
)
names(base_eq)[2] <- "success_BASE"

equal_results <- data.frame(
  condition = perturbations,
  n_maps = NA_integer_,
  mean_change_pp = NA_real_,
  ci_low_pp = NA_real_,
  ci_high_pp = NA_real_,
  p_raw = NA_real_
)

for (j in seq_along(perturbations)) {
  cond <- perturbations[j]

  pert_eq <- subset(
    equal_map,
    condition_id == cond,
    select = c("map_id", "success")
  )
  names(pert_eq)[2] <- "success_PERT"

  paired <- merge(base_eq, pert_eq, by = "map_id")
  d <- paired$success_PERT - paired$success_BASE
  observed <- mean(d)

  boot_means <- replicate(
    B_boot,
    mean(sample(d, size = length(d), replace = TRUE))
  )

  ci <- quantile(
    boot_means,
    probs = c(0.025, 0.975),
    names = FALSE
  )

  sign_stats <- replicate(
    B_sign,
    mean(
      d * sample(
        c(-1, 1),
        size = length(d),
        replace = TRUE
      )
    )
  )

  p_mc <- (
    1 + sum(abs(sign_stats) >= abs(observed))
  ) / (B_sign + 1)

  equal_results$n_maps[j] <- length(d)
  equal_results$mean_change_pp[j] <- 100 * observed
  equal_results$ci_low_pp[j] <- 100 * ci[1]
  equal_results$ci_high_pp[j] <- 100 * ci[2]
  equal_results$p_raw[j] <- p_mc
}

equal_results$p_holm <- p.adjust(
  equal_results$p_raw,
  method = "holm"
)

write.csv(
  equal_results,
  file.path(output_dir, "equal_planner_BASE_relative_inference.csv"),
  row.names = FALSE
)

# -------------------------------------------------------------------
# 5. Planner-specific reliability robustness
# -------------------------------------------------------------------

set.seed(20261119)

planner_contrasts <- data.frame()
planner_friedman <- data.frame()

for (pl in planner_order) {
  dat <- subset(sens_map, planner == pl)

  base_pl <- subset(
    dat,
    condition_id == "BASE",
    select = c("map_id", "success")
  )
  names(base_pl)[2] <- "success_BASE"

  tmp_results <- data.frame(
    planner = pl,
    condition = perturbations,
    n_maps = NA_integer_,
    mean_change_pp = NA_real_,
    ci_low_pp = NA_real_,
    ci_high_pp = NA_real_,
    p_raw = NA_real_
  )

  for (j in seq_along(perturbations)) {
    cond <- perturbations[j]

    pert_pl <- subset(
      dat,
      condition_id == cond,
      select = c("map_id", "success")
    )
    names(pert_pl)[2] <- "success_PERT"

    paired <- merge(base_pl, pert_pl, by = "map_id")
    d <- paired$success_PERT - paired$success_BASE
    observed <- mean(d)

    boot_means <- replicate(
      30000,
      mean(sample(d, size = length(d), replace = TRUE))
    )

    ci <- quantile(
      boot_means,
      probs = c(0.025, 0.975),
      names = FALSE
    )

    sign_stats <- replicate(
      50000,
      mean(
        d * sample(
          c(-1, 1),
          size = length(d),
          replace = TRUE
        )
      )
    )

    p_mc <- (
      1 + sum(abs(sign_stats) >= abs(observed))
    ) / 50001

    tmp_results$n_maps[j] <- length(d)
    tmp_results$mean_change_pp[j] <- 100 * observed
    tmp_results$ci_low_pp[j] <- 100 * ci[1]
    tmp_results$ci_high_pp[j] <- 100 * ci[2]
    tmp_results$p_raw[j] <- p_mc
  }

  tmp_results$p_holm <- p.adjust(
    tmp_results$p_raw,
    method = "holm"
  )

  planner_contrasts <- rbind(
    planner_contrasts,
    tmp_results
  )

  wide <- reshape(
    dat[, c("map_id", "condition_id", "success")],
    idvar = "map_id",
    timevar = "condition_id",
    direction = "wide"
  )

  cols <- paste0("success.", condition_order)
  X <- as.matrix(wide[, cols])

  ft <- friedman.test(X)

  planner_friedman <- rbind(
    planner_friedman,
    data.frame(
      planner = pl,
      n_maps = nrow(X),
      chi_square = unname(ft$statistic),
      df = unname(ft$parameter),
      p_raw = ft$p.value
    )
  )
}

planner_friedman$p_holm <- p.adjust(
  planner_friedman$p_raw,
  method = "holm"
)

write.csv(
  planner_contrasts,
  file.path(output_dir, "planner_specific_BASE_contrasts.csv"),
  row.names = FALSE
)

write.csv(
  planner_friedman,
  file.path(output_dir, "planner_specific_friedman.csv"),
  row.names = FALSE
)

# -------------------------------------------------------------------
# 6. Successful-run quality sensitivity -- descriptive only
# -------------------------------------------------------------------

sens_success <- subset(sens, success == 1)

quality_sens <- aggregate(
  sens_success[, quality_metrics],
  by = list(
    planner = sens_success$planner,
    map_id = sens_success$map_id,
    condition_id = sens_success$condition_id
  ),
  FUN = median
)

base_q <- subset(quality_sens, condition_id == "BASE")

quality_changes <- data.frame()

for (cond in perturbations) {
  pert_q <- subset(quality_sens, condition_id == cond)

  paired_q <- merge(
    base_q,
    pert_q,
    by = c("planner", "map_id"),
    suffixes = c("_BASE", "_PERT")
  )

  for (metric in quality_metrics) {
    x <- paired_q[[paste0(metric, "_BASE")]]
    y <- paired_q[[paste0(metric, "_PERT")]]

    keep <- is.finite(x) & is.finite(y)
    d <- y[keep] - x[keep]

    quality_changes <- rbind(
      quality_changes,
      data.frame(
        condition = cond,
        metric = metric,
        n_pairs = length(d),
        median_change = median(d),
        mean_change = mean(d),
        positive = sum(d > 0),
        negative = sum(d < 0),
        zero = sum(d == 0)
      )
    )
  }
}

write.csv(
  quality_changes,
  file.path(output_dir, "successful_run_quality_changes.csv"),
  row.names = FALSE
)

# -------------------------------------------------------------------
# 7. Visible-landmark changes on successful paired planner-map summaries
# -------------------------------------------------------------------

vis_success <- aggregate(
  mean_visible_landmarks_decision ~ planner + map_id + condition_id,
  data = sens_success,
  FUN = median
)

base_vis <- subset(vis_success, condition_id == "BASE")
vis_changes <- data.frame()

for (cond in perturbations) {
  pert_vis <- subset(vis_success, condition_id == cond)

  paired_vis <- merge(
    base_vis,
    pert_vis,
    by = c("planner", "map_id"),
    suffixes = c("_BASE", "_PERT")
  )

  d <- paired_vis$mean_visible_landmarks_decision_PERT -
    paired_vis$mean_visible_landmarks_decision_BASE
  d <- d[is.finite(d)]

  vis_changes <- rbind(
    vis_changes,
    data.frame(
      condition = cond,
      n_pairs = length(d),
      median_change_visible = median(d),
      mean_change_visible = mean(d),
      positive = sum(d > 0),
      negative = sum(d < 0),
      zero = sum(d == 0)
    )
  )
}

write.csv(
  vis_changes,
  file.path(output_dir, "visible_landmark_changes.csv"),
  row.names = FALSE
)

# -------------------------------------------------------------------
# 8. Failure termination pattern
# -------------------------------------------------------------------

fail_sens <- subset(sens, success == 0)

failure_summary <- data.frame()

for (cond in condition_order) {
  f <- subset(fail_sens, condition_id == cond)
  n_fail <- nrow(f)
  n_nvl <- sum(
    f$termination_reason == "NO_VISIBLE_LANDMARK",
    na.rm = TRUE
  )

  failure_summary <- rbind(
    failure_summary,
    data.frame(
      condition = cond,
      failures = n_fail,
      no_visible_landmark = n_nvl,
      percent_NO_VISIBLE_LANDMARK =
        if (n_fail > 0) 100 * n_nvl / n_fail else NA_real_
    )
  )
}

write.csv(
  failure_summary,
  file.path(output_dir, "failure_termination_by_condition.csv"),
  row.names = FALSE
)

# -------------------------------------------------------------------
# Console summary
# -------------------------------------------------------------------

cat("\nUFLN Phase 4: sensitivity analysis\n")
cat("----------------------------------\n")
cat("Sensitivity rows:", nrow(sens), "\n")
cat("BASE rows:", nrow(base), "\n")
cat("BASE scientific-field mismatches:", sum(baseline_comparison$mismatches), "\n\n")

cat("Raw-run condition success (%):\n")
print(raw_condition_success, row.names = FALSE)

cat("\nEqual-planner condition success and BASE-relative change (pp):\n")
print(equal_condition, row.names = FALSE)

cat("\nEqual-planner BASE-relative inference:\n")
print(equal_results, row.names = FALSE)
cat(
  "Holm-significant perturbations:",
  sum(equal_results$p_holm < 0.05),
  "of 7\n"
)

cat("\nPlanner-specific robustness:\n")
cat(
  "BASE-relative contrasts surviving within-planner Holm:",
  sum(planner_contrasts$p_holm < 0.05),
  "\n"
)
cat(
  "Planner Friedman tests surviving Holm:",
  sum(planner_friedman$p_holm < 0.05),
  "of 9\n"
)
cat(
  "Minimum Holm-adjusted planner contrast p-value:",
  min(planner_contrasts$p_holm),
  "\n"
)

cat("\nRANGE12 successful-run quality changes:\n")
print(
  subset(quality_changes, condition == "RANGE12"),
  row.names = FALSE
)

cat("\nVisible-landmark changes:\n")
print(vis_changes, row.names = FALSE)

cat("\nSensitivity failures:", nrow(fail_sens), "\n")
print(failure_summary, row.names = FALSE)
cat(
  "Minimum NO_VISIBLE_LANDMARK share across conditions:",
  min(failure_summary$percent_NO_VISIBLE_LANDMARK, na.rm = TRUE),
  "%\n"
)

cat("\nOutputs written to:", normalizePath(output_dir, winslash = "/", mustWork = FALSE), "\n")
capture.output(sessionInfo(), file = file.path(output_dir, "sessionInfo.txt"))