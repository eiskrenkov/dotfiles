function reveal-in-finder --description "Reveal a directory in Finder (basically open .)"
    # Directory to reveal; defaults to the current directory when called with no
    # argument. The command palette passes the active pane's path so it opens the
    # folder you're actually in, not the popup's cwd.
    set -l dir $argv[1]
    test -n "$dir"; or set dir $PWD
    test -d "$dir"; or return 0

    open "$dir"
end
