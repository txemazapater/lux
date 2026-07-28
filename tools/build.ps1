# Build the Phase 0 hello_lux example with Free Pascal.
param(
    [string]$Fpc = $env:FPC
)

$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSScriptRoot
$Out = Join-Path $Root 'bin'
$UnitOut = Join-Path $Out 'units'

New-Item -ItemType Directory -Force -Path $Out, $UnitOut | Out-Null

if (-not $Fpc) {
    $candidates = @(
        'fpc',
        'C:\lazarus\fpc\3.2.2\bin\x86_64-win64\fpc.exe',
        'C:\FPC\3.2.2\bin\i386-win32\fpc.exe'
    )
    foreach ($candidate in $candidates) {
        if ($candidate -eq 'fpc') {
            $cmd = Get-Command fpc -ErrorAction SilentlyContinue
            if ($cmd) {
                $Fpc = $cmd.Source
                break
            }
        } elseif (Test-Path $candidate) {
            $Fpc = $candidate
            break
        }
    }
}

if (-not $Fpc) {
    throw 'Free Pascal compiler (fpc) not found. Set $env:FPC to the fpc.exe path.'
}

$hello = Join-Path $Root 'examples\hello\hello_lux.pas'
$exe = Join-Path $Out 'hello_lux.exe'

& $Fpc `
  -Mobjfpc `
  -Scghi `
  -O1 `
  -g `
  -gl `
  -vewnhibq `
  "-Fu$(Join-Path $Root 'src\core')" `
  "-FU$UnitOut" `
  "-FE$Out" `
  "-o$exe" `
  $hello

if ($LASTEXITCODE -ne 0) {
    throw "fpc failed with exit code $LASTEXITCODE"
}

Write-Host "Built: $exe"
