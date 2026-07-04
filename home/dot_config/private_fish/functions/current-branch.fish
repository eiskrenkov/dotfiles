function current-branch --description "Output git's current branch name"
  # Directory to resolve; defaults to the current directory when called with no
  # argument. Callers that run outside the repo (e.g. copy-current-branch from
  # the command palette popup) pass the active pane's path.
  set -l dir $argv[1]
  test -n "$dir"; or set dir $PWD

  begin
    git -C "$dir" symbolic-ref HEAD; or \
    git -C "$dir" rev-parse --short HEAD; or return
  end 2>/dev/null | sed -e 's|^refs/heads/||'
end
