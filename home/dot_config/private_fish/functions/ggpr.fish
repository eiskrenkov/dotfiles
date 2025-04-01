function ggpr --description "Push git branch and open GitHub pull request"
  git push origin $(current_branch) && gh pr create --fill-first --head $(current_branch) && gh pr view --web
end
