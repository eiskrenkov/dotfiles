function ggpr --description "Push git branch and open GitHub pull request"
  git push origin $(current-branch) && gh pr create --fill-first --head $(current-branch) && gh pr view --web
end
