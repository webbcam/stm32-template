#!/usr/bin/env bash
#
# First-time setup for a freshly generated project.
#
# A generated project has .gitmodules but no git history, so it has no gitlink
# entries — and `git submodule update --init` silently does nothing without
# them (exits 0, clones nothing). This recreates the gitlinks from the `sha`
# pins recorded in .gitmodules, then does a normal init + update.
#
# Only the submodules listed in tools/required-submodules.txt are set up, so a
# project doesn't clone another MCU family's HAL. That file is rendered by
# Copier; when it's absent (i.e. in the template repo itself) every submodule
# in .gitmodules is used instead.
#
#   ./tools/bootstrap.sh              # set up submodules at their pinned commits
#   ./tools/bootstrap.sh --write-pins # re-record pins after bumping a submodule
#
set -euo pipefail

cd "$(dirname "$0")/.."

if [ ! -f .gitmodules ]; then
    echo "error: no .gitmodules here" >&2
    exit 1
fi

all_paths=$(git config -f .gitmodules --get-regexp '^submodule\..*\.path$' | awk '{print $2}')

if [ "${1:-}" = "--write-pins" ]; then
    # Maintainer mode: always covers every submodule, not just the required set.
    for path in $all_paths; do
        sha=$(git -C "$path" rev-parse HEAD)
        git config -f .gitmodules "submodule.$path.sha" "$sha"
        echo "pinned $path -> $sha"
    done
    echo "Commit .gitmodules to record the new pins."
    exit 0
fi

if [ -f tools/required-submodules.txt ]; then
    paths=$(grep -v '^[[:space:]]*#' tools/required-submodules.txt | grep -v '^[[:space:]]*$')
else
    paths=$all_paths
fi

[ -d .git ] || git init -q

for path in $paths; do
    sha=$(git config -f .gitmodules --get "submodule.$path.sha" || true)
    if [ -z "$sha" ]; then
        echo "error: no pin recorded for $path (run --write-pins)" >&2
        exit 1
    fi
    # Recreate the gitlink so `git submodule update` has a commit to target.
    git update-index --add --cacheinfo "160000,$sha,$path"
done

# shellcheck disable=SC2086 # word splitting is intended here
git submodule init $paths
git submodule update --recursive $paths

echo
echo "Submodules are at their pinned commits:"
git submodule status $paths
