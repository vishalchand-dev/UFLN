# UFLN

**Unified Field-of-View-based Landmark Navigation (UFLN)**

This repository supports the manuscript:

> **UFLN: A Controlled Landmark-Visibility Benchmark for Robot Navigation**

Authors: Vishal Raveekesh Chand, Kaylash Chaudhary, Avinesh Prasad, Sandeep Ameet Kumar, and Bibhya Sharma.

## Status

**Work in progress — coauthor review repository.**

The repository is being curated for reproducible release. It should not yet be treated as the final archival version of the paper, code, or data.

The frozen experiment discussed in the current manuscript is **UFLN V2.2.1** unless a file states otherwise.

## What UFLN evaluates

UFLN is a controlled closed-loop landmark-navigation benchmark. Landmark visibility, landmark selection, scan recovery, execution safety, motion control, metrics, and evaluation rules are shared across methods. The intentionally varied component is local waypoint generation.

The current study evaluates nine waypoint-generation methods:

- GREEDY
- DVWP
- Dijkstra
- A*
- ACO
- BA
- FA
- SAFA
- RRT

## Repository layout

- `matlab/` — benchmark and experiment code
- `analysis/` — publication-facing R statistical-analysis scripts
- `protocol/` — frozen benchmark protocol material
- `corpus/` — evaluation/corpus definitions
- `calibration/` — calibration records
- `schedules/` — experiment schedules
- `data/` — curated result data and documentation
- `reproducibility/` — environment, freeze, validation, and integrity records
- `examples/` — selected illustrative material

## Reproducibility

The publication-facing repository is intended to provide:

1. the frozen benchmark implementation;
2. experiment configuration and schedules;
3. map/corpus information;
4. primary and sensitivity result data;
5. protocol and reproducibility records; and
6. integrity/checksum information for the frozen experiment.

Publication-facing statistical-analysis scripts are provided in `analysis/`. Exploratory/private analysis workspaces remain excluded.

Large trace archives and other bulky outputs are not stored directly in normal Git history.

See [docs/REPRODUCIBILITY.md](docs/REPRODUCIBILITY.md).

## Software environment

Current manuscript environment:

- MATLAB R2026a Update 4
- R 4.6.2
- Windows 11 Enterprise

Exact MATLAB toolbox information will be frozen with the final release.

## Citation

Citation metadata are provided in `CITATION.cff`. A permanent archival identifier may be added when the publication release is frozen.

## Licence

A repository licence has **not yet been selected**. The authors will agree the code/data licensing terms before the public publication release.
