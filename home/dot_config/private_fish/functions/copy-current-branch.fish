function copy-current-branch --description "Copy the current git branch name to the clipboard"
  # Directory to resolve; defaults to the current directory when called with no
  # argument. The command palette passes the active pane's path so it copies the
  # branch of the repo you're actually in, not the popup's cwd.
  set -l dir $argv[1]
  test -n "$dir"; or set dir $PWD

  set -l branch (current-branch "$dir")
  test -n "$branch"; and printf '%s' $branch | pbcopy
end
