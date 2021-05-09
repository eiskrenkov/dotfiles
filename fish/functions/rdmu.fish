function rdmu -d "Migrate specified migration up"
  rake db:migrate:up VERSION=$1
end
