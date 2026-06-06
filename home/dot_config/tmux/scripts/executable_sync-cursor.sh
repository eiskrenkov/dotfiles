#!/bin/sh
# Keep the Cursor editor (left half of the screen) in sync with the active tmux
# session (right half). Invoked from the pop picker key bindings (prefix p/o/i)
# once the picker closes, with the now-current pane path as $1, so switching
# project via pop also flips Cursor to that project.
#
# With native tabs enabled, `cursor <dir>` focuses the existing tab for that
# folder (or opens a new one), which is exactly the "switch tab" behaviour we
# want.

dir="$1"
[ -n "$dir" ] && [ -d "$dir" ] || exit 0

# Prefer the git work-tree root so that cd-ing into a subdirectory still maps to
# the one project/worktree tab; fall back to the directory itself otherwise.
root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || root="$dir"
[ -n "$root" ] || root="$dir"

if command -v cursor >/dev/null 2>&1; then
	cursor "$root"
else
	open -a Cursor "$root"
fi
