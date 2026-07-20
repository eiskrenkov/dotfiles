function open-in-github --description "Open the git repo containing a directory on GitHub (tmux prefix+K / ⌘⇧K)"
    # Directory to resolve; defaults to the current directory when called with
    # no argument. tmux (prefix+K) and the command palette both pass the active
    # pane's path. Does nothing if the path isn't a git work tree with a remote.
    set -l dir $argv[1]
    test -n "$dir"; or set dir $PWD
    test -d "$dir"; or return 0

    # Must be inside a git work tree.
    git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; or return 0

    # Prefer origin, fall back to whatever remote exists (e.g. upstream).
    set -l url (git -C "$dir" remote get-url origin 2>/dev/null)
    if test -z "$url"
        set -l remote (git -C "$dir" remote 2>/dev/null)[1]
        test -n "$remote"; or return 0
        set url (git -C "$dir" remote get-url $remote 2>/dev/null)
    end
    test -n "$url"; or return 0

    # Normalise the remote URL to a browsable https:// address:
    #   git@github.com:owner/repo.git      → https://github.com/owner/repo
    #   ssh://git@github.com/owner/repo.git → https://github.com/owner/repo
    #   https://github.com/owner/repo.git   → https://github.com/owner/repo
    set url (string replace -r '^git@([^:]+):' 'https://$1/' -- $url)
    set url (string replace -r '^ssh://git@' 'https://' -- $url)
    set url (string replace -r '\.git$' '' -- $url)

    open "$url"
end
