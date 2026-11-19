# Calibration

V2.2 uses a two-stage pre-specified calibration to reduce laptop time without using evaluation-map results.

1. `Paper1_V22_run_calibration("screen")`
2. `Paper1_V22_select_calibration_finalists`
3. Review the screening summary/finalist JSON.
4. `Paper1_V22_run_calibration("confirm")`
5. `Paper1_V22_select_calibration`

All records are stored in one resumable `Calibration_Raw.csv`. Confirmation reuses screening records that already belong to the final confirmation design.

Do not place V2.1 calibration data in this folder.
