# UFLN statistical analysis -- Phase 3: computation timing
# Manuscript: "UFLN: A Controlled Landmark-Visibility Benchmark for Robot Navigation"
# R version used for the final validation: R 4.6.2
#
# Dedicated deterministic timing records contain 10 repetitions for each
# planner-map combination. Timing is first reduced to the median of those
# 10 repetitions, leaving the evaluation map as the independent unit.
#
# Usage:
#   Rscript 03_computation_timing.R [path/to/Results_Raw.csv]

options(stringsAsFactors = FALSE)

deterministic_order <- c("GREEDY", "DVWP", "ASTAR", "DIJKSTRA")
all_planner_order <- c(
  "GREEDY", "DVWP", "DIJKSTRA", "ASTAR",
  "ACO", "BA", "FA", "SAFA", "RRT"
)
stochastic_order <- c("ACO", "BA", "FA", "SAFA", "RRT")

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

output_dir <- file.path("analysis_outputs", "phase3_timing")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

raw <- read.csv(results_file, check.names = FALSE)
main_path <- subset(raw, phase == "MAIN" & record_type == "PATH")
timing_raw <- subset(raw, phase == "MAIN" & record_type == "TIMING")

stopifnot(nrow(timing_raw) == 3600)
stopifnot(setequal(unique(timing_raw$planner), deterministic_order))

timing_counts <- aggregate(
  rep ~ planner + map_id,
  data = timing_raw,
  FUN = length
)
stopifnot(all(timing_counts$rep == 10))

# -------------------------------------------------------------------
# 1. Median-of-10 timing reduction for each deterministic planner-map
# -------------------------------------------------------------------

timing_metrics <- c(
  "proposer_time_mean_s",
  "proposer_time_total_s",
  "end_to_end_time_s"
)

timing_map <- aggregate(
  timing_raw[, timing_metrics],
  by = list(
    planner = timing_raw$planner,
    map_id = timing_raw$map_id
  ),
  FUN = median
)

stopifnot(nrow(timing_map) == 4 * 90)

per_call_summary <- aggregate(
  proposer_time_mean_s ~ planner,
  data = timing_map,
  FUN = median
)

per_call_summary$median_proposer_time_us <-
  1e6 * per_call_summary$proposer_time_mean_s

per_call_summary <- per_call_summary[
  match(deterministic_order, per_call_summary$planner),
  c("planner", "median_proposer_time_us")
]

write.csv(
  per_call_summary,
  file.path(output_dir, "deterministic_per_call_timing.csv"),
  row.names = FALSE
)

# -------------------------------------------------------------------
# 2. Identify maps successfully completed by all four deterministic methods
# -------------------------------------------------------------------

det_path <- subset(
  main_path,
  planner %in% deterministic_order
)

success_matrix <- xtabs(
  success ~ map_id + planner,
  data = det_path
)

common_success_maps <- rownames(success_matrix)[
  rowSums(success_matrix[, deterministic_order, drop = FALSE] == 1) ==
    length(deterministic_order)
]

stopifnot(length(common_success_maps) == 45)

timing_common45 <- subset(
  timing_map,
  map_id %in% common_success_maps
)

common45_summary <- aggregate(
  timing_common45[, timing_metrics],
  by = list(planner = timing_common45$planner),
  FUN = median
)

common45_summary <- common45_summary[
  match(deterministic_order, common45_summary$planner),
]

write.csv(
  common45_summary,
  file.path(output_dir, "deterministic_common45_timing.csv"),
  row.names = FALSE
)

# -------------------------------------------------------------------
# Helpers for Friedman and pairwise Wilcoxon analyses
# -------------------------------------------------------------------

run_friedman <- function(data, metric, planner_order, family_name) {
  tmp <- data[, c("map_id", "planner", metric)]

  wide <- reshape(
    tmp,
    idvar = "map_id",
    timevar = "planner",
    direction = "wide"
  )

  cols <- paste0(metric, ".", planner_order)
  X <- as.matrix(wide[, cols])

  ft <- friedman.test(X)

  data.frame(
    family = family_name,
    metric = metric,
    n_maps = nrow(X),
    chi_square = as.numeric(ft$statistic),
    df = as.numeric(ft$parameter),
    p_value = ft$p.value
  )
}

