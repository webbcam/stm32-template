#!/usr/bin/env bash
#
# First-time setup for a freshly generated project.
#
# A generated project has .gitmodules but no git history, so it has no gitlink
# entries — and `git submodule update --init` silently does nothing without
# them (exits 0, clones nothing). This recreates the gitlinks from the commit
# SHAs recorded in .gitmodules, then does a normal init + update.
#
# Only the submodules listed in tools/required-submodules.txt are set up, so a
# project doesn't clone another MCU family's HAL. That file is rendered by
# Copier; when it's absent (i.e. in the template repo itself) every submodule
# in .gitmodules is used instead.
#
#   ./tools/bootstrap.sh               # set up submodules at their pinned commits
#   ./tools/bootstrap.sh --prune       # same, and remove no-longer-required ones
#   ./tools/bootstrap.sh --pin-commits # re-record SHAs after bumping a submodule
#
# --prune matters after switching boards with `copier update`: that rewrites
# required-submodules.txt but leaves the old family's submodules checked out,
# so they linger unused. Without --prune this script only warns about them.
#
set -euo pipefail

cd "$(dirname "$0")/.."

mode=setup
case "${1:-}" in
    --pin-commits) mode=pin-commits ;;
    --prune) mode=prune ;;
    "") ;;
    *)
        echo "usage: $0 [--prune|--pin-commits]" >&2
        exit 2
        ;;
esac

if [ ! -f .gitmodules ]; then
    echo "error: no .gitmodules here" >&2
    exit 1
fi

all_paths=$(git config -f .gitmodules --get-regexp '^submodule\..*\.path$' | awk '{print $2}')

if [ "$mode" = "pin-commits" ]; then
    # Maintainer mode: always covers every submodule, not just the required set.
    for path in $all_paths; do
        sha=$(git -C "$path" rev-parse HEAD)
        git config -f .gitmodules "submodule.$path.sha" "$sha"
        echo "pinned $path -> $sha"
    done
    echo "Commit .gitmodules to record the new commit SHAs."
    exit 0
fi

if [ -f tools/required-submodules.txt ]; then
    required=$(grep -v '^[[:space:]]*#' tools/required-submodules.txt | grep -v '^[[:space:]]*$')
else
    required=$all_paths
fi

[ -d .git ] || git init -q

# Anything present (gitlink in the index, or a non-empty working tree) that the
# current board no longer needs. $required is newline-separated, so collapse it
# to a space-delimited string before substring-matching against it.
# shellcheck disable=SC2086 # unquoted to collapse newlines into spaces
required_flat=" $(echo $required) "

stale=""
for path in $all_paths; do
    case "$required_flat" in
        *" $path "*) continue ;;
    esac
    if git ls-files -s "$path" 2>/dev/null | grep -q '^160000' ||
        [ -n "$(ls -A "$path" 2>/dev/null || true)" ]; then
        stale="$stale $path"
    fi
done

if [ "$mode" = "prune" ] && [ -n "$stale" ]; then
    for path in $stale; do
        echo "pruning $path"
        git submodule deinit -f "$path" >/dev/null 2>&1 || true
        git rm -q --cached "$path" >/dev/null 2>&1 ||
            git update-index --force-remove "$path" >/dev/null 2>&1 || true
        rmdir "$path" 2>/dev/null || true
    done
    stale=""
    echo
fi

for path in $required; do
    sha=$(git config -f .gitmodules --get "submodule.$path.sha" || true)
    if [ -z "$sha" ]; then
        echo "error: no commit SHA recorded for $path (run --pin-commits)" >&2
        exit 1
    fi
    # Recreate the gitlink so `git submodule update` has a commit to target.
    git update-index --add --cacheinfo "160000,$sha,$path"
done

# shellcheck disable=SC2086 # word splitting is intended here
git submodule init $required
# shellcheck disable=SC2086
git submodule update --recursive $required

echo
echo "Submodules are at their pinned commits:"
# shellcheck disable=SC2086
git submodule status $required

if [ -n "$stale" ]; then
    echo
    echo "warning: these submodules are checked out but not required by this board:"
    for path in $stale; do
        echo "  $path"
    done
    echo "They are unused — re-run with --prune to remove them."
    echo "(Their object data stays in .git/modules until you delete it.)"
fi
