function copy-current-path --description "Copy the current folder path to the clipboard"
  # Directory to copy; defaults to the current directory when called with no
  # argument. The command palette passes the active pane's path so it copies the
  # folder you're actually in, not the popup's cwd.
  set -l dir $argv[1]
  test -n "$dir"; or set dir $PWD

  printf '%s' $dir | pbcopy
end
