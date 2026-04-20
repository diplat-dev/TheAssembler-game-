# The Assembler

`The Assembler` is a Windows x64 assembly roguelike prototype built with `llvm-ml64`, `lld-link`, and the Win32/GDI API. It uses a deterministic fixed-step simulation, procedural dungeon generation, fog of war, a pause-and-queue command system, quick save/load support, and a simple title/help flow for onboarding.

## Requirements

- Windows x64
- One of:
  - LLVM tools available on `PATH` or under `C:\Program Files\LLVM\bin`
  - Visual Studio with the x64 C++ build tools installed
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

The game now opens on a title screen. Start a fresh run with `Enter` or `Space`, open help with `H`, load the quicksave with `F9`, or quit with `Esc`/`Q`.

## Test

```powershell
.\build\roguelike_tests.exe
```

## Controls

- `Space`: run the queued commands, or pause a run in progress
- `WASD` or arrow keys: queue movement while paused
- `.`: queue wait while paused
- `F`: queue a ranged attack at the nearest visible enemy while paused
- `G`: queue pickup while paused
- `I`: queue use first inventory item while paused
- `X`: queue drop first inventory item while paused
- `Backspace`: remove the most recent queued command
- `F5`: quicksave while paused
- `F9`: quickload
- `R`: reroll a run
- `H`: open or close the help screen
- `Esc`: return to the title screen from a run

Queued commands now execute as a batch. The game automatically pauses again when the queue is empty and the player is ready for the next decision. If the player dies, the game switches to a death screen where `Enter`, `Space`, or `R` starts a new run, `F9` loads the quicksave, and `Esc` returns to the title screen.

## Current Prototype Notes

- Slimes and heavier brutes both spawn in generated dungeons.
- Potions restore health immediately.
- Tonics apply a short regeneration effect.

## Project Layout

- `src\`: assembly source files and shared constants
- `build.ps1`: build script for game and test binaries
- `LICENSE`: MIT license

## Notes

- Build outputs and local quicksave data are intentionally not tracked.
- The quicksave file is written to `save.dat` in the project root during play or tests.

## License

Released under the MIT License. See [LICENSE](C:/Users/Taylor/Documents/ProgrammingProjects/TheAssembler/LICENSE).
