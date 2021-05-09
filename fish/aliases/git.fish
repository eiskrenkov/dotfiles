# Git aliases
alias gra="git remote add"
alias grrm="git remote remove"

alias ga="git add"
alias gst="git status"
alias ggpush="git push origin (current_branch)"
alias gpf!="git push --force"
alias gl="git pull"

alias gc="git commit -v"
alias gc!="git commit -v --amend"
alias gca!="git commit -v -a --amend"
alias gcmsg="git commit -m"
alias gcam="git commit -a -m"

alias gcm="git checkout master"
alias gcb="git checkout -b"
alias gba="git branch -a"
alias gbd="git branch -d"
alias gbD="git branch -D"

alias grb="git rebase"
alias grbm="git rebase master"
alias grba="git rebase --abort"
alias grbc="git rebase --continue"
alias grbi="git rebase -i"

alias gsta="git stash push"
alias gstp="git stash pop"
alias gstaa="git stash apply"
alias gstc="git stash clear"
alias gstd="git stash drop"
alias gstl="git stash list"
alias gsts="git stash show --text"

alias gsu="git submodule update"

alias gbl="git blame -b -w"
alias gd="git diff"

alias glg="git log --stat"
alias glgga="git log --graph --decorate --all"
alias glo="git log --oneline --decorate"
