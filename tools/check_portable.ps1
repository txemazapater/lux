# Fail if portable units reference Win32/Unix console APIs.
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$paths = @(
    (Join-Path $Root 'src\core'),
    (Join-Path $Root 'src\rendering'),
    (Join-Path $Root 'src\terminal'),
    (Join-Path $Root 'src\events'),
    (Join-Path $Root 'src\app'),
    (Join-Path $Root 'src\controls'),
    (Join-Path $Root 'src\layouts')
)
$pattern = 'uses\s+Windows\b|Windows\.|GetConsoleMode|SetConsoleMode|termios|kernel32'
$failed = $false

foreach ($dir in $paths) {
    Get-ChildItem -Path $dir -Filter *.pas -Recurse | ForEach-Object {
        $text = Get-Content -LiteralPath $_.FullName -Raw
        if ($text -match $pattern) {
            Write-Host "PORTABLE VIOLATION: $($_.FullName)"
            $failed = $true
        }
    }
}

if ($failed) {
    throw 'Portable units contain platform console dependencies.'
}

Write-Host 'Portable isolation check passed.'
