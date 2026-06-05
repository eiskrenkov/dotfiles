#!/bin/sh
# Open Sublime Merge for the git repository containing the given directory.
# Invoked by tmux (prefix + M, bound to Ghostty's cmd+shift+m) with the active
# pane's current path as $1. Does nothing if the path isn't a git work tree.

dir="$1"
[ -n "$dir" ] && [ -d "$dir" ] || exit 0

root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || exit 0
[ -n "$root" ] || exit 0

if command -v smerge >/dev/null 2>&1; then
	smerge "$root"
else
	open -a "Sublime Merge" "$root"
fi
