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
# Stored as hex (not colourNNN) so the value is consumable verbatim by both
# tmux's pane-border-format and fish's set_color, which colours the prompt
# chevrons to match the chip (see functions/fish_prompt.fish).
palette=(
  "#ff5f5f" "#ff875f" "#ffaf5f" "#ffd75f" "#ffff5f" "#d7ff5f" "#afff87"
  "#87ff87" "#5fffd7" "#5fffff" "#5fd7ff" "#87d7ff" "#afafff" "#d7afff"
  "#ffafff" "#ff87ff" "#ff87d7" "#ff8787" "#d7af87" "#afffff"
)
idx=$(( RANDOM % ${#palette[@]} ))

tmux set-option -p -t "$pane" @pane_color "${palette[$idx]}"