run_pairwise_wilcoxon <- function(data, metric, planner_order, family_name) {
  tmp <- data[, c("map_id", "planner", metric)]

  wide <- reshape(
    tmp,
    idvar = "map_id",
    timevar = "planner",
    direction = "wide"
  )

  out <- data.frame()

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

      out <- rbind(
        out,
        data.frame(
          family = family_name,
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

  out$p_holm <- p.adjust(out$p_raw, method = "holm")
  out
}

# -------------------------------------------------------------------
# 3. Inferential timing comparisons
# -------------------------------------------------------------------

friedman_results <- rbind(
  run_friedman(
    timing_map,
    "proposer_time_mean_s",
    deterministic_order,
    "per_call_all_90_maps"
  ),
  run_friedman(
    timing_common45,
    "proposer_time_total_s",
    deterministic_order,
    "total_proposer_common_45"
  ),
  run_friedman(
    timing_common45,
    "end_to_end_time_s",
    deterministic_order,
    "end_to_end_common_45"
  )
)

pairwise_results <- rbind(
  run_pairwise_wilcoxon(
    timing_map,
    "proposer_time_mean_s",
    deterministic_order,
    "per_call_all_90_maps"
  ),
  run_pairwise_wilcoxon(
    timing_common45,
    "proposer_time_total_s",
    deterministic_order,
    "total_proposer_common_45"
  ),
  run_pairwise_wilcoxon(
    timing_common45,
    "end_to_end_time_s",
    deterministic_order,
    "end_to_end_common_45"
  )
)

write.csv(
  friedman_results,
  file.path(output_dir, "timing_friedman.csv"),
  row.names = FALSE
)

write.csv(
  pairwise_results,
  file.path(output_dir, "timing_pairwise_wilcoxon.csv"),
  row.names = FALSE
)

# -------------------------------------------------------------------
# 4. A* versus Dijkstra graph-search workload on the 45 common-success maps
# -------------------------------------------------------------------

graph_common <- subset(
  det_path,
  map_id %in% common_success_maps &
    planner %in% c("ASTAR", "DIJKSTRA")
)

graph_summary <- aggregate(
  cbind(graph_expansions, edge_checks) ~ planner,
  data = graph_common,
  FUN = median
)

graph_summary <- graph_summary[
  match(c("ASTAR", "DIJKSTRA"), graph_summary$planner),
]

graph_wide_exp <- reshape(
  graph_common[, c("map_id", "planner", "graph_expansions")],
  idvar = "map_id",
  timevar = "planner",
  direction = "wide"
)

graph_wide_edge <- reshape(
  graph_common[, c("map_id", "planner", "edge_checks")],
  idvar = "map_id",
  timevar = "planner",
  direction = "wide"
)

workload_checks <- data.frame(
  metric = c("graph_expansions", "edge_checks"),
  maps = c(nrow(graph_wide_exp), nrow(graph_wide_edge)),
  astar_lower_count = c(
    sum(graph_wide_exp$graph_expansions.ASTAR <
          graph_wide_exp$graph_expansions.DIJKSTRA),
    sum(graph_wide_edge$edge_checks.ASTAR <
          graph_wide_edge$edge_checks.DIJKSTRA)
  )
)

write.csv(
  graph_summary,
  file.path(output_dir, "astar_dijkstra_workload_medians.csv"),
  row.names = FALSE
)

write.csv(
  workload_checks,
  file.path(output_dir, "astar_dijkstra_workload_checks.csv"),
  row.names = FALSE
)

# -------------------------------------------------------------------
# 5. Supporting stochastic proposer timing on the 44 all-planner-success maps
# -------------------------------------------------------------------

successful_path <- subset(main_path, success == 1)

successful_planner_maps <- aggregate(
  success ~ planner + map_id,
  data = successful_path,
  FUN = length
)

maps_per_success_block <- table(successful_planner_maps$map_id)
common44_maps <- names(maps_per_success_block[maps_per_success_block == 9])

stopifnot(length(common44_maps) == 44)

stoch_success <- subset(
  successful_path,
  planner %in% stochastic_order &
    map_id %in% common44_maps
)

stoch_map_timing <- aggregate(
  proposer_time_mean_s ~ planner + map_id,
  data = stoch_success,
  FUN = median
)

stoch_timing_summary <- aggregate(
  proposer_time_mean_s ~ planner,
  data = stoch_map_timing,
  FUN = median
)

stoch_timing_summary$median_proposer_time_ms <-
  1000 * stoch_timing_summary$proposer_time_mean_s

stoch_timing_summary <- stoch_timing_summary[
  match(stochastic_order, stoch_timing_summary$planner),
  c("planner", "median_proposer_time_ms")
]

write.csv(
  stoch_timing_summary,
  file.path(output_dir, "stochastic_supporting_timing.csv"),
  row.names = FALSE
)

# -------------------------------------------------------------------
# Console summary
# -------------------------------------------------------------------

cat("\nUFLN Phase 3: computation timing\n")
cat("--------------------------------\n")
cat("Dedicated timing records:", nrow(timing_raw), "\n")
cat("Median-of-10 planner-map summaries:", nrow(timing_map), "\n")
cat("Maps successful for all four deterministic methods:", length(common_success_maps), "\n\n")

cat("Deterministic proposer time per call (microseconds):\n")
print(per_call_summary, row.names = FALSE)

cat("\nCommon-45 deterministic timing medians (seconds):\n")
print(common45_summary, row.names = FALSE)

cat("\nFriedman tests:\n")
print(friedman_results, row.names = FALSE)

cat("\nPairwise Holm-significant counts by timing family:\n")
print(
  aggregate(
    p_holm ~ family,
    data = pairwise_results,
    FUN = function(x) sum(x < 0.05)
  ),
  row.names = FALSE
)

cat("\nA* versus Dijkstra workload medians:\n")
print(graph_summary, row.names = FALSE)
print(workload_checks, row.names = FALSE)

cat("\nSupporting stochastic proposer timing (milliseconds):\n")
print(stoch_timing_summary, row.names = FALSE)

cat("\nOutputs written to:", normalizePath(output_dir, winslash = "/", mustWork = FALSE), "\n")
capture.output(sessionInfo(), file = file.path(output_dir, "sessionInfo.txt"))