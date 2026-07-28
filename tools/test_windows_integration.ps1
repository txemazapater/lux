# Optional interactive Windows console integration tests.
param(
    [string]$Fpc = $env:FPC
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'LuxFpc.ps1')

$Root = Get-LuxRoot
$ResolvedFpc = Resolve-LuxFpc -Fpc $Fpc
$exe = Join-Path $Root 'bin\lux_windows_integration_tests.exe'

Invoke-LuxFpc `
  -Fpc $ResolvedFpc `
  -Root $Root `
  -Source (Join-Path $Root 'tests\windows\lux_windows_integration_tests.pas') `
  -OutputExe $exe `
  -UnitPaths (Get-LuxWindowsUnitPaths -Root $Root)

Write-Host "Built: $exe"
& $exe
exit $LASTEXITCODE
