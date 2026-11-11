# Run from a Visual Studio 2022 x64 Native Tools / Developer PowerShell.
[CmdletBinding()]
param([switch]$Build)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$blocked = $false
foreach ($tool in @('git', 'cmake', 'cl')) {
    if (Get-Command $tool -ErrorAction SilentlyContinue) {
        Write-Output "PASS prerequisite: $tool"
    } else {
        Write-Output "BLOCKED prerequisite: $tool (see docs/BUILDING.md; use VS developer shell)"
        $blocked = $true
    }
}
foreach ($module in @('libultraship', 'OTRExporter', 'ZAPDTR')) {
    $marker = "$module/CMakeLists.txt"
    if ($module -eq 'ZAPDTR') { $marker = 'ZAPDTR/ZAPD/CMakeLists.txt' }
    if (Test-Path -LiteralPath (Join-Path $repo $marker)) {
        Write-Output "PASS checkout: $module"
    } else {
        Write-Output "BLOCKED checkout: $module; run git submodule update --init --recursive"
        $blocked = $true
    }
}
if ($blocked) { exit 2 }
if (-not $Build) {
    Write-Output 'NOT RUN: builds and offline unit test (pass -Build to execute). No gameplay tests ran.'
    exit 0
}

function Invoke-Checked {
    param([string]$Command, [string[]]$Arguments)
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Command failed with exit code $LASTEXITCODE" }
}

Push-Location $repo
try {
    Invoke-Checked cmake @('-S', '.', '-B', 'build/x64', '-G', 'Visual Studio 17 2022', '-T', 'v143', '-A', 'x64')
    Invoke-Checked cmake @('--build', 'build/x64', '--config', 'Release', '--target', 'soh')
    Invoke-Checked cmake @('-S', 'server', '-B', 'build/server', '-G', 'Visual Studio 17 2022', '-T', 'v143', '-A', 'x64')
    Invoke-Checked cmake @('--build', 'build/server', '--config', 'Release')
    $unitDir = Join-Path $repo 'build/baseline-unit'
    New-Item -ItemType Directory -Force -Path $unitDir | Out-Null
    Push-Location $unitDir
    try {
        Invoke-Checked cl @('/nologo', '/std:c++20', '/EHsc', '/utf-8', '/DNOMINMAX',
            "/I$repo/server/src", "$repo/tools/coop-test/unit/story_progress_test.cpp",
            "$repo/server/src/ByteStream.cpp", '/Fe:story_progress_test.exe')
        Invoke-Checked (Join-Path $unitDir 'story_progress_test.exe') @()
    } finally { Pop-Location }
    Write-Output 'PASS: client/server builds and offline story_progress_test. NOT RUN: ROM extraction, gameplay, Steam and two-PC tests.'
} finally { Pop-Location }
