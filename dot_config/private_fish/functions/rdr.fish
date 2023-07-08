function rdr --description 'Rerun specified migration'
  echo "Reverting..."
  rake db:migrate:down VERSION=$argv[1] SKIP_ANNOTATE=1

  echo "Migrating..."
  rake db:migrate:up VERSION=$argv[1]
end
