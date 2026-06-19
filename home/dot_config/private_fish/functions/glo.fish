function glo --description "Browse git log in an fzf popup (rich commit info)"
    # One row per commit: sha · branches/tags · subject · relative date · author.
    # The sha is left UNCOLOURED and first so fzf's {1} field placeholder hands a
    # clean hash to the preview/copy actions (--ansi strips colour for display
    # but field splitting still sees the raw bytes).
    set -l fmt '%h %C(auto)%d%C(reset) %s %C(green)(%ad)%C(reset) %C(blue)<%an>%C(reset)'
    set -l log "git log --color=always --date=relative --format='$fmt' $argv"

    # Plain fzf when launched inside the command palette's popup (can't nest a
    # second popup); a floating `fzf --tmux` popup when run directly in a pane.
    set -l fzf_opts --ansi --no-sort --delimiter ' '
    set -q CMD_PALETTE_POPUP; or set -a fzf_opts --tmux=90%,80%

    # --layout default keeps git's newest-first output but anchors the list to the
    # bottom, so the latest commit sits just above the prompt. The preview shows
    # the full commit for the highlighted row; Enter copies its sha to clipboard.
    set -l sha (eval $log | fzf $fzf_opts \
        --layout default \
        --prompt 'log ❯ ' \
        --preview 'git show --color=always --stat {1}' \
        --preview-window 'down,60%,border-top' \
        | awk '{print $1}')

    test -n "$sha"; and printf '%s' $sha | pbcopy
end
