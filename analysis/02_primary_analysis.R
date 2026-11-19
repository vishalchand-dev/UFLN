# UFLN V2.2.1 publication analysis
# 02_primary_analysis.R
# Map-level primary analysis with stratified bootstrap uncertainty.
# Base R only.

options(stringsAsFactors = FALSE)

find_repo_root <- function() {
  candidates <- unique(normalizePath(c(".", "..", "../.."), winslash = "/", mustWork = FALSE))
  for (p in candidates) {
    if (file.exists(file.path(p, "data", "primary", "Results_Raw.csv"))) return(p)
  }
  stop("Repository root not found.")
}

root <- find_repo_root()
out_dir <- file.path(root, "analysis", "output", "tables")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

d <- read.csv(file.path(root, "data", "primary", "Results_Raw.csv"), check.names = FALSE)
d <- d[d$phase == "MAIN" & d$record_type == "PATH", , drop = FALSE]
d$success <- as.integer(d$success)

required <- c("planner","map_id","difficulty","success","path_ratio","min_clearance",
              "p05_clearance","heading_variation_per_m","linear_accel_rms",
              "angular_accel_rms","control_effort","end_to_end_time_s",
              "proposer_time_total_s")
miss <- setdiff(required, names(d))
if (length(miss)) stop("Missing columns: ", paste(miss, collapse = ", "))

B <- as.integer(Sys.getenv("UFLN_BOOT_B", "2000"))
if (is.na(B) || B < 200) stop("UFLN_BOOT_B must be an integer >= 200.")
set.seed(22021)

mean_ci <- function(x) {
  x <- x[is.finite(x)]
  c(mean = mean(x), n = length(x))
}

stratified_boot_mean <- function(df, value, B = B) {
  strata <- split(unique(df[c("map_id","difficulty")]), unique(df$difficulty))
  reps <- numeric(B)
  for (b in seq_len(B)) {
    chosen <- unlist(lapply(strata, function(s) {
      as.character(sample(s$map_id, size = nrow(s), replace = TRUE))
    }), use.names = FALSE)
    vals <- unlist(lapply(chosen, function(m) df[df$map_id == m, value]), use.names = FALSE)
    reps[b] <- mean(vals[is.finite(vals)])
  }
  quantile(reps, c(0.025, 0.975), na.rm = TRUE, names = FALSE)
}

planner_summary <- function(map_df, value, metric) {
  ans <- lapply(split(map_df, map_df$planner), function(z) {
    ci <- stratified_boot_mean(z, value)
    data.frame(
      metric = metric,
      planner = as.character(z$planner[1]),
      maps = length(unique(z$map_id)),
      estimate = mean(z[[value]], na.rm = TRUE),
      ci_low = ci[1],
      ci_high = ci[2]
    )
  })
  do.call(rbind, ans)
}

paired_effects <- function(map_df, value, metric) {
  planners <- sort(unique(as.character(map_df$planner)))
  pairs <- combn(planners, 2, simplify = FALSE)

  out <- lapply(pairs, function(p) {
    a <- map_df[map_df$planner == p[1], c("map_id","difficulty",value), drop = FALSE]
    b <- map_df[map_df$planner == p[2], c("map_id",value), drop = FALSE]
    names(a)[3] <- "a"
    names(b)[2] <- "b"
    z <- merge(a, b, by = "map_id")
    z <- z[is.finite(z$a) & is.finite(z$b), , drop = FALSE]
    z$delta <- z$a - z$b

    strata <- split(z, z$difficulty)
    boot <- numeric(B)
    for (i in seq_len(B)) {
      vals <- unlist(lapply(strata, function(s) {
        s$delta[sample(seq_len(nrow(s)), nrow(s), replace = TRUE)]
      }), use.names = FALSE)
      boot[i] <- mean(vals)
    }
    ci <- quantile(boot, c(0.025, 0.975), na.rm = TRUE, names = FALSE)

    data.frame(
      metric = metric,
      planner_a = p[1],
      planner_b = p[2],
      maps_paired = nrow(z),
      effect_a_minus_b = mean(z$delta),
      ci_low = ci[1],
      ci_high = ci[2]
    )
  })
  do.call(rbind, out)
}

# Reliability: each planner-map is one unit; stochastic seeds form a success proportion.
success_map <- aggregate(success ~ planner + map_id + difficulty, data = d, FUN = mean)
success_summary <- planner_summary(success_map, "success", "success_proportion")
success_effects <- paired_effects(success_map, "success", "success_proportion")

# Successful-run quality is explicitly conditional on success.
quality_metrics <- c(
  "path_ratio","min_clearance","p05_clearance","heading_variation_per_m",
  "linear_accel_rms","angular_accel_rms","control_effort",
  "end_to_end_time_s","proposer_time_total_s"
)

quality_summaries <- list()
quality_effects <- list()

for (m in quality_metrics) {
  ds <- d[d$success == 1 & is.finite(d[[m]]), c("planner","map_id","difficulty",m), drop = FALSE]
  map_m <- aggregate(ds[[m]],
                     by = list(planner = ds$planner, map_id = ds$map_id, difficulty = ds$difficulty),
                     FUN = mean)
  names(map_m)[4] <- "value"
  quality_summaries[[m]] <- planner_summary(map_m, "value", m)
  quality_effects[[m]] <- paired_effects(map_m, "value", m)
}

summary_all <- rbind(success_summary, do.call(rbind, quality_summaries))
effects_all <- rbind(success_effects, do.call(rbind, quality_effects))

write.csv(success_map, file.path(out_dir, "primary_map_success.csv"), row.names = FALSE)
write.csv(summary_all, file.path(out_dir, "primary_planner_summary.csv"), row.names = FALSE)
write.csv(effects_all, file.path(out_dir, "primary_pairwise_effects.csv"), row.names = FALSE)

cat("Primary analysis complete.\n")
cat("Bootstrap replicates:", B, "\n")
cat("Outputs:", out_dir, "\n")
cat("Note: continuous quality metrics are conditional on successful runs.\n")
