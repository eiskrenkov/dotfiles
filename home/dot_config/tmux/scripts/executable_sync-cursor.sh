#!/bin/sh
# Keep the Cursor editor (left half of the screen) in sync with the active tmux
# session (right half). Invoked from the pop picker key bindings (prefix p/o/i)
# once the picker closes, with the now-current pane path as $1, so switching
# project via pop also flips Cursor to that project.
#
# We want the project tab to flip in Cursor while focus STAYS in the terminal —
# Ghostty should never lose focus. The `cursor` CLI can't do this: it force-
# activates Cursor and raises its window. So instead we hand the folder to
# LaunchServices with `open -g` ("open in background"). Cursor still receives
# the open-folder event and selects the matching native tab, but macOS does not
# bring it to the foreground, so the tab switches behind Ghostty.

dir="$1"
[ -n "$dir" ] && [ -d "$dir" ] || exit 0

# Prefer the git work-tree root so that cd-ing into a subdirectory still maps to
# the one project/worktree tab; fall back to the directory itself otherwise.
root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || root="$dir"
[ -n "$root" ] || root="$dir"

# -g: don't foreground Cursor. -a Cursor: route to Cursor specifically (not
# whatever is registered for the folder). This deliberately avoids the `cursor`
# CLI, which would steal focus.
open -g -a Cursor "$root"
