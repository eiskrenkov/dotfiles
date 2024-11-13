function rdmu -d "Migrate specified migration up"
  bundle exec rake db:migrate:up VERSION=$argv[1]
end
