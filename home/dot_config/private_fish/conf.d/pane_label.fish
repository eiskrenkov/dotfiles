# Label the current tmux pane with the short cwd and the command being run, so
# panes stay distinguishable across splits. The label lives in the @pane_label
# user option, which tmux's pane-border-format renders as a chip on the pane's
# top border (see ~/.config/tmux/tmux.conf.local). The Claude Code pane-name
# Stop hook later appends "| <generated name>" for claude panes, preserving the
# "<path> - <cmd>" prefix this sets.
#
# Label = "<short cwd> - <cmd>", where <short cwd> matches the fish prompt's
# prompt_pwd (e.g. ~/.l/s/chezmoi) and <cmd> is the leading command words up to
# the first flag, capped at 3 words. The path tracks the live cwd; the command
# is the most recent one run:
#   (fresh pane in ~/work/app)         -> "~/work/app"
#   rails server                       -> "~/work/app - rails server"
#   claude --dangerously-skip-...      -> "~/work/app - claude"
#   git commit -m "..."                -> "~/work/app - git commit"
#   bundle exec rspec                  -> "~/work/app - bundle exec rspec"
#
# The path must update on every cd, independently of commands — fish_preexec
# fires *before* a `cd` takes effect, so it can't render the path itself. Instead
# the command is stashed in $__pane_cmd_label on preexec, the path is rendered on
# every PWD change, and __pane_label_render combines them.

function __pane_label_render
    test -n "$TMUX_PANE"; or return

    set -l label (prompt_pwd)
    test -n "$__pane_cmd_label"; and set label "$label - $__pane_cmd_label"

    tmux set-option -p -t $TMUX_PANE @pane_label "$label" 2>/dev/null
end

function __pane_label_on_preexec --on-event fish_preexec
    set -l words
    for word in (string split -- ' ' $argv[1])
        test -n "$word"; or continue
        string match -q -- '-*' $word; and break
        set -a words $word
        test (count $words) -ge 3; and break
    end
    test -n "$words"; or return

    set -g __pane_cmd_label (string join ' ' $words)
    __pane_label_render
end

# Re-render on every directory change so the path stays current.
function __pane_label_on_pwd --on-variable PWD
    __pane_label_render
end

# Initial render so a fresh pane shows its path before any command runs.
__pane_label_render
