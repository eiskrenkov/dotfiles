function main_branch
  git branch -r | grep -E -i '^\s.origin\/(master|main)' | cut -d/ -f2 | head -n 1
end
