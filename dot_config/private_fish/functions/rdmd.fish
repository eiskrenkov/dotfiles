function rdmd --description 'Migrate specified migration down'
  rake db:migrate:down VERSION=$argv[1]
end
