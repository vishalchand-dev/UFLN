# Reproducibility

## Purpose

This document records the materials provided with the UFLN benchmark and paper-facing repository.

The repository is currently under coauthor review. Paths, commands, checksums, and archival links will be completed before the publication release is frozen.

## Experiment reproduction

The publication-facing repository is intended to document how to run the MATLAB benchmark and reproduce the frozen experimental workflow, including:

- corpus/map loading or generation;
- the nine waypoint-generation methods;
- shared visibility, selection, safety, recovery, and control logic;
- primary evaluation schedules;
- deterministic timing schedules;
- sensitivity schedules; and
- result/trace logging.

## Released result data

The repository may include curated primary and sensitivity result tables required to inspect the reported outcomes. Large trace collections are kept outside normal Git history.

Statistical-analysis source scripts are **not included in this GitHub repository**. The manuscript records the statistical procedures and software environment used for the reported analyses.

## Frozen study environment

- Benchmark version: UFLN V2.2.1
- MATLAB: R2026a Update 4
- R: 4.6.2
- Operating system: Windows 11 Enterprise
- Hardware: Dell Pro 14 PC14250, Intel Core 7 150U, 32 GB RAM

Exact MATLAB toolbox information will be added before release.

## Integrity and provenance

The final release will retain the frozen experiment configuration, validation records, schedules, and SHA-256 integrity information needed to identify the code/data corresponding to the manuscript.

## Large files

Large trace archives and other bulky outputs are intentionally not committed directly to Git. Their publication/archive strategy will be decided before final journal submission.

## Release checklist

- [ ] MATLAB source curated
- [ ] MATLAB/toolbox versions recorded
- [ ] Raw primary results documented
- [ ] Sensitivity results documented
- [ ] Map/corpus files documented
- [ ] Supporting-information data complete
- [ ] Large trace archive strategy decided
- [ ] SHA-256 manifest generated
- [ ] Code/data licence agreed by all authors
- [ ] Repository release tagged
- [ ] Persistent archive/identifier added if required for publication
