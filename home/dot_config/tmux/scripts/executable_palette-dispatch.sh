#!/bin/sh
# Run the feature chosen in the command_palette fzf modal.
#
# The `prefix + P` binding starts this in the background *before* it opens the
# palette popup (`run-shell -b … \; display-popup …`). We then wait for the
# palette (command_palette.fish) to record the user's choice, let the popup
# finish closing, and run it. This dance is deliberate:
#
#   * tmux runs commands chained after `display-popup` immediately — NOT when
#     the popup closes — so dispatching inline from the binding would fire
#     before anything had been picked. Polling for the choice file sidesteps
#     that entirely, however tmux schedules us.
#   * tmux popups can't nest (verified on 3.6b). Interactive pickers/TUIs (gco,
#     ports, kc, pop pickers, lazygit) therefore can't run while our popup is up,
#     so the `popup` type opens them in a FRESH popup only after ours has closed
#     — which replaces the palette popup with the feature's own, independently of
#     whatever occupies the active pane (a shell, Claude Code, vim, …). Hence the
#     settle delay before dispatching.
#
# For `script`/`func` actions this runs the exact same code the matching keybind
# runs (e.g. `func` calls the open-in-sublime-merge fish function that prefix+M
# also calls), so the palette and the keybinding can never drift apart.

# $1 is the launching pane id. run-shell DOES format-expand its command, so this
# is the real pane (e.g. %133) — used by the pane/prompt cases below to send keys
# to the right place.
pane="$1"
path="$2"
dir="$HOME/.cache/tmux-command-palette"
# Fixed rendezvous names (not pane-scoped): display-popup does not format-expand
# its arguments, so it can't hand the pane id to the palette running inside it.
# Both sides therefore agree on these constant paths. See command_palette.fish.
choice="$dir/choice"
cancel="$dir/cancel"
mkdir -p "$dir"

# Fresh start. This runs at popup-open time — long before any selection — so it
# can never clobber a real choice.
rm -f "$choice" "$cancel"

# Wait (up to ~5 min of browsing) for the palette to record an outcome.
i=0
while [ "$i" -lt 3000 ]; do
	[ -f "$choice" ] && break
	[ -f "$cancel" ] && { rm -f "$cancel"; exit 0; }
	sleep 0.1
	i=$((i + 1))
done
[ -f "$choice" ] || exit 0

# Let the palette popup finish tearing down before we touch the pane, so an
# interactive tool's own popup doesn't collide with ours.
sleep 0.3

type=$(sed -n 1p "$choice")
cmd=$(sed -n 2p "$choice")
rm -f "$choice" "$cancel"
[ -n "$type" ] && [ -n "$cmd" ] || exit 0

case "$type" in
	script)
		# same code path as the feature's keybind: <script> <pane path>
		"$cmd" "$path"
		;;
	func)
		# same code path as the feature's keybind: call the fish function with
		# the pane path (autoloaded from ~/.config/fish/functions)
		fish -c "$cmd \$argv[1]" "$path"
		;;
	popup)
		# Replace the (now-closed) palette popup with the feature's own popup, so
		# interactive pickers/TUIs run independently of whatever occupies the
		# active pane. Started in the pane's dir; run via fish so our functions
		# resolve. CMD_PALETTE_POPUP tells popup-aware pickers (gco, ports) to use
		# plain fzf instead of `fzf --tmux`, which would try to nest a 2nd popup.
		tmux display-popup -E -d "$path" -w 80% -h 70% -e CMD_PALETTE_POPUP=1 "fish -c '$cmd'"
		;;
	pane)
		# run it in the active pane, exactly as if typed there
		tmux send-keys -t "$pane" -- "$cmd" Enter
		;;
	prompt)
		# drop it on the prompt for the user to finish (needs an argument)
		tmux send-keys -t "$pane" -- "$cmd"
		;;
esac
