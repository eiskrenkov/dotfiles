function rdmu -d "Migrate specified migration up"
  rake db:migrate:up VERSION=$argv[1]
end
