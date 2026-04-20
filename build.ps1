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
    & llvm-ml64 /nologo /c /I $srcDir "/Fo$objPath" $srcPath
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
    & lld-link /nologo `
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
    & lld-link /nologo `
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
