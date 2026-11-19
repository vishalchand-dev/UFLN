$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Selected = Join-Path $Root "04_Calibration\Selected_Planner_Params.json"
$Quick = Join-Path $PSScriptRoot "QUICK_VALIDATION_PASS.txt"
$Deep = Join-Path $PSScriptRoot "DEEP_VALIDATION_PASS.txt"
$Env = Join-Path $PSScriptRoot "Environment_Captured.txt"
if (!(Test-Path $Selected)) { throw "Calibration selection missing: 04_Calibration\Selected_Planner_Params.json" }
if (!(Test-Path $Quick)) { throw "Quick validation PASS flag missing." }
if (!(Test-Path $Deep)) { throw "Deep validation PASS flag missing." }
if (!(Test-Path $Env)) { throw "Environment capture missing." }
$Out = Join-Path $PSScriptRoot "SHA256_Frozen_Files.csv"
$Targets = @(
  (Join-Path $Root "00_START_HERE.txt"),
  (Join-Path $Root "VERSION.txt"),
  (Join-Path $Root "01_Protocol"),
  (Join-Path $Root "02_Source_Code"),
  (Join-Path $Root "03_Corpus"),
  (Join-Path $Root "04_Calibration"),
  (Join-Path $Root "05_Schedules")
)
$Files = foreach ($T in $Targets) {
  if ((Get-Item $T) -is [System.IO.DirectoryInfo]) { Get-ChildItem -Path $T -Recurse -File }
  else { Get-Item $T }
}
$Rows = foreach ($F in $Files) {
  $H = Get-FileHash -Algorithm SHA256 -Path $F.FullName
  [PSCustomObject]@{ RelativePath = $F.FullName.Substring($Root.Length+1); SHA256 = $H.Hash }
}
$Rows | Sort-Object RelativePath | Export-Csv -NoTypeInformation -Path $Out
"Freeze time: $(Get-Date -Format o)" | Set-Content (Join-Path $PSScriptRoot "FREEZE_CONFIRMED.txt")
"Files hashed: $($Rows.Count)" | Add-Content (Join-Path $PSScriptRoot "FREEZE_CONFIRMED.txt")
"UFLN V2.2 scientific inputs frozen." | Add-Content (Join-Path $PSScriptRoot "FREEZE_CONFIRMED.txt")
Write-Host "Freeze complete. Files hashed: $($Rows.Count)"
