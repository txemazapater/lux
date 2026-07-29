# Shared Free Pascal discovery and common switches for LUX scripts.
function Get-LuxRoot {
    Split-Path -Parent $PSScriptRoot
}

function Resolve-LuxFpc {
    param([string]$Fpc = $env:FPC)

    if ($Fpc) {
        return $Fpc
    }

    $candidates = @(
        'fpc',
        'C:\lazarus\fpc\3.2.2\bin\x86_64-win64\fpc.exe',
        'C:\FPC\3.2.2\bin\x86_64-win64\fpc.exe',
        'C:\FPC\3.2.2\bin\i386-win32\fpc.exe'
    )
    foreach ($candidate in $candidates) {
        if ($candidate -eq 'fpc') {
            $cmd = Get-Command fpc -ErrorAction SilentlyContinue
            if ($cmd) {
                return $cmd.Source
            }
        } elseif (Test-Path $candidate) {
            return $candidate
        }
    }

    throw 'Free Pascal compiler (fpc) not found. Set $env:FPC to the fpc.exe path.'
}

function Get-LuxPortableUnitPaths {
    param([string]$Root)
    @(
        (Join-Path $Root 'src\core'),
        (Join-Path $Root 'src\terminal'),
        (Join-Path $Root 'src\rendering'),
        (Join-Path $Root 'src\events'),
        (Join-Path $Root 'src\app'),
        (Join-Path $Root 'src\controls'),
        (Join-Path $Root 'src\layouts'),
        (Join-Path $Root 'tests')
    )
}

function Get-LuxWindowsUnitPaths {
    param([string]$Root)
    (Get-LuxPortableUnitPaths -Root $Root) + @(
        (Join-Path $Root 'src\platform\windows'),
        (Join-Path $Root 'examples\eventloop'),
        (Join-Path $Root 'examples\controls_demo'),
        (Join-Path $Root 'examples\stack_demo'),
        (Join-Path $Root 'examples\cursor_demo'),
        (Join-Path $Root 'examples\split_demo'),
        (Join-Path $Root 'examples\input_inspector')
    )
}

function Invoke-LuxFpc {
    param(
        [Parameter(Mandatory = $true)][string]$Fpc,
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$OutputExe,
        [string[]]$UnitPaths
    )

    $Out = Join-Path $Root 'bin'
    $UnitOut = Join-Path $Out 'units'
    New-Item -ItemType Directory -Force -Path $Out, $UnitOut | Out-Null

    $unitArgs = @()
    foreach ($path in $UnitPaths) {
        $unitArgs += "-Fu$path"
    }

    & $Fpc `
      -Mobjfpc `
      -Scghi `
      -O1 `
      -g `
      -gl `
      -vewnhibq `
      @unitArgs `
      "-FU$UnitOut" `
      "-FE$Out" `
      "-o$OutputExe" `
      $Source

    if ($LASTEXITCODE -ne 0) {
        throw "fpc failed with exit code $LASTEXITCODE"
    }
}
