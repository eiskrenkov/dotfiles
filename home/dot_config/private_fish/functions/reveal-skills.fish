function reveal-skills --description "Reveal the Claude skills folder in Finder"
    # Opens ~/.claude/skills, the symlink to the canonical ~/.agents/skills where
    # every skill lives. Unlike the other palette funcs this ignores the active
    # pane's path (passed by the command palette) — the folder is always fixed.
    set -l dir "$HOME/.claude/skills"
    test -d "$dir"; or return 0

    open "$dir"
end
