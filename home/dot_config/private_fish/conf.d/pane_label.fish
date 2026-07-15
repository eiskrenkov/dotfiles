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
# Each segment carries an embedded tmux #[…] style so the info *types* read
# distinctly on the chip — path plain, branch italic, <cmd> bold, and the
# appended claude session name italic at regular weight (see the style tokens in
# __pane_label_render and the hook). The chip is dark text on a bright per-pane
# bg, so we vary text attributes (bold/italic), not colour.
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
#   kubectl exec -it my-pod -- bash    -> "~/work/app → ⎇ main → ☸ my-pod"
#
# When a command connects to a Kubernetes pod (`kubectl exec`/`attach` into a
# pod), the <cmd> segment becomes a distinct ☸ pod badge — a saturated k8s-blue
# chip showing "☸ <pod>", breaking out of the dark-text-on-pastel scheme the
# other segments share — so a shell running inside a remote pod is never mistaken
# for a local one. The pod name is parsed from the command line by
# __pane_k8s_target; see the preexec handler and s_k8s in __pane_label_render.
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
#
# NB: preexec sees the command line *as typed*, so aliases are matched by their
# own name, not what they expand to. `cld` (alias for `claude
# --dangerously-skip-permissions`) is listed here and normalised back to
# "claude" for display below, so an aliased launch behaves like a bare `claude`.
set -g __pane_long_running_patterns \
    '^(claude|cld)\b' \
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

# -- kubectl exec/attach: pane connected to a k8s pod --------------------------
# Flags on `kubectl exec`/`attach` (and kubectl's global flags) that consume the
# *next* token as their value, so it isn't mistaken for the pod name. Long flags
# written as --flag=value are self-contained and need no entry here.
set -g __pane_k8s_value_flags -c --container -n --namespace --context --cluster \
    --user --as --kubeconfig --request-timeout --pod-running-timeout -f --filename

# Echo the pod/resource a `kubectl exec`/`attach` command targets, or return
# non-zero with no output when the command line isn't one — used by the preexec
# handler to give k8s-pod sessions their own ☸ badge. Walks the tokens, skipping
# the program name, the subcommand, flags, and their values, and stops at `--`
# (everything after it is the command run *inside* the pod). Copes with the
# subcommand trailing global flags (`kubectl -n prod exec …`) and the pod sitting
# before or after boolean flags (`kubectl exec my-pod -it -- bash`). Matched on
# the command line as typed, so the `k` alias for kubectl is recognised too.
function __pane_k8s_target --argument-names cmdline
    set -l t
    for word in (string split -- ' ' $cmdline)
        test -n "$word"; and set -a t $word
    end
    set -q t[1]; or return 1
    string match -qr '^(kubectl|k)$' -- $t[1]; or return 1
    contains -- exec $t; or contains -- attach $t; or return 1

    set -l seen_sub 0
    set -l skip 0
    for tok in $t[2..-1]
        if test $skip -eq 1
            set skip 0
            continue
        end
        test "$tok" = '--'; and break
        if string match -q -- '-*' $tok
            contains -- $tok $__pane_k8s_value_flags; and set skip 1
            continue
        end
        if test $seen_sub -eq 0
            contains -- $tok exec attach; and set seen_sub 1
            continue
        end
        echo $tok
        return 0
    end
    return 1
end

function __pane_label_render
    test -n "$TMUX_PANE"; or return

    # tmux #[…] style tokens, one per info type on the chip. The chip is dark text
    # on the bright per-pane @pane_color bg (see tmux.conf.local), so colour can't
    # tell segments apart — we lean on text attributes: path plain, branch italic,
    # <cmd> bold (the claude session name the hook appends is italic, regular
    # weight). Each
    # token sets *both* attrs explicitly so styles never bleed across segments;
    # the pane-border-format's trailing #[default] clears them off the chip edge.
    # Separators (→) stay plain so the styled segments stand out.
    set -l s_plain '#[nobold,noitalics]'
    set -l s_branch '#[nobold,italics]'
    set -l s_cmd '#[bold,noitalics]'
    # k8s-pod badge: white text on saturated Kubernetes-blue, so a pane shelled
    # into a remote pod is unmistakable — it deliberately breaks out of the
    # dark-text-on-pastel scheme the other segments share (set when
    # __pane_cmd_is_k8s is present; see the preexec handler). It is always the
    # last segment, so pane-border-format's trailing #[default] closes the badge
    # and the surrounding spaces are its padding.
    set -l s_k8s '#[fg=#ffffff,bg=#326ce5,bold]'

    set -l label "$s_plain"(prompt_pwd)

    set -l branch (git symbolic-ref --short HEAD 2>/dev/null)
    test -n "$branch"; and set label "$label$s_plain → $s_branch⎇ $branch"

    if test -n "$__pane_cmd_label"
        if set -q __pane_cmd_is_k8s
            set label "$label$s_plain → $s_k8s $__pane_cmd_label "
        else
            set label "$label$s_plain → $s_cmd$__pane_cmd_label"
        end
    end

    tmux set-option -p -t $TMUX_PANE @pane_label "$label" 2>/dev/null

    # @pane_cmd is the *bare* command identity (no path/branch prefix), used as
    # the tmux window label when this is the window's active pane (see
    # tmux.conf.local's window_status_format). Set it to the <cmd> segment when a
    # long-running command occupies the pane; unset it otherwise so the window
    # label falls back to #{pane_current_command}. The Claude pane-name hook
    # overrides it with just the session name.
    if test -n "$__pane_cmd_label"
        tmux set-option -p -t $TMUX_PANE @pane_cmd "$__pane_cmd_label" 2>/dev/null
    else
        tmux set-option -p -u -t $TMUX_PANE @pane_cmd 2>/dev/null
    end
end

function __pane_label_on_preexec --on-event fish_preexec
    # Connected to a k8s pod (kubectl exec/attach into a pod): show a distinct ☸
    # badge with the pod name so a shell running inside a remote pod is never
    # mistaken for a local one. Handled ahead of the generic long-running logic
    # because it needs the pod name and its own styling (see __pane_k8s_target and
    # s_k8s in __pane_label_render). Like other occupying commands, the badge
    # lingers after the session exits until a one-shot command replaces it.
    set -l k8s_pod (__pane_k8s_target $argv[1])
    if test -n "$k8s_pod"
        set -g __pane_cmd_is_k8s 1
        set -g __pane_cmd_label "☸ $k8s_pod"
        __pane_label_render
        return
    end
    set -e __pane_cmd_is_k8s

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
    # Normalise the `cld` alias to "claude" so it reads identically to a bare
    # `claude` on the chip and window label (and the pane-name hook's base ends
    # in "claude", as it does for a direct launch).
    set -g __pane_cmd_label (string replace -r '^cld\b' claude -- $__pane_cmd_label)
    # Render now so the long-running command (claude, rails server, …) shows on
    # the chip while it runs; path/branch may be a beat stale here but the next
    # fish_prompt corrects them.
    __pane_label_render
end

# Re-render before every prompt so the path and branch stay current.
function __pane_label_on_prompt --on-event fish_prompt
    __pane_label_render
end
