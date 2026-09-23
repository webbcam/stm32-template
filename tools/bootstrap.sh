#!/usr/bin/env bash
#
# First-time setup for a freshly generated project.
#
# A generated project has .gitmodules but no git history, so it has no gitlink
# entries — and `git submodule update --init` silently does nothing without
# them (exits 0, clones nothing). This recreates the gitlinks from the `sha`
# pins recorded in .gitmodules, then does a normal init + update.
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

paths=$(git config -f .gitmodules --get-regexp '^submodule\..*\.path$' | awk '{print $2}')

if [ "${1:-}" = "--write-pins" ]; then
    for path in $paths; do
        sha=$(git -C "$path" rev-parse HEAD)
        git config -f .gitmodules "submodule.$path.sha" "$sha"
        echo "pinned $path -> $sha"
    done
    echo "Commit .gitmodules to record the new pins."
    exit 0
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

git submodule init
git submodule update --recursive

echo
echo "Submodules are at their pinned commits:"
git submodule status
