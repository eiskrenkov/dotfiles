function gco
  # If a branch name is passed as an argument, use it directly
  if test -n "$argv[1]"
    git checkout $argv[1]
  else
    # Otherwise, prompt for a branch using fzf
    set branch (git for-each-ref --count=100 --sort=-committerdate refs/heads --format="%(authordate:short) %(color:red)%(objectname:short) %(color:yellow)%(refname:short)%(color:reset) (%(color:green)%(committerdate:relative)%(color:reset)) %(authorname)" | fzf --ansi --tmux | awk '{print $3}')

    # Check if a branch was selected
    if test -n "$branch"
      git checkout $branch
    end
  end
end
