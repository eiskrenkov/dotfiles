function gco --description "Checkout git branch with fzf or branch name"
  # Check if --fetch was passed as an argument
  set -l do_fetch false
  set -l args

  for arg in $argv
    if test "$arg" = "--fetch"
      set do_fetch true
    else
      set -a args $arg
    end
  end

  # Execute git fetch if requested
  if test "$do_fetch" = true
    echo "Fetching from remote..."
    git fetch origin
  end

  # Use the filtered args instead of original argv
  set argv $args

  # If a branch name is passed as an argument, use it directly
  if test -n "$argv[1]"
    git checkout $argv[1]
  else
    set remote_branches (git for-each-ref --count=10 refs/remotes/origin --sort=-committerdate --format="%(authordate:short) %(color:red)%(objectname:short) %(color:yellow)%(refname:short)%(color:reset) (%(color:green)%(committerdate:relative)%(color:reset)) %(authorname)" | sed "s#refs/remotes/origin/##g" | sed "s#refs/heads/##g" | sort -u)
    set local_branches (git for-each-ref --count=100 --sort=-committerdate refs/heads --format="%(authordate:short) %(color:red)%(objectname:short) %(color:yellow)%(refname:short)%(color:reset) (%(color:green)%(committerdate:relative)%(color:reset)) %(authorname)")

    set branch (string join \n $local_branches $remote_branches | fzf --ansi --tmux | awk '{print $3}')

    # Check if a branch was selected
    if test -n "$branch"
      git checkout $branch
    end
  end
end
