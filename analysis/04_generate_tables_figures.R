# UFLN V2.2.1 publication analysis
# 04_generate_tables_figures.R
# Generates compact publication-facing tables and figures.
# Base R only.

options(stringsAsFactors = FALSE)

find_repo_root <- function() {
  candidates <- unique(normalizePath(c(".", "..", "../.."), winslash = "/", mustWork = FALSE))
  for (p in candidates) {
    if (dir.exists(file.path(p, "analysis"))) return(p)
  }
  stop("Repository root not found.")
}

root <- find_repo_root()
table_dir <- file.path(root, "analysis", "output", "tables")
fig_dir <- file.path(root, "analysis", "output", "figures")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

primary_file <- file.path(table_dir, "primary_planner_summary.csv")
sens_file <- file.path(table_dir, "sensitivity_success_effects.csv")

if (!file.exists(primary_file)) {
  stop("Run analysis/02_primary_analysis.R first.")
}
if (!file.exists(sens_file)) {
  stop("Run analysis/03_sensitivity_analysis.R first.")
}

primary <- read.csv(primary_file, check.names = FALSE)
sens <- read.csv(sens_file, check.names = FALSE)

plot_ci <- function(dat, title, xlab, file_stem) {
  dat <- dat[order(dat$estimate), , drop = FALSE]
  y <- seq_len(nrow(dat))

  png(file.path(fig_dir, paste0(file_stem, ".png")), width = 1800, height = 1100, res = 180)
  par(mar = c(5, 9, 4, 2) + 0.1)
  plot(dat$estimate, y, xlim = range(c(dat$ci_low, dat$ci_high), na.rm = TRUE),
       yaxt = "n", ylab = "", xlab = xlab, main = title, pch = 19)
  axis(2, at = y, labels = dat$planner, las = 1)
  segments(dat$ci_low, y, dat$ci_high, y)
  abline(v = 0, lty = 3)
  box()
  dev.off()

  pdf(file.path(fig_dir, paste0(file_stem, ".pdf")), width = 8, height = 5.5)
  par(mar = c(5, 9, 4, 2) + 0.1)
  plot(dat$estimate, y, xlim = range(c(dat$ci_low, dat$ci_high), na.rm = TRUE),
       yaxt = "n", ylab = "", xlab = xlab, main = title, pch = 19)
  axis(2, at = y, labels = dat$planner, las = 1)
  segments(dat$ci_low, y, dat$ci_high, y)
  abline(v = 0, lty = 3)
  box()
  dev.off()
}

success <- primary[primary$metric == "success_proportion", , drop = FALSE]
plot_ci(success,
        "UFLN V2.2.1: map-level success",
        "Mean map success proportion (95% bootstrap CI)",
        "primary_success")

path <- primary[primary$metric == "path_ratio", , drop = FALSE]
plot_ci(path,
        "UFLN V2.2.1: path ratio conditional on success",
        "Mean planner-map path ratio (95% bootstrap CI)",
        "primary_path_ratio")

# Sensitivity success delta heat-style table written as a matrix CSV.
if (nrow(sens)) {
  planners <- sort(unique(sens$planner))
  conds <- sort(unique(sens$condition_id))
  mat <- matrix(NA_real_, nrow = length(planners), ncol = length(conds),
                dimnames = list(planners, conds))
  for (i in seq_len(nrow(sens))) {
    mat[sens$planner[i], sens$condition_id[i]] <- sens$effect_condition_minus_BASE[i]
  }
  write.csv(mat, file.path(table_dir, "sensitivity_success_delta_matrix.csv"))
}

# Human-readable compact table for manuscript cross-checking.
compact <- primary[, c("metric","planner","maps","estimate","ci_low","ci_high")]
write.csv(compact, file.path(table_dir, "primary_summary_compact.csv"), row.names = FALSE)

cat("Tables/figures generated.\n")
cat("Tables:", table_dir, "\n")
cat("Figures:", fig_dir, "\n")
