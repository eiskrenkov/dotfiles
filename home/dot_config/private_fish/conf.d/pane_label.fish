# Label the current tmux pane with the short cwd, git branch, and the command
# being run, so panes stay distinguishable across splits. The label lives in the
# @pane_label user option, which tmux's pane-border-format renders as a chip on
# the pane's top border (see ~/.config/tmux/tmux.conf.local). The Claude Code
# pane-name Stop hook later appends "| <generated name>" for claude panes,
# preserving the "<path> → ⎇ <branch> → <cmd>" prefix this sets.
#
# Label = "<short cwd> → ⎇ <branch> → <cmd>", where <short cwd> matches the fish
# prompt's prompt_pwd (e.g. ~/.l/s/chezmoi), <branch> is the current git branch
# prefixed with the ⎇ icon (omitted outside a repo, matching the old gitmux
# status), and <cmd> is the leading command words up to the first flag, capped at
# 3 words. Segments are separated by →. The path and branch track live state.
#
# The <cmd> segment is only shown for commands that *occupy* the pane — long-
# running servers, watchers, REPLs, and TUIs (vite dev, rails server, claude, …).
# One-shot commands (cd, ls, git commit, …) are filtered out so the chip isn't
# churned with noise; running one clears any previous <cmd> segment. The set of
# recognised commands lives in $__pane_long_running_patterns below.
#   (fresh pane in ~/work/app on main) -> "~/work/app → ⎇ main"
#   pnpm run dev                       -> "~/work/app → ⎇ main → pnpm run dev"
#   rails server                       -> "~/work/app → ⎇ main → rails server"
#   git commit -m "..."                -> "~/work/app → ⎇ main"  (cmd dropped)
#
# Rendering is driven off the fish_prompt event (fired after each command
# completes, before the prompt is drawn) so the path and branch are always
# current — including right after a `cd` or `git checkout`, which fish_preexec
# can't see because it fires *before* the command takes effect. preexec only
# stashes the command in $__pane_cmd_label.

# Commands that "occupy" the pane: long-running servers, dev/watch tasks, REPLs,
# and TUIs. Only these get shown as the <cmd> segment. Patterns are PCRE regexes
# matched against the full command line (mostly anchored at ^). Extend freely —
# add the program or `<tool> <subcommand>` shape you want to surface on the chip.
set -g __pane_long_running_patterns \
    '^claude\b' \
    '^(bin/)?(bundle exec )?rails (s|server|c|console)\b' \
    '^bin/(dev|console)\b' \
    '^(pnpm|npm|yarn|bun)( run)? (dev|start|serve|watch|storybook|preview)\b' \
    '^(vite|next|nuxt|astro|remix|webpack|nodemon|parcel|esbuild|rollup|tsx)\b' \
    '^(foreman|overmind)\b' \
    '^docker(-| )compose .*\bup\b' \
    '^(tail -f|watch )' \
    '^(jekyll|hugo) serve\b' \
    '^(http-server|live-server|serve|ngrok)\b' \
    '\brunserver\b' \
    '^(psql|redis-cli|mysql|sqlite3)\b' \
    '^(irb|pry|node|python3?) *$'

function __pane_cmd_is_long_running --argument-names cmdline
    for pattern in $__pane_long_running_patterns
        string match -rq -- $pattern $cmdline; and return 0
    end
    return 1
end

function __pane_label_render
    test -n "$TMUX_PANE"; or return

    set -l label (prompt_pwd)

    set -l branch (git symbolic-ref --short HEAD 2>/dev/null)
    test -n "$branch"; and set label "$label → ⎇ $branch"

    test -n "$__pane_cmd_label"; and set label "$label → $__pane_cmd_label"

    tmux set-option -p -t $TMUX_PANE @pane_label "$label" 2>/dev/null
end

function __pane_label_on_preexec --on-event fish_preexec
    if not __pane_cmd_is_long_running $argv[1]
        # One-shot command (cd, ls, git commit, …): drop any stale <cmd> segment
        # so the chip falls back to "<path> → ⎇ <branch>".
        set -e __pane_cmd_label
        __pane_label_render
        return
    end

    set -l words
    for word in (string split -- ' ' $argv[1])
        test -n "$word"; or continue
        string match -q -- '-*' $word; and break
        set -a words $word
        test (count $words) -ge 3; and break
    end
    test -n "$words"; or return

    set -g __pane_cmd_label (string join ' ' $words)
    # Render now so the long-running command (claude, rails server, …) shows on
    # the chip while it runs; path/branch may be a beat stale here but the next
    # fish_prompt corrects them.
    __pane_label_render
end

# Re-render before every prompt so the path and branch stay current.
function __pane_label_on_prompt --on-event fish_prompt
    __pane_label_render
end
