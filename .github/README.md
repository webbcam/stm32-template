# stm32-template

A [Copier](https://copier.readthedocs.io/) template for STM32 firmware projects
built with CMake, vendor HAL, and host-side unit tests.

Generating from it gives you a repo that configures and builds for your chosen
board(s) out of the box, with the vendor code pinned as git submodules rather
than vendored into your tree.

> This README documents **the template** and lives in `.github/` (which GitHub
> renders as the repo landing page) so the root stays free for
> `README.md.jinja`, the README each generated project gets.

## Using it

```sh
pipx install copier          # or: uv tool install copier
copier copy gh:webbcam/stm32-template ~/Develop/projects/my-fw
cd ~/Develop/projects/my-fw
./tools/bootstrap.sh
make                         # build; `make flash` to program the board, `make help` for more
```

Copier asks for a project name, a slug, and which board(s) to target. Boards are
a multiselect — space toggles, enter confirms.

To pull later template improvements into an existing project:

```sh
cd ~/Develop/projects/my-fw
copier update
```

`copier update` also re-asks the questions, so it is how a project changes which
boards it targets. Afterwards run `./tools/bootstrap.sh --prune` to clone the new
board's submodules and drop the old family's.

### Requirements

| Tool | Needed for |
|---|---|
| `copier` | generating and updating projects |
| `cmake` ≥ 3.25 | building (presets are version 6) |
| `arm-none-eabi-gcc` | cross-compiling for the target |
| `ruby` | CMock's mock generation (host tests only) |
| `openocd` | flashing |

## Supported boards

| Selection | Board | Core | Family |
|---|---|---|---|
| `blackpill_f401` | STM32F401CCU6 | Cortex-M4F | F4 |
| `bluepill_f103` | STM32F103C8T6 | Cortex-M3 | F1 |

Selecting several is fine — each gets its own CMake preset and its own build
directory. See [`boards/README.md`](../boards/README.md) to add a board the
template doesn't know about.

## What gets generated

```
CMakeLists.txt         firmware build; BOARD selects the board
CMakePresets.json      one configure/build preset per selected board
Makefile               short commands (build, flash, test) wrapping the presets
AGENTS.md              conventions, for humans and coding agents
.clangd                points clangd at each build's compile_commands.json
boards/<name>/         everything board-specific (see boards/README.md)
cmake/                 toolchain file, compiler/warning flags
src/main.c
src/app/               board-agnostic logic — this is what gets unit tested
src/drivers/           thin HAL wrappers; the seam CMock mocks
test/                  host test project (separate CMake project, native compiler)
third_party/           pinned submodules: CMSIS core + device, HAL, Unity, CMock
tools/bootstrap.sh     submodule setup
docs/                  empty; for design notes
```

Only the selected boards' directories and submodules are generated. A project
targeting blackpill never clones the F1 HAL.

## Template internals

Three pieces are less obvious than the rest:

**`copier.yml`'s `_exclude`.** Defining `_exclude` *replaces* Copier's
`DEFAULT_EXCLUDE` instead of extending it, so the defaults are restored by hand
at the top of the list. It also excludes `third_party/**` — Copier clones the
template's submodules when the source is a URL, and without that exclusion a
generated project would receive the whole HAL as ordinary files instead of
submodules. The `boards/` entries filter unselected boards and need no editing
per board; the last entry loops over the selection. Full reasoning is in the
comments there.

**`tools/bootstrap.sh`.** A generated project has `.gitmodules` but no git
history, so it has no gitlink entries — and `git submodule update --init`
silently succeeds while cloning nothing. The script recreates gitlinks from
`sha = ...` keys recorded in `.gitmodules` (git ignores unknown keys there),
then runs a normal init/update, limited to `tools/required-submodules.txt`.

Maintainer side: after adding or bumping a submodule, run
`./tools/bootstrap.sh --pin-commits` to re-record the SHAs, and commit
`.gitmodules`.

**Split ST repos.** `third_party/` uses ST's per-component repos
(`cmsis-device-f4`, `stm32f4xx-hal-driver`, …) rather than the monolithic
`STM32CubeF4`, which is over 1 GB. A single-board project pulls ~50–70 MB.

## Working on the template

Submodules are kept deinitialized here as hygiene. Correctness doesn't depend on
it — `third_party/**` in `_exclude` is what keeps vendor source out of generated
projects — but it keeps the working tree small. Run `./tools/bootstrap.sh` if you
need them checked out.

Two things to know when testing changes:

- Copier generates from the template's **committed** state, not the working
  tree. Commit before generating, or you'll test the previous version.
- Generate with an **absolute** path (`copier copy /Users/you/…/stm32-template
  dest`), not `.`. A relative `_src_path` is recorded in the answers file and
  later re-resolved against the *project* directory, which breaks
  `copier update`.
- Verify `_exclude` and submodule changes against **both** a local path and a
  URL/`gh:` source. They behave differently: only the URL form clones
  submodules.

When tags exist, Copier defaults to the latest tag rather than HEAD. Tag a
release (`git tag v0.2.0`) when you want generated projects to pick a change up;
use `--vcs-ref HEAD` to test untagged work in progress.
