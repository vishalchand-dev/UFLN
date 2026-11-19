# Reproducibility records

This directory contains historical validation and freeze records from the frozen UFLN V2.2.1 experiment package.

## Included records

- `Environment_Captured.txt` — captured software/hardware environment information.
- `QUICK_VALIDATION_PASS.txt` — quick validation pass record.
- `DEEP_VALIDATION_PASS.txt` — deep validation pass record.
- `STATIC_PACKAGE_CHECK.txt` — static package check record.
- `FREEZE_CONFIRMED.txt` — original freeze confirmation.
- `SHA256_Frozen_Files.csv` — SHA-256 manifest generated from the original frozen package layout.

## Important path note

The hash manifest predates the GitHub-facing folder reorganisation. Its paths refer to the original internal package layout, such as `01_Protocol`, `02_Source_Code`, `03_Corpus`, `04_Calibration`, and `05_Schedules`.

For that reason, the manifest is retained as a provenance record rather than as a directly runnable verification manifest for the reorganised GitHub tree.

The original local freeze/verification PowerShell scripts are intentionally not published here because they target that earlier directory layout and would not run correctly against this repository structure.
