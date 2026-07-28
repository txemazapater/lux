# Build and run Windows platform unit tests (no interactive console required).
param(
    [string]$Fpc = $env:FPC
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'LuxFpc.ps1')

$Root = Get-LuxRoot
& (Join-Path $PSScriptRoot 'build.ps1') -Target windows-tests -Fpc $Fpc
$exe = Join-Path $Root 'bin\lux_windows_tests.exe'
& $exe
exit $LASTEXITCODE
