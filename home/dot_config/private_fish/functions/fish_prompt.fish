function fish_prompt
    # The cwd now lives on the tmux pane border (see conf.d/pane_label.fish), so
    # the prompt is just three chevrons. Red when the last command failed;
    # otherwise tinted to match this pane's label-chip colour (@pane_color, a hex
    # value set by scripts/pane-color.sh) so the prompt and chip share a hue.
    # Falls back to white outside tmux or before a colour is assigned.
    set -l last_status $status

    if test $last_status -ne 0
        set_color red
    else
        set -l pane_color (test -n "$TMUX_PANE"; and tmux show-options -pqv -t $TMUX_PANE @pane_color 2>/dev/null)
        # Only honour hex values — pre-existing panes may still carry the old
        # colourNNN form, which set_color rejects. Anything else falls back to white.
        string match -qr '^#?[0-9a-fA-F]{6}$' -- "$pane_color"; or set pane_color ffffff
        set_color $pane_color
    end

    echo -n '❯❯❯ '
    set_color normal
end
