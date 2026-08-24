#!/bin/sh
# Keep the GUI editor (left half of the screen) in sync with the active tmux
# session (right half). Invoked from the client-session-changed hook once pop's
# picker has switched session, with the now-current pane path as $1, so
# switching project via pop also flips the editor to that project.
#
# WHICH editor is a per-machine choice, read from $GUI_EDITOR (set in fish's
# env.fish) — the same variable the `dotfiles` alias uses. Point it at `zed`,
# `cursor`, `code`, … and this script follows; leave it unset and project
# pairing is simply off on that machine. That replaces the old .tds gate: the
# question was never "is this the work machine", it was "is there a GUI editor
# to pair with here".
#
# We want the project to flip in the editor while focus STAYS in the terminal —
# Ghostty should never lose focus. The editor CLIs can't do this: `zed` and
# `cursor` both force-activate the app and raise its window. So instead we hand
# the folder to LaunchServices with `open -g` ("open in background"). The editor
# still receives the open-folder event and selects the matching project (a
# native tab in Cursor, a workspace window in Zed), but macOS does not bring it
# to the foreground, so the switch happens behind Ghostty.

dir="$1"
[ -n "$dir" ] && [ -d "$dir" ] || exit 0

# $GUI_EDITOR normally reaches us through the tmux server's environment, which
# it inherited from the fish session that started it. A server started some
# other way — or one still running from before an env.fish change — won't have
# it, so fall back to asking fish directly (config.fish sources env.fish for
# non-interactive shells too).
editor="$GUI_EDITOR"
[ -n "$editor" ] || editor=$(fish -c 'echo -n $GUI_EDITOR' 2>/dev/null)
[ -n "$editor" ] || exit 0

# GUI_EDITOR names a CLI shim (`zed`, `cursor`, …), but `open -a` wants the app
# itself. Every editor we care about installs that shim as a symlink into its
# own .app bundle, so resolving the symlink and truncating at `.app` yields the
# bundle — no per-editor lookup table to keep in step:
#   /opt/homebrew/bin/zed    -> /Applications/Zed.app/Contents/MacOS/cli
#   /opt/homebrew/bin/cursor -> /Applications/Cursor.app/Contents/Resources/app/bin/code
bin=$(command -v "$editor" 2>/dev/null) || exit 0
[ -n "$bin" ] || exit 0
target=$(readlink -f "$bin" 2>/dev/null) || target="$bin"
case "$target" in
    *.app/*) app="${target%%.app/*}.app" ;;
    # Not a bundle shim — hand the bare name to LaunchServices and let it
    # resolve (`open -a zed` finds Zed.app; the match is case-insensitive).
    *) app=$(basename "$editor") ;;
esac

# Prefer the git work-tree root so that cd-ing into a subdirectory still maps to
# the one project/worktree tab; fall back to the directory itself otherwise.
root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || root="$dir"
[ -n "$root" ] || root="$dir"

# -g: don't foreground the editor. -a "$app": route to that editor specifically
# (not whatever is registered for the folder). This deliberately avoids the
# editor CLI, which would steal focus.
open -g -a "$app" "$root"
