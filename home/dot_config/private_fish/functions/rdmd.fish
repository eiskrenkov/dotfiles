function rdmd --description 'Migrate specified migration down'
  bundle exec rake db:migrate:down VERSION=$argv[1]
end
