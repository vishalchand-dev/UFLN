# UFLN statistical analysis -- Phase 1: reliability
# Manuscript: "UFLN: A Controlled Landmark-Visibility Benchmark for Robot Navigation"
# R version used for the final validation: R 4.6.2
#
# Primary experimental unit: evaluation map.
# For stochastic planners, success is first reduced to a per-map success proportion.
# Deterministic planners contribute one binary success value per map.
#
# Usage from the project/reproducibility root:
#   Rscript 01_reliability.R [path/to/Results_Raw.csv]
#
# If no argument is supplied, the script expects:
#   data/primary/Results_Raw.csv

options(stringsAsFactors = FALSE)

planner_order <- c(
  "GREEDY", "DVWP", "DIJKSTRA", "ASTAR",
  "ACO", "BA", "FA", "SAFA", "RRT"
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

output_dir <- file.path("analysis_outputs", "phase1_reliability")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

raw <- read.csv(results_file, check.names = FALSE)
main <- subset(raw, phase == "MAIN" & record_type == "PATH")

stopifnot(nrow(main) == 13860)
stopifnot(length(unique(main$map_id)) == 90)
stopifnot(setequal(unique(main$planner), planner_order))

# -------------------------------------------------------------------
# 1. Map-level reliability
# -------------------------------------------------------------------

map_success <- aggregate(
  success ~ planner + map_id,
  data = main,
  FUN = mean
)

stopifnot(nrow(map_success) == 90 * 9)

mean_success <- aggregate(success ~ planner, data = map_success, FUN = mean)
median_success <- aggregate(success ~ planner, data = map_success, FUN = median)

success_summary <- merge(
  mean_success,
  median_success,
  by = "planner",
  suffixes = c("_mean", "_median")
)

success_summary$mean_success_percent <- 100 * success_summary$success_mean
success_summary$median_success_percent <- 100 * success_summary$success_median
success_summary <- success_summary[
  match(planner_order, success_summary$planner),
  c("planner", "mean_success_percent", "median_success_percent")
]

# 50,000-resample paired map bootstrap CIs for each planner mean.
set.seed(20261118)
B_reliability <- 50000

success_matrix <- xtabs(success ~ map_id + planner, data = map_success)
success_matrix <- success_matrix[, planner_order, drop = FALSE]

boot_means <- matrix(
  NA_real_,
  nrow = B_reliability,
  ncol = length(planner_order),
  dimnames = list(NULL, planner_order)
)

for (b in seq_len(B_reliability)) {
  idx <- sample.int(
    nrow(success_matrix),
    size = nrow(success_matrix),
    replace = TRUE
  )
  boot_means[b, ] <- colMeans(success_matrix[idx, , drop = FALSE])
}

bootstrap_ci <- t(
  apply(
    boot_means,
    2,
    quantile,
    probs = c(0.025, 0.975),
    names = FALSE
  )
)

bootstrap_ci <- data.frame(
  planner = rownames(bootstrap_ci),
  ci_low_percent = 100 * bootstrap_ci[, 1],
  ci_high_percent = 100 * bootstrap_ci[, 2],
  row.names = NULL
)

bootstrap_ci <- bootstrap_ci[
  match(planner_order, bootstrap_ci$planner),
]

success_summary <- merge(success_summary, bootstrap_ci, by = "planner")
success_summary <- success_summary[
  match(planner_order, success_summary$planner),
]

write.csv(
  success_summary,
  file.path(output_dir, "reliability_summary.csv"),
  row.names = FALSE
)

# -------------------------------------------------------------------
# 2. Pairwise reliability robustness: 36 paired planner comparisons
# -------------------------------------------------------------------

pairs <- combn(planner_order, 2, simplify = FALSE)

set.seed(20261118)
B_pair_boot <- 50000
B_pair_sign <- 50000

pairwise_reliability <- data.frame(
  planner1 = character(),
  planner2 = character(),
  mean_difference_pp = numeric(),
  ci_low_pp = numeric(),
  ci_high_pp = numeric(),
  p_raw = numeric()
)

for (pr in pairs) {
  p1 <- pr[1]
  p2 <- pr[2]
  d <- success_matrix[, p1] - success_matrix[, p2]
  observed <- mean(d)

  boot_diff <- replicate(
    B_pair_boot,
    mean(sample(d, size = length(d), replace = TRUE))
  )

  ci <- quantile(
    boot_diff,
    probs = c(0.025, 0.975),
    names = FALSE
  )

  sign_stats <- numeric(B_pair_sign)
  for (b in seq_len(B_pair_sign)) {
    signs <- sample(c(-1, 1), size = length(d), replace = TRUE)
    sign_stats[b] <- mean(d * signs)
  }

  p_raw <- (
    1 + sum(abs(sign_stats) >= abs(observed))
  ) / (B_pair_sign + 1)

  pairwise_reliability <- rbind(
    pairwise_reliability,
    data.frame(
      planner1 = p1,
      planner2 = p2,
      mean_difference_pp = 100 * observed,
      ci_low_pp = 100 * ci[1],
      ci_high_pp = 100 * ci[2],
      p_raw = p_raw
    )
  )
}

pairwise_reliability$p_holm <- p.adjust(
  pairwise_reliability$p_raw,
  method = "holm"
)

write.csv(
  pairwise_reliability,
  file.path(output_dir, "pairwise_reliability.csv"),
  row.names = FALSE
)

# -------------------------------------------------------------------
# 3. Failure termination states
# -------------------------------------------------------------------

failures <- subset(main, success == 0)

failure_summary <- as.data.frame(
  table(failures$termination_reason, useNA = "ifany"),
  stringsAsFactors = FALSE
)
names(failure_summary) <- c("termination_reason", "count")

write.csv(
  failure_summary,
  file.path(output_dir, "failure_termination_summary.csv"),
  row.names = FALSE
)

# -------------------------------------------------------------------
# 4. Geometry score versus equal-planner map success
# -------------------------------------------------------------------

map_geom <- aggregate(
  map_difficulty_score ~ map_id,
  data = main,
  FUN = function(x) unique(x)[1]
)

equal_planner_map_success <- aggregate(
  success ~ map_id,
  data = map_success,
  FUN = mean
)

geom_check <- merge(
  map_geom,
  equal_planner_map_success,
  by = "map_id"
)

geom_test <- suppressWarnings(
  cor.test(
    geom_check$map_difficulty_score,
    geom_check$success,
    method = "spearman",
    exact = FALSE
  )
)

set.seed(20261118)
B_geom <- 15000
boot_rho <- numeric(B_geom)

for (b in seq_len(B_geom)) {
  idx <- sample.int(
    nrow(geom_check),
    size = nrow(geom_check),
    replace = TRUE
  )

  boot_sample <- geom_check[idx, ]

  boot_rho[b] <- suppressWarnings(
    cor(
      boot_sample$map_difficulty_score,
      boot_sample$success,
      method = "spearman"
    )
  )
}

geom_ci <- quantile(
  boot_rho,
  probs = c(0.025, 0.975),
  na.rm = TRUE,
  names = FALSE
)

geometry_result <- data.frame(
  n_maps = nrow(geom_check),
  spearman_rho = unname(geom_test$estimate),
  ci_low = geom_ci[1],
  ci_high = geom_ci[2],
  p_value = geom_test$p.value
)

write.csv(
  geometry_result,
  file.path(output_dir, "geometry_success_correlation.csv"),
  row.names = FALSE
)

# -------------------------------------------------------------------
# 5. Pre-specified difficulty contrast: easy versus medium+hard
# -------------------------------------------------------------------

map_difficulty <- aggregate(
  difficulty ~ map_id,
  data = main,
  FUN = function(x) unique(x)[1]
)

map_success_diff <- merge(
  map_success,
  map_difficulty,
  by = "map_id"
)

map_success_diff$group <- ifelse(
  map_success_diff$difficulty == "easy",
  "easy",
  "medium_hard"
)

difficulty_summary <- aggregate(
  success ~ planner + group,
  data = map_success_diff,
  FUN = mean
)

difficulty_summary$success_percent <- 100 * difficulty_summary$success
difficulty_summary <- difficulty_summary[, c("planner", "group", "success_percent")]

set.seed(20261118)
B_emh_boot <- 50000
B_emh_perm <- 50000

difficulty_inference <- data.frame(
  planner = character(),
  easy_minus_medium_hard_pp = numeric(),
  ci_low_pp = numeric(),
  ci_high_pp = numeric(),
  p_raw = numeric()
)

for (pl in planner_order) {
  tmp <- subset(map_success_diff, planner == pl)
  easy <- tmp$success[tmp$group == "easy"]
  medium_hard <- tmp$success[tmp$group == "medium_hard"]

  observed <- mean(easy) - mean(medium_hard)

  boot_diff <- replicate(
    B_emh_boot,
    mean(sample(easy, length(easy), replace = TRUE)) -
      mean(sample(medium_hard, length(medium_hard), replace = TRUE))
  )

  ci <- quantile(
    boot_diff,
    probs = c(0.025, 0.975),
    names = FALSE
  )

  pooled <- c(easy, medium_hard)
  n_easy <- length(easy)

  perm_diff <- replicate(
    B_emh_perm,
    {
      shuffled <- sample(pooled, replace = FALSE)
      mean(shuffled[seq_len(n_easy)]) -
        mean(shuffled[(n_easy + 1):length(shuffled)])
    }
  )

  p_raw <- (
    1 + sum(abs(perm_diff) >= abs(observed))
  ) / (B_emh_perm + 1)

  difficulty_inference <- rbind(
    difficulty_inference,
    data.frame(
      planner = pl,
      easy_minus_medium_hard_pp = 100 * observed,
      ci_low_pp = 100 * ci[1],
      ci_high_pp = 100 * ci[2],
      p_raw = p_raw
    )
  )
}

difficulty_inference$p_holm <- p.adjust(
  difficulty_inference$p_raw,
  method = "holm"
)

write.csv(
  difficulty_summary,
  file.path(output_dir, "difficulty_descriptive.csv"),
  row.names = FALSE
)

write.csv(
  difficulty_inference,
  file.path(output_dir, "difficulty_inference.csv"),
  row.names = FALSE
)

# -------------------------------------------------------------------
# 6. FA and RRT map-level success profiles
# -------------------------------------------------------------------

profile_one <- function(planner_name) {
  x <- subset(map_success, planner == planner_name)
  data.frame(
    planner = planner_name,
    maps_with_at_least_one_success = sum(x$success > 0),
    maps_with_all_runs_successful = sum(x$success == 1),
    maps_with_zero_successes = sum(x$success == 0)
  )
}

fa_rrt_profile <- rbind(
  profile_one("FA"),
  profile_one("RRT")
)

write.csv(
  fa_rrt_profile,
  file.path(output_dir, "FA_RRT_map_profiles.csv"),
  row.names = FALSE
)

# -------------------------------------------------------------------
# Console summary
# -------------------------------------------------------------------

cat("\nUFLN Phase 1: reliability\n")
cat("-------------------------\n")
print(success_summary, row.names = FALSE)

cat("\nPairwise reliability comparisons:", nrow(pairwise_reliability), "\n")
cat(
  "Bootstrap CIs excluding zero:",
  sum(
    pairwise_reliability$ci_low_pp > 0 |
      pairwise_reliability$ci_high_pp < 0
  ),
  "\n"
)
cat(
  "Holm-significant pairwise comparisons:",
  sum(pairwise_reliability$p_holm < 0.05),
  "\n"
)

cat("\nFailed primary runs:", nrow(failures), "\n")
print(failure_summary, row.names = FALSE)

cat("\nGeometry correlation:\n")
print(geometry_result, row.names = FALSE)

cat("\nEasy versus medium+hard inference:\n")
print(difficulty_inference, row.names = FALSE)

cat("\nFA/RRT profiles:\n")
print(fa_rrt_profile, row.names = FALSE)

cat("\nOutputs written to:", normalizePath(output_dir, winslash = "/", mustWork = FALSE), "\n")
capture.output(sessionInfo(), file = file.path(output_dir, "sessionInfo.txt"))