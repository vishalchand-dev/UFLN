# Reproducibility

## Purpose

This document describes the materials provided with the UFLN benchmark and paper-facing repository.

The repository is currently under coauthor review and should not yet be treated as the final archival release.

## Experiment reproduction

The repository documents the frozen MATLAB benchmark workflow, including:

- corpus/map loading and generation;
- the nine waypoint-generation methods;
- shared visibility, landmark selection, safety, recovery, and control logic;
- primary evaluation schedules;
- deterministic timing schedules;
- sensitivity schedules; and
- result/trace logging.

The frozen pre-analysis document is retained at `protocol/Statistical_Analysis_Plan_V2_2.md`. It records the analysis options considered before final manuscript analysis. The manuscript reports the final analyses actually used.

## Released result data

The repository includes:

- `data/primary/Results_Raw.csv`: 18,270 records, including the 13,860 primary MAIN/PATH records, 3,600 MAIN/TIMING records, and 810 diagnostic path records.
- `data/sensitivity/Sensitivity_Raw.csv`: 7,776 sensitivity records across eight conditions.

See `docs/DATA_DICTIONARY.md` for field definitions.

Statistical-analysis source scripts are not included in this GitHub repository. The manuscript records the statistical procedures and software environment used for the reported analyses.

## Frozen study environment

- Benchmark version: UFLN V2.2.1
- MATLAB: R2026a Update 4
- R: 4.6.2
- Operating system: Windows 11 Enterprise
- Hardware: Dell Pro 14 PC14250, Intel Core 7 150U, 32 GB RAM

Exact MATLAB toolbox information should be treated according to the captured environment record in `reproducibility/Environment_Captured.txt`.

## Integrity and provenance

`reproducibility/SHA256_Frozen_Files.csv` is the hash manifest produced for the original frozen experiment package before the GitHub-facing directory reorganisation. Its stored relative paths therefore use the original package layout (for example, `01_Protocol`, `02_Source_Code`, and `03_Corpus`).

The manifest is retained as provenance for the frozen experiment. It is not a directly runnable checksum manifest for the reorganised GitHub directory tree.

The PASS/freeze text records in `reproducibility/` are likewise retained as historical validation records from the frozen experiment package.

## Large files

Large retained trace archives are intentionally not committed to normal Git history. Their long-term archive strategy will be decided before final journal submission.

## Release checklist

- [x] MATLAB source curated
- [x] Primary result data included
- [x] Sensitivity result data included
- [x] Map/corpus files included
- [x] Experiment schedules included
- [x] Original frozen-package SHA-256 manifest retained
- [ ] MATLAB/toolbox information finalised for publication
- [ ] Supporting-information package finalised
- [ ] Large trace archive strategy decided
- [ ] Code/data licence agreed by all authors
- [ ] Repository release tagged
- [ ] Persistent archive/identifier added if required for publication
