$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Csv = Join-Path $PSScriptRoot "SHA256_Frozen_Files.csv"
if (!(Test-Path $Csv)) { throw "No frozen hash file. Run Freeze_Experiment.ps1 first." }
$Rows = Import-Csv $Csv
$Bad = @()
foreach ($R in $Rows) {
  $P = Join-Path $Root $R.RelativePath
  if (!(Test-Path $P)) { $Bad += "$($R.RelativePath) MISSING"; continue }
  $H=(Get-FileHash -Algorithm SHA256 -Path $P).Hash
  if ($H -ne $R.SHA256) { $Bad += "$($R.RelativePath) HASH_MISMATCH" }
}
if ($Bad.Count -eq 0) { Write-Host "Frozen-file verification PASS ($($Rows.Count) files)." }
else { $Bad | ForEach-Object { Write-Host $_ }; throw "Frozen-file verification FAILED." }
