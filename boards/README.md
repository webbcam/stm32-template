# Adding a new board

A board folder contains exactly three things: an MCU identity (`board.cmake`),
a target that builds them (`CMakeLists.txt`), and a linker script. Startup
assembly is **not** hand-written — it ships in the CMSIS-device submodule for
the family and is referenced by path.

## Steps

1. **Identify the family and exact part.** e.g. bluepill = STM32F103C8T6, family F1.

2. **Add the family's submodules, if not already present.**
   ST splits CMSIS-device and HAL per family. For F1 that's
   `cmsis-device-f1` and `stm32f1xx-hal-driver` (same GitHub org/pattern as
   the F4 ones already vendored — see `.gitmodules`). `cmsis-core` is shared
   across every family and doesn't need re-adding.

   After `git submodule add`, record the pin so generated projects can
   reproduce it:

   ```sh
   ./tools/bootstrap.sh --write-pins   # writes `sha = ...` into .gitmodules
   ```

   The same command re-pins after bumping an existing submodule (it reads each
   submodule's checked-out HEAD, so they must be initialized when you run it).
   Commit `.gitmodules` afterwards — those `sha` entries are what
   `tools/bootstrap.sh` restores in a freshly generated project.

   Submodules are kept deinitialized here as hygiene, but correctness does not
   depend on it: `third_party/**` in `copier.yml`'s `_exclude` is what keeps
   vendor source out of generated projects, and that holds whether or not the
   submodules happen to be checked out. Don't remove that exclusion — Copier
   clones submodules when generating from a URL, so without it a published
   template ships the HAL as plain files instead of pinned submodules.

3. **Wire the new family into `third_party/CMakeLists.txt`.**
   Duplicate the `cmsis-device-f4`/`hal` block for the new family (e.g.
   `cmsis-device-f1`, and a `hal` build using `stm32f1xx-hal-driver/Src`).
   If more than one family is ever active at once, rename the targets
   (`hal-f4`, `hal-f1`) so `src/CMakeLists.txt` can pick the right one per board.

4. **Create `boards/<name>/`** with:
   - `board.cmake` — sets `MCU_DEFINE` (e.g. `STM32F103xB`), `LINKER_SCRIPT`,
     and `STARTUP_SOURCE` (path into the CMSIS-device submodule's
     `Source/Templates/gcc/startup_<device>.s` — check that exact filename
     exists in the submodule for your part before pointing at it).
   - `CMakeLists.txt` — same three lines as `boards/blackpill_f401/CMakeLists.txt`,
     unchanged; it just consumes the variables from `board.cmake`.
   - `<PART>_FLASH.ld` — a GCC linker script. ST doesn't publish these
     standalone; pull one from an STM32CubeIDE-generated project for the
     part, or adapt `boards/blackpill_f401/STM32F401CCUX_FLASH.ld` by
     updating the `MEMORY` block's `FLASH`/`RAM` origin and length for the
     new part's datasheet values.

5. **Add a configure/build preset pair** for the new board name in
   `CMakePresets.json`.

6. **Set the board's clock tree.** `system_stm32<family>xx.c` (from the
   CMSIS-device submodule) only does minimal CMSIS-level init — actual
   `SystemClock_Config()` (HSE frequency, PLL multipliers) is board-specific
   and belongs in the application, not in a vendored file. Write it based on
   the new board's crystal frequency.

Once there's a second board, promote the repeated `third_party` family block
and the repeated board CMake boilerplate into something less copy-pasted —
not before, since one instance isn't a pattern yet.
