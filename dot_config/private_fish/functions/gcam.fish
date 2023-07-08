function gcam -d "Add all and commit with message"
  git add -A
  git commit -m $argv[1]
end
