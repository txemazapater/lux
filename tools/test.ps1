# Build and run portable LUX tests on Windows.
param(
    [string]$Fpc = $env:FPC
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'LuxFpc.ps1')

$Root = Get-LuxRoot
& (Join-Path $PSScriptRoot 'check_portable.ps1')
& (Join-Path $PSScriptRoot 'build.ps1') -Target tests -Fpc $Fpc

$exe = Join-Path $Root 'bin\lux_tests.exe'
& $exe
exit $LASTEXITCODE
