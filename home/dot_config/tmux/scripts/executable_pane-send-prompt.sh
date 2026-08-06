#!/bin/sh
# Type a canned prompt into a tmux pane and submit it — the shared body of the
# "one keystroke, one recurring instruction" bindings (prefix + . = "commit
# this"; see tmux.conf.local).
#
# Usage: pane-send-prompt.sh <pane_id> <text>
#
# The text and the Enter go in two separate writes with a beat in between. This
# matters for the intended target, Claude Code: its input box treats a burst of
# characters arriving in one read as a *paste*, so a trailing CR in the same
# chunk lands as a literal newline in the composer instead of submitting the
# turn. Sent a beat later, the CR is read as a keystroke and the prompt goes.
# Shells don't care either way, so the pane can be anything.
#
# Run from the binding with `run-shell -b` so the sleep never blocks the tmux
# server.

pane="${1:-}"
text="${2:-}"
[ -n "$pane" ] && [ -n "$text" ] || exit 0

# -l sends the argument literally (no key-name lookup), -- guards text that
# starts with a dash.
tmux send-keys -t "$pane" -l -- "$text" 2>/dev/null || exit 0
sleep 0.15
tmux send-keys -t "$pane" Enter 2>/dev/null
