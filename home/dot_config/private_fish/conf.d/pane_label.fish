# Label the current tmux pane with the command being run, so panes stay
# distinguishable across splits. The label lives in the @pane_label user option,
# which tmux's pane-border-format renders as a chip on the pane's top border
# (see ~/.config/tmux/tmux.conf.local). The Claude Code pane-name Stop hook later
# overrides this with "claude | <generated name>" for claude panes.
#
# Label = the leading command words up to the first flag, capped at 3 words:
#   rails server                      -> "rails server"
#   claude --dangerously-skip-...     -> "claude"
#   git commit -m "..."               -> "git commit"
#   bundle exec rspec                 -> "bundle exec rspec"
function __pane_label_on_preexec --on-event fish_preexec
    test -n "$TMUX_PANE"; or return

    set -l label
    for word in (string split -- ' ' $argv[1])
        test -n "$word"; or continue
        string match -q -- '-*' $word; and break
        set -a label $word
        test (count $label) -ge 3; and break
    end
    test -n "$label"; or return

    tmux set-option -p -t $TMUX_PANE @pane_label (string join ' ' $label) 2>/dev/null
end
