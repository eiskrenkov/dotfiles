# Rails aliases
alias rs='rails server'
alias fs="foreman s"
alias rc='rails console'

alias rgm='rails generate migration'
alias rdm='rake db:migrate'
alias rdmt="rake db:migrate RAILS_ENV=test"

alias devlog='tail -f log/development.log'
alias testlog='tail -f log/test.log'

alias rr='rails routes'

alias rup='ggpull && bundle install && SKIP_ANNOTATE=true rake db:migrate'
