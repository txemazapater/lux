# Build and run the LUX portable test suite.
param(
    [string]$Fpc = $env:FPC
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'LuxFpc.ps1')

$Root = Get-LuxRoot
$ResolvedFpc = Resolve-LuxFpc -Fpc $Fpc
$exe = Join-Path $Root 'bin\lux_tests.exe'

Invoke-LuxFpc `
  -Fpc $ResolvedFpc `
  -Root $Root `
  -Source (Join-Path $Root 'tests\lux_tests.pas') `
  -OutputExe $exe

Write-Host "Built: $exe"
& $exe
exit $LASTEXITCODE
