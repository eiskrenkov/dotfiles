function open-in-sublime-merge --description "Open Sublime Merge for the git repo containing a directory (tmux prefix+M / ⌘⇧M)"
    # Directory to resolve; defaults to the current directory when called with
    # no argument. tmux (prefix+M) and the command palette both pass the active
    # pane's path. Does nothing if the path isn't a git work tree.
    set -l dir $argv[1]
    test -n "$dir"; or set dir $PWD
    test -d "$dir"; or return 0

    # Open the repo root so a subdirectory still maps to the whole repository.
    set -l root (git -C "$dir" rev-parse --show-toplevel 2>/dev/null)
    test -n "$root"; or return 0

    # Prefer the smerge CLI; fall back to LaunchServices.
    if command -q smerge
        smerge "$root"
    else
        open -a "Sublime Merge" "$root"
    end
end
