# Build LUX targets with Free Pascal (Windows host).
param(
    [ValidateSet('hello', 'tests', 'windows-demo', 'windows-tests', 'eventloop', 'controls-demo', 'input-inspector', 'all')]
    [string]$Target = 'hello',
    [string]$Fpc = $env:FPC
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'LuxFpc.ps1')

$Root = Get-LuxRoot
$ResolvedFpc = Resolve-LuxFpc -Fpc $Fpc
$portable = Get-LuxPortableUnitPaths -Root $Root
$windows = Get-LuxWindowsUnitPaths -Root $Root

function Build-One([string]$Source, [string]$ExeName, [string[]]$Paths) {
    $exe = Join-Path $Root "bin\$ExeName"
    Invoke-LuxFpc -Fpc $ResolvedFpc -Root $Root -Source $Source -OutputExe $exe -UnitPaths $Paths
    Write-Host "Built: $exe"
}

switch ($Target) {
    'hello' {
        Build-One (Join-Path $Root 'examples\hello\hello_lux.pas') 'hello_lux.exe' $portable
    }
    'tests' {
        Build-One (Join-Path $Root 'tests\lux_tests.pas') 'lux_tests.exe' $portable
    }
    'windows-demo' {
        Build-One (Join-Path $Root 'examples\windows_demo\windows_demo.pas') 'windows_demo.exe' $windows
    }
    'windows-tests' {
        Build-One (Join-Path $Root 'tests\windows\lux_windows_tests.pas') 'lux_windows_tests.exe' $windows
    }
    'eventloop' {
        Build-One (Join-Path $Root 'examples\eventloop\eventloop_windows.pas') 'eventloop_windows.exe' $windows
    }
    'controls-demo' {
        Build-One (Join-Path $Root 'examples\controls_demo\controls_demo_windows.pas') 'controls_demo_windows.exe' $windows
    }
    'input-inspector' {
        Build-One (Join-Path $Root 'examples\input_inspector\input_inspector_windows.pas') 'input_inspector_windows.exe' $windows
    }
    'all' {
        Build-One (Join-Path $Root 'examples\hello\hello_lux.pas') 'hello_lux.exe' $portable
        Build-One (Join-Path $Root 'tests\lux_tests.pas') 'lux_tests.exe' $portable
        Build-One (Join-Path $Root 'examples\windows_demo\windows_demo.pas') 'windows_demo.exe' $windows
        Build-One (Join-Path $Root 'tests\windows\lux_windows_tests.pas') 'lux_windows_tests.exe' $windows
        Build-One (Join-Path $Root 'examples\eventloop\eventloop_windows.pas') 'eventloop_windows.exe' $windows
        Build-One (Join-Path $Root 'examples\controls_demo\controls_demo_windows.pas') 'controls_demo_windows.exe' $windows
        Build-One (Join-Path $Root 'examples\input_inspector\input_inspector_windows.pas') 'input_inspector_windows.exe' $windows
    }
}
