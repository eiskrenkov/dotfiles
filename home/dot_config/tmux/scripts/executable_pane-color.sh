#!/usr/bin/env bash
# Assign a random label colour to a tmux pane, read by pane-border-format in
# tmux.conf.local (via the @pane_color user option). Idempotent: a pane that
# already has a colour is left untouched, so re-firing the creation hooks never
# recolours an existing pane.
#
# Usage: pane-color.sh <pane_id>

pane="${1:-}"
[ -n "$pane" ] || exit 0

# already coloured? leave it
if tmux show-options -p -t "$pane" @pane_color 2>/dev/null | grep -q .; then
  exit 0
fi

# Bright/pastel palette — dark chip text (fg=colour232) stays legible on each.
palette=(203 209 215 221 227 191 156 120 86 87 81 117 147 183 219 213 212 210 180 159)
idx=$(( RANDOM % ${#palette[@]} ))

tmux set-option -p -t "$pane" @pane_color "colour${palette[$idx]}"
