# Adding a new board

Everything board-specific lives in one directory. `boards/bluepill_f103/` was
added as the second board and is the worked example to copy — diff it against
`boards/blackpill_f401/` to see exactly what varies between families.

A board directory contains:

| File | Purpose |
|---|---|
| `board.cmake` | Variables only: `MCU_FAMILY`, `MCU_DEFINE`, `CPU_FLAGS`, `LINKER_SCRIPT`, `HAL_CONF_DIR`, `STARTUP_SOURCE` |
| `CMakeLists.txt` | Builds the `board` target from the startup file + `board.c` |
| `board.c` / `board.h` | `board_init()` — the clock tree |
| `mcu.h` | Includes this family's `stm32<family>xx_hal.h` |
| `stm32<family>xx_hal_conf.h` | Which HAL modules are compiled, `HSE_VALUE` |
| `<PART>_FLASH.ld` | Linker script (flash/RAM sizes) |

Startup assembly is **not** hand-written — it ships in the CMSIS-device
submodule for the family and is referenced by path.

## Steps

1. **Identify the family and exact part.** e.g. bluepill = STM32F103C8T6,
   family F1, Cortex-M3.

2. **Add the family's submodules, if the family is new.** ST splits
   CMSIS-device and HAL per family, following a consistent naming pattern
   (`cmsis-device-f1`, `stm32f1xx-hal-driver`) — see `.gitmodules`.
   `cmsis-core` is shared by every family and doesn't need re-adding.

   After `git submodule add`, record its commit so generated projects can
   reproduce it:

   ```sh
   ./tools/bootstrap.sh --pin-commits   # writes `sha = ...` into .gitmodules
   ```

   The same command re-records after bumping an existing submodule (it reads
   each submodule's checked-out HEAD, so they must be initialized when you run
   it). Commit `.gitmodules` afterwards — those `sha` entries are what
   `tools/bootstrap.sh` restores in a freshly generated project.

   Submodules are kept deinitialized here as hygiene, but correctness does not
   depend on it: `third_party/**` in `copier.yml`'s `_exclude` is what keeps
   vendor source out of generated projects, and that holds whether or not the
   submodules happen to be checked out. Don't remove that exclusion — Copier
   clones submodules when generating from a URL, so without it a published
   template ships the HAL as plain files instead of pinned submodules.

3. **Teach `third_party/CMakeLists.txt` about the family** by adding a branch
   to the `if(MCU_FAMILY ...)` block naming its device dir, system source, and
   HAL dir. The targets it produces (`cmsis-device`, `hal`) are deliberately
   family-neutral, so nothing downstream changes.

4. **Create `boards/<name>/`** with the files in the table above. The pieces
   most easily got wrong:

   - `CPU_FLAGS` must match the core. Cortex-M4F is
     `-mcpu=cortex-m4 -mfpu=fpv4-sp-d16 -mfloat-abi=hard`; Cortex-M3 has no
     FPU and needs `-mcpu=cortex-m3 -mfloat-abi=soft`. Getting this wrong
     produces link errors or silently wrong float behaviour, so verify with
     `arm-none-eabi-readelf -A <elf>` — it should report the core and FP arch
     you expect.
   - `STARTUP_SOURCE` must name a file that actually exists under the
     submodule's `Source/Templates/gcc/`; check before pointing at it.
   - The linker script's `MEMORY` block must match the part's real flash/RAM
     (bluepill C8T6 is 64K/20K; blackpill F401CC is 256K/64K). Adapt an
     existing one rather than starting from scratch.
   - `board.c` is where the clock tree goes. Don't try to share it across
     families — F1 uses `HSEPredivValue` + `PLLMUL`, F4 uses
     `PLLM/PLLN/PLLP/PLLQ`.

5. **Register it in `copier.yml`**, in two places:

   - a `choices` entry under the `boards` question,
   - a `board_meta` entry giving its `family`, `label` and `openocd` target.

   That's the whole registration. Nothing else needs editing per board:

   - `_exclude` ends with a loop over the selected boards emitting one
     `!boards/<name>` negation each, so it already covers any board.
   - `CMakePresets.json.jinja` loops over the selected boards and takes the
     display name and OpenOCD target (for the `flash` target) from `board_meta`.
   - `Makefile.jinja` takes its list of valid `BOARD` values from `boards`.
   - `tools/required-submodules.txt.jinja` maps `board_meta`'s family to its
     submodules using ST's consistent repo naming (`cmsis-device-<family>`,
     `stm32<family>xx-hal-driver`).
   - `README.md.jinja` and `AGENTS.md.jinja` read the label and OpenOCD
     target from `board_meta`.
