# The Assembler

`The Assembler` is a Windows x64 assembly roguelike prototype built with `llvm-ml64`, `lld-link`, and the Win32/GDI API. It uses a deterministic fixed-step simulation, procedural dungeon generation, fog of war, a pause-and-queue command system, and quick save/load support.

## Requirements

- Windows x64
- LLVM tools on `PATH`:
  - `llvm-ml64`
  - `lld-link`
- Windows 10/11 SDK libraries installed under `C:\Program Files (x86)\Windows Kits\10\Lib`

No `.env` file or runtime configuration is required.

## Build

```powershell
.\build.ps1
```

Build specific targets if needed:

```powershell
.\build.ps1 game
.\build.ps1 tests
```

Generated outputs:

- `build\roguelike.exe`
- `build\roguelike_tests.exe`

## Run

```powershell
.\build\roguelike.exe
```

## Test

```powershell
.\build\roguelike_tests.exe
```

## Controls

- `Space`: pause or resume
- `WASD` or arrow keys: queue movement
- `.`: queue wait
- `F`: queue a ranged attack at the nearest visible enemy
- `G`: queue pickup
- `I`: queue use first inventory item
- `X`: queue drop first inventory item
- `Backspace`: remove the most recent queued command
- `F5`: quicksave while paused
- `F9`: quickload
- `R`: start a new run

## Project Layout

- `src\`: assembly source files and shared constants
- `build.ps1`: build script for game and test binaries
- `LICENSE`: MIT license

## Notes

- Build outputs and local quicksave data are intentionally not tracked.
- The quicksave file is written to `save.dat` in the project root during play or tests.

## License

Released under the MIT License. See [LICENSE](C:/Users/Taylor/Documents/ProgrammingProjects/TheAssembler/LICENSE).
