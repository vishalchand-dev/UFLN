# Released result data

This directory contains the curated result tables released with the UFLN benchmark manuscript.

## Primary evaluation

`primary/Results_Raw.csv`

The file contains 18,270 records:

- 13,860 `MAIN/PATH` records used for the primary planner evaluation;
- 3,600 `MAIN/TIMING` records from the dedicated deterministic timing experiment; and
- 810 `DIAGNOSTIC/PATH` records retained as diagnostic cases and excluded from the primary inferential evaluation.

## Sensitivity evaluation

`sensitivity/Sensitivity_Raw.csv`

The file contains 7,776 `SENSITIVITY/PATH` records across eight conditions, with 972 records per condition.

## Notes

Large retained trace files are not committed to normal Git history.

The CSV files in this repository are frozen scientific records and should not be edited manually.

Field definitions are provided in `../docs/DATA_DICTIONARY.md`.
