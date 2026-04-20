param(
    [ValidateSet('game', 'tests', 'all')]
    [string]$Target = 'all'
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$srcDir = Join-Path $root 'src'
$buildDir = Join-Path $root 'build'
$objDir = Join-Path $buildDir 'obj'

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null
New-Item -ItemType Directory -Force -Path $objDir | Out-Null

function Resolve-ToolPath {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Names,
        [Parameter(Mandatory = $true)]
        [string[]]$FallbackPaths
    )

    foreach ($name in $Names) {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        if ($cmd) {
            return $cmd.Source
        }
    }

    foreach ($path in $FallbackPaths) {
        if ($path -and (Test-Path $path)) {
            return $path
        }
    }

    throw "Unable to locate any of: $($Names -join ', ')"
}

function Get-LatestMsvcBinDir {
    $programFilesX86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
    if (-not $programFilesX86) {
        $programFilesX86 = 'C:\Program Files (x86)'
    }
    $vswhere = Get-Command vswhere -ErrorAction SilentlyContinue
    if (-not $vswhere) {
        $vswherePath = Join-Path $programFilesX86 'Microsoft Visual Studio\Installer\vswhere.exe'
        if (Test-Path $vswherePath) {
            $vswhere = [pscustomobject]@{ Source = $vswherePath }
        }
    }

    if (-not $vswhere) {
        return $null
    }

    $installPath = & $vswhere.Source -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath 2>$null |
        Select-Object -First 1

    if (-not $installPath) {
        return $null
    }

    $msvcRoot = Join-Path $installPath 'VC\Tools\MSVC'
    if (-not (Test-Path $msvcRoot)) {
        return $null
    }

    $toolDir = Get-ChildItem -Path $msvcRoot -Directory |
        Sort-Object Name -Descending |
        Select-Object -First 1

    if (-not $toolDir) {
        return $null
    }

    $binDir = Join-Path $toolDir.FullName 'bin\Hostx64\x64'
    if (Test-Path $binDir) {
        return $binDir
    }

    return $null
}

$llvmProgramFiles = if ($env:ProgramFiles) { $env:ProgramFiles } else { 'C:\Program Files' }
$llvmBinDir = Join-Path $llvmProgramFiles 'LLVM\bin'
$msvcBinDir = Get-LatestMsvcBinDir
$assembler = Resolve-ToolPath `
    -Names @('llvm-ml64', 'llvm-ml64.exe') `
    -FallbackPaths @(
        (Join-Path $llvmBinDir 'llvm-ml64.exe'),
        $(if ($msvcBinDir) { Join-Path $msvcBinDir 'ml64.exe' })
    )
$linker = Resolve-ToolPath `
    -Names @('lld-link', 'lld-link.exe') `
    -FallbackPaths @(
        (Join-Path $llvmBinDir 'lld-link.exe'),
        $(if ($msvcBinDir) { Join-Path $msvcBinDir 'link.exe' })
    )

$sdkRoot = 'C:\Program Files (x86)\Windows Kits\10\Lib'
$umLib = Get-ChildItem $sdkRoot -Directory |
    Sort-Object Name -Descending |
    ForEach-Object { Join-Path $_.FullName 'um\x64' } |
    Where-Object { Test-Path $_ } |
    Select-Object -First 1

if (-not $umLib) {
    throw 'Unable to locate Windows SDK x64 UM libraries.'
}

$sources = @(
    'state.asm',
    'util.asm',
    'platform.asm',
    'render.asm',
    'map.asm',
    'vis.asm',
    'save.asm',
    'sim.asm',
    'main.asm',
    'tests.asm'
)

$objects = @{}

foreach ($name in $sources) {
    $srcPath = Join-Path $srcDir $name
    $objPath = Join-Path $objDir ($name -replace '\.asm$', '.obj')
    & $assembler /nologo /c /I $srcDir "/Fo$objPath" $srcPath
    $objects[$name] = $objPath
}

$common = @(
    $objects['state.asm'],
    $objects['util.asm'],
    $objects['platform.asm'],
    $objects['render.asm'],
    $objects['map.asm'],
    $objects['vis.asm'],
    $objects['save.asm'],
    $objects['sim.asm']
)

if ($Target -in @('game', 'all')) {
    $gameOut = Join-Path $buildDir 'roguelike.exe'
    & $linker /nologo `
        /subsystem:windows `
        /entry:mainCRTStartup `
        /base:0x400000 `
        /fixed `
        "/out:$gameOut" `
        "/libpath:$umLib" `
        kernel32.lib user32.lib gdi32.lib `
        @common `
        $objects['main.asm']
}

if ($Target -in @('tests', 'all')) {
    $testsOut = Join-Path $buildDir 'roguelike_tests.exe'
    & $linker /nologo `
        /subsystem:console `
        /entry:tests_mainCRTStartup `
        /base:0x400000 `
        /fixed `
        "/out:$testsOut" `
        "/libpath:$umLib" `
        kernel32.lib user32.lib gdi32.lib `
        @common `
        $objects['tests.asm']
}
