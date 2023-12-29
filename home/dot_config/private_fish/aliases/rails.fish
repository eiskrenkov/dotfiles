# Rails aliases
alias rs='bundle exec rails server'
alias rc='bundle exec rails console'

alias rgm='bundle exec rails generate migration'
alias rdm='bundle exec rake db:migrate'
alias rdmt="bundle exec rake db:migrate RAILS_ENV=test"

alias devlog='tail -f log/development.log'
alias testlog='tail -f log/test.log'

alias rr='bundle exec rails routes'
alias rt='bundle exec rake -T'

alias rup='ggpull && bundle install && SKIP_ANNOTATE=true bundle exec rake db:migrate'

alias bi='bundle install'
alias be='bundle exec'
