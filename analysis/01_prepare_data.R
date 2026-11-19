# UFLN V2.2.1 publication analysis
# 01_prepare_data.R
# Validates released tables and writes analysis-ready subsets.
# Base R only.

options(stringsAsFactors = FALSE)

find_repo_root <- function() {
  candidates <- unique(normalizePath(c(".", "..", "../.."), winslash = "/", mustWork = FALSE))
  for (p in candidates) {
    if (file.exists(file.path(p, "data", "primary", "Results_Raw.csv"))) return(p)
  }
  stop("Repository root not found. Run from the UFLN repository root or analysis directory.")
}

root <- find_repo_root()
primary_file <- file.path(root, "data", "primary", "Results_Raw.csv")
sensitivity_file <- file.path(root, "data", "sensitivity", "Sensitivity_Raw.csv")

out_dir <- file.path(root, "analysis", "output", "processed")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

cat("Reading released UFLN V2.2.1 result tables...\n")
primary <- read.csv(primary_file, check.names = FALSE)
sensitivity <- read.csv(sensitivity_file, check.names = FALSE)

required_primary <- c(
  "record_key","record_type","phase","map_id","corpus_version","difficulty",
  "planner","seed","rep","success","termination_reason","nav_steps",
  "tracking_steps","path_length","reference_length","path_ratio","goal_error",
  "end_to_end_time_s","proposer_time_total_s","proposer_time_mean_s",
  "planning_calls","min_clearance","p05_clearance",
  "heading_variation_per_m","linear_accel_rms","angular_accel_rms",
  "control_effort"
)

missing_primary <- setdiff(required_primary, names(primary))
if (length(missing_primary)) {
  stop("Primary table is missing required columns: ", paste(missing_primary, collapse = ", "))
}
if (!"condition_id" %in% names(sensitivity)) {
  stop("Sensitivity table is missing condition_id.")
}
missing_sens <- setdiff(required_primary, names(sensitivity))
if (length(missing_sens)) {
  stop("Sensitivity table is missing required columns: ", paste(missing_sens, collapse = ", "))
}

assert_equal <- function(actual, expected, label) {
  if (!identical(as.integer(actual), as.integer(expected))) {
    stop(label, ": expected ", expected, ", found ", actual)
  }
}

assert_equal(nrow(primary), 18270, "Primary total record count")
assert_equal(nrow(sensitivity), 7776, "Sensitivity total record count")

if (anyDuplicated(primary$record_key)) stop("Duplicate record_key values in primary table.")
if (anyDuplicated(sensitivity$record_key)) stop("Duplicate record_key values in sensitivity table.")

primary_path <- primary[primary$phase == "MAIN" & primary$record_type == "PATH", , drop = FALSE]
primary_timing <- primary[primary$phase == "MAIN" & primary$record_type == "TIMING", , drop = FALSE]
diagnostic_path <- primary[primary$phase == "DIAGNOSTIC" & primary$record_type == "PATH", , drop = FALSE]
sensitivity_path <- sensitivity[sensitivity$record_type == "PATH", , drop = FALSE]

assert_equal(nrow(primary_path), 13860, "MAIN/PATH record count")
assert_equal(nrow(primary_timing), 3600, "MAIN/TIMING record count")
assert_equal(nrow(diagnostic_path), 810, "DIAGNOSTIC/PATH record count")
assert_equal(nrow(sensitivity_path), 7776, "Sensitivity PATH record count")

coerce_design <- function(d) {
  d$planner <- factor(d$planner)
  d$map_id <- factor(d$map_id)
  d$difficulty <- factor(d$difficulty)
  d$success <- as.integer(d$success)
  d
}

primary_path <- coerce_design(primary_path)
primary_timing <- coerce_design(primary_timing)
diagnostic_path <- coerce_design(diagnostic_path)
sensitivity_path <- coerce_design(sensitivity_path)
sensitivity_path$condition_id <- factor(sensitivity_path$condition_id)

saveRDS(primary_path, file.path(out_dir, "primary_path.rds"))
saveRDS(primary_timing, file.path(out_dir, "primary_timing.rds"))
saveRDS(diagnostic_path, file.path(out_dir, "diagnostic_path.rds"))
saveRDS(sensitivity_path, file.path(out_dir, "sensitivity_path.rds"))

write.csv(primary_path, file.path(out_dir, "primary_path.csv"), row.names = FALSE)
write.csv(primary_timing, file.path(out_dir, "primary_timing.csv"), row.names = FALSE)
write.csv(diagnostic_path, file.path(out_dir, "diagnostic_path.csv"), row.names = FALSE)
write.csv(sensitivity_path, file.path(out_dir, "sensitivity_path.csv"), row.names = FALSE)

capture.output(sessionInfo(), file = file.path(out_dir, "R_sessionInfo.txt"))

cat("Validation PASS.\n")
cat("MAIN/PATH:", nrow(primary_path), "records\n")
cat("MAIN/TIMING:", nrow(primary_timing), "records\n")
cat("DIAGNOSTIC/PATH:", nrow(diagnostic_path), "records\n")
cat("SENSITIVITY/PATH:", nrow(sensitivity_path), "records\n")
cat("Processed data written to:", out_dir, "\n")
