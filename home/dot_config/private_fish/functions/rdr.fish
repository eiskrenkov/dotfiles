function rdr --description 'Rerun specified migration'
  echo "Reverting..."
  bundle exec rake db:migrate:down VERSION=$argv[1] SKIP_ANNOTATE=1

  echo "Migrating..."
  bundle exec rake db:migrate:up VERSION=$argv[1]
end
