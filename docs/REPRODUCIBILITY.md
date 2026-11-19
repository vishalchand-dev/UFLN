# Reproducibility

## Purpose

This document records how the UFLN paper can be reproduced from the frozen code, data, and analysis scripts.

The repository is currently under coauthor review. Paths, commands, checksums, and archival links will be completed before the publication release is frozen.

## Reproduction levels

### A. Analysis reproduction

The final package should allow a researcher to start from the released primary and sensitivity result files and reproduce:

- reliability summaries and uncertainty intervals;
- successful-run quality analyses;
- deterministic timing analyses;
- sensitivity analyses;
- manuscript tables; and
- manuscript figures derived from those analyses.

Final statistical scripts will be stored in `r/`.

### B. Experiment reproduction

The final package should also document how to run the MATLAB benchmark and reproduce the experimental workflow, including:

- corpus/map loading or generation;
- the nine waypoint-generation methods;
- shared visibility, selection, safety, recovery, and control logic;
- primary evaluation schedules;
- deterministic timing schedules;
- sensitivity schedules; and
- result/trace logging.

## Frozen study environment

- Benchmark version: UFLN V2.2.1
- MATLAB: R2026a Update 4
- R: 4.6.2
- Operating system: Windows 11 Enterprise
- Hardware: Dell Pro 14 PC14250, Intel Core 7 150U, 32 GB RAM

Exact MATLAB toolbox versions and the final R `sessionInfo()` will be added before release.

## Statistical reproducibility

The final R scripts should:

- use the evaluation map as the primary independent unit;
- preserve the manuscript's stochastic-within-map reductions;
- use fixed random seeds for bootstrap and Monte Carlo procedures;
- state all resample/sign-flip counts explicitly; and
- reproduce the manuscript numbers from the released data.

## Large files

Large trace archives and other bulky outputs are intentionally not committed directly to Git. The frozen publication release will provide a persistent location and SHA-256 checksums for those files.

## Release checklist

- [ ] MATLAB source curated
- [ ] R scripts frozen
- [ ] Random seeds fixed
- [ ] R session information saved
- [ ] MATLAB/toolbox versions recorded
- [ ] Raw primary results documented
- [ ] Sensitivity results documented
- [ ] Map/corpus files documented
- [ ] Supporting-information CSV files complete
- [ ] Large trace archive location recorded
- [ ] SHA-256 manifest generated
- [ ] Code/data licence agreed by all authors
- [ ] Repository release tagged
- [ ] Persistent archive/identifier added if required for publication
