# Git aliases

# Remote
alias gra='git remote add'
alias grrm='git remote remove'

# Basic
alias ga='git add'
alias gaa='git add -A'
alias gst='git status'
alias ggpush='git push origin (current_branch)'
alias ggpull='git pull origin (current_branch)'
alias gp='git push'
alias gpo='git push origin'
alias gpf!='git push --force'
alias gl='git pull'
alias gfo='git fetch origin'

# Commit
alias gc='git commit -v'
alias gc!='git commit -v --amend'
alias gca!='git commit -v -a --amend'
alias gcmsg='git commit -m'
# gcam is a function

# Checkout
alias gcm='git checkout $(main_branch)'
alias gcb='git checkout -b'
alias gba='git branch -a'
alias gbd='git branch -d'
alias gbD='git branch -D'

# Rebase
alias grb='git rebase'
alias grbm='git rebase $(main_branch)'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias grbi='git rebase -i'

# Stash
alias gsts='git stash push --staged'
alias gsta='gst && gaa && git stash push && gst'
alias gstp='git stash pop'
alias gstaa='git stash apply'
alias gstc='git stash clear'
alias gstd='git stash drop'
alias gstl='git stash list'

# Other
alias gsu='git submodule update'

alias gbl='git blame -b -w'
alias gd='git diff'

alias glg='git log --stat'
alias glgga='git log --graph --decorate --all'
alias glo='git log --oneline --decorate'
