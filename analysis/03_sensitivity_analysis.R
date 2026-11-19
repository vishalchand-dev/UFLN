# UFLN V2.2.1 publication analysis
# 03_sensitivity_analysis.R
# Paired map-level sensitivity analysis against BASE.
# Base R only.

options(stringsAsFactors = FALSE)

find_repo_root <- function() {
  candidates <- unique(normalizePath(c(".", "..", "../.."), winslash = "/", mustWork = FALSE))
  for (p in candidates) {
    if (file.exists(file.path(p, "data", "sensitivity", "Sensitivity_Raw.csv"))) return(p)
  }
  stop("Repository root not found.")
}

root <- find_repo_root()
out_dir <- file.path(root, "analysis", "output", "tables")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

d <- read.csv(file.path(root, "data", "sensitivity", "Sensitivity_Raw.csv"), check.names = FALSE)
d <- d[d$record_type == "PATH", , drop = FALSE]
d$success <- as.integer(d$success)

required <- c("condition_id","planner","map_id","difficulty","success","path_ratio",
              "min_clearance","p05_clearance","heading_variation_per_m",
              "linear_accel_rms","angular_accel_rms","control_effort")
miss <- setdiff(required, names(d))
if (length(miss)) stop("Missing columns: ", paste(miss, collapse = ", "))
if (!"BASE" %in% unique(d$condition_id)) stop("BASE sensitivity condition not found.")

B <- as.integer(Sys.getenv("UFLN_BOOT_B", "2000"))
if (is.na(B) || B < 200) stop("UFLN_BOOT_B must be an integer >= 200.")
set.seed(22022)

paired_condition_effect <- function(map_df, value, metric) {
  planners <- sort(unique(as.character(map_df$planner)))
  conditions <- setdiff(sort(unique(as.character(map_df$condition_id))), "BASE")
  out <- list()
  k <- 1L

  for (p in planners) {
    base <- map_df[map_df$planner == p & map_df$condition_id == "BASE",
                   c("map_id","difficulty",value), drop = FALSE]
    names(base)[3] <- "base"

    for (cond in conditions) {
      alt <- map_df[map_df$planner == p & map_df$condition_id == cond,
                    c("map_id",value), drop = FALSE]
      names(alt)[2] <- "alt"
      z <- merge(base, alt, by = "map_id")
      z <- z[is.finite(z$base) & is.finite(z$alt), , drop = FALSE]
      if (!nrow(z)) next
      z$delta <- z$alt - z$base

      strata <- split(z, z$difficulty)
      boot <- numeric(B)
      for (i in seq_len(B)) {
        vals <- unlist(lapply(strata, function(s) {
          s$delta[sample(seq_len(nrow(s)), nrow(s), replace = TRUE)]
        }), use.names = FALSE)
        boot[i] <- mean(vals)
      }
      ci <- quantile(boot, c(0.025, 0.975), na.rm = TRUE, names = FALSE)

      out[[k]] <- data.frame(
        metric = metric,
        planner = p,
        condition_id = cond,
        maps_paired = nrow(z),
        effect_condition_minus_BASE = mean(z$delta),
        ci_low = ci[1],
        ci_high = ci[2]
      )
      k <- k + 1L
    }
  }
  do.call(rbind, out)
}

# Reliability
success_map <- aggregate(success ~ condition_id + planner + map_id + difficulty, data = d, FUN = mean)
success_effects <- paired_condition_effect(success_map, "success", "success_proportion")

# Conditional quality
metrics <- c(
  "path_ratio","min_clearance","p05_clearance","heading_variation_per_m",
  "linear_accel_rms","angular_accel_rms","control_effort"
)

quality_effects <- list()
for (m in metrics) {
  ds <- d[d$success == 1 & is.finite(d[[m]]),
          c("condition_id","planner","map_id","difficulty",m), drop = FALSE]
  map_m <- aggregate(ds[[m]],
                     by = list(condition_id = ds$condition_id, planner = ds$planner,
                               map_id = ds$map_id, difficulty = ds$difficulty),
                     FUN = mean)
  names(map_m)[5] <- "value"
  quality_effects[[m]] <- paired_condition_effect(map_m, "value", m)
}

quality_effects <- do.call(rbind, quality_effects)

# Compact descriptive table by condition/planner.
success_summary <- aggregate(success ~ condition_id + planner, data = success_map, FUN = mean)
names(success_summary)[3] <- "mean_map_success_proportion"

write.csv(success_summary, file.path(out_dir, "sensitivity_planner_summary.csv"), row.names = FALSE)
write.csv(success_effects, file.path(out_dir, "sensitivity_success_effects.csv"), row.names = FALSE)
write.csv(quality_effects, file.path(out_dir, "sensitivity_quality_effects.csv"), row.names = FALSE)

cat("Sensitivity analysis complete.\n")
cat("Bootstrap replicates:", B, "\n")
cat("Effects use condition - BASE on shared maps.\n")
cat("Outputs:", out_dir, "\n")
